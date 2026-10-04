# Contas gestoras no Business

Data: 03/10/2026. Estado: especificação aprovada pelo usuário com “prossiga”; [plano de implementação](../plans/2026-10-03-contas-gestoras.md) pronto para revisão; funcionalidade ainda não implementada.

## 1. Objetivo e decisões de produto

Permitir que agências, ticketeiras e outros prestadores gerenciem várias contas de clientes com os logins individuais de sua equipe. Reutilizar a seleção de conta do Business, acrescentando uma relação explícita entre a empresa gestora e cada cliente.

O usuário pediu criação de contas pela agência e entrada em contas existentes por convite. Em 03/10/2026 autorizou prosseguir com o desenho recomendado e depois aprovou esta especificação. O aceite do titular pode ocorrer depois da criação: a agência inicia o cadastro e passa a operar quando cumpridas as aprovações normais da plataforma. Criar pela agência não aprova automaticamente conta, evento, anúncio ou crédito.

Uma conta gestora continua sendo uma conta Business. Agência, Ticketeira e Outros são classificações da empresa. A habilitação para gerenciar clientes é uma capacidade separada, ativada por um administrador interno em uma conta ativa; escolher um tipo no cadastro público não concede essa capacidade.

Cada cliente conserva conta, titularidade, dados, campanhas, créditos e cobranças próprios. Um cliente pode contratar mais de uma gestora. Cada pessoa continua identificada pelo login verificado; nenhuma operação troca sua identidade pela de um usuário do cliente.

## 2. Base existente e limites observados

Leitura estática do checkout local; não representa validação do estado de produção.

| Área | Evidência no código atual | Consequência para a proposta |
| --- | --- | --- |
| Vínculos e seleção | `includes/backend/business_account_context.cfm` consulta `tb_conta_usuarios`, valida vínculo ativo e permite trocar a conta | Reutilizar seletor e contexto, incluindo acessos delegados |
| Simulação interna | O mesmo include define `OWNER` para a conta simulada por admin | Não usar essa atribuição para conceder acesso a parceiros |
| Permissões | `includes/backend/business_permissions.cfm` consulta capacidades por conta e papel | Reutilizar o catálogo; acrescentar concessões por relação e por funcionário |
| Convites de pessoas | `administracao/contas/includes/backend.cfm`, ação `convidar`, grava vínculo `ATIVO` e aceite imediato | Novo fluxo entre empresas deve ter aceite explícito; não apresentar o fluxo legado como se já o tivesse |
| Cadastro | `cadastro/includes/backend.cfm` já oferece `Agencia` e cria solicitações de aprovação | Aproveitar validações cadastrais; separar solicitante, gestora e titular |
| Dados legados | O contexto reúne IDs de usuários e páginas da conta; `backend_login.cfm` deriva permissões de BI desses usuários | Acesso delegado não pode herdar automaticamente essa união de permissões |
| Publicidade | `ads/includes/access.cfm` separa campanha, compra de crédito, pagamentos e poderes internos | Inserir as permissões delegadas nessa fronteira e validar também endpoints e funções de banco |
| Formulários de banners | `portal/includes/paid_banner_backend.cfm` já vincula CSRF ao ator e à conta | Estender o vínculo ao modo de acesso e à relação gestora–cliente |
| Login | `business_google_callback.cfm` e `backend_login.cfm` encaminham pessoas sem conta para cadastro | Aceite por titular ainda sem vínculo precisa de uma rota autenticada própria |

Há alterações preexistentes de outras frentes em login, navegação, eventos, publicidade e banners. Implementação e publicação devem preservar esses diffs e comparar a versão efetiva de cada arquivo; este documento não os altera.

## 3. Alternativas e escolha

1. Vincular cada funcionário diretamente a cada cliente: aproveita os vínculos atuais, mas dispersa convites, manutenção e revogação. A saída de um funcionário exige administrar cada cliente e não expressa a contratação de uma empresa.
2. **Conta gestora com relações explícitas: escolha recomendada.** Cada cliente concede acesso à gestora, que distribui esse acesso entre funcionários. Permite revogar a relação inteira e atribuir ações à pessoa e à empresa.
3. Criar uma flag global de usuário-agência e adaptar a simulação administrativa: não adotado, porque uma classificação pessoal não define quais clientes, módulos e ações foram autorizados.

