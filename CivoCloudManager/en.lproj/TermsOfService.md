# Terms of Use

## Civo Cloud Manager

**Effective Date:** April 2026
**Last Updated:** April 2026

**Provider:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Germany
Email: moin@berger-rosenstock.de
VAT ID: DE455096022

---

## 1. Scope and Acceptance

### 1.1 Agreement

These Terms of Use ("Terms") govern your access to and use of the Civo Cloud Manager application ("the Application") provided by Berger & Rosenstock GbR ("the Provider", "we", "us", "our").

### 1.2 Acceptance

By installing, accessing, or using the Application, you agree to be bound by these Terms. If you do not agree, you must not install or use the Application.

### 1.3 Eligibility

The Application carries an Apple App Store age rating of **4+**. To enter into a binding contract you must be of legal contract age in your jurisdiction. A Civo Cloud account, which is required for meaningful use of the Application, requires the account holder to be of legal contract age.

### 1.4 Business Use

If you use the Application on behalf of an organization, you represent that you have the authority to bind that organization to these Terms.

### 1.5 Apple Licensed Application End User License Agreement

These Terms are supplementary to the Apple Licensed Application End User License Agreement (Apple EULA) between you and Apple Inc. In the event of any conflict between these Terms and the Apple EULA, the Apple EULA prevails with respect to matters it covers.

---

## 2. Services

### 2.1 Description

The Application is a native macOS application that enables management of Civo Cloud infrastructure (virtual instances, Kubernetes clusters, databases, firewalls, networks, load balancers, volumes, object stores, DNS, SSH keys) and direct Kubernetes API access via the user's own API credentials.

The Application connects directly from your device to:

- The Civo Cloud REST API (`api.civo.com`)
- Kubernetes API servers of your Civo clusters (via mTLS)
- S3-compatible object storage endpoints of your Civo account
- Public IP detection services (ipify.org, ifconfig.me, icanhazip.com)
- Apple App Store / StoreKit for purchase processing

The Provider does not operate any backend service, intermediate server, or proxy. All communication happens directly between your device and the respective third-party operators.

### 2.2 Free and Paid Features

The menu-bar firewall management functionality is free of charge. "Full Access" — which unlocks the management dashboard for all supported resource types — is a one-time in-app purchase processed exclusively through the Apple App Store (see Section 7).

### 2.3 Modifications

The Provider may modify, suspend, or discontinue any functionality of the Application at any time. Material changes affecting purchased features will be communicated at least thirty (30) days in advance where practicable.

### 2.4 Availability

The Application is provided on an "as available" basis. The Provider does not guarantee uninterrupted access or availability, and the functionality of the Application depends on the availability of third-party services (Civo Cloud, Apple App Store, IP detection providers) that are outside the Provider's control.

---

## 3. Accounts

The Application does not require an account with the Provider. All authentication is handled via:

- Your Civo API key (stored locally in macOS Keychain)
- Your Kubernetes kubeconfig (retrieved from Civo API)
- Your Apple ID (for in-app purchase verification, handled by Apple)

You are responsible for:

- Maintaining the confidentiality of your Civo API key and other credentials
- All activities performed using your credentials
- All resource changes, costs, and billing implications resulting from your use of the Application
- Configuring Civo API key permissions according to the principle of least privilege

The Provider has no ability to access, recover, or reset your Civo credentials. Loss of credentials is solely your responsibility.

---

## 4. User Content

The Application does not host, store, or transmit user-generated content to any server operated by the Provider. Any content, data, or configuration you create using the Application (e.g., instance names, SSH keys, firewall rule labels, object store files) is stored:

- Locally on your device, or
- In your own Civo Cloud account

You retain all rights, title, and interest in and to such content. The Provider claims no license, ownership, or other right to your content.

---

## 5. Acceptable Use

You may not use the Application to:

