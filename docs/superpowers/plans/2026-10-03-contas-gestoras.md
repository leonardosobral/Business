# Contas gestoras — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar criação e gestão de clientes por agências/ticketeiras, com equipe, convites, permissões, operação de Publicidade/Eventos e publicação verificada.

**Architecture:** Reutilizar contas, identidade e seleção de contexto. Um serviço de delegação resolve relações e capacidades no servidor; módulos existentes consomem esse contexto e validam novamente suas ações. A relação gestora–cliente e suas atribuições são independentes dos vínculos diretos do cliente.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL, templates MDBootstrap; Node e Python para as ferramentas locais de teste/publicação existentes. Sem novo framework ou dependência de produto.

**Spec:** [2026-10-03-contas-gestoras-design.md](../specs/2026-10-03-contas-gestoras-design.md), aprovada pelo usuário em 03/10/2026.

Estado deste plano: aprovado para execução com subagentes pelo usuário em 03/10/2026. Implementação em andamento; progresso e evidências no ledger da tarefa.

## Global Constraints

- “Cada cliente conserva conta, titularidade, dados, campanhas, créditos e cobranças próprios.”
- “Criar pela agência não aprova automaticamente conta, evento, anúncio ou crédito.”
- “Não copiar membros para contas de clientes, não conceder `is_admin`, `is_dev` ou `is_partner` e não mudar o enum dos papéis para representar Agência.”
- “Convites expiram em sete dias, usam token aleatório de alta entropia e armazenam somente o hash.”
- “As abas preservam filtros, paginação e links diretos em query string.”
- “As variáveis legadas de conta/papel podem ser adaptadas para compatibilidade de apresentação, mas não são prova suficiente para autorizar ações delegadas.”
- “Negação nunca recai em permissões globais ou na conta anterior.”
- “Nenhuma campanha, compra, disparo ou titularidade de cliente real deve ser alterada para testar.”
- “Não criar branch, commit, tag, push ou PR sem solicitação específica.” As etapas de commit sugeridas genericamente por skills são substituídas por revisão do diff local.
- Preservar os 17 arquivos rastreados já modificados e os arquivos novos de outras frentes, conferindo novamente o status antes da execução. Não copiar um checkout inteiro para produção.
- Publicar o runtime aprovado e verificado ao final, com baseline e backup; não pedir novamente confirmação de publicação. Acesso ausente, conflito ou privilégio de banco insuficiente é bloqueio, não autorização para alterar credenciais/roles.

## Review Focus

1. Mesma pessoa com acesso direto e por duas gestoras ao mesmo cliente: seleção explícita, sem somar poderes nem trocar silenciosamente de caminho; testes nas tarefas 2 e 5.
2. Parâmetros duplicados, arrays em campos escalares, `PATH_INFO`, aliases e CFC remoto: nenhuma rota ou ação equivalente contorna a autorização; testes nas tarefas 5 e 11.
3. Convite expirando exatamente no limite, e-mail com caixa/espaços e alteração concorrente do titular: relógio UTC, identidade verificada e aceite único; testes nas tarefas 3 e 4.
4. Remover e depois recriar um funcionário, ou reativar uma relação revogada: atribuições antigas não ressuscitam; testes nas tarefas 2, 3 e 11.
5. Timeout depois de confirmação no banco ou no provedor, inclusive upload: retentativa não duplica efeito, não apaga arquivo possivelmente utilizado e não relata uma falha como sucesso; testes nas tarefas 8 e 9.

---

## Fronteiras, arquivos e contratos comuns

O escopo é um único fluxo de acesso delegado com adaptadores de dois módulos. As tarefas se integram sequencialmente; não são subsistemas independentes publicáveis com acesso já habilitado. A implantação só habilita delegação após a integração completa.

### Propriedade e estrutura

**Business:** regras de delegação, tabelas de relacionamento, migração de compatibilidade com Ads, telas, guards, testes e publicação. **RoadRunners:** fonte consultada das funções canônicas de Ads e regressões de veiculação; nenhum arquivo desse repositório é alvo de edição/publicação neste plano. **GoRunners:** sem alteração.

Não alterar migrations históricas. A nova migration do Business mantém assinaturas públicas das funções Ads existentes; qualquer necessidade de alterar produtores/consumidores externos exige atualizar esse limite antes da execução correspondente.

| Arquivo novo | Responsabilidade |
| --- | --- |
| `services/BusinessAccountDelegation.cfc` | Fachada dos métodos listados abaixo; acesso, consulta e transação autorizada |
| `services/accountDelegation/Store.cfc` | Consultas parametrizadas, locks, versões, escopo e auditoria |
| `services/accountDelegation/Policy.cfc` | Catálogo de capacidades, política por rota/ação, normalização e token de formulário |
| `services/accountDelegation/Invitations.cfc` | Ciclo dos convites, alterações de relação e distribuição de equipe |
| `services/accountDelegation/Accounts.cfc` | Criação de cliente, revisão interna e aceite de titular |
| `includes/backend/business_delegation_request.cfm` | Guard inicial depois da identidade verificada |
| `includes/parts/business_delegation_form.cfm` | Campos ocultos do contexto esperado e CSRF |
| `gestao-clientes/index.cfm`, `home.cfm`, `includes/backend.cfm`, `includes/clients.cfm`, `includes/team.cfm`, `includes/invites.cfm`, `includes/history.cfm` | Carteira e suas quatro abas, no padrão de páginas do projeto |
| `convites/index.cfm`, `home.cfm`, `includes/backend.cfm` | Recepção e aceite após login, sem acesso prévio ao Business |
| `administracao/contas/includes/delegation_backend.cfm`, `delegation_home.cfm` | Habilitação, fila de criação por gestora e aba Gestoras |
| `includes/estrutura/home_delegated_account.cfm` | Home restrita a atalhos e dados autorizados do cliente |
| `assets/css/account-delegation.css` | Layout responsivo; abas navegáveis por links, sem novo framework |
| `_codex/sql/2026-10-03_business_account_delegation.sql` | Estrutura aditiva e capacidades |
| `_codex/sql/2026-10-03_business_account_delegation_ads.sql` | Compatibilidade transacional da autorização com banners pagos |
| `_codex/scripts/test_account_delegation.mjs` | Harness isolado CFML/PostgreSQL e suítes por argumento |
| `_codex/scripts/deploy_account_delegation.py` | Adaptador do publicador existente com allowlist da tarefa |
| `_codex/scripts/account_delegation_database.py` | Preflight/backup/aplicação/verificação do pacote SQL autorizado |
| `_codex/docs/2026-10-03_contas_gestoras_operacao.md` | Operação, instalação, evidências, limitações e recuperação |

