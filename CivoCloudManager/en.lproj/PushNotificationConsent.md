# PUSH NOTIFICATION CONSENT NOTICE

## Information shown alongside the system permission prompt for push notifications

**Effective Date:** May 2026

**Provider:**
DigitalFreedom
A brand of Berger & Rosenstock GbR
Dieselstr. 22e
61231 Bad Nauheim
Germany
Contact: hello@digitalfreedom.co.za
Data protection: data-protection@digitalfreedom.co.za
Website: https://digitalfreedom.co.za

---

## 0. PURPOSE

This Notice is shown **before** the iOS / Android system permission prompt for push notifications. It informs the user — in plain language — what they are consenting to. It satisfies:

- **Art. 6(1)(a) GDPR** — freely-given, specific, informed, unambiguous consent for processing related to notifications when the notification carries personal-data content
- **Art. 13 GDPR** — transparency at the point of collection
- **ePrivacy Directive 2002/58/EC Art. 13 / national implementations** — for any notification with marketing content
- **Apple Human Interface Guidelines** and **Google Play Developer Policy** — pre-prompt best practices

The Services are distributed globally via the Apple App Store and the Google Play Store; this Notice applies wherever push notifications are enabled and is delivered in the user's language where supported.

---

## 1. WHAT YOU ARE ALLOWING

If you tap **"Allow"** at the next prompt, `Civo Cloud Manager` will be able to:

- send notifications to your device
- show alerts, badges, banners and sounds (subject to your OS-level settings)
- use Apple's APNs / Google's FCM as the delivery channel (your device push token is shared with these providers for delivery only)

---

## 2. WHAT THE NOTIFICATIONS WILL BE ABOUT

`Civo Cloud Manager` sends notifications for the following purposes:

| Category | Examples | Default |
|---|---|---|
| **Service notifications** (essential) | account alerts, security warnings, payment reminders, important updates | On |
| **Transactional** | confirmation of an action you took, status changes you asked about | On |
| **Reminders** | reminders you set up yourself in `Civo Cloud Manager` | Your choice |
| **Tips & new features** | occasional updates about new functionality | Off by default — opt-in |
| **Marketing / promotional** | offers, campaigns, new product news | Off by default — opt-in; separate consent under § 4 |

Each category can be enabled or disabled independently in **Settings → Notifications** inside `Civo Cloud Manager` — and at any time in your device's OS-level notification settings.

---

## 3. NO TRACKING BY THE NOTIFICATION

We do **not**:

- use notifications to track your location
- include personally identifiable information (PII) about other users in your notifications
- use silent / background notifications to gather analytics about you
- share your device push token with parties other than Apple / Google for delivery

---

## 4. MARKETING NOTIFICATIONS

Marketing / promotional push notifications are governed by Art. 6(1)(a) GDPR + ePrivacy Art. 13: **explicit, separate, granular opt-in is required**.

- The marketing toggle is **off** by default
- You can turn it on (and off) at any time in **Settings → Notifications → Marketing**
- Marketing push consent is **distinct** from email-marketing consent (MailerLite); enabling one does not enable the other
- Withdrawal is as easy as opt-in (single toggle), and does not affect non-marketing notifications

---

## 5. CHILDREN

If `Civo Cloud Manager` is used by minors, the [Children's Privacy Notice](CHILDREN_PRIVACY_NOTICE.md) applies in addition. We do not send marketing push notifications to minors.

---

## 6. SUB-PROCESSORS INVOLVED

Push delivery uses platform-native services:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (independent controller for the delivery channel)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (independent controller for the delivery channel)

These act as their own controllers for the delivery layer per their own privacy policies. See [`processors/apple.md`](processors/apple.md) and [Google Cloud sub-processor record](processors/google-cloud.md).

---

## 7. YOUR RIGHTS

You may at any time:

- **Disable** all notifications at the OS level (Settings → Notifications → `Civo Cloud Manager` → off)
- **Disable specific categories** in-app (Settings → Notifications)
- **Withdraw marketing consent** without losing service notifications
- **Request deletion** of any data we hold related to notification preferences via `data-protection@digitalfreedom.co.za`

Withdrawing consent does not affect the lawfulness of processing prior to withdrawal.

---

## 8. IF YOU SAY "DON'T ALLOW"

If you decline the system prompt:

- `Civo Cloud Manager` continues to work — no feature is paywalled behind notification permission
- you can change your mind later in **Settings → Notifications → `Civo Cloud Manager`** (OS-level)
- we will not re-prompt repeatedly or use dark patterns to coerce consent

---

## 9. CONTACT

DigitalFreedom
A brand of Berger & Rosenstock GbR
Dieselstr. 22e
61231 Bad Nauheim
Germany

Notification preferences help: support@digitalfreedom.co.za
Data protection: data-protection@digitalfreedom.co.za
General: hello@digitalfreedom.co.za
Website: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom — Berger & Rosenstock GbR. All rights reserved.
