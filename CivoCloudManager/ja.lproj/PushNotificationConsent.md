<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: ja | app-version: 2.3.0 | updated: 2026-11-23 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: replaced by a notice for local notifications only, because the app has no push delivery; company identity and contacts from the legal repository -->
# 通知に関するお知らせ

## Civo Cloud Manager のローカル通知

**発効日：** 2026年11月

**提供者：**
DigitalFreedom
DigitalFreedom Global LLC のブランド
30 N Gould St, Ste N
Sheridan, WY 82801
アメリカ合衆国
連絡先： hello@digitalfreedom.co.za
データ保護： data-protection@digitalfreedom.co.za
ウェブサイト： https://digitalfreedom.co.za

---

## 1. アプリが許可を求める内容

アプリを初めて起動すると、macOS は Civo Cloud Manager がアラートを表示し、サウンドを再生してよいかどうかを尋ねます。アプリが求める許可はこれのみです。この許可は、たとえば接続中の Kubernetes クラスターのポッドが再起動したときなどに、お使いの Mac 上でローカル通知を表示するために使用されます。

## 2. アプリが行わないこと

- リモートプッシュ通知は使用しません。サーバーからお使いの Mac に何かが送信されることはありません。
- Apple Push Notification service (APNs) も Firebase Cloud Messaging (FCM) も使用せず、プッシュトークンの登録も保存も行いません。
- マーケティング通知は送信しません。
- iOS および Android 向けには配布されていません。

通知は、お客様が接続したサービスからアプリがすでに受信したデータをもとに、お使いの Mac 上で作成されます。通知が当社に送信されることはなく、当社が受け取ることもありません。

## 3. 選択を変更する方法

通知は、システム設定の「通知」で Civo Cloud Manager を選択することにより、いつでも許可または停止できます。通知を許可しない場合でも、アプリはこれまでどおり動作し、アラートは表示されません。

## 4. 詳細情報およびお問い合わせ

アプリによるデータの取扱いについては、[プライバシーポリシー](PrivacyPolicy.md)に記載しています。本お知らせに関するご質問は hello@digitalfreedom.co.za 宛にお寄せください。データ保護に関するご請求は data-protection@digitalfreedom.co.za 宛にお送りください。
