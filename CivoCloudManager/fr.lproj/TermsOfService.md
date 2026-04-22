# Conditions d'utilisation

## Civo Cloud Manager

**Date d'entrée en vigueur :** Avril 2026
**Dernière mise à jour :** Avril 2026

**Fournisseur :**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Allemagne
Courriel : moin@berger-rosenstock.de
Numéro de TVA : DE455096022

---

## 1. Champ d'application et acceptation

### 1.1 Accord

Les présentes conditions d'utilisation (« Conditions ») régissent votre accès à l'application Civo Cloud Manager (« l'Application ») et son utilisation, fournie par Berger & Rosenstock GbR (« le Fournisseur », « nous », « notre »).

### 1.2 Acceptation

En installant, en accédant ou en utilisant l'Application, vous acceptez d'être lié par les présentes Conditions. Si vous n'acceptez pas, vous ne devez pas installer ni utiliser l'Application.

### 1.3 Éligibilité

L'Application est classée **4+** dans l'App Store Apple. Pour conclure un contrat contraignant, vous devez avoir atteint l'âge légal de contracter dans votre juridiction. Un compte Civo Cloud, nécessaire à une utilisation significative de l'Application, exige que le titulaire ait atteint l'âge légal de contracter.

### 1.4 Usage professionnel

Si vous utilisez l'Application pour le compte d'une organisation, vous déclarez avoir le pouvoir d'engager cette organisation au titre des présentes Conditions.

### 1.5 Contrat de licence utilisateur final d'Apple pour les applications sous licence

Les présentes Conditions complètent le contrat de licence utilisateur final d'Apple pour les applications sous licence (EULA Apple) conclu entre vous et Apple Inc. En cas de conflit entre les présentes Conditions et l'EULA Apple, l'EULA Apple prévaut pour les questions qu'il couvre.

---

## 2. Services

### 2.1 Description

L'Application est une application macOS native qui permet la gestion de l'infrastructure Civo Cloud (instances virtuelles, clusters Kubernetes, bases de données, pare-feu, réseaux, équilibreurs de charge, volumes, magasins d'objets, DNS, clés SSH) et l'accès direct à l'API Kubernetes via les identifiants API de l'utilisateur.

L'Application se connecte directement depuis votre appareil à :

- L'API REST de Civo Cloud (`api.civo.com`)
- Les serveurs API Kubernetes de vos clusters Civo (via mTLS)
- Les points de terminaison de stockage d'objets compatibles S3 de votre compte Civo
- Les services de détection d'IP publique (ipify.org, ifconfig.me, icanhazip.com)
- L'App Store Apple / StoreKit pour le traitement des achats

Le Fournisseur n'exploite aucun service dorsal, serveur intermédiaire ou proxy. Toutes les communications se font directement entre votre appareil et les exploitants tiers respectifs.

### 2.2 Fonctionnalités gratuites et payantes

La fonctionnalité de gestion de pare-feu dans la barre de menus est gratuite. « Full Access » — qui débloque le tableau de bord de gestion pour tous les types de ressources pris en charge — est un achat intégré unique traité exclusivement via l'App Store Apple (voir section 7).

### 2.3 Modifications

Le Fournisseur peut modifier, suspendre ou interrompre toute fonctionnalité de l'Application à tout moment. Les modifications substantielles affectant des fonctionnalités payantes seront communiquées au moins trente (30) jours à l'avance lorsque cela est possible en pratique.

### 2.4 Disponibilité

L'Application est fournie « telle que disponible ». Le Fournisseur ne garantit pas un accès ou une disponibilité ininterrompus, et la fonctionnalité de l'Application dépend de la disponibilité de services tiers (Civo Cloud, App Store Apple, fournisseurs de détection d'IP) qui échappent au contrôle du Fournisseur.

---

## 3. Comptes

L'Application ne nécessite pas de compte auprès du Fournisseur. Toute l'authentification est gérée via :

- Votre clé API Civo (stockée localement dans le trousseau macOS)
- Votre kubeconfig Kubernetes (récupéré depuis l'API Civo)
- Votre identifiant Apple (pour la vérification des achats intégrés, géré par Apple)

Vous êtes responsable :

- Du maintien de la confidentialité de votre clé API Civo et des autres identifiants
- De toutes les activités effectuées avec vos identifiants
- De toutes les modifications de ressources, coûts et implications de facturation résultant de votre utilisation de l'Application
- De la configuration des permissions de la clé API Civo selon le principe du moindre privilège

Le Fournisseur n'a pas la possibilité d'accéder à vos identifiants Civo, de les récupérer ni de les réinitialiser. La perte d'identifiants relève exclusivement de votre responsabilité.

---

## 4. Contenu utilisateur

L'Application n'héberge, ne stocke ni ne transmet de contenu généré par l'utilisateur vers un serveur exploité par le Fournisseur. Tout contenu, donnée ou configuration que vous créez en utilisant l'Application (par exemple noms d'instances, clés SSH, libellés de règles de pare-feu, fichiers de magasins d'objets) est stocké :

- Localement sur votre appareil, ou
- Dans votre propre compte Civo Cloud

Vous conservez l'intégralité des droits, titres et intérêts sur ce contenu. Le Fournisseur ne revendique aucune licence, propriété ou autre droit sur votre contenu.

---

## 5. Utilisation acceptable

Vous ne pouvez pas utiliser l'Application pour :

- Violer une loi, un règlement ou un droit de tiers applicable
- Accéder à des ressources Civo ou exploiter des ressources Civo auxquelles vous n'êtes pas autorisé à accéder
- Perturber ou interrompre le service Civo Cloud, des clusters Kubernetes dont vous n'êtes pas propriétaire, ou l'Application elle-même
- Tenter de rétro-concevoir, décompiler, désassembler ou dériver le code source de l'Application, sauf dans la mesure où une telle restriction est interdite par le droit applicable
- Contourner les mécanismes de sécurité ou de contrôle d'accès (y compris la barrière de paiement intégrée)
- Distribuer, sous-licencier, louer, vendre ou autrement exploiter commercialement l'Application
- Supprimer, modifier ou masquer des mentions de propriété, marques de copyright ou marques commerciales
- Utiliser l'Application pour attaquer, compromettre ou tester la sécurité de systèmes dont vous n'êtes pas propriétaire ou pour lesquels vous n'avez pas l'autorisation écrite explicite de tester
- Utiliser l'Application à toute fin interdite par les lois de la République fédérale d'Allemagne, de l'Union européenne ou de votre juridiction de résidence

---

## 6. Propriété intellectuelle

### 6.1 Propriété

L'Application (y compris le code source, la conception, les textes, graphiques, icônes, localisations et tous les droits de propriété intellectuelle associés) est la propriété exclusive du Fournisseur et est protégée par les lois allemandes, européennes et internationales sur le droit d'auteur, les marques et autres droits de propriété intellectuelle.

### 6.2 Octroi de licence

Sous réserve de votre respect des présentes Conditions et de l'EULA Apple, le Fournisseur vous accorde une licence limitée, non exclusive, non transférable, non sous-licenciable et révocable pour installer et utiliser l'Application sur les appareils Apple que vous possédez ou contrôlez, uniquement pour votre usage personnel ou professionnel interne de gestion de votre infrastructure Civo Cloud.

### 6.3 Marques tierces

« Civo » est une marque de Civo Ltd. « Apple », « App Store », « macOS », « iCloud », « StoreKit », « TestFlight » sont des marques d'Apple Inc. « Kubernetes » est une marque de The Linux Foundation. Toutes les autres marques sont la propriété de leurs détenteurs respectifs. Le Fournisseur n'est affilié, approuvé ou parrainé par aucune de ces parties.

### 6.4 Retour d'information

Tout retour d'information, suggestion ou idée que vous soumettez au Fournisseur concernant l'Application peut être utilisé par le Fournisseur sans restriction et sans contrepartie pour vous.

---

## 7. Paiements et abonnements

### 7.1 Achat intégré

« Full Access » est vendu comme un achat intégré non consommable via l'App Store Apple pour un prix unique. Le prix est affiché dans l'Application dans votre devise locale avant l'achat.

### 7.2 Traitement du paiement

Le paiement est traité exclusivement par Apple Inc. Le Fournisseur ne reçoit, ne stocke ni ne traite aucune information de paiement. Toutes les questions de paiement, de remboursement et de facturation sont régies par les conditions des services médias d'Apple et l'EULA Apple.

### 7.3 Partage familial

« Full Access » est activé pour le Partage familial Apple. Les membres de votre groupe de Partage familial Apple pourront utiliser l'achat sur leurs propres appareils, sous réserve des règles de Partage familial d'Apple.

### 7.4 Codes promotionnels Apple

Le Fournisseur peut émettre des codes promotionnels Apple à des fins promotionnelles. Les codes peuvent être échangés via la fonction « Utiliser un code » dans l'Application ou dans l'App Store.

### 7.5 Remboursements

Les remboursements sont gérés exclusivement par Apple conformément à la politique de remboursement d'Apple. Les droits légaux des consommateurs au titre du droit applicable (voir section 15) restent inchangés. En particulier, les consommateurs de l'UE sont informés que le droit légal de rétractation de 14 jours pour le contenu numérique expire lorsque l'exécution a commencé avec votre accord exprès préalable — Apple met cela en œuvre via la boîte de dialogue de confirmation au moment de l'achat.

### 7.6 Taxes

Le prix affiché inclut toutes les taxes applicables (TVA, taxe de vente) telles que déterminées par Apple en fonction de votre pays.

---

## 8. Services tiers

L'utilisation de l'Application nécessite une interaction avec des services tiers. Votre utilisation de ces services est régie par leurs conditions respectives :

- **Civo Cloud :** https://www.civo.com/terms
- **App Store Apple / Apple ID :** https://www.apple.com/legal/internet-services/terms/
- **Clusters Kubernetes :** les conditions de votre exploitant de cluster (Civo)

Le Fournisseur n'est partie à aucun accord entre vous et un fournisseur de services tiers et n'est pas responsable de la disponibilité, de l'exactitude ou du comportement de ces services.

---

## 9. Exclusion de garanties

L'APPLICATION EST FOURNIE « EN L'ÉTAT » ET « SELON DISPONIBILITÉ », SANS GARANTIE D'AUCUNE SORTE, EXPRESSE OU IMPLICITE, Y COMPRIS, MAIS SANS S'Y LIMITER, LES GARANTIES DE QUALITÉ MARCHANDE, D'ADÉQUATION À UN USAGE PARTICULIER, D'EXACTITUDE, D'EXHAUSTIVITÉ OU DE NON-CONTREFAÇON.

LE FOURNISSEUR NE GARANTIT PAS QUE :

- L'APPLICATION SERA ININTERROMPUE, EXEMPTE D'ERREURS OU SÉCURISÉE
- L'APPLICATION AFFICHERA, CRÉERA, MODIFIERA, SUPPRIMERA OU GÉRERA CORRECTEMENT LES RESSOURCES CIVO CLOUD
- LES DONNÉES AFFICHÉES PAR L'APPLICATION SONT EXACTES, COMPLÈTES OU À JOUR
- L'APPLICATION EST COMPATIBLE AVEC TOUTES LES VERSIONS, FONCTIONNALITÉS OU RÉGIONS DE L'API CIVO

**Opérations destructives.** L'Application peut effectuer des opérations irréversibles sur votre compte Civo Cloud, y compris la suppression de clusters Kubernetes, de bases de données, de volumes, de magasins d'objets, d'instances, de clés SSH et de règles de pare-feu. Toutes les opérations destructives nécessitent une confirmation explicite de l'utilisateur (généralement en saisissant le nom de la ressource). LE FOURNISSEUR N'ASSUME AUCUNE RESPONSABILITÉ pour les suppressions involontaires, pertes de données, dépassements de coûts ou dommages à l'infrastructure causés par votre utilisation de l'Application.

Il est vivement recommandé de conserver des sauvegardes indépendantes de toutes les données critiques, d'utiliser une clé API dédiée avec les permissions Civo minimales requises et d'examiner attentivement toutes les boîtes de dialogue de confirmation.

Aucune disposition de la présente section n'exclut ni ne limite une garantie qui ne peut être exclue ou limitée en vertu du droit applicable (voir section 15).

---

## 10. Limitation de responsabilité

DANS TOUTE LA MESURE PERMISE PAR LE DROIT APPLICABLE :

### 10.1 Exclusions

LE FOURNISSEUR N'EST PAS RESPONSABLE DES DOMMAGES INDIRECTS, ACCESSOIRES, SPÉCIAUX, CONSÉCUTIFS, PUNITIFS OU EXEMPLAIRES, Y COMPRIS, MAIS SANS S'Y LIMITER :

- Perte de données, de revenus, de bénéfices ou d'opportunités commerciales
- Coûts d'obtention de services de substitution
- Dommages ou suppression de l'infrastructure cloud, de ressources ou de données
- Accès non autorisé résultant de clés API compromises

### 10.2 Plafond

LA RESPONSABILITÉ TOTALE CUMULÉE DU FOURNISSEUR À VOTRE ÉGARD POUR TOUTES LES RÉCLAMATIONS DÉCOULANT DE L'APPLICATION OU Y ÉTANT LIÉES N'EXCÉDERA PAS LE MONTANT QUE VOUS AVEZ EFFECTIVEMENT PAYÉ POUR L'APPLICATION AU COURS DES DOUZE (12) MOIS PRÉCÉDANT L'ÉVÉNEMENT DONNANT LIEU À LA RÉCLAMATION.

### 10.3 Exceptions

Aucune disposition des présentes Conditions n'exclut ni ne limite la responsabilité pour :

- Décès ou dommages corporels causés par une négligence
- Dol ou fausses déclarations frauduleuses
- Faute intentionnelle ou négligence grave (en droit allemand, §§ 276, 309 BGB)
- Violation d'obligations contractuelles essentielles (Kardinalpflichten), limitée aux dommages prévisibles typiques pour ce type de contrat
- Toute autre responsabilité qui ne peut être exclue ou limitée en vertu du droit applicable

### 10.4 Responsabilité du fait des produits

La responsabilité au titre de la loi allemande sur la responsabilité du fait des produits (Produkthaftungsgesetz) demeure inchangée.

---

## 11. Indemnisation

Vous acceptez d'indemniser, de défendre et d'exonérer le Fournisseur, ses associés, employés et agents de toute réclamation, responsabilité, dommage, perte, coût, dépense ou honoraire (y compris les honoraires raisonnables d'avocat) découlant de ou liés à :

- Votre violation des présentes Conditions
- Votre violation d'une loi ou d'un droit de tiers
- Votre utilisation de l'Application pour accéder à ou gérer une infrastructure à laquelle vous n'êtes pas autorisé à accéder
- Tout contenu ou configuration que vous créez, modifiez ou supprimez via l'Application

Cette obligation d'indemnisation ne s'applique pas aux consommateurs au sens de la législation applicable en matière de protection des consommateurs lorsque le droit impératif interdit une telle indemnisation.

---

## 12. Résiliation

### 12.1 Résiliation par vous

Vous pouvez résilier les présentes Conditions à tout moment en désinstallant l'Application de vos appareils.

### 12.2 Résiliation par le Fournisseur

Le Fournisseur peut résilier ou suspendre immédiatement votre licence d'utilisation de l'Application en cas de manquement substantiel aux présentes Conditions. En cas de résiliation :

- Votre droit d'utiliser l'Application cesse immédiatement
- Vous devez désinstaller l'Application de vos appareils
- Les sections 6, 9, 10, 11, 13, 14, 16 survivent à la résiliation

### 12.3 Effet sur l'achat

La résiliation ne vous donne pas droit à un remboursement de votre achat intégré, sauf si cela est requis par le droit applicable de protection des consommateurs ou par la politique de remboursement d'Apple.

---

## 13. Droit applicable et règlement des litiges

### 13.1 Droit applicable

Les présentes Conditions sont régies par le droit de la République fédérale d'Allemagne, à l'exclusion de ses règles de conflit de lois et de la Convention des Nations unies sur les contrats de vente internationale de marchandises (CVIM).

Pour les consommateurs de l'Union européenne / EEE, ce choix de droit ne vous prive pas de la protection impérative des consommateurs prévue par les lois de votre pays de résidence habituelle.

### 13.2 Juridiction

Pour les commerçants, personnes morales de droit public et fonds spéciaux de droit public (Kaufleute, juristische Personen des öffentlichen Rechts, öffentlich-rechtliche Sondervermögen), le lieu de juridiction exclusif pour tous les litiges découlant des présentes Conditions est Bad Nauheim, Allemagne.

Pour les consommateurs, le lieu de juridiction légal s'applique. Vous pouvez engager une procédure devant les tribunaux de votre pays de résidence habituelle.

### 13.3 Règlement en ligne des litiges de l'UE

La Commission européenne met à disposition une plateforme de règlement en ligne des litiges à l'adresse suivante : https://ec.europa.eu/consumers/odr.

### 13.4 Arbitrage consommateur

Le Fournisseur n'est ni tenu ni disposé à participer à des procédures de règlement des litiges devant un organisme d'arbitrage consommateur (Verbraucherschlichtungsstelle) au sens de la loi allemande sur le règlement des litiges de consommation (VSBG), sauf obligation légale.

---

## 14. Dispositions régionales

### 14.1 Allemagne

- Les droits des consommateurs au titre des §§ 312 et suivants, 327 et suivants BGB (produits numériques) demeurent inchangés
- Les droits légaux de rétractation selon le § 355 BGB s'appliquent le cas échéant

### 14.2 Union européenne / EEE

- La directive 2011/83/UE relative aux droits des consommateurs et la directive (UE) 2019/770 sur le contenu numérique s'appliquent lorsque vous êtes consommateur
- Les mentions applicables en vertu de l'article 12 du règlement sur les services numériques (règlement (UE) 2022/2065) figurent dans les mentions légales

### 14.3 Royaume-Uni

- Le Consumer Rights Act 2015 s'applique lorsque vous êtes consommateur résidant au Royaume-Uni
- Le contenu numérique doit être de qualité satisfaisante, adapté à sa destination et conforme à la description

### 14.4 Suisse

- Les dispositions impératives de protection des consommateurs du Code des obligations suisse (CO) demeurent inchangées
- La loi fédérale contre la concurrence déloyale (LCD) s'applique

### 14.5 États-Unis

- Les présentes Conditions ne visent pas à créer des droits au titre de lois étatiques de protection des consommateurs qui ne s'appliquent pas selon leurs propres termes
- Résidents de Californie : avis de droits des consommateurs au titre du Civil Code § 1789.3 — contactez moin@berger-rosenstock.de

### 14.6 Canada

- La Loi sur la protection du consommateur du Québec s'applique aux résidents du Québec lorsqu'elle est impérative
- Langue du contrat : les présentes Conditions sont fournies en anglais ; des versions françaises sont disponibles lorsque la Charte de la langue française (Québec) l'exige

### 14.7 Australie

- Les garanties du droit australien de la consommation (Competition and Consumer Act 2010, Schedule 2) s'appliquent lorsque vous êtes consommateur — ces garanties ne peuvent être exclues

### 14.8 Nouvelle-Zélande

- Le Consumer Guarantees Act 1993 s'applique lorsque vous êtes consommateur pour un usage personnel, domestique ou ménager

### 14.9 Japon

- La loi sur les contrats de consommation (消費者契約法) s'applique ; les dispositions des présentes Conditions qui seraient invalides en vertu de cette loi sont limitées dans la mesure nécessaire

### 14.10 Corée du Sud

- L'Act on the Regulation of Terms and Conditions (약관의 규제에 관한 법률) s'applique

### 14.11 Brésil

- Le Code de défense du consommateur (CDC, loi nº 8.078/1990) s'applique ; les droits des consommateurs ne peuvent être renoncés

### 14.12 Inde

- Le Consumer Protection Act 2019 et les E-Commerce Rules 2020 s'appliquent lorsque vous êtes consommateur

### 14.13 Autres juridictions

Pour les utilisateurs de juridictions non expressément mentionnées ci-dessus, les présentes Conditions s'appliquent dans la mesure permise par le droit impératif local de protection des consommateurs.

---

## 15. Droits des consommateurs (informations obligatoires)

Les présentes Conditions n'affectent pas vos droits légaux de consommateur au titre du droit applicable, y compris, mais sans s'y limiter :

- Directive 2011/83/UE relative aux droits des consommateurs et directive (UE) 2019/770 sur le contenu numérique
- UK Consumer Rights Act 2015
- Droit australien de la consommation
- Dispositions allemandes de protection des consommateurs du BGB (§§ 312 et suivants, §§ 327 et suivants)
- New Zealand Consumer Guarantees Act 1993
- Code de défense du consommateur brésilien (CDC)
- Lois provinciales canadiennes de protection des consommateurs
- Toute autre législation applicable de protection des consommateurs dans votre juridiction

---

## 16. Dispositions générales

### 16.1 Modifications des présentes Conditions

Nous pouvons mettre à jour les présentes Conditions de temps à autre. Les modifications substantielles seront communiquées via l'Application ou la fiche App Store au moins trente (30) jours avant leur entrée en vigueur. La poursuite de votre utilisation après l'entrée en vigueur des modifications vaut acceptation.

### 16.2 Cession

Vous ne pouvez ni céder ni transférer les présentes Conditions ou les droits qui en découlent sans le consentement écrit préalable du Fournisseur. Le Fournisseur peut céder les présentes Conditions dans le cadre d'une fusion, acquisition ou vente d'actifs.

### 16.3 Divisibilité

Si une disposition des présentes Conditions est jugée inexécutable ou invalide, cette disposition sera limitée ou supprimée dans la mesure minimale nécessaire afin que les présentes Conditions demeurent en vigueur pour le reste. Pour le droit allemand, le § 306 BGB s'applique.

### 16.4 Renonciation

Le fait pour le Fournisseur de ne pas faire valoir une disposition des présentes Conditions ne constitue pas une renonciation à cette disposition.

### 16.5 Intégralité de l'accord

Les présentes Conditions, conjointement avec la politique de confidentialité, les mentions légales et l'EULA Apple, constituent l'intégralité de l'accord entre vous et le Fournisseur concernant l'Application et remplacent tous les accords et ententes antérieurs.

### 16.6 Langue

La version faisant foi des présentes Conditions est la version anglaise. Les traductions sont fournies à titre indicatif. En cas de divergence, la version anglaise prévaut, sauf lorsque le droit local impératif l'exige autrement.

### 16.7 Communications électroniques

Vous consentez à recevoir les notifications légalement requises du Fournisseur sous forme électronique (via l'Application ou par courriel).

### 16.8 Force majeure

Le Fournisseur n'est pas responsable de tout manquement ou retard d'exécution causé par des événements échappant à son contrôle raisonnable, y compris les catastrophes naturelles, la guerre, le terrorisme, les troubles civils, les conflits du travail, les défaillances d'Internet, les interruptions de services tiers ou une action gouvernementale.

---

## 17. Contact

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Allemagne
Courriel : moin@berger-rosenstock.de
Numéro de TVA : DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. Tous droits réservés.
