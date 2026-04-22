# Nutzungsbedingungen

## Civo Cloud Manager

**Gültig ab:** April 2026
**Zuletzt aktualisiert:** April 2026

**Anbieter:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Deutschland
E-Mail: moin@berger-rosenstock.de
USt-IdNr.: DE455096022

---

## 1. Geltungsbereich und Annahme

### 1.1 Vereinbarung

Diese Nutzungsbedingungen („Bedingungen") regeln Ihren Zugang zu und Ihre Nutzung der Anwendung Civo Cloud Manager („die Anwendung"), die von Berger & Rosenstock GbR („der Anbieter", „wir", „uns", „unser") bereitgestellt wird.

### 1.2 Annahme

Durch Installation, Zugriff auf oder Nutzung der Anwendung erklären Sie sich mit diesen Bedingungen einverstanden. Falls Sie nicht einverstanden sind, dürfen Sie die Anwendung weder installieren noch nutzen.

### 1.3 Berechtigung

Die Anwendung trägt im Apple App Store die Altersfreigabe **4+**. Um einen verbindlichen Vertrag zu schließen, müssen Sie in Ihrer Rechtsordnung vertragsfähig sein. Ein Civo-Cloud-Konto, das für eine sinnvolle Nutzung der Anwendung erforderlich ist, setzt voraus, dass der Kontoinhaber vertragsfähig ist.

### 1.4 Geschäftliche Nutzung

Wenn Sie die Anwendung im Namen einer Organisation nutzen, sichern Sie zu, dass Sie befugt sind, diese Organisation an diese Bedingungen zu binden.

### 1.5 Apple Licensed Application End User License Agreement

Diese Bedingungen ergänzen das Apple Licensed Application End User License Agreement (Apple EULA) zwischen Ihnen und Apple Inc. Im Falle eines Widerspruchs zwischen diesen Bedingungen und der Apple EULA hat die Apple EULA in den von ihr erfassten Angelegenheiten Vorrang.

---

## 2. Leistungen

### 2.1 Beschreibung

Die Anwendung ist eine native macOS-Anwendung, die die Verwaltung der Civo-Cloud-Infrastruktur (virtuelle Instanzen, Kubernetes-Cluster, Datenbanken, Firewalls, Netzwerke, Load Balancer, Volumes, Object Stores, DNS, SSH-Schlüssel) sowie den direkten Zugriff auf die Kubernetes-API über die eigenen API-Zugangsdaten des Nutzers ermöglicht.

Die Anwendung verbindet sich direkt von Ihrem Gerät mit:

- Der Civo-Cloud-REST-API (`api.civo.com`)
- Kubernetes-API-Servern Ihrer Civo-Cluster (über mTLS)
- S3-kompatiblen Object-Storage-Endpunkten Ihres Civo-Kontos
- Diensten zur Erkennung der öffentlichen IP (ipify.org, ifconfig.me, icanhazip.com)
- Apple App Store / StoreKit zur Kaufabwicklung

Der Anbieter betreibt keinerlei Backend-Dienst, Zwischenserver oder Proxy. Die gesamte Kommunikation erfolgt direkt zwischen Ihrem Gerät und den jeweiligen Drittanbietern.

### 2.2 Kostenlose und kostenpflichtige Funktionen

Die Firewall-Verwaltungsfunktionen in der Menüleiste sind kostenfrei. „Full Access" — wodurch das Verwaltungs-Dashboard für alle unterstützten Ressourcentypen freigeschaltet wird — ist ein einmaliger In-App-Kauf, der ausschließlich über den Apple App Store abgewickelt wird (siehe Abschnitt 7).

### 2.3 Änderungen

Der Anbieter kann jede Funktionalität der Anwendung jederzeit ändern, aussetzen oder einstellen. Wesentliche Änderungen, die gekaufte Funktionen betreffen, werden, soweit praktikabel, mindestens dreißig (30) Tage im Voraus kommuniziert.

