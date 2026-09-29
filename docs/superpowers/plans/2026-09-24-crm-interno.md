# CRM interno — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Recomenda-se execução direta nesta sessão, pois as etapas dependem dos mesmos contratos. O usuário ainda precisa revisar este plano e escolher a execução.

**Goal:** Entregar públicos salvos, ficha do corredor e campanhas comerciais revisadas, com notificações, e-mail e card contextual no mini perfil.

**Architecture:** Business oferece a operação e consome uma API assinada do Road Runners, dono da elegibilidade, identidade e histórico central do CRM. Novas tabelas ficam em `crm_interno`; os módulos atuais mantêm seus contratos. A fila central reserva destinatários; os adaptadores de canal registram resultados sem recalcular ou ampliar o público aprovado.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL, MDBootstrap, JavaScript nativo, ferramentas de testes já adotadas (CFML isolado, SQL, Node/Python e navegador).

**Spec:** [Especificação aprovada](../specs/2026-09-24-crm-interno-design.md).

## Global Constraints

- “O usuário escolheu **públicos salvos e campanhas revisadas antes do envio**.”
- “Criar `/crm-interno/`, preservando o CRM de eventos e seus escopos.”
- “Combinar todos ou qualquer um, com até 12 critérios e sem grupos aninhados na primeira versão.”
- “Uma prévia vale por 30 minutos; depois é necessário recalcular e revisar.”
- “Não acrescentar novos usuários silenciosamente após essa confirmação.”
- “Dados obtidos via Strava e seus derivados ficam fora da segmentação comercial desta implementação.”
- “Reter os agregados por 90 dias e informar a cobertura efetiva.”
- “Notificação e e-mail compartilham limite inicial de um contato comercial por usuário a cada sete dias dentro das entregas integradas ao CRM.”
- “Limite inicial: uma impressão contabilizada por sessão e no máximo três sessões por dia/campanha/usuário.”
- “Acesso inicial para ADMIN/DEV com identidade real autorizada; negar durante impersonação.”
- “Não executar campanhas reais como parte de testes ou deploy.”
- Seguir os `AGENTS.md` dos dois projetos. Não criar branch, commit, tag, push ou PR. Preservar mudanças alheias; publicação de runtime após verificações já está autorizada pelo usuário.
- Não criar outro aplicativo frontend, runtime, SDK ou biblioteca de interface. Configuração usa mecanismos locais existentes sem copiar segredos.
- Datas e janelas comerciais em `America/Sao_Paulo`; persistência temporal em `timestamptz` quando nova.

## Review Focus

1. Troca de conta na mesma aba: nenhum card, ficha ou beacon pode herdar a identidade anterior; testes nas tarefas 2 e 8.
2. Opt-out apenas no armazenamento do navegador: coleta não pode ocorrer antes da leitura dessa preferência; teste na tarefa 4.
3. Duas campanhas/canais concorrentes: a unicidade por campanha não basta para aplicar o limite global de sete dias; teste na tarefa 6.
4. Scanner de links de e-mail: abrir uma URL não pode descadastrar nem contabilizar uma compra; testes nas tarefas 7 e 9.
5. Evento multidistância e resultado reimportado: modalidade não pode ser deduzida pelo evento, nem data de importação substituir a data da corrida; teste na tarefa 3.

## Organização, limites e execução

`B` significa `/Users/Shared/Projects/RunnerHub/Business`; `R` significa `/Users/Shared/Projects/RunnerHub/RoadRunners`. Todos os caminhos abaixo são relativos a essa raiz explicitamente indicada.

Executar as tarefas em ordem. São entregas verificáveis de um único módulo: catálogo → públicos → revisão → entrega → medição. Não liberar telas incompletas como se o CRM estivesse concluído. Uma fonte comprovadamente ausente pode aparecer indisponível conforme a especificação, mas os três canais precisam ter seus fluxos implementados; bloqueio de infraestrutura deve ser reportado por canal.

O workspace atual do Business tem diretórios `__pycache__` alheios e os documentos desta tarefa. Road Runners estava limpo na inspeção. Revalidar antes de cada edição. Road Runners está fora da raiz gravável desta sessão: usar a autorização de filesystem exigida pelo ambiente quando chegar à implementação, sem contornar o sandbox por cópias ocultas ou outro mecanismo.

### Contratos comuns

Todas as operações administrativas usam `POST /api/crm-interno/admin.cfm`, JSON e assinatura HMAC compatível com os headers `X-RR-Handoff-Timestamp` e `X-RR-Handoff-Signature`. TTL de 180 segundos; assinatura cobre timestamp e corpo exato. Validar ambiente esperado no corpo assinado e negar fallback de produção para DEV.

