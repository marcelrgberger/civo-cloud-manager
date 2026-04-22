# Gebruiksvoorwaarden

## Civo Cloud Manager

**Ingangsdatum:** april 2026
**Laatst bijgewerkt:** april 2026

**Aanbieder:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Duitsland
E-mail: moin@berger-rosenstock.de
Btw-nummer: DE455096022

---

## 1. Toepassingsgebied en aanvaarding

### 1.1 Overeenkomst

Deze Gebruiksvoorwaarden ("Voorwaarden") regelen uw toegang tot en gebruik van de applicatie Civo Cloud Manager ("de Applicatie"), geleverd door Berger & Rosenstock GbR ("de Aanbieder", "wij", "ons", "onze").

### 1.2 Aanvaarding

Door de Applicatie te installeren, te openen of te gebruiken gaat u ermee akkoord gebonden te zijn aan deze Voorwaarden. Indien u hiermee niet instemt, mag u de Applicatie niet installeren of gebruiken.

### 1.3 Geschiktheid

De Applicatie heeft in de Apple App Store een leeftijdsclassificatie van **4+**. Om een bindende overeenkomst aan te gaan, moet u de wettelijke contractleeftijd in uw rechtsgebied hebben bereikt. Een Civo Cloud-account, dat vereist is voor zinvol gebruik van de Applicatie, vereist dat de accounthouder de wettelijke contractleeftijd heeft bereikt.

### 1.4 Zakelijk gebruik

Indien u de Applicatie namens een organisatie gebruikt, verklaart u dat u bevoegd bent om die organisatie aan deze Voorwaarden te binden.

### 1.5 Apple Licensed Application End User License Agreement

Deze Voorwaarden zijn aanvullend op de Apple Licensed Application End User License Agreement (Apple EULA) tussen u en Apple Inc. In geval van strijdigheid tussen deze Voorwaarden en de Apple EULA, prevaleert de Apple EULA voor de onderwerpen die daarin worden behandeld.

---

## 2. Diensten

### 2.1 Beschrijving

De Applicatie is een native macOS-applicatie waarmee Civo Cloud-infrastructuur kan worden beheerd (virtuele instanties, Kubernetes-clusters, databases, firewalls, netwerken, loadbalancers, volumes, objectopslag, DNS, SSH-sleutels) en die directe toegang tot de Kubernetes API biedt via de eigen API-inloggegevens van de gebruiker.

De Applicatie maakt rechtstreeks vanaf uw apparaat verbinding met:

- De Civo Cloud REST API (`api.civo.com`)
- Kubernetes API-servers van uw Civo-clusters (via mTLS)
- S3-compatibele objectopslag-eindpunten van uw Civo-account
- Diensten voor het detecteren van openbare IP-adressen (ipify.org, ifconfig.me, icanhazip.com)
- Apple App Store / StoreKit voor de verwerking van aankopen

De Aanbieder exploiteert geen back-enddienst, tussenserver of proxy. Alle communicatie vindt rechtstreeks plaats tussen uw apparaat en de respectieve exploitanten van derden.

### 2.2 Gratis en betaalde functies

De functie voor firewallbeheer in de menubalk is gratis. "Full Access" — waarmee het beheerdashboard voor alle ondersteunde resourcetypen wordt ontgrendeld — is een eenmalige in-app aankoop die uitsluitend via de Apple App Store wordt verwerkt (zie paragraaf 7).

### 2.3 Wijzigingen

De Aanbieder kan de functionaliteit van de Applicatie op elk moment wijzigen, opschorten of stopzetten. Belangrijke wijzigingen die van invloed zijn op aangekochte functies, worden indien redelijkerwijs mogelijk ten minste dertig (30) dagen van tevoren gecommuniceerd.

### 2.4 Beschikbaarheid

De Applicatie wordt geleverd op "as available"-basis. De Aanbieder garandeert geen ononderbroken toegang of beschikbaarheid; de functionaliteit van de Applicatie is afhankelijk van de beschikbaarheid van diensten van derden (Civo Cloud, Apple App Store, aanbieders van IP-detectie) die buiten de controle van de Aanbieder liggen.

---

## 3. Accounts

De Applicatie vereist geen account bij de Aanbieder. Alle authenticatie verloopt via:

- Uw Civo API-sleutel (lokaal opgeslagen in de macOS-sleutelhanger)
- Uw Kubernetes kubeconfig (opgehaald uit de Civo API)
- Uw Apple ID (voor verificatie van in-app aankopen, afgehandeld door Apple)

U bent verantwoordelijk voor:

- Het vertrouwelijk houden van uw Civo API-sleutel en andere inloggegevens
- Alle activiteiten die met uw inloggegevens worden uitgevoerd
- Alle resourcewijzigingen, kosten en facturatiegevolgen die voortvloeien uit uw gebruik van de Applicatie
- Het configureren van de rechten van de Civo API-sleutel volgens het beginsel van de minste rechten

De Aanbieder heeft geen mogelijkheid om uw Civo-inloggegevens in te zien, te herstellen of opnieuw in te stellen. Verlies van inloggegevens is uitsluitend uw verantwoordelijkheid.

---

## 4. Gebruikersinhoud

De Applicatie host, bewaart of verzendt geen door gebruikers gegenereerde inhoud naar enige server die door de Aanbieder wordt beheerd. Alle inhoud, gegevens of configuratie die u met de Applicatie aanmaakt (bijvoorbeeld namen van instanties, SSH-sleutels, labels voor firewallregels, bestanden in objectopslag) wordt opgeslagen:

- Lokaal op uw apparaat, of
- In uw eigen Civo Cloud-account

U behoudt alle rechten, aanspraken en belangen in en op dergelijke inhoud. De Aanbieder maakt geen aanspraak op enige licentie, eigendom of ander recht op uw inhoud.

---

## 5. Aanvaardbaar gebruik

U mag de Applicatie niet gebruiken om:

- Enige toepasselijke wet, regelgeving of recht van een derde te schenden
- Civo-resources te benaderen of te bedienen waartoe u geen toegang heeft
- De Civo Cloud-dienst, Kubernetes-clusters die niet van u zijn, of de Applicatie zelf te verstoren of te ontregelen
- Te proberen de Applicatie te reverse-engineeren, decompileren, disassembleren of daarvan broncode af te leiden, behalve voor zover een dergelijk verbod door de toepasselijke wetgeving is uitgesloten
- Beveiligings- of toegangscontrolemechanismen te omzeilen (inclusief de paywall voor in-app aankopen)
- De Applicatie te distribueren, in sublicentie te geven, te leasen, te verhuren, te verkopen of anderszins commercieel te exploiteren
- Eigendomsvermeldingen, copyrightaanduidingen of handelsmerken te verwijderen, te wijzigen of onduidelijk te maken
- De Applicatie te gebruiken om systemen aan te vallen, te compromitteren of op beveiliging te testen die niet van u zijn of waarvoor u geen uitdrukkelijke schriftelijke toestemming tot testen heeft
- De Applicatie te gebruiken voor enig doel dat verboden is op grond van de wetgeving van de Bondsrepubliek Duitsland, de Europese Unie of uw rechtsgebied van verblijf

---

## 6. Intellectuele eigendom

### 6.1 Eigendom

De Applicatie (waaronder broncode, ontwerp, tekst, afbeeldingen, pictogrammen, lokalisaties en alle bijbehorende intellectuele eigendomsrechten) is het exclusieve eigendom van de Aanbieder en wordt beschermd door Duits, Europees en internationaal auteursrecht, merkenrecht en ander intellectueel eigendomsrecht.

### 6.2 Verlening van licentie

Onder voorbehoud van uw naleving van deze Voorwaarden en de Apple EULA verleent de Aanbieder u een beperkte, niet-exclusieve, niet-overdraagbare, niet-sublicentieerbare, herroepbare licentie om de Applicatie te installeren en te gebruiken op Apple-apparaten die u bezit of beheert, uitsluitend voor uw persoonlijk gebruik of intern bedrijfsgebruik voor het beheren van uw Civo Cloud-infrastructuur.

### 6.3 Handelsmerken van derden

"Civo" is een handelsmerk van Civo Ltd. "Apple", "App Store", "macOS", "iCloud", "StoreKit", "TestFlight" zijn handelsmerken van Apple Inc. "Kubernetes" is een handelsmerk van The Linux Foundation. Alle overige handelsmerken zijn eigendom van hun respectieve eigenaren. De Aanbieder is niet verbonden aan, onderschreven door of gesponsord door een van deze partijen.

### 6.4 Feedback

