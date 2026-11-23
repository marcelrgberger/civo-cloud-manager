<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: ar | app-version: 2.3.0 | updated: 2026-11-23 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: replaced by a notice for local notifications only, because the app has no push delivery; company identity and contacts from the legal repository -->
# إشعار الإشعارات

## الإشعارات المحلية في Civo Cloud Manager

**تاريخ السريان:** نوفمبر 2026

**المزوّد:**
DigitalFreedom
علامة تجارية تابعة لـ DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
الولايات المتحدة الأمريكية
للتواصل: hello@digitalfreedom.co.za
حماية البيانات: data-protection@digitalfreedom.co.za
الموقع الإلكتروني: https://digitalfreedom.co.za

---

## 1. ما الذي يطلبه التطبيق

عند تشغيل التطبيق للمرة الأولى، يسأل macOS ما إذا كان يجوز لـ Civo Cloud Manager عرض التنبيهات وتشغيل الأصوات. لا يطلب التطبيق سوى هذا الإذن. ويستخدمه لعرض إشعار محلي على جهاز Mac الخاص بك، مثلًا عند إعادة تشغيل pod في عنقود Kubernetes متصل به.

## 2. ما الذي لا يفعله التطبيق

- لا يستخدم إشعارات الدفع عن بُعد. ولا يُرسل أي شيء إلى جهاز Mac الخاص بك من خادم.
- لا يستخدم Apple Push Notification service (APNs) ولا Firebase Cloud Messaging (FCM)، ولا يسجل أي رمز دفع ولا يخزنه.
- لا يرسل إشعارات تسويقية.
- ليس موزعًا لنظامي iOS أو Android.

تُنشأ الإشعارات على جهاز Mac الخاص بك، من بيانات سبق أن تلقاها التطبيق من الخدمات التي ربطتها. وهي لا تُرسل إلينا، ونحن لا نتلقاها.

## 3. كيفية تغيير اختيارك

يمكنك السماح بالإشعارات أو إيقافها في أي وقت من إعدادات النظام، ضمن الإشعارات، باختيار Civo Cloud Manager. وإذا لم تسمح بالإشعارات، يعمل التطبيق كما كان ولا يعرض أي تنبيهات.

## 4. مزيد من المعلومات والتواصل

تُوصف كيفية تعامل التطبيق مع البيانات في [سياسة الخصوصية](PrivacyPolicy.md). للأسئلة المتعلقة بهذا الإشعار، اكتب إلى hello@digitalfreedom.co.za. وتُوجَّه طلبات حماية البيانات إلى data-protection@digitalfreedom.co.za.