Os arquivos existentes a alterar estão discriminados em cada tarefa. Testes novos ficam em `_codex/tests/account-delegation/`; seus nomes são definidos abaixo. Todo código de serviço tem acesso público apenas dentro da aplicação, sem métodos CFML `remote`.

### Tipos e interfaces compartilhados

Nomes de campos abaixo são o contrato entre tarefas; structs CFML não exigem classes adicionais.

- `Identity`: `{id, email, emailVerified}` proveniente exclusivamente da sessão verificada; o adaptador preenche `emailVerified` a partir da evidência de autenticação existente, nunca de FORM/URL.
- `Selection`: `{accountId, accessMode, managerAccountId, relationshipId}`; modos `DIRECT`, `DELEGATED`, `INTERNAL_SIMULATION`. O último é reservado à simulação interna atual.
- `VersionStamp`: `{managerVersion, relationshipVersion, assignmentVersion, membershipId}`. Alterações de concessões incrementam a versão correspondente. `membershipId` é a PK do vínculo direto na gestora.
- `Context`: `{actorId, accountId, accessMode, managerAccountId, relationshipId, versions, capabilities, selectionKey}`. IDs ausentes usam `0`; capacidades são array de códigos; nenhuma flag enviada pelo navegador preenche poderes internos.
- `AccessOption`: `{selection, selectionKey, accountName, managerName, roleLabel}`. `selectionKey` é serialização canônica opaca dos IDs/modo, não é credencial.
- `CommandResult`: `{status, id, version}`; `InviteResult` acrescenta `{inviteId, expiresAt, url}` somente na emissão/renovação. O token bruto não volta em listagens.
- `Page`: `{items, page, pageSize, total}`; `pageSize=25`, filtro limitado a 160 caracteres, ordenação fixa por nome/ID ou data/ID.
- `Resource`: `{type, id}`; tipos permitidos `RELATIONSHIP`, `ASSIGNMENT`, `INVITATION`, `ACCOUNT`, `CAMPAIGN`, `PAYMENT_INTENT`, `EVENT`, `EVENT_REQUEST`.

`expectedVersion` refere-se à relação em `decideRelationship`, `changeRelationship`, `assignMember`, `updatePendingClient`, `reviewCreatedClient` e `inviteOwner`; à atribuição em `removeAssignment`; ao convite em `acceptOwner`; à configuração da gestora em `configureManager`. Alterar equipe também incrementa a versão da relação, invalidando decisões concorrentes sobre o mesmo conjunto de acessos. Um objeto novo usa versão esperada `0` apenas nas operações que o criam.

Capacidades delegáveis exatas: `ads.campaigns.view`, `ads.campaigns.manage`, `ads.payments.view`, `ads.credits.purchase`, `events.view`, `events.manage`, `events.links.request`. Gerenciar implica consultar o mesmo módulo; solicitar vínculo implica `events.view`. Capacidades financeiras exigem `ads.campaigns.view`, mas comprar créditos não concede consulta do histórico de pagamentos. Um comprador pode consultar somente o comprovante da intenção que acabou de criar; o histórico exige `ads.payments.view`.

`OWNER`/`ADMIN` diretos da gestora distribuem equipe; `OPERADOR` recebe subconjuntos operacionais; `VISUALIZADOR` recebe somente capacidades `.view`; `MEDICO` não recebe delegação. Validar tanto a concessão quanto o papel atual em cada requisição.

### Entrada HTTP e contratos Ads inventariados

Permitir somente caminhos exatos e ações declaradas, com validação do recurso no handler. Não liberar um prefixo como `/api/` ou `/eventos/` inteiro. `GET /ads/canonical/index.cfm` redireciona ao canônico; POST nesse alias é recusado. Qualquer novo endpoint fica negado no modo delegado até ser classificado.

| Entrada | Regra no contexto delegado |
| --- | --- |
| `/`, `/index.cfm` | Home restrita da conta ativa |
| `/selecionar-conta/`, `/selecionar-conta/index.cfm` | GET e POST de seleção com CSRF; não atribuem permissão por si |
| `/gestao-clientes/`, `/gestao-clientes/index.cfm` | Carteira/equipe conforme vínculo direto na gestora; não usar poderes do cliente selecionado |
| `/convites/`, `/convites/index.cfm` | Somente o destinatário/gestor elegível; sem usar `backend_login.cfm` como condição de aceite |
| `/ads/`, `/ads/index.cfm` | Consulta, campanha e compras conforme a ação; histórico financeiro separado |
| `/portal/banners/`, `/portal/banners/index.cfm` | CPC do cliente; HOUSE, aprovação e gestão global recusados |
| `/api/ads/payments/status.cfm` | Pagamento do cliente, com regra de histórico/comprovante acima |
| `/eventos/`, `/eventos/index.cfm` | Consulta, edição operacional permitida e solicitação de vínculo |
| `/logout.cfm` e callback Google existente | Preservar autenticação/logout; nunca tratar como ação de cliente |
| `/administracao/contas/` | Disponível para gestão da própria relação somente por acesso direto elegível; recusado no modo delegado |
| BI, CRM, inscrições, cupons, saúde, importações e demais rotas dinâmicas | Negar no modo delegado, inclusive includes executados diretamente |

`bi/Application.cfc` usa a mesma aplicação/sessão e inclui a fronteira de identidade: precisa de teste próprio. CFCs remotos encontrados: `leaderboard/api/leaderboard.cfc` e `leaderboard/api/transmissao.cfc`. Negar chamadas delegadas antes de executar seus métodos; testar o ciclo real do servidor, sem presumir que `OnRequest` cobre remoting.

