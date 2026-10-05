# Native fork feature inventory

Mapping of every feature in freshGram `FEATURES.md` / `AUDIT.md` onto the
decoder-dev fork. Status: да / частично / нет. "Как проверила" = read the code
(static), since there is no local Swift build.

## AyuGram core (privacy & storage)

| Feature | In fork | File in code | How verified | Missing |
|---|---|---|---|---|
| Ghost Mode: read receipts | да | `TelegramUI/Sources/ChatHistoryListNode.swift` (`shouldSuppressMessageReads`), `TelegramUIPreferences/Sources/ForkExtrasSettings.swift` | read code | — |
| Ghost Mode: stories / one-time media | да | `ForkExtrasSettings` (ghost toggles), message-opening path | read code (toggles) | — |
| Ghost Mode: online / typing | да | `TelegramCore/Sources/Account/Account.swift` (`suppressOnline`, `readOnInteract`) | read code | — |
| Local message storage | да | `TelegramCore/Sources/MessageSaving/MessageSavingBridge.swift`, `TelegramUIPreferences/Sources/MessageSavingStore.swift` | read code | JSON store, not SQLite; no automatic schedule backups (manual export/import) |
| Message edit history | да | `MessageSavingBridge` (`kind: .edited`), `MessageSavingHistoryController.swift` | read code | — |
| Anti-recall (save deleted) | да | `MessageSavingBridge.shouldRetainInChat`, `MessageSavingStore` | read code | — |
| Deleted service messages | частично | `MessageSavingBridge` (media/action guard) | read code | service-action-only messages are skipped |
| Kept dialogs (banned/left chats stay) | да | `ForkExtrasSettings.keepBannedChats` | read code | only "banned/kicked", not every removed chat |

## AyuGram enhancements

| Feature | In fork | File in code | How verified | Missing |
|---|---|---|---|---|
| Peek last seen | нет | — | grep `peekLastSeen`/`privacyRestore`/`setUserPrivacySettingRules` → nothing | whole feature |
| Passcode lock + timeout | да | `TelegramCore/Sources/AccountManager/PostboxAccessChallengeDataHashing.swift`, `ForkExtrasSettings` (instant lock) | read code (PBKDF2) | — |
| Secret chats | да | native Telegram-iOS + `ForkExtrasSettings.allowSecretScreenshots`, `.expireTtlButton` | read code | full parity already native |
| AyuGram settings section | да | `SettingsUI/Sources/ForkExtrasController.swift` | read code | — |
| Streamer mode | да | `TelegramUI/Sources/ChatController.swift` (`ScreenCaptureDetectionManager`) | read code | — |
| Local premium | да | `ForkExtrasSettings.localPremium` | read code | client-side only (by design) |
| In-app translator | да | `ForkExtrasController` (`translationBackend`) | read code | — |
| Regex filters / shadow ban | да | `ForkExtrasController` (`regexFilters`) | read code | — |

## materialgram UI

| Feature | In fork | File in code | How verified | Missing |
|---|---|---|---|---|
| Google Day / Dark themes | нет | — | grep `google`/`material theme` → nothing; themes pinned to day/night Messages look (`PresentationData.swift`) | both palettes |
| Google Sans / Vazirmatn font | нет | — | grep `googleSans`/`vazirmatn`/`jakarta` → nothing | font bundle + apply |
| Material icons swap | нет | — | grep `materialIcon` → nothing | icon set + toggle |
| Rounded bubbles without tails | да | `TelegramPresentationData/Sources/PresentationData.swift` (`higChatBubbleCorners` 18/4, no tails) | read code (CLAUDE.md) | — |
| Colorful reply background | нет | — | grep `replyBackground` → nothing | opacity slider + apply |
| Delete > 100 messages | нет | — | only native `deleteAllMessagesWithAuthor` (admin), no batch-100 trick | batch delete |
| Audio/voice: jpeg 95% / 256 kbit | частично | `LegacyMediaPickerUI/Sources/LegacyMediaPickers.swift` (`extrasQuality`) | read code | max quality 0.85, not 0.95; voice bitrate unconfirmed |
| Seekable round videos | нет | — | grep `videoNote seek` → nothing | scrubber for round videos |
| Webview spoof (`tgWebAppPlatform=android`) | нет | — | grep `tgWebAppPlatform` → nothing | platform param |
| Datacenter info | да | `ForkExtrasController` (`showDC`) | read code | — |
| Account creation date | да | same (`showDC` + registration row) | read code | — |
| App icon selection | да | `Telegram/Telegram-iOS/AppIcons.xcassets` + alternate icons | read code | — |
| Unlimited recent stickers | нет | — | grep → nothing | local sticker store |
| Chat export (HTML) | нет | — | grep `exportChat` → only invite/folder links; fork has JSON DB export | HTML export |
| Custom sounds | нет | — | grep `customSound` → nothing | sound assets |
| Long-press preview + reaction | да | native Telegram-iOS | read code | — |

## Summary

The fork already carries almost the whole AyuGram core (ghost, save deleted,
edit history, kept dialogs, passcode, streamer, local premium, translator,
regex filters, secret chats). The genuinely missing work is:

1. Peek last seen (privacy-rule get/set + restore + UI).
2. The materialgram look: Google Day/Dark themes, font, material icons,
   colourful reply background, seekable round videos.
3. A handful of materialgram tweaks: delete >100, webview android spoof,
   unlimited recent stickers, HTML chat export, custom sounds, jpeg 95% /
   voice 256 kbit exact values.

## Re-estimate of Swift lines

PIVOT.md estimated 5-15k lines to finish the ayu features in Swift. That was
written before seeing the fork's actual state. decoder-dev already did most of
the AyuGram core in Swift, so the remaining work is the items above, not the
whole core. New estimate: ~2-4k lines (peek last seen ~0.3k; materialgram
themes/font/icons/reply-bg ~1.5k; round-video seek + batch delete + webview
spoof + stickers + HTML export + sounds ~1-1.5k). See `DECISIONS.md`.
