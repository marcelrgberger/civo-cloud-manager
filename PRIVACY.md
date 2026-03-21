# Privacy Policy

**Civo Cloud Manager**
Last Updated: March 21, 2026
Effective Date: March 21, 2026

Marcel R. G. Berger, operating as Berger & Rosenstock GbR ("we", "us", "our"), is committed to protecting your privacy. This Privacy Policy describes how we handle information in connection with the Civo Cloud Manager application ("Application").

---

## 1. Zero Data Collection Policy

**We do not collect, store, transmit, or process any personal data on our servers.**

The Application operates entirely on your device. All configuration, credentials, and preferences are stored locally. We have no servers that receive your data. We do not operate any backend infrastructure for data collection.

---

## 2. Data Stored on Your Device

The Application stores the following data locally on your macOS device:

| Data | Storage Location | Purpose | Sent to Our Servers |
|------|-----------------|---------|-------------------|
| Civo API Key | macOS Keychain (encrypted) | Authenticate with Civo Cloud API | No |
| Selected Region | UserDefaults | Remember active region | No |
| Managed Firewalls | UserDefaults (JSON) | Track firewall configurations | No |
| Launch at Login | UserDefaults | Persist auto-start preference | No |
| Onboarding State | UserDefaults | Track setup completion | No |
| Kubeconfig Credentials | In-memory only | Connect to Kubernetes API | No |
| Purchase Status | StoreKit (Apple managed) | Verify subscription | No |

---

## 3. Permissions

The Application requests the following system permissions:

| Permission | Purpose | Data Sent Externally |
|-----------|---------|---------------------|
| Network Access (App Sandbox) | Connect to Civo API, Kubernetes API, and IP detection services | API requests to services you configure |
| Keychain Access | Securely store your Civo API key | None |

The Application does **not** request or use:
- Location services
- Camera or microphone
- Contacts or calendar
- Health data
- Tracking or advertising identifiers
- Push notifications
- Background execution beyond standard app lifecycle

---

## 4. Third-Party Services

The Application communicates directly with the following third-party services at your explicit direction:

### 4.1 Civo Cloud API (api.civo.com)
- **Purpose**: Manage your Civo Cloud infrastructure (clusters, databases, instances, firewalls, etc.)
- **Data sent**: Your Civo API key (as authentication header), resource management requests
- **Privacy policy**: https://www.civo.com/privacy

### 4.2 Kubernetes API Servers
- **Purpose**: Access cluster nodes, pods, and logs
- **Data sent**: Client certificate credentials from your kubeconfig
- **Note**: The API server address is determined by your cluster configuration

### 4.3 IP Detection Services
- **Purpose**: Detect your public IPv4 address for firewall rule management
- **Services used**: ipify.org, ifconfig.me, icanhazip.com (fallback chain)
- **Data sent**: Standard HTTP request (your IP address is inherently visible to these services)
- **Data received**: Your public IPv4 address

### 4.4 Apple App Store / StoreKit
- **Purpose**: Process in-app purchases, verify entitlements
- **Data sent**: Managed entirely by Apple's StoreKit framework
- **Note**: We do not collect, store, or access any payment information

We do **not** use any:
- Analytics SDKs (no Google Analytics, Firebase, Mixpanel, etc.)
- Crash reporting SDKs (no Crashlytics, Sentry, Bugsnag, etc.)
- Advertising SDKs (no AdMob, Facebook Ads, etc.)
- Attribution SDKs (no AppsFlyer, Adjust, Branch, etc.)
- A/B testing frameworks
- Social media SDKs

---

## 5. International Privacy Law Compliance

### 5.1 GDPR (European Union / European Economic Area)
Regulation (EU) 2016/679 — General Data Protection Regulation

As the Application does not collect or process personal data, the Licensor does not act as a data controller or data processor under the GDPR. No personal data is transmitted to our servers. Should this change in any future version, we will:
- Obtain explicit consent or establish another lawful basis for processing
- Implement all required data subject rights (access, rectification, erasure, portability, restriction, objection)
- Conduct data protection impact assessments where required
- Appoint a Data Protection Officer if required
- Implement appropriate technical and organizational measures
- Comply with cross-border data transfer requirements

