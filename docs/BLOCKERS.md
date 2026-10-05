# Blockers

## CI: fork Actions is disabled (step 2, first build)

- State: `sorried/Telegram-iOS` is a fork of `decoder-dev/Telegram-iOS` (created
  2026-10-05). GitHub disables Actions on forks until the owner explicitly
  enables it. Evidence: parent repo reports 8 workflows + 532 runs; the fork
  reports `actions/workflows` total_count 0, `gh workflow list` empty, and a
  `workflow_dispatch` POST returns 404 ("workflow not found") even though
  `.github/workflows/build.yml` / `codeql.yml` / `symbolicate.yml` exist on both
  `master` and `ios`.
- Done (code side, all pushed to `ios`):
  - `9d3f84299e` ci: require api secrets, verify ipa, trigger on ios push
  - `6d2c55efe8` ci: pin third-party actions by commit sha
  - `f2d956325c` build: blank fork author api credentials
  - ipa verification step added (no PlugIns, single bundle id, required keys, no
    `27989480` / fork hash in binary); secrets are now required (build fails
    without `TELEGRAM_API_ID` / `TELEGRAM_API_HASH`).
- What I need from you: open https://github.com/sorried/Telegram-iOS/actions and
  click the green "I understand my workflows, go ahead and enable them" button
  (one click). There is no API/CLI to do this from my side. Once enabled, the
  next push to `ios` (or a manual `workflow_dispatch`) runs the build. Tell me
  when done and I will trigger + watch the run.