Jobs, webhooks e APIs com autenticação própria (`api/ads/payments/webhook.cfm`, `reconcile.cfm`, `api/event-description-rewrite.cfm`, `api/percursos/*`) não recebem autoridade por sessão de gestora. Preservar suas autenticações existentes e negar uso via contexto delegado; chamadas legítimas de máquina sem esse contexto continuam funcionando.

Contratos SQL consumidos: `ads.save_event_campaign`, `replace_campaign_placements`, `prepare_campaign_for_edit`, `submit_campaign_review`, `change_campaign_status`, `activate_campaign`; para banners, `save_paid_banner_campaign`, `submit_paid_banner_review`, `paid_banner_actor_allowed`; pagamentos, `create_payment_intent`, `attach_payment_checkout`. Preservar assinaturas, revisão de anúncios, idempotência e ledger. Revisão, concessão administrativa de créditos, estorno, criação/resgate de vouchers e funções HOUSE ficam fora das capacidades delegadas.

## Task 1 — Schema e ambiente de testes isolado

**Arquivos:** criar a migration principal, `_codex/scripts/test_account_delegation.mjs`, `_codex/tests/account-delegation/{schema.sql,fixtures.sql,assertions.cfm}`; criar `services/accountDelegation/Store.cfc`; modificar a inicialização em `Application.cfc`.

**Interfaces:** `Store.init(required string datasource) -> Store`; `schemaReady() -> boolean`. O harness aceita `--suite schema|policy|lifecycle|accounts|boundary|receiver|workspace|ads-db|ads|events|http|all`; suíte ausente/falha não é ignorada. DSN isolado: `business_delegation_test`. Helpers de teste: `assertEqual(actual,expected,label)`, `assertContains(text,fragment,label)`, `assertThrowsType(callback,type,label)`; retornam void e lançam erro em falha. `fixtures.sql` fornece IDs estáveis e consultas de contagem para os casos sintéticos.

