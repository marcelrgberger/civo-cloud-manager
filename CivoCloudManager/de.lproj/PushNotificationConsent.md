<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: de | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# HINWEIS ZUR EINWILLIGUNG IN PUSH-BENACHRICHTIGUNGEN

## Informationen, die zusammen mit der Systemberechtigungsabfrage für Push-Benachrichtigungen angezeigt werden

**Gültig ab:** September 2026

**Anbieter:**
DigitalFreedom
Eine Marke von DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Vereinigte Staaten
Kontakt: hello@digitalfreedom.co.za
Datenschutz: data-protection@digitalfreedom.co.za
Webseite: https://digitalfreedom.co.za

---

## 0. ZWECK

Dieser Hinweis wird **vor** der iOS- / Android-Systemberechtigungsabfrage für Push-Benachrichtigungen angezeigt. Er informiert den Nutzer — in klarer Sprache — darüber, worin er einwilligt. Er erfüllt:

- **Art. 6 Abs. 1 lit. a DSGVO** — freiwillige, spezifische, informierte und eindeutige Einwilligung zur Verarbeitung im Zusammenhang mit Benachrichtigungen, wenn diese personenbezogene Daten enthalten
- **Art. 13 DSGVO** — Transparenz zum Zeitpunkt der Datenerhebung
- **ePrivacy-Richtlinie 2002/58/EG Art. 13 / nationale Umsetzungen** — für jede Benachrichtigung mit Marketing-Inhalten
- **Apple Human Interface Guidelines** und **Google Play Developer Policy** — Best Practices für Pre-Prompts

Die Dienste werden weltweit über den Apple App Store und den Google Play Store vertrieben; dieser Hinweis gilt überall dort, wo Push-Benachrichtigungen aktiviert sind, und wird in der vom Nutzer unterstützten Sprache bereitgestellt.

---

## 1. WORIN SIE EINWILLIGEN

Wenn Sie beim nächsten Hinweis auf **„Erlauben“** tippen, kann `Civo Cloud Manager`:

- Benachrichtigungen an Ihr Gerät senden
- Hinweise, Badges, Banner und Töne anzeigen (abhängig von Ihren Betriebssystem-Einstellungen)
- Apples APNs / Googles FCM als Übertragungskanal nutzen (Ihr Geräte-Push-Token wird ausschließlich zu diesem Zweck mit diesen Anbietern geteilt)

---

## 2. WORÜBER DIE BENACHRICHTIGUNGEN INFORMIEREN

`Civo Cloud Manager` sendet Benachrichtigungen zu folgenden Zwecken:

| Kategorie | Beispiele | Standard |
|---|---|---|
| **Service-Benachrichtigungen** (essenziell) | Konto-Hinweise, Sicherheitswarnungen, Zahlungserinnerungen, wichtige Updates | An |
| **Transaktional** | Bestätigung einer von Ihnen durchgeführten Aktion, Statusänderungen, nach denen Sie gefragt haben | An |
| **Erinnerungen** | Erinnerungen, die Sie selbst in `Civo Cloud Manager` eingerichtet haben | Ihre Wahl |
| **Tipps & neue Funktionen** | gelegentliche Hinweise zu neuen Funktionen | Standardmäßig aus — Opt-in |
| **Marketing / Werbung** | Angebote, Kampagnen, Neuigkeiten zu Produkten | Standardmäßig aus — Opt-in; separate Einwilligung gemäß § 4 |

Jede Kategorie kann unabhängig voneinander in **Einstellungen → Benachrichtigungen** innerhalb von `Civo Cloud Manager` aktiviert oder deaktiviert werden — und jederzeit in den Benachrichtigungseinstellungen Ihres Betriebssystems.

---

## 3. KEIN TRACKING DURCH DIE BENACHRICHTIGUNG

Wir tun **nicht**:

- Benachrichtigungen zur Standortverfolgung verwenden
- personenbezogene Informationen (PII) über andere Nutzer in Ihre Benachrichtigungen aufnehmen
- stille / Hintergrundbenachrichtigungen nutzen, um Analysen über Sie zu erheben
- Ihr Geräte-Push-Token mit anderen Parteien als Apple / Google zur Zustellung teilen

---

## 4. MARKETING-BENACHRICHTIGUNGEN

Marketing- / Werbe-Push-Benachrichtigungen unterliegen Art. 6 Abs. 1 lit. a DSGVO + ePrivacy Art. 13: **explizite, separate, granulare Einwilligung ist erforderlich**.

- Die Marketing-Option ist **standardmäßig deaktiviert**
- Sie können sie jederzeit in **Einstellungen → Benachrichtigungen → Marketing** aktivieren (und deaktivieren)
- Die Einwilligung für Marketing-Push ist **unabhängig** von der Einwilligung für E-Mail-Marketing; das Aktivieren der einen aktiviert nicht die andere
- Der Widerruf ist ebenso einfach wie die Einwilligung (ein Schalter) und betrifft nicht die nicht-marketingbezogenen Benachrichtigungen

---

## 5. KINDER

Wenn `Civo Cloud Manager` von Minderjährigen genutzt wird, gilt zusätzlich der [Datenschutzhinweis für Kinder](CHILDREN_PRIVACY_NOTICE.md). Wir versenden keine Marketing-Push-Benachrichtigungen an Minderjährige.

---

## 6. EINGEBUNDENE SUBAUFTRAGNEHMER

Für die Zustellung von Push-Benachrichtigungen werden plattformnative Dienste verwendet:

- **Apple Push Notification Service (APNs)** — Apple Distribution International Ltd. (unabhängiger Verantwortlicher für den Übertragungskanal)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (unabhängiger Verantwortlicher für den Übertragungskanal)

Diese agieren für die Übertragungsebene gemäß ihren eigenen Datenschutzrichtlinien als eigenständige Verantwortliche. Siehe [`processors/apple.md`](processors/apple.md) und [Google Cloud Sub-Prozessoren-Verzeichnis](processors/google-cloud.md).

---

## 7. IHRE RECHTE

Sie können jederzeit:

- **Alle Benachrichtigungen** auf Betriebssystemebene deaktivieren (Einstellungen → Benachrichtigungen → `Civo Cloud Manager` → aus)
- **Spezifische Kategorien** in der App deaktivieren (Einstellungen → Benachrichtigungen)
- **Marketing-Einwilligung widerrufen** ohne Verlust von Service-Benachrichtigungen
- **Löschung** aller von uns zu Ihren Benachrichtigungseinstellungen gespeicherten Daten über `data-protection@digitalfreedom.co.za` verlangen

Der Widerruf der Einwilligung berührt nicht die Rechtmäßigkeit der Verarbeitung bis zum Widerruf.

---

## 8. WENN SIE „NICHT ERLAUBEN“ WÄHLEN

Wenn Sie die Systemabfrage ablehnen:

- `Civo Cloud Manager` funktioniert weiterhin — keine Funktion ist hinter einer Benachrichtigungsberechtigung kostenpflichtig
- Sie können Ihre Entscheidung später in **Einstellungen → Benachrichtigungen → `Civo Cloud Manager`** (Betriebssystemebene) ändern
- Wir werden Sie nicht wiederholt erneut fragen oder Dark Patterns einsetzen, um Ihre Einwilligung zu erzwingen

---

## 9. KONTAKT

DigitalFreedom
Eine Marke von DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Vereinigte Staaten

Hilfe zu Benachrichtigungseinstellungen: support@digitalfreedom.co.za
Datenschutz: data-protection@digitalfreedom.co.za
Allgemein: hello@digitalfreedom.co.za
Webseite: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. Alle Rechte vorbehalten.
