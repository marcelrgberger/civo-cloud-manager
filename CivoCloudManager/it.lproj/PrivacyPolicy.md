# Informativa sulla Privacy

## Civo Cloud Manager

**Data di entrata in vigore:** Aprile 2026
**Ultimo aggiornamento:** Aprile 2026

**Titolare del trattamento:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Germania
Email: moin@berger-rosenstock.de

---

## 1. Introduzione

La presente Informativa sulla Privacy illustra le modalità con cui Marcel R. G. Berger, operante come Berger & Rosenstock GbR ("noi", "nostro"), tratta le informazioni relative all'applicazione Civo Cloud Manager ("l'Applicazione").

Ci impegniamo a tutelare la Sua privacy e a rispettare le leggi applicabili in materia di protezione dei dati, comprese, a titolo esemplificativo ma non esaustivo:

- Regolamento Generale UE sulla Protezione dei Dati (RGPD, Regolamento (UE) 2016/679)
- Legge Federale Tedesca sulla Protezione dei Dati (BDSG)
- Regolamento Generale sulla Protezione dei Dati del Regno Unito (UK GDPR) e Data Protection Act 2018
- Legge Federale Svizzera sulla Protezione dei Dati (LPD / revDSG)
- California Consumer Privacy Act (CCPA) e California Privacy Rights Act (CPRA)
- Virginia Consumer Data Protection Act (VCDPA), Colorado Privacy Act (CPA), Connecticut Data Privacy Act (CTDPA), Utah Consumer Privacy Act (UCPA) e altre leggi statali statunitensi
- Personal Information Protection and Electronic Documents Act (PIPEDA) canadese e leggi provinciali
- Australian Privacy Act 1988 e Australian Privacy Principles (APPs)
- Legge Generale Brasiliana sulla Protezione dei Dati (LGPD, Legge n. 13.709/2018)
- Legge Giapponese sulla Protezione delle Informazioni Personali (APPI)
- Legge Sudcoreana sulla Protezione delle Informazioni Personali (PIPA)
- Personal Data Protection Act di Singapore (PDPA)
- Personal Data Protection Act thailandese (PDPA 2019)
- Legge Cinese sulla Protezione delle Informazioni Personali (PIPL)
- Digital Personal Data Protection Act indiano del 2023 (DPDP Act)
- Protection of Personal Information Act sudafricano (POPIA)
- Personal Data Protection Law degli Emirati Arabi Uniti (PDPL)
- New Zealand Privacy Act 2020
- Children's Online Privacy Protection Act (COPPA, USA)

---

## 2. Principio di Raccolta Zero

**Non raccogliamo, conserviamo, trasmettiamo né trattiamo alcun dato personale sui nostri server.**

L'Applicazione opera interamente sul Suo dispositivo. Tutte le configurazioni, le credenziali e le preferenze sono memorizzate localmente. Non disponiamo di server che ricevono i Suoi dati. Non gestiamo alcuna infrastruttura backend per raccolta dati, analisi, segnalazione di crash o telemetria.

Poiché non trattiamo dati personali sotto il nostro controllo, la maggior parte degli obblighi previsti dalle leggi sulla protezione dei dati (doveri del titolare, obblighi relativi ai trasferimenti internazionali, notifica delle violazioni, ecc.) non si applica a noi in qualità di editore di questa Applicazione. La Sezione 10 descrive comunque i diritti a Sua disposizione ai sensi della legge applicabile.

---

## 3. Dati Memorizzati sul Suo Dispositivo

L'Applicazione memorizza localmente i seguenti dati sul Suo dispositivo macOS. Nessuno di questi dati viene trasmesso ai nostri server.

### 3.1 Credenziali

