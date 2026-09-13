<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: ko | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# 푸시 알림 동의 안내

## 푸시 알림 시스템 권한 요청과 함께 표시되는 정보

**시행일:** 2026년 9월

**제공자:**
DigitalFreedom
DigitalFreedom Global LLC의 브랜드
30 N Gould St, Ste N
Sheridan, WY 82801
미국
연락처:  hello@digitalfreedom.co.za 
데이터 보호:  data-protection@digitalfreedom.co.za 
웹사이트:  https://digitalfreedom.co.za 

---

## 0. 목적

이 안내문은 iOS / Android 시스템의 푸시 알림 권한 요청 **이전에** 표시됩니다. 사용자가 무엇에 동의하는지 알기 쉽게 설명합니다. 본 안내문은 다음을 충족합니다:

- **GDPR 제6조(1항)(a)** — 알림에 개인정보가 포함된 경우, 자유롭게, 구체적으로, 충분히 알리고, 명확하게 동의
- **GDPR 제13조** — 수집 시점의 투명성
- **ePrivacy 지침 2002/58/EC 제13조 / 각국 법령** — 마케팅 내용이 포함된 알림의 경우
- **Apple Human Interface Guidelines** 및 **Google Play Developer Policy** — 사전 안내 모범 사례

서비스는 Apple App Store와 Google Play Store를 통해 전 세계에 배포되며, 푸시 알림이 활성화된 모든 지역에 본 안내문이 적용됩니다. 지원되는 경우 사용자의 언어로 제공됩니다.

---

## 1. 허용 시 동의 내용

다음 화면에서 **"허용"**을 누르면, `Civo Cloud Manager`이(가) 다음을 할 수 있습니다:

- 기기로 알림 전송
- 알림, 배지, 배너, 소리 표시 (운영체제 설정에 따름)
- Apple의 APNs / Google의 FCM을 전달 채널로 사용 (기기 푸시 토큰은 전달 목적으로만 해당 제공업체와 공유됨)

---

## 2. 알림의 내용

`Civo Cloud Manager`은(는) 다음 목적을 위해 알림을 보냅니다:

| 카테고리 | 예시 | 기본값 |
|---|---|---|
| **서비스 알림** (필수) | 계정 경고, 보안 경고, 결제 알림, 중요 업데이트 | 켜짐 |
| **거래 관련** | 사용자가 요청한 작업 확인, 상태 변경 | 켜짐 |
| **알림** | 사용자가 `Civo Cloud Manager`에서 직접 설정한 알림 | 선택 가능 |
| **팁 및 신규 기능** | 새로운 기능에 대한 간헐적 안내 | 기본 꺼짐 — 선택적 동의 |
| **마케팅 / 프로모션** | 혜택, 캠페인, 신제품 소식 | 기본 꺼짐 — 선택적 동의; § 4에 따른 별도 동의 필요 |

각 카테고리는 `Civo Cloud Manager` 내 **설정 → 알림**에서 개별적으로 켜거나 끌 수 있으며, 기기 운영체제의 알림 설정에서도 언제든 변경할 수 있습니다.

---

## 3. 알림을 통한 추적 없음

당사는 **다음 행위를 하지 않습니다**:

- 알림을 통해 위치 추적
- 알림에 타 사용자의 개인식별정보(PII) 포함
- 조용한/백그라운드 알림으로 분석 정보 수집
- Apple/Google 이외의 제삼자에게 기기 푸시 토큰 제공

---

## 4. 마케팅 알림

마케팅/프로모션 푸시 알림은 GDPR 제6조(1항)(a) 및 ePrivacy 제13조에 따라 **명시적이고, 별도이며, 세분화된 동의가 필요합니다**.

- 마케팅 토글은 기본적으로 **꺼짐** 상태입니다
- **설정 → 알림 → 마케팅**에서 언제든 켜거나 끌 수 있습니다
- 마케팅 푸시 동의는 이메일 마케팅 동의와 **별개**입니다; 하나를 켠다고 다른 하나가 자동으로 켜지지 않습니다
- 철회는 동의만큼 간단합니다(단일 토글) — 비마케팅 알림에는 영향이 없습니다

---

## 5. 아동

`Civo Cloud Manager`가 미성년자에 의해 사용되는 경우, [아동 개인정보 보호 고지](CHILDREN_PRIVACY_NOTICE.md)도 추가로 적용됩니다. 우리는 미성년자에게 마케팅 푸시 알림을 발송하지 않습니다.

---

## 6. 하위 처리자 참여

푸시 전달은 플랫폼 기본 서비스를 사용합니다:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (전달 채널에 대한 독립적 관리자로서)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (전달 채널에 대한 독립적 관리자로서)

이들은 각자의 개인정보 처리방침에 따라 전달 계층의 독립적 관리자로서 활동합니다. [`processors/apple.md`](processors/apple.md) 및 [Google Cloud 하위 처리자 기록](processors/google-cloud.md)을 참조하십시오.

---

## 7. 귀하의 권리

귀하는 언제든지 다음을 할 수 있습니다:

- 운영체제 수준에서 모든 알림 **비활성화** (설정 → 알림 → `Civo Cloud Manager` → 끄기)
- 앱 내에서 특정 카테고리 **비활성화** (설정 → 알림)
- 서비스 알림은 유지하면서 마케팅 동의 **철회**
- 알림 환경설정과 관련하여 당사가 보유한 모든 데이터의 **삭제 요청** (`data-protection@digitalfreedom.co.za` 통해)

동의를 철회하더라도 철회 이전의 처리 적법성에는 영향을 미치지 않습니다.

---

## 8. "허용 안 함"을 선택하는 경우

시스템 프롬프트를 거부하면:

- `Civo Cloud Manager`는 계속 작동합니다 — 알림 권한이 없더라도 어떤 기능도 유료화되지 않습니다
- 나중에 **설정 → 알림 → `Civo Cloud Manager`** (운영체제 수준)에서 변경할 수 있습니다
- 반복적으로 다시 묻거나 동의를 강요하는 다크 패턴을 사용하지 않습니다

---

## 9. 연락처

DigitalFreedom
DigitalFreedom Global LLC의 브랜드
30 N Gould St, Ste N
Sheridan, WY 82801
미국

알림 환경설정 도움말: support@digitalfreedom.co.za
데이터 보호: data-protection@digitalfreedom.co.za
일반 문의: hello@digitalfreedom.co.za
웹사이트: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. 모든 권리 보유.
