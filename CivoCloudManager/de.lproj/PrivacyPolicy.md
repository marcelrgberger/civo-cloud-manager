# Datenschutzerklärung

## Civo Cloud Manager

**Gültig ab:** April 2026
**Zuletzt aktualisiert:** April 2026

**Verantwortlicher:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Deutschland
E-Mail: moin@berger-rosenstock.de

---

## 1. Einleitung

Diese Datenschutzerklärung erläutert, wie Marcel R. G. Berger, handelnd als Berger & Rosenstock GbR („wir", „uns", „unser"), Informationen im Zusammenhang mit der Anwendung Civo Cloud Manager („die Anwendung") behandelt.

Wir verpflichten uns zum Schutz Ihrer Privatsphäre und zur Einhaltung der anwendbaren Datenschutzgesetze, einschließlich, aber nicht beschränkt auf:

- Datenschutz-Grundverordnung der EU (DSGVO, Verordnung (EU) 2016/679)
- Bundesdatenschutzgesetz (BDSG)
- UK General Data Protection Regulation (UK GDPR) und Data Protection Act 2018
- Schweizer Bundesgesetz über den Datenschutz (DSG / revDSG)
- California Consumer Privacy Act (CCPA) und California Privacy Rights Act (CPRA)
- Virginia Consumer Data Protection Act (VCDPA), Colorado Privacy Act (CPA), Connecticut Data Privacy Act (CTDPA), Utah Consumer Privacy Act (UCPA) und andere US-Bundesstaatengesetze
- Kanadischer Personal Information Protection and Electronic Documents Act (PIPEDA) und Provinzgesetze
- Australian Privacy Act 1988 und Australian Privacy Principles (APPs)
- Brasilianisches allgemeines Datenschutzgesetz (LGPD, Gesetz Nr. 13.709/2018)
- Japanisches Act on the Protection of Personal Information (APPI)
- Südkoreanisches Personal Information Protection Act (PIPA)
- Singapur Personal Data Protection Act (PDPA)
- Thailand Personal Data Protection Act (PDPA 2019)
- Chinesisches Personal Information Protection Law (PIPL)
- Indisches Digital Personal Data Protection Act 2023 (DPDP Act)
- Südafrikanisches Protection of Personal Information Act (POPIA)
- Personal Data Protection Law (PDPL) der Vereinigten Arabischen Emirate
- Neuseeländischer Privacy Act 2020
- Children's Online Privacy Protection Act (COPPA, USA)

---

## 2. Grundsatz der Nulldatenerhebung

**Wir erheben, speichern, übertragen oder verarbeiten keinerlei personenbezogene Daten auf unseren Servern.**

Die Anwendung läuft vollständig auf Ihrem Gerät. Sämtliche Konfigurationen, Zugangsdaten und Präferenzen werden lokal gespeichert. Wir betreiben keine Server, die Ihre Daten empfangen. Wir betreiben keine Backend-Infrastruktur zur Datenerhebung, Analyse, Absturzberichterstattung oder Telemetrie.

Da wir keine personenbezogenen Daten unter unserer Kontrolle verarbeiten, gelten die meisten Pflichten aus den Datenschutzgesetzen (Pflichten als Verantwortlicher, Pflichten bei internationalen Übermittlungen, Meldepflichten bei Datenpannen usw.) für uns als Herausgeber dieser Anwendung nicht. Abschnitt 10 beschreibt gleichwohl die Ihnen nach geltendem Recht zustehenden Rechte.

---

## 3. Auf Ihrem Gerät gespeicherte Daten

Die Anwendung speichert die folgenden Daten lokal auf Ihrem macOS-Gerät. Keine dieser Daten werden an unsere Server übertragen.

### 3.1 Zugangsdaten

- **Civo-API-Schlüssel** — gespeichert im macOS-Schlüsselbund (hardwaregestützte Verschlüsselung) — dient der Authentifizierung gegenüber der Civo-Cloud-API
- **Kubeconfig-Zugangsdaten** — ausschließlich im Arbeitsspeicher während aktiver Sitzungen gespeichert, niemals persistiert
- **Object-Store-Zugangsdaten (Access Key ID / Secret)** — bei Bedarf von der Civo-API abgerufen, ausschließlich im Arbeitsspeicher gespeichert

### 3.2 Präferenzen

