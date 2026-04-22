# Política de Privacidade

## Civo Cloud Manager

**Data de Vigência:** Abril de 2026
**Última Atualização:** Abril de 2026

**Controlador de Dados:**
Berger & Rosenstock GbR
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e, 61231 Bad Nauheim, Alemanha
E-mail: moin@berger-rosenstock.de

---

## 1. Introdução

Esta Política de Privacidade explica como Marcel R. G. Berger, atuando como Berger & Rosenstock GbR ("nós", "nosso"), trata informações em conexão com o aplicativo Civo Cloud Manager ("o Aplicativo").

Temos o compromisso de proteger sua privacidade e cumprir as leis de proteção de dados aplicáveis, incluindo, entre outras:

- Regulamento Geral de Proteção de Dados da UE (GDPR, Regulamento (UE) 2016/679)
- Lei Federal Alemã de Proteção de Dados (BDSG)
- Regulamento Geral de Proteção de Dados do Reino Unido (UK GDPR) e Data Protection Act 2018
- Lei Federal Suíça de Proteção de Dados (FADP / revDSG)
- California Consumer Privacy Act (CCPA) e California Privacy Rights Act (CPRA)
- Virginia Consumer Data Protection Act (VCDPA), Colorado Privacy Act (CPA), Connecticut Data Privacy Act (CTDPA), Utah Consumer Privacy Act (UCPA) e outras leis estaduais dos EUA
- Personal Information Protection and Electronic Documents Act do Canadá (PIPEDA) e leis provinciais
- Australian Privacy Act 1988 e Australian Privacy Principles (APPs)
- Lei Geral de Proteção de Dados Pessoais do Brasil (LGPD, Lei nº 13.709/2018)
- Lei Japonesa de Proteção de Informações Pessoais (APPI)
- Lei Sul-Coreana de Proteção de Informações Pessoais (PIPA)
- Personal Data Protection Act de Singapura (PDPA)
- Personal Data Protection Act da Tailândia (PDPA 2019)
- Lei Chinesa de Proteção de Informações Pessoais (PIPL)
- Digital Personal Data Protection Act 2023 da Índia (DPDP Act)
- Protection of Personal Information Act da África do Sul (POPIA)
- Lei de Proteção de Dados Pessoais dos Emirados Árabes Unidos (PDPL)
- New Zealand Privacy Act 2020
- Children's Online Privacy Protection Act (COPPA, EUA)

---

## 2. Princípio de Coleta Zero de Dados

**Não coletamos, armazenamos, transmitimos ou processamos quaisquer dados pessoais em nossos servidores.**

O Aplicativo opera inteiramente no seu dispositivo. Todas as configurações, credenciais e preferências são armazenadas localmente. Não possuímos servidores que recebam seus dados. Não operamos qualquer infraestrutura de backend para coleta de dados, análises, relatórios de falhas ou telemetria.

Como não processamos dados pessoais sob nosso controle, a maioria das obrigações das leis de proteção de dados (deveres de controlador de dados, obrigações de transferência internacional, notificação de violações, etc.) não se aplica a nós como editor deste Aplicativo. A Seção 10, no entanto, descreve os direitos disponíveis a você nos termos da lei aplicável.

---

## 3. Dados Armazenados em Seu Dispositivo

O Aplicativo armazena os seguintes dados localmente em seu dispositivo macOS. Nenhum destes dados é transmitido aos nossos servidores.

### 3.1 Credenciais

- **Chave da API Civo** — armazenada no Keychain do macOS (criptografia com suporte de hardware) — utilizada para autenticação com a API da Civo Cloud
- **Credenciais do Kubeconfig** — armazenadas apenas em memória durante sessões ativas, nunca persistidas em disco
- **Credenciais do Object Store (Access Key ID / Secret)** — recuperadas da API da Civo sob demanda, armazenadas apenas em memória

### 3.2 Preferências