- **Chiave API Civo** — memorizzata nel Keychain di macOS (crittografia supportata dall'hardware) — utilizzata per autenticarsi con la Civo Cloud API
- **Credenziali Kubeconfig** — memorizzate solo in memoria durante le sessioni attive, mai salvate su disco
- **Credenziali Object Store (Access Key ID / Secret)** — recuperate dalla Civo API su richiesta, memorizzate solo in memoria

### 3.2 Preferenze

- **Regione selezionata** (UserDefaults) — codice regione Civo attiva
- **Firewall gestiti** (UserDefaults, JSON) — configurazioni firewall tracciate dall'Applicazione
- **Avvio al login** (UserDefaults) — preferenza di avvio automatico
- **Stato di onboarding** (UserDefaults) — flag di completamento della configurazione
- **Preset IP** (UserDefaults, JSON) — indirizzi IP denominati dall'utente per le regole firewall

### 3.3 Dati di Runtime Transitori

- **IP pubblico rilevato** — mantenuto in memoria durante la sessione, mai salvato
- **Risposte API** — mantenute in memoria mentre sono visualizzate, mai conservate oltre la sessione

### 3.4 Stato degli Acquisti

Gestito interamente da Apple StoreKit. Non riceviamo, conserviamo né trattiamo alcuna informazione di pagamento.

---

## 4. Base Giuridica del Trattamento (RGPD)

Poiché non agiamo come titolare o responsabile del trattamento per dati personali raccolti tramite l'Applicazione, le basi giuridiche di cui all'art. 6 RGPD non si applicano a noi. Nella misura in cui il funzionamento dell'Applicazione comporta un trattamento locale sul Suo dispositivo, questo avviene sulla base di:

- **Esecuzione del contratto** (art. 6, par. 1, lett. b) RGPD) — fornitura delle funzionalità per le quali ha installato l'Applicazione
- **Consenso** (art. 6, par. 1, lett. a) RGPD) — laddove Lei attivi esplicitamente azioni quali il rilevamento IP, la creazione di regole firewall o l'autenticazione tramite Touch ID

Nessun trattamento avviene ai sensi dell'art. 6, par. 1, lett. a), c), d), e) o f) RGPD su infrastrutture gestite da noi.

---

## 5. Modalità di Utilizzo dei Dati

I dati presenti sul Suo dispositivo sono utilizzati esclusivamente per:

- Autenticarsi presso la Civo Cloud API, i server API di Kubernetes e gli endpoint di archiviazione oggetti compatibili con S3 indicati dall'utente tramite l'Applicazione
- Gestire le Sue risorse Civo Cloud (istanze, cluster, database, firewall, ecc.)
- Rilevare il Suo indirizzo IPv4 pubblico per aprire e chiudere regole firewall
- Visualizzare localmente lo stato delle risorse, le stime dei costi e i log di attività
- Elaborare l'acquisto in-app una tantum tramite Apple StoreKit

I dati non vengono mai condivisi, venduti, noleggiati o altrimenti divulgati a terzi da parte nostra.

---

## 6. Servizi di Terze Parti

L'Applicazione comunica direttamente con i seguenti servizi di terze parti su Sua esplicita indicazione. Non siamo parte di tali comunicazioni.

### 6.1 Civo Cloud API (api.civo.com)

- **Finalità:** Gestire la Sua infrastruttura Civo Cloud
- **Dati inviati:** La Sua chiave API Civo (come header di autenticazione), richieste di gestione risorse
- **Gestore:** Civo Ltd, Regno Unito
- **Informativa sulla privacy:** https://www.civo.com/privacy

### 6.2 Server API Kubernetes

- **Finalità:** Accedere a nodi del cluster, pod, log, deployment e metriche
- **Dati inviati:** Credenziali tramite certificato client dal Suo kubeconfig (mTLS PKCS#12)
- **Gestore:** L'operatore del cluster Kubernetes (il Suo cluster Civo; Lei controlla l'endpoint)

### 6.3 Civo Object Storage (compatibile S3)

- **Finalità:** Sfogliare, caricare e scaricare file nei Suoi object store
- **Dati inviati:** Richieste compatibili S3 firmate con le Sue credenziali object store (AWS Signature V4)
- **Gestore:** Civo Ltd

