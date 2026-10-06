# Final report

Honest status of the native fork work. The fork (decoder-dev) already carried most
of the AyuGram core; this report covers what was changed on top of it and what
remains open.

## Done and verified (green CI)

- Security audit: clean, no exfiltration/backdoor (`docs/SECURITY_REVIEW.md`).
- CI: sideload ipa build, pinned actions, required secrets, ipa verification
  (single `.app`, no PlugIns, single bundle id, no fork api_id `27989480` in the
  binary, `Assets.car` present).
- App icon: AyuGram icon, flattened onto its background colour
  (`docs/ICON.md`, `scripts/generate_app_icon.py`).
- Interface cleanup: fork strings trimmed, hub footer removed, README rewritten.
- Peek last seen: engine + privacy restore + crash restore at startup. No UI
  trigger yet.
- materialgram themes: Google Day/Dark accent, outgoing and incoming bubble
  colours, chat background (`DefaultDayPresentationTheme.swift`,
  `DefaultDarkPresentationTheme.swift`).

## Feature inventory

See `docs/FEATURES_NATIVE.md`. Summary:

| Area | Status |
|---|---|
| AyuGram core (ghost, save deleted, edit history, kept dialogs, passcode, streamer, local premium, translator, regex filters, secret chats) | да (already in fork) |
| Peek last seen | частично (engine only, no UI) |
| materialgram Google Day/Dark themes | частично (colours done, font + icons not done) |
| materialgram tweaks (reply bg, round-video seek, delete 100+, webview spoof, unlimited stickers, HTML export, sounds) | не сделано |
| Dark text bug | не сделано (blocked, see below) |

## Divergences from freshGram

- Local store is JSON (`MessageSavingStore`), not SQLite/drift; backups are
  manual export/import, not a schedule.
- Appearance is a static day/night palette, not a dynamic Material You engine
  (impossible on iOS).
- The fork pins the "Messages" look by default; the materialgram palette is now
  applied on top (accent + bubbles + background), but the Google Sans font and
  Material icons are not bundled.

## Limitations

- No push notifications, iCloud, or Siri on a free Apple ID.
- Free Apple ID: 3 apps, re-sign every 7 days.
- Messages deleted before the client ever saw them cannot be restored.
- Local Premium is client-side only; nothing server-enforced changes.

## Open items

- Peek last seen UI (a tap/context-menu action in the profile).
- materialgram font (Jakarta Sans / Vazirmatn) and Material icons.
- Remaining materialgram tweaks from `FEATURES_NATIVE.md`.
- Dark text bug: not reproduced without a device; needs a screenshot or the
  exact screen (tracked in `docs/BLOCKERS.md`).

## Secrets

The fork author's `api_id` `27989480` is in git history (introduced by the fork,
blanked in `f2d956325c`, referenced in docs). The owner's own
`TELEGRAM_API_ID` / `TELEGRAM_API_HASH` live only in GitHub secrets and the CI
build config; they are not in the repository or history.

## Manual device checklist

See `docs/MANUAL_CHECKLIST.md`.