- **Região Selecionada** (UserDefaults) — código da região Civo ativa
- **Firewalls Gerenciados** (UserDefaults, JSON) — configurações de firewall rastreadas pelo Aplicativo
- **Iniciar ao Fazer Login** (UserDefaults) — preferência de início automático
- **Estado de Onboarding** (UserDefaults) — sinalizador de conclusão de configuração
- **Presets de IP** (UserDefaults, JSON) — endereços IP nomeados pelo usuário para regras de firewall

### 3.3 Dados Transitórios de Execução

- **IP Público Detectado** — mantido em memória durante uma sessão, nunca persistido
- **Respostas da API** — mantidas em memória enquanto exibidas, nunca persistidas além da sessão

### 3.4 Status da Compra

Gerenciado inteiramente pelo Apple StoreKit. Não recebemos, armazenamos ou processamos quaisquer informações de pagamento.

---

## 4. Base Legal para o Tratamento (GDPR)

Como não atuamos como controlador ou operador de dados pessoais coletados por meio do Aplicativo, as bases do Art. 6 do GDPR para tratamento não se aplicam a nós. Na medida em que a operação do Aplicativo envolve tratamento local em seu dispositivo, este é realizado com base em:

- **Execução de contrato** (Art. 6(1)(b) GDPR) — fornecer a funcionalidade para a qual você instalou o Aplicativo
- **Consentimento** (Art. 6(1)(a) GDPR) — quando você aciona explicitamente ações como detecção de IP, criação de regras de firewall ou autenticação via Touch ID

Nenhum tratamento ocorre sob os Arts. 6(1)(a), (c), (d), (e) ou (f) do GDPR em infraestrutura operada por nós.

---

## 5. Como os Dados São Utilizados

Os dados em seu dispositivo são utilizados exclusivamente para:

- Autenticar contra a API da Civo Cloud, servidores da API do Kubernetes e endpoints de armazenamento de objetos compatíveis com S3 aos quais você direciona o Aplicativo
- Gerenciar seus recursos da Civo Cloud (instâncias, clusters, bancos de dados, firewalls, etc.)
- Detectar seu endereço IPv4 público para abrir e fechar regras de firewall
- Exibir status de recursos, estimativas de custo e registros de atividade localmente
- Processar sua compra única no aplicativo através do Apple StoreKit

Os dados nunca são compartilhados, vendidos, alugados ou de outra forma divulgados a terceiros por nós.

---

## 6. Serviços de Terceiros

O Aplicativo se comunica diretamente com os seguintes serviços de terceiros sob sua orientação explícita. Não somos parte dessas comunicações.

### 6.1 API da Civo Cloud (api.civo.com)

- **Finalidade:** Gerenciar sua infraestrutura da Civo Cloud
- **Dados enviados:** Sua chave da API Civo (como cabeçalho de autenticação), requisições de gerenciamento de recursos
- **Operador:** Civo Ltd, Reino Unido
- **Política de privacidade:** https://www.civo.com/privacy

### 6.2 Servidores da API do Kubernetes