- Violate any applicable law, regulation, or third-party right
- Access or operate Civo resources you are not authorized to access
- Interfere with or disrupt the Civo Cloud service, Kubernetes clusters you do not own, or the Application itself
- Attempt to reverse-engineer, decompile, disassemble, or derive source code from the Application, except to the extent such restriction is prohibited by applicable law
- Circumvent security or access-control mechanisms (including the in-app purchase paywall)
- Distribute, sublicense, lease, rent, sell, or otherwise commercially exploit the Application
- Remove, alter, or obscure proprietary notices, copyright marks, or trademarks
- Use the Application to attack, compromise, or test the security of systems you do not own or have explicit written authorization to test
- Use the Application for any purpose prohibited by the laws of the Federal Republic of Germany, the European Union, or your jurisdiction of residence

---

## 6. Intellectual Property

### 6.1 Ownership

The Application (including source code, design, text, graphics, icons, localizations, and all associated intellectual property rights) is the exclusive property of the Provider and is protected by German, European Union, and international copyright, trademark, and other intellectual property laws.

### 6.2 License Grant

Subject to your compliance with these Terms and the Apple EULA, the Provider grants you a limited, non-exclusive, non-transferable, non-sublicensable, revocable license to install and use the Application on Apple devices you own or control, solely for your personal or internal business use of managing your Civo Cloud infrastructure.

### 6.3 Third-Party Trademarks

"Civo" is a trademark of Civo Ltd. "Apple", "App Store", "macOS", "iCloud", "StoreKit", "TestFlight" are trademarks of Apple Inc. "Kubernetes" is a trademark of The Linux Foundation. All other trademarks are the property of their respective owners. The Provider is not affiliated with, endorsed by, or sponsored by any of these parties.

### 6.4 Feedback

Any feedback, suggestions, or ideas you submit to the Provider regarding the Application may be used by the Provider without restriction and without compensation to you.

---

## 7. Payments and Subscriptions

### 7.1 In-App Purchase

"Full Access" is sold as a non-consumable in-app purchase through the Apple App Store for a one-time fee. The price is displayed in the Application in your local currency prior to purchase.

### 7.2 Payment Processing

Payment is processed exclusively by Apple Inc. The Provider does not receive, store, or process any payment information. All payment, refund, and invoicing matters are governed by Apple's Media Services Terms and the Apple EULA.

### 7.3 Family Sharing

"Full Access" is enabled for Apple Family Sharing. Members of your Apple Family Sharing group will be able to use the purchase on their own devices, subject to Apple's Family Sharing rules.

### 7.4 Apple Offer Codes

The Provider may issue Apple offer codes for promotional purposes. Offer codes may be redeemed via the "Redeem Code" function in the Application or the App Store.

### 7.5 Refunds

Refunds are handled exclusively by Apple in accordance with Apple's refund policy. Statutory consumer rights under applicable law (see Section 15) remain unaffected. In particular, EU consumers are informed that the statutory 14-day right of withdrawal for digital content expires when performance has begun with your prior express consent — Apple implements this via the confirmation dialog at purchase time.

### 7.6 Taxes

The displayed price includes all applicable taxes (VAT, sales tax) as determined by Apple based on your country.

---

## 8. Third-Party Services

Use of the Application requires interaction with third-party services. Your use of those services is governed by their respective terms:

- **Civo Cloud:** https://www.civo.com/terms
- **Apple App Store / Apple ID:** https://www.apple.com/legal/internet-services/terms/
- **Kubernetes clusters:** the terms of your cluster operator (Civo)

The Provider is not a party to any agreement between you and a third-party service provider and is not responsible for the availability, accuracy, or behavior of those services.

---

## 9. Disclaimer of Warranties

THE APPLICATION IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, COMPLETENESS, OR NON-INFRINGEMENT.

THE PROVIDER DOES NOT WARRANT THAT:

- THE APPLICATION WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE
- THE APPLICATION WILL CORRECTLY DISPLAY, CREATE, MODIFY, DELETE, OR MANAGE CIVO CLOUD RESOURCES
- ANY DATA DISPLAYED BY THE APPLICATION IS ACCURATE, COMPLETE, OR UP TO DATE
- THE APPLICATION IS COMPATIBLE WITH ALL CIVO API VERSIONS, FEATURES, OR REGIONS

**Destructive operations.** The Application can perform irreversible operations on your Civo Cloud account, including deleting Kubernetes clusters, databases, volumes, object stores, instances, SSH keys, and firewall rules. All destructive operations require explicit user confirmation (typically by typing the resource name). THE PROVIDER ASSUMES NO RESPONSIBILITY for any unintended deletions, data loss, cost overruns, or infrastructure damage caused by your use of the Application.

