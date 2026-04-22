# Termos de Uso

## Civo Cloud Manager

**Data de Vigência:** Abril de 2026
**Última Atualização:** Abril de 2026

**Prestador:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Alemanha
E-mail: moin@berger-rosenstock.de
CNPJ/IVA: DE455096022

---

## 1. Escopo e Aceitação

### 1.1 Acordo

Estes Termos de Uso ("Termos") regem seu acesso e uso do aplicativo Civo Cloud Manager ("o Aplicativo") fornecido por Berger & Rosenstock GbR ("o Prestador", "nós", "nosso").

### 1.2 Aceitação

Ao instalar, acessar ou usar o Aplicativo, você concorda em estar vinculado a estes Termos. Se você não concorda, não deve instalar ou usar o Aplicativo.

### 1.3 Elegibilidade

O Aplicativo possui uma classificação etária na Apple App Store de **4+**. Para celebrar um contrato vinculativo, você deve ter a idade legal para contratos em sua jurisdição. Uma conta da Civo Cloud, que é necessária para um uso significativo do Aplicativo, exige que o titular da conta tenha a idade legal para contratos.

### 1.4 Uso Empresarial

Se você utiliza o Aplicativo em nome de uma organização, declara ter autoridade para vincular essa organização a estes Termos.

### 1.5 Contrato de Licença de Usuário Final de Aplicativo Licenciado pela Apple

Estes Termos são complementares ao Contrato de Licença de Usuário Final de Aplicativo Licenciado pela Apple (Apple EULA) entre você e a Apple Inc. Em caso de conflito entre estes Termos e o Apple EULA, o Apple EULA prevalece nas matérias que abrange.

---

## 2. Serviços

### 2.1 Descrição

O Aplicativo é uma aplicação nativa do macOS que permite o gerenciamento da infraestrutura da Civo Cloud (instâncias virtuais, clusters Kubernetes, bancos de dados, firewalls, redes, load balancers, volumes, object stores, DNS, chaves SSH) e acesso direto à API do Kubernetes através das próprias credenciais de API do usuário.

O Aplicativo se conecta diretamente do seu dispositivo a:

- A API REST da Civo Cloud (`api.civo.com`)
- Servidores da API do Kubernetes dos seus clusters Civo (via mTLS)
- Endpoints de armazenamento de objetos compatíveis com S3 da sua conta Civo
- Serviços de detecção de IP público (ipify.org, ifconfig.me, icanhazip.com)
- Apple App Store / StoreKit para processamento de compras

O Prestador não opera qualquer serviço de backend, servidor intermediário ou proxy. Toda a comunicação acontece diretamente entre seu dispositivo e os respectivos operadores terceiros.

### 2.2 Recursos Gratuitos e Pagos

A funcionalidade de gerenciamento de firewall na barra de menu é gratuita. O "Full Access" — que desbloqueia o painel de gerenciamento para todos os tipos de recursos suportados — é uma compra única no aplicativo processada exclusivamente através da Apple App Store (consulte a Seção 7).

### 2.3 Modificações

O Prestador pode modificar, suspender ou descontinuar qualquer funcionalidade do Aplicativo a qualquer momento. Alterações materiais que afetem recursos comprados serão comunicadas com pelo menos trinta (30) dias de antecedência, quando praticável.

### 2.4 Disponibilidade

O Aplicativo é fornecido na base "conforme disponível". O Prestador não garante acesso ou disponibilidade ininterruptos, e a funcionalidade do Aplicativo depende da disponibilidade de serviços de terceiros (Civo Cloud, Apple App Store, provedores de detecção de IP) que estão fora do controle do Prestador.

---

## 3. Contas

O Aplicativo não exige uma conta com o Prestador. Toda a autenticação é gerenciada através de:

- Sua chave da API Civo (armazenada localmente no Keychain do macOS)
- Seu kubeconfig do Kubernetes (recuperado da API da Civo)
- Seu Apple ID (para verificação de compras no aplicativo, gerenciado pela Apple)

