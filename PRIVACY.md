# Privacy Policy

**Civo Cloud Manager**
Last Updated: November 23, 2026
Effective Date: 8 November 2026

DigitalFreedom Global LLC ("we", "us", "our") publishes the macOS app Civo Cloud Manager ("Application"). This Privacy Policy describes how data is handled in connection with the Application. The full text shown in the Application (Legal > Privacy Policy, in 16 languages) is the same policy; it adds the complete regional provisions (section 17 there). Which data flows exist, and the evidence for each, is documented in [docs/privacy-applicability.md](docs/privacy-applicability.md).

---

## 1. Scope: What We Receive and What We Do Not

**We operate no backend that receives the data you manage with the cloud-management features of the Application.** Your Civo API key, the settings of the Application and the content of your requests stay on your Mac or go directly to the recipients you choose by using the Application (section 4). The Application has no user accounts, no analytics, no crash reporting, no advertising and no tracking.

**This does not cover the Support tab.** The Support tab shows a page of the publisher's support portal at https://support.apps.digitalfreedom.co.za inside the Application. The support portal collects only what you enter (your name, your email address and the description of your problem, plus the subject, any attachments and any account context you choose to give), solely to handle your support request. The notice shown on that portal is the "Privacy Policy - Helpdesk" (effective 14 October 2026); it is displayed and accepted in the portal itself. When the portal is used:

- the web server records your IP address, the time, the page requested, the referring page and your browser's user agent;
- one session cookie keeps the form secure while you fill it in, and expires after two hours;
- a draft of your name, email address and message may be kept in the local storage of the embedded browser on your device, and is removed when you send the form.

Recipients, retention and your rights for support requests are in sections 4.6, 5 and 7.

---

## 2. Data Stored on Your Device

The Application stores the following data locally on your macOS device. None of it is sent to us.

| Data | Storage Location | Purpose |
|------|-----------------|---------|
| Civo API key | macOS Keychain | Authenticate with the Civo API |
| Saved instance credentials | Data-protection keychain of this Mac, not synchronized, user presence required to read | Access to your instances |
| SSH key backups and their master key | Encrypted files in the Application Support folder; master key in the Keychain | Keep a copy of keys created in the Application |
| Selected region, managed firewalls, IP presets, launch at login, onboarding state | UserDefaults | Remember settings |
| Start date of the seven-day trial | UserDefaults | Compute the trial period |
| Activity log (resource type, name, identifier, action, short detail; no keys, headers or raw answers) | UserDefaults; newest 200 entries, older entries are dropped | Show your recent actions |
| Timed firewall closures; cache of billing amounts of completed months | Files in the Application Support folder | Close firewall access on time; avoid repeated requests |
| Kubeconfig credentials of a cluster | Used in memory for the connection; the Application does not save them itself | Connect to the Kubernetes API |
| Purchase status | StoreKit (Apple managed) | Verify the Full Access purchase and the trial |
| System log entries | Unified log of macOS, managed by the operating system | Diagnose errors; not uploaded |

Files you export (SSH private keys, kubeconfig files, object store downloads) are written where you choose, with the system file dialog. They are outside the protection and the management of the Application, which does not track, encrypt or delete them.

---

## 3. Permissions

The Application requests the following system permissions:

| Permission | Purpose | Data Sent Externally |
|-----------|---------|---------------------|
| Network Access (App Sandbox) | Connect to Civo, your Kubernetes and S3 endpoints, the IP lookup services and the Support tab | Requests to those recipients (section 4) |
| Keychain Access | Store your Civo API key and saved credentials | None |
| User-selected files (read and write) | Export and import files you choose | None |
| Notifications (alerts and sounds) | Show local notifications on your Mac | None; no push token is registered and no remote push is used |
| Face ID / Touch ID / password (user presence) | Unlock saved credentials; the Application receives only a yes/no result | None |

The Application does **not** request or use:
- Location services
- Camera or microphone
- Contacts or calendar
- Health data
- Tracking or advertising identifiers
- Remote push notifications (APNs, FCM)

---

## 4. Recipients and Third-Party Services

### 4.1 Civo (api.civo.com and the Civo console host)
- **Purpose**: Manage your Civo Cloud infrastructure (clusters, databases, instances, firewalls, etc.), and open the instance console
- **Data sent**: Your Civo API key (as authentication header) and your resource management requests
- **Recipient**: Civo Ltd., which is responsible for its own processing. Privacy policy: https://www.civo.com/legal/privacy

