# Politique de confidentialité

## Civo Cloud Manager

**Date d'entrée en vigueur :** Avril 2026
**Dernière mise à jour :** Avril 2026

**Responsable du traitement :**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Allemagne
Courriel : moin@berger-rosenstock.de

---

## 1. Introduction

La présente politique de confidentialité explique la manière dont Marcel R. G. Berger, agissant sous la forme de Berger & Rosenstock GbR (« nous », « notre »), traite les informations en lien avec l'application Civo Cloud Manager (« l'Application »).

Nous nous engageons à protéger votre vie privée et à respecter les lois applicables en matière de protection des données, y compris, mais sans s'y limiter :

- Règlement général sur la protection des données de l'UE (RGPD, règlement (UE) 2016/679)
- Loi fédérale allemande sur la protection des données (BDSG)
- Règlement général sur la protection des données du Royaume-Uni (UK GDPR) et Data Protection Act 2018
- Loi fédérale suisse sur la protection des données (LPD / revDSG)
- California Consumer Privacy Act (CCPA) et California Privacy Rights Act (CPRA)
- Virginia Consumer Data Protection Act (VCDPA), Colorado Privacy Act (CPA), Connecticut Data Privacy Act (CTDPA), Utah Consumer Privacy Act (UCPA) et autres lois des États américains
- Loi canadienne sur la protection des renseignements personnels et les documents électroniques (LPRPDE / PIPEDA) et lois provinciales
- Australian Privacy Act 1988 et Australian Privacy Principles (APPs)
- Loi générale brésilienne sur la protection des données (LGPD, loi nº 13.709/2018)
- Loi japonaise sur la protection des informations personnelles (APPI)
- Loi sud-coréenne sur la protection des informations personnelles (PIPA)
- Loi singapourienne sur la protection des données personnelles (PDPA)
- Loi thaïlandaise sur la protection des données personnelles (PDPA 2019)
- Loi chinoise sur la protection des informations personnelles (PIPL)
- Digital Personal Data Protection Act 2023 de l'Inde (DPDP Act)
- Loi sud-africaine sur la protection des informations personnelles (POPIA)
- Loi des Émirats arabes unis sur la protection des données personnelles (PDPL)
- New Zealand Privacy Act 2020
- Children's Online Privacy Protection Act (COPPA, États-Unis)

---

## 2. Principe de collecte nulle

**Nous ne collectons, ne stockons, ne transmettons ni ne traitons aucune donnée personnelle sur nos serveurs.**

L'Application fonctionne entièrement sur votre appareil. Toutes les configurations, identifiants et préférences sont stockés localement. Nous n'exploitons aucun serveur qui reçoit vos données. Nous n'exploitons aucune infrastructure dorsale à des fins de collecte de données, d'analyse, de rapport d'erreurs ou de télémétrie.

Étant donné que nous ne traitons aucune donnée personnelle sous notre contrôle, la plupart des obligations découlant des lois sur la protection des données (obligations du responsable du traitement, obligations de transfert international, notification de violation, etc.) ne s'appliquent pas à nous en tant qu'éditeur de cette Application. La section 10 décrit néanmoins les droits dont vous disposez en vertu du droit applicable.

---

## 3. Données stockées sur votre appareil

L'Application stocke les données suivantes localement sur votre appareil macOS. Aucune de ces données n'est transmise à nos serveurs.

### 3.1 Identifiants

- **Clé API Civo** — stockée dans le trousseau macOS (chiffrement matériel) — utilisée pour l'authentification auprès de l'API Civo Cloud
- **Identifiants Kubeconfig** — stockés uniquement en mémoire pendant les sessions actives, jamais persistés sur le disque
- **Identifiants du stockage d'objets (Access Key ID / Secret)** — récupérés depuis l'API Civo à la demande, stockés uniquement en mémoire

### 3.2 Préférences