### 2.4 Verfügbarkeit

Die Anwendung wird auf „as available"-Basis bereitgestellt. Der Anbieter garantiert keinen unterbrechungsfreien Zugriff oder ständige Verfügbarkeit; die Funktionsfähigkeit der Anwendung hängt von der Verfügbarkeit von Diensten Dritter (Civo Cloud, Apple App Store, IP-Erkennungsanbieter) ab, die außerhalb der Kontrolle des Anbieters liegen.

---

## 3. Konten

Die Anwendung erfordert kein Konto beim Anbieter. Die gesamte Authentifizierung erfolgt über:

- Ihren Civo-API-Schlüssel (lokal im macOS-Schlüsselbund gespeichert)
- Ihre Kubernetes-Kubeconfig (von der Civo-API abgerufen)
- Ihre Apple-ID (für die Prüfung von In-App-Käufen, abgewickelt durch Apple)

Sie sind verantwortlich für:

- Die Geheimhaltung Ihres Civo-API-Schlüssels und sonstiger Zugangsdaten
- Alle mit Ihren Zugangsdaten durchgeführten Aktivitäten
- Alle aus Ihrer Nutzung der Anwendung resultierenden Ressourcenänderungen, Kosten und Abrechnungsfolgen
- Die Konfiguration der Civo-API-Schlüsselberechtigungen nach dem Prinzip der geringsten Rechte

Der Anbieter hat keine Möglichkeit, auf Ihre Civo-Zugangsdaten zuzugreifen, sie wiederherzustellen oder zurückzusetzen. Der Verlust von Zugangsdaten liegt allein in Ihrer Verantwortung.

---

## 4. Nutzerinhalte

Die Anwendung hostet, speichert oder überträgt keine von Nutzern erzeugten Inhalte auf einen vom Anbieter betriebenen Server. Sämtliche Inhalte, Daten oder Konfigurationen, die Sie mit der Anwendung erstellen (z. B. Instanznamen, SSH-Schlüssel, Firewall-Regel-Labels, Object-Store-Dateien), werden gespeichert:

- Lokal auf Ihrem Gerät, oder
- In Ihrem eigenen Civo-Cloud-Konto

Sie behalten sämtliche Rechte, Titel und Anteile an solchen Inhalten. Der Anbieter beansprucht keine Lizenz, kein Eigentum und keine sonstigen Rechte an Ihren Inhalten.

---

## 5. Zulässige Nutzung

Sie dürfen die Anwendung nicht verwenden, um:

- Gegen geltendes Recht, Vorschriften oder Rechte Dritter zu verstoßen
- Auf Civo-Ressourcen zuzugreifen oder diese zu betreiben, zu denen Sie nicht berechtigt sind
- Den Civo-Cloud-Dienst, Kubernetes-Cluster, die Ihnen nicht gehören, oder die Anwendung selbst zu beeinträchtigen oder zu stören
- Die Anwendung zu reverse-engineeren, zu dekompilieren, zu disassemblieren oder Quellcode daraus abzuleiten, außer soweit eine solche Einschränkung durch geltendes Recht untersagt ist
- Sicherheits- oder Zugriffskontrollmechanismen zu umgehen (einschließlich der In-App-Kauf-Paywall)
- Die Anwendung zu verbreiten, unterzulizenzieren, zu verleasen, zu vermieten, zu verkaufen oder anderweitig kommerziell zu verwerten
- Eigentumsvermerke, Copyright-Kennzeichnungen oder Markenzeichen zu entfernen, zu verändern oder zu verbergen
- Die Anwendung zum Angriff, zur Kompromittierung oder zum Testen der Sicherheit von Systemen zu nutzen, die Ihnen nicht gehören oder für die Sie keine ausdrückliche schriftliche Testberechtigung besitzen
- Die Anwendung für Zwecke zu verwenden, die nach den Gesetzen der Bundesrepublik Deutschland, der Europäischen Union oder Ihrer Rechtsordnung verboten sind

