<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: tr | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# ANLIK BİLDİRİM ONAYI BİLDİRİMİ

## Anlık bildirimler için sistem izin istemiyle birlikte gösterilen bilgiler

**Yürürlük Tarihi:** Eylül 2026

**Sağlayıcı:**
DigitalFreedom
DigitalFreedom Global LLC markasıdır
30 N Gould St, Ste N
Sheridan, WY 82801
Amerika Birleşik Devletleri
İletişim:  hello@digitalfreedom.co.za 
Veri koruma:  data-protection@digitalfreedom.co.za 
Web sitesi:  https://digitalfreedom.co.za 

---

## 0. AMAÇ

Bu Bildirim, iOS / Android sistem izin isteminden **önce** gösterilir. Kullanıcıya — açık bir dille — neye onay verdiğini bildirir. Şunları karşılar:

- **Madde 6(1)(a) GDPR** — bildirim kişisel veri içerdiğinde, bildirime ilişkin işlemler için özgürce verilmiş, belirli, bilgilendirilmiş, açık rıza
- **Madde 13 GDPR** — toplama anında şeffaflık
- **ePrivacy Direktifi 2002/58/EC Madde 13 / ulusal uygulamalar** — pazarlama içeriği taşıyan tüm bildirimler için
- **Apple İnsan Arayüzü Kılavuzları** ve **Google Play Geliştirici Politikası** — ön-bilgilendirme en iyi uygulamaları

Hizmetler, Apple App Store ve Google Play Store üzerinden dünya çapında dağıtılır; bu Bildirim, anlık bildirimlerin etkin olduğu her yerde geçerlidir ve desteklenen dillerde kullanıcının dilinde sunulur.

---

## 1. İZİN VERDİĞİNİZ ŞEY

Bir sonraki istemde **"İzin Ver"** seçeneğine dokunursanız, `Civo Cloud Manager` şunları yapabilir:

- cihazınıza bildirim gönderebilir
- uyarılar, rozetler, afişler ve sesler gösterebilir (işletim sistemi düzeyindeki ayarlarınıza bağlı olarak)
- iletim kanalı olarak Apple'ın APNs / Google'ın FCM'sini kullanabilir (cihazınızın anlık bildirim belirteci yalnızca iletim amacıyla bu sağlayıcılarla paylaşılır)

---

## 2. BİLDİRİMLERİN KONUSU

`Civo Cloud Manager` aşağıdaki amaçlarla bildirim gönderir:

| Kategori | Örnekler | Varsayılan |
|---|---|---|
| **Hizmet bildirimleri** (zorunlu) | hesap uyarıları, güvenlik uyarıları, ödeme hatırlatıcıları, önemli güncellemeler | Açık |
| **İşlemsel** | gerçekleştirdiğiniz bir işlemin onayı, talep ettiğiniz durum değişiklikleri | Açık |
| **Hatırlatıcılar** | `Civo Cloud Manager` içinde kendinizin kurduğu hatırlatıcılar | Seçiminiz |
| **İpuçları & yeni özellikler** | yeni işlevlerle ilgili ara sıra güncellemeler | Varsayılan olarak kapalı — isteğe bağlı |
| **Pazarlama / promosyon** | teklifler, kampanyalar, yeni ürün haberleri | Varsayılan olarak kapalı — isteğe bağlı; § 4 kapsamında ayrı onay |

Her kategori, **Ayarlar → Bildirimler** bölümünden `Civo Cloud Manager` içinde ve dilediğiniz zaman cihazınızın işletim sistemi düzeyindeki bildirim ayarlarından bağımsız olarak açılıp kapatılabilir.

---

## 3. BİLDİRİM YOLUYLA TAKİP YOK

Şunları **yapmayız**:

- bildirimleri konumunuzu izlemek için kullanmak
- bildirimlerinizde diğer kullanıcılarla ilgili kişisel olarak tanımlanabilir bilgi (PII) bulundurmak
- sessiz / arka plan bildirimleriyle sizinle ilgili analiz toplamak
- cihazınızın anlık bildirim belirtecini iletim dışında Apple / Google harici taraflarla paylaşmak

---

## 4. PAZARLAMA BİLDİRİMLERİ

Pazarlama / promosyon anlık bildirimleri, Madde 6(1)(a) GDPR + ePrivacy Madde 13 kapsamında yönetilir: **açık, ayrı, ayrıntılı onay gereklidir**.

- Pazarlama anahtarı varsayılan olarak **kapalıdır**
- **Ayarlar → Bildirimler → Pazarlama** yoluyla istediğiniz zaman açıp kapatabilirsiniz
- Pazarlama anlık bildirim onayı, e-posta pazarlama onayından **bağımsızdır**; birini etkinleştirmek diğerini etkinleştirmez
- Onaydan vazgeçmek, onay vermek kadar kolaydır (tek anahtar) ve pazarlama dışı bildirimleri etkilemez

---

## 5. ÇOCUKLAR

`Civo Cloud Manager` küçükler tarafından kullanılıyorsa, ek olarak [Çocukların Gizliliği Bildirimi](CHILDREN_PRIVACY_NOTICE.md) geçerlidir. Küçüklere pazarlama amaçlı anlık bildirim göndermiyoruz.

---

## 6. DAHİL OLAN ALT-İŞLEYENLER

Anlık bildirim iletimi platforma özgü hizmetlerle sağlanır:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (iletim kanalı için bağımsız veri sorumlusu)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (iletim kanalı için bağımsız veri sorumlusu)

Bunlar, kendi gizlilik politikalarına göre iletim katmanında kendi veri sorumluları olarak hareket eder. Ayrıntılar için bkz. [`processors/apple.md`](processors/apple.md) ve [Google Cloud alt-işleyici kaydı](processors/google-cloud.md).

---

## 7. HAKLARINIZ

Her zaman şunları yapabilirsiniz:

- **Tüm bildirimleri devre dışı bırakın** (Sistem Ayarları → Bildirimler → `Civo Cloud Manager` → kapalı)
- **Belirli kategorileri uygulama içinde devre dışı bırakın** (Ayarlar → Bildirimler)
- **Pazarlama onayınızı geri çekin** (hizmet bildirimlerini kaybetmeden)
- **Bildirime ilişkin tercihlerinizle ilgili tuttuğumuz tüm verilerin silinmesini talep edin** ( `data-protection@digitalfreedom.co.za`  üzerinden)

Onayın geri çekilmesi, geri çekilmeden önceki işlemenin hukuka uygunluğunu etkilemez.

---

## 8. "İZİN VERME" DERSENİZ

Sistem istemini reddederseniz:

- `Civo Cloud Manager` çalışmaya devam eder — hiçbir özellik bildirim iznine bağlı değildir
- fikrinizi daha sonra **Ayarlar → Bildirimler → `Civo Cloud Manager`** (sistem düzeyinde) üzerinden değiştirebilirsiniz
- tekrar tekrar istemde bulunmayacağız veya onay vermeniz için yanıltıcı yöntemler kullanmayacağız

---

## 9. İLETİŞİM

DigitalFreedom
Bir DigitalFreedom Global LLC markasıdır
30 N Gould St, Ste N
Sheridan, WY 82801
Amerika Birleşik Devletleri

Bildirim tercihleri desteği:  support@digitalfreedom.co.za 
Veri koruma:  data-protection@digitalfreedom.co.za 
Genel:  hello@digitalfreedom.co.za 
Web sitesi:  https://digitalfreedom.co.za 

---

(c) 2025-2026 DigitalFreedom Global LLC. Tüm hakları saklıdır.