You are strongly advised to maintain independent backups of all critical data, to use a dedicated API key with the minimum Civo permissions required, and to review all confirmation dialogs carefully.

Nothing in this Section excludes or limits any warranty that cannot be excluded or limited under applicable law (see Section 15).

---

## 10. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW:

### 10.1 Exclusions

THE PROVIDER SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, PUNITIVE, OR EXEMPLARY DAMAGES, INCLUDING BUT NOT LIMITED TO:

- Loss of data, revenue, profits, or business opportunities
- Costs of procurement of substitute services
- Damage to or deletion of cloud infrastructure, resources, or data
- Unauthorized access resulting from compromised API keys

### 10.2 Cap

THE PROVIDER'S TOTAL AGGREGATE LIABILITY TO YOU FOR ALL CLAIMS ARISING OUT OF OR IN CONNECTION WITH THE APPLICATION SHALL NOT EXCEED THE AMOUNT YOU ACTUALLY PAID FOR THE APPLICATION IN THE TWELVE (12) MONTHS PRECEDING THE EVENT GIVING RISE TO THE CLAIM.

### 10.3 Carve-Outs

Nothing in these Terms excludes or limits liability for:

- Death or personal injury caused by negligence
- Fraud or fraudulent misrepresentation
- Willful misconduct or gross negligence (under German law, §§ 276, 309 BGB)
- Breach of essential contractual obligations (Kardinalpflichten), limited to foreseeable damages typical for this type of contract
- Any other liability that cannot be excluded or limited by applicable law

### 10.4 Product Liability

Liability under the German Product Liability Act (Produkthaftungsgesetz) remains unaffected.

---

## 11. Indemnification

