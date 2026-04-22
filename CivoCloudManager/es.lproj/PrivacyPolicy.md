# Política de Privacidad

## Civo Cloud Manager

**Fecha de entrada en vigor:** Abril de 2026
**Última actualización:** Abril de 2026

**Responsable del tratamiento:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Alemania
Correo electrónico: moin@berger-rosenstock.de

---

## 1. Introducción

La presente Política de Privacidad explica cómo Marcel R. G. Berger, actuando como Berger & Rosenstock GbR («nosotros», «nos», «nuestro»), trata la información en relación con la aplicación Civo Cloud Manager («la Aplicación»).

Nos comprometemos a proteger su privacidad y a cumplir con las leyes de protección de datos aplicables, incluidas, entre otras:

- Reglamento General de Protección de Datos de la UE (RGPD, Reglamento (UE) 2016/679)
- Ley Federal Alemana de Protección de Datos (BDSG)
- Reglamento General de Protección de Datos del Reino Unido (UK GDPR) y Ley de Protección de Datos de 2018
- Ley Federal Suiza de Protección de Datos (FADP / revDSG)
- Ley de Privacidad del Consumidor de California (CCPA) y Ley de Derechos de Privacidad de California (CPRA)
- Ley de Protección de Datos del Consumidor de Virginia (VCDPA), Ley de Privacidad de Colorado (CPA), Ley de Privacidad de Datos de Connecticut (CTDPA), Ley de Privacidad del Consumidor de Utah (UCPA) y otras leyes estatales de EE. UU.
- Ley Canadiense de Protección de la Información Personal y los Documentos Electrónicos (PIPEDA) y leyes provinciales
- Ley Australiana de Privacidad de 1988 y Principios de Privacidad Australianos (APPs)
- Ley General de Protección de Datos de Brasil (LGPD, Ley n.º 13.709/2018)
- Ley Japonesa sobre la Protección de la Información Personal (APPI)
- Ley de Protección de la Información Personal de Corea del Sur (PIPA)
- Ley de Protección de Datos Personales de Singapur (PDPA)
- Ley de Protección de Datos Personales de Tailandia (PDPA 2019)
- Ley China de Protección de la Información Personal (PIPL)
- Ley India de Protección de Datos Personales Digitales de 2023 (DPDP Act)
- Ley Sudafricana de Protección de la Información Personal (POPIA)
- Ley de Protección de Datos Personales de los Emiratos Árabes Unidos (PDPL)
- Ley de Privacidad de Nueva Zelanda de 2020
- Ley de Protección de la Privacidad Infantil en Línea (COPPA, EE. UU.)

---

## 2. Principio de recopilación cero de datos

**No recopilamos, almacenamos, transmitimos ni tratamos datos personales en nuestros servidores.**

La Aplicación funciona íntegramente en su dispositivo. Toda la configuración, las credenciales y las preferencias se almacenan localmente. No disponemos de servidores que reciban sus datos. No operamos ninguna infraestructura backend para la recopilación de datos, la analítica, los informes de fallos ni la telemetría.

Dado que no tratamos datos personales bajo nuestro control, la mayoría de las obligaciones previstas en las leyes de protección de datos (deberes del responsable del tratamiento, obligaciones relativas a las transferencias internacionales, notificación de brechas, etc.) no nos son aplicables como editor de esta Aplicación. No obstante, la Sección 10 describe los derechos que le asisten conforme a la legislación aplicable.

---

## 3. Datos almacenados en su dispositivo

La Aplicación almacena los siguientes datos de forma local en su dispositivo macOS. Ninguno de estos datos se transmite a nuestros servidores.

### 3.1 Credenciales

- **Clave de API de Civo** — almacenada en el Keychain de macOS (cifrado con respaldo de hardware) — utilizada para autenticarse con la API de Civo Cloud
- **Credenciales de Kubeconfig** — almacenadas únicamente en memoria durante las sesiones activas, nunca persistidas en disco
- **Credenciales de Object Store (Access Key ID / Secret)** — obtenidas de la API de Civo bajo demanda, almacenadas únicamente en memoria