### 6.4 Servizi di Rilevamento IP

- **Finalità:** Rilevare il Suo indirizzo IPv4 pubblico per la gestione delle regole firewall
- **Servizi utilizzati:** ipify.org, ifconfig.me, icanhazip.com (catena di fallback)
- **Dati inviati:** Richiesta HTTPS standard (il Suo indirizzo IP è intrinsecamente visibile a tali servizi)
- **Dati ricevuti:** Il Suo indirizzo IPv4 pubblico

### 6.5 Apple App Store / StoreKit

- **Finalità:** Elaborare acquisti in-app, verificare diritti, abilitare l'uso in famiglia
- **Dati inviati:** Gestiti interamente dal framework StoreKit di Apple
- **Gestore:** Apple Inc.
- **Informativa sulla privacy:** https://www.apple.com/legal/privacy/

### 6.6 SDK Non Utilizzati

**Non** integriamo alcuno dei seguenti:

- SDK di analytics (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog, ecc.)
- SDK di segnalazione crash (Crashlytics, Sentry, Bugsnag, ecc.)
- SDK pubblicitari (AdMob, Meta Audience Network, AppLovin, ecc.)
- SDK di attribuzione (AppsFlyer, Adjust, Branch, Kochava, ecc.)
- Framework per test A/B
- SDK di social media
- Fornitori di autenticazione terzi

---

## 7. Trasferimenti Internazionali di Dati

Non trasferiamo dati personali a livello internazionale poiché non raccogliamo né trattiamo dati personali.

I flussi di dati avviati da Lei (chiamate API a Civo, Kubernetes, S3, rilevamento IP) possono comportare la trasmissione transfrontaliera. Tali trasferimenti sono disciplinati dalle informative sulla privacy e dai meccanismi di trasferimento dati dei rispettivi gestori. Per gli utenti SEE/Regno Unito, Civo Ltd si avvale delle decisioni di adeguatezza del Regno Unito e dell'UE e, ove applicabile, delle Clausole Contrattuali Standard (SCC).

---

## 8. Conservazione dei Dati

Non conserviamo alcun dato. Tutti i dati dell'Applicazione sono memorizzati localmente sul Suo dispositivo e sotto il Suo esclusivo controllo.

- **La disinstallazione dell'Applicazione** rimuove le preferenze memorizzate in UserDefaults (tipicamente `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Gli elementi del Keychain** possono persistere dopo la disinstallazione; possono essere rimossi manualmente tramite Accesso Portachiavi
- **Le cache dei costi del mese precedente** sono memorizzate localmente e rimosse insieme al container alla disinstallazione

---

## 9. Sicurezza dei Dati

Sebbene non raccogliamo i Suoi dati, implementiamo le seguenti misure di sicurezza all'interno dell'Applicazione:

- **Memorizzazione della chiave API:** Keychain di macOS con crittografia supportata dall'hardware (Secure Enclave ove disponibile)
- **Segreti Object Store:** protetti tramite Touch ID / password di sistema attraverso il framework LocalAuthentication
- **Credenziali Kubeconfig:** memorizzate solo in memoria durante le sessioni attive, mai salvate su disco
- **Comunicazione di rete:** HTTPS/TLS 1.2+ per tutte le comunicazioni API
- **Autenticazione certificato:** l'API Kubernetes utilizza mTLS con certificato client PKCS#12
- **App Sandbox:** l'Applicazione funziona all'interno della sandbox applicativa macOS, con i diritti minimi necessari
- **Hardened Runtime:** ulteriore rafforzamento della sicurezza a runtime
- **Nessuna telemetria:** nessun dato di utilizzo, analisi o segnalazione crash viene trasmesso
- **Nessun logging persistente:** i log utilizzano `os.Logger` con `privacy: .private` e non vengono esportati

Nessun sistema è completamente sicuro. Raccomandiamo di utilizzare una chiave API dedicata con i permessi Civo minimi necessari al Suo flusso di lavoro.

