# Privacy applicability matrix

This file records which data flows the macOS app Civo Cloud Manager really has, what the three privacy texts say about each of them, and where that text comes from. It is a documentary reconciliation of the texts with the code. It is not a statement that any clause is legally sufficient.

The three texts are the bundled `CivoCloudManager/<lang>.lproj/PrivacyPolicy.md` (16 languages, shown in the app), the public `PRIVACY.md` and the privacy section of `README.md`. No keys, kubeconfigs, credentials, console URLs or user data appear in this file.

## Provenance

| Item | Value |
|---|---|
| Date of this reconciliation | 2026-11-23 |
| App base commit | `93336d0` on `development`; `MARKETING_VERSION` 2.3.0 (not changed) |
| Privacy policy template used | `shared/PRIVACY_POLICY.en.md` version 2.3.2, valid from 2026-11-08, Effective Date 8 November 2026, commit `cc9c4543cf0ed58be97cd3c9d38fc86781b04680` of `digitalfreedom-co-za/legal` |
| Template revisions not used | 2.4.0 and 2.5.0 (valid from 2026-12-10, after the date of this reconciliation; they also bring Apple Business seat and health content that does not apply) |
| Helpdesk notice used for support wording | `website/HELPDESK_PRIVACY_NOTICE.en.md` version 1.0.1, valid from 2026-10-14 (shown at the support portal as "Privacy Policy - Helpdesk", effective 14 October 2026) |
| `legal` repository head when checked | `dc9b56ca7bf3bc52d0c582edcba13ea4b17669b3`; `internal/PRODUCT_PROFILE.en.md` version 1.5.1 at that head |
| Product profile entry for this app | None. The profile lists no per-app entry for Civo Cloud Manager (no occurrence of the app name under `legal/internal`, `legal/apps`, `legal/shared`). Follow-up in the `legal` repository, not done here |
| Dates used | Effective Date 8 November 2026 (from the template) in the bundled policy and in `PRIVACY.md`; `updated: 2026-11-23` in the bundled headers and "Last Updated: November 23, 2026" in `PRIVACY.md` |
| Support portal notice URL used in the texts | `https://support.apps.digitalfreedom.co.za` (the published alias). No FreeScout mailbox URL (`/help/<id>/...`) is published, because mailbox ids can change. A standalone `digitalfreedom.co.za/helpdesk-privacy/` page does not exist (404 on 2026-11-23) |

## Data-flow matrix

Classes: local; configured third-party endpoint; third-party endpoint not configured by the user; publisher support processing; platform operator; user-managed file; not present.