---

## 6. Geistiges Eigentum

### 6.1 Eigentum

Die Anwendung (einschließlich Quellcode, Design, Text, Grafiken, Symbole, Lokalisierungen und aller zugehörigen Rechte des geistigen Eigentums) ist das ausschließliche Eigentum des Anbieters und durch deutsche, europäische und internationale Urheberrechts-, Marken- und sonstige Gesetze zum Schutz des geistigen Eigentums geschützt.

### 6.2 Lizenzerteilung

Vorbehaltlich Ihrer Einhaltung dieser Bedingungen und der Apple EULA gewährt Ihnen der Anbieter eine beschränkte, nicht ausschließliche, nicht übertragbare, nicht unterlizenzierbare, widerrufliche Lizenz zur Installation und Nutzung der Anwendung auf von Ihnen besessenen oder kontrollierten Apple-Geräten, ausschließlich zur persönlichen oder internen geschäftlichen Nutzung zur Verwaltung Ihrer Civo-Cloud-Infrastruktur.

### 6.3 Marken Dritter

„Civo" ist eine Marke der Civo Ltd. „Apple", „App Store", „macOS", „iCloud", „StoreKit", „TestFlight" sind Marken von Apple Inc. „Kubernetes" ist eine Marke der Linux Foundation. Alle sonstigen Marken sind Eigentum ihrer jeweiligen Inhaber. Der Anbieter ist mit keiner dieser Parteien verbunden, wird von ihnen nicht unterstützt oder gesponsert.

### 6.4 Feedback

Jegliche Rückmeldungen, Vorschläge oder Ideen, die Sie dem Anbieter bezüglich der Anwendung übermitteln, können vom Anbieter ohne Einschränkung und ohne Vergütung an Sie verwendet werden.

---

## 7. Zahlungen und Abonnements

### 7.1 In-App-Kauf

„Full Access" wird als nicht-verbrauchbarer In-App-Kauf über den Apple App Store zu einem einmaligen Entgelt verkauft. Der Preis wird in der Anwendung in Ihrer Landeswährung vor dem Kauf angezeigt.

### 7.2 Zahlungsabwicklung

Die Zahlung wird ausschließlich durch Apple Inc. abgewickelt. Der Anbieter erhält, speichert oder verarbeitet keinerlei Zahlungsinformationen. Sämtliche Zahlungs-, Rückerstattungs- und Rechnungsangelegenheiten unterliegen den Apple Media Services Terms und der Apple EULA.

### 7.3 Familienfreigabe

„Full Access" ist für die Apple Familienfreigabe aktiviert. Mitglieder Ihrer Apple-Familienfreigabegruppe können den Kauf auf ihren eigenen Geräten nutzen, vorbehaltlich der Apple-Regeln zur Familienfreigabe.

### 7.4 Apple Angebotscodes

Der Anbieter kann Apple-Angebotscodes zu Werbezwecken herausgeben. Angebotscodes können über die Funktion „Code einlösen" in der Anwendung oder im App Store eingelöst werden.

### 7.5 Rückerstattungen

Rückerstattungen werden ausschließlich durch Apple gemäß der Apple-Rückerstattungsrichtlinie abgewickelt. Gesetzliche Verbraucherrechte nach geltendem Recht (siehe Abschnitt 15) bleiben unberührt. Insbesondere werden EU-Verbraucher darüber informiert, dass das gesetzliche 14-tägige Widerrufsrecht für digitale Inhalte erlischt, wenn die Leistung mit Ihrer vorherigen ausdrücklichen Zustimmung begonnen hat — Apple setzt dies über den Bestätigungsdialog zum Kaufzeitpunkt um.

### 7.6 Steuern

Der angezeigte Preis enthält sämtliche anwendbaren Steuern (Mehrwertsteuer, Verkaufssteuer), wie von Apple auf Grundlage Ihres Landes ermittelt.

---

## 8. Dienste Dritter

