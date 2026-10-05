# Cleanup plan

Findings from a pass over fork-authored code and strings (files + lines), with
the fix for each. Upstream Telegram strings and code are left alone.

## 3a. Interface strings

Fork strings live in `ForkExtrasController.swift` (en/ru tables) and inline in a
few feature files.

- [x] `ForkExtrasController.swift:135` (en) + `:269` (ru) `SaveDeletedMessagesFooter`
  — "(🧹)" emoji in the footer text. Removed; the mark itself is still the default.
- [x] `ForkExtrasController.swift:142` (en) `AyuForwardFooter` — "noforwards
  channels" jargon. Reworded to "channels that block forwarding".
- [x] `ForkExtrasController.swift:152` (en) `LocalPremiumFooter` — "Premium UX"
  jargon. Reworded to "Premium features".
- [x] `ForkExtrasController.swift:180` (en) + `:314` (ru) `HubFooter` — "Each row
  opens a grouped Settings list. Navigation, sheets and switches follow iOS
  conventions" is meta filler. Removed the footer row and its string.
- [x] `MessageSavingHistoryController.swift:60` — "📎 " emoji prefixed to the
  attachment filename. Removed; the filename alone is enough.
- [x] `MessageSavingHistoryController.swift:56` — "·" as a separator between
  author and mark. Left as-is (single separator, not an interface emoji).

Kept deliberately: `🧹` as the default deleted-message mark (AyuGram parity, it
is a feature value, not a label), and the `placeholder: "🧹"` on the mark input
(it shows the default).

## 3b. Code

- Names are fine: no `Helper`/`Manager`/`Utils` symbol abuse in fork files
  (`ForkExtrasController`, `MessageSavingBridge`, `MessageSavingStore`,
  `ArchiveLockHelpers`). `ArchiveLockHelpers.swift` is a file name (localized
  strings + helpers); renaming it would churn BUILD files for no user-visible
  gain, so it stays.
- Fork comments are mostly "why" (design rationale, invariants), not "what"
  restatements; kept. No dead-code or duplicate removal attempted without a
  compiler to confirm. No mass renames.

## 3c. Repo

- [x] `README.md` rewritten (short, no emoji, no buzzwords): what it is, build,
  SideStore install, limitations.
