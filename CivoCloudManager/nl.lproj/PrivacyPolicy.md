# Privacybeleid

## Civo Cloud Manager

**Ingangsdatum:** april 2026
**Laatst bijgewerkt:** april 2026

**Verwerkingsverantwoordelijke:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Duitsland
E-mail: moin@berger-rosenstock.de

---

## 1. Inleiding

Dit Privacybeleid beschrijft hoe Marcel R. G. Berger, handelend als Berger & Rosenstock GbR ("wij", "ons", "onze"), omgaat met informatie in verband met de applicatie Civo Cloud Manager ("de Applicatie").

Wij zetten ons in voor de bescherming van uw privacy en de naleving van de toepasselijke wetgeving inzake gegevensbescherming, waaronder maar niet beperkt tot:

- Algemene Verordening Gegevensbescherming van de EU (AVG, Verordening (EU) 2016/679)
- Duitse federale wet bescherming persoonsgegevens (BDSG)
- Algemene Verordening Gegevensbescherming van het Verenigd Koninkrijk (UK GDPR) en Data Protection Act 2018
- Zwitserse federale wet op de gegevensbescherming (FADP / revDSG)
- California Consumer Privacy Act (CCPA) en California Privacy Rights Act (CPRA)
- Virginia Consumer Data Protection Act (VCDPA), Colorado Privacy Act (CPA), Connecticut Data Privacy Act (CTDPA), Utah Consumer Privacy Act (UCPA) en overige Amerikaanse deelstaatwetgeving
- Canadese Personal Information Protection and Electronic Documents Act (PIPEDA) en provinciale wetgeving
- Australische Privacy Act 1988 en Australian Privacy Principles (APPs)
- Braziliaanse algemene wet bescherming persoonsgegevens (LGPD, wet nr. 13.709/2018)
- Japanse Act on the Protection of Personal Information (APPI)
- Zuid-Koreaanse Personal Information Protection Act (PIPA)
- Singaporese Personal Data Protection Act (PDPA)
- Thaise Personal Data Protection Act (PDPA 2019)
- Chinese Personal Information Protection Law (PIPL)
- Indiase Digital Personal Data Protection Act 2023 (DPDP Act)
- Zuid-Afrikaanse Protection of Personal Information Act (POPIA)
- Personal Data Protection Law (PDPL) van de Verenigde Arabische Emiraten
- Nieuw-Zeelandse Privacy Act 2020
- Children's Online Privacy Protection Act (COPPA, VS)

---

## 2. Beginsel van geen gegevensverzameling

**Wij verzamelen, bewaren, verzenden of verwerken geen persoonsgegevens op onze servers.**

De Applicatie werkt volledig op uw apparaat. Alle configuratie, inloggegevens en voorkeuren worden lokaal opgeslagen. Wij beschikken niet over servers die uw gegevens ontvangen. Wij exploiteren geen back-endinfrastructuur voor gegevensverzameling, analyse, crashrapportage of telemetrie.

Omdat wij geen persoonsgegevens onder onze controle verwerken, zijn de meeste verplichtingen uit de wetgeving inzake gegevensbescherming (verplichtingen voor de verwerkingsverantwoordelijke, verplichtingen bij internationale doorgifte, meldingsplicht bij datalekken enz.) niet op ons van toepassing als uitgever van deze Applicatie. In paragraaf 10 worden niettemin de rechten beschreven die u op grond van de toepasselijke wetgeving toekomen.

---

## 3. Gegevens die op uw apparaat worden opgeslagen

De Applicatie slaat de volgende gegevens lokaal op uw macOS-apparaat op. Geen van deze gegevens wordt naar onze servers verzonden.

### 3.1 Inloggegevens

- **Civo API-sleutel** — opgeslagen in de macOS-sleutelhanger (hardware-gebaseerde versleuteling) — gebruikt om te authenticeren bij de Civo Cloud API
- **Kubeconfig-inloggegevens** — alleen in het geheugen opgeslagen tijdens actieve sessies, nooit op schijf bewaard
- **Object Store-inloggegevens (Access Key ID / Secret)** — op aanvraag opgehaald uit de Civo API, alleen in het geheugen opgeslagen

