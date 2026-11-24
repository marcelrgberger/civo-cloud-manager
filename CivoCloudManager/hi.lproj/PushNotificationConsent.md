<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: hi | app-version: 2.3.0 | updated: 2026-11-23 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: replaced by a notice for local notifications only, because the app has no push delivery; company identity and contacts from the legal repository -->
# सूचना-संबंधी नोटिस

## Civo Cloud Manager में स्थानीय सूचनाएँ

**प्रभावी तिथि:** नवंबर 2026

**प्रदाता:**
DigitalFreedom
DigitalFreedom Global LLC का एक ब्रांड
30 N Gould St, Ste N
Sheridan, WY 82801
संयुक्त राज्य अमेरिका
संपर्क: hello@digitalfreedom.co.za
डेटा संरक्षण: data-protection@digitalfreedom.co.za
वेबसाइट: https://digitalfreedom.co.za

---

## 1. ऐप किस चीज़ की अनुमति माँगता है

ऐप पहली बार चलने पर macOS पूछता है कि क्या Civo Cloud Manager अलर्ट दिखा सकता है और ध्वनि चला सकता है। ऐप केवल यही अनुमति माँगता है। वह इसका उपयोग आपके Mac पर एक स्थानीय सूचना दिखाने के लिए करता है, उदाहरण के लिए तब, जब आपके जुड़े हुए किसी Kubernetes क्लस्टर का कोई पॉड पुनः आरंभ हुआ हो।

## 2. ऐप क्या नहीं करता

- वह दूरस्थ पुश सूचनाओं का उपयोग नहीं करता। किसी सर्वर से आपके Mac पर कुछ नहीं भेजा जाता।
- वह Apple Push Notification service (APNs) और Firebase Cloud Messaging (FCM) का उपयोग नहीं करता, और कोई पुश टोकन न पंजीकृत करता है, न संग्रहीत करता है।
- वह विपणन सूचनाएँ नहीं भेजता।
- उसे iOS या Android के लिए वितरित नहीं किया जाता।

सूचनाएँ आपके Mac पर ही बनाई जाती हैं, उस डेटा से जो ऐप आपके द्वारा जोड़ी गई सेवाओं से पहले ही प्राप्त कर चुका है। वे हमें नहीं भेजी जातीं, और हम उन्हें प्राप्त नहीं करते।

## 3. अपना चुनाव कैसे बदलें

आप किसी भी समय सिस्टम सेटिंग्ज़ में, सूचनाएँ (Notifications) के अंतर्गत, Civo Cloud Manager चुनकर सूचनाओं को अनुमति दे सकते हैं या रोक सकते हैं। यदि आप सूचनाओं की अनुमति नहीं देते, तो ऐप पहले की तरह काम करता है और कोई अलर्ट नहीं दिखाता।

## 4. अधिक जानकारी और संपर्क

ऐप डेटा को कैसे संभालता है, यह [गोपनीयता नीति](PrivacyPolicy.md) में वर्णित है। इस नोटिस से संबंधित प्रश्नों के लिए hello@digitalfreedom.co.za पर लिखें। डेटा संरक्षण अनुरोध data-protection@digitalfreedom.co.za पर भेजे जाते हैं।