- [ ] Escrever `schema.sql` verificando as sete entidades da especificação, estados, FKs, unicidade de par, auto-vínculo proibido e enum original de papéis intacto. Asserções SQL lançam exceção, por exemplo `IF EXISTS(SELECT 1 FROM pg_enum WHERE enumlabel='AGENCIA' AND enumtypid='papel_usuario_conta'::regtype) THEN RAISE EXCEPTION 'role leak'; END IF;`.
- [ ] Criar harness a partir dos padrões de `_codex/scripts/test_business_remember_local.sh` e `test_ads_paid_banners.mjs`: PostgreSQL temporário, bind local/socket, schema sintético, CFML sem configurações de produção, transportes de e-mail/pagamento fake. Recusar DSN de produção e encerrar todos os processos próprios no cleanup. Parâmetros de runtime: `BUSINESS_DELEGATION_PG_BIN`, `BUSINESS_DELEGATION_BOX`, `BUSINESS_DELEGATION_BOX_HOME`; ausência de runtime termina com exit 2.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite schema`; exigir falha por schema ausente antes da implementação.
- [ ] Criar a migration idempotente aditiva com colunas/constraints da especificação. `tb_conta_gestoras.id_conta` usa a conta como PK; configuração da gestora, relações, equipe e convites têm `version bigint NOT NULL DEFAULT 1`; relações/equipe/convites usam PK bigint própria. Gravar capacidades propostas em JSONB validado pelo catálogo e capacidades efetivas nas tabelas normalizadas. Acrescentar `origem_gestora_id` e `gestao_vinculo_id` nullable a solicitações cadastrais, preservando as linhas existentes.
- [ ] Criar índices para seleção por membro, relação, destinatário e pendências. Convite titular: índice único parcial por conta/tipo com `status='PENDENTE'`; antes de renovar, expirar/cancelar o anterior na mesma transação. Nenhuma regra de unicidade depende de `now()` no índice.
- [ ] Implementar `schemaReady()` conferindo versão e objetos exigidos. Acrescentar `APPLICATION.businessAccountDelegationEnabled`, default false, resolvido por `BUSINESS_ACCOUNT_DELEGATION_ENABLED` ou pela chave `businessLocalConfig.accountDelegationEnabled` no padrão existente. Esta tarefa só implementa a leitura: não edita configuração privada nem ativa contas reais. Migração não habilita gestoras nem altera grants/roles; falta de privilégios deve aparecer no preflight.
- [ ] Reexecutar a suíte, reaplicar a migration e exigir `PASS schema`, incluindo preservação de vínculos diretos e dados sintéticos anteriores. Revisar o diff somente dos arquivos da tarefa.

## Task 2 — Contexto, capacidades e transação autorizada

**Arquivos:** criar `services/BusinessAccountDelegation.cfc`, `services/accountDelegation/Policy.cfc`, `_codex/tests/account-delegation/policy.cfm`; ampliar Store.

**Interfaces da fachada:** `init(required string datasource, boolean enabled=false) -> service`; `listAccess(required struct identity) -> array<AccessOption>`; `resolve(required struct identity, required struct selection) -> Context`; `has(required struct context, required string capability) -> boolean`; `formToken(required struct context, required string seed) -> string`; `verifyForm(required struct context, required struct posted, required string seed) -> void`; `withMutation(required struct context, required string capability, required struct expected, required struct resource, required any work) -> any`. A instância usa um único datasource, inclusive em `work(context)`.

- [ ] Escrever `testThreeAccessPathsStaySeparate`, `testViewerCannotInheritWrite`, `testDeletedMembershipDoesNotResurrect`, `testRevocationWinsBeforeMutation`: usar `assertEqual(actual,expected,label)` e `assertThrowsType(fn,type,label)` definidos em `assertions.cfm`. Asserções centrais: `assertEqual(service.has(directViewer,'ads.campaigns.manage'),false,'direct'); assertEqual(service.has(agencyManager,'ads.campaigns.manage'),true,'delegated'); assertEqual(service.has(secondAgencyViewer,'ads.campaigns.manage'),false,'other agency');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite policy`; confirmar falha pelos métodos ausentes.
- [ ] Implementar interseção e implicações das capacidades declaradas; sem união entre relações/caminhos. Identidade, membros e estados são lidos do banco. Guardar versões no contexto; verificar se a PK do vínculo direto é a atribuída, não apenas se o usuário voltou a entrar na gestora.
- [ ] Implementar `withMutation`: transação no mesmo datasource das queries do callback; locks em ordem estável por conta/ID, incluindo pessoa, vínculo direto, configuração da gestora, relação e atribuição; revalidar capacidades e versões; chamar `work(context)`; registrar auditoria na mesma transação. Comandos de revogação/redução usam a mesma ordem. Não manter locks durante chamadas de rede.
- [ ] Implementar HMAC do formulário sobre ator, conta, modo, relação, versões e nonce da sessão. Validar campos escalares antes de converter IDs. Erros tipados: `BusinessDelegation.Forbidden`, `NotFound`, `Conflict`, `Unavailable`, `Validation`; handlers mapeiam para 403/404/409/503/400.
- [ ] Exercitar corrida em duas conexões reais: revogação confirmada antes da aquisição dos locks impede gravação; mutação confirmada antes permanece auditada. Exigir `PASS policy` e nenhuma escrita/auditoria de sucesso após falha.

## Task 3 — Relações, convites e atribuição de equipe

**Arquivos:** criar `services/accountDelegation/Invitations.cfc`, `_codex/tests/account-delegation/lifecycle.cfm`; ampliar Store e fachada.

**Interfaces da fachada:** `createRelationshipInvite(identity, clientId, managerId, capabilities) -> InviteResult`; `requestRelationship(identity, managerId, clientReference, capabilities) -> CommandResult`; `decideRelationship(identity, relationshipId, expectedVersion, decision, capabilities) -> CommandResult`; `changeRelationship(identity, relationshipId, expectedVersion, action, capabilities) -> CommandResult`; `assignMember(identity, relationshipId, membershipId, expectedVersion, capabilities) -> CommandResult`; `removeAssignment(identity, assignmentId, expectedVersion) -> CommandResult`. `identity` é struct, IDs/versões numeric, `decision/action/clientReference` string, `capabilities` array; todos os argumentos obrigatórios.

- [ ] Escrever testes `testInviteNeedsCounterparty`, `testRequestApprovalCanOnlyNarrow`, `testReductionInvalidatesTeamImmediately`, `testRevokeAndReinviteDoesNotRestoreTeam`, `testSevenDayExpiry`, `testNoTransitiveManagement`. Asserções: `assertEqual(invite.expiresAt,dateAdd('d',7,fixedNow),'expiry'); assertThrowsType(acceptAtExpiry,'BusinessDelegation.Conflict','expired'); assertEqual(effectiveCaps,requestedIntersection,'no widening');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite lifecycle` e observar falha.
- [ ] Implementar estados/consentimentos da especificação; decisões são POST transacionais com versão esperada. Revogação invalida atribuições e cancela ampliações pendentes. Suspensão/reativação são explícitas; nova relação após revogação requer aceite e novas atribuições. Toda redução incrementa versão antes da próxima resolução de contexto.
- [ ] Gerar tokens com CSPRNG de 32 bytes, armazenar SHA-256, expiração UTC de sete dias; `now >= expiresAt` recusa. Emissão, troca de destinatário e renovação cancelam o token anterior. Papel médico e atribuição superior ao papel atual são rejeitados. Normalizar e-mail por trim/caixa sem remover pontos ou sufixos `+`.
- [ ] Implementar identificação exata e resposta não enumerável para solicitação de acesso; limitar repetição por ator/gestora/alvo e retornar a pendência existente. Não expor documento, nome ou e-mail de cliente sem vínculo.
- [ ] Exigir `PASS lifecycle`, duas gestoras independentes para um cliente, autorizações negativas por acesso apenas delegado e audit trail com ator real.

## Task 4 — Criar cliente e confirmar titular

**Arquivos:** criar `services/accountDelegation/Accounts.cfc`, `_codex/tests/account-delegation/accounts.cfm`; ampliar fachada; modificar pontos de aprovação em `administracao/contas/includes/backend.cfm` através do novo `delegation_backend.cfm`.

**Interfaces da fachada:** `createClient(required struct identity, required numeric managerId, required struct fields, required array capabilities) -> CommandResult`; `updatePendingClient(identity, relationshipId, expectedVersion, fields) -> CommandResult`; `reviewCreatedClient(identity, registrationId, expectedVersion, decision, capabilities) -> CommandResult`; `inviteOwner(identity, relationshipId, expectedVersion, email) -> InviteResult`; `inspectInvite(identity, token) -> struct`; `acceptOwner(identity, token, expectedVersion) -> CommandResult`. Tipos seguem tarefa 3; `fields` struct e `token/email` string. A revisão exige admin interno real fora de simulação.

- [ ] Escrever `testNewClientHasNoAgencyOwner`, `testDuplicateDocumentDoesNotGrantAccess`, `testConcurrentOwnerAcceptance`, `testOwnerAcceptanceDoesNotActivatePendingAccount`, `testRequesterCannotBecomeOwnerThroughOwnInvite`. Asserções: `assertEqual(newAccount.status,'PENDENTE','approval'); assertEqual(ownerMembershipCount(agencyActor,client),0,'not owner'); assertEqual(voucherCount(client),0,'no benefits');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite accounts` e confirmar falha.
- [ ] Implementar criação atômica de conta/solicitação/relação `AGUARDANDO_CONTA`, reusando campos e normalização cadastrais. Documento duplicado, inclusive colisão na constraint, não atualiza titular nem conta existente. Guardar dados do titular separadamente do solicitante da agência.
- [ ] Implementar atualização do cadastro pendente pela gestora e revisão interna que ativa a conta/relação com as capacidades revistas. Inserir desvio explícito para solicitações com `origem_gestora_id`: não passar pelo trecho legado que transforma o solicitante em `OWNER` nem pelos fluxos de benefício/voucher. Recusa deixa acesso operacional inexistente.
- [ ] Implementar convite/aceite de titular com identidade e e-mail verificados, lock da conta e vínculo único de titular confirmado. Um membro ativo da gestora criadora não se autoatribui titularidade por esse fluxo; regularização excepcional fica com gestão interna. Não substituir titular confirmado nem impedir seu acesso direto. Revogar gestora sem titular mantém conta e auditoria para recuperação administrativa.
- [ ] Exigir `PASS accounts`, incluindo colisões em duas conexões, aceite no limite de sete dias, e preservação da fila de cadastros comuns.

## Task 5 — Fronteira HTTP, seleção e formulários

**Arquivos:** criar `business_delegation_request.cfm`, `business_delegation_form.cfm`, `_codex/tests/account-delegation/boundary.cfm`; modificar `Application.cfc`, `bi/Application.cfc`, `includes/backend/business_request_identity.cfm`, `business_account_context.cfm`, `business_permissions.cfm`, `backend_login.cfm`, `services/BusinessAuthSession.cfc`, `selecionar-conta/index.cfm`, `includes/estrutura/account_context_modal.cfm`, `navbar.cfm`, `sidenav.cfm`.

**Interfaces Policy:** `routePolicy(required string targetPath, required string method, required struct query, required struct form) -> struct{allowed,capability,action}`; `normalizeSelection(required struct posted) -> Selection`. Contexto canônico em `REQUEST.businessAccessContext`; seleção em `SESSION.businessAccessSelection`. O modo direto mantém os contratos legados existentes.

- [ ] Escrever `testBoundaryBeforeQueries`, `testNestedBiDenied`, `testRemoteCfcDenied`, `testDuplicateParametersRejected`, `testStaleTabCannotChangeClient`, `testRevokedSelectionHasNoFallback`. Asserções: `assertEqual(response.status,403,'denied'); assertEqual(queryCounter,0,'before business data'); assertEqual(changesToWrongClient,0,'stale form');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite boundary`; confirmar falha.
- [ ] Resolver o modo depois da identidade e antes dos dados da página. Classificar pelo caminho real do target e parâmetros escalares; recusar `PATH_INFO` inesperado, aliases de mutação e ações não reconhecidas. Verificar o ciclo CFC no servidor e inserir guard pré-invocação compartilhado nos pontos que não chamarem a fronteira; não implementar um despachante genérico de métodos remotos.
- [ ] Integrar os caminhos diretos/delegados no seletor. Seleção inválida apaga IDs efetivos e exige nova escolha, sem converter a requisição atual em acesso direto. Permitir somente logout, seleção e a recepção restrita de convites enquanto esse estado persiste. Login novo e logout limpam todas as seleções/versões da sessão anterior.
- [ ] No acesso delegado, fornecer conta/eventos por vínculo do cliente; `businessEffectiveUserIds`, páginas e `qPermissoes` legados ficam vazios. Adaptar a home/menu para não executarem consultas de módulos não integrados. Não traduzir capacidades para `OWNER`/`ADMIN` do cliente.
- [ ] Adicionar seleção funcional por HTML sem depender de modal JS. Cada formulário integrado envia o contexto esperado e o token da tarefa 2. Em acessos diretos, preservar comportamento/CSRF existentes.
- [ ] Exigir `PASS boundary`; executar `bash _codex/scripts/test_business_login_routing.sh` e registrar que sua verificação textual é complementar. A comprovação HTTP/CFC fica também na tarefa 11.

## Task 6 — Receber convite e retomar após autenticação

**Arquivos:** criar `convites/index.cfm`, `home.cfm`, `includes/backend.cfm`, `_codex/tests/account-delegation/receiver.cfm`; modificar `includes/backend/business_google_callback.cfm` e adicionar a recepção restrita ao guard da tarefa 5.

**Interfaces:** `/convites/?token=...` aceita somente token opaco; GET mostra proposta sem consumir; POST `action=accept|reject`, token e CSRF. Usa `inspectInvite`, `acceptOwner` ou `decideRelationship` conforme o tipo; o navegador não determina tipo, conta ou destinatário.

- [ ] Escrever `testAuthenticatedNonmemberCanAcceptOwnInvite`, `testScannerGetDoesNotConsume`, `testWrongEmailCannotInspect`, `testLoginReturnIsLocal`. Asserções: `assertEqual(statusBeforePost,'PENDENTE','GET inert'); assertEqual(otherIdentityResponse.status,404,'recipient'); assertEqual(externalRedirectAccepted,false,'local return');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite receiver` e confirmar falha.
- [ ] Implementar retorno pós-Google por estado da sessão validado para `/convites/`; validar destino na gravação e no consumo. Não fazer exceção geral ao login Business. Rotacionar sessão pelo fluxo existente e preservar apenas o retorno permitido.
- [ ] Implementar página com confirmação explícita, ações POST e mensagens para convite vencido/consumido. Aplicar `Cache-Control: private, no-store` e `Referrer-Policy: no-referrer`; não carregar recursos externos nem registrar token em logs de aplicação/auditoria. Depois de ler o token, manter referência na sessão e redirecionar para URL sem token quando autenticado.
- [ ] Entregar copiar link na emissão e renovar link depois, sem recuperar token bruto do banco. E-mail automático não é habilitado nesta primeira entrega; a UI usa link e pendência no painel, ambos previstos na especificação. Não reaproveitar serviços de campanha de e-mail para uma transação de convite.
- [ ] Exigir `PASS receiver` e regressão de callback sem convite, destinatário com várias contas e destinatário ainda sem conta.

## Task 7 — Carteira, equipe e gestão pelo cliente

**Arquivos:** criar arquivos de `/gestao-clientes/`, `delegation_home.cfm`, `home_delegated_account.cfm`, CSS e `_codex/tests/account-delegation/workspace.cfm`; modificar `administracao/contas/home.cfm`, `includes/backend.cfm`, `includes/estrutura/home_conta_dashboard.cfm`, navegação da tarefa 5.

**Interfaces da fachada:** `listClients(identity, managerId, filters) -> Page`; `listTeam(identity, managerId, filters) -> Page`; `listInvites(identity, managerId, filters) -> Page`; `listAudit(identity, managerId, filters) -> Page`; `listClientManagers(identity, clientId) -> array`; `configureManager(identity, accountId, enabled, classification, expectedVersion) -> CommandResult`. `filters` struct, `enabled` boolean, `classification` uma de `AGENCIA,TICKETEIRA,OUTROS`; a última operação exige admin interno real fora de simulação.

- [ ] Escrever testes de dados/render `testPortfolioOnlyAssignedClients`, `testManagerCanAssignWithoutReadingUnassignedData`, `testOwnerCanRevokeAgency`, `testPendingClientVisibleWithoutModuleAccess`, `testTabsPreserveFilters`. Asserções: `assertEqual(page.pageSize,25,'pagination'); assertEqual(unassignedCampaignRows,0,'management is not data access'); assertContains(html,'Titular ainda não confirmado','ownership');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite workspace` e confirmar falha.
- [ ] Implementar consultas paginadas e formulários usando a fachada. Gestores veem metadados necessários da carteira; dados operacionais do cliente exigem atribuição. Validar a gestora do filtro contra vínculo direto, sem aceitar a conta selecionada como prova.
- [ ] Implementar abas Clientes, Equipe, Convites, Histórico com links e `aria-current`; preservar `tab`, `busca`, estado e página. Usar escape contextual de texto/atributos, erros locais de formulário e POST/redirect/GET; foco visível e confirmação para revogar.
- [ ] Integrar aba Gestoras do cliente para `OWNER` direto, configuração interna e fila de aprovação de contas criadas por gestora. Usar includes novos; não reestruturar o gerenciador de contas inteiro. Explicar que gerenciar campanhas pode consumir saldo e que finanças são permissões separadas.
- [ ] Renderizar a home delegada somente com atalhos concedidos. Exibir “Via Agência X”, cliente ativo e retorno à carteira. Para titulares de conta pendente, exibir estado e recursos permitidos pelo onboarding atual; aceite não dá acesso operacional antes da aprovação.
- [ ] Exigir `PASS workspace`; a checagem visual em desktop/celular e teclado é tarefa 11.

## Task 8 — Autorização Ads no banco sem substituir o ator

**Arquivos:** criar `_codex/sql/2026-10-03_business_account_delegation_ads.sql`, `_codex/tests/account-delegation/ads-db.sql`; ampliar `Store.cfc` e `withMutation`.

**Interfaces SQL:** `public.business_gestao_ads_allowed(p_account_id bigint,p_actor_id integer) RETURNS boolean`; preservar `ads.paid_banner_actor_allowed(bigint,integer) RETURNS boolean`. As demais funções canônicas mantêm nome e argumentos.

- [ ] Reutilizar no harness os schemas/funcões canônicos carregados por `test_ads_paid_banners.mjs`. Escrever teste que usa ator sem vínculo direto no cliente: salva/submete banner apenas com contexto delegado válido, e `created_by/updated_by` continuam sendo esse ator. Chamada com relação de outro cliente ou sem capacidade falha; aprovação pelo mesmo ator também falha.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite ads-db` e observar rejeição pelo helper de vínculo direto atual.
- [ ] Dentro de `withMutation`, definir `set_config('business.delegation_context', JSON, true)` com IDs/versões canônicos somente na transação Ads. Esse valor representa a seleção, nunca uma prova de autorização: o helper reconfirma ator, conta, gestora, relação, atribuição, versões, estados e `ads.campaigns.manage` nas tabelas. `NULL`, JSON inválido, contexto incompleto ou recurso desligado retornam falso.
- [ ] Substituir apenas `ads.paid_banner_actor_allowed` por versão compatível: se existe contexto delegado, validar exclusivamente esse caminho pelo novo helper; sem contexto, manter a regra direta/interna atual. Não fazer `OR` entre a delegação selecionada e um papel direto superior. Preservar assinatura, proprietário e ACL existentes. Usar nomes SQL qualificados e search_path fixo; não enfraquecer segurança das funções chamadoras.
- [ ] A migration só substitui a função se `pg_get_functiondef`, owner e ACL corresponderem ao baseline recuperável registrado no preflight. Objetos sem privilégios necessários bloqueiam instalação, sem gerar GRANT ou mudar roles automaticamente. Não reaplicar migrations históricas do RoadRunners.
- [ ] Exigir `PASS ads-db`, rollback transacional sem vazamento do contexto na conexão reutilizada e regressões de EVENT/BANNER, revisão e cobrança. Testar a role real de runtime em banco isolado, além do dono das fixtures.

