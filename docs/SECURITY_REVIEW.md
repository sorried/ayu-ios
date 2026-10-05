# Security review — decoder-dev/Telegram-iOS fork

Date: 2026-10-05. Audited commit `227329a54c` (branch `ios`, identical to
`upstream/master` and `origin`). Baseline: `TelegramMessenger/Telegram-iOS`
(`tg/master`, fetched to `6ad963e5b6`, public HEAD 2026-07-18).

## Method

The fork's history diverged from the public Telegram repo at merge-base
`094ae2ad` (2019-06-11), so `git diff <merge-base>..upstream/master` is ~6 years
of Telegram development plus the fork and is not a usable "fork delta" by itself.
Two complementary approaches were used instead:

1. **Whole-tree grep** of the exact code that will be built (network hosts, ip
   addresses, api_id/api_hash, token/secret literals, analytics SDK names).
2. **Fork-delta identification** by (a) author (`decoder-dev`, `D3C0Y`,
   `overtake`, `Iulian Onofrei`, `CryZFix`) over `git log tg/master..upstream/master`,
   and (b) file-presence delta `comm -23 (upstream/master files) (tg/master files)`.

## Verdict: clean

No backdoor, no data exfiltration, no secret exfiltration, no weakened crypto,
no analytics/tracking SDK. The fork's changes to security-critical code are bug
fixes or genuine hardening (PBKDF2 passcode hashing). Full findings below.

---

## 1. Network endpoints outside Telegram datacenters

All non-Telegram network destinations found, and why each is benign:

| Endpoint | File:line | Purpose | Verdict |
|---|---|---|---|
| `kws{N}.web.telegram.org` / `kws{N}-1.web.telegram.org` | `submodules/MTWebSocketTransport/Sources/WebSocketDatacenterMapping.swift:19-21` | WebSocket transport to Telegram's own gateway | Telegram infra |
| `dns.google.com`, `mozilla.cloudflare-dns.com` | `submodules/MtProtoKit/Sources/MTBackupAddressSignals.m:174,178` | DoH for backup DC-ip discovery | upstream stock behavior, metadata only |
| `dns.google`, `cloudflare-dns.com`, `mozilla.cloudflare-dns.com` | `submodules/TelegramCore/Sources/State/ManagedAutomaticMtProxy.swift:354-356` | DoH to resolve proxy hostnames (TXT) | opt-in proxy feature |
| `cdn.jsdelivr.net/gh/...`, `raw.gitmirror.com/...`, `raw.githubusercontent.com/...` (SoliSpirit/kort0881/dubblebyte/Chumbayoumba mtproto proxy lists) | `submodules/TelegramCore/Sources/State/ManagedAutomaticMtProxy.swift:14-33` | fetch public MTProxy server lists | opt-in censorship bypass; downloads only, sends nothing |
| `translate.googleapis.com` | `submodules/TranslateUI/Sources/Translate.swift:461` | Google free translate endpoint | upstream Telegram free-user fallback, unchanged |
| `tgb*.smart-glocal.com/cds/v1/tokenize/card` | `submodules/BotPaymentsUI/Sources/BotCheckoutNativeCardEntryControllerNode.swift:318-320` | Telegram's card-tokenization processor | upstream, unchanged |
| `api.foursquare.com`, `ss3.4sqi.net` | `submodules/ShareItems/.../TGShareLocationSignals.m:16`, `submodules/LocationResources/.../VenueIconResources.swift:39` | venue search/icons | upstream, unchanged |
| `fragment.com` | `submodules/PeerInfoUI/.../ChannelVisibilityController.swift:1837`, `SettingsUI/.../UsernameSetupController.swift` | username auction links | upstream, unchanged |
| Stripe `api.stripe.com` | `submodules/Stripe/Sources/STPAPIClient.m:95` | payments | upstream, unchanged |
| WEB proxy carrier `wss://<hostname>/api/v1/ws`, `https://<normalized>` | `submodules/WebProxyTransport/Sources/WebProxyHttpCarrier.swift:196,1124` | user-configured WEB proxy host | catalog empty by default (`WebProxyCatalog.swift:35-42`) |