Você é responsável por:

- Manter a confidencialidade de sua chave da API Civo e outras credenciais
- Todas as atividades realizadas usando suas credenciais
- Todas as alterações de recursos, custos e implicações de faturamento resultantes do seu uso do Aplicativo
- Configurar as permissões da chave da API Civo de acordo com o princípio do menor privilégio

O Prestador não tem capacidade de acessar, recuperar ou redefinir suas credenciais da Civo. A perda de credenciais é de sua exclusiva responsabilidade.

---

## 4. Conteúdo do Usuário

O Aplicativo não hospeda, armazena ou transmite conteúdo gerado pelo usuário a qualquer servidor operado pelo Prestador. Qualquer conteúdo, dado ou configuração que você cria usando o Aplicativo (por exemplo, nomes de instâncias, chaves SSH, rótulos de regras de firewall, arquivos de object store) é armazenado:

- Localmente em seu dispositivo, ou
- Em sua própria conta da Civo Cloud

Você retém todos os direitos, títulos e interesses em e sobre tal conteúdo. O Prestador não reivindica qualquer licença, propriedade ou outro direito sobre seu conteúdo.

---

## 5. Uso Aceitável

Você não pode usar o Aplicativo para:

- Violar qualquer lei, regulamento ou direito de terceiros aplicável
- Acessar ou operar recursos Civo aos quais não está autorizado a acessar
- Interferir ou interromper o serviço da Civo Cloud, clusters Kubernetes que você não possui ou o próprio Aplicativo
- Tentar fazer engenharia reversa, descompilar, desmontar ou derivar código-fonte do Aplicativo, exceto na medida em que tal restrição seja proibida pela lei aplicável
- Contornar mecanismos de segurança ou controle de acesso (incluindo o paywall de compra no aplicativo)
- Distribuir, sublicenciar, arrendar, alugar, vender ou de outra forma explorar comercialmente o Aplicativo
- Remover, alterar ou obscurecer avisos de propriedade, marcas de copyright ou marcas registradas
- Usar o Aplicativo para atacar, comprometer ou testar a segurança de sistemas que você não possui ou para os quais não tem autorização expressa por escrito para testar
- Usar o Aplicativo para qualquer finalidade proibida pelas leis da República Federal da Alemanha, da União Europeia ou de sua jurisdição de residência

---

## 6. Propriedade Intelectual

### 6.1 Propriedade

O Aplicativo (incluindo código-fonte, design, texto, gráficos, ícones, localizações e todos os direitos de propriedade intelectual associados) é propriedade exclusiva do Prestador e é protegido pelas leis alemãs, da União Europeia e internacionais de copyright, marcas registradas e outras leis de propriedade intelectual.

### 6.2 Concessão de Licença

Sujeito ao seu cumprimento destes Termos e do Apple EULA, o Prestador concede a você uma licença limitada, não exclusiva, intransferível, não sublicenciável e revogável para instalar e usar o Aplicativo em dispositivos Apple de sua propriedade ou controle, exclusivamente para seu uso pessoal ou empresarial interno de gerenciamento de sua infraestrutura da Civo Cloud.

### 6.3 Marcas Registradas de Terceiros

"Civo" é uma marca registrada da Civo Ltd. "Apple", "App Store", "macOS", "iCloud", "StoreKit", "TestFlight" são marcas registradas da Apple Inc. "Kubernetes" é uma marca registrada da The Linux Foundation. Todas as outras marcas registradas são propriedade de seus respectivos proprietários. O Prestador não é afiliado, endossado ou patrocinado por qualquer uma dessas partes.

### 6.4 Feedback

Qualquer feedback, sugestão ou ideia que você envie ao Prestador em relação ao Aplicativo poderá ser utilizado pelo Prestador sem restrições e sem compensação para você.

