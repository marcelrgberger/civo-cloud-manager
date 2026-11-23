<!-- doc-id: PRIVACY_POLICY | lang: en | app-version: 2.3.0 | updated: 2026-11-23 | source-version: 2.3.2 | source: shared/PRIVACY_POLICY.en.md (legal repository commit cc9c4543cf0ed58be97cd3c9d38fc86781b04680) | adapted: company identity; app-specific data flows, legal bases, recipients, retention, rights routing, cookies and regional sections reconciled with docs/privacy-applicability.md -->
# PRIVACY POLICY

## Global Data Protection and Privacy Notice

**Effective Date:** 8 November 2026

**Service operated by:** DigitalFreedom — a brand of DigitalFreedom Global LLC

**Data Controller (legal entity):**
DigitalFreedom Global LLC (trading as DigitalFreedom)
30 N Gould St, Ste N
Sheridan, WY 82801
United States

Contact (general): hello@digitalfreedom.co.za
Contact (data protection): data-protection@digitalfreedom.co.za
Data protection request form: https://data-protection.digitalfreedom.co.za
Website: https://digitalfreedom.co.za

---

## 1. INTRODUCTION

This Privacy Policy explains how DigitalFreedom (a brand of DigitalFreedom Global LLC, collectively "we", "us", "our") collects, uses, stores, and protects your personal data when you use our applications, software, websites, and related services ("the Services"). This copy belongs to the macOS app Civo Cloud Manager ("the app").

### 1.1 Global scope

This app is distributed via the Apple App Store and is therefore made available in every country and territory the App Store serves. This Privacy Policy applies globally to all users of the app, regardless of the country in which it is downloaded, accessed or used.

### 1.2 GDPR as the global baseline

We adopt the **European Union General Data Protection Regulation (GDPR)** and related EU data-protection law as the baseline and apply it as a **global floor** — every user, in every country, benefits from at least the GDPR-level protections set out in this Policy. We additionally respect and comply with any applicable local data-protection law of the user's jurisdiction, and where that local law is more protective for the user, the more protective standard applies.

We are committed to protecting your privacy and complying with applicable data-protection laws, including but not limited to:

- EU General Data Protection Regulation (GDPR) — applied as the global baseline
- German Federal Data Protection Act (BDSG)
- UK General Data Protection Regulation (UK GDPR) and Data Protection Act 2018
- Swiss Federal Act on Data Protection (FADP)
- California Consumer Privacy Act (CCPA) / California Privacy Rights Act (CPRA) and other US state privacy laws
- Canadian Personal Information Protection and Electronic Documents Act (PIPEDA)
- Australian Privacy Act 1988
- Brazilian General Data Protection Law (LGPD)
- Japanese Act on the Protection of Personal Information (APPI)
- South Korean Personal Information Protection Act (PIPA)
- Indian Digital Personal Data Protection Act (DPDP Act) and IT Act
- South African Protection of Personal Information Act (POPIA)
- All other applicable national data-protection regimes in jurisdictions in which the Services are made available via the Apple App Store

### 1.3 What this app does with your data

Civo Cloud Manager manages your Civo cloud account from your Mac. It has no user accounts, no analytics, no crash reporting, no advertising and no tracking.

- The publisher operates no backend that receives the data you manage with the cloud-management features of the app. Your Civo API key, the settings of the app and the content of your requests stay on your Mac or go to the recipients you choose by using the app (section 6.1).
- This does not cover the Support tab. The Support tab shows a page of the publisher's support portal at https://support.apps.digitalfreedom.co.za inside the app. What happens to data you enter there is described in sections 3.1, 3.2, 6.1.1 and 8.

---

## 2. DATA CONTROLLER

The Services are offered under the **DigitalFreedom** brand. The legal entity responsible for processing your personal data (the "data controller" under Art. 4(7) GDPR) is:

DigitalFreedom Global LLC (trading as DigitalFreedom)
30 N Gould St, Ste N
Sheridan, WY 82801
United States

For data protection inquiries (GDPR Art. 13/14, access, rectification, erasure, portability, objection requests):
Request form: https://data-protection.digitalfreedom.co.za
Email: data-protection@digitalfreedom.co.za

You may use either route, and you are free to reach us by any other channel — we act on your request however it arrives.

For general inquiries:
Email: hello@digitalfreedom.co.za

Website: https://digitalfreedom.co.za

---

## 3. DATA WE COLLECT

### 3.1 Data You Provide

- **Support requests.** When you use the Support tab, the support portal collects only what you enter: your name, your email address and the description of your problem. It also receives the subject of your message, any attachments and any account context you choose to give us. If you use the separate route for reporting a security vulnerability, it receives the details of the vulnerability and your contact details. We use this solely to handle your request.
- **Cloud-management data.** Your Civo API key, the settings you make in the app and the resources you manage are not provided to us. They stay on your Mac or go to the recipients described in section 6.1.

