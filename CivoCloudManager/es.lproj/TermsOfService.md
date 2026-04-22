# Condiciones de Uso

## Civo Cloud Manager

**Fecha de entrada en vigor:** Abril de 2026
**Última actualización:** Abril de 2026

**Proveedor:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Alemania
Correo electrónico: moin@berger-rosenstock.de
NIF-IVA: DE455096022

---

## 1. Ámbito y aceptación

### 1.1 Acuerdo

Las presentes Condiciones de Uso («Condiciones») regulan su acceso a y uso de la aplicación Civo Cloud Manager («la Aplicación») proporcionada por Berger & Rosenstock GbR («el Proveedor», «nosotros», «nos», «nuestro»).

### 1.2 Aceptación

Al instalar, acceder o utilizar la Aplicación, usted acepta quedar vinculado por estas Condiciones. Si no está de acuerdo, no debe instalar ni utilizar la Aplicación.

### 1.3 Elegibilidad

La Aplicación tiene una calificación por edad de **4+** en la App Store de Apple. Para celebrar un contrato vinculante, debe tener la edad legal para contratar en su jurisdicción. Una cuenta de Civo Cloud, necesaria para un uso significativo de la Aplicación, requiere que el titular tenga la edad legal para contratar.

### 1.4 Uso empresarial

Si utiliza la Aplicación en nombre de una organización, declara que está autorizado para vincular a dicha organización a estas Condiciones.

### 1.5 Contrato de Licencia de Usuario Final de Apple (Apple EULA)

Estas Condiciones son complementarias al Contrato de Licencia de Usuario Final para Aplicaciones con Licencia de Apple (Apple EULA) entre usted y Apple Inc. En caso de conflicto entre estas Condiciones y el Apple EULA, prevalecerá el Apple EULA respecto de las materias que regula.

---

## 2. Servicios

### 2.1 Descripción

La Aplicación es una aplicación nativa de macOS que permite la gestión de la infraestructura de Civo Cloud (instancias virtuales, clústeres de Kubernetes, bases de datos, firewalls, redes, balanceadores de carga, volúmenes, object stores, DNS, claves SSH) y el acceso directo a la API de Kubernetes mediante las credenciales de API propias del usuario.

La Aplicación se conecta directamente desde su dispositivo a:

- La API REST de Civo Cloud (`api.civo.com`)
- Los servidores de la API de Kubernetes de sus clústeres Civo (mediante mTLS)
- Los endpoints de almacenamiento de objetos compatibles con S3 de su cuenta de Civo
- Los servicios públicos de detección de IP (ipify.org, ifconfig.me, icanhazip.com)
- Apple App Store / StoreKit para el tratamiento de la compra

El Proveedor no opera ningún servicio backend, servidor intermedio o proxy. Toda la comunicación se produce directamente entre su dispositivo y los respectivos operadores de terceros.

### 2.2 Funciones gratuitas y de pago

La funcionalidad de gestión de firewall desde la barra de menús es gratuita. «Full Access», que desbloquea el panel de gestión para todos los tipos de recursos admitidos, es una compra única dentro de la aplicación tramitada exclusivamente a través de la Apple App Store (véase la Sección 7).

### 2.3 Modificaciones

El Proveedor puede modificar, suspender o interrumpir cualquier funcionalidad de la Aplicación en cualquier momento. Los cambios sustanciales que afecten a funciones de pago se comunicarán con al menos treinta (30) días de antelación cuando sea practicable.

### 2.4 Disponibilidad

La Aplicación se proporciona «según disponibilidad». El Proveedor no garantiza el acceso ininterrumpido ni la disponibilidad, y la funcionalidad de la Aplicación depende de la disponibilidad de servicios de terceros (Civo Cloud, Apple App Store, proveedores de detección de IP) que escapan al control del Proveedor.

---

## 3. Cuentas

La Aplicación no requiere una cuenta con el Proveedor. Toda la autenticación se gestiona mediante:

- Su clave de API de Civo (almacenada localmente en el Keychain de macOS)
- Su kubeconfig de Kubernetes (obtenido de la API de Civo)
- Su ID de Apple (para la verificación de compras dentro de la aplicación, gestionado por Apple)

Usted es responsable de:

- Mantener la confidencialidad de su clave de API de Civo y demás credenciales
- Todas las actividades realizadas utilizando sus credenciales
- Todos los cambios de recursos, costes e implicaciones de facturación derivados de su uso de la Aplicación
- Configurar los permisos de la clave de API de Civo conforme al principio de mínimo privilegio

El Proveedor no tiene capacidad para acceder, recuperar ni restablecer sus credenciales de Civo. La pérdida de credenciales es exclusivamente su responsabilidad.

---

## 4. Contenido del usuario

La Aplicación no aloja, almacena ni transmite contenido generado por el usuario a ningún servidor operado por el Proveedor. Cualquier contenido, dato o configuración que usted cree mediante la Aplicación (por ejemplo, nombres de instancias, claves SSH, etiquetas de reglas de firewall, archivos de object store) se almacena:

- Localmente en su dispositivo, o
- En su propia cuenta de Civo Cloud

Usted conserva todos los derechos, títulos e intereses sobre dicho contenido. El Proveedor no reclama ninguna licencia, titularidad ni derecho sobre su contenido.

---

## 5. Uso aceptable

No podrá utilizar la Aplicación para:

- Infringir cualquier ley, norma o derecho de terceros aplicable
- Acceder o manejar recursos de Civo para los que no esté autorizado
- Interferir o perturbar el servicio de Civo Cloud, los clústeres de Kubernetes que no le pertenezcan o la propia Aplicación
- Intentar aplicar ingeniería inversa, descompilar, desensamblar o derivar el código fuente de la Aplicación, salvo en la medida en que la legislación aplicable prohíba dicha restricción
- Eludir los mecanismos de seguridad o de control de acceso (incluido el paywall de compras dentro de la aplicación)
- Distribuir, sublicenciar, arrendar, alquilar, vender o explotar comercialmente la Aplicación de cualquier otro modo
- Eliminar, alterar u ocultar avisos de propiedad, marcas de copyright o marcas registradas
- Utilizar la Aplicación para atacar, comprometer o probar la seguridad de sistemas que no posea o para los que no cuente con autorización expresa por escrito
- Utilizar la Aplicación con cualquier finalidad prohibida por las leyes de la República Federal de Alemania, la Unión Europea o su jurisdicción de residencia

---

## 6. Propiedad intelectual

### 6.1 Titularidad

La Aplicación (incluidos el código fuente, el diseño, los textos, los gráficos, los iconos, las localizaciones y todos los derechos de propiedad intelectual asociados) es propiedad exclusiva del Proveedor y está protegida por las leyes alemanas, de la Unión Europea e internacionales de copyright, marcas registradas y demás propiedad intelectual.

### 6.2 Concesión de licencia

Sujeto al cumplimiento de estas Condiciones y del Apple EULA, el Proveedor le concede una licencia limitada, no exclusiva, intransferible, no sublicenciable y revocable para instalar y utilizar la Aplicación en dispositivos Apple de su propiedad o bajo su control, únicamente para su uso personal o empresarial interno consistente en gestionar su infraestructura de Civo Cloud.

### 6.3 Marcas de terceros

«Civo» es una marca comercial de Civo Ltd. «Apple», «App Store», «macOS», «iCloud», «StoreKit», «TestFlight» son marcas comerciales de Apple Inc. «Kubernetes» es una marca comercial de The Linux Foundation. Todas las demás marcas son propiedad de sus respectivos titulares. El Proveedor no está afiliado a, respaldado por o patrocinado por ninguna de estas partes.

### 6.4 Comentarios

Cualquier comentario, sugerencia o idea que usted remita al Proveedor en relación con la Aplicación podrá ser utilizado por el Proveedor sin restricción y sin contraprestación para usted.