Envelope: `{success:boolean, code:string, data:struct, request_id:string}`. Erros: `400 invalid_payload`, `401 invalid_signature`, `403 forbidden`, `404 not_found`, `409 revision_conflict|preview_expired`, `422 invalid_rule|source_unavailable`, `503 module_unavailable|channel_unavailable`. Não retornar stack trace, SQL ou segredo.

Regras normalizadas têm `{operator:"all"|"any",criteria:array}`. IDs são inteiros positivos; UUIDs são strings validadas. Datas da API usam ISO 8601 com offset. Instantes de corte são obtidos no servidor; horário do cliente não determina elegibilidade.

Contratos CFML novos ficam em `R/services/crm/`; cada componente recebe `datasource`, configuração e, nos testes, adaptadores de relógio/transporte. Não incluir backends de chat para inicializar CRM.

| Componente | Interface pública |
|---|---|
| `CrmSecurity.cfc` | `requireActor(numeric actorId, boolean impersonating): struct`; `verifyRequest(string body, struct headers, string expectedEnvironment): struct` |
| `CrmRules.cfc` | `normalize(struct policy, struct capabilities): struct`; `compile(struct policy, struct capabilities, date asOf): struct` retornando `{sql,params}` |
| `CrmAudienceService.cfc` | `capabilities(): struct`; `listAudiences(string term,numeric page): struct`; `saveAudience(numeric actorId,struct input): struct`; `archiveAudience(numeric actorId,numeric id,numeric expectedVersion): struct`; `evaluate(struct policy,date asOf,numeric page,numeric limit): struct`; `profile(numeric userId): struct` |
| `CrmAccessService.cfc` | `record(numeric userId,string environment,date at): void`; `coverage(date asOf): struct`; `prune(date asOf): numeric` |
| `CrmCampaignService.cfc` | `save(numeric actorId,struct input): struct`; `list(numeric page): struct`; `get(numeric id): struct`; `preview(numeric actorId,numeric campaignId,numeric revision): struct`; `confirm(numeric actorId,string previewId,string requestId): struct`; `transition(numeric actorId,numeric campaignId,numeric revision,string action): struct` |
| `CrmDeliveryService.cfc` | `claim(string channel,numeric limit): array`; `authorize(string deliveryId,string leaseToken): struct`; `complete(string deliveryId,string leaseToken,struct result): struct`; `reconcile(string deliveryId): struct`; `runNotifications(numeric limit): struct` |
| `CrmPreferenceService.cfc` | `eligibility(numeric userId,string channel): struct`; `unsubscribe(string token): struct`; `tokenFor(numeric userId,string channel): string` |
| `CrmTrackingService.cfc` | `selectCard(numeric userId,string sessionKey): struct`; `recordEvent(numeric userId,string token,string kind,string requestId): struct`; `conversion(struct signedEvent): struct`; `report(numeric campaignId): struct` |
| `B/services/CrmClient.cfc` | `request(string action,struct data,numeric actorId,string requestId): struct`; `workerRequest(string action,struct data,string requestId): struct` |
| `B/services/CrmEmailAdapter.cfc` | `run(numeric limit): struct`; `send(struct authorizedDelivery): struct` |

Administrativo, jobs e eventos públicos usam escopos distintos; worker não aceita ações de gestão/ficha. O chamador do Business deriva `actorId` da sessão real, nunca do FORM. Métodos de domínio são chamados apenas após o guard correspondente.

## Tarefa 1 — Base de dados, capacidades e testes isolados

**Arquivos:** criar `R/_codex/sql/migrations/2026-09-24_crm_interno.sql`, `R/_codex/sql/crm-interno-source-audit.sql`, `R/_codex/tests/crm-interno/bootstrap.cfm`, `R/_codex/tests/crm-interno/schema.sql`, `R/_codex/scripts/test_crm_interno.py`; criar `B/_codex/docs/2026-09-24_crm_interno_sources.md` durante execução.

**Entrega:** esquema aditivo e inventário de fontes/ambiente sem extrair nomes, e-mails, atividades individuais ou tokens. O schema é criado no banco de teste antes de qualquer produção.

- [ ] Auditar catálogos com `information_schema`, índices, permissões existentes, volume agregado e datas de atualização. Confirmar schema de gestão, tabelas de resultados/check-in/desafios e transporte/descadastro. Registrar cada capacidade como disponível, ausente ou origem não comprovada, com a consulta que sustentou a conclusão.
- [ ] Criar runner que exige `CRM_TEST_DSN` explicitamente isolado e recusa `runner_dba`/`runnerhub` como DSN de teste. Reutilizar a execução CFML isolada exemplificada em `R/_codex/scripts/test_audience_live_cfml_local.sh`, sem carregar `Application.cfc` de produção. Configurar `CRM_TEST_BOX_RUNTIME`/`CRM_TEST_COMMANDBOX_HOME` explicitamente; falta de runtime termina com código 2, sem sucesso simulado.
- [ ] Criar `crmAssert(boolean,string)` e `crmReject(any,string)` no bootstrap. O segundo executa a closure, exige exceção cujo `message` seja o código esperado e falha se não houver exceção. A fixture SQL cria usuários sintéticos 101 (ativo/admin), 102 (ativo/comum), 103 (excluído), 104 (parceiro), prova 201 (5/21/42 km), prova 202 (meia), agenda 102→201 sem modalidade, resultado 102→202 de 21,0975 km e uma segunda linha vinculada à mesma participação.

