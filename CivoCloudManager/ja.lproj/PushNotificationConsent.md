<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: ja | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# プッシュ通知同意通知

## プッシュ通知のシステム許可プロンプトと共に表示される情報

**発効日：** 2026年9月

**提供者：**
DigitalFreedom
DigitalFreedom Global LLCのブランド
30 N Gould St, Ste N
Sheridan, WY 82801
アメリカ合衆国
連絡先： hello@digitalfreedom.co.za 
データ保護： data-protection@digitalfreedom.co.za 
ウェブサイト： https://digitalfreedom.co.za 

---

## 0．目的

本通知は、iOS／Android のシステムによるプッシュ通知の許可プロンプト**前**に表示されます。ユーザーが何に同意するかを平易な言葉で説明します。これにより、以下を満たします：

- **GDPR 第6条第1項(a)** — 通知に個人データが含まれる場合の処理について、自由意思・特定・十分な情報提供・明確な同意
- **GDPR 第13条** — 収集時点での透明性
- **eプライバシー指令 2002/58/EC 第13条／各国実装** — マーケティング内容を含む通知に関して
- **Apple Human Interface Guidelines** および **Google Play Developer Policy** — 事前プロンプトのベストプラクティス

サービスは Apple App Store および Google Play Store を通じて全世界に配信されます。本通知は、プッシュ通知が有効なすべての地域に適用され、対応言語で表示されます。

---

## 1．許可内容

次のプロンプトで**「許可」**をタップすると、`Civo Cloud Manager`は以下が可能となります：

- お使いの端末に通知を送信
- アラート、バッジ、バナー、サウンドを表示（OSレベルの設定に従う）
- Apple の APNs／Google の FCM を配信チャネルとして利用（端末のプッシュトークンは配信目的のみでこれらの提供者と共有）

---

## 2．通知の内容

`Civo Cloud Manager`は、以下の目的で通知を送信します：

| カテゴリ | 例 | デフォルト |
|---|---|---|
| **サービス通知**（必須） | アカウント警告、セキュリティ警告、支払いリマインダー、重要な更新 | オン |
| **取引関連** | ユーザー操作の確認、依頼したステータス変更 | オン |
| **リマインダー** | `Civo Cloud Manager`内でユーザー自身が設定したリマインダー | 選択可 |
| **ヒント・新機能** | 新機能に関する時折のアップデート | デフォルトはオフ — オプトイン |
| **マーケティング／プロモーション** | オファー、キャンペーン、新製品情報 | デフォルトはオフ — オプトイン；§4に基づく個別同意 |

各カテゴリは、`Civo Cloud Manager`内の**設定 → 通知**および端末のOSレベルの通知設定で、個別にオン／オフを切り替えられます。

---

## 3．通知による追跡なし

当社は**以下を行いません**：

- 通知を使ってユーザーの位置情報を追跡
- 他のユーザーの個人識別情報（PII）を通知に含める
- サイレント／バックグラウンド通知でユーザーの分析情報を収集
- 配信以外の目的で Apple／Google 以外の第三者と端末プッシュトークンを共有

---

## 4．マーケティング通知

マーケティング／プロモーションのプッシュ通知は、GDPR 第6条第1項(a)および eプライバシー第13条に基づき管理されます：**明示的かつ個別・細分化されたオプトインが必要です**。

- マーケティングの切り替えはデフォルトで**オフ**です
- **設定 → 通知 → マーケティング**でいつでもオン／オフを切り替え可能
- プッシュ通知のマーケティング同意は、メールマーケティング同意とは**別個**です；一方を有効にしても他方は有効になりません
- オプトインと同様に、ワンタップで簡単に同意を撤回でき、非マーケティング通知には影響しません

---

## 5．児童

未成年者が`Civo Cloud Manager`を利用する場合は、[子どものプライバシーに関する通知](CHILDREN_PRIVACY_NOTICE.md)も適用されます。当社は未成年者に対してマーケティング目的のプッシュ通知を送信しません。

---

## 6．サブプロセッサーの関与

プッシュ配信にはプラットフォーム標準のサービスを利用しています：

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd.（配信チャネルの独立管理者）
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited（配信チャネルの独立管理者）

これらは、それぞれのプライバシーポリシーに基づき、配信レイヤーの独立した管理者として機能します。詳細は[`processors/apple.md`](processors/apple.md)および[Google Cloud サブプロセッサー記録](processors/google-cloud.md)をご参照ください。

---

## 7．お客様の権利

お客様はいつでも以下のことが可能です：

- OSレベルで**すべての通知を無効化**（設定 → 通知 → `Civo Cloud Manager` → オフ）
- アプリ内で**特定カテゴリを無効化**（設定 → 通知）
- サービス通知を失うことなく**マーケティング同意を撤回**
- `data-protection@digitalfreedom.co.za`宛に通知設定に関連する当社保有データの**削除を請求**

同意の撤回は、撤回前の処理の適法性には影響しません。

---

## 8．「許可しない」と選択した場合

システムのプロンプトを拒否した場合：

- `Civo Cloud Manager`は引き続き利用可能です — 通知権限の有無で機能が制限されることはありません
- 後から**設定 → 通知 → `Civo Cloud Manager`**（OSレベル）で変更できます
- 当社は繰り返し再表示したり、同意を強要するダークパターンを用いたりしません

---

## 9．お問い合わせ

DigitalFreedom
DigitalFreedom Global LLCのブランド
30 N Gould St, Ste N
Sheridan, WY 82801
アメリカ合衆国

通知設定のサポート：support@digitalfreedom.co.za
データ保護：data-protection@digitalfreedom.co.za
一般窓口：hello@digitalfreedom.co.za
ウェブサイト：https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC。全著作権所有。