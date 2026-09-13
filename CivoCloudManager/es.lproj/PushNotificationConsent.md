<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: es | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# AVISO DE CONSENTIMIENTO PARA NOTIFICACIONES PUSH

## Información mostrada junto con el aviso de permiso del sistema para notificaciones push

**Fecha de entrada en vigor:** septiembre de 2026

**Proveedor:**
DigitalFreedom
Una marca de DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Estados Unidos
Contacto: hello@digitalfreedom.co.za
Protección de datos: data-protection@digitalfreedom.co.za
Sitio web: https://digitalfreedom.co.za

---

## 0. FINALIDAD

Este Aviso se muestra **antes** del aviso de permiso del sistema iOS / Android para notificaciones push. Informa al usuario — en lenguaje claro — a qué está consintiendo. Cumple con:

- **Art. 6(1)(a) RGPD** — consentimiento libre, específico, informado e inequívoco para el tratamiento relacionado con notificaciones cuando la notificación contiene datos personales
- **Art. 13 RGPD** — transparencia en el momento de la recogida
- **Directiva ePrivacy 2002/58/CE Art. 13 / implementaciones nacionales** — para cualquier notificación con contenido de marketing
- **Apple Human Interface Guidelines** y **Google Play Developer Policy** — mejores prácticas de preaviso

Los Servicios se distribuyen globalmente a través de la App Store de Apple y Google Play Store; este Aviso se aplica dondequiera que las notificaciones push estén habilitadas y se entrega en el idioma del usuario cuando sea compatible.

---

## 1. LO QUE USTED AUTORIZA

Si pulsa **"Permitir"** en el siguiente aviso, `Civo Cloud Manager` podrá:

- enviar notificaciones a su dispositivo
- mostrar alertas, distintivos, banners y sonidos (sujeto a la configuración de su sistema operativo)
- utilizar APNs de Apple / FCM de Google como canal de entrega (el token push de su dispositivo se comparte con estos proveedores solo para la entrega)

---

## 2. SOBRE QUÉ TRATARÁN LAS NOTIFICACIONES

`Civo Cloud Manager` envía notificaciones para los siguientes fines:

| Categoría | Ejemplos | Predeterminado |
|---|---|---|
| **Notificaciones de servicio** (esenciales) | alertas de cuenta, advertencias de seguridad, recordatorios de pago, actualizaciones importantes | Activado |
| **Transaccionales** | confirmación de una acción realizada por usted, cambios de estado solicitados | Activado |
| **Recordatorios** | recordatorios que usted mismo configure en `Civo Cloud Manager` | A su elección |
| **Consejos y nuevas funciones** | actualizaciones ocasionales sobre nuevas funcionalidades | Desactivado por defecto — requiere suscripción |
| **Marketing / promocionales** | ofertas, campañas, novedades de productos | Desactivado por defecto — requiere suscripción; consentimiento separado según § 4 |

Cada categoría puede activarse o desactivarse de forma independiente en **Configuración → Notificaciones** dentro de `Civo Cloud Manager` — y en cualquier momento en la configuración de notificaciones a nivel de sistema operativo de su dispositivo.

---

## 3. NO HAY SEGUIMIENTO POR MEDIO DE LA NOTIFICACIÓN

Nosotros **no**:

- utilizamos notificaciones para rastrear su ubicación
- incluimos información personal identificable (PII) sobre otros usuarios en sus notificaciones
- usamos notificaciones silenciosas / en segundo plano para recopilar análisis sobre usted
- compartimos el token push de su dispositivo con terceros distintos de Apple / Google para la entrega

---

## 4. NOTIFICACIONES DE MARKETING

Las notificaciones push de marketing / promocionales se rigen por el Art. 6(1)(a) RGPD + ePrivacy Art. 13: **se requiere un consentimiento explícito, separado y granular**.

- El interruptor de marketing está **desactivado** por defecto
- Puede activarlo (y desactivarlo) en cualquier momento en **Configuración → Notificaciones → Marketing**
- El consentimiento para notificaciones push de marketing es **distinto** del consentimiento para marketing por correo electrónico; habilitar uno no habilita el otro
- La retirada es tan sencilla como el alta (un solo interruptor), y no afecta a las notificaciones no comerciales

---

## 5. MENORES

Si `Civo Cloud Manager` es utilizado por menores de edad, se aplica además el [Aviso de Privacidad para Niños](CHILDREN_PRIVACY_NOTICE.md). No enviamos notificaciones push de marketing a menores.

---

## 6. SUBENCARGADOS INVOLUCRADOS

La entrega de notificaciones push utiliza servicios nativos de la plataforma:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (responsable independiente para el canal de entrega)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (responsable independiente para el canal de entrega)

Estos actúan como responsables independientes para la capa de entrega según sus propias políticas de privacidad. Véase [`processors/apple.md`](processors/apple.md) y [registro de subencargados de Google Cloud](processors/google-cloud.md).

---

## 7. SUS DERECHOS

Usted puede en cualquier momento:

- **Desactivar** todas las notificaciones a nivel de sistema operativo (Configuración → Notificaciones → `Civo Cloud Manager` → desactivado)
- **Desactivar categorías específicas** en la aplicación (Configuración → Notificaciones)
- **Retirar el consentimiento de marketing** sin perder las notificaciones de servicio
- **Solicitar la eliminación** de cualquier dato que tengamos relacionado con sus preferencias de notificación a través de `data-protection@digitalfreedom.co.za`

La retirada del consentimiento no afecta a la licitud del tratamiento realizado antes de la retirada.

---

## 8. SI USTED DICE "NO PERMITIR"

Si rechaza el aviso del sistema:

- `Civo Cloud Manager` seguirá funcionando — ninguna función está restringida por el permiso de notificaciones
- puede cambiar de opinión más adelante en **Configuración → Notificaciones → `Civo Cloud Manager`** (a nivel de sistema operativo)
- no volveremos a solicitar el permiso repetidamente ni utilizaremos patrones oscuros para forzar el consentimiento

---

## 9. CONTACTO

DigitalFreedom
Una marca de DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Estados Unidos

Ayuda con preferencias de notificación: support@digitalfreedom.co.za
Protección de datos: data-protection@digitalfreedom.co.za
General: hello@digitalfreedom.co.za
Sitio web: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. Todos los derechos reservados.