Die Nutzung der Anwendung erfordert die Interaktion mit Diensten Dritter. Ihre Nutzung dieser Dienste unterliegt den jeweiligen Bedingungen:

- **Civo Cloud:** https://www.civo.com/terms
- **Apple App Store / Apple-ID:** https://www.apple.com/legal/internet-services/terms/
- **Kubernetes-Cluster:** den Bedingungen Ihres Clusterbetreibers (Civo)

Der Anbieter ist an keiner Vereinbarung zwischen Ihnen und einem Drittanbieter beteiligt und ist nicht verantwortlich für die Verfügbarkeit, Richtigkeit oder das Verhalten dieser Dienste.

---

## 9. Gewährleistungsausschluss

DIE ANWENDUNG WIRD „WIE BESEHEN" UND „WIE VERFÜGBAR" OHNE GEWÄHRLEISTUNGEN JEGLICHER ART BEREITGESTELLT, WEDER AUSDRÜCKLICH NOCH STILLSCHWEIGEND, EINSCHLIESSLICH, ABER NICHT BESCHRÄNKT AUF GEWÄHRLEISTUNGEN DER MARKTGÄNGIGKEIT, DER EIGNUNG FÜR EINEN BESTIMMTEN ZWECK, DER GENAUIGKEIT, VOLLSTÄNDIGKEIT ODER NICHTVERLETZUNG.

DER ANBIETER GARANTIERT NICHT, DASS:

- DIE ANWENDUNG UNTERBRECHUNGSFREI, FEHLERFREI ODER SICHER IST
- DIE ANWENDUNG CIVO-CLOUD-RESSOURCEN KORREKT ANZEIGT, ERSTELLT, ÄNDERT, LÖSCHT ODER VERWALTET
- VON DER ANWENDUNG ANGEZEIGTE DATEN GENAU, VOLLSTÄNDIG ODER AKTUELL SIND
- DIE ANWENDUNG MIT ALLEN CIVO-API-VERSIONEN, -FUNKTIONEN ODER -REGIONEN KOMPATIBEL IST

**Destruktive Operationen.** Die Anwendung kann unwiderrufliche Operationen auf Ihrem Civo-Cloud-Konto durchführen, einschließlich der Löschung von Kubernetes-Clustern, Datenbanken, Volumes, Object Stores, Instanzen, SSH-Schlüsseln und Firewall-Regeln. Alle destruktiven Operationen erfordern eine ausdrückliche Nutzerbestätigung (in der Regel durch Eingabe des Ressourcennamens). DER ANBIETER ÜBERNIMMT KEINE VERANTWORTUNG für unbeabsichtigte Löschungen, Datenverluste, Kostenüberschreitungen oder Infrastrukturschäden, die durch Ihre Nutzung der Anwendung verursacht werden.

Es wird dringend empfohlen, unabhängige Sicherungen aller kritischen Daten zu führen, einen dedizierten API-Schlüssel mit den mindestens erforderlichen Civo-Berechtigungen zu verwenden und alle Bestätigungsdialoge sorgfältig zu prüfen.

Nichts in diesem Abschnitt schließt eine Gewährleistung aus oder beschränkt sie, die nach geltendem Recht nicht ausgeschlossen oder beschränkt werden kann (siehe Abschnitt 15).

---

## 10. Haftungsbeschränkung

SOWEIT NACH GELTENDEM RECHT ZULÄSSIG:

### 10.1 Ausschlüsse

DER ANBIETER HAFTET NICHT FÜR MITTELBARE, ZUFÄLLIGE, BESONDERE, FOLGESCHÄDEN, STRAFSCHADENSERSATZ ODER EXEMPLARISCHE SCHÄDEN, EINSCHLIESSLICH, ABER NICHT BESCHRÄNKT AUF:

- Verlust von Daten, Einnahmen, Gewinnen oder Geschäftschancen
- Kosten der Beschaffung von Ersatzdiensten
- Beschädigung oder Löschung von Cloud-Infrastruktur, Ressourcen oder Daten
- Unberechtigten Zugriff infolge kompromittierter API-Schlüssel