---

## 7. Pagamentos e Assinaturas

### 7.1 Compra no Aplicativo

O "Full Access" é vendido como uma compra no aplicativo não consumível através da Apple App Store por uma taxa única. O preço é exibido no Aplicativo em sua moeda local antes da compra.

### 7.2 Processamento de Pagamento

O pagamento é processado exclusivamente pela Apple Inc. O Prestador não recebe, armazena ou processa qualquer informação de pagamento. Todos os assuntos de pagamento, reembolso e faturamento são regidos pelos Termos de Serviços de Mídia da Apple e pelo Apple EULA.

### 7.3 Compartilhamento Familiar

O "Full Access" está habilitado para o Compartilhamento Familiar da Apple. Membros do seu grupo de Compartilhamento Familiar da Apple poderão usar a compra em seus próprios dispositivos, sujeito às regras de Compartilhamento Familiar da Apple.

### 7.4 Códigos de Oferta Apple

O Prestador pode emitir códigos de oferta Apple para fins promocionais. Os códigos de oferta podem ser resgatados através da função "Resgatar Código" no Aplicativo ou na App Store.

### 7.5 Reembolsos

Os reembolsos são tratados exclusivamente pela Apple de acordo com a política de reembolso da Apple. Os direitos estatutários do consumidor sob a lei aplicável (consulte a Seção 15) permanecem inalterados. Em particular, os consumidores da UE são informados de que o direito legal de retratação de 14 dias para conteúdo digital expira quando a execução começa com seu consentimento expresso prévio — a Apple implementa isso por meio do diálogo de confirmação no momento da compra.

### 7.6 Impostos

O preço exibido inclui todos os impostos aplicáveis (IVA, imposto sobre vendas) conforme determinado pela Apple com base em seu país.

---

## 8. Serviços de Terceiros

O uso do Aplicativo requer interação com serviços de terceiros. Seu uso desses serviços é regido por seus respectivos termos:

- **Civo Cloud:** https://www.civo.com/terms
- **Apple App Store / Apple ID:** https://www.apple.com/legal/internet-services/terms/
- **Clusters Kubernetes:** os termos do operador do seu cluster (Civo)

O Prestador não é parte de qualquer acordo entre você e um provedor de serviços terceiro e não é responsável pela disponibilidade, precisão ou comportamento desses serviços.

---

## 9. Isenção de Garantias

O APLICATIVO É FORNECIDO "NO ESTADO EM QUE SE ENCONTRA" E "CONFORME DISPONÍVEL" SEM GARANTIAS DE QUALQUER TIPO, EXPRESSAS OU IMPLÍCITAS, INCLUINDO, MAS NÃO SE LIMITANDO A GARANTIAS DE COMERCIABILIDADE, ADEQUAÇÃO A UM PROPÓSITO ESPECÍFICO, PRECISÃO, COMPLETUDE OU NÃO VIOLAÇÃO.

O PRESTADOR NÃO GARANTE QUE:

- O APLICATIVO SERÁ ININTERRUPTO, LIVRE DE ERROS OU SEGURO
- O APLICATIVO EXIBIRÁ, CRIARÁ, MODIFICARÁ, EXCLUIRÁ OU GERENCIARÁ CORRETAMENTE OS RECURSOS DA CIVO CLOUD
- QUALQUER DADO EXIBIDO PELO APLICATIVO SEJA PRECISO, COMPLETO OU ATUALIZADO
- O APLICATIVO SEJA COMPATÍVEL COM TODAS AS VERSÕES, RECURSOS OU REGIÕES DA API CIVO

**Operações destrutivas.** O Aplicativo pode realizar operações irreversíveis em sua conta da Civo Cloud, incluindo excluir clusters Kubernetes, bancos de dados, volumes, object stores, instâncias, chaves SSH e regras de firewall. Todas as operações destrutivas exigem confirmação explícita do usuário (tipicamente digitando o nome do recurso). O PRESTADOR NÃO ASSUME QUALQUER RESPONSABILIDADE por exclusões não intencionais, perda de dados, estouros de custo ou danos à infraestrutura causados pelo seu uso do Aplicativo.