## 4. Escopo da primeira entrega

Entregar um fluxo completo de conta gestora, cadastro de clientes, convite/solicitação de vínculo, aceite de titular, atribuição de equipe, troca de conta, revogação e histórico.

Integrar inicialmente os módulos de Publicidade (`/ads/` e banners pagos) e Eventos: listagem, edição autorizada e solicitações de vínculo existentes. No produto, os acessos aparecem como ações compreensíveis, por exemplo “Consultar campanhas”, “Gerenciar campanhas”, “Consultar eventos” e “Editar eventos”.

Compra de créditos e consulta de pagamentos têm concessões separadas, desmarcadas por padrão. Gerenciar campanhas permite propor orçamento e consumir o saldo do cliente conforme as regras e aprovações atuais; esse efeito deve estar explicado no convite. Créditos, pagamentos e lançamentos permanecem na conta do cliente.

BI legado, CRM, inscrições, cupons, importações, saúde e módulos administrativos globais não são liberados pelo vínculo de gestora nesta primeira entrega. No contexto delegado, seus caminhos são negados no servidor. A classificação Ticketeira não concede poderes sobre esses módulos. Essa limitação deve aparecer na interface de acessos, sem controles que prometam capacidades ainda não integradas.

São evoluções posteriores: relatórios consolidados de todos os clientes, faturamento da agência, comissões, carteira compartilhada, revenda de créditos, integrações externas adicionais e delegação entre gestoras. Nenhuma delas é necessária para o primeiro fluxo completo.

## 5. Fluxos de negócio

### 5.1 Habilitar a gestora e administrar sua equipe

Um admin interno habilita uma conta ativa como gestora e informa sua classificação. Os membros diretos `OWNER` e `ADMIN` dessa conta administram carteira, convites e atribuições. Usuários `OPERADOR` e `VISUALIZADOR` acessam somente clientes atribuídos; o papel médico não confere acesso delegado.

A equipe continua em `tb_conta_usuarios` da gestora. A atribuição a clientes não cria vínculos diretos adicionais em `tb_conta_usuarios` do cliente. Isso evita que permissões concedidas pela gestora sobrevivam à revogação da relação ou à saída de um funcionário.

Gestores podem distribuir somente capacidades autorizadas pelo cliente. A condição de gestor da agência permite administrar a relação, mas o acesso aos dados de um cliente exige atribuição individual. Ao aceitar/criar uma relação, o gestor responsável recebe a atribuição inicial, limitada ao que foi concedido. Os demais precisam ser atribuídos explicitamente.

### 5.2 Criar cliente

Um gestor informa os dados cadastrais obrigatórios da conta, contato do titular e o conjunto de acessos pretendidos. A validação de documento é a mesma do cadastro Business; normalização e unicidade são conferidas também na transação de gravação.

Se o documento já estiver cadastrado, nenhuma conta ou relação ativa é criada automaticamente. O fluxo orienta solicitar acesso, sem revelar dados privados de uma conta encontrada.

Para um cliente novo, uma transação cria a conta `PENDENTE`, a solicitação para revisão interna, o registro de criação pela gestora e a relação aguardando aprovação da conta. O solicitante é a pessoa real da agência; ela não é gravada como `OWNER` do cliente. Antes da aprovação, a agência consulta e complementa o cadastro, mas não recebe acesso operacional aos módulos.

A aprovação interna torna a conta ativa e habilita a relação inicial com as capacidades aprovadas. O revisor vê que se trata de criação por gestora e quais capacidades serão concedidas. Não são emitidos vouchers, créditos ou benefícios automáticos por esse fluxo.

A conta pode operar sem o aceite do titular, enquanto exibe “Titular ainda não confirmado”. O titular indicado recebe um convite que pode ser gerado no cadastro ou depois. A agência pode operar dentro do acesso aprovado, mas não pode se tornar titular, transferir a conta ou excluir seus dados por meio dessa relação.

### 5.3 Aceite do titular