### 10.2 Haftungshöchstgrenze

DIE GESAMTE AGGREGIERTE HAFTUNG DES ANBIETERS IHNEN GEGENÜBER FÜR ALLE ANSPRÜCHE, DIE SICH AUS ODER IM ZUSAMMENHANG MIT DER ANWENDUNG ERGEBEN, IST AUF DEN BETRAG BESCHRÄNKT, DEN SIE IN DEN ZWÖLF (12) MONATEN VOR DEM SCHADENSEREIGNIS TATSÄCHLICH FÜR DIE ANWENDUNG GEZAHLT HABEN.

### 10.3 Ausnahmen

Nichts in diesen Bedingungen schließt eine Haftung aus oder beschränkt sie für:

- Tod oder Körperverletzung durch Fahrlässigkeit
- Arglist oder arglistige Täuschung
- Vorsatz oder grobe Fahrlässigkeit (nach deutschem Recht, §§ 276, 309 BGB)
- Verletzung wesentlicher Vertragspflichten (Kardinalpflichten), begrenzt auf vorhersehbare, vertragstypische Schäden
- Sonstige Haftung, die nach geltendem Recht nicht ausgeschlossen oder beschränkt werden kann

### 10.4 Produkthaftung

Die Haftung nach dem deutschen Produkthaftungsgesetz bleibt unberührt.

---

## 11. Freistellung

Sie verpflichten sich, den Anbieter, seine Partner, Mitarbeiter und Beauftragten von und gegen sämtliche Ansprüche, Verbindlichkeiten, Schäden, Verluste, Kosten, Aufwendungen oder Gebühren (einschließlich angemessener Anwaltskosten) freizustellen, zu verteidigen und schadlos zu halten, die sich ergeben aus oder im Zusammenhang stehen mit:

- Ihrem Verstoß gegen diese Bedingungen
- Ihrem Verstoß gegen Gesetze oder Rechte Dritter
- Ihrer Nutzung der Anwendung zum Zugriff auf oder zur Verwaltung von Infrastruktur, zu der Sie nicht berechtigt sind
- Allen Inhalten oder Konfigurationen, die Sie über die Anwendung erstellen, ändern oder löschen

Diese Freistellungspflicht gilt nicht für Verbraucher im Sinne anwendbarer Verbraucherschutzgesetzgebung, soweit zwingendes Recht eine solche Freistellung untersagt.

---

## 12. Beendigung

### 12.1 Beendigung durch Sie

Sie können diese Bedingungen jederzeit beenden, indem Sie die Anwendung von Ihren Geräten deinstallieren.

### 12.2 Beendigung durch den Anbieter

Der Anbieter kann Ihre Lizenz zur Nutzung der Anwendung unverzüglich beenden oder aussetzen, wenn Sie wesentlich gegen diese Bedingungen verstoßen. Im Falle der Beendigung:

- Erlischt Ihr Recht zur Nutzung der Anwendung unverzüglich
- Müssen Sie die Anwendung von Ihren Geräten deinstallieren
- Überdauern die Abschnitte 6, 9, 10, 11, 13, 14, 16 die Beendigung

### 12.3 Auswirkung auf den Kauf

Die Beendigung berechtigt Sie nicht zu einer Rückerstattung Ihres In-App-Kaufs, außer soweit nach geltendem Verbraucherschutzrecht oder der Apple-Rückerstattungsrichtlinie erforderlich.

---

## 13. Anwendbares Recht und Streitbeilegung

### 13.1 Anwendbares Recht

Diese Bedingungen unterliegen dem Recht der Bundesrepublik Deutschland unter Ausschluss seiner Kollisionsnormen und des UN-Kaufrechts (CISG).

