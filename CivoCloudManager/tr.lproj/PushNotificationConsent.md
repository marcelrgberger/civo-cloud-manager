<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: tr | app-version: 2.3.0 | updated: 2026-11-23 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: replaced by a notice for local notifications only, because the app has no push delivery; company identity and contacts from the legal repository -->
# BİLDİRİMLER HAKKINDA BİLGİLENDİRME

## Civo Cloud Manager'da yerel bildirimler

**Yürürlük Tarihi:** Kasım 2026

**Sağlayıcı:**
DigitalFreedom
DigitalFreedom Global LLC markası
30 N Gould St, Ste N
Sheridan, WY 82801
Amerika Birleşik Devletleri
İletişim: hello@digitalfreedom.co.za
Veri koruma: data-protection@digitalfreedom.co.za
Web sitesi: https://digitalfreedom.co.za

---

## 1. UYGULAMA NEYİ İSTER

Uygulama ilk çalıştırıldığında macOS, Civo Cloud Manager'ın uyarı gösterip ses çalmasına izin verip vermediğinizi sorar. Uygulama yalnızca bu izni ister. Bu izni, örneğin bağlı olduğunuz bir Kubernetes kümesindeki bir pod yeniden başladığında Mac'inizde yerel bir bildirim göstermek için kullanır.

## 2. UYGULAMA NEYİ YAPMAZ

- Uzak anlık bildirimler (push) kullanmaz. Mac'inize bir sunucudan hiçbir şey gönderilmez.
- Apple Push Notification service (APNs) veya Firebase Cloud Messaging (FCM) kullanmaz; hiçbir push belirteci kaydetmez ve saklamaz.
- Pazarlama bildirimleri göndermez.
- iOS veya Android için dağıtılmaz.

Bildirimler, Mac'inizde, uygulamanın bağladığınız hizmetlerden zaten almış olduğu verilerden oluşturulur. Bildirimler bize gönderilmez ve biz onları almayız.

## 3. SEÇİMİNİZİ NASIL DEĞİŞTİREBİLİRSİNİZ

Bildirimlere istediğiniz zaman Sistem Ayarları'nda, Bildirimler bölümünde Civo Cloud Manager'ı seçerek izin verebilir veya bildirimleri durdurabilirsiniz. Bildirimlere izin vermezseniz uygulama eskisi gibi çalışır ve hiçbir uyarı göstermez.

## 4. DAHA FAZLA BİLGİ VE İLETİŞİM

Uygulamanın verileri nasıl işlediği [Gizlilik Politikası](PrivacyPolicy.md) içinde açıklanmıştır. Bu bilgilendirmeye ilişkin sorularınız için hello@digitalfreedom.co.za adresine yazabilirsiniz. Veri koruma talepleri data-protection@digitalfreedom.co.za adresine gönderilir.