- **Région sélectionnée** (UserDefaults) — code de région Civo active
- **Pare-feu gérés** (UserDefaults, JSON) — configurations de pare-feu suivies par l'Application
- **Lancement à l'ouverture de session** (UserDefaults) — préférence de démarrage automatique
- **État d'intégration** (UserDefaults) — indicateur de fin de configuration
- **Préréglages d'adresses IP** (UserDefaults, JSON) — adresses IP nommées par l'utilisateur pour les règles de pare-feu

### 3.3 Données d'exécution transitoires

- **Adresse IP publique détectée** — conservée en mémoire pendant une session, jamais persistée
- **Réponses de l'API** — conservées en mémoire pendant leur affichage, jamais persistées au-delà de la session

### 3.4 Statut d'achat

Entièrement géré par Apple StoreKit. Nous ne recevons, ne stockons ni ne traitons aucune information de paiement.

---

## 4. Base juridique du traitement (RGPD)

Étant donné que nous n'agissons ni comme responsable du traitement ni comme sous-traitant pour les données personnelles collectées via l'Application, les bases juridiques de traitement prévues à l'art. 6 du RGPD ne s'appliquent pas à nous. Dans la mesure où l'exploitation de l'Application implique un traitement local sur votre appareil, celui-ci est effectué sur la base de :

- **Exécution d'un contrat** (art. 6, §1, b) RGPD) — fournir la fonctionnalité pour laquelle vous avez installé l'Application
- **Consentement** (art. 6, §1, a) RGPD) — lorsque vous déclenchez explicitement des actions telles que la détection d'IP, la création de règles de pare-feu ou l'authentification Touch ID

Aucun traitement n'est effectué au titre de l'art. 6, §1, a), c), d), e) ou f) RGPD sur une infrastructure exploitée par nos soins.

---

## 5. Utilisation des données

Les données présentes sur votre appareil sont utilisées exclusivement pour :

- S'authentifier auprès de l'API Civo Cloud, des serveurs API Kubernetes et des points de terminaison de stockage d'objets compatibles S3 vers lesquels vous dirigez l'Application
- Gérer vos ressources Civo Cloud (instances, clusters, bases de données, pare-feu, etc.)
- Détecter votre adresse IPv4 publique afin d'ouvrir et de fermer des règles de pare-feu
- Afficher localement l'état des ressources, les estimations de coûts et les journaux d'activité
- Traiter votre achat intégré unique via Apple StoreKit

Les données ne sont jamais partagées, vendues, louées ou autrement divulguées à des tiers par nos soins.

---

## 6. Services tiers

L'Application communique directement avec les services tiers suivants sur vos instructions explicites. Nous ne sommes pas partie à ces communications.

### 6.1 API Civo Cloud (api.civo.com)

- **Finalité :** gérer votre infrastructure Civo Cloud
- **Données envoyées :** votre clé API Civo (en tant qu'en-tête d'authentification), requêtes de gestion des ressources
- **Exploitant :** Civo Ltd, Royaume-Uni
- **Politique de confidentialité :** https://www.civo.com/privacy

### 6.2 Serveurs API Kubernetes

