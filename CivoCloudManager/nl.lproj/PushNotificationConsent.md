<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: nl | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# TOESTEMMINGSKENNISGEVING VOOR PUSHMELDINGEN

## Informatie getoond naast het systeemtoestemmingsverzoek voor pushmeldingen

**Ingangsdatum:** september 2026

**Aanbieder:**
DigitalFreedom
Een merk van DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Verenigde Staten
Contact: hello@digitalfreedom.co.za
Gegevensbescherming: data-protection@digitalfreedom.co.za
Website: https://digitalfreedom.co.za

---

## 0. DOEL

Deze kennisgeving wordt getoond **vóór** het iOS / Android systeemtoestemmingsverzoek voor pushmeldingen. Het informeert de gebruiker — in duidelijke taal — waar hij of zij toestemming voor geeft. Het voldoet aan:

- **Art. 6(1)(a) AVG** — vrij gegeven, specifiek, geïnformeerde, ondubbelzinnige toestemming voor verwerking met betrekking tot meldingen wanneer de melding persoonsgegevens bevat
- **Art. 13 AVG** — transparantie op het moment van verzameling
- **e-Privacyrichtlijn 2002/58/EG Art. 13 / nationale implementaties** — voor elke melding met marketinginhoud
- **Apple Human Interface Guidelines** en **Google Play Developer Policy** — best practices voor pre-prompt

De Diensten worden wereldwijd verspreid via de Apple App Store en de Google Play Store; deze kennisgeving is van toepassing waar pushmeldingen zijn ingeschakeld en wordt geleverd in de taal van de gebruiker waar ondersteund.

---

## 1. WAARVOOR U TOESTEMMING GEEFT

Als u bij de volgende prompt op **"Toestaan"** tikt, kan `Civo Cloud Manager`:

- meldingen naar uw apparaat sturen
- waarschuwingen, badges, banners en geluiden tonen (afhankelijk van uw instellingen op OS-niveau)
- gebruikmaken van Apple's APNs / Google's FCM als leveringskanaal (uw apparaat-pushtoken wordt uitsluitend voor levering gedeeld met deze aanbieders)

---

## 2. WAAROVER DE MELDINGEN GAAN

`Civo Cloud Manager` stuurt meldingen voor de volgende doeleinden:

| Categorie | Voorbeelden | Standaard |
|---|---|---|
| **Servicemeldingen** (essentieel) | accountwaarschuwingen, beveiligingswaarschuwingen, betalingsherinneringen, belangrijke updates | Aan |
| **Transactioneel** | bevestiging van een door u uitgevoerde handeling, statuswijzigingen waar u om heeft gevraagd | Aan |
| **Herinneringen** | herinneringen die u zelf heeft ingesteld in `Civo Cloud Manager` | Uw keuze |
| **Tips & nieuwe functies** | incidentele updates over nieuwe functionaliteit | Standaard uit — opt-in |
| **Marketing / promotioneel** | aanbiedingen, campagnes, nieuws over nieuwe producten | Standaard uit — opt-in; aparte toestemming onder § 4 |

Elke categorie kan onafhankelijk worden in- of uitgeschakeld in **Instellingen → Meldingen** binnen `Civo Cloud Manager` — en op elk moment in de meldingsinstellingen van uw apparaat op OS-niveau.

---

## 3. GEEN TRACKING VIA DE MELDING

Wij doen **niet** het volgende:

- meldingen gebruiken om uw locatie te volgen
- persoonlijk identificeerbare informatie (PII) over andere gebruikers opnemen in uw meldingen
- stille / achtergrondmeldingen gebruiken om analyses over u te verzamelen
- uw apparaat-pushtoken delen met andere partijen dan Apple / Google voor levering

---

## 4. MARKETINGMELDINGEN

Marketing- / promotionele pushmeldingen vallen onder Art. 6(1)(a) AVG + e-Privacy Art. 13: **expliciete, afzonderlijke, gedetailleerde opt-in is vereist**.

- De marketingoptie staat **standaard uit**
- U kunt deze op elk moment aan- (en uit-) zetten in **Instellingen → Meldingen → Marketing**
- Toestemming voor marketing-pushmeldingen is **afzonderlijk** van toestemming voor e-mailmarketing; het inschakelen van de ene schakelt de andere niet in
- Intrekken is net zo eenvoudig als opt-in (één schakelaar), en heeft geen invloed op niet-marketingmeldingen

---

## 5. KINDEREN

Indien `Civo Cloud Manager` wordt gebruikt door minderjarigen, is de [Kennisgeving Kinderprivacy](CHILDREN_PRIVACY_NOTICE.md) aanvullend van toepassing. Wij sturen geen marketing-pushmeldingen naar minderjarigen.

---

## 6. INGESCHAKELDE SUBVERWERKERS

Pushlevering maakt gebruik van platformeigen diensten:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (onafhankelijke verwerkingsverantwoordelijke voor het leveringskanaal)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (onafhankelijke verwerkingsverantwoordelijke voor het leveringskanaal)

Deze treden op als eigen verwerkingsverantwoordelijken voor de leveringslaag volgens hun eigen privacybeleid. Zie [`processors/apple.md`](processors/apple.md) en [Google Cloud subverwerkerregister](processors/google-cloud.md).

---

## 7. UW RECHTEN

U kunt te allen tijde:

- **Alle meldingen uitschakelen** op OS-niveau (Instellingen → Meldingen → `Civo Cloud Manager` → uit)
- **Specifieke categorieën uitschakelen** in de app (Instellingen → Meldingen)
- **Marketingtoestemming intrekken** zonder servicemeldingen te verliezen
- **Verwijdering aanvragen** van alle gegevens die wij bewaren met betrekking tot meldingsvoorkeuren via `data-protection@digitalfreedom.co.za`

Het intrekken van toestemming heeft geen invloed op de rechtmatigheid van de verwerking vóór de intrekking.

---

## 8. ALS U "NIET TOESTAAN" ZEGT

Als u het systeemverzoek weigert:

- `Civo Cloud Manager` blijft werken — geen enkele functie wordt achter een meldingsmachtiging geplaatst
- u kunt later van gedachten veranderen in **Instellingen → Meldingen → `Civo Cloud Manager`** (OS-niveau)
- wij zullen u niet herhaaldelijk opnieuw vragen of gebruikmaken van misleidende patronen om toestemming af te dwingen

---

## 9. CONTACT

DigitalFreedom
Een merk van DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Verenigde Staten

Hulp bij meldingsvoorkeuren: support@digitalfreedom.co.za
Gegevensbescherming: data-protection@digitalfreedom.co.za
Algemeen: hello@digitalfreedom.co.za
Website: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. Alle rechten voorbehouden.