```cfml
function crmAssert(required boolean condition, required string label) {
    if (!condition) throw(type="CrmTestFailure",message=label);
}
```

- [ ] Escrever teste SQL que exige as restrições únicas abaixo e prova rollback de fixtures. Executar antes da migration: falha por schema ausente. Definir entidades com PKs/FKs, estados CHECK, timestamps e índices por acesso/estado/período:

| Tabela `crm_interno` | Colunas específicas e invariantes |
|---|---|
| `audiences` | `id`, `name`, `description`, `current_version`, `archived_at`, `created_by`, timestamps |
| `audience_versions` | `(audience_id,version)` PK, `policy jsonb`, `created_by`, `created_at`; versões imutáveis |
| `campaigns` | `id`, `current_revision`, `status`, timestamps |
| `campaign_revisions` | `(campaign_id,revision)` PK, `audience_id`, `audience_version`, `channel`, `name`, `content jsonb`, `destination`, `starts_at`, `ends_at`, `priority`, `created_by`, `created_at`; FK composta para público |
| `previews` | `id uuid`, campanha/revisão, `as_of`, `expires_at`, `status`, contagens, `confirmed_by`, `confirmed_at`, `confirm_request_id unique` |
| `preview_members` | `(preview_id,user_id)` PK, `eligible`, `exclusion_code`, `reasons jsonb` |
| `deliveries` | `id uuid`, campanha/revisão/usuário/canal UNIQUE, `preview_id`, `status`, `lease_token`, `leased_until`, `attempts`, `provider_id`, `error_code`, `accepted_at`, timestamps |
| `contact_windows` | `user_id` PK, `reserved_delivery_id`, `reserved_until`, `last_accepted_at`; limite entre canais |
| `preferences` | `(user_id,channel)` PK, `status`, `source`, `updated_at`; desconhecido não equivale a consentimento |
| `events` | `id uuid`, `delivery_id`, `kind`, `request_id unique`, `session_key_hash`, `occurred_at`, `is_test`, `details jsonb`; sem IP, segredo ou HTML |
| `dismissals` | `(campaign_id,user_id)` PK, `dismissed_at`; dispensa vale para todas as revisões |
| `access_daily` | `(user_id,environment,day)` PK, `first_at`, `last_at` |
| `coverage_daily` | `(source,environment,day)` PK, `status`, timestamps; saúde da coleta separada da ausência de acessos |
| `audit` | `id`, `actor_id`, `action`, entidade/revisão, `request_id`, `created_at`, metadados mínimos |

```sql
SELECT count(*) = count(DISTINCT (campaign_id, revision, user_id, channel))
FROM crm_interno.deliveries;
```

- [ ] Aplicar migration duas vezes no banco isolado e verificar idempotência. Não incluir GRANT novo sem verificar privilégios existentes e autorização; falta de privilégio de runtime é bloqueio relatado.
- [ ] Executar `python3 R/_codex/scripts/test_crm_interno.py --suite schema` substituindo `R` pela raiz definida acima. Esperado: schema, constraints e reaplicação passam; zero conexões externas de envio.

## Tarefa 2 — API protegida e cliente Business

**Arquivos:** criar `R/services/crm/CrmSecurity.cfc`, `R/api/crm-interno/_bootstrap.cfm`, `R/api/crm-interno/admin.cfm`, `B/services/CrmClient.cfc`; modificar configuração em `R/Application.cfc` e `B/Application.cfc` somente nos blocos de integrações; criar `R/_codex/tests/crm-interno/security.cfm` e `B/_codex/tests/crm-interno-client.cfm`.

**Consome:** schema e bootstrap. **Produz:** guards, envelope e `CrmClient.request`/`workerRequest` da tabela de interfaces.

- [ ] Testar assinatura ausente/expirada, ambiente incorreto, ator comum, parceiro, excluído e impersonação antes de implementar.

```cfml
crmReject(function(){ security.requireActor(102,false); },"forbidden");
crmReject(function(){ security.requireActor(104,false); },"forbidden");
crmReject(function(){ security.requireActor(101,true); },"forbidden");
crmReject(function(){ security.verifyRequest("{}",{},"prod"); },"invalid_signature");
```

