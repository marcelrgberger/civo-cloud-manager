# Privacy Policy

## Civo Cloud Manager

**Effective Date:** April 2026
**Last Updated:** April 2026

**Data Controller:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Germany
Email: moin@berger-rosenstock.de

---

## 1. Introduction

This Privacy Policy explains how Marcel R. G. Berger, operating as Berger & Rosenstock GbR ("we", "us", "our"), handles information in connection with the Civo Cloud Manager application ("the Application").

We are committed to protecting your privacy and complying with applicable data protection laws, including but not limited to:

- EU General Data Protection Regulation (GDPR, Regulation (EU) 2016/679)
- German Federal Data Protection Act (BDSG)
- UK General Data Protection Regulation (UK GDPR) and Data Protection Act 2018
- Swiss Federal Act on Data Protection (FADP / revDSG)
- California Consumer Privacy Act (CCPA) and California Privacy Rights Act (CPRA)
- Virginia Consumer Data Protection Act (VCDPA), Colorado Privacy Act (CPA), Connecticut Data Privacy Act (CTDPA), Utah Consumer Privacy Act (UCPA), and other US state laws
- Canadian Personal Information Protection and Electronic Documents Act (PIPEDA) and provincial laws
- Australian Privacy Act 1988 and Australian Privacy Principles (APPs)
- Brazilian General Data Protection Law (LGPD, Law No. 13.709/2018)
- Japanese Act on the Protection of Personal Information (APPI)
- South Korean Personal Information Protection Act (PIPA)
- Singapore Personal Data Protection Act (PDPA)
- Thailand Personal Data Protection Act (PDPA 2019)
- Chinese Personal Information Protection Law (PIPL)
- Indian Digital Personal Data Protection Act 2023 (DPDP Act)
- South African Protection of Personal Information Act (POPIA)
- United Arab Emirates Personal Data Protection Law (PDPL)
- New Zealand Privacy Act 2020
- Children's Online Privacy Protection Act (COPPA, USA)

---

## 2. Zero Data Collection Principle

**We do not collect, store, transmit, or process any personal data on our servers.**

The Application operates entirely on your device. All configuration, credentials, and preferences are stored locally. We have no servers that receive your data. We do not operate any backend infrastructure for data collection, analytics, crash reporting, or telemetry.

Because we do not process personal data under our control, most obligations under data protection laws (data controller duties, international transfer obligations, breach notification, etc.) do not apply to us as the publisher of this Application. Section 10 nonetheless describes the rights available to you under applicable law.

---

## 3. Data Stored on Your Device

The Application stores the following data locally on your macOS device. None of this data is transmitted to our servers.

### 3.1 Credentials

- **Civo API Key** — stored in the macOS Keychain (hardware-backed encryption) — used to authenticate with the Civo Cloud API
- **Kubeconfig Credentials** — stored in memory only during active sessions, never persisted to disk
- **Object Store Credentials (Access Key ID / Secret)** — retrieved from the Civo API on demand, stored in memory only

### 3.2 Preferences

- **Selected Region** (UserDefaults) — active Civo region code
- **Managed Firewalls** (UserDefaults, JSON) — firewall configurations tracked by the Application
- **Launch at Login** (UserDefaults) — auto-start preference
- **Onboarding State** (UserDefaults) — setup completion flag
- **IP Presets** (UserDefaults, JSON) — user-named IP addresses for firewall rules

### 3.3 Transient Runtime Data

- **Detected Public IP** — held in memory during a session, never persisted
- **API Responses** — held in memory while displayed, never persisted beyond the session

### 3.4 Purchase Status

Managed entirely by Apple StoreKit. We do not receive, store, or process any payment information.

---

## 4. Legal Basis for Processing (GDPR)

Since we do not act as a data controller or processor for personal data collected through the Application, Art. 6 GDPR bases for processing do not apply to us. To the extent the operation of the Application involves local processing on your device, it is performed on the basis of:

- **Contract performance** (Art. 6(1)(b) GDPR) — providing the functionality you installed the Application for
- **Consent** (Art. 6(1)(a) GDPR) — where you explicitly trigger actions such as IP detection, firewall rule creation, or Touch ID authentication

