<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: it | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# AVVISO DI CONSENSO PER LE NOTIFICHE PUSH

## Informazioni visualizzate insieme al prompt di autorizzazione di sistema per le notifiche push

**Data di entrata in vigore:** Settembre 2026

**Fornitore:**
DigitalFreedom
Un marchio di DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Stati Uniti
Contatto: hello@digitalfreedom.co.za
Protezione dei dati: data-protection@digitalfreedom.co.za
Sito web: https://digitalfreedom.co.za

---

## 0. SCOPO

Il presente Avviso viene mostrato **prima** del prompt di autorizzazione di sistema iOS / Android per le notifiche push. Informa l’utente — in linguaggio semplice — su cosa sta prestando il proprio consenso. Soddisfa i seguenti requisiti:

- **Art. 6(1)(a) GDPR** — consenso libero, specifico, informato e inequivocabile per il trattamento relativo alle notifiche quando queste contengono dati personali
- **Art. 13 GDPR** — trasparenza al momento della raccolta
- **Direttiva ePrivacy 2002/58/CE Art. 13 / attuazioni nazionali** — per qualsiasi notifica con contenuto di marketing
- **Apple Human Interface Guidelines** e **Google Play Developer Policy** — migliori pratiche di pre-prompt

I Servizi sono distribuiti a livello globale tramite Apple App Store e Google Play Store; il presente Avviso si applica ovunque siano abilitate le notifiche push ed è fornito nella lingua dell’utente ove supportato.

---

## 1. COSA STAI AUTORIZZANDO

Se tocchi **"Consenti"** al prossimo prompt, `Civo Cloud Manager` potrà:

- inviare notifiche al tuo dispositivo
- mostrare avvisi, badge, banner e suoni (in base alle impostazioni a livello di sistema operativo)
- utilizzare APNs di Apple / FCM di Google come canale di consegna (il token push del tuo dispositivo viene condiviso con questi fornitori solo per la consegna)

---

## 2. OGGETTO DELLE NOTIFICHE

`Civo Cloud Manager` invia notifiche per i seguenti scopi:

| Categoria | Esempi | Predefinito |
|---|---|---|
| **Notifiche di servizio** (essenziali) | avvisi account, avvisi di sicurezza, promemoria di pagamento, aggiornamenti importanti | Attivo |
| **Transazionali** | conferma di un’azione da te eseguita, cambiamenti di stato richiesti | Attivo |
| **Promemoria** | promemoria impostati da te in `Civo Cloud Manager` | A tua scelta |
| **Suggerimenti & nuove funzionalità** | aggiornamenti occasionali su nuove funzionalità | Disattivato per impostazione predefinita — opt-in |
| **Marketing / promozionali** | offerte, campagne, novità su nuovi prodotti | Disattivato per impostazione predefinita — opt-in; consenso separato ai sensi del § 4 |

Ogni categoria può essere attivata o disattivata in modo indipendente in **Impostazioni → Notifiche** all’interno di `Civo Cloud Manager` — e in qualsiasi momento nelle impostazioni delle notifiche a livello di sistema operativo del tuo dispositivo.

---

## 3. NESSUN TRACCIAMENTO ATTRAVERSO LA NOTIFICA

Noi **non**:

- utilizziamo le notifiche per tracciare la tua posizione
- includiamo informazioni personali identificabili (PII) su altri utenti nelle tue notifiche
- utilizziamo notifiche silenziose / in background per raccogliere analisi su di te
- condividiamo il token push del tuo dispositivo con soggetti diversi da Apple / Google per la consegna

---

## 4. NOTIFICHE DI MARKETING

Le notifiche push di marketing / promozionali sono regolate dall’Art. 6(1)(a) GDPR + ePrivacy Art. 13: **è richiesto un opt-in esplicito, separato e granulare**.

- L’interruttore per il marketing è **disattivato** per impostazione predefinita
- Puoi attivarlo (e disattivarlo) in qualsiasi momento in **Impostazioni → Notifiche → Marketing**
- Il consenso alle notifiche push di marketing è **distinto** dal consenso al marketing via email; abilitare uno non abilita l’altro
- La revoca è semplice quanto l’opt-in (un solo interruttore), e non influisce sulle notifiche non di marketing

---

## 5. MINORI

Se `Civo Cloud Manager` viene utilizzato da minori, si applica anche l’[Informativa sulla privacy dei minori](CHILDREN_PRIVACY_NOTICE.md). Non inviamo notifiche push di marketing ai minori.

---

## 6. SUB-RESPONSABILI COINVOLTI

La consegna delle notifiche push utilizza servizi nativi della piattaforma:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (titolare autonomo per il canale di consegna)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (titolare autonomo per il canale di consegna)

Questi agiscono come titolari autonomi per il livello di consegna secondo le proprie informative sulla privacy. Vedi [`processors/apple.md`](processors/apple.md) e [registro dei sub-responsabili Google Cloud](processors/google-cloud.md).

---

## 7. I TUOI DIRITTI

Puoi in qualsiasi momento:

- **Disattivare** tutte le notifiche a livello di sistema operativo (Impostazioni → Notifiche → `Civo Cloud Manager` → off)
- **Disattivare categorie specifiche** nell’app (Impostazioni → Notifiche)
- **Revocare il consenso al marketing** senza perdere le notifiche di servizio
- **Richiedere la cancellazione** di qualsiasi dato in nostro possesso relativo alle preferenze di notifica tramite `data-protection@digitalfreedom.co.za`

La revoca del consenso non pregiudica la liceità del trattamento effettuato prima della revoca stessa.

---

## 8. SE DICI "NON CONSENTIRE"

Se rifiuti il prompt di sistema:

- `Civo Cloud Manager` continuerà a funzionare — nessuna funzionalità è vincolata al consenso alle notifiche
- puoi cambiare idea in seguito in **Impostazioni → Notifiche → `Civo Cloud Manager`** (a livello di sistema operativo)
- non ti riproporremo ripetutamente il prompt né useremo dark pattern per forzare il consenso

---

## 9. CONTATTI

DigitalFreedom
Un marchio di DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Stati Uniti

Assistenza preferenze notifiche: support@digitalfreedom.co.za
Protezione dei dati: data-protection@digitalfreedom.co.za
Generale: hello@digitalfreedom.co.za
Sito web: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. Tutti i diritti riservati.