---

## 10. I Suoi Diritti

### 10.1 Diritti ai sensi del RGPD (UE / SEE / Regno Unito)

Lei ha il diritto di:

- **Accesso** ai Suoi dati personali (art. 15 RGPD) — non applicabile, non deteniamo dati su di Lei
- **Rettifica** di dati inesatti (art. 16 RGPD) — non applicabile
- **Cancellazione** / diritto all'oblio (art. 17 RGPD) — non applicabile; può eliminare i dati locali disinstallando
- **Limitazione** del trattamento (art. 18 RGPD) — non applicabile
- **Portabilità dei dati** (art. 20 RGPD) — non applicabile
- **Opposizione** al trattamento (art. 21 RGPD) — non applicabile
- **Revoca del consenso** in qualsiasi momento (art. 7, par. 3 RGPD) — può smettere di utilizzare l'Applicazione in qualsiasi momento
- **Proporre reclamo** a un'autorità di controllo

Tali diritti sono soddisfatti dalla nostra politica di raccolta zero. In caso di modifiche future, La informeremo e implementeremo il quadro completo dei diritti.

### 10.2 Diritti ai sensi del CCPA / CPRA (California, USA)

I residenti in California hanno il diritto di:

- Conoscere quali informazioni personali vengono raccolte, utilizzate, condivise o vendute
- Eliminare le informazioni personali
- Rifiutare la vendita o la condivisione di informazioni personali
- Non subire discriminazioni per l'esercizio dei diritti sulla privacy
- Correggere informazioni personali inesatte
- Limitare l'uso di informazioni personali sensibili

Non vendiamo informazioni personali. Non condividiamo informazioni personali per pubblicità comportamentale cross-context. Non raccogliamo informazioni personali ai sensi del CCPA/CPRA.

### 10.3 Diritti ai sensi di Altre Leggi Statali Statunitensi (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR, ecc.)

I residenti in Virginia, Colorado, Connecticut, Utah, Texas, Oregon, Iowa, Montana, Florida, Tennessee, Indiana, Delaware, New Jersey e altri Stati americani con normativa sulla privacy hanno il diritto di accedere, eliminare, correggere e rifiutare pubblicità mirata / vendita / profilazione. Tali diritti sono soddisfatti dalla nostra politica di raccolta zero.

### 10.4 Diritti ai sensi del PIPEDA e delle Leggi Provinciali (Canada)

I residenti canadesi hanno il diritto di accedere, contestare l'accuratezza, revocare il consenso e presentare reclamo all'Office of the Privacy Commissioner of Canada (o alle autorità provinciali in Québec, British Columbia, Alberta).

### 10.5 Diritti ai sensi dell'Australian Privacy Act

I residenti australiani hanno il diritto di accedere e correggere le proprie informazioni personali e di presentare reclamo all'Office of the Australian Information Commissioner (OAIC).

### 10.6 Diritti ai sensi della LGPD (Brasile)

I residenti brasiliani hanno il diritto alla conferma del trattamento, accesso, correzione, anonimizzazione, portabilità, informazioni sulla condivisione e revoca del consenso. I reclami possono essere indirizzati all'Autoridade Nacional de Proteção de Dados (ANPD).

### 10.7 Diritti ai sensi dell'APPI (Giappone)

I residenti giapponesi hanno il diritto di divulgazione, correzione, cancellazione e cessazione dell'uso. I reclami possono essere indirizzati alla Personal Information Protection Commission (PPC).

### 10.8 Diritti ai sensi del PIPA (Corea del Sud)

I residenti sudcoreani hanno il diritto di accedere, correggere, cancellare, sospendere il trattamento e richiedere il risarcimento. I reclami possono essere indirizzati alla Personal Information Protection Commission (PIPC).

### 10.9 Diritti ai sensi del PDPA (Singapore / Thailandia)