Você é fortemente aconselhado a manter backups independentes de todos os dados críticos, a usar uma chave de API dedicada com as permissões Civo mínimas necessárias e a revisar cuidadosamente todos os diálogos de confirmação.

Nada nesta Seção exclui ou limita qualquer garantia que não possa ser excluída ou limitada sob a lei aplicável (consulte a Seção 15).

---

## 10. Limitação de Responsabilidade

NA MÁXIMA EXTENSÃO PERMITIDA PELA LEI APLICÁVEL:

### 10.1 Exclusões

O PRESTADOR NÃO SERÁ RESPONSÁVEL POR QUAISQUER DANOS INDIRETOS, INCIDENTAIS, ESPECIAIS, CONSEQUENTES, PUNITIVOS OU EXEMPLARES, INCLUINDO, MAS NÃO SE LIMITANDO A:

- Perda de dados, receita, lucros ou oportunidades de negócios
- Custos de aquisição de serviços substitutos
- Danos ou exclusão de infraestrutura em nuvem, recursos ou dados
- Acesso não autorizado resultante de chaves de API comprometidas

### 10.2 Limite

A RESPONSABILIDADE TOTAL AGREGADA DO PRESTADOR PERANTE VOCÊ POR TODAS AS RECLAMAÇÕES DECORRENTES OU RELACIONADAS AO APLICATIVO NÃO EXCEDERÁ O VALOR QUE VOCÊ REALMENTE PAGOU PELO APLICATIVO NOS DOZE (12) MESES ANTERIORES AO EVENTO QUE DEU ORIGEM À RECLAMAÇÃO.

### 10.3 Exceções

Nada nestes Termos exclui ou limita a responsabilidade por:

- Morte ou lesão pessoal causada por negligência
- Fraude ou deturpação fraudulenta
- Conduta dolosa ou negligência grave (nos termos da lei alemã, §§ 276, 309 BGB)
- Violação de obrigações contratuais essenciais (Kardinalpflichten), limitada a danos previsíveis típicos para este tipo de contrato
- Qualquer outra responsabilidade que não possa ser excluída ou limitada pela lei aplicável

### 10.4 Responsabilidade pelo Produto

A responsabilidade sob a Lei Alemã de Responsabilidade pelo Produto (Produkthaftungsgesetz) permanece inalterada.

---

## 11. Indenização

Você concorda em indenizar, defender e isentar o Prestador, seus parceiros, funcionários e agentes de e contra quaisquer reclamações, responsabilidades, danos, perdas, custos, despesas ou taxas (incluindo honorários advocatícios razoáveis) decorrentes ou relacionados a:

- Sua violação destes Termos
- Sua violação de qualquer lei ou direito de terceiros
- Seu uso do Aplicativo para acessar ou gerenciar infraestrutura que você não está autorizado a acessar
- Qualquer conteúdo ou configuração que você criar, modificar ou excluir através do Aplicativo

Esta obrigação de indenização não se aplica a consumidores no sentido da legislação aplicável de proteção ao consumidor, onde a lei obrigatória proíbe tal indenização.

---

## 12. Rescisão

### 12.1 Rescisão por Você

Você pode rescindir estes Termos a qualquer momento desinstalando o Aplicativo de seus dispositivos.

### 12.2 Rescisão pelo Prestador

O Prestador pode rescindir ou suspender sua licença de uso do Aplicativo imediatamente se você violar materialmente estes Termos. Em caso de rescisão:

- Seu direito de usar o Aplicativo cessa imediatamente
- Você deve desinstalar o Aplicativo de seus dispositivos
- As Seções 6, 9, 10, 11, 13, 14, 16 sobrevivem à rescisão

