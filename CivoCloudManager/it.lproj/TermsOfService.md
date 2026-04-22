# Condizioni d'Uso

## Civo Cloud Manager

**Data di entrata in vigore:** Aprile 2026
**Ultimo aggiornamento:** Aprile 2026

**Fornitore:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Germania
Email: moin@berger-rosenstock.de
Partita IVA: DE455096022

---

## 1. Ambito di Applicazione e Accettazione

### 1.1 Accordo

Le presenti Condizioni d'Uso ("Condizioni") disciplinano l'accesso e l'utilizzo dell'applicazione Civo Cloud Manager ("l'Applicazione") fornita da Berger & Rosenstock GbR ("il Fornitore", "noi", "nostro").

### 1.2 Accettazione

Installando, accedendo o utilizzando l'Applicazione, Lei accetta di essere vincolato dalle presenti Condizioni. In caso di mancata accettazione, non deve installare né utilizzare l'Applicazione.

### 1.3 Requisiti

L'Applicazione ha una classificazione per età sull'Apple App Store di **4+**. Per stipulare un contratto vincolante, deve avere l'età contrattuale legale nella Sua giurisdizione. Un account Civo Cloud, necessario per un uso significativo dell'Applicazione, richiede che il titolare dell'account abbia l'età contrattuale legale.

### 1.4 Utilizzo Aziendale

Se utilizza l'Applicazione per conto di un'organizzazione, dichiara di avere il potere di vincolare tale organizzazione alle presenti Condizioni.

### 1.5 Apple Licensed Application End User License Agreement

Le presenti Condizioni sono integrative rispetto all'Apple Licensed Application End User License Agreement (EULA Apple) tra Lei e Apple Inc. In caso di conflitto tra le presenti Condizioni e l'EULA Apple, prevale l'EULA Apple in relazione alle materie da esso disciplinate.

---

## 2. Servizi

### 2.1 Descrizione

L'Applicazione è un'applicazione macOS nativa che consente la gestione dell'infrastruttura Civo Cloud (istanze virtuali, cluster Kubernetes, database, firewall, reti, bilanciatori di carico, volumi, object store, DNS, chiavi SSH) e l'accesso diretto all'API Kubernetes tramite le credenziali API dell'utente stesso.

L'Applicazione si connette direttamente dal Suo dispositivo a:

- La Civo Cloud REST API (`api.civo.com`)
- I server API Kubernetes dei Suoi cluster Civo (tramite mTLS)
- Gli endpoint di archiviazione oggetti compatibili con S3 del Suo account Civo
- Servizi di rilevamento IP pubblico (ipify.org, ifconfig.me, icanhazip.com)
- Apple App Store / StoreKit per l'elaborazione degli acquisti

Il Fornitore non gestisce alcun servizio backend, server intermedio o proxy. Tutte le comunicazioni avvengono direttamente tra il Suo dispositivo e i rispettivi gestori terzi.

### 2.2 Funzionalità Gratuite e a Pagamento

La funzionalità di gestione del firewall nella barra dei menu è gratuita. "Full Access" — che sblocca la dashboard di gestione per tutti i tipi di risorse supportate — è un acquisto in-app una tantum elaborato esclusivamente tramite l'Apple App Store (vedere Sezione 7).

### 2.3 Modifiche

Il Fornitore può modificare, sospendere o interrompere qualsiasi funzionalità dell'Applicazione in qualsiasi momento. Le modifiche sostanziali che interessano funzionalità acquistate saranno comunicate con almeno trenta (30) giorni di anticipo, ove praticabile.

### 2.4 Disponibilità

L'Applicazione è fornita "come disponibile". Il Fornitore non garantisce un accesso o una disponibilità ininterrotti, e la funzionalità dell'Applicazione dipende dalla disponibilità di servizi di terze parti (Civo Cloud, Apple App Store, fornitori di rilevamento IP) fuori dal controllo del Fornitore.

---

## 3. Account

L'Applicazione non richiede un account presso il Fornitore. Tutta l'autenticazione è gestita tramite:

- La Sua chiave API Civo (memorizzata localmente nel Keychain macOS)
- Il Suo kubeconfig Kubernetes (recuperato dalla Civo API)
- Il Suo ID Apple (per la verifica degli acquisti in-app, gestita da Apple)

Lei è responsabile di:

- Mantenere la riservatezza della Sua chiave API Civo e delle altre credenziali
- Tutte le attività svolte utilizzando le Sue credenziali
- Tutte le modifiche alle risorse, i costi e le implicazioni di fatturazione derivanti dal Suo utilizzo dell'Applicazione
- Configurare i permessi della chiave API Civo secondo il principio del minimo privilegio

Il Fornitore non ha la possibilità di accedere, recuperare o reimpostare le Sue credenziali Civo. La perdita delle credenziali è esclusivamente Sua responsabilità.

---

## 4. Contenuti dell'Utente

L'Applicazione non ospita, conserva né trasmette contenuti generati dall'utente ad alcun server gestito dal Fornitore. Qualsiasi contenuto, dato o configurazione che Lei crei utilizzando l'Applicazione (ad es. nomi di istanze, chiavi SSH, etichette di regole firewall, file object store) viene memorizzato:

- Localmente sul Suo dispositivo, oppure
- Nel Suo account Civo Cloud

Lei mantiene tutti i diritti, titoli e interessi su tali contenuti. Il Fornitore non rivendica alcuna licenza, proprietà o altro diritto sui Suoi contenuti.

---

## 5. Uso Accettabile

Non può utilizzare l'Applicazione per:

- Violare leggi, regolamenti o diritti di terzi applicabili
- Accedere o gestire risorse Civo per le quali non è autorizzato
- Interferire con o interrompere il servizio Civo Cloud, cluster Kubernetes non di Sua proprietà o l'Applicazione stessa
- Tentare di decodificare, decompilare, disassemblare o derivare il codice sorgente dall'Applicazione, salvo nella misura in cui tale restrizione sia vietata dalla legge applicabile
- Eludere i meccanismi di sicurezza o controllo degli accessi (incluso il paywall dell'acquisto in-app)
- Distribuire, concedere in sublicenza, locare, noleggiare, vendere o altrimenti sfruttare commercialmente l'Applicazione
- Rimuovere, alterare o oscurare avvisi proprietari, marchi di copyright o marchi registrati
- Utilizzare l'Applicazione per attaccare, compromettere o testare la sicurezza di sistemi non di Sua proprietà o per i quali non dispone di autorizzazione scritta esplicita a testare
- Utilizzare l'Applicazione per qualsiasi scopo vietato dalle leggi della Repubblica Federale di Germania, dell'Unione Europea o della Sua giurisdizione di residenza

---

## 6. Proprietà Intellettuale

### 6.1 Titolarità

L'Applicazione (inclusi codice sorgente, design, testi, grafica, icone, localizzazioni e tutti i relativi diritti di proprietà intellettuale) è di proprietà esclusiva del Fornitore ed è protetta dalle leggi tedesche, dell'Unione Europea e internazionali in materia di copyright, marchi e altre proprietà intellettuali.

### 6.2 Concessione di Licenza

Subordinatamente al rispetto delle presenti Condizioni e dell'EULA Apple, il Fornitore Le concede una licenza limitata, non esclusiva, non trasferibile, non concedibile in sublicenza e revocabile per installare e utilizzare l'Applicazione su dispositivi Apple di Sua proprietà o controllati da Lei, esclusivamente per il Suo uso personale o aziendale interno nella gestione della Sua infrastruttura Civo Cloud.

### 6.3 Marchi di Terze Parti

"Civo" è un marchio di Civo Ltd. "Apple", "App Store", "macOS", "iCloud", "StoreKit", "TestFlight" sono marchi di Apple Inc. "Kubernetes" è un marchio di The Linux Foundation. Tutti gli altri marchi sono di proprietà dei rispettivi titolari. Il Fornitore non è affiliato, approvato né sponsorizzato da nessuna di queste parti.

### 6.4 Feedback

Qualsiasi feedback, suggerimento o idea che Lei invii al Fornitore riguardo all'Applicazione potrà essere utilizzato dal Fornitore senza limitazioni e senza compenso per Lei.

---

## 7. Pagamenti e Abbonamenti

### 7.1 Acquisto In-App

"Full Access" è venduto come acquisto in-app non consumabile tramite l'Apple App Store per un corrispettivo una tantum. Il prezzo è mostrato nell'Applicazione nella Sua valuta locale prima dell'acquisto.

### 7.2 Elaborazione del Pagamento

Il pagamento è elaborato esclusivamente da Apple Inc. Il Fornitore non riceve, conserva né tratta alcuna informazione di pagamento. Tutte le questioni relative a pagamento, rimborso e fatturazione sono disciplinate dai Termini dei servizi multimediali Apple e dall'EULA Apple.

### 7.3 In Famiglia

"Full Access" è abilitato per la funzione "In Famiglia" di Apple. I membri del Suo gruppo "In Famiglia" potranno utilizzare l'acquisto sui propri dispositivi, secondo le regole "In Famiglia" di Apple.

### 7.4 Codici Promozionali Apple

Il Fornitore può emettere codici promozionali Apple per scopi promozionali. I codici promozionali possono essere riscattati tramite la funzione "Riscatta codice" nell'Applicazione o nell'App Store.

### 7.5 Rimborsi

I rimborsi sono gestiti esclusivamente da Apple in conformità con la politica di rimborso di Apple. I diritti legali dei consumatori ai sensi della legge applicabile (vedere Sezione 15) rimangono impregiudicati. In particolare, i consumatori dell'UE sono informati che il diritto legale di recesso di 14 giorni per i contenuti digitali decade all'inizio dell'esecuzione con il Suo previo consenso espresso — Apple implementa ciò tramite la finestra di conferma al momento dell'acquisto.

### 7.6 Imposte

Il prezzo visualizzato include tutte le imposte applicabili (IVA, sales tax) come determinate da Apple in base al Suo paese.

---

## 8. Servizi di Terze Parti

L'utilizzo dell'Applicazione richiede l'interazione con servizi di terze parti. L'uso di tali servizi è disciplinato dai rispettivi termini:

- **Civo Cloud:** https://www.civo.com/terms
- **Apple App Store / ID Apple:** https://www.apple.com/legal/internet-services/terms/
- **Cluster Kubernetes:** i termini del gestore del Suo cluster (Civo)

Il Fornitore non è parte di alcun accordo tra Lei e un fornitore di servizi terzi e non è responsabile della disponibilità, accuratezza o comportamento di tali servizi.

---

## 9. Esclusione di Garanzie

L'APPLICAZIONE È FORNITA "COSÌ COM'È" E "COME DISPONIBILE" SENZA GARANZIE DI ALCUN TIPO, ESPRESSE O IMPLICITE, INCLUSE, A TITOLO ESEMPLIFICATIVO MA NON ESAUSTIVO, LE GARANZIE DI COMMERCIABILITÀ, IDONEITÀ A UNO SCOPO PARTICOLARE, ACCURATEZZA, COMPLETEZZA O NON VIOLAZIONE.

IL FORNITORE NON GARANTISCE CHE:

- L'APPLICAZIONE SARÀ ININTERROTTA, PRIVA DI ERRORI O SICURA
- L'APPLICAZIONE VISUALIZZERÀ, CREERÀ, MODIFICHERÀ, ELIMINERÀ O GESTIRÀ CORRETTAMENTE LE RISORSE CIVO CLOUD
- QUALSIASI DATO VISUALIZZATO DALL'APPLICAZIONE SIA ACCURATO, COMPLETO O AGGIORNATO
- L'APPLICAZIONE SIA COMPATIBILE CON TUTTE LE VERSIONI, FUNZIONALITÀ O REGIONI DELL'API CIVO

**Operazioni distruttive.** L'Applicazione può eseguire operazioni irreversibili sul Suo account Civo Cloud, inclusa l'eliminazione di cluster Kubernetes, database, volumi, object store, istanze, chiavi SSH e regole firewall. Tutte le operazioni distruttive richiedono conferma esplicita dell'utente (tipicamente digitando il nome della risorsa). IL FORNITORE NON ASSUME ALCUNA RESPONSABILITÀ per eliminazioni non intenzionali, perdita di dati, superamenti di costo o danni all'infrastruttura causati dal Suo uso dell'Applicazione.

Si raccomanda vivamente di mantenere backup indipendenti di tutti i dati critici, di utilizzare una chiave API dedicata con i permessi Civo minimi necessari e di esaminare attentamente tutti i dialoghi di conferma.

Nessuna disposizione di questa Sezione esclude o limita alcuna garanzia che non possa essere esclusa o limitata dalla legge applicabile (vedere Sezione 15).

---

## 10. Limitazione di Responsabilità

NELLA MASSIMA MISURA CONSENTITA DALLA LEGGE APPLICABILE:

### 10.1 Esclusioni

IL FORNITORE NON SARÀ RESPONSABILE PER ALCUN DANNO INDIRETTO, INCIDENTALE, SPECIALE, CONSEQUENZIALE, PUNITIVO O ESEMPLARE, INCLUSI, A TITOLO ESEMPLIFICATIVO MA NON ESAUSTIVO:

- Perdita di dati, ricavi, profitti od opportunità di business
- Costi di approvvigionamento di servizi sostitutivi
- Danneggiamento o cancellazione di infrastrutture cloud, risorse o dati
- Accessi non autorizzati derivanti da chiavi API compromesse

### 10.2 Massimale

LA RESPONSABILITÀ COMPLESSIVA TOTALE DEL FORNITORE NEI SUOI CONFRONTI PER TUTTE LE PRETESE DERIVANTI DA O IN RELAZIONE ALL'APPLICAZIONE NON POTRÀ SUPERARE L'IMPORTO DA LEI EFFETTIVAMENTE PAGATO PER L'APPLICAZIONE NEI DODICI (12) MESI PRECEDENTI L'EVENTO CHE HA DATO ORIGINE ALLA PRETESA.

### 10.3 Esclusioni alla Limitazione

Nessuna disposizione delle presenti Condizioni esclude o limita la responsabilità per:

- Morte o lesioni personali causate da negligenza
- Frode o falsa dichiarazione fraudolenta
- Dolo o colpa grave (ai sensi del diritto tedesco, §§ 276, 309 BGB)
- Violazione di obbligazioni contrattuali essenziali (Kardinalpflichten), limitata ai danni prevedibili tipici per questo tipo di contratto
- Qualsiasi altra responsabilità che non possa essere esclusa o limitata dalla legge applicabile

### 10.4 Responsabilità da Prodotto

La responsabilità ai sensi della Legge tedesca sulla responsabilità da prodotto (Produkthaftungsgesetz) rimane impregiudicata.

---

## 11. Manleva

Lei accetta di manlevare, difendere e tenere indenni il Fornitore, i suoi soci, dipendenti e agenti da e contro qualsiasi pretesa, responsabilità, danno, perdita, costo, spesa o onorario (inclusi ragionevoli onorari legali) derivanti da o relativi a:

- La Sua violazione delle presenti Condizioni
- La Sua violazione di qualsiasi legge o diritto di terzi
- Il Suo uso dell'Applicazione per accedere o gestire infrastrutture per le quali non è autorizzato
- Qualsiasi contenuto o configurazione che Lei crei, modifichi o elimini tramite l'Applicazione

Questo obbligo di manleva non si applica ai consumatori ai sensi della legislazione applicabile a tutela dei consumatori laddove la legge imperativa vieti tale manleva.

---

## 12. Risoluzione

### 12.1 Risoluzione da Parte Sua

Lei può risolvere le presenti Condizioni in qualsiasi momento disinstallando l'Applicazione dai Suoi dispositivi.

### 12.2 Risoluzione da Parte del Fornitore

Il Fornitore può risolvere o sospendere immediatamente la Sua licenza d'uso dell'Applicazione qualora Lei violi sostanzialmente le presenti Condizioni. In caso di risoluzione:

- Il Suo diritto di utilizzare l'Applicazione cessa immediatamente
- Deve disinstallare l'Applicazione dai Suoi dispositivi
- Le Sezioni 6, 9, 10, 11, 13, 14, 16 sopravvivono alla risoluzione

### 12.3 Effetto sull'Acquisto

La risoluzione non dà diritto al rimborso dell'acquisto in-app, salvo quanto richiesto dalla legge applicabile a tutela dei consumatori o dalla politica di rimborso di Apple.

---

## 13. Legge Applicabile e Risoluzione delle Controversie

### 13.1 Legge Applicabile

Le presenti Condizioni sono regolate dalle leggi della Repubblica Federale di Germania, con esclusione delle sue norme di conflitto e della Convenzione delle Nazioni Unite sui Contratti di Compravendita Internazionale di Merci (CISG).

Per i consumatori all'interno dell'Unione Europea / SEE, questa scelta di legge non La priva della tutela consumeristica imperativa delle leggi del Suo paese di residenza abituale.

### 13.2 Foro Competente

Per commercianti, persone giuridiche di diritto pubblico e patrimoni speciali di diritto pubblico (Kaufleute, juristische Personen des öffentlichen Rechts, öffentlich-rechtliche Sondervermögen), il foro esclusivo per tutte le controversie derivanti dalle presenti Condizioni sarà Bad Nauheim, Germania.

Per i consumatori si applica il foro legale. Lei può avviare procedimenti presso i tribunali del Suo paese di residenza abituale.

### 13.3 Risoluzione delle Controversie Online UE

La Commissione Europea fornisce una piattaforma di risoluzione delle controversie online all'indirizzo https://ec.europa.eu/consumers/odr.

### 13.4 Arbitrato del Consumatore

Il Fornitore non è obbligato né disposto a partecipare a procedimenti di risoluzione delle controversie dinanzi a un organismo di composizione per i consumatori (Verbraucherschlichtungsstelle) ai sensi della Legge tedesca sulla risoluzione delle controversie dei consumatori (VSBG), salvo quanto richiesto dalla legge.

---

## 14. Disposizioni Regionali

### 14.1 Germania

- I diritti dei consumatori ai sensi del BGB §§ 312 e segg., §§ 327 e segg. (prodotti digitali) rimangono impregiudicati
- I diritti legali di recesso ai sensi del BGB § 355 si applicano ove applicabili

### 14.2 Unione Europea / SEE

- La Direttiva sui Diritti dei Consumatori 2011/83/UE e la Direttiva sui Contenuti Digitali (UE) 2019/770 si applicano qualora Lei sia un consumatore
- Le comunicazioni applicabili ai sensi del Digital Services Act (Regolamento (UE) 2022/2065) ai sensi dell'Articolo 12 sono fornite nelle Note Legali

### 14.3 Regno Unito

- Il Consumer Rights Act 2015 si applica qualora Lei sia un consumatore residente nel Regno Unito
- I contenuti digitali devono essere di qualità soddisfacente, idonei allo scopo e come descritti

### 14.4 Svizzera

- Le disposizioni consumeristiche imperative del Codice delle obbligazioni svizzero (CO) rimangono impregiudicate
- Si applica la Legge federale contro la concorrenza sleale (LCSl)

### 14.5 Stati Uniti

- Le presenti Condizioni non intendono creare diritti ai sensi di statuti statali a tutela dei consumatori che non siano applicabili nei loro termini
- Residenti in California: avviso dei diritti dei consumatori ai sensi del Civil Code § 1789.3 — contattare moin@berger-rosenstock.de

### 14.6 Canada

- La Quebec Consumer Protection Act si applica ai residenti del Québec ove imperativa
- Lingua dell'accordo: le presenti Condizioni sono fornite in inglese; versioni francesi disponibili ove richieste dalla Charter of the French Language (Québec)

### 14.7 Australia

- Le garanzie dell'Australian Consumer Law (Competition and Consumer Act 2010, Allegato 2) si applicano qualora Lei sia un consumatore — tali garanzie non possono essere escluse

### 14.8 Nuova Zelanda

- Il Consumer Guarantees Act 1993 si applica qualora Lei sia un consumatore per uso personale, domestico o familiare

### 14.9 Giappone

- Si applica il Consumer Contract Act (消費者契約法); le disposizioni delle presenti Condizioni che sarebbero invalide ai sensi di tale legge sono limitate nella misura necessaria

### 14.10 Corea del Sud

- Si applica l'Act on the Regulation of Terms and Conditions (약관의 규제에 관한 법률)

### 14.11 Brasile

- Si applica il Codice di Difesa del Consumatore (CDC, Legge n. 8.078/1990); i diritti dei consumatori non possono essere rinunciati

### 14.12 India

- Il Consumer Protection Act 2019 e le E-Commerce Rules 2020 si applicano qualora Lei sia un consumatore

### 14.13 Altre Giurisdizioni

Per gli utenti in giurisdizioni non specificamente elencate sopra, le presenti Condizioni si applicano nella misura consentita dalle leggi imperative locali a tutela dei consumatori.

---

## 15. Diritti dei Consumatori (Informazioni Obbligatorie)

Le presenti Condizioni non incidono sui Suoi diritti legali di consumatore ai sensi della legge applicabile, inclusi, a titolo esemplificativo ma non esaustivo:

- Direttiva UE sui Diritti dei Consumatori (2011/83/UE) e Direttiva sui Contenuti Digitali ((UE) 2019/770)
- UK Consumer Rights Act 2015
- Australian Consumer Law
- Disposizioni a tutela dei consumatori del BGB tedesco (§§ 312 e segg., §§ 327 e segg.)
- New Zealand Consumer Guarantees Act 1993
- Codice brasiliano di Difesa del Consumatore (CDC)
- Statuti provinciali canadesi a tutela dei consumatori
- Qualsiasi altra legislazione applicabile a tutela dei consumatori nella Sua giurisdizione

---

## 16. Disposizioni Generali

### 16.1 Modifiche alle Presenti Condizioni

Possiamo aggiornare le presenti Condizioni di volta in volta. Le modifiche sostanziali saranno comunicate tramite l'Applicazione o la pagina dell'App Store con almeno trenta (30) giorni di anticipo rispetto all'entrata in vigore. L'uso continuato dopo l'entrata in vigore delle modifiche costituisce accettazione.

### 16.2 Cessione

Lei non può cedere o trasferire le presenti Condizioni o alcun diritto derivante dalle stesse senza il previo consenso scritto del Fornitore. Il Fornitore può cedere le presenti Condizioni in relazione a una fusione, acquisizione o vendita di attività.

### 16.3 Clausola Salvatoria

Qualora una disposizione delle presenti Condizioni risulti inapplicabile o invalida, tale disposizione sarà limitata o eliminata nella misura minima necessaria affinché le presenti Condizioni restino per il resto pienamente efficaci. Per il diritto tedesco si applica il § 306 BGB.

### 16.4 Rinuncia

Il mancato esercizio da parte del Fornitore di qualsiasi disposizione delle presenti Condizioni non costituisce rinuncia a tale disposizione.

### 16.5 Intero Accordo

Le presenti Condizioni, insieme all'Informativa sulla Privacy, alle Note Legali e all'EULA Apple, costituiscono l'intero accordo tra Lei e il Fornitore riguardo all'Applicazione e sostituiscono tutti gli accordi e le intese precedenti.

### 16.6 Lingua

La versione autentica delle presenti Condizioni è la versione inglese. Le traduzioni sono fornite per comodità. In caso di discrepanza, prevale la versione inglese, salvo ove la legge locale imperativa disponga diversamente.

### 16.7 Comunicazioni Elettroniche

Lei acconsente a ricevere dal Fornitore le comunicazioni legalmente richieste in forma elettronica (tramite l'Applicazione o email).

### 16.8 Forza Maggiore

Il Fornitore non è responsabile di eventuali inadempimenti o ritardi nell'esecuzione causati da eventi al di fuori del suo ragionevole controllo, inclusi cause di forza maggiore, guerra, terrorismo, disordini civili, vertenze sindacali, interruzioni di internet, disservizi di servizi terzi o atti governativi.

---

## 17. Contatti

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Germania
Email: moin@berger-rosenstock.de
Partita IVA: DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. Tutti i diritti riservati.