- **Finalité :** accéder aux nœuds, pods, journaux, déploiements et métriques du cluster
- **Données envoyées :** identifiants de certificat client issus de votre kubeconfig (mTLS PKCS#12)
- **Exploitant :** l'exploitant du cluster Kubernetes (votre cluster Civo ; vous contrôlez le point de terminaison)

### 6.3 Stockage d'objets Civo (compatible S3)

- **Finalité :** parcourir, téléverser et télécharger des fichiers dans vos magasins d'objets
- **Données envoyées :** requêtes compatibles S3 signées avec vos identifiants de magasin d'objets (AWS Signature V4)
- **Exploitant :** Civo Ltd

### 6.4 Services de détection d'IP

- **Finalité :** détecter votre adresse IPv4 publique pour la gestion des règles de pare-feu
- **Services utilisés :** ipify.org, ifconfig.me, icanhazip.com (chaîne de repli)
- **Données envoyées :** requête HTTPS standard (votre adresse IP est intrinsèquement visible par ces services)
- **Données reçues :** votre adresse IPv4 publique

### 6.5 App Store Apple / StoreKit

- **Finalité :** traiter les achats intégrés, vérifier les droits, activer le partage familial
- **Données envoyées :** entièrement gérées par le framework StoreKit d'Apple
- **Exploitant :** Apple Inc.
- **Politique de confidentialité :** https://www.apple.com/legal/privacy/

### 6.6 SDK non utilisés

Nous n'intégrons **aucun** des éléments suivants :

- SDK d'analyse (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog, etc.)
- SDK de rapport d'erreurs (Crashlytics, Sentry, Bugsnag, etc.)
- SDK publicitaires (AdMob, Meta Audience Network, AppLovin, etc.)
- SDK d'attribution (AppsFlyer, Adjust, Branch, Kochava, etc.)
- Frameworks de tests A/B
- SDK de réseaux sociaux
- Fournisseurs d'authentification tiers

---

## 7. Transferts internationaux de données

Nous ne transférons pas de données personnelles à l'international, car nous ne collectons ni ne traitons de données personnelles.

Les flux de données que vous initiez (appels d'API vers Civo, Kubernetes, S3, détection d'IP) peuvent impliquer une transmission transfrontalière. Ces transferts sont régis par les avis de confidentialité et les mécanismes de transfert de données des exploitants respectifs. Pour les utilisateurs de l'EEE/Royaume-Uni, Civo Ltd s'appuie sur les décisions d'adéquation britanniques et européennes et, le cas échéant, sur les clauses contractuelles types (CCT).

---

## 8. Conservation des données

Nous ne conservons aucune donnée. Toutes les données de l'Application sont stockées localement sur votre appareil et se trouvent sous votre seul contrôle.

- **La désinstallation de l'Application** supprime les préférences stockées dans UserDefaults (en général `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Les éléments du trousseau** peuvent subsister après la désinstallation ; ils peuvent être supprimés manuellement via Accès au trousseau
- **Les caches de coûts du mois écoulé** sont stockés localement et supprimés avec le conteneur lors de la désinstallation

---

## 9. Sécurité des données

Bien que nous ne collections pas vos données, nous mettons en œuvre les mesures de sécurité suivantes au sein de l'Application :

- **Stockage de la clé API :** trousseau macOS avec chiffrement matériel (Secure Enclave lorsqu'il est disponible)
- **Secrets du magasin d'objets :** protégés par Touch ID / mot de passe système via le framework LocalAuthentication
- **Identifiants Kubeconfig :** stockés uniquement en mémoire pendant les sessions actives, jamais persistés sur le disque
- **Communication réseau :** HTTPS/TLS 1.2+ pour toutes les communications API
- **Authentification par certificat :** l'API Kubernetes utilise une authentification mTLS par certificat client PKCS#12
- **Sandbox d'application :** l'Application s'exécute dans le sandbox macOS, avec les entitlements minimaux requis
- **Hardened Runtime :** durcissement de sécurité supplémentaire à l'exécution
- **Aucune télémétrie :** aucune donnée d'utilisation, analyse ou rapport d'erreur n'est transmis où que ce soit
- **Aucune journalisation persistante :** les journaux utilisent `os.Logger` avec `privacy: .private` et ne sont pas exportés

Aucun système n'est totalement sécurisé. Nous recommandons d'utiliser une clé API dédiée avec les permissions Civo minimales requises pour votre flux de travail.

---

## 10. Vos droits

### 10.1 Droits au titre du RGPD (UE / EEE / Royaume-Uni)

Vous disposez du droit :

- **D'accès** à vos données personnelles (art. 15 RGPD) — non applicable, nous ne détenons aucune donnée vous concernant
- **De rectification** des données inexactes (art. 16 RGPD) — non applicable
- **À l'effacement** / droit à l'oubli (art. 17 RGPD) — non applicable ; vous pouvez supprimer les données locales en désinstallant l'Application
- **À la limitation** du traitement (art. 18 RGPD) — non applicable
- **À la portabilité des données** (art. 20 RGPD) — non applicable
- **D'opposition** au traitement (art. 21 RGPD) — non applicable
- **De retirer son consentement** à tout moment (art. 7, §3, RGPD) — vous pouvez cesser d'utiliser l'Application à tout moment
- **D'introduire une réclamation** auprès d'une autorité de contrôle

Ces droits sont satisfaits par notre politique de collecte nulle. Si cela venait à changer dans une version future, nous vous en informerions et mettrions en œuvre le cadre complet des droits.

### 10.2 Droits au titre du CCPA / CPRA (Californie, États-Unis)

Les résidents de Californie ont le droit de :

- Savoir quelles informations personnelles sont collectées, utilisées, partagées ou vendues
- Supprimer les informations personnelles
- Refuser la vente ou le partage des informations personnelles
- Ne pas faire l'objet de discrimination pour l'exercice des droits à la vie privée
- Corriger les informations personnelles inexactes
- Limiter l'utilisation des informations personnelles sensibles

Nous ne vendons pas d'informations personnelles. Nous ne partageons pas d'informations personnelles à des fins de publicité comportementale inter-contextuelle. Nous ne collectons pas d'informations personnelles au sens du CCPA/CPRA.

### 10.3 Droits au titre d'autres lois étatiques des États-Unis (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR, etc.)

Les résidents de Virginie, du Colorado, du Connecticut, de l'Utah, du Texas, de l'Oregon, de l'Iowa, du Montana, de Floride, du Tennessee, de l'Indiana, du Delaware, du New Jersey et d'autres États américains dotés d'une législation sur la vie privée disposent de droits d'accès, de suppression, de correction et de refus de la publicité ciblée / vente / profilage. Ces droits sont satisfaits par notre politique de collecte nulle.

### 10.4 Droits au titre de la LPRPDE et des lois provinciales (Canada)

Les résidents canadiens ont le droit d'accéder à leurs renseignements, d'en contester l'exactitude, de retirer leur consentement et de porter plainte auprès du Commissariat à la protection de la vie privée du Canada (ou des autorités provinciales au Québec, en Colombie-Britannique, en Alberta).

### 10.5 Droits au titre de l'Australian Privacy Act

Les résidents australiens ont le droit d'accéder à leurs informations personnelles, de les corriger et de porter plainte auprès de l'Office of the Australian Information Commissioner (OAIC).

### 10.6 Droits au titre de la LGPD (Brésil)

Les résidents brésiliens ont le droit à la confirmation du traitement, à l'accès, à la correction, à l'anonymisation, à la portabilité, à l'information sur le partage et à la révocation du consentement. Les réclamations peuvent être adressées à l'Autoridade Nacional de Proteção de Dados (ANPD).

### 10.7 Droits au titre de l'APPI (Japon)

Les résidents japonais ont le droit à la divulgation, à la correction, à la suppression et à la cessation d'utilisation. Les réclamations peuvent être adressées à la Personal Information Protection Commission (PPC).

### 10.8 Droits au titre du PIPA (Corée du Sud)

Les résidents sud-coréens ont le droit d'accéder, de corriger, de supprimer, de suspendre le traitement et de demander des dommages-intérêts. Les réclamations peuvent être adressées à la Personal Information Protection Commission (PIPC).

### 10.9 Droits au titre du PDPA (Singapour / Thaïlande)

Les résidents ont le droit d'accéder, de corriger et de retirer leur consentement. Les réclamations peuvent être adressées à la Personal Data Protection Commission (PDPC) du pays concerné.

### 10.10 Droits au titre du PIPL (Chine)

Les résidents chinois ont le droit de savoir, de décider, de restreindre, de refuser, d'accéder, de copier, de porter, de corriger, de supprimer et de demander des explications concernant les règles de traitement.

### 10.11 Droits au titre du DPDP Act (Inde)

Les résidents indiens ont droit à l'information, à la correction, à l'effacement, au traitement des griefs et à la désignation.

### 10.12 Droits au titre de la POPIA (Afrique du Sud)

Les résidents sud-africains ont le droit d'accès, de correction, de suppression et de plainte auprès de l'Information Regulator.

### 10.13 Droits au titre de la LPD suisse

Les résidents suisses ont le droit à l'information, à l'accès, à la rectification, à la suppression, à l'opposition et à la portabilité des données. Les réclamations peuvent être adressées au Préposé fédéral à la protection des données et à la transparence (PFPDT).

### 10.14 Droits au titre du NZ Privacy Act

Les résidents néo-zélandais ont le droit d'accéder à leurs informations personnelles et de les corriger, et de porter plainte auprès du Privacy Commissioner.

### 10.15 Comment exercer vos droits

Étant donné que nous ne détenons aucune donnée vous concernant, ces droits sont satisfaits par défaut. Si vous estimez que nous détenons des données personnelles vous concernant malgré la présente politique, contactez moin@berger-rosenstock.de.

---

## 11. Vie privée des enfants

L'Application est classée **4+** dans l'App Store Apple et est donc techniquement accessible aux utilisateurs de tout âge. Cependant, l'Application est un outil technique de gestion d'infrastructure destiné aux administrateurs de comptes Civo Cloud. Un compte Civo Cloud exige que le titulaire ait atteint l'âge légal de contracter dans sa juridiction.

**Nous ne collectons sciemment d'informations personnelles auprès de personne, y compris des enfants de moins de 13 ans (COPPA, États-Unis), 16 ans (RGPD-K, UE), ou de l'âge de consentement applicable dans votre juridiction.**

L'Application mettant en œuvre une politique stricte de collecte nulle (voir section 2), aucune information personnelle concernant un utilisateur — quel que soit son âge — n'est collectée, transmise, stockée sur nos serveurs ni partagée avec des tiers. Cela satisfait :

- **COPPA** (Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506, États-Unis)
- **Art. 8 RGPD** (UE)
- **LPRPDE** et lois provinciales applicables (Canada)
- **Art. 14 LGPD** (Brésil)
- **APPI** (Japon)
- **Australian Privacy Act** et APP 8 sur la vie privée des enfants

Si vous êtes un parent ou tuteur et estimez que votre enfant a fourni des informations personnelles, contactez moin@berger-rosenstock.de. Nous enquêterons rapidement et supprimerons ces informations lorsqu'elles seront trouvées.

---

## 12. Cookies et traçage

L'Application est une application macOS native et n'utilise ni cookies, ni balises web, ni pixels espions, ni empreintes numériques, ni technologies de traçage similaires.

L'Application ne contient aucune vue web intégrée qui chargerait du contenu tiers.

---

## 13. Décisions automatisées

Nous ne procédons à aucune décision automatisée ou profilage produisant des effets juridiques ou vous affectant de manière significative. L'Application n'effectue aucune décision automatisée fondée sur des données personnelles.

---

## 14. Liens et services tiers

L'Application peut contenir des liens vers des sites web tiers (par exemple le site Civo, l'App Store Apple, la plateforme de règlement en ligne des litiges). Nous ne sommes pas responsables des pratiques de confidentialité ou du contenu des services tiers. Veuillez consulter leurs politiques de confidentialité avant de fournir des données.

---

## 15. Modifications de la présente politique

Nous pouvons mettre à jour la présente politique de confidentialité de temps à autre.

- Les modifications substantielles seront communiquées via l'Application ou la fiche App Store au moins 30 jours avant leur entrée en vigueur
- La « Date d'entrée en vigueur » figurant en tête reflète la dernière révision
- Nous ne modifierons pas rétroactivement nos pratiques de confidentialité pour collecter des données sans obtenir votre consentement explicite

---

## 16. Contact

Pour toute demande relative à la vie privée ou pour exercer vos droits :

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Allemagne
Courriel : moin@berger-rosenstock.de

Pour les résidents de l'UE, vous pouvez également contacter l'autorité de contrôle compétente de votre État membre. Une liste des autorités de contrôle de l'UE est disponible à l'adresse suivante : https://edpb.europa.eu/about-edpb/board/members_en

Pour les résidents du Royaume-Uni, l'autorité de contrôle est l'Information Commissioner's Office (ICO) : https://ico.org.uk

---

## 17. Dispositions régionales

### 17.1 Union européenne / Espace économique européen

- Le fonctionnement est conforme au RGPD lorsqu'il s'applique au traitement local sur votre appareil
- L'autorité de contrôle du responsable du traitement est l'autorité allemande compétente de protection des données au niveau du Land
- Les analyses d'impact relatives à la protection des données (AIPD) ne sont pas requises (pas de collecte)

### 17.2 Allemagne

- Conformité au RGPD et au Bundesdatenschutzgesetz (BDSG)
- Autorité de contrôle compétente : le Landesbeauftragte für Datenschutz du Land concerné (le responsable du traitement réside en Allemagne)

### 17.3 Autriche

- Conformité au RGPD et au Datenschutzgesetz (DSG)
- Autorité de contrôle : Datenschutzbehörde (DSB)

### 17.4 Suisse

- Conformité à la loi fédérale révisée sur la protection des données (revDSG / LPD), en vigueur depuis le 1er septembre 2023
- Autorité de contrôle : Préposé fédéral à la protection des données et à la transparence (PFPDT / EDÖB)

### 17.5 Royaume-Uni

- Conformité au UK GDPR et au Data Protection Act 2018
- Autorité de contrôle : Information Commissioner's Office (ICO)

### 17.6 France

- Conformité au RGPD et à la Loi Informatique et Libertés
- Autorité de contrôle : Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Italie

- Conformité au RGPD et au Codice in materia di protezione dei dati personali
- Autorité de contrôle : Garante per la Protezione dei Dati Personali

### 17.8 Espagne

- Conformité au RGPD et à la Ley Orgánica 3/2018 (LOPDGDD)
- Autorité de contrôle : Agencia Española de Protección de Datos (AEPD)

### 17.9 Pays-Bas

- Conformité au RGPD et à l'Uitvoeringswet AVG (UAVG)
- Autorité de contrôle : Autoriteit Persoonsgegevens (AP)

### 17.10 Pologne

- Conformité au RGPD et à la Ustawa o ochronie danych osobowych
- Autorité de contrôle : Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portugal

- Conformité au RGPD et à la Lei n.º 58/2019
- Autorité de contrôle : Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 Belgique

- Conformité au RGPD et à la loi du 30 juillet 2018
- Autorité de contrôle : Autorité de protection des données (APD-GBA)

### 17.13 Irlande

- Conformité au RGPD et au Data Protection Act 2018
- Autorité de contrôle : Data Protection Commission (DPC)

### 17.14 Pays nordiques (Danemark, Finlande, Norvège, Suède, Islande)

- Conformité au RGPD (et équivalents EEE pour la Norvège et l'Islande)
- Autorités nationales de contrôle : Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Autres États membres UE/EEE

Conformité au RGPD et à la mise en œuvre nationale correspondante. Liste des autorités de contrôle : https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 États-Unis

- Conformité aux lois étatiques applicables en matière de vie privée : CCPA/CPRA (Californie), VCDPA (Virginie), CPA (Colorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Texas), OCPA (Oregon), IDPA (Iowa), MCDPA (Montana), FDBR (Floride), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (New Jersey)
- Les signaux « Do Not Track » et « Global Privacy Control » sont respectés lorsque cela est techniquement réalisable (l'Application ne procède à aucun traçage)
- Conformité COPPA pour les utilisateurs de moins de 13 ans

### 17.17 Canada

- Conformité à la LPRPDE et aux lois provinciales applicables : Loi 25 du Québec, PIPA de Colombie-Britannique, PIPA de l'Alberta
- Réclamations : Commissariat à la protection de la vie privée du Canada (CPVP) et autorités provinciales

### 17.18 Mexique

- Conformité à la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Autorité de contrôle : Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brésil

- Conformité à la LGPD
- Autorité de contrôle : Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentine, Chili, Colombie, Pérou, Uruguay

- Conformité aux lois nationales sur la protection des données (Loi 25.326 / Loi 19.628 / Loi 1581 / Loi 29733 / Loi 18.331)

### 17.21 Australie

- Conformité au Privacy Act 1988 et aux Australian Privacy Principles (APPs)
- Autorité de contrôle : Office of the Australian Information Commissioner (OAIC)

### 17.22 Nouvelle-Zélande

- Conformité au Privacy Act 2020
- Autorité de contrôle : Office of the Privacy Commissioner

### 17.23 Japon

- Conformité à l'Act on the Protection of Personal Information (APPI)
- Autorité de contrôle : Personal Information Protection Commission (PPC)

### 17.24 Corée du Sud

- Conformité au Personal Information Protection Act (PIPA)
- Autorité de contrôle : Personal Information Protection Commission (PIPC)

### 17.25 Singapour

- Conformité au Personal Data Protection Act (PDPA)
- Autorité de contrôle : Personal Data Protection Commission (PDPC)

### 17.26 Thaïlande

- Conformité au Personal Data Protection Act B.E. 2562 (2019)
- Autorité de contrôle : Personal Data Protection Committee

### 17.27 Chine

- Conformité à la Personal Information Protection Law (PIPL), à la Cybersecurity Law (CSL) et à la Data Security Law (DSL)

### 17.28 Hong Kong

- Conformité à la Personal Data (Privacy) Ordinance (PDPO)
- Autorité de contrôle : Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 Inde

- Conformité au Digital Personal Data Protection Act 2023 (DPDP Act) et à l'Information Technology Act 2000
- Autorité de contrôle : Data Protection Board of India

### 17.30 Émirats arabes unis

- Conformité au Federal Decree-Law No. 45 of 2021 (Personal Data Protection Law)

### 17.31 Arabie saoudite

- Conformité à la Personal Data Protection Law (PDPL)

### 17.32 Turquie

- Conformité à la loi nº 6698 sur la protection des données personnelles (KVKK)
- Autorité de contrôle : Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Israël

- Conformité à la Privacy Protection Law, 5741-1981 et aux Privacy Protection Regulations
- Autorité de contrôle : Privacy Protection Authority (PPA)

### 17.34 Afrique du Sud

- Conformité au Protection of Personal Information Act (POPIA)
- Autorité de contrôle : Information Regulator

### 17.35 Kenya, Nigéria, Égypte, Maroc

- Conformité aux lois nationales de protection des données (Data Protection Act 2019 du Kenya, NDPR / NDPA du Nigéria, loi nº 151 de 2020 d'Égypte, loi 09-08 du Maroc)

### 17.36 Autres juridictions

Pour les utilisateurs de juridictions non expressément mentionnées ci-dessus, l'approche de collecte nulle de l'Application garantit le respect des principes de minimisation des données et de limitation des finalités communs aux cadres modernes de protection de la vie privée. Si votre droit local prévoit des droits supplémentaires, ces droits sont respectés.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. Tous droits réservés.