### 12.3 Efeito sobre a Compra

A rescisão não lhe dá direito a reembolso de sua compra no aplicativo, exceto conforme exigido pela lei aplicável de proteção ao consumidor ou pela política de reembolso da Apple.

---

## 13. Lei Aplicável e Resolução de Litígios

### 13.1 Lei Aplicável

Estes Termos são regidos pelas leis da República Federal da Alemanha, excluindo suas regras de conflito de leis e a Convenção das Nações Unidas sobre Contratos de Compra e Venda Internacional de Mercadorias (CISG).

Para consumidores dentro da União Europeia / EEE, esta escolha de lei não o priva da proteção obrigatória do consumidor das leis de seu país de residência habitual.

### 13.2 Jurisdição

Para comerciantes, pessoas jurídicas de direito público e fundos especiais de direito público (Kaufleute, juristische Personen des öffentlichen Rechts, öffentlich-rechtliche Sondervermögen), o foro exclusivo para todas as disputas decorrentes destes Termos será Bad Nauheim, Alemanha.

Para consumidores, aplica-se o foro estatutário. Você pode intentar ações nos tribunais de seu país de residência habitual.

### 13.3 Resolução de Litígios Online da UE

A Comissão Europeia fornece uma plataforma de resolução de litígios online em https://ec.europa.eu/consumers/odr.

### 13.4 Arbitragem de Consumo

O Prestador não é obrigado nem está disposto a participar de processos de resolução de litígios perante uma comissão de arbitragem do consumidor (Verbraucherschlichtungsstelle) no sentido da Lei Alemã de Resolução de Litígios de Consumo (VSBG), salvo quando exigido por lei.

---

## 14. Disposições Regionais

### 14.1 Alemanha

- Os direitos do consumidor nos termos do BGB §§ 312 e seguintes, §§ 327 e seguintes (produtos digitais) permanecem inalterados
- Os direitos estatutários de retratação nos termos do BGB § 355 aplicam-se quando cabível

### 14.2 União Europeia / EEE

- A Diretiva de Direitos do Consumidor 2011/83/UE e a Diretiva de Conteúdo Digital (UE) 2019/770 aplicam-se quando você é um consumidor
- Os avisos aplicáveis do Regulamento dos Serviços Digitais (Regulamento (UE) 2022/2065) nos termos do Artigo 12 são fornecidos no Aviso Legal

### 14.3 Reino Unido

- O Consumer Rights Act 2015 aplica-se quando você é um consumidor residente no Reino Unido
- O conteúdo digital deve ser de qualidade satisfatória, adequado ao propósito e conforme descrito

### 14.4 Suíça

- As disposições obrigatórias de consumo do Código Suíço das Obrigações (OR) permanecem inalteradas
- Aplica-se a Lei Federal contra a Concorrência Desleal (UWG)

### 14.5 Estados Unidos

- Estes Termos não se destinam a criar direitos nos termos de estatutos estaduais de proteção ao consumidor que não se apliquem por seus termos
- Residentes da Califórnia: aviso de direitos do consumidor do Civil Code § 1789.3 — entre em contato com moin@berger-rosenstock.de

### 14.6 Canadá

- A Lei de Proteção do Consumidor de Quebec aplica-se aos residentes de Quebec onde obrigatória
- Idioma do acordo: estes Termos são fornecidos em inglês; versões em francês disponíveis onde exigidas pela Charter of the French Language (Quebec)

### 14.7 Austrália

- As garantias da Lei Australiana do Consumidor (Competition and Consumer Act 2010, Schedule 2) aplicam-se quando você é um consumidor — estas garantias não podem ser excluídas

### 14.8 Nova Zelândia

- O Consumer Guarantees Act 1993 aplica-se quando você é um consumidor para uso pessoal, doméstico ou familiar

### 14.9 Japão

