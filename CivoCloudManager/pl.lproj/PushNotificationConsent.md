<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: pl | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# POWIADOMIENIE O WYRAŻENIU ZGODY NA POWIADOMIENIA PUSH

## Informacje wyświetlane wraz z systemowym monitorem uprawnień dotyczącym powiadomień push

**Data wejścia w życie:** wrzesień 2026

**Dostawca:**
DigitalFreedom
Marka należąca do DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Stany Zjednoczone
Kontakt: hello@digitalfreedom.co.za
Ochrona danych: data-protection@digitalfreedom.co.za
Strona internetowa: https://digitalfreedom.co.za

---

## 0. CEL

Niniejsze Powiadomienie jest wyświetlane **przed** systemowym monitorem uprawnień iOS / Android dotyczącym powiadomień push. Informuje użytkownika — prostym językiem — na co wyraża zgodę. Spełnia wymogi:

- **art. 6 ust. 1 lit. a RODO** — dobrowolna, konkretna, świadoma i jednoznaczna zgoda na przetwarzanie związane z powiadomieniami, gdy powiadomienie zawiera treści stanowiące dane osobowe
- **art. 13 RODO** — przejrzystość w momencie zbierania danych
- **Dyrektywa ePrivacy 2002/58/WE art. 13 / krajowe implementacje** — w przypadku powiadomień o treści marketingowej
- **Apple Human Interface Guidelines** oraz **Google Play Developer Policy** — najlepsze praktyki dotyczące pre-promptu

Usługi są dystrybuowane globalnie za pośrednictwem Apple App Store oraz Google Play Store; niniejsze Powiadomienie ma zastosowanie wszędzie tam, gdzie powiadomienia push są włączone i jest dostarczane w języku użytkownika, jeśli jest obsługiwany.

---

## 1. NA CO WYRAŻASZ ZGODĘ

Jeśli naciśniesz **„Zezwól”** w następnym monicie, `Civo Cloud Manager` będzie mógł:

- wysyłać powiadomienia na Twoje urządzenie
- wyświetlać alerty, odznaki, banery i dźwięki (zgodnie z ustawieniami na poziomie systemu operacyjnego)
- korzystać z APNs Apple / FCM Google jako kanału dostarczania (token push Twojego urządzenia jest udostępniany tym dostawcom wyłącznie w celu dostarczenia powiadomienia)

---

## 2. TEMATYKA POWIADOMIEŃ

`Civo Cloud Manager` wysyła powiadomienia w następujących celach:

| Kategoria | Przykłady | Domyślnie |
|---|---|---|
| **Powiadomienia serwisowe** (niezbędne) | alerty dotyczące konta, ostrzeżenia bezpieczeństwa, przypomnienia o płatnościach, ważne aktualizacje | Włączone |
| **Transakcyjne** | potwierdzenie wykonanej przez Ciebie czynności, zmiany statusu, o które prosiłeś | Włączone |
| **Przypomnienia** | przypomnienia ustawione samodzielnie w `Civo Cloud Manager` | Według wyboru |
| **Porady i nowe funkcje** | okazjonalne informacje o nowych funkcjonalnościach | Domyślnie wyłączone — wymaga zgody |
| **Marketingowe / promocyjne** | oferty, kampanie, informacje o nowych produktach | Domyślnie wyłączone — wymaga zgody; osobna zgoda zgodnie z § 4 |

Każdą kategorię można włączyć lub wyłączyć niezależnie w **Ustawienia → Powiadomienia** w aplikacji `Civo Cloud Manager` — oraz w dowolnym momencie w ustawieniach powiadomień na poziomie systemu operacyjnego Twojego urządzenia.

---

## 3. BRAK ŚLEDZENIA PRZEZ POWIADOMIENIA

Nie:

- używamy powiadomień do śledzenia Twojej lokalizacji
- zawieramy danych osobowych innych użytkowników w Twoich powiadomieniach
- wykorzystujemy ciche / działające w tle powiadomienia do zbierania danych analitycznych o Tobie
- udostępniamy token push Twojego urządzenia innym podmiotom niż Apple / Google w celu dostarczenia powiadomienia

---

## 4. POWIADOMIENIA MARKETINGOWE

Powiadomienia push o charakterze marketingowym / promocyjnym podlegają art. 6 ust. 1 lit. a RODO + ePrivacy art. 13: **wymagana jest wyraźna, osobna i szczegółowa zgoda**.

- Przełącznik marketingowy jest **domyślnie wyłączony**
- Możesz go włączyć (i wyłączyć) w dowolnym momencie w **Ustawienia → Powiadomienia → Marketing**
- Zgoda na powiadomienia push marketingowe jest **odrębna** od zgody na marketing e-mailowy; włączenie jednej nie powoduje włączenia drugiej
- Wycofanie zgody jest równie łatwe jak jej udzielenie (pojedynczy przełącznik) i nie wpływa na powiadomienia niebędące marketingowymi

---

## 5. DZIECI

Jeśli z `Civo Cloud Manager` korzystają osoby niepełnoletnie, dodatkowo obowiązuje [Informacja o prywatności dzieci](CHILDREN_PRIVACY_NOTICE.md). Nie wysyłamy powiadomień push o charakterze marketingowym do osób niepełnoletnich.

---

## 6. PODWYKONAWCY ZAANGAŻOWANI

Dostarczenie powiadomień push wykorzystuje natywne usługi platformowe:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (niezależny administrator dla kanału dostarczania)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (niezależny administrator dla kanału dostarczania)

Podmioty te działają jako niezależni administratorzy warstwy dostarczania zgodnie z własnymi politykami prywatności. Zobacz [`processors/apple.md`](processors/apple.md) oraz [rejestr podwykonawców Google Cloud](processors/google-cloud.md).

---

## 7. TWOJE PRAWA

W każdej chwili możesz:

- **Wyłączyć** wszystkie powiadomienia na poziomie systemu operacyjnego (Ustawienia → Powiadomienia → `Civo Cloud Manager` → wyłącz)
- **Wyłączyć wybrane kategorie** w aplikacji (Ustawienia → Powiadomienia)
- **Wycofać zgodę marketingową** bez utraty powiadomień serwisowych
- **Zażądać usunięcia** wszelkich danych, które posiadamy w związku z preferencjami powiadomień, za pośrednictwem `data-protection@digitalfreedom.co.za`

Wycofanie zgody nie wpływa na zgodność z prawem przetwarzania dokonanego przed jej wycofaniem.

---

## 8. JEŚLI WYBIERZESZ „NIE ZEZWALAJ”

Jeśli odrzucisz systemowy monit:

- `Civo Cloud Manager` nadal działa — żadna funkcja nie jest uzależniona od zgody na powiadomienia
- możesz zmienić decyzję później w **Ustawienia → Powiadomienia → `Civo Cloud Manager`** (na poziomie systemu operacyjnego)
- nie będziemy ponawiać monitów ani stosować ciemnych wzorców w celu wymuszenia zgody

---

## 9. KONTAKT

DigitalFreedom
Marka należąca do DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Stany Zjednoczone

Pomoc dotycząca preferencji powiadomień: support@digitalfreedom.co.za
Ochrona danych: data-protection@digitalfreedom.co.za
Ogólne: hello@digitalfreedom.co.za
Strona internetowa: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. Wszelkie prawa zastrzeżone.