## Task 9 — Publicidade, banners, créditos e comprovantes

**Arquivos:** modificar `ads/includes/access.cfm`, `backend.cfm`, `payments_backend.cfm`, `payments_home.cfm`, `workspace_campaign_form.cfm`, `workspace_campaigns.cfm`, `workspace_campaign_detail.cfm`, `workspace_history.cfm`, `ads/components/AdsPaymentService.cfc`, `api/ads/payments/status.cfm`, `portal/includes/paid_banner_backend.cfm`, `paid_banner_actions.cfm`, `paid_banner_queries.cfm`, `paid_banner_form.cfm`, `paid_banner_list.cfm`; criar `_codex/tests/account-delegation/ads.cfm`.

**Interfaces:** reutilizar `Context`, `verifyForm` e `withMutation`. Estender `AdsPaymentService.createCheckout(accountId,createdBy,amountCents,idempotencyKey, struct accessContext={})` mantendo chamadas antigas. `accessContext` é gerado no servidor; vazio conserva fluxo direto. O serviço autoriza a criação local da intenção antes da chamada ao provedor.

- [ ] Escrever `testCampaignManagerCannotBuy`, `testBuyerCannotReadOtherPayments`, `testCampaignAndBannerKeepRealActor`, `testRevokedPostDoesNotUpload`, `testUncertainCheckoutIsIdempotent`. Asserções: `assertEqual(fakeProvider.calls,0,'denied purchase'); assertEqual(intent.accountId,clientId,'wallet'); assertEqual(saved.updatedBy,actorId,'actor'); assertEqual(countAfterRetry,1,'one intent');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite ads` e confirmar falha.
- [ ] Derivar flags de `ads/includes/access.cfm` das capacidades selecionadas no modo delegado; flags de revisão, HOUSE, crédito manual, estorno e vouchers ficam falsas mesmo se a pessoa tiver poderes em outro caminho. Leituras usam somente o cliente ativo.
- [ ] Conferir campanha/banner por `account_id` antes de qualquer alteração; executar chamadas SQL existentes na transação autorizada da tarefa 2 usando instância do serviço com datasource `runnerhub`. Vincular todos os formulários a contexto/versões, incluindo pausa, retomada, retirada de análise e envio.
- [ ] Antes de escrever arquivo de upload, validar contexto; antes de salvar o banner, revalidar na transação. Timeout com resultado de gravação desconhecido não apaga arquivo nem confirma sucesso. Preservar a proteção já existente para imagem possivelmente utilizada.
- [ ] Separar compra de histórico financeiro. Comprador sem `ads.payments.view` só acompanha intenção criada por ele no contexto autorizado; endpoint de status confere ator, conta e relação de origem registrada na auditoria da intenção. Registrar intenção autorizada e auditoria na transação, liberar locks, chamar provedor com idempotência existente e reconciliar o resultado. Revogação posterior não duplica nem apaga a intenção já confirmada localmente. Webhook/reconciliação conservam seus próprios guards.
- [ ] Exigir `PASS ads`; rodar `node _codex/scripts/test_ads_paid_banners.mjs` e as suítes existentes `test_ads_phase2_business_access.sh`, `test_ads_phase2_payment_services.sh`, `test_ads_phase2_payment_endpoints.sh`. Suíte existente indisponível/falhando precisa de diagnóstico registrado, não de remoção do teste.