| # | Dataflow | Class | Purpose | Evidence | Retention and deletion | Who answers rights requests | Disclosure decision | Text locations (policy / `PRIVACY.md`) |
|---|---|---|---|---|---|---|---|---|
| 1 | Civo API key, region, managed firewalls, IP presets, launch at login, onboarding, trial start | Local | Run the app | `CivoConfig`; key in keychain, rest in UserDefaults (`fullAccessTrialStartedAt` for the trial); README "Persistence and current limits" | Until the user removes the key or the app's data; no uninstall-cleanup promise | Not applicable, the publisher does not receive it | Describe as stored on the Mac, not received by the publisher | 1.3, 3.2, 8 / 1, 2, 7 |
| 2 | Activity log | Local, UserDefaults key `CivoActivityLog` | Show recent actions | `ActivityLog.swift`: `maxEntries = 200`, older entries dropped on insert. `clear()` exists but has no caller in the app, so no clear action is promised | Newest 200 entries; stays until the app's data is deleted | Not applicable | State the 200 limit; entries may contain resource names and ids | 3.2, 8 / 2, 7 |
| 3 | Saved instance credentials, SSH encrypted backups, master key, timed firewall closures, charges cache | Local keychain and files | Run the app | `InstanceCredentialStore` (data-protection keychain, this Mac, not synchronized, user presence), `SSHKeychain`, README "Persistence and current limits" | Until the user deletes the item or the app's data. No delete path is promised beyond that | Not applicable | Local, keychain, no sync; no "hardware-backed" claim | 3.2, 8, 9 / 2, 6, 7 |
| 4 | Exported SSH private keys, kubeconfig, object store downloads | User-managed file | User's own use | `NSSavePanel` / `NSOpenPanel` in `CreateSSHKeyView`, `SSHKeyListView`, `ClusterListView`, `ObjectStoreBrowserView`. No other file import or export path found (`fileImporter` and security-scoped bookmarks: no occurrence in `*.swift`) | Not tracked or deleted by the app | The user | State that exports are outside the app's protection; no promise of encryption of exports | 3.4, 8, 9 / 2, 6, 7 |
| 5 | Requests to `api.civo.com` and the Civo console host | Configured third-party endpoint | Manage the Civo account | `CivoAPIClient`, `CivoConsoleService` | Civo's retention | Civo | Recipient Civo; link to Civo's policy | 3.3, 6.1 / 4.1 |
| 6 | Kubernetes API of the user's clusters | Configured third-party endpoint (user's infrastructure) | Cluster access | `KubernetesAPIClient`, `KubeconfigParser`. The credentials are parsed into `KubeconfigCredentials` and used for the connection; no `UserDefaults`, keychain or file write of them was found in these files | The user's own | The operator (the user) | "Used for the connection, not saved by the app itself". The earlier wording "in-memory only" is not repeated as an absolute | 3.3, 6.1 / 2, 4.2 |
| 7 | S3-compatible endpoints of the user's object stores | Configured third-party endpoint | Browse and transfer files | `S3Client` | The endpoint operator's | The operator | Added to all three texts | 3.3, 6.1 / 4.3 |
| 8 | Public IP lookup (`api.ipify.org`, `ifconfig.me`, `icanhazip.com`, fallback chain) | Third-party endpoint not configured by the user, triggered by the firewall feature | Detect the public IPv4 address | `IPDetector.swift` | The operators' own | The operators | Named; the IP address is inherently visible to them | 3.3, 6.1 / 4.4 |
| 9 | StoreKit purchase and 7 day trial | Platform operator (Apple, independent controller) | Sell and verify Full Access | `StoreManager.swift` (non-consumable `de.berger_rosenstock.CivoCloudManager.fullaccess`), local trial start date | Apple's | Apple | Non-consumable plus local trial; no "subscription"; the publisher sees no payment data | 3.3, 6.1.2 / 4.5 |
| 10 | Support tab: the support portal page | Publisher support processing | Handle a support request | `Views/MainWindow/Account/SupportView.swift` loads `CivoConfig.supportPortalURL` in a `WKWebView`. Facts of the portal: owner statement (name, email, problem description, solely to handle the request) and published notice 1.0.1 (subject, content, attachments, account context, optional vulnerability details; server log IP, time, page, referrer, user agent; one session cookie of two hours; local-storage draft removed on send) | From the published notice: open tickets until resolved, closed tickets 3 years, data protection records 6 years, logs up to 15 days, cookie 2 hours, draft until sent, backups 30 days rolling | The publisher | Disclosed from the notice and the template; no retention figure or processor beyond them | 1.3, 3.1, 3.2, 6.1.1, 8, 8a, 9, 12 / 1, 4.6, 7 |
| 11 | Links to digitalfreedom.co.za, civo.com, Apple pages | User-initiated outbound | Navigation | `AboutView`, `OnboardingView` | n/a | n/a | "Links open in your browser" | 3.3 / 4.7 |
| 12 | Local notifications | Local | Pod restart alerts | `NotificationService.swift`: `requestAuthorization(options: [.alert, .sound])`; `KubernetesViewModel.checkPodRestarts` calls `sendAlert` | n/a | n/a | Local only; no push token, no APNs/FCM | 3.4, 6.1.2, 12 / 3; `PushNotificationConsent.md` |
| 13 | Face ID / Touch ID / password user presence | Local, yes/no result from the OS | Unlock saved credentials | `LocalAuthentication` in `ObjectStoreDetailView`, `InstanceCredentialVault` | n/a | n/a | Keep the biometric sentence for this feature only | 3.4 / 3 |
| 14 | `os.Logger` entries | Local unified log (`error` and `warning` public) | Diagnose errors | `Utilities/Logger.swift` | OS-managed | n/a | One sentence; no upload | 3.2 / 2 |
| 15 | Analytics, crash reporting, attribution, advertising, A/B testing | Not present | n/a | No such code (README line 7; `grep` over `CivoCloudManager`, `Package.swift`, `project.yml`) | n/a | n/a | Keep the explicit negative list | 1.3, 3.5, 8a / 1, 4 |
| 16 | AI (OpenAI), user accounts, marketing email, social login, Fair Use telemetry, a cookie policy for the app | Not present | n/a | No such code or UI | n/a | n/a | Deleted; links to documents that are not bundled removed | 13, 12 |
| 17 | Publisher hosting of this app's cloud-management data | Not evidenced (support hosting is row 10) | n/a | No publisher backend call in the app code | n/a | n/a | Civo, Migadu and Storj are named only as providers for support requests, as in the published notice; no Google, OpenAI, RevenueCat or Microsoft | 6.1.1 / 4.6 |