### 3.2 Data Collected Automatically

- **Support tab.** When the portal is used, its web server records your IP address, the time, the page requested, the referring page and your browser's user agent. The portal sets one session cookie that keeps the form secure while you fill it in; it expires after two hours. While you type, a draft of your name, email address and message may be kept in the local storage of the embedded browser on your device; it is removed when you send the form.
- **Stored on your Mac and not received by us.** Your Civo API key (macOS keychain); saved instance credentials (data-protection keychain of this Mac, not synchronized, user presence required to read); encrypted SSH key backups and their master key (application support folder and keychain); the selected region, managed firewall settings, IP presets, launch-at-login and onboarding settings and the start date of the seven-day trial (user defaults); timed firewall closures and a cache of billing amounts of completed months (application support folder); and an activity log of your actions in the app (resource type, name, identifier, action and a short detail; no keys, headers or raw answers). The activity log keeps the newest 200 entries and drops older ones; it stays on your Mac until you delete the app's data.
- **System log.** The app writes to the unified log of macOS. Entries are managed by the operating system and are not uploaded by the app.

### 3.3 Data Exchanged with Third Parties at Your Direction

- **Civo.** The app sends requests, including your Civo API key as authentication, to the Civo API (api.civo.com) and, for the instance console, to the Civo console host. These requests reach Civo directly, not us.
- **Your own endpoints.** The app connects to the Kubernetes API server named in the kubeconfig of your cluster, using the client certificate in it, and to the S3-compatible endpoints of your object stores, using their access and secret keys. The app does not save the kubeconfig credentials itself.
- **Public IP lookup.** For the firewall features the app asks ipify (api.ipify.org), ifconfig.me and icanhazip.com, in this order of fallback, for your public IP address. These services see your IP address like any web server does.
- **Apple.** Your purchase of Full Access is handled by Apple through StoreKit. We receive no payment data. For this data Apple's own privacy policy applies (section 6.1.2). Apple does not handle the seven-day trial: the app computes it locally from the start date kept on your Mac.
- **Links.** Links to websites, such as digitalfreedom.co.za or civo.com, open in your browser.

### 3.4 Sensor, Device and Biometric Data

- **User presence (Face ID / Touch ID / password):** used to unlock saved credentials. The biometric template never leaves your device. The app only receives a yes/no result from the operating system.
- **Notifications:** the app asks macOS for permission to show alerts and play sounds and schedules notifications locally on your Mac. It registers no push token and receives no remote notifications.
- **Files you choose:** SSH private keys, kubeconfig files and object store downloads that you export are written to the location you pick in the system file dialog. These copies are outside the protection and the management of the app; it does not track, encrypt or delete them.

### 3.5 Data NOT Collected

The app does **not** collect or use:

- location, camera, microphone, contacts, calendar, photos or health data
- analytics, crash reports or telemetry
- advertising identifiers or any data for tracking you across other companies' apps and websites
- payment-card data (payment is collected by Apple; we never receive card details)

---

## 4. LEGAL BASIS FOR PROCESSING (GDPR)

We process your personal data based on the following legal grounds:

| Legal Basis | Purpose |
|---|---|
| **Contract performance** (Art. 6(1)(b) GDPR) | Providing the app and the cloud-management service you requested, and handling support requests that concern that contract |
| **Legitimate interests** (Art. 6(1)(f) GDPR) | Handling other support requests; security and integrity of the support portal, including its server logs, and of our products, including reports of security vulnerabilities |
| **Legal obligation** (Art. 6(1)(c) GDPR) | Records of data protection requests, to show that we handled your request properly (Art. 5(2) GDPR) |

The app asks for no consent under the GDPR. The permission that macOS asks for local notifications is a setting of the operating system, not a consent we collect or rely on. The session cookie of the support portal is strictly necessary to send the form (§ 25(2) no. 2 TDDDG and Art. 5(3) of Directive 2002/58/EC).

---

## 5. HOW WE USE YOUR DATA

We use your personal data to:

- Handle and answer your support requests, complaints, data protection requests and reports of security vulnerabilities
- Keep the support portal secure and find faults, using its server logs
- Comply with legal obligations

The app itself uses the data on your Mac only to provide the app. We do not use your data for analytics, advertising, marketing or to personalize the app.

---

## 6. DATA SHARING AND DISCLOSURE

### 6.1 Recipients You Send Data To by Using the App

The cloud-management features of the app send data directly from your Mac to the following recipients. We do not receive it. Each of them is responsible for its own processing, and requests about that data go to them:

- **Civo Ltd.** (api.civo.com and the Civo console host): the requests you make to manage your Civo account. Privacy policy: <https://www.civo.com/legal/privacy>.
- **The operators of your Kubernetes API servers and S3-compatible endpoints:** these are endpoints you or your organization configure.
- **ipify, ifconfig.me and icanhazip.com:** the operators of the public IP lookup services receive a standard web request, which includes your IP address.

### 6.1.1 Service Providers for Support Requests

When you send a request through the Support tab or write to one of our email addresses, the following providers process it on our behalf:

| Processor | Role | Location |
|---|---|---|
| Civo Limited | Hosts the support portal, its database and its backups | Frankfurt am Main, Germany and London, United Kingdom |
| Migadu-Mail GmbH | Hosts the email of the domain digitalfreedom.co.za | Servers in France (EU); company established in Switzerland |
| Storj | Keeps an additional copy of our backups, including the helpdesk database and attachments, outside Civo | United States (company); encrypted pieces on storage nodes in the EU |

The list of service providers may change; the current list is available on request via the data protection contact below.

### 6.1.2 Platform and Distribution Channel

Apple acts as an **independent controller** for processing carried out in connection with platform distribution, payment and platform-level services, not as our processor under Art. 28 GDPR. It is disclosed here for transparency:

| Party | Role | Location |
|---|---|---|
| Apple Distribution International Ltd. | App Store distribution; In-App Purchase / StoreKit (the Full Access purchase only; the app computes the seven-day trial locally, without Apple). **Seller of the purchase in the EU/EEA, UK, Switzerland and Türkiye**, and our agent elsewhere. **Not** push delivery: the app uses local notifications only and registers no push token. | Ireland (with intra-group processing by Apple Inc. in the United States under Apple's internal safeguards / SCCs) |

For data processed by Apple under its own controllership (Apple Account, payment details, App Store analytics), Apple's own Privacy Policy applies: <https://www.apple.com/legal/privacy/>.

### 6.2 Legal Requirements

We may disclose data when required by law, legal process, or government request.

### 6.3 Business Transfers

In the event of a merger, acquisition, or sale of assets, your data may be transferred.

### 6.4 No Sale of Personal Data

We do not sell your personal data to third parties.

---

## 7. INTERNATIONAL DATA TRANSFERS

The requests the app sends to Civo, to your own endpoints and to the IP lookup services go where you direct them; their location is that of the recipient.

For support requests, with regard to our named service providers:

- **Civo Frankfurt am Main (Germany)** and **Migadu's servers in France**: inside the EU, no transfer outside the EEA.
- **Civo London (United Kingdom)**: covered by the EU Commission adequacy decision for the UK pursuant to Art. 45 GDPR.
- **Migadu-Mail GmbH**: Migadu is established in Switzerland; access by the Swiss company is covered by the EU Commission adequacy decision for Switzerland pursuant to Art. 45 GDPR.
- **Storj (United States company; storage in the EU)** — the backup copy is uploaded through Storj's hosted gateway, which encrypts it on Storj's side, so Storj can access the data in readable form there; where that gateway runs has not been verified. The encrypted pieces are stored on storage nodes in the EU, because our bucket is placed in Storj's EU region. As Storj is a US company with access to the data, this is a transfer to a third country. **No data processing agreement and no Standard Contractual Clauses with Storj are in place at the date of this Policy**, and we do not rely on an adequacy decision for it. A request to Storj for a data processing agreement, the EU Standard Contractual Clauses and the UK Addendum has been prepared.
- **Apple (Apple Distribution International Ltd., Ireland; intra-group processing by Apple Inc., United States)** — Apple acts as **independent controller**. Intra-group transfers to Apple Inc. in the United States are governed by Apple's internal Binding Corporate Rules / SCCs as disclosed in the Apple Privacy Policy.

The Controller is established outside the EEA. Where personal data of users in the EEA is processed by the Controller itself, that processing takes place outside the EEA; the Controller applies the GDPR standard to it as a global baseline, as set out in section 1.2.

For transfers from other jurisdictions, we comply with applicable cross-border transfer requirements.

---

## 8. DATA RETENTION

We retain personal data only as long as necessary for the purposes described in this Policy.

**On your Mac (not received by us):**

- Your Civo API key, saved instance credentials, SSH key backups and master key, settings, trial start date, timed firewall closures and the cache of billing amounts stay on your Mac until you remove them or delete the app's data. The activity log keeps the newest 200 entries.
- Files you export (SSH private keys, kubeconfig files, object store downloads) are yours. The app does not track or delete them.

**Support requests:**

- Open tickets: until resolved. Closed tickets: 3 years from closure.
- Records of data protection requests: 6 years.
- Contact details from vulnerability reports: as long as the coordinated disclosure and our records require.
- Web server logs of the support portal: up to 15 days.
- The session cookie: 2 hours. The local draft: until you send the form or clear the browser storage.
- Database backups: 30 days, rolling. The copy at Storj follows our primary backup: what is deleted there is deleted at Storj the following night.

When the period ends, the data is deleted or anonymized. Recipients you send data to by using the app (Civo, the IP lookup services, the operators of your endpoints) and Apple keep it under their own retention rules. Jurisdiction-specific retention statements are in § 17.

---

## 8a. ACCESS TO INFORMATION ON YOUR DEVICE (APP)

Independently of data protection law, § 25(1) TDDDG and Art. 5(3) of Directive 2002/58/EC require your consent for storing information on your device or reading information already stored there, unless it is strictly necessary.

| What | When it happens | Basis |
|---|---|---|
| Settings, credentials, activity log and caches the app needs to work | Always, on your Mac | Strictly necessary; § 25(2) no. 2 TDDDG |
| Session cookie of the support portal | While you use the form in the Support tab; expires after two hours | Strictly necessary; § 25(2) no. 2 TDDDG |
| Draft of name, email address and message in the local storage of the Support tab | While you type; removed when you send the form | Stays on your device; a convenience so that nothing is lost if the page reloads |

**No advertising identifier is read.** The app displays no advertising and uses no analytics or attribution.

---

## 9. DATA SECURITY

The app implements the following measures:

- Your Civo API key is stored in the macOS keychain. Saved instance credentials are stored in the data-protection keychain of this Mac, are not synchronized, and require user presence to read. SSH key backups are stored encrypted, with their master key in the keychain.
- Requests to the Civo API use HTTPS.
- The app runs in the macOS App Sandbox with the Hardened Runtime.
- The app contains no telemetry.
- Files you export are not protected by the app (section 3.4).

For the support portal: connections are encrypted (TLS), the session cookie is sent only over encrypted connections and cannot be read by scripts, and access to tickets is restricted to the people who answer them.

No system is completely secure. We cannot guarantee absolute data security.

### 9.1 Breach Notification to You

In the event of a personal data breach **likely to result in a high risk** to your rights and freedoms (Art. 34 GDPR), we will notify you without undue delay, using the contact details you gave in your support request, including:

- nature of the breach
- categories and approximate number of records concerned
- likely consequences
- measures taken or proposed to address the breach and mitigate adverse effects
- contact details for further information

If individual notification would involve disproportionate effort, we make a public communication on https://digitalfreedom.co.za/.

---

## 10. YOUR RIGHTS

### 10.1 The GDPR catalogue, as the global floor

Wherever you live, you can exercise at least:

- **Access** to your personal data (Art. 15 GDPR)
- **Rectification** of inaccurate data (Art. 16)
- **Erasure** ("right to be forgotten") (Art. 17)
- **Restriction** of processing (Art. 18)
- **Data portability** (Art. 20)
- **Objection** to processing (Art. 21)
- **Withdrawal of consent** at any time, as easily as it was given (Art. 7(3))
- **A complaint** to a supervisory authority

### 10.2 What your jurisdiction adds

Several jurisdictions grant rights beyond this floor or attach different deadlines and procedures — appeal routes, shorter response periods, named officers. **§ 17 is the single place where those are stated, per jurisdiction.** Nothing in § 17 reduces the floor above.

### 10.3 How to exercise any of them

Email `data-protection@digitalfreedom.co.za` or use the request form at <https://data-protection.digitalfreedom.co.za>. We respond within one month (Art. 12(3) GDPR), or within the shorter period your jurisdiction prescribes, as stated in § 17.

**Who answers which request.** We answer requests about the data of your support requests and about any other processing we carry out ourselves. We hold no data from the cloud-management features of the app. Requests about data held by Apple (purchase and App Store data), by Civo (your Civo account and the requests you made to it) or by the operators of the IP lookup services go to those parties under their own privacy policies; we point you to them where you ask us.

---

## 11. CHILDREN'S PRIVACY

Our Services are not directed to children under the age of 16 (or the applicable age of consent in your jurisdiction).

We do not knowingly collect personal data from children. If we become aware that we have collected data from a child, we will take steps to delete it promptly.

---

## 12. COOKIES AND TRACKING

The app itself sets no cookies and uses no tracking technologies. The Support tab shows a page of the support portal in an embedded browser. That page uses one session cookie, which expires after two hours, and keeps a draft of your message in the local storage of the embedded browser until you send the form (sections 3.2 and 8a). The app has no cookie banner and no separate cookie policy because no analytics or advertising cookies are used.

---

## 13. AUTOMATED DECISION-MAKING

### 13.1 Automated decisions with legal or similarly significant effect

We do not engage in automated decision-making or profiling that produces legal effects concerning you or similarly significantly affects you, unless:

- You have given explicit consent
- It is necessary for contract performance
- It is authorized by applicable law

Where any such processing occurs, you have the right under Art. 22(3) GDPR to obtain human intervention, to express your point of view, and to contest the decision. The app has no AI-assisted features and sends no marketing communications.

---

## 14. THIRD-PARTY LINKS AND SERVICES

The Services may contain links to third-party websites or services. We are not responsible for the privacy practices of third parties.

---

## 15. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time.

- Material changes will be communicated via the Services or, where we hold your email address from a support request, by email
- Where a change to the processing requires your consent under applicable law, we will obtain that consent before the change applies to you; we do not rely on continued use alone as consent
- The "Effective Date" at the top reflects the latest revision

---

## 16. CONTACT

For privacy-related inquiries or to exercise your rights:

DigitalFreedom
A brand of DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
United States

Data protection: data-protection@digitalfreedom.co.za
Data protection request form: https://data-protection.digitalfreedom.co.za
General inquiries: hello@digitalfreedom.co.za
Website: https://digitalfreedom.co.za

For EU residents, you may also contact the competent supervisory authority in your member state.

---

## 17. REGIONAL PROVISIONS

What each jurisdiction adds to the global baseline of this Policy. § 10.1 states the floor that applies
everywhere; nothing below reduces it. Requests for any of the rights in this section:
`data-protection@digitalfreedom.co.za` or <https://data-protection.digitalfreedom.co.za>.

### 17.1 European Union and EEA

- Processing complies with the GDPR, which also applies in Norway, Iceland and Liechtenstein through the EEA Agreement.
- No lead supervisory authority applies: the Controller is not established in the Union, so the one-stop-shop under Art. 56 GDPR does not apply.
- You may lodge a complaint with the supervisory authority of your habitual residence, your place of work, or the place of the alleged infringement (Art. 77 GDPR) — in the EEA states that is Datatilsynet (Norway), Persónuvernd (Iceland) or the Datenschutzstelle (Liechtenstein).
- Data Protection Impact Assessments are conducted where required.
- The age of digital consent is set by Member States between 13 and 16; this Policy states no single number because none exists.

### 17.2 United Kingdom

- Processing complies with the UK GDPR and the Data Protection Act 2018.
- The supervisory authority is the Information Commissioner's Office (ICO).

### 17.3 Switzerland

- The revised Federal Act on Data Protection (revFADP) applies to circumstances that have an effect in Switzerland regardless of where the Controller sits. The GDPR baseline of this Policy covers its substance.
- **Right to information (Art. 25 revFADP):** substantially the access right of Art. 15 GDPR; we respond within 30 days.
- **Breach notification (Art. 24 revFADP):** owed to the FDPIC "as soon as possible". Our internal plan runs on the shorter of the applicable periods, so the GDPR's 72-hour clock governs in practice.
- Switzerland is recognised as adequate by the EU and recognises the EEA; transfers between them need no additional safeguard.
- The competent authority is the Federal Data Protection and Information Commissioner (FDPIC).

### 17.4 United States

**The state-law common core.** The comprehensive state statutes (Virginia, Colorado, Connecticut, Texas, Oregon and the wider family) grant substantially the rights in § 10.1, and add two things:

- **Appeal.** If we deny your request, you may appeal to us; our appeal response tells you how to complain to your State Attorney General. **Exception: Utah** (Utah Code § 13-61-203 provides no appeal process).
- **Deadlines.** We respond within **45 days**, extendable once by a further 45 with notice. **Exception: Iowa**, where the statute allows 90 days plus a 45-day extension (Iowa Code § 715D.3(3)) — in practice we apply the shorter period.

**Biometrics (Illinois BIPA).** No biometric identifier is collected. Face ID and Touch ID are handled by the operating system on your device; the app receives only a yes/no. If a feature ever collects a biometric identifier, BIPA's written-release, retention-schedule and destruction duties apply **before** the first collection.

**"Do Not Sell or Share" link.** Not required here: no personal information is sold or shared for cross-context behavioural advertising, because no advertising runs in the app and no advertising identifier is used. If that changes, the link becomes mandatory.

#### California — Notice at Collection (CCPA/CPRA)

Provided to California residents at or before the point of collection, as required by Cal. Civ. Code §§ 1798.100(a) and 1798.130(a)(5)(A). The full Privacy Policy this notice belongs to is this document.

**Categories collected in the past 12 months** (only through the support portal; the app itself sends us nothing):

| Category (CCPA § 1798.140(v)) | Examples we collect | Purpose | Disclosed for business purpose? | Sold or shared? |
|---|---|---|---|---|
| A. Identifiers | Name and email address you enter; IP address recorded by the web server | Handling your support request, security of the portal | Yes, to the service providers in § 6.1.1 | **No** |
| B. Customer records (Cal. Civ. Code § 1798.80(e)) | Name you enter | Handling your support request | Yes, to the service providers in § 6.1.1 | **No** |
| C. Characteristics of protected classifications | None | None | None | None |
| D. Commercial information | None (purchases are handled by Apple; we receive none) | None | None | None |
| E. Biometric information | None (Face ID / Touch ID is on-device only; the app receives yes/no) | None | None | None |
| F. Internet / electronic network activity | Time, page requested, referring page and browser user agent in the web server log | Security and fault finding | Yes, to the service providers in § 6.1.1 | **No** |
| G. Geolocation | None | None | None | None |
| H. Sensory information | None | None | None | None |
| I. Professional / employment information | None, unless you enter it in your message | None | None | None |
| J. Education information | None | None | None | None |
| K. Inferences from the above | None | None | None | None |
| L. Sensitive personal information (CCPA § 1798.140(ae)) | None collected by design; if you put such information in a message, it is used only to handle that request | Handling your support request | Yes, to the service providers in § 6.1.1 | **No** |

We have **not** sold or shared personal information of California residents in the past 12 months and do not intend to. The opt-out of sale or sharing therefore has no operative effect, but is available on request.

**Retention per category:** open tickets, until resolved; closed tickets, 3 years from closure; records of data protection requests, 6 years; web server logs, up to 15 days; backups, 30 days rolling (see § 8).

**Sensitive personal information, limit of use (§ 1798.121).** We use sensitive personal information only for the purposes permitted under CPRA Regs § 7027(m). Not for inferring characteristics, not for targeted advertising. The opt-out therefore has no operative effect, but is available on request.

**Your CCPA/CPRA rights:**

| Right | How to exercise |
|---|---|
| Know | Email `data-protection@digitalfreedom.co.za`, subject "CCPA Right to Know" |
| Delete | Same address |
| Correct | Same address |
| Opt out of sale/sharing | Not applicable (we do neither); confirmation on request |
| Limit sensitive-PI use | Not applicable (use is already limited); confirmation on request |
| Non-discrimination | We do not discriminate for exercising rights |
| Portability | Included in the Right-to-Know response, machine-readable |
| Authorized agent | Accepted with proof of authorisation and your written permission |

We verify requests proportionate to sensitivity and risk (CCPA Regs §§ 7060–7063) and respond within **45 days**, extendable once by 45 with notice.

**Shine the Light (§ 1798.83):** we disclose no personal information to third parties for their direct-marketing purposes; the annual response is "none disclosed".

**Global Privacy Control:** honoured as a valid opt-out signal (CPRA Regs § 7025). Because we neither sell nor share, it does not change our processing, but it is acknowledged.

**Complaints:** California Privacy Protection Agency, 2101 Arena Boulevard, Sacramento, CA 95834 — <https://cppa.ca.gov/webapplications/complaint> — or the California Attorney General.

### 17.5 Canada

- **Consent (PIPEDA Principle 3):** express consent where information is sensitive or the purpose not obvious; implied consent where it is obvious and not sensitive. Withdrawal at any time, subject to legal or contractual restrictions and reasonable notice.
- **Your PIPEDA rights:** access and a copy, accuracy challenge and correction, withdrawal of consent, and complaint to the Office of the Privacy Commissioner of Canada (<https://www.priv.gc.ca>). Response generally within 30 days (PIPEDA § 8(4)).
- **Quebec (Law 25):**
  - Person responsible for the protection of personal information: **Marcel R. G. Berger**, `data-protection@digitalfreedom.co.za`, 30 N Gould St, Ste N, Sheridan, WY 82801, United States.
  - Before personal information of Quebec residents is transferred outside Quebec, a privacy impact assessment (EFVP) is conducted (Law 25 § 17). Destinations: EEA, UK and Switzerland (adequate), and the United States, where the Controller accesses the data and for the backup copy described in § 7.
  - You may request your data in a structured, commonly used technological format (§ 27), request cessation of dissemination or de-indexing where dissemination seriously injures your reputation or privacy, and are informed of any decision based exclusively on automated processing with the right to human review — no such decisions are currently made.
  - Confidentiality incidents presenting a risk of serious injury are notified to the Commission d'accès à l'information and to you without delay.
  - A French version of any document is available on request; for Quebec residents the French version governs where Quebec law so requires.
- **CASL:** commercial electronic messages only with express opt-in, sender identification and a working unsubscribe processed within 10 business days.
- Provincial laws (BC PIPA, Alberta PIPA) apply where more protective. Complaints also to the OIPC BC and OIPC Alberta.

### 17.6 Australia and New Zealand

- **Australia:** the Privacy Act 1988 and the Australian Privacy Principles apply to an overseas entity carrying on business in Australia. APP 12 sets a **30-day** response period for access. APP 8 makes us accountable for an overseas recipient's handling of your data — stricter than a transfer analysis, and part of why recipients are named in § 6. Complaints: Office of the Australian Information Commissioner (OAIC).
- **New Zealand:** the Privacy Act 2020 applies to an overseas agency carrying on business in New Zealand. IPP 12 restricts disclosure outside New Zealand; access requests are answered within **20 working days**. Complaints: Office of the Privacy Commissioner (NZ).

### 17.7 Brazil (LGPD)

- **Encarregado (Art. 41 LGPD):** **Marcel R. G. Berger**, `data-protection@digitalfreedom.co.za`, 30 N Gould St, Ste N, Sheridan, WY 82801, United States. ANPD Resolution CD/ANPD No. 18/2024 permits the role to be performed for a foreign controller through the channels above; this Policy is the public publication of the Encarregado's contact details it requires.
- **Legal bases (Art. 7 and 11):** contract performance (V) for providing the app; legitimate interest (IX) for support and security; legal obligation (II) for the records of data protection requests. No consent is asked. Sensitive data only on explicit consent or another Art. 11 ground.
- **Your Art. 18 rights:** confirmation, access, correction, anonymisation/blocking/deletion of unnecessary or non-compliant data, portability, deletion of consent-based data, information about sharing and about the consequences of refusing consent, and revocation of consent. Response within **15 days** (Art. 19 § 3).
- **Transfers (Chapter V, Art. 33):** the recipients of support requests are named in § 6.1.1 and the position for each is set out in § 7: Civo's servers are in Germany and the United Kingdom, Migadu's in France, and Migadu is established in Switzerland. The support backup copy at Storj, a United States company, is a transfer to a third country for which no data processing agreement, no standard contractual clauses and no adequacy decision are in place (§ 7). That arrangement is unresolved, and this Policy names no transfer instrument for it. Apple acts as an independent controller for the Full Access purchase; its intra-group safeguards (§ 7) cover Apple's own processing only, not our support backups.
- **Children (Art. 14):** processing of a child's data (under 12) requires specific and prominent parental consent; no such mechanism is operated, and the app is not directed at children.
- **Incidents (Art. 48):** the ANPD and affected data subjects are notified; our target is 72 hours, aligned with Art. 33 GDPR.
- **Complaints:** Autoridade Nacional de Proteção de Dados — <https://www.gov.br/anpd>. A Portuguese version of this section is available on request.

### 17.8 India (DPDP Act, 2023)

- DigitalFreedom Global LLC is the Data Fiduciary; it is not designated a Significant Data Fiduciary.
- **Consent (§ 6):** free, specific, informed, unconditional and unambiguous, by clear affirmative action, limited to what the purpose needs, withdrawable as easily as given. Service is not conditioned on consent the purpose does not need.
- **Your rights (§§ 11–14):** access to what is processed and with whom it is shared; correction, completion and erasure; grievance redressal; and nomination of another person to exercise your rights in case of death or incapacity.
- **Grievance Officer (§ 8(10), IT Rules 2021):** **Marcel R. G. Berger**, `data-protection@digitalfreedom.co.za`. Acknowledgement within 24 hours; resolution within 15 days, extended to 30 for complex grievances with explanation. Escalation: the Data Protection Board of India, once constituted.
- **Children (§ 9):** data of a person under 18 is processed only with verifiable parental or guardian consent; no tracking, behavioural monitoring or targeted advertising directed at children.
- **Transfers (§ 16):** permitted save to destinations notified as restricted; none of the destinations used (EEA, UK, Switzerland, US) is currently restricted.
- Notices are available in English; a Hindi or other Eighth-Schedule-language version can be requested at `hello@digitalfreedom.co.za`.

### 17.9 Japan (APPI)

- The APPI applies to a foreign operator that acquires personal information in connection with supplying goods or services to persons in Japan; this Service is therefore covered.
- **Purpose specification:** the purpose of use is specified as narrowly as possible and notified or published at acquisition. A change of purpose is limited to what remains relevantly connected to the original purpose; a larger change requires fresh consent.
- **Third-party provision, and provision to third parties in a foreign country:** the APPI requires your consent as a rule for provision to a third party. For a third party in a foreign country, the consent must be preceded by information on **(1) the name of the country, (2) that country's personal-information protection system, and (3) the measures the recipient takes to protect personal information.** This describes the legal requirement, not a verified procedure. The support portal offers a general control to accept this Policy before a request is sent; we have not established that it presents this information or records a separate consent for the provision, and this Policy does not claim that it does. Support requests are processed by the service providers named in § 6.1.1, in the countries stated in §§ 6.1.1 and 7. How the support portal handles consent for these recipients is an open follow-up.
- **Publicly available matters (Art. 32):** the operator's name and address and its representative's name, the purposes of use, the procedures for disclosure requests and the complaint contact are kept in your reach — through this Policy and the [Impressum](Impressum.md). Representative: **Marcel R. G. Berger**.
- **Breach reporting:** for the reportable categories, a preliminary report to the Personal Information Protection Commission within roughly 3–5 days and a final report within 30 days (60 for breaches caused by wrongful access); you are notified. Our internal plan runs on the shortest applicable deadline.
- No advertising email is sent (特定電子メール法 — opt-in, sender identification, unsubscribe — would otherwise apply).

### 17.10 Korea (PIPA)

- PIPA applies to a foreign operator processing personal information in the course of offering goods or services to data subjects in Korea; this Service is therefore covered.
- **Itemised, separated consent (legal requirement):** PIPA requires consent to be obtained separately per item, with required and optional items distinguished, and each request to state the items collected, the purpose, the retention period, the right to refuse and the consequence of refusal. This describes the law, not a verified procedure. The support portal offers a general control to accept this Policy before a request is sent; we have not established that it separates items, distinguishes required from optional items or carries these statements, and this Policy does not claim that it does. The mechanism of the support portal is an open follow-up.
- **Cross-border transfer (legal requirement):** PIPA requires notice of **the recipient, the destination country, the date and method of transfer, the items transferred, the recipient's purpose and retention period**, and your separate consent for a transfer abroad. For support requests, the recipients and countries are stated in §§ 6.1.1 and 7, the items are your name, email address and message, the purpose is handling your request, and the retention periods are stated in § 8. We have not established that the support portal obtains a separate consent for the transfer abroad; this is an open follow-up, and this Policy does not claim that it does.
- **Under 14:** processing a child's data requires the legal representative's consent, with only the minimum information collected to verify it. The app is not directed at children.
- **Response period:** access, correction/deletion and suspension requests are acted on within **10 days**, or you are told the reason and schedule. That is shorter than the GDPR month, and the shorter period governs.
- **Breach:** you are notified without delay; above the statutory scale, the Personal Information Protection Commission or the designated agency is notified within **72 hours**.

### 17.11 Türkiye (KVKK)

- The KVKK (Law No. 6698) resembles the GDPR in concept but leans harder on explicit consent as the general basis; each processing activity is assessed against Turkish law separately rather than assumed to carry over from an Art. 6(1)(f) analysis.
- **Transfers abroad:** the app transmits no personal data to us outside the Support tab. Where support requests are processed is stated in § 7.
- **Response period:** requests are answered within **30 days**. You may complain to the Personal Data Protection Board (Kişisel Verileri Koruma Kurulu, Art. 14 KVKK) after applying to us first — within 30 days of our response or 60 days of your application.
- The Turkish version of the published documents governs for consumers resident in Türkiye.

### 17.12 South Africa (POPIA)

POPIA § 3(1) applies to a responsible party domiciled in the Republic, or processing by means located there. Neither is the case — the Controller is domiciled in Wyoming and processes on servers in Frankfurt and London, with an off-provider backup copy on Storj storage nodes in the EU (§ 7), and a `.co.za` domain name is a name, not a processing means. **The Act therefore does not apply on the present facts.** Every POPIA-style enquiry is nonetheless answered through the same channels and on the same clock as everywhere else — a service commitment, not an admission that the Act applies. Two points where POPIA would differ from the GDPR floor, stated rather than papered over: POPIA treats everyone under 18 as a child, and § 22(1) requires breach notification without the GDPR's high-risk threshold — the breach plan operates on the GDPR standard. The Information Regulator: JD House, 27 Stiemens Street, Braamfontein, Johannesburg, 2001 — <https://inforegulator.org.za>.

### 17.13 All other countries

Everywhere the App Store distributes and no section above applies: the GDPR baseline of this Policy is your floor (§ 1.2), any more protective mandatory local law prevails over it, and every request goes through `data-protection@digitalfreedom.co.za` or <https://data-protection.digitalfreedom.co.za>.

---

(c) 2025-2026 DigitalFreedom Global LLC. All rights reserved.