I residenti hanno il diritto di accedere, correggere e revocare il consenso. I reclami possono essere indirizzati alla Personal Data Protection Commission (PDPC) del rispettivo paese.

### 10.10 Diritti ai sensi del PIPL (Cina)

I residenti cinesi hanno il diritto di conoscere, decidere, limitare, rifiutare, accedere, copiare, portare, correggere, cancellare e richiedere spiegazioni sulle regole di trattamento.

### 10.11 Diritti ai sensi del DPDP Act (India)

I residenti indiani hanno il diritto all'informazione, alla correzione, alla cancellazione, alla soluzione dei reclami e alla nomina.

### 10.12 Diritti ai sensi del POPIA (Sudafrica)

I residenti sudafricani hanno il diritto di accesso, correzione, cancellazione e reclamo all'Information Regulator.

### 10.13 Diritti ai sensi della LPD Svizzera

I residenti svizzeri hanno il diritto all'informazione, accesso, rettifica, cancellazione, opposizione e portabilità dei dati. I reclami possono essere indirizzati all'Incaricato federale della protezione dei dati e della trasparenza (IFPDT).

### 10.14 Diritti ai sensi del NZ Privacy Act

I residenti neozelandesi hanno il diritto di accedere e correggere le informazioni personali e di presentare reclamo al Privacy Commissioner.

### 10.15 Come Esercitare i Suoi Diritti

Poiché non deteniamo dati su di Lei, tali diritti sono soddisfatti per impostazione predefinita. Se ritiene che deteniamo dati personali che La riguardano nonostante la presente Informativa, contatti moin@berger-rosenstock.de.

---

## 11. Privacy dei Minori

L'Applicazione ha una classificazione per età sull'Apple App Store di **4+** ed è quindi tecnicamente accessibile a utenti di tutte le età. Tuttavia, l'Applicazione è uno strumento tecnico di gestione dell'infrastruttura destinato agli amministratori di account Civo Cloud. Un account Civo Cloud richiede che il titolare abbia l'età contrattuale legale nella propria giurisdizione.

**Non raccogliamo consapevolmente informazioni personali da alcun utente, inclusi i minori di 13 anni (COPPA, USA), 16 anni (RGPD-K, UE) o l'età di consenso applicabile nella Sua giurisdizione.**

Poiché l'Applicazione implementa una rigorosa politica di raccolta zero (vedere Sezione 2), nessuna informazione personale relativa a qualsiasi utente — indipendentemente dall'età — viene raccolta, trasmessa, memorizzata sui nostri server o condivisa con terzi. Ciò soddisfa:

- **COPPA** (Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506, USA)
- **RGPD art. 8** (UE)
- **PIPEDA** e leggi provinciali applicabili (Canada)
- **LGPD art. 14** (Brasile)
- **APPI** (Giappone)
- **Australian Privacy Act** e APP 8 sulla privacy dei minori

Se Lei è genitore o tutore e ritiene che il minore abbia fornito informazioni personali, contatti moin@berger-rosenstock.de. Indagheremo prontamente ed elimineremo tali informazioni ove rinvenute.

---

## 12. Cookie e Tracciamento

L'Applicazione è un'applicazione macOS nativa e non utilizza cookie, web beacon, pixel tag, fingerprinting o tecnologie di tracciamento simili.

L'Applicazione non contiene webview incorporate che carichino contenuti di terze parti.

---

## 13. Processo Decisionale Automatizzato

Non effettuiamo processi decisionali automatizzati o profilazione che producano effetti giuridici o incidano in modo analogamente significativo su di Lei. L'Applicazione non esegue decisioni automatizzate basate su dati personali.

---

## 14. Link e Servizi di Terze Parti

L'Applicazione può contenere link a siti web di terze parti (ad es. sito web di Civo, Apple App Store, piattaforma di risoluzione delle controversie online). Non siamo responsabili delle pratiche sulla privacy o dei contenuti dei servizi di terze parti. La preghiamo di consultare le loro informative sulla privacy prima di fornire dati.