---

## 7. Pagos y suscripciones

### 7.1 Compra dentro de la aplicación

«Full Access» se vende como una compra dentro de la aplicación no consumible a través de la Apple App Store por una tarifa única. El precio se muestra en la Aplicación en su moneda local antes de la compra.

### 7.2 Tramitación del pago

El pago lo tramita exclusivamente Apple Inc. El Proveedor no recibe, almacena ni trata ninguna información de pago. Todos los asuntos relativos a pagos, reembolsos y facturación se rigen por las Media Services Terms de Apple y el Apple EULA.

### 7.3 En Familia

«Full Access» está habilitado para En Familia de Apple. Los miembros de su grupo En Familia podrán utilizar la compra en sus propios dispositivos, con sujeción a las reglas de En Familia de Apple.

### 7.4 Códigos promocionales de Apple

El Proveedor podrá emitir códigos promocionales de Apple con fines promocionales. Los códigos promocionales pueden canjearse mediante la función «Canjear código» en la Aplicación o en la App Store.

### 7.5 Reembolsos

Los reembolsos los gestiona exclusivamente Apple conforme a su política de reembolsos. Los derechos legales del consumidor conforme a la legislación aplicable (véase la Sección 15) quedan inalterados. En particular, se informa a los consumidores de la UE de que el derecho legal de desistimiento de 14 días para contenido digital expira cuando la ejecución ha comenzado con su consentimiento expreso previo — Apple lo implementa mediante el cuadro de diálogo de confirmación en el momento de la compra.

### 7.6 Impuestos

El precio mostrado incluye todos los impuestos aplicables (IVA, impuesto sobre ventas) según lo determine Apple en función de su país.

---

## 8. Servicios de terceros

El uso de la Aplicación requiere la interacción con servicios de terceros. Su uso de dichos servicios se rige por sus respectivas condiciones:

- **Civo Cloud:** https://www.civo.com/terms
- **Apple App Store / ID de Apple:** https://www.apple.com/legal/internet-services/terms/
- **Clústeres de Kubernetes:** las condiciones del operador de su clúster (Civo)

El Proveedor no es parte de ningún acuerdo entre usted y un proveedor de servicios externo y no es responsable de la disponibilidad, exactitud o comportamiento de dichos servicios.

---

## 9. Exención de garantías

LA APLICACIÓN SE PROPORCIONA «TAL CUAL» Y «SEGÚN DISPONIBILIDAD» SIN GARANTÍAS DE NINGÚN TIPO, EXPRESAS O IMPLÍCITAS, INCLUIDAS, ENTRE OTRAS, LAS GARANTÍAS DE COMERCIABILIDAD, IDONEIDAD PARA UN FIN DETERMINADO, EXACTITUD, COMPLETITUD O NO INFRACCIÓN.

EL PROVEEDOR NO GARANTIZA QUE:

- LA APLICACIÓN SEA ININTERRUMPIDA, LIBRE DE ERRORES O SEGURA
- LA APLICACIÓN MOSTRARÁ, CREARÁ, MODIFICARÁ, ELIMINARÁ O GESTIONARÁ CORRECTAMENTE LOS RECURSOS DE CIVO CLOUD
- LOS DATOS MOSTRADOS POR LA APLICACIÓN SEAN PRECISOS, COMPLETOS O ESTÉN ACTUALIZADOS
- LA APLICACIÓN SEA COMPATIBLE CON TODAS LAS VERSIONES, FUNCIONES O REGIONES DE LA API DE CIVO

**Operaciones destructivas.** La Aplicación puede realizar operaciones irreversibles en su cuenta de Civo Cloud, incluida la eliminación de clústeres de Kubernetes, bases de datos, volúmenes, object stores, instancias, claves SSH y reglas de firewall. Todas las operaciones destructivas requieren una confirmación explícita del usuario (normalmente escribiendo el nombre del recurso). EL PROVEEDOR NO ASUME RESPONSABILIDAD alguna por eliminaciones no deseadas, pérdida de datos, sobrecostes o daños a la infraestructura causados por su uso de la Aplicación.