- **Ausgewählte Region** (UserDefaults) — aktiver Civo-Regionscode
- **Verwaltete Firewalls** (UserDefaults, JSON) — von der Anwendung erfasste Firewall-Konfigurationen
- **Beim Anmelden starten** (UserDefaults) — Einstellung für den automatischen Start
- **Onboarding-Status** (UserDefaults) — Kennzeichen für den Abschluss der Einrichtung
- **IP-Voreinstellungen** (UserDefaults, JSON) — benutzerdefinierte IP-Adressen für Firewall-Regeln

### 3.3 Transiente Laufzeitdaten

- **Erkannte öffentliche IP** — während einer Sitzung im Arbeitsspeicher gehalten, niemals persistiert
- **API-Antworten** — während der Anzeige im Arbeitsspeicher gehalten, niemals über die Sitzung hinaus persistiert

### 3.4 Kaufstatus

Wird vollständig durch Apple StoreKit verwaltet. Wir erhalten, speichern oder verarbeiten keinerlei Zahlungsinformationen.

---

## 4. Rechtsgrundlage für die Verarbeitung (DSGVO)

Da wir weder als Verantwortlicher noch als Auftragsverarbeiter für über die Anwendung erhobene personenbezogene Daten auftreten, finden die Rechtsgrundlagen nach Art. 6 DSGVO auf uns keine Anwendung. Soweit der Betrieb der Anwendung lokale Verarbeitungen auf Ihrem Gerät umfasst, erfolgen diese auf Grundlage von:

- **Vertragserfüllung** (Art. 6 Abs. 1 lit. b DSGVO) — Bereitstellung der Funktionen, zu deren Nutzung Sie die Anwendung installiert haben
- **Einwilligung** (Art. 6 Abs. 1 lit. a DSGVO) — wenn Sie Aktionen wie IP-Erkennung, Erstellung von Firewall-Regeln oder Touch-ID-Authentifizierung explizit auslösen

Auf von uns betriebener Infrastruktur erfolgt keine Verarbeitung nach Art. 6 Abs. 1 lit. a, c, d, e oder f DSGVO.

---

## 5. Verwendung der Daten

Daten auf Ihrem Gerät werden ausschließlich verwendet, um:

- Sie gegenüber der Civo-Cloud-API, Kubernetes-API-Servern und S3-kompatiblen Object-Storage-Endpunkten zu authentifizieren, die Sie der Anwendung vorgeben
- Ihre Civo-Cloud-Ressourcen (Instanzen, Cluster, Datenbanken, Firewalls usw.) zu verwalten
- Ihre öffentliche IPv4-Adresse zu erkennen, um Firewall-Regeln zu öffnen und zu schließen
- Ressourcenstatus, Kostenschätzungen und Aktivitätsprotokolle lokal anzuzeigen
- Ihren einmaligen In-App-Kauf über Apple StoreKit abzuwickeln

Daten werden von uns niemals an Dritte weitergegeben, verkauft, vermietet oder anderweitig offengelegt.

---

## 6. Dienste Dritter

Die Anwendung kommuniziert auf Ihre ausdrückliche Veranlassung hin direkt mit den folgenden Diensten Dritter. Wir sind an diesen Kommunikationen nicht beteiligt.

### 6.1 Civo-Cloud-API (api.civo.com)

- **Zweck:** Verwaltung Ihrer Civo-Cloud-Infrastruktur
- **Gesendete Daten:** Ihr Civo-API-Schlüssel (als Authentifizierungs-Header), Ressourcenverwaltungsanfragen
- **Betreiber:** Civo Ltd, Vereinigtes Königreich
- **Datenschutzerklärung:** https://www.civo.com/privacy

### 6.2 Kubernetes-API-Server