- A Lei de Contratos de Consumo (消費者契約法) aplica-se; as disposições destes Termos que seriam inválidas sob esta Lei são limitadas na medida necessária

### 14.10 Coreia do Sul

- Aplica-se a Lei sobre a Regulamentação dos Termos e Condições (약관의 규제에 관한 법률)

### 14.11 Brasil

- Aplica-se o Código de Defesa do Consumidor (CDC, Lei nº 8.078/1990); os direitos do consumidor não podem ser renunciados

### 14.12 Índia

- O Consumer Protection Act 2019 e as E-Commerce Rules 2020 aplicam-se quando você é um consumidor

### 14.13 Outras Jurisdições

Para usuários em jurisdições não especificamente listadas acima, estes Termos aplicam-se na medida permitida pela lei obrigatória local de proteção ao consumidor.

---

## 15. Direitos do Consumidor (Divulgações Obrigatórias)

Estes Termos não afetam seus direitos estatutários de consumidor nos termos da lei aplicável, incluindo, mas não se limitando a:

- Diretiva de Direitos do Consumidor da UE (2011/83/UE) e Diretiva de Conteúdo Digital ((UE) 2019/770)
- UK Consumer Rights Act 2015
- Lei Australiana do Consumidor
- Disposições de proteção ao consumidor do BGB alemão (§§ 312 e seguintes, §§ 327 e seguintes)
- Consumer Guarantees Act 1993 da Nova Zelândia
- Código de Defesa do Consumidor brasileiro (CDC)
- Estatutos provinciais canadenses de proteção ao consumidor
- Qualquer outra legislação aplicável de proteção ao consumidor em sua jurisdição

---

## 16. Disposições Gerais

### 16.1 Alterações a estes Termos

Podemos atualizar estes Termos periodicamente. Alterações materiais serão comunicadas através do Aplicativo ou da listagem na App Store pelo menos trinta (30) dias antes de entrarem em vigor. Seu uso continuado após as alterações entrarem em vigor constitui aceitação.

### 16.2 Cessão

Você não pode ceder ou transferir estes Termos ou quaisquer direitos sob eles sem o consentimento prévio por escrito do Prestador. O Prestador pode ceder estes Termos em conexão com uma fusão, aquisição ou venda de ativos.

### 16.3 Separabilidade

Se qualquer disposição destes Termos for considerada inexequível ou inválida, essa disposição será limitada ou eliminada na extensão mínima necessária para que estes Termos permaneçam em pleno vigor. Para a lei alemã, aplica-se o § 306 BGB.

### 16.4 Renúncia

A falha do Prestador em fazer cumprir qualquer disposição destes Termos não constituirá uma renúncia a essa disposição.

### 16.5 Acordo Integral

Estes Termos, juntamente com a Política de Privacidade, o Aviso Legal e o Apple EULA, constituem o acordo integral entre você e o Prestador em relação ao Aplicativo e substituem todos os acordos e entendimentos anteriores.

### 16.6 Idioma

A versão autorizada destes Termos é a versão em inglês. Traduções são fornecidas por conveniência. Em caso de discrepância, prevalece a versão em inglês, exceto quando a lei local obrigatória exigir de outra forma.

### 16.7 Comunicações Eletrônicas

Você consente em receber avisos legalmente exigidos do Prestador em formato eletrônico (através do Aplicativo ou e-mail).

### 16.8 Força Maior

O Prestador não é responsável por qualquer falha ou atraso no desempenho causado por eventos além de seu controle razoável, incluindo atos de Deus, guerra, terrorismo, agitação civil, disputas trabalhistas, falhas de internet, interrupções de serviços de terceiros ou ação governamental.

---

## 17. Contato

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Alemanha
E-mail: moin@berger-rosenstock.de
CNPJ/IVA: DE455096022

---

© 2025–2026 Berger & Rosenstock GbR. Todos os direitos reservados.