O destinatário autentica com o e-mail verificado do convite, consulta os dados da conta e a gestora vinculada, e confirma o aceite. A transação valida convite, destinatário, conta, versão e ausência de um titular confirmado; em seguida cria seu vínculo direto `OWNER` e registra o evento.

O aceite não aprova uma conta ainda pendente e não transfere contas que já têm titular. O titular pode manter, restringir ou revogar a gestora. Correção do destinatário antes do aceite revoga o convite anterior; reenviar não reativa tokens antigos. Conta sem titular confirmado que perde a gestora fica disponível à gestão interna para regularização, com histórico preservado.

### 5.4 Cliente existente convida a gestora

O `OWNER` direto do cliente escolhe uma gestora habilitada por identificador exato e seleciona capacidades. O convite fica pendente e não libera dados. Um `OWNER` ou `ADMIN` direto da gestora aceita o conjunto apresentado; o aceite ativa a relação e atribui o responsável inicial.

O cliente confirma qual empresa está convidando. A busca não fornece um diretório de clientes nem expõe contatos internos. Usuários com acesso apenas delegado não podem convidar outra gestora em nome do cliente.

### 5.5 Gestora solicita acesso

O gestor informa um identificador exato fornecido pelo cliente e as capacidades solicitadas. O sistema registra a solicitação e apresenta uma resposta que não permite enumerar contas por documento. A solicitação aparece para o `OWNER` direto do cliente.

O titular pode aprovar o conjunto solicitado ou reduzi-lo; nunca ampliar silenciosamente o pedido. Aprovar ativa a relação com esse conjunto, pois a gestora já manifestou aceite ao solicitar. Recusar ou cancelar mantém acesso inexistente. Repetições retornam a solicitação pendente existente, sem criar pedidos duplicados.

### 5.6 Mudar permissões e encerrar a relação

O titular pode reduzir acessos ou revogar a gestora. A gestora pode renunciar à relação; o admin interno pode suspendê-la. Ampliações de acesso exigem novo aceite da outra parte. Durante uma ampliação pendente, continuam valendo apenas as concessões já ativas.

Revogar a relação elimina o acesso delegado de toda a equipe a partir da próxima requisição, inclusive em sessão aberta. Suspender a gestora, suspender o cliente ou desativar um funcionário também invalida o acesso correspondente. Reativação após revogação exige novo aceite e novas atribuições; não restaura permissões antigas silenciosamente.

Vínculos diretos de uma pessoa com o cliente são independentes. Caso existam, a pessoa pode voltar a entrar pelo seu acesso direto, identificado separadamente; revogar a agência não apaga esses vínculos.

## 6. Interface e navegação

A gestão da agência terá rota própria `/gestao-clientes/`, com abas **Clientes**, **Equipe**, **Convites** e **Histórico**. A gestão do cliente acrescenta a aba **Gestoras** em `/administracao/contas/`. A separação evita ampliar ainda mais os arquivos atuais de contas.

As abas preservam filtros, paginação e links diretos em query string. Devem ter foco visível, navegação por teclado e funcionamento básico sem JavaScript. Convites recebidos e enviados são filtros dentro da aba Convites. Clientes mostram estado da conta, vínculo, titular pendente e acessos disponíveis.

O seletor existente distingue “Acesso direto” e “Via Agência X”. Uma pessoa com mais de um caminho para o mesmo cliente escolhe explicitamente qual usar; as permissões não são somadas. O cabeçalho mostra o cliente ativo e, quando aplicável, a gestora. O botão para retornar à carteira permanece disponível.

Aceites são feitos em uma rota `/convites/` acessível após autenticação mesmo para quem ainda não possui conta Business. Essa exceção autoriza apenas consultar/aceitar o próprio convite, sem liberar o restante do Business. Links usam tokens opacos; o destino após login é local e validado no servidor.

Avisos na interface são parte da entrega. Um link de convite pode ser copiado para compartilhamento. E-mail utiliza apenas a infraestrutura transacional já aprovada, se configurada; falha no envio mantém o convite pendente e disponível para copiar/reenviar, sem simular sucesso. Testes usam transporte isolado e não enviam mensagens reais a clientes.

## 7. Modelo de dados proposto

