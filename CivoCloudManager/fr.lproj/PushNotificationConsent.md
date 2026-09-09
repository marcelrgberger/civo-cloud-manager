<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: fr | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# AVIS DE CONSENTEMENT AUX NOTIFICATIONS PUSH

## Informations affichées en même temps que la demande d'autorisation système pour les notifications push

**Date d'entrée en vigueur :** septembre 2026

**Fournisseur :**
DigitalFreedom
Une marque de DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
États-Unis
Contact : hello@digitalfreedom.co.za
Protection des données : data-protection@digitalfreedom.co.za
Site web : https://digitalfreedom.co.za

---

## 0. OBJET

Le présent avis est affiché **avant** la demande d'autorisation système iOS / Android pour les notifications push. Il informe l'utilisateur — en langage clair — de ce à quoi il consent. Il satisfait aux exigences suivantes :

- **Art. 6(1)(a) RGPD** — consentement libre, spécifique, éclairé et sans ambiguïté pour le traitement lié aux notifications lorsque la notification contient des données à caractère personnel
- **Art. 13 RGPD** — transparence au moment de la collecte
- **Directive ePrivacy 2002/58/CE art. 13 / transpositions nationales** — pour toute notification à contenu marketing
- **Apple Human Interface Guidelines** et **Google Play Developer Policy** — bonnes pratiques de pré-demande

Les Services sont distribués mondialement via l'Apple App Store et le Google Play Store ; le présent avis s'applique partout où les notifications push sont activées et est délivré dans la langue de l'utilisateur lorsque celle-ci est prise en charge.

---

## 1. CE QUE VOUS AUTORISEZ

Si vous appuyez sur **« Autoriser »** à la prochaine demande, `Civo Cloud Manager` pourra :

- envoyer des notifications à votre appareil
- afficher des alertes, pastilles, bannières et sons (sous réserve de vos paramètres au niveau du système d'exploitation)
- utiliser APNs d'Apple / FCM de Google comme canal de distribution (le jeton push de votre appareil est partagé avec ces fournisseurs uniquement pour la livraison)

---

## 2. OBJET DES NOTIFICATIONS

`Civo Cloud Manager` envoie des notifications pour les finalités suivantes :

| Catégorie | Exemples | Par défaut |
|---|---|---|
| **Notifications de service** (essentielles) | alertes de compte, avertissements de sécurité, rappels de paiement, mises à jour importantes | Activé |
| **Transactionnelles** | confirmation d'une action effectuée, changements de statut demandés | Activé |
| **Rappels** | rappels que vous avez configurés vous-même dans `Civo Cloud Manager` | À votre choix |
| **Astuces & nouvelles fonctionnalités** | mises à jour occasionnelles sur de nouvelles fonctionnalités | Désactivé par défaut — sur inscription |
| **Marketing / promotionnelles** | offres, campagnes, nouveautés produits | Désactivé par défaut — sur inscription ; consentement distinct selon § 4 |

Chaque catégorie peut être activée ou désactivée indépendamment dans **Paramètres → Notifications** à l'intérieur de `Civo Cloud Manager` — et à tout moment dans les paramètres de notification au niveau du système d'exploitation de votre appareil.

---

## 3. ABSENCE DE TRAÇAGE PAR LA NOTIFICATION

Nous ne :

- utilisons pas les notifications pour suivre votre localisation
- incluons pas d'informations personnellement identifiables (PII) concernant d'autres utilisateurs dans vos notifications
- utilisons pas de notifications silencieuses / en arrière-plan pour collecter des analyses vous concernant
- partageons pas votre jeton push d'appareil avec des tiers autres qu'Apple / Google pour la livraison

---

## 4. NOTIFICATIONS MARKETING

Les notifications push marketing / promotionnelles sont régies par l'art. 6(1)(a) RGPD + ePrivacy art. 13 : **un consentement explicite, distinct et granulaire est requis**.

- Le bouton marketing est **désactivé** par défaut
- Vous pouvez l'activer (et le désactiver) à tout moment dans **Paramètres → Notifications → Marketing**
- Le consentement aux notifications push marketing est **distinct** du consentement au marketing par e-mail ; activer l'un n'active pas l'autre
- Le retrait est aussi simple que l'inscription (un seul bouton), et n'affecte pas les notifications non-marketing

---

## 5. ENFANTS

Si `Civo Cloud Manager` est utilisé par des mineurs, la [Notice de confidentialité pour les enfants](CHILDREN_PRIVACY_NOTICE.md) s'applique en complément. Nous n'envoyons pas de notifications push marketing aux mineurs.

---

## 6. SOUS-TRAITANTS IMPLIQUÉS

La distribution des notifications push utilise les services natifs des plateformes :

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (responsable de traitement indépendant pour le canal de livraison)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (responsable de traitement indépendant pour le canal de livraison)

Ces entités agissent en tant que responsables de traitement pour la couche de livraison selon leurs propres politiques de confidentialité. Voir [`processors/apple.md`](processors/apple.md) et [registre des sous-traitants Google Cloud](processors/google-cloud.md).

---

## 7. VOS DROITS

Vous pouvez à tout moment :

- **Désactiver** toutes les notifications au niveau du système d'exploitation (Paramètres → Notifications → `Civo Cloud Manager` → désactivé)
- **Désactiver des catégories spécifiques** dans l'application (Paramètres → Notifications)
- **Retirer votre consentement marketing** sans perdre les notifications de service
- **Demander la suppression** de toute donnée que nous détenons relative à vos préférences de notification via `data-protection@digitalfreedom.co.za`

Le retrait du consentement n'affecte pas la licéité du traitement effectué avant ce retrait.

---

## 8. SI VOUS DITES « NE PAS AUTORISER »

Si vous refusez la demande système :

- `Civo Cloud Manager` continue de fonctionner — aucune fonctionnalité n'est conditionnée à l'autorisation des notifications
- vous pouvez changer d'avis ultérieurement dans **Paramètres → Notifications → `Civo Cloud Manager`** (au niveau du système d'exploitation)
- nous ne vous relancerons pas de manière répétée et n'utiliserons pas de pratiques trompeuses pour obtenir votre consentement

---

## 9. CONTACT

DigitalFreedom
Une marque de DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
États-Unis

Aide sur les préférences de notification : support@digitalfreedom.co.za
Protection des données : data-protection@digitalfreedom.co.za
Général : hello@digitalfreedom.co.za
Site web : https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. Tous droits réservés.