- **Finalidade:** Acessar nós, pods, logs, deployments e métricas do cluster
- **Dados enviados:** Credenciais de certificado cliente do seu kubeconfig (PKCS#12 mTLS)
- **Operador:** O operador do cluster Kubernetes (seu cluster Civo; você controla o endpoint)

### 6.3 Armazenamento de Objetos Civo (compatível com S3)

- **Finalidade:** Navegar, fazer upload e download de arquivos em seus object stores
- **Dados enviados:** Requisições compatíveis com S3 assinadas com suas credenciais do object store (AWS Signature V4)
- **Operador:** Civo Ltd

### 6.4 Serviços de Detecção de IP

- **Finalidade:** Detectar seu endereço IPv4 público para gerenciamento de regras de firewall
- **Serviços utilizados:** ipify.org, ifconfig.me, icanhazip.com (cadeia de fallback)
- **Dados enviados:** Requisição HTTPS padrão (seu endereço IP é inerentemente visível a estes serviços)
- **Dados recebidos:** Seu endereço IPv4 público

### 6.5 Apple App Store / StoreKit

- **Finalidade:** Processar compras no aplicativo, verificar autorizações, habilitar o Compartilhamento Familiar
- **Dados enviados:** Gerenciados inteiramente pelo framework StoreKit da Apple
- **Operador:** Apple Inc.
- **Política de privacidade:** https://www.apple.com/legal/privacy/

### 6.6 SDKs Não Utilizados

**Não** integramos nenhum dos seguintes:

- SDKs de análise (Google Analytics, Firebase Analytics, Mixpanel, Amplitude, PostHog, etc.)
- SDKs de relatório de falhas (Crashlytics, Sentry, Bugsnag, etc.)
- SDKs de publicidade (AdMob, Meta Audience Network, AppLovin, etc.)
- SDKs de atribuição (AppsFlyer, Adjust, Branch, Kochava, etc.)
- Frameworks de teste A/B
- SDKs de mídia social
- Provedores de autenticação de terceiros

---

## 7. Transferências Internacionais de Dados

Não transferimos dados pessoais internacionalmente porque não coletamos ou processamos dados pessoais.

Os fluxos de dados iniciados por você (chamadas de API para Civo, Kubernetes, S3, detecção de IP) podem envolver transmissão transfronteiriça. Essas transferências são regidas pelos avisos de privacidade e mecanismos de transferência de dados dos respectivos operadores. Para usuários do EEE/Reino Unido, a Civo Ltd baseia-se em decisões de adequação do Reino Unido e da UE e, quando aplicável, nas Cláusulas Contratuais Padrão (SCCs).

---

## 8. Retenção de Dados

Não retemos dados. Todos os dados do Aplicativo são armazenados localmente em seu dispositivo e estão sob seu controle exclusivo.

- **Desinstalar o Aplicativo** remove as preferências armazenadas no UserDefaults (tipicamente `~/Library/Containers/de.berger-rosenstock.CivoCloudManager/`)
- **Itens do Keychain** podem persistir após a desinstalação; estes podem ser removidos manualmente via Acesso às Chaves
- **Caches de custo do mês anterior** são armazenados localmente e removidos com o contêiner ao desinstalar

---

## 9. Segurança dos Dados

Embora não coletemos seus dados, implementamos as seguintes medidas de segurança dentro do Aplicativo:

- **Armazenamento da Chave da API:** Keychain do macOS com criptografia com suporte de hardware (Secure Enclave quando disponível)
- **Segredos do Object Store:** Protegidos por Touch ID / senha do sistema via framework LocalAuthentication
- **Credenciais do Kubeconfig:** Armazenadas apenas em memória durante sessões ativas, nunca persistidas em disco
- **Comunicação de Rede:** HTTPS/TLS 1.2+ para todas as comunicações de API
- **Autenticação por Certificado:** A API do Kubernetes usa mTLS com certificado cliente PKCS#12
- **App Sandbox:** O Aplicativo é executado dentro do App Sandbox do macOS, com as autorizações mínimas necessárias
- **Hardened Runtime:** Endurecimento de segurança adicional em tempo de execução
- **Sem Telemetria:** Nenhum dado de uso, análise ou relatório de falha é transmitido a lugar algum
- **Sem Registro Persistente:** Os logs usam `os.Logger` com `privacy: .private` e não são exportados

Nenhum sistema é completamente seguro. Recomendamos o uso de uma chave de API dedicada com as permissões Civo mínimas necessárias para seu fluxo de trabalho.

---

## 10. Seus Direitos

### 10.1 Direitos sob o GDPR (UE / EEE / Reino Unido)

Você tem o direito de:

- **Acesso** aos seus dados pessoais (Art. 15 GDPR) — não aplicável, não mantemos dados sobre você
- **Retificação** de dados imprecisos (Art. 16 GDPR) — não aplicável
- **Apagamento** / direito ao esquecimento (Art. 17 GDPR) — não aplicável; você pode excluir dados locais desinstalando
- **Limitação** do tratamento (Art. 18 GDPR) — não aplicável
- **Portabilidade dos dados** (Art. 20 GDPR) — não aplicável
- **Oposição** ao tratamento (Art. 21 GDPR) — não aplicável
- **Retirada do consentimento** a qualquer momento (Art. 7(3) GDPR) — você pode parar de usar o Aplicativo a qualquer momento
- **Apresentar uma reclamação** a uma autoridade supervisora

Esses direitos são atendidos por nossa política de coleta zero. Caso isso mude em uma versão futura, notificaremos você e implementaremos o quadro completo de direitos.

### 10.2 Direitos sob CCPA / CPRA (Califórnia, EUA)

Residentes da Califórnia têm o direito de:

- Saber quais informações pessoais são coletadas, utilizadas, compartilhadas ou vendidas
- Excluir informações pessoais
- Optar por não participar da venda ou compartilhamento de informações pessoais
- Não sofrer discriminação por exercer direitos de privacidade
- Corrigir informações pessoais imprecisas
- Limitar o uso de informações pessoais sensíveis

Não vendemos informações pessoais. Não compartilhamos informações pessoais para publicidade comportamental entre contextos. Não coletamos informações pessoais conforme definido pelo CCPA/CPRA.

### 10.3 Direitos sob Outras Leis Estaduais dos EUA (VCDPA, CPA, CTDPA, UCPA, TDPSA, OCPA, IDPA, MCDPA, FDBR, etc.)

Residentes de Virgínia, Colorado, Connecticut, Utah, Texas, Oregon, Iowa, Montana, Flórida, Tennessee, Indiana, Delaware, Nova Jersey e outros estados dos EUA com legislação de privacidade têm direitos de acesso, exclusão, correção e de optar por não participar de publicidade direcionada / venda / criação de perfil. Esses direitos são atendidos por nossa política de coleta zero.

### 10.4 Direitos sob PIPEDA e Leis Provinciais (Canadá)

Residentes canadenses têm o direito de acesso, contestar a precisão, retirar o consentimento e reclamar ao Office of the Privacy Commissioner of Canada (ou autoridades provinciais em Quebec, Colúmbia Britânica, Alberta).

### 10.5 Direitos sob o Australian Privacy Act

Residentes australianos têm o direito de acessar e corrigir suas informações pessoais e de reclamar ao Office of the Australian Information Commissioner (OAIC).

### 10.6 Direitos sob a LGPD (Brasil)

Residentes brasileiros têm o direito de confirmação do tratamento, acesso, correção, anonimização, portabilidade, informação sobre compartilhamento e revogação do consentimento. Reclamações podem ser direcionadas à Autoridade Nacional de Proteção de Dados (ANPD).

### 10.7 Direitos sob a APPI (Japão)

Residentes japoneses têm o direito de divulgação, correção, exclusão e cessação de uso. Reclamações podem ser direcionadas à Personal Information Protection Commission (PPC).

### 10.8 Direitos sob a PIPA (Coreia do Sul)

Residentes sul-coreanos têm o direito de acessar, corrigir, excluir, suspender o tratamento e reclamar danos. Reclamações podem ser direcionadas à Personal Information Protection Commission (PIPC).

### 10.9 Direitos sob a PDPA (Singapura / Tailândia)

Residentes têm o direito de acessar, corrigir e retirar o consentimento. Reclamações podem ser direcionadas à Personal Data Protection Commission (PDPC) do respectivo país.

### 10.10 Direitos sob a PIPL (China)

Residentes chineses têm o direito de saber, decidir, restringir, recusar, acessar, copiar, portar, corrigir, excluir e exigir explicação sobre as regras de tratamento.

### 10.11 Direitos sob o DPDP Act (Índia)

Residentes indianos têm o direito à informação, correção, apagamento, reparação de queixas e nomeação.

### 10.12 Direitos sob a POPIA (África do Sul)

Residentes sul-africanos têm o direito de acesso, correção, exclusão e reclamação ao Information Regulator.

### 10.13 Direitos sob a FADP Suíça

Residentes suíços têm o direito à informação, acesso, retificação, exclusão, oposição e portabilidade dos dados. Reclamações podem ser direcionadas ao Federal Data Protection and Information Commissioner (FDPIC).

### 10.14 Direitos sob o NZ Privacy Act

Residentes da Nova Zelândia têm o direito de acessar e corrigir informações pessoais e de reclamar ao Privacy Commissioner.

### 10.15 Como Exercer Seus Direitos

Como não mantemos dados sobre você, esses direitos são atendidos por padrão. Se você acredita que mantemos dados pessoais sobre você apesar desta Política, entre em contato com moin@berger-rosenstock.de.

---

## 11. Privacidade Infantil

O Aplicativo possui uma classificação etária na Apple App Store de **4+** e, portanto, é tecnicamente acessível a usuários de todas as idades. No entanto, o Aplicativo é uma ferramenta de gerenciamento de infraestrutura técnica destinada a administradores de contas da Civo Cloud. Uma conta da Civo Cloud exige que o titular da conta tenha a idade legal para contratos em sua jurisdição.

**Não coletamos intencionalmente informações pessoais de ninguém, incluindo crianças menores de 13 anos (COPPA, EUA), 16 anos (GDPR-K, UE) ou a idade aplicável de consentimento em sua jurisdição.**

Como o Aplicativo implementa uma política estrita de coleta zero (consulte a Seção 2), nenhuma informação pessoal sobre qualquer usuário — independentemente da idade — é coletada, transmitida, armazenada em nossos servidores ou compartilhada com terceiros. Isso atende:

- **COPPA** (Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506, EUA)
- **Art. 8 GDPR** (UE)
- **PIPEDA** e leis provinciais aplicáveis (Canadá)
- **Art. 14 LGPD** (Brasil)
- **APPI** (Japão)
- **Australian Privacy Act** e AAP 8 sobre privacidade infantil

Se você for pai, mãe ou responsável e acredita que seu filho forneceu informações pessoais, entre em contato com moin@berger-rosenstock.de. Investigaremos prontamente e excluiremos tais informações quando encontradas.

---

## 12. Cookies e Rastreamento

O Aplicativo é um aplicativo nativo do macOS e não usa cookies, web beacons, pixel tags, fingerprinting ou tecnologias de rastreamento similares.

O Aplicativo não contém quaisquer webviews incorporadas que carreguem conteúdo de terceiros.

---

## 13. Tomada de Decisão Automatizada

Não nos envolvemos em tomada de decisão automatizada ou criação de perfis que produzam efeitos jurídicos ou afetem você de forma similarmente significativa. O Aplicativo não realiza decisões automatizadas com base em dados pessoais.

---

## 14. Links e Serviços de Terceiros

O Aplicativo pode conter links para sites de terceiros (por exemplo, site da Civo, Apple App Store, plataforma de Resolução de Litígios Online). Não somos responsáveis pelas práticas de privacidade ou conteúdo de serviços de terceiros. Revise as políticas de privacidade deles antes de fornecer dados.

---

## 15. Alterações nesta Política

Podemos atualizar esta Política de Privacidade periodicamente.

- Alterações materiais serão comunicadas através do Aplicativo ou da listagem na App Store pelo menos 30 dias antes de entrarem em vigor
- A "Data de Vigência" no topo reflete a revisão mais recente
- Não alteraremos retroativamente nossas práticas de privacidade para coletar dados sem obter seu consentimento explícito

---

## 16. Contato

Para consultas relacionadas à privacidade ou para exercer seus direitos:

**Berger & Rosenstock GbR**
Marcel R. G. Berger, Jasmin Rosenstock
Dieselstraße 22e
61231 Bad Nauheim
Alemanha
E-mail: moin@berger-rosenstock.de

Para residentes da UE, você também pode entrar em contato com a autoridade supervisora competente em seu Estado-Membro. Uma lista de autoridades supervisoras da UE está disponível em: https://edpb.europa.eu/about-edpb/board/members_en

Para residentes do Reino Unido, a autoridade supervisora é o Information Commissioner's Office (ICO): https://ico.org.uk

---

## 17. Disposições Regionais

### 17.1 União Europeia / Espaço Econômico Europeu

- A operação está em conformidade com o GDPR, quando aplicável ao tratamento local em seu dispositivo
- A autoridade supervisora do controlador de dados é a autoridade estadual alemã de proteção de dados competente
- Avaliações de Impacto sobre a Proteção de Dados (DPIAs) não são exigidas (sem coleta)

### 17.2 Alemanha

- Conformidade com o GDPR e a Bundesdatenschutzgesetz (BDSG)
- Autoridade supervisora competente: a Landesbeauftragte für Datenschutz do respectivo estado federal (o controlador reside na Alemanha)

### 17.3 Áustria

- Conformidade com o GDPR e a Datenschutzgesetz (DSG)
- Autoridade supervisora: Datenschutzbehörde (DSB)

### 17.4 Suíça

- Conformidade com a Lei Federal revisada de Proteção de Dados (revDSG), em vigor desde 1º de setembro de 2023
- Autoridade supervisora: Eidgenössischer Datenschutz- und Öffentlichkeitsbeauftragter (EDÖB)

### 17.5 Reino Unido

- Conformidade com o UK GDPR e Data Protection Act 2018
- Autoridade supervisora: Information Commissioner's Office (ICO)

### 17.6 França

- Conformidade com o GDPR e a Loi Informatique et Libertés
- Autoridade supervisora: Commission Nationale de l'Informatique et des Libertés (CNIL)

### 17.7 Itália

- Conformidade com o GDPR e o Codice in materia di protezione dei dati personali
- Autoridade supervisora: Garante per la Protezione dei Dati Personali

### 17.8 Espanha

- Conformidade com o GDPR e a Ley Orgánica 3/2018 (LOPDGDD)
- Autoridade supervisora: Agencia Española de Protección de Datos (AEPD)

### 17.9 Países Baixos

- Conformidade com o GDPR e a Uitvoeringswet AVG (UAVG)
- Autoridade supervisora: Autoriteit Persoonsgegevens (AP)

### 17.10 Polônia

- Conformidade com o GDPR e a Ustawa o ochronie danych osobowych
- Autoridade supervisora: Urząd Ochrony Danych Osobowych (UODO)

### 17.11 Portugal

- Conformidade com o GDPR e a Lei n.º 58/2019
- Autoridade supervisora: Comissão Nacional de Proteção de Dados (CNPD)

### 17.12 Bélgica

- Conformidade com o GDPR e a Loi du 30 juillet 2018
- Autoridade supervisora: Gegevensbeschermingsautoriteit (APD-GBA)

### 17.13 Irlanda

- Conformidade com o GDPR e Data Protection Act 2018
- Autoridade supervisora: Data Protection Commission (DPC)

### 17.14 Países Nórdicos (Dinamarca, Finlândia, Noruega, Suécia, Islândia)

- Conformidade com o GDPR (e equivalentes do EEE para Noruega e Islândia)
- Autoridades supervisoras nacionais: Datatilsynet (DK, NO), Tietosuojavaltuutettu (FI), Integritetsskyddsmyndigheten (SE), Persónuvernd (IS)

### 17.15 Outros Estados-Membros da UE/EEE

Conformidade com o GDPR e a respectiva implementação nacional. Listagens de autoridades supervisoras: https://edpb.europa.eu/about-edpb/board/members_en

### 17.16 Estados Unidos

- Conformidade com leis estaduais de privacidade aplicáveis: CCPA/CPRA (Califórnia), VCDPA (Virgínia), CPA (Colorado), CTDPA (Connecticut), UCPA (Utah), TDPSA (Texas), OCPA (Oregon), IDPA (Iowa), MCDPA (Montana), FDBR (Flórida), TIPA (Tennessee), INDPA (Indiana), DPDPA (Delaware), NJDPA (Nova Jersey)
- Sinais "Do Not Track" e "Global Privacy Control" são respeitados quando tecnicamente viável (o Aplicativo não rastreia)
- Conformidade com COPPA para usuários menores de 13 anos

### 17.17 Canadá

- Conformidade com PIPEDA e leis provinciais aplicáveis: Quebec Act 25, British Columbia PIPA, Alberta PIPA
- Reclamações: Office of the Privacy Commissioner of Canada (OPC) e autoridades provinciais

### 17.18 México

- Conformidade com a Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)
- Autoridade supervisora: Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)