---

## 15. Modifiche alla Presente Informativa

Possiamo aggiornare la presente Informativa sulla Privacy di volta in volta.

- Le modifiche sostanziali saranno comunicate tramite l'Applicazione o la pagina dell'App Store con almeno 30 giorni di anticipo rispetto all'entrata in vigore
- La "Data di entrata in vigore" in alto riflette l'ultima revisione
- Non modificheremo retroattivamente le nostre pratiche sulla privacy per raccogliere dati senza ottenere il Suo esplicito consenso

---

## 16. Contatti

Per richieste relative alla privacy o per esercitare i Suoi diritti:

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Germania
Email: moin@berger-rosenstock.de

Per i residenti nell'UE, può inoltre contattare l'autorità di controllo competente nel Suo Stato membro. Un elenco delle autorità di controllo UE è disponibile all'indirizzo: https://edpb.europa.eu/about-edpb/board/members_en

Per i residenti nel Regno Unito, l'autorità di controllo è l'Information Commissioner's Office (ICO): https://ico.org.uk

---

## 17. Disposizioni Regionali

### 17.1 Unione Europea / Spazio Economico Europeo

- Il funzionamento è conforme al RGPD ove applicabile al trattamento locale sul Suo dispositivo
- L'autorità di controllo del titolare del trattamento è l'autorità tedesca competente per la protezione dei dati del Land
- Le Valutazioni d'Impatto sulla Protezione dei Dati (DPIA) non sono richieste (nessuna raccolta)

### 17.2 Germania

- Conformità con il RGPD e il Bundesdatenschutzgesetz (BDSG)
- Autorità di controllo competente: il Landesbeauftragte für Datenschutz del relativo Land federale (il titolare risiede in Germania)

### 17.3 Austria

- Conformità con il RGPD e il Datenschutzgesetz (DSG)
- Autorità di controllo: Datenschutzbehörde (DSB)

### 17.4 Svizzera

- Conformità con la Legge Federale riveduta sulla Protezione dei Dati (revDSG), in vigore dal 1° settembre 2023
- Autorità di controllo: Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB)

### 17.5 Regno Unito

- Conformità con UK GDPR e Data Protection Act 2018
- Autorità di controllo: Information Commissioner's Office (ICO)

### 17.6 Francia

- Conformità con il RGPD e la Loi Informatique et Libertés
- Autorità di controllo: Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Italia

- Conformità con il RGPD e il Codice in materia di protezione dei dati personali (D.Lgs. 196/2003)
- Autorità di controllo: Garante per la Protezione dei Dati Personali

### 17.8 Spagna

- Conformità con il RGPD e la Ley Orgánica 3/2018 (LOPDGDD)
- Autorità di controllo: Agencia Española de Protección de Datos (AEPD)

### 17.9 Paesi Bassi

- Conformità con il RGPD e la Uitvoeringswet AVG (UAVG)
- Autorità di controllo: Autoriteit Persoonsgegevens (AP)

### 17.10 Polonia

- Conformità con il RGPD e la Ustawa o ochronie danych osobowych
- Autorità di controllo: Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portogallo

- Conformità con il RGPD e la Lei n.º 58/2019
- Autorità di controllo: Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 Belgio

- Conformità con il RGPD e la Loi du 30 juillet 2018
- Autorità di controllo: Gegevensbeschermingsautoriteit (APD-GBA)

### 17.13 Irlanda

- Conformità con il RGPD e il Data Protection Act 2018
- Autorità di controllo: Data Protection Commission (DPC)

### 17.14 Paesi Nordici (Danimarca, Finlandia, Norvegia, Svezia, Islanda)

- Conformità con il RGPD (ed equivalenti SEE per Norvegia e Islanda)
- Autorità nazionali di controllo: Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Altri Stati Membri UE/SEE

Conformità con il RGPD e la rispettiva attuazione nazionale. Elenco delle autorità di controllo: https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 Stati Uniti

