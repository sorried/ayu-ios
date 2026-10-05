# NEXT

1. Security audit done and clean (docs/SECURITY_REVIEW.md). No backdoor/exfiltration.
2. Step 2: set up CI for sideload ipa. Workflow reads TELEGRAM_API_ID / TELEGRAM_API_HASH
   (not API_ID/API_HASH). Replace hardcoded fork creds (api_id 27989480) with owner's own.
   Add push-to-ios trigger with paths-ignore, ipa verification step. Then STOP for install.
