<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: id | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# PEMBERITAHUAN PERSETUJUAN NOTIFIKASI PUSH

## Informasi yang ditampilkan bersamaan dengan permintaan izin sistem untuk notifikasi push

**Tanggal Berlaku:** September 2026

**Penyedia:**
DigitalFreedom
Merek dari DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Amerika Serikat
Kontak:  hello@digitalfreedom.co.za 
Perlindungan data:  data-protection@digitalfreedom.co.za 
Situs web:  https://digitalfreedom.co.za 

---

## 0. TUJUAN

Pemberitahuan ini ditampilkan **sebelum** permintaan izin sistem iOS / Android untuk notifikasi push. Ini memberi tahu pengguna — dengan bahasa yang jelas — tentang apa yang mereka setujui. Ini memenuhi:

- **Pasal 6(1)(a) GDPR** — persetujuan yang diberikan secara bebas, spesifik, diinformasikan, dan tegas untuk pemrosesan terkait notifikasi jika notifikasi tersebut memuat konten data pribadi
- **Pasal 13 GDPR** — transparansi pada saat pengumpulan
- **Direktif ePrivacy 2002/58/EC Pasal 13 / implementasi nasional** — untuk setiap notifikasi yang mengandung konten pemasaran
- **Apple Human Interface Guidelines** dan **Google Play Developer Policy** — praktik terbaik sebelum permintaan izin

Layanan didistribusikan secara global melalui Apple App Store dan Google Play Store; Pemberitahuan ini berlaku di mana pun notifikasi push diaktifkan dan disampaikan dalam bahasa pengguna jika didukung.

---

## 1. APA YANG ANDA IZINKAN

Jika Anda mengetuk **"Izinkan"** pada permintaan berikutnya, `Civo Cloud Manager` akan dapat:

- mengirim notifikasi ke perangkat Anda
- menampilkan peringatan, lencana, spanduk, dan suara (tergantung pengaturan tingkat OS Anda)
- menggunakan APNs milik Apple / FCM milik Google sebagai saluran pengiriman (token push perangkat Anda dibagikan dengan penyedia ini hanya untuk pengiriman)

---

## 2. TENTANG APA NOTIFIKASI TERSEBUT

`Civo Cloud Manager` mengirimkan notifikasi untuk tujuan berikut:

| Kategori | Contoh | Default |
|---|---|---|
| **Notifikasi layanan** (esensial) | peringatan akun, peringatan keamanan, pengingat pembayaran, pembaruan penting | Aktif |
| **Transaksional** | konfirmasi atas tindakan yang Anda lakukan, perubahan status yang Anda minta | Aktif |
| **Pengingat** | pengingat yang Anda atur sendiri di `Civo Cloud Manager` | Pilihan Anda |
| **Tips & fitur baru** | pembaruan sesekali tentang fungsionalitas baru | Nonaktif secara default — pilih masuk |
| **Pemasaran / promosi** | penawaran, kampanye, berita produk baru | Nonaktif secara default — pilih masuk; persetujuan terpisah di bawah § 4 |

Setiap kategori dapat diaktifkan atau dinonaktifkan secara mandiri di **Pengaturan → Notifikasi** di dalam `Civo Cloud Manager` — dan kapan saja melalui pengaturan notifikasi tingkat OS perangkat Anda.

---

## 3. TIDAK ADA PELACAKAN MELALUI NOTIFIKASI

Kami **tidak**:

- menggunakan notifikasi untuk melacak lokasi Anda
- menyertakan informasi identitas pribadi (PII) tentang pengguna lain dalam notifikasi Anda
- menggunakan notifikasi senyap / latar belakang untuk mengumpulkan analitik tentang Anda
- membagikan token push perangkat Anda dengan pihak selain Apple / Google untuk pengiriman

---

## 4. NOTIFIKASI PEMASARAN

Notifikasi push pemasaran / promosi diatur oleh Pasal 6(1)(a) GDPR + ePrivacy Pasal 13: **persetujuan eksplisit, terpisah, dan terperinci diperlukan**.

- Tombol pemasaran **nonaktif** secara default
- Anda dapat mengaktifkan (dan menonaktifkan) kapan saja di **Pengaturan → Notifikasi → Pemasaran**
- Persetujuan push pemasaran **berbeda** dari persetujuan pemasaran email; mengaktifkan salah satu tidak mengaktifkan yang lain
- Penarikan persetujuan semudah memilih masuk (satu tombol), dan tidak memengaruhi notifikasi non-pemasaran

---

## 5. ANAK-ANAK

Jika `Civo Cloud Manager` digunakan oleh anak di bawah umur, [Pemberitahuan Privasi Anak](CHILDREN_PRIVACY_NOTICE.md) juga berlaku. Kami tidak mengirimkan notifikasi pemasaran kepada anak di bawah umur.

---

## 6. SUB-PROSESOR YANG TERLIBAT

Pengiriman push menggunakan layanan bawaan platform:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (pengendali independen untuk saluran pengiriman)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (pengendali independen untuk saluran pengiriman)

Mereka bertindak sebagai pengendali sendiri untuk lapisan pengiriman sesuai kebijakan privasi masing-masing. Lihat [`processors/apple.md`](processors/apple.md) dan [catatan sub-prosesor Google Cloud](processors/google-cloud.md).

---

## 7. HAK ANDA

Anda dapat sewaktu-waktu:

- **Menonaktifkan** semua notifikasi di tingkat OS (Pengaturan → Notifikasi → `Civo Cloud Manager` → mati)
- **Menonaktifkan kategori tertentu** di dalam aplikasi (Pengaturan → Notifikasi)
- **Mencabut persetujuan pemasaran** tanpa kehilangan notifikasi layanan
- **Meminta penghapusan** data apa pun yang kami simpan terkait preferensi notifikasi melalui  `data-protection@digitalfreedom.co.za` 

Pencabutan persetujuan tidak memengaruhi keabsahan pemrosesan sebelum pencabutan.

---

## 8. JIKA ANDA MEMILIH "JANGAN IZINKAN"

Jika Anda menolak permintaan sistem:

- `Civo Cloud Manager` tetap dapat digunakan — tidak ada fitur yang dikunci di balik izin notifikasi
- Anda dapat mengubah keputusan nanti di **Pengaturan → Notifikasi → `Civo Cloud Manager`** (tingkat OS)
- kami tidak akan meminta ulang secara berulang atau menggunakan pola gelap untuk memaksa persetujuan

---

## 9. KONTAK

DigitalFreedom
Merek dari DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Amerika Serikat

Bantuan preferensi notifikasi:  support@digitalfreedom.co.za 
Perlindungan data:  data-protection@digitalfreedom.co.za 
Umum:  hello@digitalfreedom.co.za 
Situs web:  https://digitalfreedom.co.za 

---

(c) 2025-2026 DigitalFreedom Global LLC. Seluruh hak cipta dilindungi.