- [ ] Implementar comparação constante de assinatura conforme `_helpers.cfm` de grupos especiais; limitar corpo a 256 KiB, critério/count/página por allowlist. Reusar segredo de handoff já configurado. Definir `APPLICATION.crmInternal` com `enabled=false`, ambiente, endpoint, timeout 20s e referência ao segredo existente. Nenhuma credencial literal ou fallback para outro ambiente.
- [ ] Implementar `CrmClient`: sessão real → payload assinado → HTTP → envelope; 401/403/503/timeout viram erro específico na tela, nunca lista vazia. Não repassar mensagens técnicas brutas.
- [ ] Testar duas contas na mesma sessão sequencial e requisição com ID forjado; assertar que o guard usa o contexto atual e não um cache do primeiro usuário.
- [ ] Executar suite `security` no runner e teste de cliente CFML isolado. Esperado: todos os acessos negados falham antes de consultar audiência ou executar ação.

## Tarefa 3 — Regras canônicas, públicos e ficha

**Arquivos:** criar `R/services/crm/CrmRules.cfc`, `R/services/crm/CrmAudienceService.cfc`, `R/services/crm/queries/{audience,profile,capabilities}.sql`, `R/_codex/tests/crm-interno/rules.cfm`, `R/_codex/tests/crm-interno/audience.sql`; ampliar `R/api/crm-interno/admin.cfm`.

**Consome:** guards/schema. **Produz:** `capabilities`, `listAudiences`, `saveAudience`, `archiveAudience`, `evaluate` e `profile`.

- [ ] Escrever testes para critério desconhecido, 13 critérios, grupo aninhado, SQL disfarçado de campo e fonte indisponível em regra OR. Capacidade contém `{available,reason,source,updated_at,coverage_from}` por critério.

```cfml
crmReject(function(){ rules.normalize(
    {operator="any",criteria=[{type="shoe_km",minimum=600}]},
    {shoe_km={available=false,reason="source_unavailable"}}
); },"source_unavailable");
```

- [ ] Implementar tipos `profile_location`, `recent_result`, `event_agenda`, `event_registration`, `event_offers_distance`, `confirmed_distance`, `challenge_enrollment`, `challenge_activity`, `recent_training`, `shoe_km`, `site_access`, `contact_history`. Somente habilitar tipos sustentados pelo inventário da tarefa 1. Não criar fallback baseado no Strava, mesmo agregado. Um tipo indisponível não é aceito pelo backend nem com JSON manual.
- [ ] `compile` retorna SQL parametrizado contra alias fixo `u` de `tb_usuarios`, sem alias/coluna enviados pelo cliente. Usar `EXISTS` para relações; escolher perfil canônico de modo determinístico e respeitar estados da gestão. Normalizar distância pela regra de domínio existente e exigir origem oficial/reconhecida pertinente.

```sql
EXISTS (SELECT 1 FROM public.tb_evento_corridas_checkin a
        WHERE a.id_usuario=u.id AND a.id_fornecedor IS NULL
          AND a.tipo_checkin=:checkin_type AND a.id_evento=:event_id)
```

- [ ] Provar com fixtures: usuário 102 tem agenda em evento multidistância, mas não distância pessoal confirmada; seu resultado tem data da prova apesar de importação posterior; duplicação não aumenta público. Evento na agenda fora da janela não entra.
- [ ] Implementar salvamento/versionamento transacional, arquivo lógico e avaliação com total distinto, razões por critério e paginação de 25 (máximo 100). Ficha retorna somente dados próprios permitidos, histórico com fonte e capacidade; não retorna tokens de integração.
- [ ] Executar suites `rules` e `audience`; verificar planos das consultas em volume sintético representativo. Falha de fonte deve produzir 422/503, não resultado parcial silencioso.

## Tarefa 4 — Acessos autenticados e cobertura

**Arquivos:** criar `R/services/crm/CrmAccessService.cfc`, `R/includes/crm/bootstrap.cfm`, `R/assets/js/rr-crm-access.js`, `R/api/crm-interno/access.cfm`, `R/_codex/tests/crm-interno/access.cfm`, `R/_codex/tests/crm-access.test.js`; modificar `R/includes/estrutura/seo-web-tools-body-end.cfm` com include aditivo isolado.

**Consome:** sessão canônica, configurações e schema. **Produz:** agregado diário e capacidade `site_access`.

- [ ] Testar preferência em localStorage, cookie, Global Privacy Control, evento `rr-audience-preference` e storage event entre abas. Nenhum fetch antes de ler preferências. Não adicionar consulta de banco ao bootstrap de analytics existente.

```js
const assert = require('node:assert/strict');
// collectAccess é a função exportada pelo módulo rr-crm-access.js para testes.
let calls = 0;
collectAccess({ optOut: true, authenticated: true, send: () => calls++ });
assert.equal(calls, 0);
```

