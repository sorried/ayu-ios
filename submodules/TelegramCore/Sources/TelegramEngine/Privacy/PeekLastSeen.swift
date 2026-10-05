import Foundation
import Postbox
import SwiftSignalKit

/// Crash-recovery state for a peek-last-seen in flight. Stored before the privacy
/// rules are modified and cleared once they are restored, so a kill mid-peek never
/// leaves the target permanently able to see your status.
private struct PeekLastSeenRestoreState: Codable {
    enum PresenceKind: Int32, Codable {
        case enableEveryone = 0
        case enableContacts = 1
        case disableEveryone = 2
    }

    struct PeerRef: Codable {
        var namespace: Int32
        var id: Int64
    }

    var kind: PresenceKind
    var enableFor: [PeerRef]
    var disableFor: [PeerRef]
    var enableForCloseFriends: Bool
    var enableForPremium: Bool
    var enableForBots: Bool
}

private func peerRefs(_ peers: [PeerId: SelectivePrivacyPeer]) -> [PeekLastSeenRestoreState.PeerRef] {
    return peers.keys.map { PeekLastSeenRestoreState.PeerRef(namespace: $0.namespace, id: $0.id._internalGetInt64Value()) }
}

private func restoreState(for presence: SelectivePrivacySettings) -> PeekLastSeenRestoreState {
    switch presence {
    case let .enableEveryone(disableFor):
        return PeekLastSeenRestoreState(kind: .enableEveryone, enableFor: [], disableFor: peerRefs(disableFor), enableForCloseFriends: false, enableForPremium: false, enableForBots: false)
    case let .enableContacts(enableFor, disableFor, enableForPremium, enableForBots):
        return PeekLastSeenRestoreState(kind: .enableContacts, enableFor: peerRefs(enableFor), disableFor: peerRefs(disableFor), enableForCloseFriends: false, enableForPremium: enableForPremium, enableForBots: enableForBots)
    case let .disableEveryone(enableFor, enableForCloseFriends, enableForPremium, enableForBots):
        return PeekLastSeenRestoreState(kind: .disableEveryone, enableFor: peerRefs(enableFor), disableFor: [], enableForCloseFriends: enableForCloseFriends, enableForPremium: enableForPremium, enableForBots: enableForBots)
    }
}

private func presence(from state: PeekLastSeenRestoreState, transaction: Transaction) -> SelectivePrivacySettings {
    func resolve(_ refs: [PeekLastSeenRestoreState.PeerRef]) -> [PeerId: SelectivePrivacyPeer] {
        var result: [PeerId: SelectivePrivacyPeer] = [:]
        for ref in refs {
            let peerId = PeerId(namespace: ref.namespace, id: PeerId.Id._internalFromInt64Value(ref.id))
            if let peer = transaction.getPeer(peerId) {
                result[peerId] = SelectivePrivacyPeer(peer: peer, participantCount: nil)
            }
        }
        return result
    }
    switch state.kind {
    case .enableEveryone:
        return .enableEveryone(disableFor: resolve(state.disableFor))
    case .enableContacts:
        return .enableContacts(enableFor: resolve(state.enableFor), disableFor: resolve(state.disableFor), enableForPremium: state.enableForPremium, enableForBots: state.enableForBots)
    case .disableEveryone:
        return .disableEveryone(enableFor: resolve(state.enableFor), enableForCloseFriends: state.enableForCloseFriends, enableForPremium: state.enableForPremium, enableForBots: state.enableForBots)
    }
}

private func presenceHasHiddenStatus(_ presence: TelegramUserPresence) -> Bool {
    switch presence.status {
    case let .recently(isHidden), let .lastWeek(isHidden), let .lastMonth(isHidden):
        return isHidden
    default:
        return false
    }
}

/// Reads the target's last-activity timestamp. Returns nil while their exact
/// status is still hidden (the privacy change has not propagated yet).
private func readExactLastSeen(account: Account, peerId: PeerId) -> Signal<Int32?, NoError> {
    return account.viewTracker.peerView(peerId, updateData: false)
    |> map { view -> Int32? in
        guard let presence = view.peerPresences[peerId] as? TelegramUserPresence else {
            return nil
        }
        if presenceHasHiddenStatus(presence) {
            return nil
        }
        return presence.lastActivity
    }
}

