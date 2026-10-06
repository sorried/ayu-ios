# Manual device checklist

Things that cannot be verified without a live iPhone and a Telegram account.
Each line is one check with the expected result.

1. Install the ipa via SideStore with a fresh bundle id. Expect: it installs and launches.
2. Log in (phone + code). Expect: chat list loads.
3. Send and receive a text message from a second account.
4. Ghost Mode: enable "Don't read messages", open a chat from the second account. Expect: no read receipt on the other side; the local unread badge still clears.
5. Anti-recall: the second account deletes a message "for everyone". Expect: it stays in your chat with the deleted mark.
6. Edit history: the second account edits a message. Expect: "edited" appears and Edit History shows the previous text.
7. Peek last seen: (no UI yet, so this is a no-op until the trigger lands).
8. Streamer mode: enable it, open your own profile. Expect: phone number and username hidden.
9. Passcode: set a passcode, kill the app, reopen. Expect: lock screen; wrong code is rejected.
10. Secret chat: create one with the second account, send text and a photo. Expect: both arrive, timer works.
11. materialgram theme: check the olive accent, olive outgoing bubble, cream incoming bubble, warm chat background in day and dark mode. Expect: matches the Google palette, not Telegram blue.
12. App icon: the AyuGram icon shows on the home screen.
13. Voice note and round video: record and play both. Expect: both work.
14. Translator: translate an incoming message. Expect: it shows the translation.
15. Regex filters: add a pattern, send a matching message from the second account. Expect: the message is hidden.

Also report: which screen still shows dark text on dark background (a screenshot pins it immediately).