- [ ] Implementar beacon same-origin POST com CSRF e sessão verificada, sem parâmetro `user_id`. Servidor nega anonimato, impersonação, ambiente não produtivo e origem inválida. Agregado usa dia em São Paulo e UPSERT; duas abas não aumentam dias distintos.

```sql
INSERT INTO crm_interno.access_daily(user_id,environment,day,first_at,last_at)
VALUES (:user_id,:environment,(:at::timestamptz AT TIME ZONE 'America/Sao_Paulo')::date,:at,:at)
ON CONFLICT(user_id,environment,day)
DO UPDATE SET last_at=greatest(crm_interno.access_daily.last_at,excluded.last_at);
```

- [ ] Registrar saúde da coleta em `coverage_daily` pelo job autenticado, marcando dias incompletos quando houve interrupção; não inferir saúde de ausência de visitas. Retenção elimina apenas dias anteriores à janela de 90 dias. Mostrar dias medidos na tela e negar inferência de inatividade em janela incompleta.
- [ ] Executar suite `access` e `node --test R/_codex/tests/crm-access.test.js`. Testar virada do dia, abas concorrentes, troca de usuário e falha do endpoint sem quebra da navegação.

## Tarefa 5 — Painel de públicos e ficha no Business

**Arquivos:** criar `B/crm-interno/index.cfm`, `home.cfm`, `includes/backend.cfm`, `includes/audiences.cfm`, `includes/profile.cfm`, `assets/crm-interno.css`, `assets/crm-interno.js`; modificar `B/includes/estrutura/sidenav.cfm`; criar `B/_codex/tests/crm-interno-ui.mjs` e fixtures sintéticas.

**Consome:** `CrmClient` e ações `catalog`, `audiences.list`, `audiences.save`, `audiences.archive`, `audiences.evaluate`, `users.profile`. **Produz:** fluxo operacional de públicos/ficha, sem disparo.

- [ ] Montar cenários de UI com respostas sintéticas para público vazio, erro de serviço, fonte indisponível, usuário sem dados e listagem paginada. Não apontar fixtures para produção.
- [ ] Usar os mesmos includes de autenticação de `administracao/usuarios/index.cfm`: `backend_login`, `require_admin_dev` e `require_real_platform_context`. Menu respeita as mesmas condições; endpoints mantêm proteção independente do menu.

```cfml
<cfset VARIABLES.template="/crm-interno/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/require_admin_dev.cfm"/>
<cfinclude template="../includes/backend/require_real_platform_context.cfm"/>
```

- [ ] Criar filtros com labels explícitos, “todos/qualquer um”, motivos em linguagem simples, total versus elegíveis por canal, cobertura e links de ficha. Ações de salvar/arquivar usam POST+CSRF e controle de versão. Estado de erro não substitui a seleção digitada.
- [ ] Testar desktop 1440px/mobile 390px, teclado e IDOR. O teste verifica que a seleção “evento oferece meia” não aparece resumida como “vai correr meia”.

```js
await page.getByRole('button', {name:'Avaliar público'}).click();
await page.getByText('Evento oferece meia maratona', {exact:true}).waitFor();
if (await page.getByText('Inscrito na meia', {exact:true}).count()) {
  throw new Error('A interface inferiu modalidade sem fonte');
}
```

- [ ] Executar `node B/_codex/tests/crm-interno-ui.mjs` em servidor isolado configurado por `CRM_UI_BASE_URL`; guardar screenshots sem dados reais. Renderização deve mostrar erro reconhecível quando a API está indisponível.

## Tarefa 6 — Campanhas, revisão e reserva da fila

**Arquivos:** criar `R/services/crm/CrmCampaignService.cfc`, `R/services/crm/CrmDeliveryService.cfc`, `R/services/crm/CrmPreferenceService.cfc`, `R/_codex/tests/crm-interno/campaigns.cfm`, `R/_codex/tests/crm-interno/concurrency.sql`; criar `B/crm-interno/includes/campaigns.cfm`, `B/crm-interno/includes/campaign-review.cfm`; ampliar API/cliente e backend da tela.

**Consome:** avaliação de audiência e schema. **Produz:** métodos de campanha/entrega/preferências definidos no contrato; ações `campaigns.save|list|get|preview|confirm|transition`.

- [ ] Testar edição concorrente e prévia expirada antes de implementar. Usar relógio injetável e banco isolado; congelar `asOf` e materializar todos os membros em uma transação consistente. Para volume alto, preparação em job mantém `status=building` até a fotografia estar completa; não exibir amostra como audiência total.

```cfml
crmReject(function(){ campaigns.confirm(101,expiredPreviewId,requestId); },"preview_expired");
crmAssert(confirmedAgain.id == confirmed.id,"confirmação repetida retorna a mesma campanha");
crmAssert(deliveriesAfterNewUser == deliveriesBeforeNewUser,"não ampliar snapshot aprovado");
```