## D4 proposal: legal bases and rights routing

Written from the owner's constraints and the published helpdesk notice (version 1.0.1). For review by Codex.

| Retained purpose | Basis written | Evidence |
|---|---|---|
| Providing the app and the cloud-management service the user requested | Art. 6(1)(b) GDPR | Rows 1 to 9; the purchase and the service are the contract |
| Handling support requests that concern that contract | Art. 6(1)(b) GDPR | Helpdesk notice 1.0.1 section 3 ("Where your enquiry concerns a contract with us") |
| Handling other support requests | Art. 6(1)(f) GDPR | Owner constraint; notice section 3 |
| Server logs of the support portal; security and integrity of the portal and of the products, including reports of security vulnerabilities | Art. 6(1)(f) GDPR | Owner constraint; notice section 3 |
| Records of data protection requests | Art. 6(1)(c) GDPR | Notice section 3. This basis is not in the owner's list of three; it is kept because the published notice states it. Reviewer to confirm or strike |
| Session cookie of the support portal | Not an Art. 6 basis: strictly necessary, § 25(2) no. 2 TDDDG and Art. 5(3) of Directive 2002/58/EC | Notice section 3 |
| macOS notification permission | No basis row, and no Art. 6(1)(a) consent. The permission is an operating system setting; the app does not collect a GDPR consent | `NotificationService.swift` |
| Accounts, marketing, analytics, service improvement | Rows deleted, no replacement | Row 15 and 16 |

The notice also gives Art. 6(1)(c) "where the law requires us to act on a report" for vulnerability reports. That clause is not repeated in the policy and is left to the reviewer.

Rights routing as written (bundled section 10.3, `PRIVACY.md` section 5.2): the publisher answers requests about support-request data and about other processing it carries out itself, and holds no data from the cloud-management features. Requests about data held by Apple (purchase and App Store data), Civo (the account and the requests made to it) or the IP lookup operators go to those parties under their own policies; the publisher points the user to them where asked.

## Section mapping of the bundled policy

"Shipped" is the text of 2.0.0 as it stood before this change, "incorporated" is text taken from 2.3.2 that was not in the shipped file, "removed" is text deleted because the matrix does not support it. A section equal to 2.3.2 apart from this table is marked "template".

| Section | Decision | Provenance |
|---|---|---|
| Header block, 2 data controller, 11, 14, 16, 6.2 to 6.4 | Kept as in the template | Shipped text equal to 2.3.2, except that 2 now carries the "either route" paragraph (incorporated) |
| 1, 1.1, 1.2 | Adapted | 1: names the app. 1.1: Apple App Store only. 1.2: last bullet without Google Play. Removed: Google Play wording |
| 1.3 | New | Scoped statement that the publisher operates no backend for cloud-management data, excluding the Support tab (rows 10, 15) |
| 3 data we collect | Adapted | Removed: account, payment information, usage and analytics data, social login, health, ATT, camera and similar entries. Added: rows 1 to 14 |
| 4 legal bases | Rewritten (D4) | Removed: account management, service improvement, marketing communications, optional analytics, tax records |
| 5 how we use data | Adapted | Removed: transactions and subscriptions, improving and personalizing, analytics |
| 6, 6.1, 6.1.1, 6.1.2 | Adapted | Removed: cloud hosting, payment processors, analytics providers, customer support tools; sub-processor rows for Google, OpenAI, RevenueCat, Microsoft; GA4 block; Google Play row; optional Sign in with Apple; APNs delivery. Kept from the published notice: Civo, Migadu, Storj as providers for support requests. Added: recipients you send data to by using the app |
| 7 transfers | Adapted | Removed: Google, OpenAI, RevenueCat, Microsoft bullets, GA4 bullet, the Standard Contractual Clauses bullet list (no remaining recipient relies on them; Storj has none). Kept: Civo, Migadu, Storj, Apple, controller outside the EEA |
| 8 retention | Adapted | Removed: account-based retention, billing records, logs 30/90 days, marketing subscribers. Added: local items and the support periods of the published notice |
| 8a (template 8b) | Adapted and renumbered | Removed: analytics, crash reporting and attribution rows, "every one of these is a separate switch". Kept: strictly necessary local storage. Added: support cookie and draft |
| 8a (template, health and fitness data) | Removed | The app processes no health data |
| 9, 9.1 | Adapted | Removed: server-side TLS 1.3 at rest, RBAC, MFA, daily backups, off-site replicas, account email for breach notices. Added: only measures the app implements, and the portal measures of the published notice |
| 10, 10.1, 10.2 | Template | Incorporated (not in the shipped file): the GDPR catalogue as global floor. Removed from the shipped file: 10.1 to 10.5 per-regime lists, which section 17 now carries |
| 10.3 | Adapted (D4) | Incorporated from 2.3.2; routing paragraph added |
| 12 cookies | Adapted | Removed: link to the Cookie Policy (not bundled) |
| 13 | Adapted | 13.1 kept with one added sentence. Removed: 13.2 AI-assisted features, 13.3 Fair Use, 13.4 marketing communications, 13.5 account deletion, and their links |
| 15 | Adapted | "by email" limited to where an email address is held from a support request |
| 17 intro, 17.2, 17.3, 17.6, 17.8, 17.12 | Template | Incorporated in part: 17.3 Switzerland, 17.6 Australia and New Zealand, 17.8 India, 17.12 South Africa; 17 intro and 17.2 United Kingdom |
| 17.1 | Adapted | Link to the Children's Privacy Notice removed |
| 17.4 United States | Adapted | Removed: consumer health data paragraph (link not bundled, no health data); CCPA table rebuilt from the matrix (the support portal is the only collection); "in-app deletion route" and "edit in-app" removed; `{{APP_DOMAIN}}` URL replaced |
| 17.5 Canada | Adapted | Removed: the claim that US transfers rest on SCCs and the DPF |
| 17.7 Brazil | Adapted | Legal bases rewritten, AI transfer and consent bullets removed, Children's Notice link removed |
| 17.9 Japan, 17.10 Korea, 17.11 Türkiye | Adapted | Removed: OpenAI, the AI consent screen, per-purpose toggles, age gate, AI-based US transfer consent; link to the Imprint routed to the bundled `Impressum.md` |
| 17.13 | Template | One word adapted (the App Store) |