### 17.19 Brasil

- Conformidade com a LGPD
- Autoridade supervisora: Autoridade Nacional de Proteção de Dados (ANPD)

### 17.20 Argentina, Chile, Colômbia, Peru, Uruguai

- Conformidade com leis nacionais de proteção de dados (Lei 25.326 / Lei 19.628 / Lei 1581 / Lei 29733 / Lei 18.331)

### 17.21 Austrália

- Conformidade com o Privacy Act 1988 e Australian Privacy Principles (APPs)
- Autoridade supervisora: Office of the Australian Information Commissioner (OAIC)

### 17.22 Nova Zelândia

- Conformidade com o Privacy Act 2020
- Autoridade supervisora: Office of the Privacy Commissioner

### 17.23 Japão

- Conformidade com o Act on the Protection of Personal Information (APPI)
- Autoridade supervisora: Personal Information Protection Commission (PPC)

### 17.24 Coreia do Sul

- Conformidade com o Personal Information Protection Act (PIPA)
- Autoridade supervisora: Personal Information Protection Commission (PIPC)

### 17.25 Singapura

- Conformidade com o Personal Data Protection Act (PDPA)
- Autoridade supervisora: Personal Data Protection Commission (PDPC)

### 17.26 Tailândia

- Conformidade com o Personal Data Protection Act B.E. 2562 (2019)
- Autoridade supervisora: Personal Data Protection Committee