- [ ] Implementar revisão de 30 minutos, hash/revisão do conteúdo e regra, estados canônicos da spec e controle otimista por `expected_revision`. Confirmar usa transação e trava da prévia. Auditoria e criação de entregas fazem parte da mesma transação. Pausar/cancelar impede novas reservas, sem falsificar resultado de itens já enviados.
- [ ] Implementar reserva de fila por lote máximo 50, lease de 120s e `FOR UPDATE SKIP LOCKED`. Além da entrega, travar `contact_windows` por usuário antes de autorizar e aplicar sete dias entre os dois canais. Falha definitiva libera reserva; envio aceito inicia a janela; resultado incerto mantém bloqueio até reconciliação.

```sql
SELECT id FROM crm_interno.deliveries
WHERE channel=:channel AND status='pending'
ORDER BY created_at,id FOR UPDATE SKIP LOCKED LIMIT :batch_size;
```

- [ ] `authorize` revalida critérios, gestão e preferências imediatamente antes do canal. Se a fonte falhou, não consumir o envio; se o usuário perdeu elegibilidade, marcar `excluded` com motivo. Um novo elegível nunca entra nesta campanha.
- [ ] Rodar dois workers simultâneos sobre duas campanhas, uma email e uma notificação para o mesmo usuário: apenas um recebe autorização. Testar lease expirado, resposta perdida e pausa com worker ativo. Executar suites `campaigns` e `concurrency`.
- [ ] Na UI, mostrar conteúdo, destinatários, exclusões, corte e expiração; botão separado “Confirmar envio”/“Confirmar agendamento”/“Ativar card”. Alterações invalidam a revisão. Nenhuma confirmação é executada pelo teste contra pessoas reais.

## Tarefa 7 — Entrega de notificações, e-mail e descadastro

**Arquivos:** criar `R/api/crm-interno/jobs/run.cfm`, `R/api/crm-interno/worker.cfm`, `R/crm/preferencias/index.cfm`, `R/_codex/tests/crm-interno/channels.cfm`; criar `B/services/CrmEmailAdapter.cfc`, `B/api/crm-interno/jobs/email.cfm`, `B/administracao/cron-jobs/crm_interno_jobs.sql`, `B/_codex/tests/crm-email-adapter.cfm`; ampliar serviços de entrega/preferências. Reutilizar `R/includes/backend/backend_notifications.cfm` e `B/emailmkt/EmailSenderService.cfc` sem mudar seus contratos legados.

**Consome:** fila e `authorize/complete/reconcile`. **Produz:** notificação/inbox e transporte de e-mail com status rastreado, jobs inativos e descadastro funcional.

- [ ] Criar transportes fake que contam chamadas e simulam aceite, falha definitiva e timeout após aceite. Testar o adaptador sem SMTP/push real.

```cfml
crmAssert(fakeMail.calls == 1,"uma chamada ao transporte por lease autorizado");
crmAssert(uncertainDelivery.status == "unknown","timeout não vira falha reenviável");
crmAssert(fakePush.calls == 0,"materialização já reconciliada não repete push");
```

- [ ] Notificações: reservar um template próprio por campanha/revisão; usar `rrNotificationsCreate(userId,content,icon,link,templateId,publishAt,expireAt)` e fluxo central de push. O código atual já tem UPSERT por usuário/template; não recriar essa lógica. Correlacionar `id_notifica` com a entrega e não reinvocar materialização após reconciliar sucesso, pois o UPSERT reseta leitura. Push sem confirmação confiável vira desconhecido e não é repetido automaticamente.
- [ ] E-mail: worker Business chama API central com escopo técnico apenas para `email.claim|authorize|complete|reconcile`. Ator de gestão não é inventado pelo cron. Usar transporte `enviarEmail(assunto,conteudo,emailDestinatario,nomeDestinatario)`; retorno `OK` comprova apenas aceite do transporte. Não reutilizar `emailmkt/fila.cfm` como mecanismo de retomada. Transportes configuráveis para teste nunca podem selecionar destinatário real em modo offline.
- [ ] Descadastro: token opaco/assinado vinculado a usuário/canal, sem e-mail/ID na URL. GET mostra confirmação; POST efetua supressão idempotente. Suportar POST de one-click com assinatura quando o transporte permitir headers adequados. Preferências canônicas conhecidas prevalecem sobre novas; consentimento desconhecido mantém canal indisponível para aquele usuário. Renderizar corpo controlado, com HTML escapado e destino validado, em vez de executar HTML arbitrário do operador.
- [ ] Provar que crawler GET não descadastra, repetição POST não falha e opt-out depois da prévia impede envio. Bounce/complaint verificado do provedor vira supressão; sem webhook autenticado/correlação comprovada não declarar entrega, abertura ou supressão sincronizada. Registrar capacidade correspondente como ausente.
- [ ] Cadastrar jobs com `ativo=false`, retries HTTP automáticos zero e intervalos explícitos: notificações/email a cada minuto; cobertura/retenção a cada dia. Jobs só operam campanhas confirmadas. Executar suite `channels` e testes do adaptador Business; nenhuma mensagem sai nesta etapa de validação offline.