- **Zweck:** Zugriff auf Cluster-Knoten, Pods, Logs, Deployments und Metriken
- **Gesendete Daten:** Client-Zertifikat-Zugangsdaten aus Ihrer Kubeconfig (PKCS#12 mTLS)
- **Betreiber:** Der Betreiber des Kubernetes-Clusters (Ihr Civo-Cluster; Sie kontrollieren den Endpunkt)

### 6.3 Civo Object Storage (S3-kompatibel)

- **Zweck:** Durchsuchen, Hochladen und Herunterladen von Dateien in Ihren Object Stores
- **Gesendete Daten:** S3-kompatible Anfragen, signiert mit Ihren Object-Store-Zugangsdaten (AWS Signature V4)
- **Betreiber:** Civo Ltd

### 6.4 IP-Erkennungsdienste

- **Zweck:** Erkennung Ihrer öffentlichen IPv4-Adresse zur Verwaltung von Firewall-Regeln
- **Verwendete Dienste:** ipify.org, ifconfig.me, icanhazip.com (Fallback-Kette)
- **Gesendete Daten:** Standard-HTTPS-Anfrage (Ihre IP-Adresse ist für diese Dienste inhärent sichtbar)
- **Empfangene Daten:** Ihre öffentliche IPv4-Adresse

### 6.5 Apple App Store / StoreKit

- **Zweck:** Abwicklung von In-App-Käufen, Prüfung von Berechtigungen, Aktivierung der Familienfreigabe
- **Gesendete Daten:** Vollständig durch Apples StoreKit-Framework verwaltet
- **Betreiber:** Apple Inc.
- **Datenschutzerklärung:** https://www.apple.com/legal/privacy/

### 6.6 Nicht verwendete SDKs

Wir integrieren **keine** der folgenden:

- Analyse-SDKs (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog usw.)
- Absturzberichts-SDKs (Crashlytics, Sentry, Bugsnag usw.)
- Werbe-SDKs (AdMob, Meta Audience Network, AppLovin usw.)
- Attributions-SDKs (AppsFlyer, Adjust, Branch, Kochava usw.)
- A/B-Test-Frameworks
- Social-Media-SDKs
- Authentifizierungsanbieter Dritter

---

## 7. Internationale Datenübermittlungen

Wir übermitteln keine personenbezogenen Daten international, da wir keine personenbezogenen Daten erheben oder verarbeiten.

Durch Sie initiierte Datenflüsse (API-Aufrufe an Civo, Kubernetes, S3, IP-Erkennung) können grenzüberschreitende Übertragungen umfassen. Diese Übermittlungen unterliegen den Datenschutzhinweisen und Übertragungsmechanismen der jeweiligen Betreiber. Für Nutzer aus dem EWR/Vereinigten Königreich stützt sich Civo Ltd auf Angemessenheitsbeschlüsse der EU und des Vereinigten Königreichs sowie gegebenenfalls auf Standardvertragsklauseln (SCCs).

---

## 8. Speicherdauer

Wir speichern keine Daten. Sämtliche Anwendungsdaten werden lokal auf Ihrem Gerät gespeichert und unterliegen ausschließlich Ihrer Kontrolle.

- **Deinstallation der Anwendung** entfernt die in UserDefaults gespeicherten Präferenzen (typischerweise unter `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Schlüsselbund-Einträge** können nach der Deinstallation bestehen bleiben; diese können manuell über die Schlüsselbundverwaltung entfernt werden
- **Zwischenspeicher für Kosten des Vormonats** werden lokal gespeichert und mit dem Container bei der Deinstallation entfernt

---

## 9. Datensicherheit

Obwohl wir keine Daten von Ihnen erheben, setzen wir innerhalb der Anwendung folgende Sicherheitsmaßnahmen um:

- **Speicherung des API-Schlüssels:** macOS-Schlüsselbund mit hardwaregestützter Verschlüsselung (Secure Enclave, sofern verfügbar)
- **Object-Store-Secrets:** durch Touch ID / Systempasswort über das LocalAuthentication-Framework geschützt
- **Kubeconfig-Zugangsdaten:** ausschließlich im Arbeitsspeicher während aktiver Sitzungen gespeichert, niemals persistiert
- **Netzwerkkommunikation:** HTTPS/TLS 1.2+ für sämtliche API-Kommunikation
- **Zertifikatsauthentifizierung:** Kubernetes-API verwendet PKCS#12-Client-Zertifikat-mTLS
- **App Sandbox:** Die Anwendung läuft innerhalb der macOS App Sandbox mit minimal erforderlichen Entitlements
- **Hardened Runtime:** Zusätzliche Sicherheitshärtung zur Laufzeit
- **Keine Telemetrie:** Es werden keinerlei Nutzungsdaten, Analysen oder Absturzberichte übertragen
- **Keine persistente Protokollierung:** Protokolle verwenden `os.Logger` mit `privacy: .private` und werden nicht exportiert

Kein System ist vollständig sicher. Wir empfehlen die Verwendung eines dedizierten API-Schlüssels mit den für Ihren Arbeitsablauf mindestens erforderlichen Civo-Berechtigungen.

---

## 10. Ihre Rechte

### 10.1 Rechte nach DSGVO (EU / EWR / Vereinigtes Königreich)

Sie haben das Recht auf:

- **Auskunft** über Ihre personenbezogenen Daten (Art. 15 DSGVO) — nicht anwendbar, wir speichern keine Daten über Sie
- **Berichtigung** unrichtiger Daten (Art. 16 DSGVO) — nicht anwendbar
- **Löschung** / Recht auf Vergessenwerden (Art. 17 DSGVO) — nicht anwendbar; Sie können lokale Daten durch Deinstallation löschen
- **Einschränkung** der Verarbeitung (Art. 18 DSGVO) — nicht anwendbar
- **Datenübertragbarkeit** (Art. 20 DSGVO) — nicht anwendbar
- **Widerspruch** gegen die Verarbeitung (Art. 21 DSGVO) — nicht anwendbar
- **Widerruf der Einwilligung** jederzeit (Art. 7 Abs. 3 DSGVO) — Sie können die Nutzung der Anwendung jederzeit einstellen
- **Beschwerde** bei einer Aufsichtsbehörde

Diese Rechte werden durch unsere Nulldatenerhebungs-Richtlinie erfüllt. Sollte sich dies in einer künftigen Version ändern, werden wir Sie benachrichtigen und den vollständigen Rechterahmen umsetzen.

### 10.2 Rechte nach CCPA / CPRA (Kalifornien, USA)

Einwohner Kaliforniens haben das Recht auf:

- Kenntnis darüber, welche personenbezogenen Informationen erhoben, verwendet, weitergegeben oder verkauft werden
- Löschung personenbezogener Informationen
- Widerspruch gegen den Verkauf oder die Weitergabe personenbezogener Informationen
- Nichtdiskriminierung bei Ausübung von Datenschutzrechten
- Berichtigung unrichtiger personenbezogener Informationen
- Einschränkung der Nutzung sensibler personenbezogener Informationen

Wir verkaufen keine personenbezogenen Informationen. Wir geben keine personenbezogenen Informationen zu kontextübergreifender verhaltensbezogener Werbung weiter. Wir erheben keine personenbezogenen Informationen im Sinne des CCPA/CPRA.

### 10.3 Rechte nach weiteren US-Staatsgesetzen (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR usw.)

Einwohner von Virginia, Colorado, Connecticut, Utah, Texas, Oregon, Iowa, Montana, Florida, Tennessee, Indiana, Delaware, New Jersey und anderen US-Bundesstaaten mit Datenschutzgesetzen haben Rechte auf Auskunft, Löschung, Berichtigung und Widerspruch gegen zielgerichtete Werbung / Verkauf / Profiling. Diese Rechte werden durch unsere Nulldatenerhebungs-Richtlinie erfüllt.

### 10.4 Rechte nach PIPEDA und Provinzgesetzen (Kanada)

Kanadische Einwohner haben das Recht auf Auskunft, Anfechtung der Richtigkeit, Widerruf der Einwilligung und Beschwerde beim Office of the Privacy Commissioner of Canada (oder Provinzbehörden in Quebec, British Columbia, Alberta).

### 10.5 Rechte nach australischem Privacy Act

Australische Einwohner haben das Recht auf Auskunft und Berichtigung ihrer personenbezogenen Informationen sowie auf Beschwerde beim Office of the Australian Information Commissioner (OAIC).

### 10.6 Rechte nach LGPD (Brasilien)

Brasilianische Einwohner haben das Recht auf Bestätigung der Verarbeitung, Auskunft, Berichtigung, Anonymisierung, Übertragbarkeit, Information über Weitergaben und Widerruf der Einwilligung. Beschwerden können an die Autoridade Nacional de Proteção de Dados (ANPD) gerichtet werden.

### 10.7 Rechte nach APPI (Japan)

Japanische Einwohner haben das Recht auf Offenlegung, Berichtigung, Löschung und Einstellung der Nutzung. Beschwerden können an die Personal Information Protection Commission (PPC) gerichtet werden.

### 10.8 Rechte nach PIPA (Südkorea)

Südkoreanische Einwohner haben das Recht auf Auskunft, Berichtigung, Löschung, Aussetzung der Verarbeitung und Geltendmachung von Schadensersatz. Beschwerden können an die Personal Information Protection Commission (PIPC) gerichtet werden.

### 10.9 Rechte nach PDPA (Singapur / Thailand)

Einwohner haben das Recht auf Auskunft, Berichtigung und Widerruf der Einwilligung. Beschwerden können an die Personal Data Protection Commission (PDPC) des jeweiligen Landes gerichtet werden.

### 10.10 Rechte nach PIPL (China)

Chinesische Einwohner haben das Recht zu wissen, zu entscheiden, einzuschränken, abzulehnen, Einsicht zu nehmen, zu kopieren, zu übertragen, zu berichtigen, zu löschen und eine Erläuterung zu den Verarbeitungsregeln zu verlangen.

### 10.11 Rechte nach DPDP Act (Indien)

Indische Einwohner haben das Recht auf Information, Berichtigung, Löschung, Beschwerdebearbeitung und Nominierung.

### 10.12 Rechte nach POPIA (Südafrika)

Südafrikanische Einwohner haben das Recht auf Auskunft, Berichtigung, Löschung und Beschwerde beim Information Regulator.

### 10.13 Rechte nach Schweizer DSG

Schweizer Einwohner haben das Recht auf Information, Auskunft, Berichtigung, Löschung, Widerspruch und Datenübertragbarkeit. Beschwerden können an den Eidgenössischen Datenschutz- und Öffentlichkeitsbeauftragten (EDÖB) gerichtet werden.

### 10.14 Rechte nach neuseeländischem Privacy Act

Neuseeländische Einwohner haben das Recht auf Auskunft und Berichtigung personenbezogener Informationen sowie auf Beschwerde beim Privacy Commissioner.

### 10.15 Ausübung Ihrer Rechte

Da wir keine Daten über Sie speichern, sind diese Rechte standardmäßig erfüllt. Sollten Sie glauben, dass wir trotz dieser Richtlinie personenbezogene Daten über Sie speichern, wenden Sie sich an moin@berger-rosenstock.de.

---

## 11. Datenschutz bei Kindern

Die Anwendung trägt im Apple App Store die Altersfreigabe **4+** und ist daher technisch für Nutzer aller Altersgruppen zugänglich. Die Anwendung ist jedoch ein technisches Werkzeug zur Infrastrukturverwaltung, das sich an Administratoren von Civo-Cloud-Konten richtet. Ein Civo-Cloud-Konto setzt voraus, dass der Kontoinhaber in seiner Rechtsordnung vertragsfähig ist.

**Wir erheben wissentlich keine personenbezogenen Informationen von irgendwem, einschließlich Kindern unter 13 Jahren (COPPA, USA), 16 Jahren (DSGVO-K, EU) oder dem in Ihrer Rechtsordnung geltenden Einwilligungsalter.**

Da die Anwendung eine strikte Nulldatenerhebungs-Richtlinie umsetzt (siehe Abschnitt 2), werden keinerlei personenbezogene Informationen über einen Nutzer — unabhängig vom Alter — erhoben, übertragen, auf unseren Servern gespeichert oder an Dritte weitergegeben. Damit werden erfüllt:

- **COPPA** (Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506, USA)
- **Art. 8 DSGVO** (EU)
- **PIPEDA** und anwendbare Provinzgesetze (Kanada)
- **Art. 14 LGPD** (Brasilien)
- **APPI** (Japan)
- **Australian Privacy Act** und APP 8 zum Schutz von Kindern

Sollten Sie Elternteil oder Erziehungsberechtigter sein und der Ansicht sein, dass Ihr Kind personenbezogene Informationen angegeben hat, wenden Sie sich an moin@berger-rosenstock.de. Wir werden die Angelegenheit unverzüglich prüfen und solche Informationen bei Auffinden löschen.

---

## 12. Cookies und Tracking

Die Anwendung ist eine native macOS-Anwendung und verwendet keine Cookies, Web Beacons, Pixel-Tags, Fingerprinting oder ähnliche Tracking-Technologien.

Die Anwendung enthält keine eingebetteten Webviews, die Inhalte Dritter laden.

---

## 13. Automatisierte Entscheidungsfindung

Wir nehmen keine automatisierte Entscheidungsfindung oder Profilbildung vor, die rechtliche Wirkung entfaltet oder Sie in ähnlicher Weise erheblich beeinträchtigt. Die Anwendung führt keine automatisierten Entscheidungen auf Grundlage personenbezogener Daten durch.

---

## 14. Links und Dienste Dritter

Die Anwendung kann Links zu Websites Dritter enthalten (z. B. Civo-Website, Apple App Store, Plattform zur Online-Streitbeilegung). Wir sind für die Datenschutzpraktiken oder Inhalte von Diensten Dritter nicht verantwortlich. Bitte lesen Sie deren Datenschutzerklärungen, bevor Sie Daten bereitstellen.

---

## 15. Änderungen dieser Erklärung

Wir können diese Datenschutzerklärung von Zeit zu Zeit aktualisieren.

- Wesentliche Änderungen werden mindestens 30 Tage vor ihrem Inkrafttreten über die Anwendung oder den App-Store-Eintrag kommuniziert
- Das „Gültig ab"-Datum am Anfang spiegelt die jüngste Überarbeitung wider
- Wir werden unsere Datenschutzpraktiken nicht rückwirkend ändern, um ohne Ihre ausdrückliche Einwilligung Daten zu erheben

---

## 16. Kontakt

Für datenschutzbezogene Anfragen oder zur Ausübung Ihrer Rechte:

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Deutschland
E-Mail: moin@berger-rosenstock.de

Für Einwohner der EU können Sie sich auch an die zuständige Aufsichtsbehörde in Ihrem Mitgliedstaat wenden. Eine Liste der EU-Aufsichtsbehörden ist verfügbar unter: https://edpb.europa.eu/about-edpb/board/members_en

Für Einwohner des Vereinigten Königreichs ist die Aufsichtsbehörde das Information Commissioner's Office (ICO): https://ico.org.uk

---

## 17. Regionale Bestimmungen

### 17.1 Europäische Union / Europäischer Wirtschaftsraum

- Der Betrieb erfolgt konform mit der DSGVO, soweit auf lokale Verarbeitungen auf Ihrem Gerät anwendbar
- Aufsichtsbehörde des Verantwortlichen ist die zuständige deutsche Landesdatenschutzbehörde
- Datenschutz-Folgenabschätzungen (DSFA) sind nicht erforderlich (keine Erhebung)

### 17.2 Deutschland

- Einhaltung der DSGVO und des Bundesdatenschutzgesetzes (BDSG)
- Zuständige Aufsichtsbehörde: Landesbeauftragte für Datenschutz des jeweiligen Bundeslandes (der Verantwortliche hat seinen Sitz in Deutschland)

### 17.3 Österreich

- Einhaltung der DSGVO und des Datenschutzgesetzes (DSG)
- Aufsichtsbehörde: Datenschutzbehörde (DSB)

### 17.4 Schweiz

- Einhaltung des revidierten Bundesgesetzes über den Datenschutz (revDSG), in Kraft seit 1. September 2023
- Aufsichtsbehörde: Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB)

### 17.5 Vereinigtes Königreich

- Einhaltung von UK GDPR und Data Protection Act 2018
- Aufsichtsbehörde: Information Commissioner's Office (ICO)

### 17.6 Frankreich

- Einhaltung der DSGVO und des Loi Informatique et Libertés
- Aufsichtsbehörde: Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Italien

- Einhaltung der DSGVO und des Codice in materia di protezione dei dati personali
- Aufsichtsbehörde: Garante per la Protezione dei Dati Personali

### 17.8 Spanien

- Einhaltung der DSGVO und der Ley Orgánica 3/2018 (LOPDGDD)
- Aufsichtsbehörde: Agencia Española de Protección de Datos (AEPD)

### 17.9 Niederlande

- Einhaltung der DSGVO und der Uitvoeringswet AVG (UAVG)
- Aufsichtsbehörde: Autoriteit Persoonsgegevens (AP)

### 17.10 Polen

- Einhaltung der DSGVO und der Ustawa o ochronie danych osobowych
- Aufsichtsbehörde: Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portugal

- Einhaltung der DSGVO und der Lei n.º 58/2019
- Aufsichtsbehörde: Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 Belgien

- Einhaltung der DSGVO und des Loi du 30 juillet 2018
- Aufsichtsbehörde: Gegevensbeschermingsautoriteit (APD-GBA)

### 17.13 Irland

- Einhaltung der DSGVO und des Data Protection Act 2018
- Aufsichtsbehörde: Data Protection Commission (DPC)

### 17.14 Nordische Länder (Dänemark, Finnland, Norwegen, Schweden, Island)

- Einhaltung der DSGVO (und der EWR-Entsprechungen für Norwegen und Island)
- Nationale Aufsichtsbehörden: Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Weitere Mitgliedstaaten der EU/des EWR

Einhaltung der DSGVO und der jeweiligen nationalen Umsetzung. Aufsichtsbehörden: https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 Vereinigte Staaten

- Einhaltung der anwendbaren staatlichen Datenschutzgesetze: CCPA/CPRA (Kalifornien), VCDPA (Virginia), CPA (Colorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Texas), OCPA (Oregon), IDPA (Iowa), MCDPA (Montana), FDBR (Florida), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (New Jersey)
- „Do Not Track"- und „Global Privacy Control"-Signale werden, soweit technisch möglich, beachtet (die Anwendung führt kein Tracking durch)
- COPPA-Konformität für Nutzer unter 13 Jahren

### 17.17 Kanada

- Einhaltung von PIPEDA und anwendbaren Provinzgesetzen: Quebec Act 25, British Columbia PIPA, Alberta PIPA
- Beschwerden: Office of the Privacy Commissioner of Canada (OPC) und Provinzbehörden

### 17.18 Mexiko

- Einhaltung des Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Aufsichtsbehörde: Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brasilien

- Einhaltung der LGPD
- Aufsichtsbehörde: Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentinien, Chile, Kolumbien, Peru, Uruguay

- Einhaltung der nationalen Datenschutzgesetze (Gesetz 25.326 / Gesetz 19.628 / Gesetz 1581 / Gesetz 29733 / Gesetz 18.331)

### 17.21 Australien

- Einhaltung des Privacy Act 1988 und der Australian Privacy Principles (APPs)
- Aufsichtsbehörde: Office of the Australian Information Commissioner (OAIC)

### 17.22 Neuseeland

- Einhaltung des Privacy Act 2020
- Aufsichtsbehörde: Office of the Privacy Commissioner

### 17.23 Japan

- Einhaltung des Act on the Protection of Personal Information (APPI)
- Aufsichtsbehörde: Personal Information Protection Commission (PPC)

### 17.24 Südkorea

- Einhaltung des Personal Information Protection Act (PIPA)
- Aufsichtsbehörde: Personal Information Protection Commission (PIPC)

### 17.25 Singapur

- Einhaltung des Personal Data Protection Act (PDPA)
- Aufsichtsbehörde: Personal Data Protection Commission (PDPC)

### 17.26 Thailand

- Einhaltung des Personal Data Protection Act B.E. 2562 (2019)
- Aufsichtsbehörde: Personal Data Protection Committee

### 17.27 China

- Einhaltung des Personal Information Protection Law (PIPL), Cybersecurity Law (CSL) und Data Security Law (DSL)

### 17.28 Hongkong

- Einhaltung der Personal Data (Privacy) Ordinance (PDPO)
- Aufsichtsbehörde: Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 Indien

- Einhaltung des Digital Personal Data Protection Act 2023 (DPDP Act) und des Information Technology Act 2000
- Aufsichtsbehörde: Data Protection Board of India

### 17.30 Vereinigte Arabische Emirate

- Einhaltung des Federal Decree-Law Nr. 45 von 2021 (Personal Data Protection Law)

### 17.31 Saudi-Arabien

- Einhaltung des Personal Data Protection Law (PDPL)

### 17.32 Türkei

- Einhaltung des Personal Data Protection Law Nr. 6698 (KVKK)
- Aufsichtsbehörde: Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Israel

- Einhaltung des Privacy Protection Law, 5741-1981 und der Privacy Protection Regulations
- Aufsichtsbehörde: Privacy Protection Authority (PPA)

### 17.34 Südafrika

- Einhaltung des Protection of Personal Information Act (POPIA)
- Aufsichtsbehörde: Information Regulator

### 17.35 Kenia, Nigeria, Ägypten, Marokko

- Einhaltung der nationalen Datenschutzgesetze (Data Protection Act 2019 Kenia, NDPR / NDPA Nigeria, Gesetz Nr. 151 von 2020 Ägypten, Gesetz 09-08 Marokko)

### 17.36 Weitere Rechtsordnungen

Für Nutzer in Rechtsordnungen, die oben nicht ausdrücklich aufgeführt sind, stellt der Nulldatenerhebungs-Ansatz der Anwendung die Einhaltung der Grundsätze der Datenminimierung und Zweckbindung sicher, die modernen Datenschutzrahmen gemein sind. Sollte Ihr lokales Recht zusätzliche Rechte vorsehen, werden diese Rechte respektiert.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. Alle Rechte vorbehalten.