## Task 10 — Eventos e solicitações de vínculo

**Arquivos:** modificar `eventos/includes/backend/backend.cfm`, `backend_evento_edicao.cfm`, `backend_evento_solicitacoes.cfm`, `eventos/includes/variaveis.cfm`, `form_edicao.cfm`, `form_edicao_conteudo.cfm`, `form_edicao_fornecedores.cfm`, `form_edicao_percursos.cfm`, `solicitacoes_eventos.cfm`; criar `_codex/tests/account-delegation/events.cfm`.

**Interfaces:** as ações já existentes continuam com seus nomes. `events.manage` libera somente `editar_evento_basico`, `editar_evento_fornecedores`, `editar_evento_competition_id`, `editar_evento_descricao`, `editar_evento_percursos` (campo `categorias`), `salvar_evento_percurso`, sujeitos ao escopo do cliente e às restrições atuais. `events.links.request` libera `evento_solicitacao_action=solicitar`. Configurações internas, OR, agregadores, exclusões de evento/resultados e aprovação/negação de vínculos permanecem internas.

- [ ] Escrever `testViewerCannotPostEvent`, `testNestedResourceBelongsToEventAndClient`, `testRequestDoesNotSelfApprove`, `testGlobalEventActionsDenied`. Asserções: `assertEqual(response.status,403,'viewer'); assertEqual(eventRowsChanged,0,'foreign parent'); assertEqual(link.status,'PENDENTE','needs approval');`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite events` e confirmar falha.
- [ ] Usar `tb_conta_eventos` ativo para consultar/editar eventos; dados como percurso, fornecedor e competition ID também precisam corresponder ao evento autorizado. Não usar só o ID do pai enviado em FORM. Reutilizar as validações de negócio dos handlers existentes.
- [ ] Colocar as escritas permitidas e auditoria dentro de `withMutation` no mesmo datasource. Os forms recebem contexto esperado e CSRF; GET não altera. Preservar a alteração preexistente de disponibilidade de inscrições: ela mantém suas exigências administrativas atuais e não é liberada automaticamente para gestoras.
- [ ] Autorizar solicitação somente na conta ativa e manter a aprovação interna. Consultas de busca exibem apenas informação pública de eventos necessária ao pedido; não expõem relações/solicitações de outras contas. Inserir ator real da gestora em `id_usuario_solicitante`.
- [ ] Exigir `PASS events`; executar `bash _codex/scripts/test_event_request_copy_accents.sh`, `node _codex/tests/seo_registration_submission_cfml.mjs` e `node _codex/tests/seo_registration_persistence_cfml.mjs` como regressões existentes, sem modificar resultados alheios ou mudanças de outras frentes. O teste textual de copy não substitui a suíte comportamental de autorização.

## Task 11 — Integração HTTP, interface e regressões

**Arquivos:** criar `_codex/tests/account-delegation/http.mjs`, `coverage.json`; ampliar harness e registrar evidências no documento operacional. Ajustar somente arquivos da tarefa em caso de falha.

**Interfaces de teste:** `BUSINESS_DELEGATION_TEST_URL` aponta exclusivamente para o servidor local isolado; harness fornece sessões sintéticas por fixture local fora do runtime distribuído. O teste recusa host externo. Credenciais, cookies e tokens não são impressos.

- [ ] Criar HTTP tests com duas agências, três clientes, titular novo, leitor, operador, admin interno e pessoa com caminho direto + delegado. Cobrir os endpoints do inventário, todos os verbos utilizados, POSTs com ação desconhecida, arrays, parâmetros duplicados e CFC remoto. Exemplo de asserção: `assert.equal(blocked.status,403); assert.equal(await fixture.countUnauthorizedWrites(),0);`.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite http`; confirmar ausência de testes pulados e rotas realmente executadas no runtime. Validar códigos e conteúdo, não somente redirecionamentos ou fontes de template.
- [ ] Executar `node _codex/scripts/test_account_delegation.mjs --suite all`; exigir todas as suites PASS. Rodar `bash _codex/scripts/test_business_remember_local.sh` com runtime/jose4j já instalados, `test_business_existing_account_access_request.sh` e `test_business_duplicate_document_registration.sh`; registrar comandos e resultados.
- [ ] Verificar visualmente a UI local em 1280 px e 390 px, teclado e JavaScript desligado. Fluxo: criar cliente → revisão interna → atribuir funcionário → alternar clientes → operar campanha autorizada → aceitar titular → revogar agência → negar POST de aba antiga. E-mail/provedor permanecem fake; produzir capturas sem dados reais.
- [ ] Conferir cobertura da especificação em `coverage.json`: cada critério aponta para suíte/caso/evidência; campo `status` distingue `passed`, `failed`, `not_run`. Qualquer falha de autorização ou cobertura HTTP essencial impede habilitação/publicação do recurso.
- [ ] Solicitar revisão independente pelo fluxo de revisão aplicável à execução escolhida, fornecendo spec, plano, patch delimitado e evidências. Resolver achados relevantes e repetir somente verificações afetadas antes da publicação.

