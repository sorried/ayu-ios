# TASK_IOS — the main task

The authoritative task description. This is the single source of truth; read it
first on any context reset.

## Context

Decision is made: we leave Flutter and move to a native fork. The `PIVOT.md`
analysis (in `../freshGram/docs/PIVOT.md`) is accepted. The Flutter version is
frozen (tag `flutter-snapshot`), nothing more is done there.

Working repo: my fork of `decoder-dev/Telegram-iOS`, cloned at
`/home/cldoff/dev/Telegram-iOS`, branch `ios`. The Flutter reference lives
locally at `/home/cldoff/dev/freshGram` (branch `ios`); read the ayu-core
behavior spec from there (`docs/AUDIT.md`, `docs/DECISIONS.md`, `ios_app/test/`,
and the desktop reference `Telegram/SourceFiles/ayu/`). Read-only: change
nothing, do not switch branch, do not commit there. freshGram original:
https://github.com/Snowy-Fluffy/freshGram. Fork upstream: `decoder-dev/Telegram-iOS`
(verify with `git remote -v`); add `tg = https://github.com/TelegramMessenger/Telegram-iOS`
if missing.

## 0. How I work

- One big autonomous task. I do not sit next to you and check every step.
  Exceptions: stop and report immediately if step 1 finds anything suspicious,
  and after step 2 wait for my confirmation that the ipa is installed.
- Keep this text in `docs/TASK_IOS.md` (it is the main). Memory is limited;
  external memory is files in the repo: `docs/TODO.md` (checklist with items),
  `docs/BLOCKERS.md`, `docs/DECISIONS.md`, `docs/NEXT.md` (3-5 lines: what to do
  next, update after each item). If context resets, start by reading these files
  and `git log` and continue from where you stopped.
- A TODO item is marked `[x]` only when done and verified: CI green, behavior
  checked against the reference, output pasted to chat, commit pushed. No
  batching of marks. Statuses only: работает / частично / заглушка / не сделано
  / невозможно / не проверено. "работает" without proof is forbidden. Do not
  write "готово", "итог", "всё сделано".
- git: commits add/feat/fix/ci/docs/test, format "тип: что сделано", English,
  lowercase, up to 70 chars, one step per commit, `git push origin ios`
  immediately. Only branch `ios`. Force push forbidden. No secrets, `build/`,
  binaries in commits. No history rewriting.
- There is no local iOS build (linux), everything builds only in GitHub Actions
  on macos. Swift does not compile locally, so: small careful changes, repeat the
  style and patterns of already-implemented fork features (Ghost Mode, Save
  Deleted, etc.), re-read the diff for typos and non-existent symbols before
  pushing. Fix red CI by the cause from the log, do not work around it.
- Do not ask "continue?". Blockers go to `docs/BLOCKERS.md` and move to the next
  item. Stuck after 2-3 different attempts: write what was tried and what is
  needed from me.
- To chat write only "NN: status, commit, run" or a blocker.

## 1. Security audit of the fork BEFORE build and install

This is a client with my Telegram session, and decoder-dev is a stranger to me.
Diff the fork against `TelegramMessenger/Telegram-iOS` (by merge-base, nearest
common ancestor) and find:

- network addresses other than Telegram datacenters and known ones (grep http,
  https, wss, ip-addresses)
- third-party SDKs and analytics
- hardcoded keys, api_id, tokens
- sending data outside MtProtoKit
- changes to MtProtoKit, Postbox, authorization, secret chats, encryption,
  keychain, session handling

Check `.github/workflows`: which actions are used (pinned by sha?), where
secrets go, any steps uploading artifacts or secrets to third-party hosts.

Result in `docs/SECURITY_REVIEW.md` with files and lines. If anything suspicious
is found, stop all work and tell me in the first line. If clean, say so with the
list of what was checked. Also check the fork LICENSE and record which it is.

## 2. CI and first ipa

Green sideload-ipa build WITHOUT code changes: workflow from the fork +
`docs/SIDELOAD.md`, my api_id and api_hash from GitHub secrets `API_ID` and
`API_HASH` (if the workflow expects other secret names, say which, do not invent),
own bundle id (SideStore replaces it on install anyway). Configure the workflow
to not burn minutes: `workflow_dispatch` and push to `ios` only on code changes
(paths-ignore for `docs/**` and `*.md`), concurrency with cancel-in-progress,
bazel cache (`actions/cache` on `~/telegram-bazel-cache`). ipa verification in
CI: no PlugIns, one bundle id, required Info.plist keys, runs without App Groups
(fallback). To chat: link to green run, cold and warm build times, ipa size and
how to download (`gh run download <id> -n <artifact-name>`). After this STOP and
wait until I install the ipa via SideStore and confirm it starts. Do not go
further.

## 3. Inventory

`docs/FEATURES_NATIVE.md`: table of all ayu features from `FEATURES.md` and
`AUDIT.md` (Flutter repo) and materialgram features: feature | in fork (да/частично/нет)
| file in code | how verified (read code, compared with reference) | what is missing.
Take module paths from `PIVOT.md` and verify against real code, do not trust
blindly. Re-evaluate the 5-15k Swift lines estimate after the inventory and
write the new one to `DECISIONS.md`.

## 4. Implement what is missing

One feature at a time, each a separate commit and separate CI build. Order:
peek last seen, kept dialogs (deleted and left chats stay in the list), secret
chats in the main list, streamer mode (ScreenCaptureDetection), edit history and
save deleted (if incomplete in the fork), filters and translator, missing
materialgram bits (Google Day and Dark themes, font, tailless bubbles, rounding,
colorful reply background, round-video rewind, delete >100 messages, export and
the rest from FEATURES.md), everything else from the inventory. Per feature:
spec from the reference, implementation in the fork's style, check: unit test if
the module has test infra, else an item in `docs/MANUAL_CHECKLIST.md` with the
expected result for me. Port the Flutter-test logic (ghost, anti-recall, edit
ordering, privacy_restore in try/finally at peek, restore at startup) as a spec,
not as code.

## 5. Final

Clean clone into an empty folder, green from-scratch build, ipa check,
`git log -S` for api_id and api_hash finds no secrets in history,
`docs/FINAL_REPORT.md` with an honest status table, divergences from freshGram
and limitations (push, iCloud, Siri impossible on a free apple id), a manual
checklist for me of 12-15 items (what cannot be verified without a live iPhone:
install, login, ghost with a check from a second account, deleted stays, peek
returns privacy, secret chats, streamer, themes), README with SideStore install.
