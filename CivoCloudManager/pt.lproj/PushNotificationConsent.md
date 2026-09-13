<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: pt | app-version: 2.1.2 | updated: 2026-09-09 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: company identity and related clauses -->
# AVISO DE CONSENTIMENTO PARA NOTIFICAÇÕES PUSH

## Informação apresentada juntamente com o pedido de permissão do sistema para notificações push

**Data de Entrada em Vigor:** Setembro de 2026

**Fornecedor:**
DigitalFreedom
Uma marca de DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Estados Unidos da América
Contacto: hello@digitalfreedom.co.za
Proteção de dados: data-protection@digitalfreedom.co.za
Website: https://digitalfreedom.co.za

---

## 0. FINALIDADE

Este Aviso é apresentado **antes** do pedido de permissão do sistema iOS / Android para notificações push. Informa o utilizador — em linguagem clara — sobre o que está a consentir. Satisfaz:

- **Art. 6.º, n.º 1, alínea a) do RGPD** — consentimento livre, específico, informado e inequívoco para o tratamento relacionado com notificações quando estas contêm dados pessoais
- **Art. 13.º do RGPD** — transparência no momento da recolha
- **Diretiva ePrivacy 2002/58/CE Art. 13 / implementações nacionais** — para qualquer notificação com conteúdo de marketing
- **Apple Human Interface Guidelines** e **Google Play Developer Policy** — boas práticas de pré-aviso

Os Serviços são distribuídos globalmente através da Apple App Store e da Google Play Store; este Aviso aplica-se onde quer que as notificações push estejam ativadas e é apresentado na língua do utilizador, quando suportado.

---

## 1. O QUE ESTÁ A PERMITIR

Se tocar em **"Permitir"** no próximo pedido, `Civo Cloud Manager` poderá:

- enviar notificações para o seu dispositivo
- apresentar alertas, distintivos, banners e sons (sujeito às definições do seu sistema operativo)
- utilizar o APNs da Apple / FCM da Google como canal de entrega (o seu token de push do dispositivo é partilhado com estes fornecedores apenas para efeitos de entrega)

---

## 2. SOBRE O QUE SERÃO AS NOTIFICAÇÕES

`Civo Cloud Manager` envia notificações para os seguintes fins:

| Categoria | Exemplos | Predefinição |
|---|---|---|
| **Notificações de serviço** (essenciais) | alertas de conta, avisos de segurança, lembretes de pagamento, atualizações importantes | Ativo |
| **Transacionais** | confirmação de uma ação realizada por si, alterações de estado solicitadas | Ativo |
| **Lembretes** | lembretes configurados por si em `Civo Cloud Manager` | À sua escolha |
| **Dicas & novas funcionalidades** | atualizações ocasionais sobre novas funcionalidades | Desativado por defeito — opt-in |
| **Marketing / promocional** | ofertas, campanhas, novidades de produtos | Desativado por defeito — opt-in; consentimento separado ao abrigo do § 4 |

Cada categoria pode ser ativada ou desativada de forma independente em **Definições → Notificações** dentro de `Civo Cloud Manager` — e a qualquer momento nas definições de notificações ao nível do sistema operativo do seu dispositivo.

---

## 3. NÃO HÁ RASTREAMENTO PELA NOTIFICAÇÃO

Nós **não**:

- utilizamos notificações para rastrear a sua localização
- incluímos informações pessoalmente identificáveis (PII) sobre outros utilizadores nas suas notificações
- utilizamos notificações silenciosas / em segundo plano para recolher análises sobre si
- partilhamos o seu token de push do dispositivo com terceiros que não a Apple / Google para efeitos de entrega

---

## 4. NOTIFICAÇÕES DE MARKETING

As notificações push de marketing / promocionais são regidas pelo Art. 6.º, n.º 1, alínea a) do RGPD + ePrivacy Art. 13: **é necessário um opt-in explícito, separado e granular**.

- O interruptor de marketing está **desativado** por defeito
- Pode ativá-lo (e desativá-lo) a qualquer momento em **Definições → Notificações → Marketing**
- O consentimento para notificações push de marketing é **distinto** do consentimento para marketing por e-mail; ativar um não ativa o outro
- A revogação é tão simples quanto o opt-in (um único interruptor) e não afeta notificações não relacionadas com marketing

---

## 5. MENORES

Se `Civo Cloud Manager` for utilizado por menores, aplica-se adicionalmente o [Aviso de Privacidade para Crianças](CHILDREN_PRIVACY_NOTICE.md). Não enviamos notificações push de marketing a menores.

---

## 6. SUBCONTRATANTES ENVOLVIDOS

A entrega das notificações push utiliza serviços nativos da plataforma:

- **Apple Push Notification service (APNs)** — Apple Distribution International Ltd. (responsável independente pelo canal de entrega)
- **Firebase Cloud Messaging (FCM) / Google Mobile Services** — Google Ireland Limited (responsável independente pelo canal de entrega)

Estes atuam como responsáveis pelo tratamento para a camada de entrega, de acordo com as suas próprias políticas de privacidade. Consulte [`processors/apple.md`](processors/apple.md) e o registo de subcontratantes da Google Cloud ([Google Cloud sub-processor record](processors/google-cloud.md)).

---

## 7. OS SEUS DIREITOS

Pode, a qualquer momento:

- **Desativar** todas as notificações ao nível do sistema operativo (Definições → Notificações → `Civo Cloud Manager` → desativar)
- **Desativar categorias específicas** na aplicação (Definições → Notificações)
- **Retirar o consentimento de marketing** sem perder notificações de serviço
- **Solicitar a eliminação** de quaisquer dados que detenhamos relacionados com preferências de notificações através de `data-protection@digitalfreedom.co.za`

A retirada do consentimento não afeta a licitude do tratamento efetuado com base no consentimento previamente dado.

---

## 8. SE DISSER "NÃO PERMITIR"

Se recusar o pedido do sistema:

- `Civo Cloud Manager` continuará a funcionar — nenhuma funcionalidade está sujeita a pagamento ou bloqueada por falta de permissão para notificações
- pode mudar de opinião mais tarde em **Definições → Notificações → `Civo Cloud Manager`** (ao nível do sistema operativo)
- não voltaremos a solicitar repetidamente nem utilizaremos padrões escuros para coagir o consentimento

---

## 9. CONTACTO

DigitalFreedom
Uma marca de DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Estados Unidos da América

Ajuda com preferências de notificações: support@digitalfreedom.co.za
Proteção de dados: data-protection@digitalfreedom.co.za
Geral: hello@digitalfreedom.co.za
Website: https://digitalfreedom.co.za

---

(c) 2025-2026 DigitalFreedom Global LLC. Todos os direitos reservados.