## Task 12 — Publicação verificável e recuperação

**Arquivos:** criar os dois scripts operacionais listados no mapa, `_codex/tests/account-delegation/publisher_test.py`, `_codex/docs/2026-10-03_contas_gestoras_operacao.md`; gerar manifesto/recibos no mesmo diretório de documentação operacional. Modificar README e `_codex/docs/business_account_permissions.md` com comportamento instalado, somente após validação.

**Interfaces:** `deploy_account_delegation.py prepare|publish|verify|rollback manifest.json receipt.json`, adaptando `deploy_house_banner_scope` com allowlist exclusiva Business. `account_delegation_database.py preflight|apply|verify manifest.json receipt.json`, usando o acesso autorizado já existente; sem nova credencial/grant. Manifesto registra caminho, baseline SHA-256, candidato SHA-256 e definição/hash/owner/ACL das funções SQL afetadas.

- [ ] Escrever testes com transporte fake: baseline remoto mudou, arquivo de outra frente, caminho fora de escopo, compile falhou, backup incompleto e verificação pós-upload falhou devem recusar sucesso. `assertFalse(result.published)` e `assertEqual(remoteWrites,[])` nos casos de preflight recusado. Verificar rollback que preserva schema/dados e invalida somente seleções delegadas.
- [ ] Rodar `python3 -m unittest discover -s _codex/tests/account-delegation -p 'publisher_test.py'`; primeiro falha, depois PASS ao implementar os adaptadores. `prepare` é não publicador e deve ser repetível sem substituir backup.
- [ ] Capturar baseline real de runtime/schema/ACL por acesso autorizado e montar candidatos que preservem alterações de outras frentes. Não publicar arquivo inteiro com mudanças não relacionadas ausentes do baseline. Verificar o diff antes de cada troca; qualquer divergência interrompe o pacote.
- [ ] Criar backup privado recuperável e executar preflight SQL: versões, objetos, privilégios disponíveis, idempotência e compatibilidade com runtime anterior. Bloquear aplicação se faltar acesso/privilégio; não mudar roles ou credenciais. Aplicar migrations somente após testes e preflight passarem, com delegação desligada e definições anteriores recuperáveis.
- [ ] Executar `prepare`, conferir compilação Adobe ColdFusion dos arquivos do manifesto, depois `publish` e `verify`. Hash igual comprova upload, não comprova o fluxo funcional. Não executar comandos deste plano com manifestos antigos de banners ou de outro trabalho.
- [ ] Verificar o resultado real com contas de homologação autorizadas: login, convite sintético, seleção, consulta e negações por URL/POST. Não usar cliente real, enviar e-mail real, comprar crédito ou ativar anúncio. Se sessão/contas de homologação não estiverem disponíveis, registrar homologação pendente e não habilitar gestoras para clientes reais.
- [ ] Habilitar o recurso geral somente quando pronto e contas gestoras apenas quando deliberadamente selecionadas; a habilitação de contas é operação administrativa explícita. Registrar runtime publicado versus recurso habilitado versus fluxo homologado separadamente. O usuário não forneceu IDs de agências a ativar.
- [ ] Registrar backup, hashes, testes, mudanças de contrato, resultado HTTP, limitações e ordem de recuperação. Rollback desliga novas delegações, invalida contextos e restaura runtime/função compatíveis sem apagar relações, contas, auditoria ou dados financeiros. Não executar rollback destrutivo de schema.

