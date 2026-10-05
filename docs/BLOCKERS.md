# Blockers

## Resolved: fork Actions disabled (step 2)

Resolved by moving to a normal repo `sorried/ayu-ios` (Actions work, default
branch `ios`). The old fork `sorried/Telegram-iOS` is no longer used (remote
`old-fork`). First green sideload build: run 37315771258.

## Design holes (user report, not yet reproduced)

The user saw two things on the phone: "в местах нету отступов" (missing padding
in places) and "иногда текст черный на черном фоне" (black text on black
background). I cannot reproduce without a device, so this is what I checked and
why I have no confirmed fix yet.

What I checked (all clean / intentional):

- Fork ItemList screens (Extras, View Deleted / Edit History, Archive lock,
  proxy) route text through `presentationData`/theme colours. The fork's own
  `docs/ui-audit.md` §1 states "no hardcoded colors or fonts found in fork UI
  code".
- Deleted/edited marks render through `dateColor`, which is theme-derived in
  every branch (`ChatMessageDateAndStatusNode.swift`).
- The outgoing-bubble text colour in `DefaultDarkPresentationTheme.swift` /
  `DefaultDayPresentationTheme.swift` switches black/white by bubble lightness;
  it is intentional (black text on light bubbles, white on dark). `#007AFF` sits
  in the white branch, so normal chats are fine.
- Streamer-mode "Hidden" label uses `.white` (`PeerInfoHeaderNode.swift:1247`),
  which is upstream-standard white-on-gradient for the peer header.
- The layout knobs that shrink insets are opt-in and OFF by default:
  `wideChannelPosts` (bubble inset -16) and `compactChatList` /
  `compactMessagePreview` (negative title/author line spacing) in
  `ChatListItem.swift`.

Candidates I could not confirm as the bug (no device):

- A light accent / gift / chat theme with `editing: false` keeps the sender's
  light bubble colour, which flips outgoing text to black (`lightness > 0.735`).
  On the fork's dark background this could read as black-on-light-bubble, but
  not literally black-on-black.
- The opt-in `wideChannelPosts` / compact modes above, if enabled, hug the
  screen edge.

What I need from you:

1. Which screen and which element (chat list row, chat bubble, Extras, profile)?
   Light or dark mode? A screenshot or two would pin it in minutes.
2. Are any of the layout toggles on (compact rows/preview, wide channel posts)?

No code change made for these yet; I did not want to guess at theme/layout
edits I cannot verify.