### 3.2 Preferencias

- **Región seleccionada** (UserDefaults) — código de la región Civo activa
- **Firewalls gestionados** (UserDefaults, JSON) — configuraciones de firewall gestionadas por la Aplicación
- **Inicio automático al iniciar sesión** (UserDefaults) — preferencia de arranque automático
- **Estado de incorporación** (UserDefaults) — indicador de finalización de la configuración inicial
- **Presets de IP** (UserDefaults, JSON) — direcciones IP nombradas por el usuario para reglas de firewall

### 3.3 Datos transitorios en tiempo de ejecución

- **IP pública detectada** — conservada en memoria durante una sesión, nunca persistida
- **Respuestas de la API** — conservadas en memoria mientras se muestran, nunca persistidas más allá de la sesión

### 3.4 Estado de compra

Gestionado íntegramente por Apple StoreKit. No recibimos, almacenamos ni tratamos ninguna información de pago.

---

## 4. Base jurídica del tratamiento (RGPD)

Dado que no actuamos como responsable ni como encargado del tratamiento de datos personales recopilados a través de la Aplicación, las bases del artículo 6 del RGPD para el tratamiento no nos son aplicables. En la medida en que el funcionamiento de la Aplicación implique un tratamiento local en su dispositivo, se realiza sobre la base de:

- **Ejecución de un contrato** (art. 6.1.b RGPD) — proporcionar la funcionalidad para la que instaló la Aplicación
- **Consentimiento** (art. 6.1.a RGPD) — cuando usted activa expresamente acciones como la detección de IP, la creación de reglas de firewall o la autenticación mediante Touch ID

No se realiza ningún tratamiento en virtud del art. 6.1.a, c, d, e o f del RGPD en infraestructura operada por nosotros.

---

## 5. Cómo se utilizan los datos

Los datos de su dispositivo se utilizan exclusivamente para:

- Autenticarse frente a la API de Civo Cloud, los servidores de la API de Kubernetes y los endpoints de almacenamiento de objetos compatibles con S3 a los que usted dirija la Aplicación
- Gestionar sus recursos de Civo Cloud (instancias, clústeres, bases de datos, firewalls, etc.)
- Detectar su dirección IPv4 pública para abrir y cerrar reglas de firewall
- Mostrar el estado de los recursos, las estimaciones de costes y los registros de actividad localmente
- Tramitar su compra única dentro de la aplicación a través de Apple StoreKit

Nosotros nunca compartimos, vendemos, alquilamos ni divulgamos de otro modo los datos a terceros.

---

## 6. Servicios de terceros

La Aplicación se comunica directamente con los siguientes servicios de terceros bajo su indicación expresa. No somos parte en estas comunicaciones.

### 6.1 API de Civo Cloud (api.civo.com)

- **Finalidad:** Gestionar su infraestructura de Civo Cloud
- **Datos enviados:** Su clave de API de Civo (como cabecera de autenticación), solicitudes de gestión de recursos
- **Operador:** Civo Ltd, Reino Unido
- **Política de privacidad:** https://www.civo.com/privacy

### 6.2 Servidores de la API de Kubernetes