Retained template text keeps its typographic dashes. The new passages written for this app use plain ASCII punctuation.

## Checked references

All checked with `curl -sI` and `-L` on 2026-11-23.

| URL | Result |
|---|---|
| https://www.civo.com/legal/privacy | 200 |
| https://www.civo.com/privacy | 301 to the URL above (not used in the texts) |
| https://www.apple.com/legal/privacy/ | 200 |
| https://digitalfreedom.co.za | 200 |
| https://data-protection.digitalfreedom.co.za | 301, then 200 at the helpdesk |
| https://support.apps.digitalfreedom.co.za | 301, then 200 at the helpdesk form |
| https://cppa.ca.gov/webapplications/complaint | 200 |
| https://www.priv.gc.ca | 200 |
| https://www.gov.br/anpd | 200 (redirects to the Portuguese page) |
| https://inforegulator.org.za | 200 |

Not checked: website legal pages and App Store Connect URLs (out of scope, unverified).

## Open decisions and follow-ups

| Item | Status |
|---|---|
| D1 support portal facts and notice URL | Answered by the owner and the public site, applied (row 10) |
| D2 source revision | Answered: 2.3.2, applied |
| D3 notifications document | Answered: replaced by a local-notifications notice in 16 languages |
| D4 legal bases and rights routing | Answered with constraints, proposal above awaiting review |
| `PrivacyInfo.xcprivacy` | Declares no collected data. The support page collects name, email and message in the embedded web view, which may conflict with that declaration. Not edited here; to be checked by the owner together with the App Store Connect privacy answers |
| Other bundled documents (scanned, not rewritten) | `TrademarkDisclaimer.md` section 1 and `AcceptableUsePolicy.md` section 1 say the apps are distributed via the Apple App Store and the Google Play Store (this app is App Store only; `EULA.md` section 20 already says so). `AcceptableUsePolicy.md` links `FAIR_USE_POLICY.md`, which is not bundled, and has an "AI invocations" column in its usage table. `TermsOfService.md` mentions accounts (section 3 and the notices clause, "address associated with your account") and "account deletion requests". `EULA.md` section 8 is generic and does not contradict the matrix. Each is a template carry-over for the owner to decide; the link guard therefore covers only the two documents this reconciliation owns |
| `legal` repository | Add a Civo Cloud Manager entry to `internal/PRODUCT_PROFILE.en.md` section 2a. No change made here |
| Helpdesk notice | The local-storage draft is recorded there as a convenience whose TDDDG assessment is open; the policy states the fact only |
