# Telegram-iOS fork (AyuGram + materialgram)

A native Telegram-iOS client with the AyuGram privacy and storage features
(ghost mode, save deleted messages, edit history, secret chats, local Premium)
and the materialgram look, built as a sideload IPA for a free Apple ID.

## Build

The build runs in GitHub Actions (`Build sideload IPA`). It needs two repo
secrets: `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` (from my.telegram.org). The
workflow triggers on push to `ios` (code changes only) or manually. It produces
a fake-signed `release_arm64` IPA with extensions disabled.

```sh
gh run download <run-id> -R sorried/ayu-ios -n "Telegram-<version>-<build>-sideload"
```

Local builds need macOS and Xcode; see `docs/SIDELOAD.md`.

## Install (SideStore)

1. Download the IPA artifact.
2. In SideStore, import the IPA and set a new Bundle ID (so it does not clash
   with App Store Telegram).
3. Sign and install, then trust the certificate in Settings > VPN & Device
   Management.

The build falls back to Documents when App Groups are missing, so it boots
without entitlements.

## Limitations

- No push notifications (no Notification Service Extension on a free Apple ID).
- No iCloud or Siri.
- Free Apple ID: 3 apps, re-sign every 7 days.
- Messages deleted before the client saw them cannot be restored.

## License

GPL-2.0-or-later (Telegram's iOS client). See `SECURITY_REVIEW.md` for the fork
audit and `docs/` for feature and build documentation.