Feedback, suggesties of ideeën die u bij de Aanbieder over de Applicatie indient, mogen zonder beperking en zonder vergoeding aan u door de Aanbieder worden gebruikt.

---

## 7. Betalingen en abonnementen

### 7.1 In-app aankoop

"Full Access" wordt verkocht als een niet-verbruikbare in-app aankoop via de Apple App Store tegen een eenmalige vergoeding. De prijs wordt voorafgaand aan de aankoop in uw lokale valuta in de Applicatie weergegeven.

### 7.2 Betaalverwerking

Betaling wordt uitsluitend verwerkt door Apple Inc. De Aanbieder ontvangt, bewaart of verwerkt geen betalingsgegevens. Alle zaken met betrekking tot betaling, terugbetaling en facturering worden beheerst door de Apple Media Services Terms en de Apple EULA.

### 7.3 Delen met gezin

"Full Access" is geschikt voor Apple Delen met gezin. Leden van uw Apple-gezinsdelingsgroep kunnen de aankoop op hun eigen apparaten gebruiken, onder voorbehoud van de regels van Apple voor Delen met gezin.

### 7.4 Apple-aanbiedingscodes

De Aanbieder kan Apple-aanbiedingscodes uitgeven voor promotionele doeleinden. Aanbiedingscodes kunnen worden verzilverd via de functie "Code inwisselen" in de Applicatie of in de App Store.

### 7.5 Terugbetalingen

Terugbetalingen worden uitsluitend door Apple afgehandeld overeenkomstig het terugbetalingsbeleid van Apple. Wettelijke consumentenrechten uit hoofde van de toepasselijke wetgeving (zie paragraaf 15) blijven onverlet. In het bijzonder worden EU-consumenten erop gewezen dat het wettelijke herroepingsrecht van 14 dagen voor digitale inhoud vervalt wanneer de uitvoering is begonnen met uw voorafgaande uitdrukkelijke toestemming — Apple implementeert dit via het bevestigingsvenster op het moment van aankoop.

### 7.6 Belastingen

De weergegeven prijs is inclusief alle toepasselijke belastingen (btw, sales tax), zoals bepaald door Apple op basis van uw land.

---

## 8. Diensten van derden

Gebruik van de Applicatie vereist interactie met diensten van derden. Uw gebruik van die diensten wordt beheerst door hun respectieve voorwaarden:

- **Civo Cloud:** https://www.civo.com/terms
- **Apple App Store / Apple ID:** https://www.apple.com/legal/internet-services/terms/
- **Kubernetes-clusters:** de voorwaarden van uw clusterexploitant (Civo)

De Aanbieder is geen partij bij enige overeenkomst tussen u en een externe dienstverlener en is niet verantwoordelijk voor de beschikbaarheid, nauwkeurigheid of het gedrag van die diensten.

---

## 9. Afwijzing van garanties

DE APPLICATIE WORDT GELEVERD "AS IS" EN "AS AVAILABLE" ZONDER ENIGE GARANTIE, EXPLICIET OF IMPLICIET, INCLUSIEF MAAR NIET BEPERKT TOT GARANTIES VAN VERKOOPBAARHEID, GESCHIKTHEID VOOR EEN BEPAALD DOEL, NAUWKEURIGHEID, VOLLEDIGHEID OF NIET-INBREUK.

DE AANBIEDER GARANDEERT NIET DAT:

- DE APPLICATIE ONONDERBROKEN, FOUTVRIJ OF VEILIG ZAL ZIJN
- DE APPLICATIE CIVO CLOUD-RESOURCES CORRECT WEERGEEFT, AANMAAKT, WIJZIGT, VERWIJDERT OF BEHEERT
- GEGEVENS DIE DOOR DE APPLICATIE WORDEN WEERGEGEVEN NAUWKEURIG, VOLLEDIG OF ACTUEEL ZIJN
- DE APPLICATIE COMPATIBEL IS MET ALLE CIVO API-VERSIES, -FUNCTIES OF -REGIO'S

**Onomkeerbare bewerkingen.** De Applicatie kan onomkeerbare bewerkingen op uw Civo Cloud-account uitvoeren, waaronder het verwijderen van Kubernetes-clusters, databases, volumes, objectopslag, instanties, SSH-sleutels en firewallregels. Alle onomkeerbare bewerkingen vereisen expliciete bevestiging door de gebruiker (doorgaans door de naam van de resource in te typen). DE AANBIEDER AANVAARDT GEEN ENKELE VERANTWOORDELIJKHEID voor onbedoelde verwijderingen, gegevensverlies, kostenoverschrijdingen of infrastructuurschade als gevolg van uw gebruik van de Applicatie.