You agree to indemnify, defend, and hold harmless the Provider, its partners, employees, and agents from and against any and all claims, liabilities, damages, losses, costs, expenses, or fees (including reasonable attorneys' fees) arising out of or related to:

- Your violation of these Terms
- Your violation of any law or third-party right
- Your use of the Application to access or manage infrastructure you are not authorized to access
- Any content or configuration you create, modify, or delete through the Application

This indemnification obligation does not apply to consumers within the meaning of applicable consumer protection legislation where mandatory law prohibits such indemnification.

---

## 12. Termination

### 12.1 Termination by You

You may terminate these Terms at any time by uninstalling the Application from your devices.

### 12.2 Termination by the Provider

The Provider may terminate or suspend your license to use the Application immediately if you materially breach these Terms. In case of termination:

- Your right to use the Application ceases immediately
- You must uninstall the Application from your devices
- Sections 6, 9, 10, 11, 13, 14, 16 survive termination

### 12.3 Effect on Purchase

Termination does not entitle you to a refund of your in-app purchase, except as required by applicable consumer protection law or Apple's refund policy.

---

## 13. Governing Law and Dispute Resolution

### 13.1 Governing Law

These Terms are governed by the laws of the Federal Republic of Germany, excluding its conflict-of-law rules and the UN Convention on Contracts for the International Sale of Goods (CISG).

For consumers within the European Union / EEA, this choice of law does not deprive you of the mandatory consumer protection of the laws of your country of habitual residence.

### 13.2 Jurisdiction

For merchants, legal entities under public law, and public-law special funds (Kaufleute, juristische Personen des öffentlichen Rechts, öffentlich-rechtliche Sondervermögen), the exclusive place of jurisdiction for all disputes arising from these Terms shall be Bad Nauheim, Germany.

For consumers, the statutory place of jurisdiction applies. You may bring proceedings in the courts of your country of habitual residence.

### 13.3 EU Online Dispute Resolution

The European Commission provides an online dispute resolution platform at https://ec.europa.eu/consumers/odr.

### 13.4 Consumer Arbitration

The Provider is neither obligated nor willing to participate in dispute resolution proceedings before a consumer arbitration board (Verbraucherschlichtungsstelle) within the meaning of the German Consumer Dispute Resolution Act (VSBG), unless required by law.

---

## 14. Regional Provisions

### 14.1 Germany

- Consumer rights under BGB §§ 312 et seq., §§ 327 et seq. (digital products) remain unaffected
- Statutory withdrawal rights per BGB § 355 apply where applicable

### 14.2 European Union / EEA

- Consumer Rights Directive 2011/83/EU and Digital Content Directive (EU) 2019/770 apply where you are a consumer
- Digital Services Act (Regulation (EU) 2022/2065) applicable notices per Article 12 are provided in the Imprint

### 14.3 United Kingdom

- Consumer Rights Act 2015 applies where you are a consumer resident in the UK
- Digital content must be of satisfactory quality, fit for purpose, and as described

### 14.4 Switzerland

- Swiss Code of Obligations (OR) mandatory consumer provisions remain unaffected
- Federal Act against Unfair Competition (UWG) applies

### 14.5 United States

- These Terms are not intended to create rights under state consumer protection statutes that do not apply by their terms
- California residents: Civil Code § 1789.3 consumer rights notice — contact moin@berger-rosenstock.de

### 14.6 Canada

- Quebec Consumer Protection Act applies to Quebec residents where mandatory
- Language of agreement: these Terms are provided in English; French versions available where required by the Charter of the French Language (Quebec)

### 14.7 Australia

- Australian Consumer Law (Competition and Consumer Act 2010, Schedule 2) guarantees apply where you are a consumer — these guarantees cannot be excluded

### 14.8 New Zealand

- Consumer Guarantees Act 1993 applies where you are a consumer for personal, domestic, or household use

### 14.9 Japan

- Consumer Contract Act (消費者契約法) applies; provisions of these Terms that would be invalid under this Act are limited to the extent necessary

### 14.10 South Korea

- Act on the Regulation of Terms and Conditions (약관의 규제에 관한 법률) applies

### 14.11 Brazil

- Consumer Defense Code (CDC, Law No. 8.078/1990) applies; consumer rights cannot be waived

### 14.12 India

- Consumer Protection Act 2019 and E-Commerce Rules 2020 apply where you are a consumer

### 14.13 Other Jurisdictions

For users in jurisdictions not specifically listed above, these Terms apply to the extent permitted by local mandatory consumer protection law.

---

## 15. Consumer Rights (Mandatory Disclosures)

These Terms do not affect your statutory consumer rights under applicable law, including but not limited to:

- EU Consumer Rights Directive (2011/83/EU) and Digital Content Directive ((EU) 2019/770)
- UK Consumer Rights Act 2015
- Australian Consumer Law
- German BGB consumer protection provisions (§§ 312 ff., §§ 327 ff.)
- New Zealand Consumer Guarantees Act 1993
- Brazilian Consumer Defense Code (CDC)
- Canadian provincial consumer protection statutes
- Any other applicable consumer protection legislation in your jurisdiction

---

## 16. General

### 16.1 Changes to These Terms

We may update these Terms from time to time. Material changes will be communicated through the Application or the App Store listing at least thirty (30) days before they take effect. Your continued use after changes take effect constitutes acceptance.

### 16.2 Assignment

You may not assign or transfer these Terms or any rights under them without the Provider's prior written consent. The Provider may assign these Terms in connection with a merger, acquisition, or sale of assets.

### 16.3 Severability

If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary so that these Terms shall otherwise remain in full force. For German law, § 306 BGB applies.

### 16.4 Waiver

Failure by the Provider to enforce any provision of these Terms shall not constitute a waiver of that provision.

### 16.5 Entire Agreement

These Terms, together with the Privacy Policy, the Imprint, and the Apple EULA, constitute the entire agreement between you and the Provider regarding the Application and supersede all prior agreements and understandings.

### 16.6 Language

The authoritative version of these Terms is the English version. Translations are provided for convenience. In case of discrepancy, the English version prevails, except where mandatory local law requires otherwise.

### 16.7 Electronic Communications

You consent to receive legally required notices from the Provider in electronic form (via the Application or email).

### 16.8 Force Majeure

The Provider is not liable for any failure or delay in performance caused by events beyond its reasonable control, including acts of God, war, terrorism, civil unrest, labor disputes, internet failures, third-party service outages, or governmental action.

---

## 17. Contact

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Germany
Email: moin@berger-rosenstock.de
VAT ID: DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. All rights reserved.