No processing occurs under Art. 6(1)(a), (c), (d), (e), or (f) GDPR on infrastructure operated by us.

---

## 5. How Data Is Used

Data on your device is used exclusively to:

- Authenticate against the Civo Cloud API, Kubernetes API servers, and S3-compatible object storage endpoints you direct the Application to
- Manage your Civo Cloud resources (instances, clusters, databases, firewalls, etc.)
- Detect your public IPv4 address to open and close firewall rules
- Display resource status, cost estimates, and activity logs locally
- Process your one-time in-app purchase through Apple StoreKit

Data is never shared, sold, rented, or otherwise disclosed to third parties by us.

---

## 6. Third-Party Services

The Application communicates directly with the following third-party services at your explicit direction. We are not a party to these communications.

### 6.1 Civo Cloud API (api.civo.com)

- **Purpose:** Manage your Civo Cloud infrastructure
- **Data sent:** Your Civo API key (as authentication header), resource management requests
- **Operator:** Civo Ltd, United Kingdom
- **Privacy policy:** https://www.civo.com/privacy

### 6.2 Kubernetes API Servers

- **Purpose:** Access cluster nodes, pods, logs, deployments, and metrics
- **Data sent:** Client certificate credentials from your kubeconfig (PKCS#12 mTLS)
- **Operator:** The Kubernetes cluster operator (your Civo cluster; you control the endpoint)

### 6.3 Civo Object Storage (S3-compatible)

- **Purpose:** Browse, upload, and download files in your object stores
- **Data sent:** S3-compatible requests signed with your object store credentials (AWS Signature V4)
- **Operator:** Civo Ltd

### 6.4 IP Detection Services

- **Purpose:** Detect your public IPv4 address for firewall rule management
- **Services used:** ipify.org, ifconfig.me, icanhazip.com (fallback chain)
- **Data sent:** Standard HTTPS request (your IP address is inherently visible to these services)
- **Data received:** Your public IPv4 address

### 6.5 Apple App Store / StoreKit

- **Purpose:** Process in-app purchases, verify entitlements, enable Family Sharing
- **Data sent:** Managed entirely by Apple's StoreKit framework
- **Operator:** Apple Inc.
- **Privacy policy:** https://www.apple.com/legal/privacy/

### 6.6 SDKs Not Used

We do **not** integrate any of the following:

- Analytics SDKs (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog, etc.)
- Crash reporting SDKs (Crashlytics, Sentry, Bugsnag, etc.)
- Advertising SDKs (AdMob, Meta Audience Network, AppLovin, etc.)
- Attribution SDKs (AppsFlyer, Adjust, Branch, Kochava, etc.)
- A/B testing frameworks
- Social media SDKs
- Third-party authentication providers

---

## 7. International Data Transfers

We do not transfer personal data internationally because we do not collect or process personal data.

Data flows initiated by you (API calls to Civo, Kubernetes, S3, IP detection) may involve cross-border transmission. Those transfers are governed by the privacy notices and data transfer mechanisms of the respective operators. For EEA/UK users, Civo Ltd relies on UK and EU adequacy decisions and, where applicable, Standard Contractual Clauses (SCCs).

---

## 8. Data Retention

We retain no data. All Application data is stored locally on your device and is under your sole control.

- **Uninstalling the Application** removes preferences stored in UserDefaults (typically `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Keychain items** may persist after uninstall; these can be removed manually via Keychain Access
- **Past-month cost caches** are stored locally and removed with the container upon uninstall

---

## 9. Data Security

Although we do not collect your data, we implement the following security measures within the Application:

- **API Key Storage:** macOS Keychain with hardware-backed encryption (Secure Enclave where available)
- **Object Store Secrets:** Touch ID / system password protected via LocalAuthentication framework
- **Kubeconfig Credentials:** Stored only in memory during active sessions, never persisted to disk
- **Network Communication:** HTTPS/TLS 1.2+ for all API communications
- **Certificate Authentication:** Kubernetes API uses PKCS#12 client certificate mTLS
- **App Sandbox:** Application runs within macOS App Sandbox, with minimum required entitlements
- **Hardened Runtime:** Additional security hardening at runtime
- **No Telemetry:** No usage data, analytics, or crash reports are transmitted anywhere
- **No Persistent Logging:** Logs use `os.Logger` with `privacy: .private` and are not exported

No system is completely secure. We recommend using a dedicated API key with the minimum Civo permissions required for your workflow.

---

## 10. Your Rights

### 10.1 Rights under GDPR (EU / EEA / UK)

You have the right to:

- **Access** your personal data (Art. 15 GDPR) — not applicable, we hold no data about you
- **Rectification** of inaccurate data (Art. 16 GDPR) — not applicable
- **Erasure** / right to be forgotten (Art. 17 GDPR) — not applicable; you may delete local data by uninstalling
- **Restriction** of processing (Art. 18 GDPR) — not applicable
- **Data portability** (Art. 20 GDPR) — not applicable
- **Objection** to processing (Art. 21 GDPR) — not applicable
- **Withdrawal of consent** at any time (Art. 7(3) GDPR) — you may stop using the Application at any time
- **Lodge a complaint** with a supervisory authority

These rights are satisfied by our zero-collection policy. Should this change in a future version, we will notify you and implement the full rights framework.

### 10.2 Rights under CCPA / CPRA (California, USA)

California residents have the right to:

- Know what personal information is collected, used, shared, or sold
- Delete personal information
- Opt out of the sale or sharing of personal information
- Non-discrimination for exercising privacy rights
- Correct inaccurate personal information
- Limit the use of sensitive personal information

We do not sell personal information. We do not share personal information for cross-context behavioral advertising. We do not collect personal information as defined under CCPA/CPRA.

### 10.3 Rights under Other US State Laws (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR, etc.)

Residents of Virginia, Colorado, Connecticut, Utah, Texas, Oregon, Iowa, Montana, Florida, Tennessee, Indiana, Delaware, New Jersey, and other US states with privacy legislation have rights to access, delete, correct, and opt out of targeted advertising / sale / profiling. These rights are satisfied by our zero-collection policy.

### 10.4 Rights under PIPEDA and Provincial Laws (Canada)

Canadian residents have the right to access, challenge accuracy, withdraw consent, and complain to the Office of the Privacy Commissioner of Canada (or provincial authorities in Quebec, British Columbia, Alberta).

### 10.5 Rights under Australian Privacy Act

Australian residents have the right to access and correct their personal information, and to complain to the Office of the Australian Information Commissioner (OAIC).

### 10.6 Rights under LGPD (Brazil)

Brazilian residents have the right to confirmation of processing, access, correction, anonymization, portability, information about sharing, and revocation of consent. Complaints may be directed to the Autoridade Nacional de Proteção de Dados (ANPD).

### 10.7 Rights under APPI (Japan)

Japanese residents have the right to disclosure, correction, deletion, and cessation of use. Complaints may be directed to the Personal Information Protection Commission (PPC).

### 10.8 Rights under PIPA (South Korea)

South Korean residents have the right to access, correct, delete, suspend processing, and claim damages. Complaints may be directed to the Personal Information Protection Commission (PIPC).

### 10.9 Rights under PDPA (Singapore / Thailand)

Residents have the right to access, correct, and withdraw consent. Complaints may be directed to the Personal Data Protection Commission (PDPC) of the respective country.

### 10.10 Rights under PIPL (China)

Chinese residents have the right to know, decide, restrict, refuse, access, copy, port, correct, delete, and demand explanation regarding processing rules.

### 10.11 Rights under DPDP Act (India)

Indian residents have the right to information, correction, erasure, grievance redressal, and nomination.

### 10.12 Rights under POPIA (South Africa)

South African residents have the right to access, correction, deletion, and complaint to the Information Regulator.

### 10.13 Rights under Swiss FADP

Swiss residents have the right to information, access, rectification, deletion, objection, and data portability. Complaints may be directed to the Federal Data Protection and Information Commissioner (FDPIC).

### 10.14 Rights under NZ Privacy Act

New Zealand residents have the right to access and correct personal information, and to complain to the Privacy Commissioner.

### 10.15 How to Exercise Your Rights

Because we hold no data about you, these rights are satisfied by default. If you believe we hold personal data about you despite this Policy, contact moin@berger-rosenstock.de.

---

## 11. Children's Privacy

The Application carries an Apple App Store age rating of **4+** and is therefore technically accessible to users of all ages. However, the Application is a technical infrastructure management tool intended for administrators of Civo Cloud accounts. A Civo Cloud account requires the account holder to be of legal contract age in their jurisdiction.

**We do not knowingly collect personal information from anyone, including children under the age of 13 (COPPA, USA), 16 (GDPR-K, EU), or the applicable age of consent in your jurisdiction.**

Because the Application implements a strict zero-collection policy (see Section 2), no personal information about any user — regardless of age — is collected, transmitted, stored on our servers, or shared with third parties. This satisfies:

- **COPPA** (Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506, USA)
- **GDPR Art. 8** (EU)
- **PIPEDA** and applicable provincial laws (Canada)
- **LGPD Art. 14** (Brazil)
- **APPI** (Japan)
- **Australian Privacy Act** and AAP 8 on child privacy

If you are a parent or guardian and believe your child has provided personal information, contact moin@berger-rosenstock.de. We will promptly investigate and delete such information where found.

---

## 12. Cookies and Tracking

The Application is a native macOS application and does not use cookies, web beacons, pixel tags, fingerprinting, or similar tracking technologies.

The Application does not contain any embedded webviews that load third-party content.

---

## 13. Automated Decision-Making

We do not engage in automated decision-making or profiling that produces legal effects or similarly significantly affects you. The Application does not perform automated decisions based on personal data.

---

## 14. Third-Party Links and Services

The Application may contain links to third-party websites (e.g., Civo website, Apple App Store, Online Dispute Resolution platform). We are not responsible for the privacy practices or content of third-party services. Please review their privacy policies before providing data.

---

## 15. Changes to This Policy

We may update this Privacy Policy from time to time.

- Material changes will be communicated through the Application or the App Store listing at least 30 days before they take effect
- The "Effective Date" at the top reflects the latest revision
- We will not retroactively change our privacy practices to collect data without obtaining your explicit consent

---

## 16. Contact

For privacy-related inquiries or to exercise your rights:

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Germany
Email: moin@berger-rosenstock.de

For EU residents, you may also contact the competent supervisory authority in your Member State. A list of EU supervisory authorities is available at: https://edpb.europa.eu/about-edpb/board/members_en

For UK residents, the supervisory authority is the Information Commissioner's Office (ICO): https://ico.org.uk

---

## 17. Regional Provisions

### 17.1 European Union / European Economic Area

- Operation complies with GDPR where applicable to local processing on your device
- The supervisory authority of the data controller is the competent German state data protection authority
- Data Protection Impact Assessments (DPIAs) are not required (no collection)

### 17.2 Germany

- Compliance with GDPR and Bundesdatenschutzgesetz (BDSG)
- Competent supervisory authority: the Landesbeauftragte für Datenschutz of the relevant federal state (the controller resides in Germany)

### 17.3 Austria

- Compliance with GDPR and Datenschutzgesetz (DSG)
- Supervisory authority: Datenschutzbehörde (DSB)

### 17.4 Switzerland

- Compliance with the revised Federal Act on Data Protection (revDSG), in force since 1 September 2023
- Supervisory authority: Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB)

### 17.5 United Kingdom

- Compliance with UK GDPR and Data Protection Act 2018
- Supervisory authority: Information Commissioner's Office (ICO)

### 17.6 France

- Compliance with GDPR and Loi Informatique et Libertés
- Supervisory authority: Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Italy

- Compliance with GDPR and Codice in materia di protezione dei dati personali
- Supervisory authority: Garante per la Protezione dei Dati Personali

### 17.8 Spain

- Compliance with GDPR and Ley Orgánica 3/2018 (LOPDGDD)
- Supervisory authority: Agencia Española de Protección de Datos (AEPD)

### 17.9 Netherlands

- Compliance with GDPR and Uitvoeringswet AVG (UAVG)
- Supervisory authority: Autoriteit Persoonsgegevens (AP)

### 17.10 Poland

- Compliance with GDPR and Ustawa o ochronie danych osobowych
- Supervisory authority: Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portugal

- Compliance with GDPR and Lei n.º 58/2019
- Supervisory authority: Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 Belgium

- Compliance with GDPR and Loi du 30 juillet 2018
- Supervisory authority: Gegevensbeschermingsautoriteit (APD-GBA)

### 17.13 Ireland

- Compliance with GDPR and Data Protection Act 2018
- Supervisory authority: Data Protection Commission (DPC)

### 17.14 Nordic Countries (Denmark, Finland, Norway, Sweden, Iceland)

- Compliance with GDPR (and EEA equivalents for Norway and Iceland)
- National supervisory authorities: Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Other EU/EEA Member States

Compliance with GDPR and the respective national implementation. Supervisory authority listings: https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 United States

- Compliance with applicable state privacy laws: CCPA/CPRA (California), VCDPA (Virginia), CPA (Colorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Texas), OCPA (Oregon), IDPA (Iowa), MCDPA (Montana), FDBR (Florida), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (New Jersey)
- "Do Not Track" and "Global Privacy Control" signals are respected where technically feasible (the Application does not track)
- COPPA compliance for users under 13

### 17.17 Canada

- Compliance with PIPEDA and applicable provincial laws: Quebec Act 25, British Columbia PIPA, Alberta PIPA
- Complaints: Office of the Privacy Commissioner of Canada (OPC) and provincial authorities

### 17.18 Mexico

- Compliance with Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Supervisory authority: Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brazil

- Compliance with LGPD
- Supervisory authority: Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentina, Chile, Colombia, Peru, Uruguay

- Compliance with national data protection laws (Law 25.326 / Law 19.628 / Law 1581 / Law 29733 / Law 18.331)

### 17.21 Australia

- Compliance with Privacy Act 1988 and Australian Privacy Principles (APPs)
- Supervisory authority: Office of the Australian Information Commissioner (OAIC)

### 17.22 New Zealand

- Compliance with Privacy Act 2020
- Supervisory authority: Office of the Privacy Commissioner

### 17.23 Japan

- Compliance with Act on the Protection of Personal Information (APPI)
- Supervisory authority: Personal Information Protection Commission (PPC)

### 17.24 South Korea

- Compliance with Personal Information Protection Act (PIPA)
- Supervisory authority: Personal Information Protection Commission (PIPC)

### 17.25 Singapore

- Compliance with Personal Data Protection Act (PDPA)
- Supervisory authority: Personal Data Protection Commission (PDPC)

### 17.26 Thailand

- Compliance with Personal Data Protection Act B.E. 2562 (2019)
- Supervisory authority: Personal Data Protection Committee

### 17.27 China

- Compliance with Personal Information Protection Law (PIPL), Cybersecurity Law (CSL), and Data Security Law (DSL)

### 17.28 Hong Kong

- Compliance with Personal Data (Privacy) Ordinance (PDPO)
- Supervisory authority: Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 India

- Compliance with Digital Personal Data Protection Act 2023 (DPDP Act) and Information Technology Act 2000
- Supervisory authority: Data Protection Board of India

### 17.30 United Arab Emirates

- Compliance with Federal Decree-Law No. 45 of 2021 (Personal Data Protection Law)

### 17.31 Saudi Arabia

- Compliance with Personal Data Protection Law (PDPL)

### 17.32 Turkey

- Compliance with Personal Data Protection Law No. 6698 (KVKK)
- Supervisory authority: Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Israel

- Compliance with Privacy Protection Law, 5741-1981 and Privacy Protection Regulations
- Supervisory authority: Privacy Protection Authority (PPA)

### 17.34 South Africa

- Compliance with Protection of Personal Information Act (POPIA)
- Supervisory authority: Information Regulator

### 17.35 Kenya, Nigeria, Egypt, Morocco

- Compliance with national data protection laws (Data Protection Act 2019 Kenya, NDPR / NDPA Nigeria, Law No. 151 of 2020 Egypt, Law 09-08 Morocco)

### 17.36 Other Jurisdictions

For users in jurisdictions not specifically listed above, the Application's zero-collection approach ensures compliance with the data minimization and purpose limitation principles common to modern privacy frameworks. Should your local law provide additional rights, those rights are respected.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. All rights reserved.