U wordt met klem aangeraden onafhankelijke back-ups van alle kritieke gegevens bij te houden, een aparte API-sleutel te gebruiken met de minimaal vereiste Civo-rechten en alle bevestigingsdialoogvensters zorgvuldig te controleren.

Niets in deze paragraaf sluit garanties uit of beperkt deze die op grond van de toepasselijke wetgeving niet kunnen worden uitgesloten of beperkt (zie paragraaf 15).

---

## 10. Aansprakelijkheidsbeperking

VOOR ZOVER WETTELIJK TOEGESTAAN:

### 10.1 Uitsluitingen

DE AANBIEDER IS NIET AANSPRAKELIJK VOOR ENIGE INDIRECTE, INCIDENTELE, BIJZONDERE, GEVOLG-, PUNITIEVE OF EXEMPLAIRE SCHADE, WAARONDER MAAR NIET BEPERKT TOT:

- Verlies van gegevens, inkomsten, winst of zakelijke kansen
- Kosten voor de aanschaf van vervangende diensten
- Schade aan of verwijdering van cloudinfrastructuur, resources of gegevens
- Ongeautoriseerde toegang als gevolg van gecompromitteerde API-sleutels

### 10.2 Maximumbedrag

DE TOTALE GEAGGREGEERDE AANSPRAKELIJKHEID VAN DE AANBIEDER JEGENS U VOOR ALLE VORDERINGEN DIE VOORTVLOEIEN UIT OF VERBAND HOUDEN MET DE APPLICATIE, BEDRAAGT NIET MEER DAN HET BEDRAG DAT U VOOR DE APPLICATIE DAADWERKELIJK HEEFT BETAALD IN DE TWAALF (12) MAANDEN VOORAFGAAND AAN DE GEBEURTENIS DIE AANLEIDING GAF TOT DE VORDERING.

### 10.3 Uitzonderingen

Niets in deze Voorwaarden sluit aansprakelijkheid uit of beperkt deze voor:

- Overlijden of persoonlijk letsel veroorzaakt door nalatigheid
- Bedrog of frauduleuze voorstelling van zaken
- Opzet of grove nalatigheid (naar Duits recht, §§ 276, 309 BGB)
- Schending van wezenlijke contractuele verplichtingen (Kardinalpflichten), beperkt tot voor dit type overeenkomst typische, voorzienbare schade
- Elke andere aansprakelijkheid die op grond van de toepasselijke wetgeving niet kan worden uitgesloten of beperkt

### 10.4 Productaansprakelijkheid

Aansprakelijkheid op grond van de Duitse Productaansprakelijkheidswet (Produkthaftungsgesetz) blijft onverlet.

---

## 11. Vrijwaring

U stemt ermee in de Aanbieder, zijn partners, werknemers en agenten te vrijwaren, te verdedigen en te vrijwaren tegen alle vorderingen, aansprakelijkheden, schade, verliezen, kosten, uitgaven of honoraria (waaronder redelijke advocatenhonoraria) die voortvloeien uit of verband houden met:

- Uw schending van deze Voorwaarden
- Uw schending van enige wet of recht van een derde
- Uw gebruik van de Applicatie om toegang te krijgen tot of infrastructuur te beheren waartoe u niet bent gerechtigd
- Enige inhoud of configuratie die u via de Applicatie aanmaakt, wijzigt of verwijdert

Deze vrijwaringsverplichting is niet van toepassing op consumenten in de zin van de toepasselijke consumentenbeschermingswetgeving waar dwingend recht een dergelijke vrijwaring verbiedt.

---

## 12. Beëindiging

### 12.1 Beëindiging door u

U kunt deze Voorwaarden op elk moment beëindigen door de Applicatie van uw apparaten te verwijderen.

### 12.2 Beëindiging door de Aanbieder

De Aanbieder kan uw licentie om de Applicatie te gebruiken onmiddellijk beëindigen of opschorten als u deze Voorwaarden wezenlijk schendt. Bij beëindiging:

- Vervalt uw recht om de Applicatie te gebruiken onmiddellijk
- Dient u de Applicatie van uw apparaten te verwijderen
- Blijven de paragrafen 6, 9, 10, 11, 13, 14 en 16 van kracht na beëindiging

### 12.3 Gevolgen voor aankoop

Beëindiging geeft u geen recht op terugbetaling van uw in-app aankoop, behalve voor zover vereist door de toepasselijke consumentenbeschermingswetgeving of het terugbetalingsbeleid van Apple.

---

## 13. Toepasselijk recht en geschillenbeslechting

### 13.1 Toepasselijk recht

Deze Voorwaarden worden beheerst door het recht van de Bondsrepubliek Duitsland, met uitsluiting van de regels van internationaal privaatrecht en het VN-Verdrag inzake internationale koopovereenkomsten betreffende roerende zaken (Weens Koopverdrag / CISG).

Voor consumenten binnen de Europese Unie / EER ontneemt deze rechtskeuze u niet de bescherming van het dwingend consumentenrecht van het land waar u uw gewone verblijfplaats heeft.

### 13.2 Bevoegde rechter

Voor handelaren, rechtspersonen naar publiek recht en publiekrechtelijke vermogensfondsen (Kaufleute, juristische Personen des öffentlichen Rechts, öffentlich-rechtliche Sondervermögen) is Bad Nauheim, Duitsland, de exclusief bevoegde rechtbank voor alle geschillen die voortvloeien uit deze Voorwaarden.

Voor consumenten is de wettelijke bevoegde rechtbank van toepassing. U kunt procedures aanhangig maken bij de rechter van het land waar u uw gewone verblijfplaats heeft.

### 13.3 EU-platform voor onlinegeschillenbeslechting

De Europese Commissie stelt een platform voor onlinegeschillenbeslechting ter beschikking op https://ec.europa.eu/consumers/odr.

### 13.4 Consumentenarbitrage

De Aanbieder is niet verplicht noch bereid om deel te nemen aan geschillenbeslechtingsprocedures voor een consumentenarbitragecommissie (Verbraucherschlichtungsstelle) in de zin van de Duitse wet inzake consumentengeschillenbeslechting (VSBG), tenzij wettelijk verplicht.

---

## 14. Regionale bepalingen

### 14.1 Duitsland

- Consumentenrechten op grond van BGB §§ 312 e.v., §§ 327 e.v. (digitale producten) blijven onverlet
- Wettelijke herroepingsrechten op grond van BGB § 355 gelden waar van toepassing

### 14.2 Europese Unie / EER

- Richtlijn consumentenrechten 2011/83/EU en Richtlijn digitale inhoud (EU) 2019/770 zijn van toepassing wanneer u consument bent
- Toepasselijke mededelingen op grond van artikel 12 van de Digital Services Act (Verordening (EU) 2022/2065) zijn opgenomen in het Colofon

### 14.3 Verenigd Koninkrijk

- Consumer Rights Act 2015 is van toepassing wanneer u consument bent en in het VK woont
- Digitale inhoud moet van bevredigende kwaliteit, geschikt voor het doel en zoals beschreven zijn

### 14.4 Zwitserland

- Dwingende consumentenbepalingen uit het Zwitserse Wetboek van Verbintenissen (OR) blijven onverlet
- De Federal Act against Unfair Competition (UWG) is van toepassing

### 14.5 Verenigde Staten

- Deze Voorwaarden beogen geen rechten te scheppen op grond van deelstaatconsumentenbeschermingswetten die niet uit hun aard van toepassing zijn
- Inwoners van Californië: kennisgeving consumentenrechten krachtens Civil Code § 1789.3 — contact via moin@berger-rosenstock.de

### 14.6 Canada

- De Quebec Consumer Protection Act is van toepassing op inwoners van Quebec waar dit dwingend is
- Taal van de overeenkomst: deze Voorwaarden worden verstrekt in het Engels; Franse versies zijn beschikbaar waar vereist op grond van het Handvest van de Franse taal (Quebec)

### 14.7 Australië

- Garanties op grond van het Australian Consumer Law (Competition and Consumer Act 2010, Schedule 2) zijn van toepassing wanneer u consument bent — deze garanties kunnen niet worden uitgesloten

### 14.8 Nieuw-Zeeland

- De Consumer Guarantees Act 1993 is van toepassing wanneer u consument bent voor persoonlijk, huiselijk of huishoudelijk gebruik