Se le recomienda encarecidamente mantener copias de seguridad independientes de todos los datos críticos, utilizar una clave de API dedicada con los permisos mínimos de Civo necesarios y revisar detenidamente todos los cuadros de diálogo de confirmación.

Nada en esta Sección excluye ni limita ninguna garantía que no pueda excluirse o limitarse conforme a la legislación aplicable (véase la Sección 15).

---

## 10. Limitación de responsabilidad

EN LA MÁXIMA MEDIDA PERMITIDA POR LA LEGISLACIÓN APLICABLE:

### 10.1 Exclusiones

EL PROVEEDOR NO SERÁ RESPONSABLE DE DAÑOS INDIRECTOS, INCIDENTALES, ESPECIALES, CONSECUENTES, PUNITIVOS O EJEMPLARIZANTES, INCLUIDOS, ENTRE OTROS:

- Pérdida de datos, ingresos, beneficios u oportunidades de negocio
- Costes de adquisición de servicios sustitutivos
- Daños o eliminación de infraestructura, recursos o datos en la nube
- Acceso no autorizado derivado de claves de API comprometidas

### 10.2 Límite

LA RESPONSABILIDAD TOTAL AGREGADA DEL PROVEEDOR FRENTE A USTED POR TODAS LAS RECLAMACIONES DERIVADAS DE O RELACIONADAS CON LA APLICACIÓN NO EXCEDERÁ EL IMPORTE QUE USTED HAYA PAGADO EFECTIVAMENTE POR LA APLICACIÓN EN LOS DOCE (12) MESES PREVIOS AL HECHO QUE ORIGINA LA RECLAMACIÓN.

### 10.3 Excepciones

Nada en estas Condiciones excluye ni limita la responsabilidad por:

- Muerte o lesiones corporales causadas por negligencia
- Dolo o manifestación fraudulenta
- Conducta dolosa o negligencia grave (conforme al derecho alemán, §§ 276, 309 BGB)
- Incumplimiento de obligaciones contractuales esenciales (Kardinalpflichten), limitada a los daños previsibles típicos de este tipo de contrato
- Cualquier otra responsabilidad que no pueda excluirse ni limitarse conforme a la legislación aplicable

### 10.4 Responsabilidad por producto

La responsabilidad conforme a la Ley Alemana de Responsabilidad por Productos (Produkthaftungsgesetz) queda inalterada.

---

## 11. Indemnización

Usted se compromete a indemnizar, defender y mantener indemne al Proveedor, sus socios, empleados y agentes frente a toda reclamación, responsabilidad, daño, pérdida, coste, gasto u honorario (incluidos los honorarios razonables de abogados) derivados de o relacionados con:

- Su incumplimiento de estas Condiciones
- Su infracción de cualquier ley o derecho de terceros
- Su uso de la Aplicación para acceder o gestionar infraestructura para la que no esté autorizado
- Cualquier contenido o configuración que usted cree, modifique o elimine a través de la Aplicación

Esta obligación de indemnización no se aplica a los consumidores en el sentido de la legislación aplicable de protección de los consumidores cuando la ley imperativa prohíba tal indemnización.

---

## 12. Terminación

### 12.1 Terminación por su parte

Puede rescindir estas Condiciones en cualquier momento desinstalando la Aplicación de sus dispositivos.

### 12.2 Terminación por parte del Proveedor

El Proveedor podrá rescindir o suspender de forma inmediata su licencia para utilizar la Aplicación si usted incumple sustancialmente estas Condiciones. En caso de terminación:

- Su derecho a utilizar la Aplicación cesará de inmediato
- Deberá desinstalar la Aplicación de sus dispositivos
- Las Secciones 6, 9, 10, 11, 13, 14, 16 sobrevivirán a la terminación