- **Finalidad:** Acceder a nodos, pods, registros, despliegues y métricas del clúster
- **Datos enviados:** Credenciales de certificado de cliente de su kubeconfig (PKCS#12 mTLS)
- **Operador:** El operador del clúster de Kubernetes (su clúster Civo; usted controla el endpoint)

### 6.3 Almacenamiento de objetos de Civo (compatible con S3)

- **Finalidad:** Navegar, cargar y descargar archivos en sus object stores
- **Datos enviados:** Solicitudes compatibles con S3 firmadas con sus credenciales del object store (AWS Signature V4)
- **Operador:** Civo Ltd

### 6.4 Servicios de detección de IP

- **Finalidad:** Detectar su dirección IPv4 pública para la gestión de reglas de firewall
- **Servicios utilizados:** ipify.org, ifconfig.me, icanhazip.com (cadena de respaldo)
- **Datos enviados:** Solicitud HTTPS estándar (su dirección IP es inherentemente visible para estos servicios)
- **Datos recibidos:** Su dirección IPv4 pública

### 6.5 Apple App Store / StoreKit

- **Finalidad:** Tramitar compras dentro de la aplicación, verificar derechos, habilitar En Familia
- **Datos enviados:** Gestionados íntegramente por el framework StoreKit de Apple
- **Operador:** Apple Inc.
- **Política de privacidad:** https://www.apple.com/legal/privacy/

### 6.6 SDKs no utilizados

**No** integramos ninguno de los siguientes:

- SDKs de analítica (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog, etc.)
- SDKs de informes de fallos (Crashlytics, Sentry, Bugsnag, etc.)
- SDKs de publicidad (AdMob, Meta Audience Network, AppLovin, etc.)
- SDKs de atribución (AppsFlyer, Adjust, Branch, Kochava, etc.)
- Frameworks de pruebas A/B
- SDKs de redes sociales
- Proveedores de autenticación de terceros

---

## 7. Transferencias internacionales de datos

No realizamos transferencias internacionales de datos personales porque no recopilamos ni tratamos datos personales.

Los flujos de datos iniciados por usted (llamadas a la API de Civo, Kubernetes, S3, detección de IP) pueden implicar una transmisión transfronteriza. Dichas transferencias se rigen por los avisos de privacidad y los mecanismos de transferencia de datos de los respectivos operadores. Para los usuarios del EEE/Reino Unido, Civo Ltd se apoya en las decisiones de adecuación del Reino Unido y la UE y, cuando corresponda, en las Cláusulas Contractuales Tipo (SCC).

---

## 8. Conservación de los datos

No conservamos ningún dato. Todos los datos de la Aplicación se almacenan localmente en su dispositivo y están bajo su control exclusivo.

- **Desinstalar la Aplicación** elimina las preferencias almacenadas en UserDefaults (normalmente en `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Los elementos del Keychain** pueden persistir tras la desinstalación; pueden eliminarse manualmente mediante Acceso a Llaveros
- **Las cachés de costes del mes anterior** se almacenan localmente y se eliminan junto con el contenedor al desinstalar

---

## 9. Seguridad de los datos

Aunque no recopilamos sus datos, implementamos las siguientes medidas de seguridad dentro de la Aplicación:

- **Almacenamiento de la clave de API:** Keychain de macOS con cifrado respaldado por hardware (Secure Enclave cuando está disponible)
- **Secretos de Object Store:** Protegidos con Touch ID / contraseña del sistema mediante el framework LocalAuthentication
- **Credenciales de Kubeconfig:** Almacenadas únicamente en memoria durante las sesiones activas, nunca persistidas en disco
- **Comunicación de red:** HTTPS/TLS 1.2+ para todas las comunicaciones con API
- **Autenticación por certificado:** La API de Kubernetes utiliza mTLS con certificado de cliente PKCS#12
- **App Sandbox:** La Aplicación se ejecuta dentro del App Sandbox de macOS, con los permisos mínimos necesarios
- **Hardened Runtime:** Endurecimiento de seguridad adicional en tiempo de ejecución
- **Sin telemetría:** No se transmite ningún dato de uso, analítica ni informe de fallos a ningún lugar
- **Sin registros persistentes:** Los registros utilizan `os.Logger` con `privacy: .private` y no se exportan

Ningún sistema es completamente seguro. Recomendamos utilizar una clave de API dedicada con los permisos mínimos de Civo necesarios para su flujo de trabajo.

---

## 10. Sus derechos

### 10.1 Derechos conforme al RGPD (UE / EEE / Reino Unido)

Usted tiene derecho a:

- **Acceso** a sus datos personales (art. 15 RGPD) — no aplicable, no conservamos datos sobre usted
- **Rectificación** de datos inexactos (art. 16 RGPD) — no aplicable
- **Supresión** / derecho al olvido (art. 17 RGPD) — no aplicable; puede eliminar los datos locales desinstalando la Aplicación
- **Limitación** del tratamiento (art. 18 RGPD) — no aplicable
- **Portabilidad de los datos** (art. 20 RGPD) — no aplicable
- **Oposición** al tratamiento (art. 21 RGPD) — no aplicable
- **Retirada del consentimiento** en cualquier momento (art. 7.3 RGPD) — puede dejar de utilizar la Aplicación en cualquier momento
- **Presentar una reclamación** ante una autoridad de control

Estos derechos quedan satisfechos por nuestra política de recopilación cero. Si esto cambiara en una versión futura, se lo notificaremos e implementaremos el marco completo de derechos.

### 10.2 Derechos conforme a la CCPA / CPRA (California, EE. UU.)

Los residentes de California tienen derecho a:

- Conocer qué información personal se recopila, utiliza, comparte o vende
- Eliminar información personal
- Oponerse a la venta o el intercambio de información personal
- No sufrir discriminación por ejercer los derechos de privacidad
- Corregir la información personal inexacta
- Limitar el uso de información personal sensible

No vendemos información personal. No compartimos información personal con fines de publicidad conductual entre contextos. No recopilamos información personal según se define en la CCPA/CPRA.

### 10.3 Derechos conforme a otras leyes estatales de EE. UU. (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR, etc.)

Los residentes de Virginia, Colorado, Connecticut, Utah, Texas, Oregón, Iowa, Montana, Florida, Tennessee, Indiana, Delaware, Nueva Jersey y otros estados de EE. UU. con legislación en materia de privacidad tienen derecho a acceder, eliminar, corregir y excluirse de la publicidad segmentada / venta / elaboración de perfiles. Estos derechos quedan satisfechos por nuestra política de recopilación cero.

### 10.4 Derechos conforme a la PIPEDA y leyes provinciales (Canadá)

Los residentes canadienses tienen derecho a acceder, impugnar la exactitud, retirar el consentimiento y presentar reclamaciones ante la Oficina del Comisionado de Privacidad de Canadá (o las autoridades provinciales de Quebec, Columbia Británica o Alberta).

### 10.5 Derechos conforme a la Ley Australiana de Privacidad

Los residentes australianos tienen derecho a acceder a su información personal y a corregirla, así como a presentar reclamaciones ante la Oficina del Comisionado de Información Australiano (OAIC).

### 10.6 Derechos conforme a la LGPD (Brasil)

Los residentes brasileños tienen derecho a la confirmación del tratamiento, acceso, corrección, anonimización, portabilidad, información sobre la comunicación y revocación del consentimiento. Las reclamaciones pueden dirigirse a la Autoridade Nacional de Proteção de Dados (ANPD).

### 10.7 Derechos conforme a la APPI (Japón)

Los residentes japoneses tienen derecho a la divulgación, corrección, eliminación y cese del uso. Las reclamaciones pueden dirigirse a la Comisión para la Protección de la Información Personal (PPC).

### 10.8 Derechos conforme a la PIPA (Corea del Sur)

Los residentes surcoreanos tienen derecho al acceso, corrección, eliminación, suspensión del tratamiento y reclamación de daños. Las reclamaciones pueden dirigirse a la Comisión para la Protección de la Información Personal (PIPC).

### 10.9 Derechos conforme a la PDPA (Singapur / Tailandia)

Los residentes tienen derecho al acceso, corrección y retirada del consentimiento. Las reclamaciones pueden dirigirse a la Comisión para la Protección de Datos Personales (PDPC) del respectivo país.

### 10.10 Derechos conforme a la PIPL (China)

Los residentes chinos tienen derecho a conocer, decidir, restringir, rechazar, acceder, copiar, portar, corregir, eliminar y exigir una explicación de las normas de tratamiento.

### 10.11 Derechos conforme a la Ley DPDP (India)

Los residentes indios tienen derecho a la información, corrección, supresión, reparación de reclamaciones y designación.

### 10.12 Derechos conforme a la POPIA (Sudáfrica)

Los residentes sudafricanos tienen derecho al acceso, corrección, eliminación y reclamación ante el Information Regulator.

### 10.13 Derechos conforme a la FADP suiza

Los residentes suizos tienen derecho a la información, acceso, rectificación, eliminación, oposición y portabilidad de los datos. Las reclamaciones pueden dirigirse al Comisionado Federal para la Protección de Datos e Información (FDPIC).

### 10.14 Derechos conforme a la Ley de Privacidad de Nueva Zelanda

Los residentes de Nueva Zelanda tienen derecho a acceder a la información personal y a corregirla, así como a presentar reclamaciones ante el Comisionado de Privacidad.

### 10.15 Cómo ejercer sus derechos

Dado que no conservamos datos sobre usted, estos derechos quedan satisfechos por defecto. Si cree que conservamos datos personales sobre usted a pesar de esta Política, póngase en contacto con moin@berger-rosenstock.de.

---

## 11. Privacidad de los menores

La Aplicación cuenta con una calificación por edad de **4+** en la App Store de Apple y, por tanto, es técnicamente accesible para usuarios de todas las edades. No obstante, la Aplicación es una herramienta técnica de gestión de infraestructura destinada a administradores de cuentas de Civo Cloud. Una cuenta de Civo Cloud requiere que el titular de la cuenta tenga la edad legal para contratar en su jurisdicción.

**No recopilamos intencionadamente información personal de ninguna persona, incluidos los menores de 13 años (COPPA, EE. UU.), 16 años (RGPD-K, UE) o la edad aplicable para prestar el consentimiento en su jurisdicción.**

Dado que la Aplicación implementa una estricta política de recopilación cero (véase la Sección 2), no se recopila, transmite, almacena en nuestros servidores ni se comparte con terceros ninguna información personal sobre ningún usuario, con independencia de su edad. Esto satisface:

- **COPPA** (Ley de Protección de la Privacidad Infantil en Línea, 15 U.S.C. §§ 6501–6506, EE. UU.)
- **Art. 8 RGPD** (UE)
- **PIPEDA** y leyes provinciales aplicables (Canadá)
- **Art. 14 LGPD** (Brasil)
- **APPI** (Japón)
- **Ley Australiana de Privacidad** y el AAP 8 sobre privacidad infantil

Si es padre, madre o tutor y cree que su hijo ha facilitado información personal, póngase en contacto con moin@berger-rosenstock.de. Investigaremos con prontitud y eliminaremos dicha información cuando se detecte.

---

## 12. Cookies y seguimiento

La Aplicación es una aplicación nativa de macOS y no utiliza cookies, web beacons, píxeles, huellas digitales ni tecnologías de seguimiento similares.

La Aplicación no contiene webviews integrados que carguen contenido de terceros.

---

## 13. Decisiones automatizadas

No llevamos a cabo decisiones automatizadas ni elaboración de perfiles que produzcan efectos jurídicos o que le afecten significativamente de modo similar. La Aplicación no realiza decisiones automatizadas basadas en datos personales.

---

## 14. Enlaces y servicios de terceros

La Aplicación puede contener enlaces a sitios web de terceros (por ejemplo, el sitio web de Civo, Apple App Store, plataforma de Resolución de Litigios en Línea). No somos responsables de las prácticas de privacidad ni del contenido de los servicios de terceros. Revise sus políticas de privacidad antes de proporcionar datos.

---

## 15. Cambios en esta Política

Podemos actualizar periódicamente esta Política de Privacidad.

- Los cambios sustanciales se comunicarán a través de la Aplicación o de la ficha de la App Store con al menos 30 días de antelación a su entrada en vigor
- La «Fecha de entrada en vigor» indicada al principio refleja la revisión más reciente
- No cambiaremos retroactivamente nuestras prácticas de privacidad para recopilar datos sin obtener su consentimiento expreso

---

## 16. Contacto

Para consultas relacionadas con la privacidad o para ejercer sus derechos:

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Alemania
Correo electrónico: moin@berger-rosenstock.de

Para los residentes de la UE, también puede dirigirse a la autoridad de control competente de su Estado miembro. Un listado de autoridades de control de la UE está disponible en: https://edpb.europa.eu/about-edpb/board/members_en

Para los residentes del Reino Unido, la autoridad de control es la Information Commissioner's Office (ICO): https://ico.org.uk

---

## 17. Disposiciones regionales

### 17.1 Unión Europea / Espacio Económico Europeo

- El funcionamiento cumple con el RGPD en lo aplicable al tratamiento local en su dispositivo
- La autoridad de control del responsable del tratamiento es la autoridad alemana de protección de datos del estado federado competente
- No se requieren Evaluaciones de Impacto relativas a la Protección de Datos (EIPD) (no hay recopilación)

### 17.2 Alemania

- Cumplimiento con el RGPD y la Bundesdatenschutzgesetz (BDSG)
- Autoridad de control competente: el Landesbeauftragte für Datenschutz del estado federado correspondiente (el responsable reside en Alemania)

### 17.3 Austria

- Cumplimiento con el RGPD y la Datenschutzgesetz (DSG)
- Autoridad de control: Datenschutzbehörde (DSB)

### 17.4 Suiza

- Cumplimiento con la Ley Federal de Protección de Datos revisada (revDSG), en vigor desde el 1 de septiembre de 2023
- Autoridad de control: Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB)

### 17.5 Reino Unido

- Cumplimiento con el UK GDPR y la Data Protection Act 2018
- Autoridad de control: Information Commissioner's Office (ICO)

### 17.6 Francia

- Cumplimiento con el RGPD y la Loi Informatique et Libertés
- Autoridad de control: Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Italia

- Cumplimiento con el RGPD y el Codice in materia di protezione dei dati personali
- Autoridad de control: Garante per la Protezione dei Dati Personali

### 17.8 España

- Cumplimiento con el RGPD y la Ley Orgánica 3/2018 (LOPDGDD)
- Autoridad de control: Agencia Española de Protección de Datos (AEPD)

### 17.9 Países Bajos

- Cumplimiento con el RGPD y la Uitvoeringswet AVG (UAVG)
- Autoridad de control: Autoriteit Persoonsgegevens (AP)

### 17.10 Polonia

- Cumplimiento con el RGPD y la Ustawa o ochronie danych osobowych
- Autoridad de control: Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portugal

- Cumplimiento con el RGPD y la Lei n.º 58/2019
- Autoridad de control: Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 Bélgica

- Cumplimiento con el RGPD y la Loi du 30 juillet 2018
- Autoridad de control: Gegevensbeschermingsautoriteit (APD-GBA)

### 17.13 Irlanda

- Cumplimiento con el RGPD y la Data Protection Act 2018
- Autoridad de control: Data Protection Commission (DPC)

### 17.14 Países nórdicos (Dinamarca, Finlandia, Noruega, Suecia, Islandia)

- Cumplimiento con el RGPD (y los equivalentes del EEE para Noruega e Islandia)
- Autoridades nacionales de control: Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Otros Estados miembros de la UE/EEE

Cumplimiento con el RGPD y su respectiva transposición nacional. Listado de autoridades de control: https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 Estados Unidos

- Cumplimiento con las leyes estatales de privacidad aplicables: CCPA/CPRA (California), VCDPA (Virginia), CPA (Colorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Texas), OCPA (Oregón), IDPA (Iowa), MCDPA (Montana), FDBR (Florida), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (Nueva Jersey)
- Las señales «Do Not Track» y «Global Privacy Control» se respetan cuando es técnicamente viable (la Aplicación no realiza seguimiento)
- Cumplimiento de la COPPA para usuarios menores de 13 años

### 17.17 Canadá

- Cumplimiento con la PIPEDA y las leyes provinciales aplicables: Ley 25 de Quebec, PIPA de Columbia Británica, PIPA de Alberta
- Reclamaciones: Oficina del Comisionado de Privacidad de Canadá (OPC) y autoridades provinciales

### 17.18 México

- Cumplimiento con la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Autoridad de control: Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brasil

- Cumplimiento con la LGPD
- Autoridad de control: Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentina, Chile, Colombia, Perú, Uruguay

- Cumplimiento con las leyes nacionales de protección de datos (Ley 25.326 / Ley 19.628 / Ley 1581 / Ley 29733 / Ley 18.331)

### 17.21 Australia

- Cumplimiento con la Privacy Act 1988 y los Australian Privacy Principles (APPs)
- Autoridad de control: Office of the Australian Information Commissioner (OAIC)

### 17.22 Nueva Zelanda

- Cumplimiento con la Privacy Act 2020
- Autoridad de control: Office of the Privacy Commissioner

### 17.23 Japón

- Cumplimiento con la Ley sobre la Protección de la Información Personal (APPI)
- Autoridad de control: Personal Information Protection Commission (PPC)

### 17.24 Corea del Sur

- Cumplimiento con la Personal Information Protection Act (PIPA)
- Autoridad de control: Personal Information Protection Commission (PIPC)

### 17.25 Singapur

- Cumplimiento con la Personal Data Protection Act (PDPA)
- Autoridad de control: Personal Data Protection Commission (PDPC)

### 17.26 Tailandia

- Cumplimiento con la Personal Data Protection Act B.E. 2562 (2019)
- Autoridad de control: Personal Data Protection Committee

### 17.27 China

- Cumplimiento con la Personal Information Protection Law (PIPL), la Cybersecurity Law (CSL) y la Data Security Law (DSL)

### 17.28 Hong Kong

- Cumplimiento con la Personal Data (Privacy) Ordinance (PDPO)
- Autoridad de control: Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 India

- Cumplimiento con la Digital Personal Data Protection Act 2023 (DPDP Act) y la Information Technology Act 2000
- Autoridad de control: Data Protection Board of India

### 17.30 Emiratos Árabes Unidos

- Cumplimiento con el Decreto-Ley Federal n.º 45 de 2021 (Ley de Protección de Datos Personales)

### 17.31 Arabia Saudí

- Cumplimiento con la Personal Data Protection Law (PDPL)

### 17.32 Turquía

- Cumplimiento con la Ley de Protección de Datos Personales n.º 6698 (KVKK)
- Autoridad de control: Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Israel

- Cumplimiento con la Privacy Protection Law, 5741-1981 y sus reglamentos
- Autoridad de control: Privacy Protection Authority (PPA)

### 17.34 Sudáfrica

- Cumplimiento con la Protection of Personal Information Act (POPIA)
- Autoridad de control: Information Regulator

### 17.35 Kenia, Nigeria, Egipto, Marruecos

- Cumplimiento con las leyes nacionales de protección de datos (Data Protection Act 2019 de Kenia, NDPR / NDPA de Nigeria, Ley n.º 151 de 2020 de Egipto, Ley 09-08 de Marruecos)

### 17.36 Otras jurisdicciones

Para los usuarios de jurisdicciones no enumeradas específicamente anteriormente, el enfoque de recopilación cero de la Aplicación garantiza el cumplimiento de los principios de minimización de datos y limitación de la finalidad comunes a los marcos modernos de privacidad. Si su legislación local otorga derechos adicionales, dichos derechos se respetan.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. Todos los derechos reservados.