Modelo lógico para uma migração aditiva; os nomes abaixo orientam o plano de implementação.

| Entidade | Conteúdo e invariantes |
| --- | --- |
| `tb_conta_gestoras` | Uma configuração por `id_conta`: classificação, habilitação, autor e datas. Não altera flags globais dos usuários |
| `tb_conta_gestao_vinculos` | Gestora, cliente, origem, estado, solicitante, aprovadores, versão e datas. Uma relação por par; auto-vínculo proibido; sem concessão transitiva |
| `tb_conta_gestao_permissoes` | Capacidades ativas da relação, referenciando `tb_business_permissoes`; unicidade por relação/capacidade |
| `tb_conta_gestao_equipe` | Relação, vínculo direto do funcionário na gestora, estado e versão; unicidade por relação/membro |
| `tb_conta_gestao_equipe_permissoes` | Subconjunto atribuído ao funcionário. Uma capacidade removida da relação nunca permanece efetiva na equipe |
| `tb_conta_gestao_convites` | Tipo (relação, ampliação ou titular), destinatário, relação/conta, capacidades propostas, hash do token, expiração, estado e autor. Um convite de titular vigente por conta |
| `tb_conta_gestao_auditoria` | Ator real, gestora, cliente, relação, ação, recurso, resultado, alterações relevantes e data; sem tokens ou credenciais |

As solicitações de criação continuam ligadas a `tb_conta_cadastro_solicitacoes`, com referência explícita à gestora e à origem do pedido. O estado “titular ainda não confirmado” é calculado pelo registro de criação e ausência de `OWNER` confirmado, não pelo simples fato de o cliente ter uma agência.

Estados da relação: `AGUARDANDO_CONTA`, `PENDENTE_CLIENTE`, `PENDENTE_GESTORA`, `ATIVO`, `SUSPENSO`, `RECUSADO` e `REVOGADO`. Convites usam `PENDENTE`, `ACEITO`, `RECUSADO`, `CANCELADO` e `EXPIRADO`. Suspensão administrativa exige reativação explícita; revogação exige novo ciclo de consentimento.

Convites expiram em sete dias, usam token aleatório de alta entropia e armazenam somente o hash. Aceite é de uso único e atômico. O servidor verifica a expiração em cada acesso, independentemente de qualquer job. Operações concorrentes usam bloqueio das linhas relevantes e versão esperada para impedir dupla criação, duplo aceite e reativação de vínculo revogado.

Não copiar membros para contas de clientes, não conceder `is_admin`, `is_dev` ou `is_partner` e não mudar o enum dos papéis para representar Agência. Integridade por FKs, índices e constraints segue o padrão PostgreSQL do projeto.

## 8. Autorização e contexto

Um serviço dedicado resolve o acesso a partir da identidade verificada e do caminho selecionado: direto, delegado ou simulação interna. A sessão armazena a seleção; o banco determina se ela ainda é válida em cada requisição.

No acesso delegado, a autorização é a interseção de:

1. Pessoa ativa com vínculo direto ativo na gestora e papel elegível.
2. Gestora habilitada e ativa, cliente ativo e relação ativa.
3. Atribuição ativa da pessoa ao cliente.
4. Capacidade concedida pelo cliente e atribuída à pessoa.
5. Habilitação do produto e escopo do recurso no próprio cliente.

Gerenciar implica consultar dentro do mesmo módulo. O sistema não atribui `OWNER` ou `ADMIN` do cliente como atalho. As variáveis legadas de conta/papel podem ser adaptadas para compatibilidade de apresentação, mas não são prova suficiente para autorizar ações delegadas.

O contexto carrega `actorId`, `accountId`, `accessMode`, `managerAccountId`, `relationshipId` e versões das concessões. Não existe herança transitiva: gerir uma conta que também é gestora não permite entrar na carteira dela.

A fronteira de requisição resolve e valida esse contexto antes de endpoints dinâmicos executarem consultas. Para acessos delegados, há uma lista explícita de rotas e ações integradas; módulos não integrados são negados. O inventário deve cobrir páginas, handlers, downloads, endpoints remotos CFC e aplicações aninhadas que tenham ciclo próprio. Um caminho que não passa pelo guard não pode ser publicado como acessível à gestora.