### 4.2 Kubernetes API Servers
- **Purpose**: Access cluster nodes, pods and logs
- **Data sent**: The client certificate credentials from your kubeconfig, to the API server named in it
- **Note**: The API server address is determined by your cluster configuration

### 4.3 S3-Compatible Object Storage Endpoints
- **Purpose**: Browse and transfer files in your object stores
- **Data sent**: Requests signed with the access and secret key of your object store, to the endpoint you configured

### 4.4 IP Detection Services
- **Purpose**: Detect your public IPv4 address for firewall rule management
- **Services used**: ipify.org, ifconfig.me, icanhazip.com (fallback chain)
- **Data sent**: A standard HTTP request; your IP address is inherently visible to these services
- **Data received**: Your public IPv4 address

### 4.5 Apple App Store / StoreKit
- **Purpose**: Process the one-time Full Access purchase and verify the entitlement; the seven-day trial itself is tracked locally
- **Data sent**: Managed entirely by Apple's StoreKit framework
- **Note**: We do not receive payment information. Apple acts as an independent controller; Apple's privacy policy applies: https://www.apple.com/legal/privacy/

### 4.6 Support Portal (Support tab and email)
- **Purpose**: Handle your support request
- **Data processed**: As described in section 1
- **Service providers acting on our behalf**: Civo Limited (hosts the support portal, its database and its backups, in Frankfurt am Main and London); Migadu-Mail GmbH (hosts the email of the domain digitalfreedom.co.za, on servers in France); Storj (keeps an additional copy of our backups, including the helpdesk database and attachments; a United States company, with encrypted pieces on storage nodes in the EU; no data processing agreement and no Standard Contractual Clauses are in place at the date of this policy)

### 4.7 Links
Links to websites such as digitalfreedom.co.za or civo.com open in your browser.

We do **not** use any:
- Analytics SDKs
- Crash reporting SDKs
- Advertising SDKs
- Attribution SDKs
- A/B testing frameworks
- Social media SDKs

---

## 5. Legal Bases and Your Rights

### 5.1 Controller and legal bases

The controller is DigitalFreedom Global LLC (section 10). The legal bases under the GDPR are:

- Art. 6(1)(b) GDPR (contract): providing the Application and the cloud-management service you requested, and handling support requests that concern that contract.
- Art. 6(1)(f) GDPR (legitimate interests): handling other support requests; security and integrity of the support portal, including its server logs, and of our products, including reports of security vulnerabilities.
- Art. 6(1)(c) GDPR (legal obligation): records of data protection requests.

The Application asks for no consent under the GDPR. The permission that macOS asks for local notifications is a setting of the operating system, not a consent we collect or rely on. No Data Protection Officer is appointed, because the threshold for a mandatory appointment under Art. 37 GDPR is not met.

### 5.2 Your rights, and who answers

Wherever you live, you have at least these rights under the GDPR: access, rectification, erasure, restriction, data portability, objection, withdrawal of consent and a complaint to a supervisory authority. Write to data-protection@digitalfreedom.co.za or use https://data-protection.digitalfreedom.co.za. We answer within one month, or within the shorter period your jurisdiction sets.

We answer requests about the data of your support requests and about any other processing we carry out ourselves. We hold no data from the cloud-management features. Requests about data held by Apple (purchase and App Store data), by Civo or by the operators of the IP lookup services go to those parties under their own privacy policies; we point you to them where you ask us.

### 5.3 Regional provisions

These are the same as in section 17 of the policy shown in the Application. Nothing there reduces the rights in section 5.2.