### 12.3 Efecto sobre la compra

La terminación no le da derecho a un reembolso de su compra dentro de la aplicación, salvo que así lo exija la legislación aplicable en materia de consumidores o la política de reembolsos de Apple.

---

## 13. Ley aplicable y resolución de conflictos

### 13.1 Ley aplicable

Estas Condiciones se rigen por las leyes de la República Federal de Alemania, con exclusión de sus normas de conflicto de leyes y de la Convención de las Naciones Unidas sobre los Contratos de Compraventa Internacional de Mercaderías (CISG).

Para los consumidores dentro de la Unión Europea / EEE, esta elección de ley no le priva de la protección obligatoria del consumidor de las leyes de su país de residencia habitual.

### 13.2 Jurisdicción

Para los comerciantes, personas jurídicas de derecho público y fondos especiales de derecho público (Kaufleute, juristische Personen des öffentlichen Rechts, öffentlich-rechtliche Sondervermögen), el fuero exclusivo para todos los litigios derivados de estas Condiciones será Bad Nauheim, Alemania.

Para los consumidores, será de aplicación el fuero legal. Usted podrá entablar procedimientos ante los tribunales de su país de residencia habitual.

### 13.3 Resolución de Litigios en Línea de la UE

La Comisión Europea proporciona una plataforma de Resolución de Litigios en Línea disponible en https://ec.europa.eu/consumers/odr.

### 13.4 Arbitraje de consumo

El Proveedor no está obligado ni dispuesto a participar en procedimientos de resolución de litigios ante una junta de arbitraje de consumidores (Verbraucherschlichtungsstelle) en el sentido de la Ley Alemana de Resolución de Litigios de Consumidores (VSBG), salvo que así lo exija la ley.

---

## 14. Disposiciones regionales

### 14.1 Alemania

- Los derechos del consumidor conforme al BGB §§ 312 y ss., §§ 327 y ss. (productos digitales) quedan inalterados
- Los derechos legales de desistimiento conforme al § 355 BGB se aplican cuando corresponda

### 14.2 Unión Europea / EEE

- La Directiva sobre los derechos de los consumidores 2011/83/UE y la Directiva sobre contenidos digitales (UE) 2019/770 se aplican cuando usted sea consumidor
- Los avisos aplicables del Reglamento de Servicios Digitales (Reglamento (UE) 2022/2065) conforme al artículo 12 se proporcionan en el Aviso Legal

### 14.3 Reino Unido

- La Consumer Rights Act 2015 se aplica cuando usted sea un consumidor residente en el Reino Unido
- El contenido digital debe ser de calidad satisfactoria, adecuado para su finalidad y conforme a la descripción

### 14.4 Suiza

- Las disposiciones imperativas de protección del consumidor del Código Suizo de las Obligaciones (OR) quedan inalteradas
- La Ley Federal contra la Competencia Desleal (UWG) se aplica

### 14.5 Estados Unidos

- Estas Condiciones no pretenden crear derechos en virtud de estatutos estatales de protección del consumidor que no sean aplicables según sus propios términos
- Residentes de California: aviso de derechos del consumidor del Código Civil § 1789.3 — contacte con moin@berger-rosenstock.de

### 14.6 Canadá

- La Quebec Consumer Protection Act se aplica a los residentes de Quebec cuando sea imperativa
- Idioma del acuerdo: estas Condiciones se proporcionan en inglés; se proporcionarán versiones en francés cuando así lo exija la Charte de la langue française (Quebec)

### 14.7 Australia

- Las garantías de la Australian Consumer Law (Competition and Consumer Act 2010, Schedule 2) se aplican cuando usted sea consumidor — dichas garantías no pueden excluirse

### 14.8 Nueva Zelanda

- La Consumer Guarantees Act 1993 se aplica cuando usted sea consumidor para un uso personal, doméstico o del hogar

### 14.9 Japón