- Conformità con le leggi statali applicabili in materia di privacy: CCPA/CPRA (California), VCDPA (Virginia), CPA (Colorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Texas), OCPA (Oregon), IDPA (Iowa), MCDPA (Montana), FDBR (Florida), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (New Jersey)
- I segnali "Do Not Track" e "Global Privacy Control" sono rispettati ove tecnicamente possibile (l'Applicazione non traccia)
- Conformità COPPA per utenti di età inferiore a 13 anni

### 17.17 Canada

- Conformità con PIPEDA e leggi provinciali applicabili: Quebec Act 25, British Columbia PIPA, Alberta PIPA
- Reclami: Office of the Privacy Commissioner of Canada (OPC) e autorità provinciali

### 17.18 Messico

- Conformità con la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Autorità di controllo: Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brasile

- Conformità con la LGPD
- Autorità di controllo: Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentina, Cile, Colombia, Perù, Uruguay

- Conformità con le leggi nazionali sulla protezione dei dati (Legge 25.326 / Legge 19.628 / Legge 1581 / Legge 29733 / Legge 18.331)

### 17.21 Australia

- Conformità con il Privacy Act 1988 e gli Australian Privacy Principles (APPs)
- Autorità di controllo: Office of the Australian Information Commissioner (OAIC)

### 17.22 Nuova Zelanda

- Conformità con il Privacy Act 2020
- Autorità di controllo: Office of the Privacy Commissioner

### 17.23 Giappone

- Conformità con l'Act on the Protection of Personal Information (APPI)
- Autorità di controllo: Personal Information Protection Commission (PPC)

### 17.24 Corea del Sud

- Conformità con il Personal Information Protection Act (PIPA)
- Autorità di controllo: Personal Information Protection Commission (PIPC)

### 17.25 Singapore

- Conformità con il Personal Data Protection Act (PDPA)
- Autorità di controllo: Personal Data Protection Commission (PDPC)

### 17.26 Thailandia

- Conformità con il Personal Data Protection Act B.E. 2562 (2019)
- Autorità di controllo: Personal Data Protection Committee

### 17.27 Cina

- Conformità con Personal Information Protection Law (PIPL), Cybersecurity Law (CSL) e Data Security Law (DSL)

### 17.28 Hong Kong

- Conformità con Personal Data (Privacy) Ordinance (PDPO)
- Autorità di controllo: Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 India

- Conformità con il Digital Personal Data Protection Act 2023 (DPDP Act) e l'Information Technology Act 2000
- Autorità di controllo: Data Protection Board of India

### 17.30 Emirati Arabi Uniti

- Conformità con il Federal Decree-Law No. 45 del 2021 (Personal Data Protection Law)

### 17.31 Arabia Saudita

- Conformità con la Personal Data Protection Law (PDPL)

### 17.32 Turchia

- Conformità con la Legge sulla Protezione dei Dati Personali n. 6698 (KVKK)
- Autorità di controllo: Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Israele

- Conformità con la Privacy Protection Law, 5741-1981 e i Privacy Protection Regulations
- Autorità di controllo: Privacy Protection Authority (PPA)

### 17.34 Sudafrica

- Conformità con il Protection of Personal Information Act (POPIA)
- Autorità di controllo: Information Regulator

### 17.35 Kenya, Nigeria, Egitto, Marocco

- Conformità con le leggi nazionali sulla protezione dei dati (Data Protection Act 2019 Kenya, NDPR / NDPA Nigeria, Legge n. 151 del 2020 Egitto, Legge 09-08 Marocco)

### 17.36 Altre Giurisdizioni

Per gli utenti in giurisdizioni non specificamente elencate sopra, l'approccio di raccolta zero dell'Applicazione garantisce la conformità con i principi di minimizzazione dei dati e limitazione delle finalità comuni ai moderni quadri sulla privacy. Qualora la Sua legge locale preveda diritti aggiuntivi, tali diritti sono rispettati.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. Tutti i diritti riservati.