Für Verbraucher innerhalb der Europäischen Union / des EWR entzieht Ihnen diese Rechtswahl nicht den zwingenden Verbraucherschutz des Rechts Ihres gewöhnlichen Aufenthaltsstaates.

### 13.2 Gerichtsstand

Für Kaufleute, juristische Personen des öffentlichen Rechts und öffentlich-rechtliche Sondervermögen ist ausschließlicher Gerichtsstand für alle Streitigkeiten aus diesen Bedingungen Bad Nauheim, Deutschland.

Für Verbraucher gilt der gesetzliche Gerichtsstand. Sie können Verfahren vor den Gerichten Ihres gewöhnlichen Aufenthaltsstaates anstrengen.

### 13.3 EU-Online-Streitbeilegung

Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung unter https://ec.europa.eu/consumers/odr bereit.

### 13.4 Verbraucherschlichtung

Der Anbieter ist weder verpflichtet noch bereit, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle im Sinne des deutschen Verbraucherstreitbeilegungsgesetzes (VSBG) teilzunehmen, sofern nicht gesetzlich erforderlich.

---

## 14. Regionale Bestimmungen

### 14.1 Deutschland

- Verbraucherrechte nach §§ 312 ff., §§ 327 ff. BGB (digitale Produkte) bleiben unberührt
- Gesetzliche Widerrufsrechte nach § 355 BGB gelten, sofern anwendbar

### 14.2 Europäische Union / EWR

- Verbraucherrechterichtlinie 2011/83/EU und Digitale-Inhalte-Richtlinie (EU) 2019/770 gelten, sofern Sie Verbraucher sind
- Anwendbare Hinweise nach Artikel 12 des Digital Services Act (Verordnung (EU) 2022/2065) finden sich im Impressum

### 14.3 Vereinigtes Königreich

- Consumer Rights Act 2015 gilt, sofern Sie Verbraucher mit Wohnsitz im Vereinigten Königreich sind
- Digitale Inhalte müssen von zufriedenstellender Qualität, zweckgeeignet und wie beschrieben sein

### 14.4 Schweiz

- Zwingende Verbraucherbestimmungen des Schweizer Obligationenrechts (OR) bleiben unberührt
- Das Bundesgesetz gegen den unlauteren Wettbewerb (UWG) gilt

### 14.5 Vereinigte Staaten

- Diese Bedingungen sollen keine Rechte nach bundesstaatlichen Verbraucherschutzgesetzen begründen, die ihrem Wortlaut nach nicht anwendbar sind
- Einwohner Kaliforniens: Civil Code § 1789.3 Hinweis auf Verbraucherrechte — Kontakt moin@berger-rosenstock.de

### 14.6 Kanada

- Quebec Consumer Protection Act gilt für Einwohner Quebecs, soweit zwingend
- Vertragssprache: Diese Bedingungen werden in englischer Sprache bereitgestellt; französische Fassungen sind verfügbar, soweit dies durch die Charta der französischen Sprache (Quebec) gefordert wird

### 14.7 Australien

- Garantien des Australian Consumer Law (Competition and Consumer Act 2010, Schedule 2) gelten, sofern Sie Verbraucher sind — diese Garantien können nicht ausgeschlossen werden

### 14.8 Neuseeland

- Consumer Guarantees Act 1993 gilt, sofern Sie Verbraucher für persönliche, häusliche oder Haushaltszwecke sind

### 14.9 Japan

- Consumer Contract Act (消費者契約法) gilt; Bestimmungen dieser Bedingungen, die nach diesem Gesetz ungültig wären, werden auf das erforderliche Maß beschränkt

### 14.10 Südkorea

- Act on the Regulation of Terms and Conditions (약관의 규제에 관한 법률) gilt

### 14.11 Brasilien

- Consumer Defense Code (CDC, Gesetz Nr. 8.078/1990) gilt; auf Verbraucherrechte kann nicht verzichtet werden

### 14.12 Indien

- Consumer Protection Act 2019 und E-Commerce Rules 2020 gelten, sofern Sie Verbraucher sind