### 3.2 Voorkeuren

- **Geselecteerde regio** (UserDefaults) — actieve Civo-regiocode
- **Beheerde firewalls** (UserDefaults, JSON) — door de Applicatie bijgehouden firewallconfiguraties
- **Starten bij inloggen** (UserDefaults) — voorkeur voor automatisch starten
- **Onboardingstatus** (UserDefaults) — markering voor voltooiing van de installatie
- **IP-voorinstellingen** (UserDefaults, JSON) — door de gebruiker benoemde IP-adressen voor firewallregels

### 3.3 Tijdelijke runtimegegevens

- **Gedetecteerd openbaar IP** — tijdens een sessie in het geheugen bewaard, nooit permanent opgeslagen
- **API-antwoorden** — in het geheugen bewaard terwijl ze worden weergegeven, nooit buiten de sessie bewaard

### 3.4 Aankoopstatus

Volledig beheerd door Apple StoreKit. Wij ontvangen, bewaren of verwerken geen betalingsgegevens.

---

## 4. Rechtsgrondslag voor verwerking (AVG)

Aangezien wij voor persoonsgegevens die via de Applicatie worden verzameld niet optreden als verwerkingsverantwoordelijke of verwerker, zijn de grondslagen van artikel 6 AVG op ons niet van toepassing. Voor zover de werking van de Applicatie lokale verwerking op uw apparaat met zich meebrengt, vindt deze plaats op basis van:

- **Uitvoering van de overeenkomst** (art. 6 lid 1 onder b AVG) — het leveren van de functionaliteit waarvoor u de Applicatie heeft geïnstalleerd
- **Toestemming** (art. 6 lid 1 onder a AVG) — waar u uitdrukkelijk acties activeert zoals IP-detectie, het aanmaken van firewallregels of Touch ID-authenticatie

Er vindt geen verwerking plaats op grond van artikel 6 lid 1 onder a, c, d, e of f AVG op infrastructuur die door ons wordt beheerd.

---

## 5. Hoe gegevens worden gebruikt

Gegevens op uw apparaat worden uitsluitend gebruikt om:

- Te authenticeren bij de Civo Cloud API, Kubernetes API-servers en S3-compatibele objectopslageindpunten waar u de Applicatie naar verwijst
- Uw Civo Cloud-resources te beheren (instanties, clusters, databases, firewalls enz.)
- Uw openbare IPv4-adres te detecteren om firewallregels te openen en sluiten
- Resourcestatus, kostenramingen en activiteitenlogboeken lokaal weer te geven
- Uw eenmalige in-app aankoop te verwerken via Apple StoreKit

Gegevens worden door ons nooit gedeeld, verkocht, verhuurd of anderszins aan derden verstrekt.

---

## 6. Diensten van derden

De Applicatie communiceert rechtstreeks met de volgende diensten van derden op uw uitdrukkelijke aanwijzing. Wij zijn geen partij bij deze communicatie.

### 6.1 Civo Cloud API (api.civo.com)

- **Doel:** Beheer van uw Civo Cloud-infrastructuur
- **Verzonden gegevens:** Uw Civo API-sleutel (als authenticatieheader), verzoeken tot resourcebeheer
- **Exploitant:** Civo Ltd, Verenigd Koninkrijk
- **Privacybeleid:** https://www.civo.com/privacy

### 6.2 Kubernetes API-servers