### 14.9 Japan

- De Consumer Contract Act (消費者契約法) is van toepassing; bepalingen van deze Voorwaarden die onder deze wet ongeldig zouden zijn, worden beperkt tot het noodzakelijke

### 14.10 Zuid-Korea

- De Act on the Regulation of Terms and Conditions (약관의 규제에 관한 법률) is van toepassing

### 14.11 Brazilië

- De Consumer Defense Code (CDC, wet nr. 8.078/1990) is van toepassing; van consumentenrechten kan geen afstand worden gedaan

### 14.12 India

- De Consumer Protection Act 2019 en de E-Commerce Rules 2020 zijn van toepassing wanneer u consument bent

### 14.13 Overige rechtsgebieden

Voor gebruikers in rechtsgebieden die hierboven niet specifiek zijn vermeld, zijn deze Voorwaarden van toepassing voor zover toegestaan door het plaatselijke dwingende consumentenrecht.

---

## 15. Consumentenrechten (verplichte informatie)

Deze Voorwaarden doen geen afbreuk aan uw wettelijke consumentenrechten op grond van de toepasselijke wetgeving, waaronder maar niet beperkt tot:

- EU-richtlijn consumentenrechten (2011/83/EU) en richtlijn digitale inhoud ((EU) 2019/770)
- VK Consumer Rights Act 2015
- Australian Consumer Law
- Consumentenbeschermingsbepalingen van het Duitse BGB (§§ 312 e.v., §§ 327 e.v.)
- Nieuw-Zeelandse Consumer Guarantees Act 1993
- Braziliaanse Consumer Defense Code (CDC)
- Canadese provinciale consumentenbeschermingswetgeving
- Andere toepasselijke consumentenbeschermingswetgeving in uw rechtsgebied

---

## 16. Algemeen

### 16.1 Wijzigingen in deze Voorwaarden

Wij kunnen deze Voorwaarden van tijd tot tijd bijwerken. Belangrijke wijzigingen worden ten minste dertig (30) dagen vóór inwerkingtreding gecommuniceerd via de Applicatie of de vermelding in de App Store. Voortgezet gebruik na inwerkingtreding van de wijzigingen geldt als aanvaarding.

### 16.2 Overdracht

U mag deze Voorwaarden of de daaruit voortvloeiende rechten niet overdragen zonder voorafgaande schriftelijke toestemming van de Aanbieder. De Aanbieder mag deze Voorwaarden overdragen in verband met een fusie, overname of verkoop van activa.

### 16.3 Scheidbaarheid

Indien enige bepaling van deze Voorwaarden niet-afdwingbaar of ongeldig wordt bevonden, wordt die bepaling beperkt of geëlimineerd tot het minimum dat nodig is, zodat deze Voorwaarden voor het overige volledig van kracht blijven. Voor Duits recht is § 306 BGB van toepassing.

### 16.4 Afstandsverklaring

Het niet afdwingen door de Aanbieder van enige bepaling van deze Voorwaarden houdt geen afstand van die bepaling in.

### 16.5 Volledige overeenkomst

Deze Voorwaarden vormen, samen met het Privacybeleid, het Colofon en de Apple EULA, de gehele overeenkomst tussen u en de Aanbieder met betrekking tot de Applicatie en vervangen alle eerdere overeenkomsten en afspraken.

### 16.6 Taal

De authentieke versie van deze Voorwaarden is de Engelse versie. Vertalingen worden voor het gemak verstrekt. In geval van verschil prevaleert de Engelse versie, tenzij het plaatselijke dwingende recht anders vereist.

### 16.7 Elektronische communicatie

U stemt ermee in wettelijk vereiste kennisgevingen van de Aanbieder in elektronische vorm te ontvangen (via de Applicatie of e-mail).

### 16.8 Overmacht

De Aanbieder is niet aansprakelijk voor enige tekortkoming of vertraging in de uitvoering die wordt veroorzaakt door gebeurtenissen buiten zijn redelijke controle, waaronder natuurrampen, oorlog, terrorisme, burgerlijke onrust, arbeidsconflicten, internetstoringen, storingen bij diensten van derden of overheidsmaatregelen.

---

## 17. Contact

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Duitsland
E-mail: moin@berger-rosenstock.de
Btw-nummer: DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. Alle rechten voorbehouden.