### 14.13 Weitere Rechtsordnungen

Für Nutzer in Rechtsordnungen, die oben nicht ausdrücklich aufgeführt sind, gelten diese Bedingungen, soweit dies nach lokalem zwingenden Verbraucherschutzrecht zulässig ist.

---

## 15. Verbraucherrechte (Pflichthinweise)

Diese Bedingungen berühren nicht Ihre gesetzlichen Verbraucherrechte nach geltendem Recht, einschließlich, aber nicht beschränkt auf:

- EU-Verbraucherrechterichtlinie (2011/83/EU) und Digitale-Inhalte-Richtlinie ((EU) 2019/770)
- UK Consumer Rights Act 2015
- Australian Consumer Law
- Deutsche Verbraucherschutzbestimmungen des BGB (§§ 312 ff., §§ 327 ff.)
- Neuseeländischer Consumer Guarantees Act 1993
- Brasilianischer Consumer Defense Code (CDC)
- Kanadische Provinz-Verbraucherschutzgesetze
- Sonstige anwendbare Verbraucherschutzgesetzgebung in Ihrer Rechtsordnung

---

## 16. Allgemeines

### 16.1 Änderungen dieser Bedingungen

Wir können diese Bedingungen von Zeit zu Zeit aktualisieren. Wesentliche Änderungen werden mindestens dreißig (30) Tage vor ihrem Inkrafttreten über die Anwendung oder den App-Store-Eintrag kommuniziert. Ihre fortgesetzte Nutzung nach Inkrafttreten der Änderungen stellt die Annahme dar.

### 16.2 Abtretung

Sie dürfen diese Bedingungen oder daraus folgende Rechte nicht ohne vorherige schriftliche Zustimmung des Anbieters abtreten oder übertragen. Der Anbieter darf diese Bedingungen im Zusammenhang mit einer Fusion, einem Erwerb oder einem Verkauf von Vermögenswerten abtreten.

### 16.3 Salvatorische Klausel

Sollte eine Bestimmung dieser Bedingungen undurchsetzbar oder ungültig sein, wird diese Bestimmung auf das zur Aufrechterhaltung der übrigen Bedingungen erforderliche Mindestmaß beschränkt oder gestrichen. Für das deutsche Recht gilt § 306 BGB.

### 16.4 Verzicht

Die Nichtdurchsetzung einer Bestimmung dieser Bedingungen durch den Anbieter stellt keinen Verzicht auf diese Bestimmung dar.

### 16.5 Gesamte Vereinbarung

Diese Bedingungen bilden zusammen mit der Datenschutzerklärung, dem Impressum und der Apple EULA die gesamte Vereinbarung zwischen Ihnen und dem Anbieter bezüglich der Anwendung und ersetzen alle früheren Vereinbarungen und Absprachen.

### 16.6 Sprache

Die verbindliche Fassung dieser Bedingungen ist die englische Fassung. Übersetzungen werden zur Erleichterung bereitgestellt. Bei Abweichungen hat die englische Fassung Vorrang, sofern nicht zwingendes lokales Recht etwas anderes vorschreibt.

### 16.7 Elektronische Kommunikation

Sie stimmen zu, gesetzlich erforderliche Mitteilungen des Anbieters in elektronischer Form (über die Anwendung oder per E-Mail) zu erhalten.

### 16.8 Höhere Gewalt

Der Anbieter haftet nicht für Ausfälle oder Verzögerungen in der Leistung, die durch Ereignisse außerhalb seiner angemessenen Kontrolle verursacht werden, einschließlich höherer Gewalt, Krieg, Terrorismus, zivile Unruhen, Arbeitskämpfe, Internetausfälle, Ausfälle von Drittanbieterdiensten oder staatliche Maßnahmen.

---

## 17. Kontakt

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Deutschland
E-Mail: moin@berger-rosenstock.de
USt-IdNr.: DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. Alle Rechte vorbehalten.