### 17.27 China

- Conformidade com a Personal Information Protection Law (PIPL), Cybersecurity Law (CSL) e Data Security Law (DSL)

### 17.28 Hong Kong

- Conformidade com a Personal Data (Privacy) Ordinance (PDPO)
- Autoridade supervisora: Office of the Privacy Commissioner for Personal Data (PCPD)

### 17.29 Índia

- Conformidade com o Digital Personal Data Protection Act 2023 (DPDP Act) e o Information Technology Act 2000
- Autoridade supervisora: Data Protection Board of India

### 17.30 Emirados Árabes Unidos

- Conformidade com o Federal Decree-Law No. 45 of 2021 (Personal Data Protection Law)

### 17.31 Arábia Saudita

- Conformidade com a Personal Data Protection Law (PDPL)

### 17.32 Turquia

- Conformidade com a Personal Data Protection Law No. 6698 (KVKK)
- Autoridade supervisora: Kişisel Verileri Koruma Kurulu (KVKK)

### 17.33 Israel

- Conformidade com a Privacy Protection Law, 5741-1981 e Privacy Protection Regulations
- Autoridade supervisora: Privacy Protection Authority (PPA)

### 17.34 África do Sul

- Conformidade com o Protection of Personal Information Act (POPIA)
- Autoridade supervisora: Information Regulator

### 17.35 Quênia, Nigéria, Egito, Marrocos

- Conformidade com leis nacionais de proteção de dados (Data Protection Act 2019 Quênia, NDPR / NDPA Nigéria, Lei nº 151 de 2020 Egito, Lei 09-08 Marrocos)

### 17.36 Outras Jurisdições

Para usuários em jurisdições não especificamente listadas acima, a abordagem de coleta zero do Aplicativo garante conformidade com os princípios de minimização de dados e limitação de finalidade comuns às estruturas modernas de privacidade. Caso sua lei local forneça direitos adicionais, esses direitos são respeitados.

---

© 2025–2026 Marcel R. G. Berger / Berger & Rosenstock GbR. Todos os direitos reservados.