| Region | What applies |
|---|---|
| EU and EEA | GDPR. There is no lead supervisory authority; you can complain to the authority where you live, work or where the alleged infringement took place (Art. 77 GDPR) |
| United Kingdom | UK GDPR and Data Protection Act 2018; authority: Information Commissioner's Office (ICO) |
| Switzerland | Revised Federal Act on Data Protection; information requests answered within 30 days; authority: FDPIC |
| United States | State privacy laws: responses within 45 days (extendable once by 45), appeal if a request is denied (not in Utah). We do not sell or share personal information. California: Notice at Collection in section 17.4 of the policy; complaints to the California Privacy Protection Agency or the Attorney General |
| Canada | PIPEDA, responses generally within 30 days; Quebec Law 25 provisions in section 17.5 of the policy; authority: Office of the Privacy Commissioner of Canada |
| Australia and New Zealand | Access requests answered within 30 days (Australia) and 20 working days (New Zealand); complaints to the OAIC and the Office of the Privacy Commissioner |
| Brazil | LGPD, responses within 15 days; contact for data subjects: Encarregado named in section 17.7 of the policy; authority: ANPD |
| India | DPDP Act; grievance officer named in section 17.8 of the policy, acknowledgement within 24 hours, resolution within 15 days |
| Japan | APPI; section 17.9 of the policy |
| Korea | PIPA; requests acted on within 10 days; section 17.10 of the policy |
| Türkiye | KVKK; requests answered within 30 days; section 17.11 of the policy |
| South Africa | POPIA does not apply on the present facts; every enquiry is nonetheless answered through the same channels and on the same clock (section 17.12 of the policy) |
| All other countries | The GDPR baseline is your floor; any more protective mandatory local law prevails |

### 5.4 Children

The Application is not directed at children under 16, or under the age of consent that applies in your jurisdiction. If we learn that we hold data of a child, we delete it promptly. If you are a parent or guardian and believe your child has provided data, contact us at hello@digitalfreedom.co.za.

---

## 6. Data Security

- **API Key Storage**: Your Civo API key is stored in the macOS Keychain. Saved instance credentials are stored in the data-protection keychain of this Mac, are not synchronized and require user presence to read. SSH key backups are stored encrypted, with their master key in the Keychain.
- **Network Communication**: Requests to the Civo API use HTTPS.
- **App Sandbox**: The Application runs within the macOS App Sandbox, restricting access to system resources
- **Hardened Runtime**: The Application uses the macOS Hardened Runtime
- **No Telemetry**: No usage data, analytics or crash reports are transmitted
- **Exported files**: Files you export are not protected by the Application
- **Support portal**: Connections are encrypted (TLS), the session cookie is sent only over encrypted connections and cannot be read by scripts, and access to tickets is restricted to the people who answer them

No system is completely secure.

---

## 7. Data Retention

**On your Mac:** your Civo API key, saved instance credentials, SSH key backups, settings, trial start date, timed firewall closures and the cache of billing amounts stay on your Mac until you remove them or delete the Application's data; the activity log keeps the newest 200 entries. Files you export are yours; the Application does not track or delete them. Recipients you send data to by using the Application, and Apple, keep it under their own retention rules.

**Support requests:**
- Open tickets: until resolved. Closed tickets: 3 years from closure.
- Records of data protection requests: 6 years.
- Contact details from vulnerability reports: as long as the coordinated disclosure and our records require.
- Web server logs of the support portal: up to 15 days.
- The session cookie: 2 hours. The local draft: until you send the form or clear the browser storage.
- Database backups: 30 days, rolling. The copy at Storj follows our primary backup: what is deleted there is deleted at Storj the following night.

---

## 8. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Material changes will be communicated via the Application or, where we hold your email address from a support request, by email. Where a change to the processing requires your consent under applicable law, we will obtain that consent before the change applies to you; we do not rely on continued use alone as consent. The "Effective Date" at the top reflects the latest revision, and "Last Updated" the day it was made.

---

## 9. Dispute Resolution

The European Commission's Online Dispute Resolution platform ceased operation on 20 July 2025. Regulation (EU) 2024/3228 repealed Regulation (EU) No 524/2013, under which the platform had been established. Consumers may contact us directly at hello@digitalfreedom.co.za or approach a competent alternative dispute resolution body in their country of residence.

We are neither obligated nor willing to participate in dispute resolution proceedings before a consumer arbitration board (Verbraucherschlichtungsstelle) pursuant to the German Consumer Dispute Resolution Act (VSBG), unless required by law.

---

## 10. Contact

If you have questions about this Privacy Policy or our privacy practices:

DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
United States
Email: hello@digitalfreedom.co.za
Web: https://digitalfreedom.co.za

For data protection inquiries: data-protection@digitalfreedom.co.za
Request form: https://data-protection.digitalfreedom.co.za

---

Copyright (c) 2026 DigitalFreedom Global LLC. All rights reserved.