## Cobertura e ordem

| Requisito da especificação | Tarefas responsáveis |
| --- | --- |
| Base, classificação e habilitação | 1, 2, 7 |
| Criar cliente e aprovar sem benefício automático | 4, 7 |
| Convite, solicitação, aceite e titular | 3, 4, 6 |
| Equipe, capacidades e revogação | 2, 3, 7 |
| Seleção, identidade real e ausência de herança | 2, 5 |
| Abas, links, teclado e celular | 5, 6, 7, 11 |
| Publicidade, Eventos e negação dos demais módulos | 5, 8, 9, 10 |
| Concorrência, falhas, auditoria e não duplicação | 1, 2, 3, 4, 8, 9, 11 |
| Publicação, preservação de outras frentes e recuperação | 11, 12 |

Executar na ordem 1–12. Tarefas 8 e 10 têm componentes independentes, mas alteram fronteiras compartilhadas; qualquer paralelismo deve usar contratos e atribuições de arquivos explícitos. Não criar branches/commits para isso. Enquanto o pacote estiver incompleto, a flag permanece desligada e o acesso delegado não é anunciado como disponível.

## Revisão e escolha de execução

Plano revisado contra as 12 seções da especificação; todas possuem tarefas responsáveis. As cinco condições de Review Focus estão vinculadas a casos concretos. Suítes e arquivos identificados como novos serão implementados nas tarefas; os comandos registrados acima ainda não foram executados.

Recomendação: execução por etapas com subagentes e revisão de cada tarefa, pela alteração de autorização entre contas e pela integração com compras de créditos. A alternativa é execução por mim nesta conversa, com revisão independente ao final. O usuário deve revisar este plano e escolher o método antes da implementação, conforme o fluxo de writing-plans. Publicação já está autorizada pela preferência do projeto, condicionada às verificações descritas.