- **Doel:** Toegang tot clusterknooppunten, pods, logs, deployments en metrics
- **Verzonden gegevens:** Clientcertificaatgegevens uit uw kubeconfig (PKCS#12 mTLS)
- **Exploitant:** De beheerder van het Kubernetes-cluster (uw Civo-cluster; u beheert het eindpunt)

### 6.3 Civo Object Storage (S3-compatibel)

- **Doel:** Bladeren in, uploaden en downloaden van bestanden in uw objectopslag
- **Verzonden gegevens:** S3-compatibele verzoeken ondertekend met uw objectopslag-inloggegevens (AWS Signature V4)
- **Exploitant:** Civo Ltd

### 6.4 IP-detectiediensten

- **Doel:** Uw openbare IPv4-adres detecteren voor beheer van firewallregels
- **Gebruikte diensten:** ipify.org, ifconfig.me, icanhazip.com (fallbackketen)
- **Verzonden gegevens:** Standaard HTTPS-verzoek (uw IP-adres is inherent zichtbaar voor deze diensten)
- **Ontvangen gegevens:** Uw openbare IPv4-adres

### 6.5 Apple App Store / StoreKit

- **Doel:** Verwerken van in-app aankopen, verifiëren van rechten, activeren van Delen met gezin
- **Verzonden gegevens:** Volledig beheerd door Apple's StoreKit-framework
- **Exploitant:** Apple Inc.
- **Privacybeleid:** https://www.apple.com/legal/privacy/

### 6.6 Niet-gebruikte SDK's

Wij integreren **geen** van de volgende:

- Analytics-SDK's (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog enz.)
- SDK's voor crashrapportage (Crashlytics, Sentry, Bugsnag enz.)
- Advertentie-SDK's (AdMob, Meta Audience Network, AppLovin enz.)
- Attributie-SDK's (AppsFlyer, Adjust, Branch, Kochava enz.)
- Frameworks voor A/B-testen
- SDK's voor sociale media
- Externe authenticatieproviders

---

## 7. Internationale doorgiften van gegevens

Wij geven geen persoonsgegevens internationaal door omdat wij geen persoonsgegevens verzamelen of verwerken.

Door u geïnitieerde gegevensstromen (API-oproepen naar Civo, Kubernetes, S3, IP-detectie) kunnen grensoverschrijdende transmissie inhouden. Deze doorgiften worden beheerst door de privacyverklaringen en doorgiftemechanismen van de respectieve exploitanten. Voor gebruikers in de EER/VK baseert Civo Ltd zich op adequaatheidsbesluiten van het VK en de EU en, waar van toepassing, Standard Contractual Clauses (SCC's).

---

## 8. Bewaartermijn

Wij bewaren geen gegevens. Alle gegevens van de Applicatie worden lokaal op uw apparaat opgeslagen en vallen uitsluitend onder uw controle.

- **Het verwijderen van de Applicatie** verwijdert de voorkeuren die in UserDefaults zijn opgeslagen (doorgaans `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Sleutelhangeritems** kunnen na het verwijderen blijven bestaan; deze kunnen handmatig worden verwijderd via Sleutelhangertoegang
- **Cache van kosten over de afgelopen maand** wordt lokaal opgeslagen en bij het verwijderen samen met de container verwijderd

---

## 9. Gegevensbeveiliging

Hoewel wij uw gegevens niet verzamelen, implementeren wij binnen de Applicatie de volgende beveiligingsmaatregelen:

- **Opslag van API-sleutel:** macOS-sleutelhanger met hardware-gebaseerde versleuteling (Secure Enclave waar beschikbaar)
- **Geheimen van objectopslag:** beschermd met Touch ID / systeemwachtwoord via het LocalAuthentication-framework
- **Kubeconfig-inloggegevens:** alleen in het geheugen opgeslagen tijdens actieve sessies, nooit op schijf bewaard
- **Netwerkcommunicatie:** HTTPS/TLS 1.2+ voor alle API-communicatie
- **Certificaatauthenticatie:** Kubernetes API gebruikt PKCS#12-clientcertificaat-mTLS
- **App Sandbox:** De Applicatie draait binnen de macOS App Sandbox met de minimaal vereiste entitlements
- **Hardened Runtime:** Aanvullende beveiligingsversterking tijdens runtime
- **Geen telemetrie:** Geen gebruiksgegevens, analyses of crashrapporten worden ergens naartoe verzonden
- **Geen permanente logregistratie:** Logs gebruiken `os.Logger` met `privacy: .private` en worden niet geëxporteerd

Geen enkel systeem is volledig veilig. Wij raden u aan een aparte API-sleutel te gebruiken met de minimaal vereiste Civo-rechten voor uw workflow.

---

## 10. Uw rechten

### 10.1 Rechten op grond van de AVG (EU / EER / VK)

U heeft het recht op:

- **Inzage** in uw persoonsgegevens (art. 15 AVG) — niet van toepassing, wij bewaren geen gegevens over u
- **Rectificatie** van onjuiste gegevens (art. 16 AVG) — niet van toepassing
- **Wissing** / het recht om vergeten te worden (art. 17 AVG) — niet van toepassing; u kunt lokale gegevens verwijderen door de Applicatie te de-installeren
- **Beperking** van verwerking (art. 18 AVG) — niet van toepassing
- **Overdraagbaarheid** van gegevens (art. 20 AVG) — niet van toepassing
- **Bezwaar** tegen verwerking (art. 21 AVG) — niet van toepassing
- **Intrekking van toestemming** op elk moment (art. 7 lid 3 AVG) — u kunt op elk moment stoppen met het gebruik van de Applicatie
- **Het indienen van een klacht** bij een toezichthoudende autoriteit

Aan deze rechten wordt voldaan door ons beleid van nulverzameling. Mocht dit in een toekomstige versie veranderen, dan zullen wij u hiervan op de hoogte stellen en het volledige rechtenkader implementeren.

### 10.2 Rechten op grond van CCPA / CPRA (Californië, VS)

Inwoners van Californië hebben het recht om:

- Te weten welke persoonsgegevens worden verzameld, gebruikt, gedeeld of verkocht
- Persoonsgegevens te laten verwijderen
- Zich af te melden voor de verkoop of het delen van persoonsgegevens
- Niet te worden gediscrimineerd bij de uitoefening van privacyrechten
- Onjuiste persoonsgegevens te laten corrigeren
- Het gebruik van gevoelige persoonsgegevens te beperken

Wij verkopen geen persoonsgegevens. Wij delen geen persoonsgegevens voor op gedrag gebaseerde advertenties in meerdere contexten. Wij verzamelen geen persoonsgegevens zoals gedefinieerd onder CCPA/CPRA.

### 10.3 Rechten op grond van andere Amerikaanse deelstaatwetten (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR enz.)

Inwoners van Virginia, Colorado, Connecticut, Utah, Texas, Oregon, Iowa, Montana, Florida, Tennessee, Indiana, Delaware, New Jersey en andere Amerikaanse deelstaten met privacywetgeving hebben het recht op inzage, verwijdering, correctie en afmelding voor gerichte advertenties / verkoop / profilering. Aan deze rechten wordt voldaan door ons beleid van nulverzameling.

### 10.4 Rechten op grond van PIPEDA en provinciale wetten (Canada)

Canadese inwoners hebben het recht op inzage, het betwisten van de juistheid, het intrekken van toestemming en het indienen van een klacht bij het Office of the Privacy Commissioner of Canada (of provinciale autoriteiten in Quebec, Brits-Columbia, Alberta).

### 10.5 Rechten op grond van de Australian Privacy Act

Australische inwoners hebben het recht op inzage en correctie van hun persoonsgegevens en kunnen een klacht indienen bij het Office of the Australian Information Commissioner (OAIC).

### 10.6 Rechten op grond van LGPD (Brazilië)

Braziliaanse inwoners hebben het recht op bevestiging van verwerking, inzage, correctie, anonimisering, overdraagbaarheid, informatie over delen en intrekking van toestemming. Klachten kunnen worden gericht aan de Autoridade Nacional de Proteção de Dados (ANPD).

### 10.7 Rechten op grond van APPI (Japan)

Japanse inwoners hebben het recht op openbaarmaking, correctie, verwijdering en stopzetting van gebruik. Klachten kunnen worden gericht aan de Personal Information Protection Commission (PPC).

### 10.8 Rechten op grond van PIPA (Zuid-Korea)

Zuid-Koreaanse inwoners hebben het recht op inzage, correctie, verwijdering, opschorting van verwerking en schadevergoeding. Klachten kunnen worden gericht aan de Personal Information Protection Commission (PIPC).

### 10.9 Rechten op grond van PDPA (Singapore / Thailand)

Inwoners hebben het recht op inzage, correctie en intrekking van toestemming. Klachten kunnen worden gericht aan de Personal Data Protection Commission (PDPC) van het betreffende land.

### 10.10 Rechten op grond van PIPL (China)

Chinese inwoners hebben het recht om te weten, te beslissen, te beperken, te weigeren, in te zien, te kopiëren, over te dragen, te corrigeren, te verwijderen en om uitleg te eisen over verwerkingsregels.

### 10.11 Rechten op grond van DPDP Act (India)

Indiase inwoners hebben het recht op informatie, correctie, wissing, klachtenafhandeling en nominatie.

### 10.12 Rechten op grond van POPIA (Zuid-Afrika)

Zuid-Afrikaanse inwoners hebben het recht op inzage, correctie, verwijdering en het indienen van een klacht bij de Information Regulator.

### 10.13 Rechten op grond van de Zwitserse FADP

Zwitserse inwoners hebben het recht op informatie, inzage, rectificatie, verwijdering, bezwaar en gegevensoverdraagbaarheid. Klachten kunnen worden gericht aan de Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB).

### 10.14 Rechten op grond van de NZ Privacy Act

Inwoners van Nieuw-Zeeland hebben het recht op inzage en correctie van persoonsgegevens en kunnen een klacht indienen bij de Privacy Commissioner.

### 10.15 Hoe u uw rechten kunt uitoefenen

Omdat wij geen gegevens over u bewaren, wordt aan deze rechten standaard voldaan. Indien u van mening bent dat wij ondanks dit beleid toch persoonsgegevens over u bewaren, neemt u contact op via moin@berger-rosenstock.de.

---

## 11. Privacy van kinderen

De Applicatie heeft in de Apple App Store een leeftijdsclassificatie van **4+** en is daardoor technisch toegankelijk voor gebruikers van alle leeftijden. De Applicatie is echter een hulpmiddel voor technisch infrastructuurbeheer, bedoeld voor beheerders van Civo Cloud-accounts. Voor een Civo Cloud-account moet de houder de wettelijke contractleeftijd in zijn of haar rechtsgebied hebben bereikt.

**Wij verzamelen niet bewust persoonsgegevens van wie dan ook, inclusief kinderen onder 13 jaar (COPPA, VS), 16 jaar (AVG-K, EU) of de toepasselijke leeftijd van toestemming in uw rechtsgebied.**

Omdat de Applicatie een strikt beleid van nulverzameling hanteert (zie paragraaf 2), worden er geen persoonsgegevens over welke gebruiker dan ook — ongeacht leeftijd — verzameld, verzonden, op onze servers opgeslagen of met derden gedeeld. Dit voldoet aan:

- **COPPA** (Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506, VS)
- **Art. 8 AVG** (EU)
- **PIPEDA** en toepasselijke provinciale wetten (Canada)
- **Art. 14 LGPD** (Brazilië)
- **APPI** (Japan)
- **Australian Privacy Act** en AAP 8 inzake kinderprivacy

Indien u ouder of voogd bent en vermoedt dat uw kind persoonsgegevens heeft verstrekt, neemt u contact op via moin@berger-rosenstock.de. Wij zullen dit onmiddellijk onderzoeken en dergelijke informatie, indien aangetroffen, verwijderen.

---

## 12. Cookies en tracking

De Applicatie is een native macOS-applicatie en maakt geen gebruik van cookies, webbakens, pixeltags, fingerprinting of vergelijkbare volgtechnieken.

De Applicatie bevat geen ingesloten webweergaven die inhoud van derden laden.

---

## 13. Geautomatiseerde besluitvorming

Wij maken geen gebruik van geautomatiseerde besluitvorming of profilering die rechtsgevolgen heeft of u op vergelijkbare wijze in aanmerkelijke mate treft. De Applicatie neemt geen geautomatiseerde beslissingen op basis van persoonsgegevens.

---

## 14. Links en diensten van derden

De Applicatie kan links bevatten naar websites van derden (bijvoorbeeld de Civo-website, Apple App Store, Online Geschillenbeslechtingsplatform). Wij zijn niet verantwoordelijk voor de privacypraktijken of inhoud van diensten van derden. Raadpleeg hun privacybeleid voordat u gegevens verstrekt.

---

## 15. Wijzigingen in dit beleid

Wij kunnen dit Privacybeleid van tijd tot tijd bijwerken.

- Belangrijke wijzigingen worden ten minste 30 dagen vóór inwerkingtreding gecommuniceerd via de Applicatie of de vermelding in de App Store
- De "Ingangsdatum" bovenaan weerspiegelt de meest recente herziening
- Wij zullen onze privacypraktijken niet met terugwerkende kracht wijzigen om gegevens te verzamelen zonder uw uitdrukkelijke toestemming

---

## 16. Contact

Voor privacygerelateerde vragen of het uitoefenen van uw rechten:

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Duitsland
E-mail: moin@berger-rosenstock.de

Inwoners van de EU kunnen ook contact opnemen met de bevoegde toezichthoudende autoriteit in hun lidstaat. Een lijst van toezichthoudende autoriteiten in de EU is beschikbaar op: https://edpb.europa.eu/about-edpb/board/members_en

Voor inwoners van het Verenigd Koninkrijk is de toezichthoudende autoriteit het Information Commissioner's Office (ICO): https://ico.org.uk

---

## 17. Regionale bepalingen

### 17.1 Europese Unie / Europese Economische Ruimte

- De werking voldoet aan de AVG voor zover van toepassing op lokale verwerking op uw apparaat
- De toezichthoudende autoriteit van de verwerkingsverantwoordelijke is de bevoegde Duitse deelstaatautoriteit voor gegevensbescherming
- Gegevensbeschermingseffectbeoordelingen (DPIA's) zijn niet vereist (geen verzameling)

### 17.2 Duitsland

- Naleving van de AVG en het Bundesdatenschutzgesetz (BDSG)
- Bevoegde toezichthoudende autoriteit: de Landesbeauftragte für Datenschutz van de betreffende deelstaat (de verwerkingsverantwoordelijke is gevestigd in Duitsland)

### 17.3 Oostenrijk

- Naleving van de AVG en het Datenschutzgesetz (DSG)
- Toezichthoudende autoriteit: Datenschutzbehörde (DSB)

### 17.4 Zwitserland

- Naleving van de herziene federale wet op de gegevensbescherming (revDSG), in werking sinds 1 september 2023
- Toezichthoudende autoriteit: Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB)

### 17.5 Verenigd Koninkrijk

- Naleving van de UK GDPR en Data Protection Act 2018
- Toezichthoudende autoriteit: Information Commissioner's Office (ICO)

### 17.6 Frankrijk

- Naleving van de AVG en Loi Informatique et Libertés
- Toezichthoudende autoriteit: Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Italië

- Naleving van de AVG en Codice in materia di protezione dei dati personali
- Toezichthoudende autoriteit: Garante per la Protezione dei Dati Personali

### 17.8 Spanje

- Naleving van de AVG en Ley Orgánica 3/2018 (LOPDGDD)
- Toezichthoudende autoriteit: Agencia Española de Protección de Datos (AEPD)

### 17.9 Nederland

- Naleving van de AVG en de Uitvoeringswet AVG (UAVG)
- Toezichthoudende autoriteit: Autoriteit Persoonsgegevens (AP)

### 17.10 Polen

- Naleving van de AVG en Ustawa o ochronie danych osobowych
- Toezichthoudende autoriteit: Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portugal

- Naleving van de AVG en Lei n.º 58/2019
- Toezichthoudende autoriteit: Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 België

- Naleving van de AVG en de wet van 30 juli 2018
- Toezichthoudende autoriteit: Gegevensbeschermingsautoriteit (APD-GBA)

### 17.13 Ierland

- Naleving van de AVG en Data Protection Act 2018
- Toezichthoudende autoriteit: Data Protection Commission (DPC)

### 17.14 Noordse landen (Denemarken, Finland, Noorwegen, Zweden, IJsland)

- Naleving van de AVG (en de EER-equivalenten voor Noorwegen en IJsland)
- Nationale toezichthoudende autoriteiten: Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Overige lidstaten van EU/EER

Naleving van de AVG en de respectieve nationale uitvoering. Overzicht van toezichthoudende autoriteiten: https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 Verenigde Staten

- Naleving van de toepasselijke deelstaatprivacywetten: CCPA/CPRA (Californië), VCDPA (Virginia), CPA (Colorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Texas), OCPA (Oregon), IDPA (Iowa), MCDPA (Montana), FDBR (Florida), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (New Jersey)
- "Do Not Track"- en "Global Privacy Control"-signalen worden gerespecteerd waar technisch haalbaar (de Applicatie volgt niet)
- COPPA-naleving voor gebruikers onder 13 jaar

### 17.17 Canada

- Naleving van PIPEDA en toepasselijke provinciale wetten: Quebec Act 25, British Columbia PIPA, Alberta PIPA
- Klachten: Office of the Privacy Commissioner of Canada (OPC) en provinciale autoriteiten

### 17.18 Mexico

- Naleving van Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Toezichthoudende autoriteit: Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brazilië

- Naleving van de LGPD
- Toezichthoudende autoriteit: Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentinië, Chili, Colombia, Peru, Uruguay

- Naleving van nationale gegevensbeschermingswetgeving (Wet 25.326 / Wet 19.628 / Wet 1581 / Wet 29733 / Wet 18.331)

### 17.21 Australië

- Naleving van de Privacy Act 1988 en Australian Privacy Principles (APPs)
- Toezichthoudende autoriteit: Office of the Australian Information Commissioner (OAIC)

### 17.22 Nieuw-Zeeland

- Naleving van de Privacy Act 2020
- Toezichthoudende autoriteit: Office of the Privacy Commissioner

### 17.23 Japan

- Naleving van de Act on the Protection of Personal Information (APPI)
- Toezichthoudende autoriteit: Personal Information Protection Commission (PPC)

### 17.24 Zuid-Korea

- Naleving van de Personal Information Protection Act (PIPA)
- Toezichthoudende autoriteit: Personal Information Protection Commission (PIPC)

### 17.25 Singapore

- Naleving van de Personal Data Protection Act (PDPA)
- Toezichthoudende autoriteit: Personal Data Protection Commission (PDPC)

### 17.26 Thailand

- Naleving van de Personal Data Protection Act B.E. 2562 (2019)
- Toezichthoudende autoriteit: Personal Data Protection Committee

### 17.27 China

- Naleving van de Personal Information Protection Law (PIPL), Cybersecurity Law (CSL) en Data Security Law (DSL)

### 17.28 Hongkong

- Naleving van de Personal Data (Privacy) Ordinance (PDPO)
- Toezichthoudende autoriteit: Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 India

- Naleving van de Digital Personal Data Protection Act 2023 (DPDP Act) en de Information Technology Act 2000
- Toezichthoudende autoriteit: Data Protection Board of India

### 17.30 Verenigde Arabische Emiraten

- Naleving van Federal Decree-Law No. 45 of 2021 (Personal Data Protection Law)

### 17.31 Saoedi-Arabië

- Naleving van de Personal Data Protection Law (PDPL)

### 17.32 Turkije

- Naleving van de Personal Data Protection Law No. 6698 (KVKK)
- Toezichthoudende autoriteit: Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Israël

- Naleving van de Privacy Protection Law, 5741-1981 en de Privacy Protection Regulations
- Toezichthoudende autoriteit: Privacy Protection Authority (PPA)

### 17.34 Zuid-Afrika

- Naleving van de Protection of Personal Information Act (POPIA)
- Toezichthoudende autoriteit: Information Regulator

### 17.35 Kenia, Nigeria, Egypte, Marokko

- Naleving van nationale gegevensbeschermingswetgeving (Data Protection Act 2019 Kenia, NDPR / NDPA Nigeria, Wet nr. 151 van 2020 Egypte, Wet 09-08 Marokko)

### 17.36 Overige rechtsgebieden

Voor gebruikers in rechtsgebieden die hierboven niet specifiek zijn vermeld, zorgt de aanpak van nulverzameling van de Applicatie voor naleving van de beginselen van gegevensminimalisatie en doelbinding die gangbaar zijn in moderne privacykaders. Mocht uw lokale wetgeving aanvullende rechten bieden, dan worden die rechten gerespecteerd.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. Alle rechten voorbehouden.