**Legal basis**: Not applicable (no data processing occurs).
**Data Protection Officer**: Not required (no systematic monitoring or large-scale processing).
**EU Representative**: Not required (no data processing of EU residents' personal data).

### 5.2 UK GDPR (United Kingdom)
UK General Data Protection Regulation (as incorporated by the Data Protection Act 2018)

The Application complies with UK GDPR requirements. No personal data of UK residents is collected, processed, or transferred. The Information Commissioner's Office (ICO) is the relevant supervisory authority for UK users.

### 5.3 CCPA / CPRA (California, USA)
California Consumer Privacy Act (Cal. Civ. Code 1798.100 et seq.) and California Privacy Rights Act

- We do **not** sell personal information
- We do **not** share personal information for cross-context behavioral advertising
- We do **not** collect personal information as defined under CCPA/CPRA
- California residents have the right to know, delete, correct, and opt-out. As we collect no personal information, these rights are satisfied by default
- We do **not** use sensitive personal information
- We do **not** engage in profiling or automated decision-making

### 5.4 LGPD (Brazil)
Lei Geral de Protecao de Dados Pessoais (Law No. 13,709/2018)

The Application does not process personal data of Brazilian residents. No personal data is collected, used, processed, stored, or transferred. Brazilian users have rights under LGPD including access, correction, anonymization, portability, deletion, and information about sharing — all of which are satisfied by our zero-collection policy.

### 5.5 PIPEDA (Canada)
Personal Information Protection and Electronic Documents Act (S.C. 2000, c. 5)

The Application does not collect personal information as defined under PIPEDA. No personal information is collected, used, or disclosed. Canadian users retain all rights under PIPEDA.

### 5.6 Australian Privacy Act 1988
Privacy Act 1988 (Cth), including the Australian Privacy Principles (APPs)

The Application does not collect personal information as defined under the Privacy Act. We comply with all Australian Privacy Principles. Australian users have the right to access and correct their personal information — as we collect none, these rights are satisfied by default.

### 5.7 APPI (Japan)
Act on the Protection of Personal Information (Act No. 57 of 2003, as amended 2022)

The Application does not handle personal information of Japanese users. No personal information is acquired, used, or provided to third parties. We comply with all obligations under the APPI.

### 5.8 PIPA (South Korea)
Personal Information Protection Act (Act No. 10465, as amended)

The Application does not process personal information of South Korean users. We do not collect, use, provide, or manage personal information as defined under PIPA.

### 5.9 PDPA (Singapore / Thailand)
Personal Data Protection Acts of Singapore (No. 26 of 2012) and Thailand (B.E. 2562, 2019)

The Application does not collect or process personal data of users in Singapore or Thailand. We comply with the consent, purpose limitation, and data protection requirements of both jurisdictions.

### 5.10 PIPL (China)
Personal Information Protection Law of the People's Republic of China (effective November 1, 2021)

The Application does not process personal information of users in China. No personal information is collected, stored, or transferred outside of the user's device. We comply with all applicable PIPL requirements.

### 5.11 COPPA (USA)
Children's Online Privacy Protection Act (15 U.S.C. 6501-6506)

The Application is not directed at children under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided personal information, we will take immediate steps to delete such information. If you are a parent or guardian and believe your child has provided personal information, please contact us at hello@marcelrgberger.com.

### 5.12 Other Jurisdictions

For users in jurisdictions not specifically listed above: The Application's zero-data-collection approach ensures compliance with the data minimization and purpose limitation principles common to all modern privacy frameworks. If your local law provides additional rights, those rights are respected.

---

## 6. Data Security

Although we do not collect your data, we implement the following security measures within the Application:

- **API Key Storage**: Your Civo API key is stored in the macOS Keychain, which provides hardware-backed encryption
- **Kubeconfig Credentials**: Stored only in memory during active sessions, never persisted to disk
- **Network Communication**: All API communications use HTTPS/TLS encryption
- **App Sandbox**: The Application runs within macOS App Sandbox, restricting access to system resources
- **Hardened Runtime**: The Application uses macOS Hardened Runtime for additional security
- **No Telemetry**: No usage data, analytics, or crash reports are transmitted

---

## 7. Data Retention

We retain no data. All Application data is stored locally on your device and is under your sole control. Uninstalling the Application removes all locally stored data, except for Keychain items which may need to be manually removed via Keychain Access.

---

## 8. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Material changes will be communicated at least thirty (30) days before they take effect, through the Application or via the App Store listing. The "Last Updated" date at the top of this policy indicates when the latest revision was made.

We will not retroactively change our privacy practices to collect data without obtaining your explicit consent.

---

## 9. EU Online Dispute Resolution

The European Commission provides an online dispute resolution platform at:
https://ec.europa.eu/consumers/odr

We are not obligated to participate in dispute resolution proceedings before a consumer arbitration board, but may choose to do so on a case-by-case basis.

---

## 10. Contact

If you have questions about this Privacy Policy or our privacy practices:

**Marcel R. G. Berger**
**Berger & Rosenstock GbR**
Email: hello@marcelrgberger.com
Web: https://berger-rosenstock.de

For data protection inquiries: hello@marcelrgberger.com

---

Copyright (c) 2026 Marcel R. G. Berger / Berger & Rosenstock GbR. All rights reserved.