No hardcoded third-party host that receives Telegram message/session/contact
data. The translator and DoH calls carry only the specific text/DNS being
translated/resolved, exactly as upstream Telegram does.

## 2. Hardcoded keys / api_id / tokens

| Item | Location | Assessment |
|---|---|---|
| `api_id = "27989480"`, `api_hash = "ff8662eec9630346532b13f56014c258"` | `build-system/sideload-configuration.json:3-4` | Fork author's personal Telegram API credentials (a client identifier, **not** a user-account secret). Hardcoded and committed. Replaced at build time when `TELEGRAM_API_ID`/`TELEGRAM_API_HASH` secrets are present (see §4). Recommend replacing with own credentials (step 2). |
| `api_id = "8"`, `api_hash = "7245de8e...cc0bb"` | `build-system/example-configuration/variables.bzl:3-4` | Official Telegram iOS app credentials; byte-identical to upstream (`git diff tg/master` = empty). |
| `apiId: 0, apiHash: ""` | `submodules/SettingsUI/.../ChangePhoneNumberController.swift:25` | placeholder, upstream. |

No hardcoded access tokens, secret keys, or credentials of any other kind were
found (regex sweep for `apiKey|secretKey|clientSecret|accessToken|authToken`
with long literal values returned nothing).

## 3. Third-party SDKs / analytics

Sweep for Firebase, Amplitude, Mixpanel, AppsFlyer, adjust, Sentry, AppMetrica,
Google Analytics, gtag, IDFA, Segment returned **no matches** (only false
positives on the words "adjust"/"segment"). `MetricKit` is used
(`submodules/TelegramUI/Sources/ForkPerformanceTelemetry.swift`) but its
payloads are written to the local `Logger`, never sent anywhere
(`ForkPerformanceTelemetry.swift:434,441,493`). No telemetry exfiltration.

## 4. GitHub Actions workflows

`.github/workflows/` contains `build.yml`, `codeql.yml`, `symbolicate.yml`.

- **Actions and pinning.** `actions/checkout@v5`, `actions/cache@v4`,
  `actions/upload-artifact@v5` (`build.yml:53,110,338,347`); `codeql-action/*@v4`
  (`codeql.yml`); `actions/download-artifact@v5` (`symbolicate.yml`). All are
  **tag refs, not SHA-pinned**. A mutable tag could be repointed by its owner;
  recommend pinning to full commit SHA as hardening (not a current defect).
- **Secret destinations.** Only two secrets are consumed: `TELEGRAM_API_ID` and
  `TELEGRAM_API_HASH` (`build.yml:128-129`). They are written into
  `build-system/ci-configuration.json` and baked into the binary (normal for a
  Telegram client). `GH_TOKEN` = `github.token` is used only for `gh release`
  against this repo (`build.yml:240`). No step uploads artifacts or secrets to a
  third-party host; `actions/upload-artifact` writes to GitHub's own store.
- **Note for step 2.** The workflow reads `TELEGRAM_API_ID` / `TELEGRAM_API_HASH`
  (`build.yml:128-129`), **not** `API_ID` / `API_HASH`. If the owner adds their
  credentials under `API_ID`/`API_HASH` only, either rename the secrets or add a
  second `env` mapping. The same secret names are also absent from the current
  `build.yml`'s `on:` — it triggers on `push: tags v*` and `workflow_dispatch`
  only (no `push` to `ios`, no `paths-ignore`, no `cancel-in-progress` already
  present via `concurrency`). These are step-2 config items, not findings.

## 5. Changes to security-critical modules

- **MtProtoKit.** Fork-authored changes are connection-management only: FakeTLS
  fragmentation, WebSocket transport seam, reconnect ladders, log bounding
  (`f3f10ea52e`, `a8e51df23c`, `dda128856e`, `6e914579a9`, `08d3fb6f85`). The
  core crypto (`MTAes.m`, `MTRsa.m`, `MTKeychain.m`) has **no fork-authored
  changes**; the only touching commits are upstream Telegram ones.