- La Ley sobre Contratos de Consumo (消費者契約法) se aplica; las disposiciones de estas Condiciones que fueran inválidas conforme a esta Ley se limitan en la medida necesaria

### 14.10 Corea del Sur

- La Ley sobre la Regulación de Términos y Condiciones (약관의 규제에 관한 법률) se aplica

### 14.11 Brasil

- El Código de Defensa del Consumidor (CDC, Ley n.º 8.078/1990) se aplica; los derechos del consumidor no pueden renunciarse

### 14.12 India

- La Consumer Protection Act 2019 y las E-Commerce Rules 2020 se aplican cuando usted sea consumidor

### 14.13 Otras jurisdicciones

Para los usuarios de jurisdicciones no enumeradas específicamente anteriormente, estas Condiciones se aplican en la medida permitida por la legislación local imperativa de protección del consumidor.

---

## 15. Derechos del consumidor (avisos obligatorios)

Estas Condiciones no afectan a sus derechos legales como consumidor conforme a la legislación aplicable, incluidos, entre otros:

- La Directiva sobre los derechos de los consumidores de la UE (2011/83/UE) y la Directiva sobre contenidos digitales ((UE) 2019/770)
- La Consumer Rights Act 2015 del Reino Unido
- La Australian Consumer Law
- Las disposiciones de protección del consumidor del BGB alemán (§§ 312 y ss., §§ 327 y ss.)
- La Consumer Guarantees Act 1993 de Nueva Zelanda
- El Código de Defensa del Consumidor brasileño (CDC)
- Los estatutos provinciales canadienses de protección del consumidor
- Cualquier otra legislación aplicable de protección del consumidor en su jurisdicción

---

## 16. Disposiciones generales

### 16.1 Cambios en estas Condiciones

Podemos actualizar estas Condiciones periódicamente. Los cambios sustanciales se comunicarán a través de la Aplicación o de la ficha de la App Store con al menos treinta (30) días de antelación a su entrada en vigor. El uso continuado tras la entrada en vigor de los cambios constituye su aceptación.

### 16.2 Cesión

No podrá ceder ni transferir estas Condiciones ni ningún derecho derivado de ellas sin el consentimiento previo por escrito del Proveedor. El Proveedor podrá ceder estas Condiciones en el contexto de una fusión, adquisición o venta de activos.

### 16.3 Divisibilidad

Si alguna disposición de estas Condiciones resultara inaplicable o inválida, dicha disposición se limitará o eliminará en la medida mínima necesaria para que estas Condiciones permanezcan en pleno vigor. Para el derecho alemán, se aplica el § 306 BGB.

### 16.4 Renuncia

El hecho de que el Proveedor no haga valer una disposición de estas Condiciones no constituirá una renuncia a dicha disposición.

### 16.5 Acuerdo íntegro

Estas Condiciones, junto con la Política de Privacidad, el Aviso Legal y el Apple EULA, constituyen el acuerdo íntegro entre usted y el Proveedor respecto de la Aplicación y sustituyen a todos los acuerdos y entendimientos anteriores.

### 16.6 Idioma

La versión auténtica de estas Condiciones es la versión en inglés. Las traducciones se facilitan por comodidad. En caso de discrepancia, prevalecerá la versión en inglés, salvo cuando la legislación local imperativa exija lo contrario.

### 16.7 Comunicaciones electrónicas

Usted consiente recibir del Proveedor los avisos legalmente exigidos en forma electrónica (a través de la Aplicación o por correo electrónico).

### 16.8 Fuerza mayor

El Proveedor no será responsable de ningún incumplimiento o demora en el cumplimiento causado por hechos que escapen a su control razonable, incluidos casos fortuitos, guerra, terrorismo, disturbios civiles, conflictos laborales, fallos de internet, interrupciones de servicios de terceros o acciones gubernamentales.

---

## 17. Contacto

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Alemania
Correo electrónico: moin@berger-rosenstock.de
NIF-IVA: DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. Todos los derechos reservados.