/// Polls for the exact last-activity timestamp with short backoff.
private func pollExactLastSeen(account: Account, peerId: PeerId, attempts: Int) -> Signal<Int32?, NoError> {
    return readExactLastSeen(account: account, peerId: peerId)
    |> mapToSignal { value -> Signal<Int32?, NoError> in
        if let value {
            return .single(value)
        }
        if attempts <= 1 {
            return .single(nil)
        }
        return .single(nil)
        |> delay(0.8, queue: .concurrentDefaultQueue())
        |> mapToSignal { _ in pollExactLastSeen(account: account, peerId: peerId, attempts: attempts - 1) }
    }
}

/// Temporarily lets `peerId` see your status, reads their exact last-activity
/// timestamp, and restores your previous presence rules in every exit path.
/// Returns the timestamp, or 0 when no exact value could be read.
public func _internal_peekLastSeen(account: Account, peerId: PeerId) -> Signal<Int32, NoError> {
    return Signal { subscriber in
        var restored = false

        func restore(_ original: SelectivePrivacySettings) {
            guard !restored else {
                return
            }
            restored = true
            let _ = (account.postbox.transaction { transaction -> Void in
                transaction.updatePreferencesEntry(key: PreferencesKeys.peekLastSeenRestore, { _ in
                    return nil
                })
            }
            |> then(_internal_updateSelectiveAccountPrivacySettings(account: account, type: .presence, settings: original))).start()
        }

        let disposable = (combineLatest(
            _internal_requestAccountPrivacySettings(account: account)
            |> map { $0.presence },
            account.postbox.transaction { transaction -> SelectivePrivacyPeer? in
                guard let peer = transaction.getPeer(peerId) else {
                    return nil
                }
                return SelectivePrivacyPeer(peer: peer, participantCount: nil)
            }
        )
        |> mapToSignal { originalPresence, targetPeer -> Signal<Int32, NoError> in
            guard let targetPeer else {
                return .single(0)
            }

            let modifiedPresence = originalPresence.withEnabledPeers([peerId: targetPeer])
            let needsPrivacyChange = modifiedPresence != originalPresence

            let poll = pollExactLastSeen(account: account, peerId: peerId, attempts: 3)

            if !needsPrivacyChange {
                // The target can already see our status; read their exact value directly.
                return poll
                |> map { $0 ?? 0 }
                |> afterDisposed { restore(originalPresence) }
            }

            // Persist the original rules before mutating, so a kill mid-peek can restore.
            let _ = (account.postbox.transaction { transaction -> Void in
                let state = restoreState(for: originalPresence)
                transaction.updatePreferencesEntry(key: PreferencesKeys.peekLastSeenRestore, { _ in
                    return PreferencesEntry(state)
                })
            }
            |> then(_internal_updateSelectiveAccountPrivacySettings(account: account, type: .presence, settings: modifiedPresence))).start()

            return poll
            |> map { $0 ?? 0 }
            |> afterDisposed { restore(originalPresence) }
        }).start(next: { timestamp in
            subscriber.putNext(timestamp)
            subscriber.putCompletion()
        })

        return ActionDisposable {
            disposable.dispose()
        }
    }
}

/// Restores presence privacy rules left behind by a peek interrupted by a crash.
public func _internal_restorePeekLastSeenIfNeeded(account: Account) -> Signal<Void, NoError> {
    return account.postbox.transaction { transaction -> SelectivePrivacySettings? in
        guard let state = transaction.getPreferencesEntry(key: PreferencesKeys.peekLastSeenRestore)?.get(PeekLastSeenRestoreState.self) else {
            return nil
        }
        return presence(from: state, transaction: transaction)
    }
    |> mapToSignal { original -> Signal<Void, NoError> in
        guard let original else {
            return .single(Void())
        }
        return account.postbox.transaction { transaction -> Void in
            transaction.updatePreferencesEntry(key: PreferencesKeys.peekLastSeenRestore, { _ in
                return nil
            })
        }
        |> then(_internal_updateSelectiveAccountPrivacySettings(account: account, type: .presence, settings: original))
    }
}
