# Decisions

Architectural decisions for the native fork. Populated as work proceeds.

- **Security baseline (step 1).** The fork is a heavily modified Telegram-iOS whose
  git history diverged from the public Telegram repo in 2019, so a merge-base diff
  is not a usable fork delta. Audit used whole-tree grep + fork-delta by author and
  file-presence (see SECURITY_REVIEW.md). Verdict clean.

## Feature inventory (step 3)

- **Re-estimated Swift line count: ~2-4k, down from PIVOT's 5-15k.** The fork
  already carries the whole AyuGram core (ghost mode, save deleted, edit history,
  kept dialogs, passcode, streamer, local premium, translator, regex filters,
  secret chats). What is genuinely missing is peek last seen plus the materialgram
  look/tweaks (Google Day/Dark themes, font, material icons, colourful reply
  background, seekable round videos, delete >100, webview android spoof, unlimited
  recent stickers, HTML chat export, custom sounds). See `FEATURES_NATIVE.md`.
- **The fork's appearance is pinned to the iOS Messages look, not materialgram.**
  `forkNormalizedThemeSettings` forces day/night; there are no Google Day/Dark
  palettes. Adding the materialgram themes means adding two theme builders rather
  than swapping the existing ones, and deciding (in step 4) whether materialgram
  becomes the default look or an option.

## Workflow cleanup (step 2)

The repo moved from the fork `sorried/Telegram-iOS` (Actions disabled by the
fork gate, abandoned) to a normal repo `sorried/ayu-ios` (Actions working,
default branch `ios`). GitHub registered only two of the four workflow files:
`Build sideload IPA` (`build.yml`) and `ping` (`ping.yml`). The other two were
never registered, so they were deleted rather than left as dead files:

- `ping.yml` — a one-off service workflow (`echo ok`) used only to trigger the
  first build. Deleted.
- `codeql.yml` — CodeQL static analysis. Triggers on push/PR to `master` (no such
  branch here) and a weekly `schedule`; it was not registered and the weekly run
  would only burn macOS minutes with no benefit to the ipa build. Deleted.
- `symbolicate.yml` — manual `workflow_dispatch` crash-symbolication aid. Not
  registered, not needed for producing the sideload ipa. Deleted.

Only `build.yml` remains: `workflow_dispatch` + `push` to `ios` with
`paths-ignore` for `docs/**` and `*.md`, `concurrency` cancel-in-progress, bazel
cache, required `TELEGRAM_API_ID`/`TELEGRAM_API_HASH` secrets, and an ipa
verification step (single `.app`, no PlugIns, single bundle id, required
Info.plist keys, no fork author api_id `27989480` in the binary).

- **Secret names.** The workflow reads `TELEGRAM_API_ID` / `TELEGRAM_API_HASH`
  (the fork's existing names); the owner added both `API_ID`/`API_HASH` and
  `TELEGRAM_API_ID`/`TELEGRAM_API_HASH` to the repo, and the workflow uses the
  `TELEGRAM_*` pair. Fork author credentials (`api_id 27989480` + hash) were
  blanked in `build-system/sideload-configuration.json` and the build now fails
  without the secrets.