## Tarefa 8 — Card contextual no mini perfil

**Arquivos:** criar `R/services/crm/CrmTrackingService.cfc`, `R/includes/crm/profile_card.cfm`, `R/assets/js/rr-crm-card.js`, `R/assets/css/rr-crm-card.css`, `R/api/crm-interno/card.cfm`, `R/api/crm-interno/events.cfm`, `R/_codex/tests/crm-interno/cards.cfm`, `R/_codex/tests/crm-card.test.js`; modificar `R/includes/estrutura/profile_mini.cfm`, `profile_mini_fast.cfm`, `R/i18n/pt-BR.cfm`, `en.cfm`, `es.cfm` com blocos localizados.

**Consome:** campanha confirmada, fotografia de destinatários, preferências e tracking. **Produz:** `selectCard/recordEvent`, APIs same-origin privadas e card acessível.

- [ ] Testar usuário fora do snapshot, troca de conta, expiração, dispensa, empate de prioridade e múltiplos mini perfis na mesma página. Nenhum resposta personalizada pode ter cache público.

```cfml
crmAssert(!cardForOtherUser.available,"snapshot não vaza entre contas");
crmAssert(!dismissedCard.available,"dispensa cobre todas as revisões");
crmAssert(impressionCountForSession == 1,"beacon repetido não duplica impressão");
```

- [ ] Inserir placeholder e carregar por endpoint same-origin com `Cache-Control: private, no-store`, sessão canônica e token ligado a usuário/sessão. Não executar consulta personalizada dentro do cache de sugestão patrocinada existente. Preservar o bloco Ads e seus débitos; o novo card é uma unidade distinta com no máximo um CRM visível.
- [ ] Ordenar por prioridade DESC e campanha ASC; restringir elegibilidade, janela, snapshot, dispensa e limite diário. Exposição visível: pelo menos 50% do card por um segundo contínuo em aba visível. Uma sessão autenticada opaca, rotacionada ao trocar a conta, identifica deduplicação; não confiar em ID arbitrário do cliente.
- [ ] Beacon exige token específico, usuário e campanha/revisão atuais, nonce/requestId e allowlist de eventos. Dispensa é POST com CSRF. Concorrência de abas não supera três sessões/dia. Sem serviço/usuário elegível, ocultar bloco sem erro de página.
- [ ] Verificar posição ao lado do mini perfil desktop e no fluxo mobile, teclado, foco após dispensar e textos PT/EN/ES. Executar suites `cards` e browser JS; verificar que nenhum evento do CRM grava em tabelas de créditos/leilão Ads.

## Tarefa 9 — Histórico, cliques e resultados das campanhas

**Arquivos:** criar `R/api/crm-interno/click.cfm`, `R/api/crm-interno/conversion.cfm`, `R/_codex/tests/crm-interno/tracking.cfm`, `B/crm-interno/includes/campaign-report.cfm`; ampliar `CrmTrackingService`, API administrativa e telas.

**Consome:** entregas, templates/canais e eventos. **Produz:** `conversion/report`, ação `campaigns.report` e histórico de ficha.

- [ ] Testar destino `javascript:`, URL com credenciais, redirect para host não aprovado, token de outra revisão e conversão repetida. Registrar evento somente após validar token e destino persistido; URL de destino nunca vem livre do request.

```cfml
crmAssert(report.accepted == 1 && report.delivered == 0,"aceite não comprova entrega");
crmAssert(report.conversions == 0,"clique não comprova compra");
crmAssert(report.revenue == 0,"receita exige evento transacional validado");
```

- [ ] Destinos internos usam path canônico; externos exigem HTTPS e domínio validado ao revisar campanha. Click tracking usa token opaco escopado, sem exigir login em e-mail e sem expor destinatário. Métrica é “cliques registrados”, não “pessoas que compraram”; scanners não produzem conversões.
- [ ] Conversão aceita somente callback assinado de integração confiável, ID externo único e vínculo ao produto/prova/campanha; armazenar valor/moeda apenas quando fornecidos e validados. Sem produtor configurado mostrar “conversão não integrada”, nunca estimar receita a partir de cliques. Não alterar checkout alheio neste plano.
- [ ] Relatório distingue pending, excluded, accepted, unknown, failed, impressão, clique, leitura, entrega comprovada e conversão. Preservar histórico de falhas/retomadas; excluir `is_test`. Só mostrar aberturas/entrega do provedor quando a capacidade foi validada na tarefa 7.
- [ ] Executar suite `tracking` e cenários de UI de histórico, incluindo mesmo usuário em dois canais, falha parcial e ausência de integração de conversão.