Cada recurso é conferido por conta: IDs de campanha, evento, banner, cobrança e upload recebidos em URL/FORM não substituem o contexto autorizado. Não usar `businessEffectiveUserIds` ou páginas de membros como prova de propriedade de dados delegados. Consultas sem propriedade de conta comprovável permanecem indisponíveis nesse modo.

Mutações exigem POST, CSRF vinculado ao ator/conta/modo/relação, versão esperada e nova validação de autorização antes da escrita. Formulários antigos após troca de conta, revogação ou mudança de permissão falham sem gravar no cliente errado. A gravação e a auditoria da ação devem ser transacionais; para uma chamada externa, usar o padrão existente de operação identificável e resultado reconciliável.

Para revogação concorrente, o teste precisa comprovar que a mutação não confirma com uma concessão já invalidada: a checagem de versão e a escrita devem compartilhar a transação e os bloqueios adequados. Operações já confirmadas antes da revogação permanecem no histórico.

Resposta: `403` para acesso negado; `404` para recurso de outra conta sem revelar sua existência; `409` para conflito de versão ou contexto; `503` para recurso indisponível por schema/configuração incompletos. Negação nunca recai em permissões globais ou na conta anterior.

## 9. Integração por componente e responsabilidade

**Business é o dono do fluxo e das regras de delegação.** A primeira entrega não altera autenticação do RoadRunners nem o aplicativo GoRunners. O banco compartilhado recebe somente a migração necessária; contratos de publicação, revisão e cobrança de anúncios continuam os mesmos.

| Componente | Responsabilidade |
| --- | --- |
| Novo serviço `services/BusinessAccountDelegation.cfc` | Resolver relações, capacidades e atribuições; fornecer comandos transacionais e auditoria |
| `includes/backend/business_request_identity.cfm` e fronteiras remotas aplicáveis | Acrescentar resolução/guard do contexto delegado depois da identidade, sem substituir a autenticação |
| `includes/backend/business_account_context.cfm` | Integrar seleção de caminhos diretos/delegados e invalidar seleção sem acesso |
| `includes/backend/business_permissions.cfm` | Resolver a interseção de capacidades delegadas preservando o comportamento do acesso direto |
| `includes/backend/backend_login.cfm` | Consumir contexto, restringir dados auxiliares e não herdar BI legado no acesso delegado |
| `business_google_callback.cfm` e nova rota `/convites/` | Retorno autenticado para aceite do destinatário sem exigir vínculo prévio |
| `/gestao-clientes/` | Carteira, criação, equipe, solicitações, convites e histórico da gestora |
| `/administracao/contas/` | Habilitação interna, aprovação de cadastro por gestora e gestão de relações pelo titular |
| Seletor, cabeçalho e navegação | Exibir cliente/gestora, caminhos de acesso e menus coerentes com capacidades |
| `ads/includes/access.cfm`, ações Ads, pagamentos e banners pagos | Separar campanha, compra e leitura financeira; validar conta, ação e auditoria |
| `/eventos/` e seus handlers | Aplicar capacidades e vínculos de eventos por cliente em leitura e escrita |
| Migração em `_codex/sql/` e documentação operacional | Schema compatível, verificação de instalação, ativação e recuperação |

O plano deve enumerar os endpoints e contratos SQL realmente consumidos antes de modificá-los. Se uma função de banco também autorizar pelo vínculo direto, deve receber uma integração explícita da autorização delegada; não criar um falso vínculo nem substituir o ator. Alterar consumidores de outro projeto exige mapear contrato e instruções desse repositório primeiro.

## 10. Verificação e critérios de aceite

Testes comportamentais em CFML e banco PostgreSQL isolado, usando as ferramentas existentes do projeto. Verificações por busca de texto podem complementar, mas não comprovar isolamento de contas ou autorização.