- **Postbox.** Fork changes are bug fixes (races, retry throttling, batching)
  and the message-saving feature (`51be31b4c4`, `3fa6671609`). No crypto change.
- **EncryptionProvider / OpenSSLEncryptionProvider.** Upstream only ("Refactor
  Bignum into EncryptionProvider", spm/bazel packaging by `overtake`). No fork
  weakening of the cipher stack.
- **Passcode / app lock.** Fork changed plaintext passcode storage to
  PBKDF2-HMAC-SHA256 (100k iterations, 16-byte salt, constant-time compare) —
  `submodules/TelegramCore/Sources/AccountManager/PostboxAccessChallengeDataHashing.swift`
  (commits `5317afe0bd`, `7ea0bd6776`). This is a hardening, not a weakening.
- **Keychain / session.** New `SessionKeychainBackup`
  (`submodules/TelegramUIPreferences/Sources/SessionKeychainBackup.swift`) stores
  `AccountBackupData` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
  and explicitly does **not** sync to iCloud. Device-local only.
- **Secret chats.** Fork commits are crash/decrypt bug fixes
  (`4acedd832b`, `c559baa638`), no change to the key-exchange or encryption
  scheme.
- **Cross-check.** No fork-added file references both `SecItem`/keychain and
  `URLSession`/network in the same file (scripted sweep over the file-presence
  delta). I.e. there is no code path that reads keychain/session data and sends
  it over the network.

## 6. License

There is **no `LICENSE` file** in the fork, and none in upstream either
(`git ls-tree` on both `upstream/master` and `tg/master`; the public
`TelegramMessenger/Telegram-iOS` repo also has no `LICENSE` and
`raw.githubusercontent.com/.../LICENSE` 404s). The README says only "publish
your code too in order to comply with the licences" without naming one.
Telegram-iOS source is commonly understood as GPLv3 (Telegram's mobile clients
are GPLv3), but this is **not declared in-repo**. Recommendation: add a GPLv3
`LICENSE` file in step 5 (it is on the final checklist anyway).

## 7. Other observations (not defects)

- The app is rebranded "ZalupaGram" (`28e33d5655`, `6acdbc0451`); display name
  is cosmetic and replaceable in the build config.
- Censorship-bypass machinery (FakeTLS, MTProxy mirrors, WEB proxy) is present
  and is **opt-in**; its default catalogs/fronts are empty, so a stock build
  talks only to Telegram's own endpoints.
- `.gitlab-ci.yml` is upstream Telegram's internal CI (darwin containers,
  TestFlight deploy via env-var secrets); it is not used by GitHub Actions and
  carries no hardcoded secrets.

## 8. What I checked (checklist)

- [x] grep http/https/wss across Swift/m/mm/h/plist/py/sh/bzl/json (third-party excluded) and reviewed every non-Telegram host
- [x] grep ip-address literals (only Telegram DC ranges `149.154.x.x`/`91.108.x.x`, `8.8.8.8` DNS probe, loopback `127.0.0.1`)
- [x] grep api_id / api_hash / apiId literals
- [x] grep token / secret / apiKey literal patterns
- [x] grep analytics/attribution SDK names (Firebase, Amplitude, Mixpanel, AppsFlyer, adjust, Sentry, AppMetrica, GA, IDFA, Segment)
- [x] `.github/workflows` reviewed (actions, pinning, secret destinations, artifact uploads)
- [x] fork-authored commits to MtProtoKit / Postbox / EncryptionProvider / OpenSSLEncryptionProvider / LocalAuth / secret-chat / AuthManager reviewed
- [x] fork-added files reviewed (network transport, message saving, keychain, telemetry, log export, proxy)
- [x] scripted cross-check: no fork file reads keychain AND does network in one file
- [x] LICENSE check