## Tarefa 10 — Validação integrada, publicação e recibo

**Arquivos:** criar `B/docs/crm-interno.md`, `R/_codex/docs/crm-interno.md`, `B/_codex/scripts/deploy_crm_interno.py`, `B/_codex/docs/2026-09-24_crm_interno_release.json`; atualizar índices de documentação e README dos dois projetos com links somente após runtime concluído.

**Consome:** tarefas 1–9 verificadas. **Produz:** módulo publicado e verificado, ou bloqueio específico com arquivos concluídos e evidência; nenhum envio real implícito.

- [ ] Executar a suíte completa uma vez após integração: runner CFML/SQL (`--suite all`), testes JS alterados e navegação Business/Road Runners. Compilar todos os `.cfm/.cfc` do manifesto com Adobe CF usando a rotina já exemplificada em `B/_codex/scripts/deploy_publico_location.py`; Lucee isolado sozinho não comprova compatibilidade Adobe.
- [ ] Conferir matriz dos 12 critérios de aceitação da spec, relatórios SQL de contagens e permissões, UI 1440/390 e ausência de dados Strava/credenciais. Medir consultas com volume sintético, sem N+1. Testar APIs indisponíveis e consumidores antigos durante rollout aditivo.
- [ ] Revalidar baseline Git e produção. Gerar manifesto fechado de arquivos desta tarefa, hash anterior/novo, existência anterior, permissões e backup recuperável. O publisher implementa `prepare`, `publish`, `verify`, `rollback`; divergência de baseline aborta sem sobrescrever.

```python
if current_hash != manifest_entry['before_sha256']:
    raise RuntimeError('production_baseline_changed')
if not backup_verified or not compile_verified:
    raise RuntimeError('release_not_ready')
```

- [ ] Aplicar migration aditiva no mecanismo existente somente depois da revisão dos objetos, índices, volume e privilégios; não executar GRANT ou alterar credenciais para superar erro. Publicar Road Runners com módulo desativado, depois Business; verificar endpoint/guards; habilitar módulo e capacidades comprovadas, sem ativar campanhas. Ativar jobs somente após validar que só consomem confirmações persistidas.
- [ ] Verificar produção por hashes e requisições reais: anônimo negado, operador autorizado abre CRM, consulta funciona com cobertura correta, usuários comuns não acessam ficha global, mini perfil mantém comportamento quando não há campanha. Teste de entrega externa só se houver destinatário de teste explicitamente autorizado; caso contrário registrar essa limitação, sem disparar.
- [ ] Gravar recibo com horário, manifesto, backups, migrations, checks executados, capacidades habilitadas/bloqueadas e rollback. Falha após deploy desativa módulo e restaura apenas arquivos do manifesto; não apagar tabelas ou histórico.
- [ ] Documentar contratos/configuração sem segredos, operação de prévia/confirmar/pausar/retomar, descadastro, origem dos sinais e diferenças de status. Relatar ao usuário por repositório: comportamento entregue, validação real, publicação e limitações específicas. Não anunciar conclusão integral se algum canal obrigatório não foi implementado.

## Revisão do plano e rastreabilidade

| Requisito da especificação | Tarefas |
|---|---|
| Público, ficha, versões e causas de inclusão | 1, 2, 3, 5 |
| Origem dos sinais, distância e dado ausente | 1, 3 |
| Recorrência e cobertura de acessos | 4 |
| Prévia, confirmação, snapshot e concorrência | 6 |
| Notificação, push, e-mail e preferências | 6, 7 |
| Mini perfil, mobile, frequência e dispensa | 8 |
| Histórico, cliques e conversão comprovada | 9 |
| Autorização, falhas, i18n e desempenho | 2–10 |
| Publicação verificada e reversão | 10 |

Contratos, nomes dos métodos e estados foram conferidos entre as tarefas. Os trechos são contratos e exemplos orientadores dos testes, não código já instalado. As variáveis de fixture citadas nos testes de campanha/canal são produzidas pelos cenários descritos em cada tarefa no banco isolado.

Status: executado diretamente na sessão após a confirmação “prossiga” e a correção do usuário sobre aprovações repetidas. Sem novos gates de aprovação. Operação, limites e evidências em `docs/crm-interno-operacao.md` e `.superpowers/sdd/2026-09-24-crm-interno/`.

Ajustes de implementação: configurações de integração existentes foram reutilizadas; nenhum Application.cfc foi alterado. O agendador usa sua identidade atual via wrappers do Business porque a referência legada do handoff difere da configuração atual. A interpretação de “3 sessões/dia” usa admissão atômica antes de renderizar e deduplicação de impressão por sessão/dia. Relatórios sinalizam explicitamente recibos externos, abertura e conversões ainda indisponíveis. Os exemplos de testes do plano foram substituídos por cenários executáveis.