- Pessoa da agência alterna entre dois clientes atribuídos, mantendo sua identidade real.
- O mesmo cliente aparece por acesso direto e por agência; selecionar um caminho não soma permissões do outro.
- Cliente com duas gestoras conserva concessões e equipes independentes.
- Agência cria cliente, a conta aguarda revisão interna, a aprovação habilita somente o conjunto revisado e o titular pode aceitar depois.
- Documento duplicado, inclusive em duas requisições concorrentes, não cria conta duplicada nem concede acesso à conta existente.
- Convite pendente, expirado, cancelado, destinatário incorreto ou segundo aceite não concede acesso.
- Pessoa sem vínculo Business consegue aceitar seu convite após login e não abre dados antes disso.
- Aprovação de solicitação limita-se ao conjunto pedido; ampliação exige novo aceite.
- Troca de conta em outra aba impede envio de formulário para o cliente errado.
- Funcionário removido, relação revogada, gestora suspensa ou cliente suspenso perde acesso em sessões existentes.
- Mutação concorrente à revogação respeita a checagem transacional; efeitos confirmados antes da revogação são auditáveis.
- Gestor não atribui capacidade ausente e funcionário não amplia o próprio acesso.
- Leitor não altera campanhas/eventos; gestor de campanhas sem permissão financeira não compra crédito nem consulta pagamentos.
- URLs, POSTs, downloads e CFCs diretos de módulos não integrados são negados no modo delegado.
- Recurso de outro cliente não vaza em tela, resposta, relatório, arquivo ou erro; acesso ao cliente não agrega permissões de BI dos seus usuários.
- Campanhas e banners preservam revisão interna, conta financeira, saldos e ator real.
- Cliente sem titular que perde a gestora permanece recuperável pelo admin interno.
- Acesso direto, simulação interna, cadastro existente, login persistente e perfil médico continuam funcionando.
- Desktop e celular: abas, filtros, paginação, teclado, foco e retorno à carteira; aceite e troca de conta funcionam sem depender exclusivamente de modal JavaScript.

Executar regressões existentes de autenticação, roteamento, solicitação de acesso, cadastro duplicado e publicidade, complementadas por testes da nova autorização. Nenhum teste funcional foi executado nesta etapa de especificação.

## 11. Publicação e recuperação

A preferência vigente autoriza publicar o runtime ao concluir a implementação verificada, sem nova confirmação de publicação. Este documento não é runtime e sua criação não instala o recurso.

1. Conferir baseline de produção e alterações concorrentes; preparar backup recuperável dos arquivos que serão substituídos e dos objetos de banco alterados.
2. Validar a migração em banco isolado e manter contas gestoras desabilitadas por padrão. A migração é aditiva e não altera permissões de usuários, roles de banco ou credenciais; privilégios ausentes devem ser tratados como bloqueio de implantação.
3. Aplicar schema pelo mecanismo autorizado existente. Código antigo deve continuar funcionando com o schema novo.
4. Publicar somente arquivos da tarefa a partir do baseline revisado, preservando mudanças de outras frentes.
5. Validar no ambiente real login, seleção, negações por URL, convites e isolamento com contas de homologação autorizadas. Nenhuma campanha, compra, disparo ou titularidade de cliente real deve ser alterada para testar.
6. Habilitar a capacidade de gestora apenas para as contas deliberadamente selecionadas. Não habilitar automaticamente contas classificadas como Agência no histórico.
7. Verificar resultado real, hashes e logs, registrando limitações e evidências antes de declarar publicação concluída.

Rollback: desabilitar o recurso de delegação, impedir seleção e execução de contextos delegados, invalidar essas seleções e restaurar arquivos do backup compatível. Preservar relações, auditoria, contas e dados criados; não executar migração destrutiva. Acesso direto existente deve continuar funcional. Falta de schema ou erro ao resolver uma relação nega o acesso delegado.

Não criar branch, commit, tag, push ou PR sem solicitação específica.

## 12. Revisão desta proposta

Decisões aprovadas: habilitação interna da gestora; operação do cliente após a aprovação normal da plataforma, com titular aceitando depois; atribuição individual da equipe; concessões por ação; primeira integração limitada a Publicidade e Eventos; preservação das contas e dos vínculos diretos existentes.

Após revisão do documento, produzir o plano de implementação com inventário de endpoints, migração, testes e sequência de publicação. O recurso só estará concluído após implementação, validações e confirmação do funcionamento em produção.
