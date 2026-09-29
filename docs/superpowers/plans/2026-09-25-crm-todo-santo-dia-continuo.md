# Todo Santo Dia contínuo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. A execução direta já foi escolhida nesta frente. As instruções do workspace proíbem commit, branch, push e PR sem pedido específico; não criar etapas Git mutantes.

**Goal:** Mostrar o Todo Santo Dia como acompanhamento contínuo no CRM, medir cadastros e compras com graus de evidência separados e permitir um teste real de inscrição/pagamento com outra conta depois da publicação da conciliação.

**Architecture:** RoadRunners guarda identidade, eventos, conciliação Pagar.me, vigências e métricas; Business usa o proxy administrativo assinado já existente e renderiza a iniciativa em Campanhas. A iniciativa não reutiliza `crm_interno.campaigns`, pois essa tabela representa veiculação finita; um vínculo opcional conecta campanhas promocionais sem disparar entregas. Publicar em três incrementos testáveis: painel orgânico, compras futuras, auditoria histórica.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL, JavaScript nativo, MDBootstrap, Pagar.me Core API v5 já usado no checkout. Sem dependência nova.

**Spec:** [Especificação aprovada](../specs/2026-09-25-crm-todo-santo-dia-continuo-design.md).

## Global Constraints

- B = `/Users/Shared/Projects/RunnerHub/Business`; R = `/Users/Shared/Projects/RunnerHub/RoadRunners`. Git/status/diff e alterações são separados por repositório; preservar arquivos já modificados por outras frentes.
- “Ativa · acompanhamento” não cria destinatários, cards, notificações ou e-mails. Campanhas de veiculação mantêm revisão e confirmação próprias.
- A fonte `public.desafios` mede somente base atual; `crm_interno.challenge_signup_events` mede primeiros inícios desde `challenge_signup_source.started_at`. `data_inscricao` pode ser regravada.
- Compras confirmadas exigem GET autenticado ao Pagar.me, SKU exato `todosantodia`, `todosantodiavip` ou `todosantodiaupg`, estado suportado, BRL e vínculo seguro para indicadores pessoais. Não resolver identidade por e-mail ou `id_pagina`.
- Anuidade: `[paid_at, aniversário local em São Paulo no ano seguinte)`; 29/02 vira 28/02 em ano não bissexto. Renovação inicia outro intervalo na data do novo pagamento; períodos sobrepostos não se somam. Upgrade muda para VIP apenas durante vigência; não renova.
- Estorno total confirmado reverte o pedido; parcial, chargeback, várias cobranças, SKU/valor divergente e fonte indisponível ficam pendentes, sem valor confirmado até classificação testada. Receita bruta de pedido não é lucro nem split recebido.
- Atribuição a contato é observacional: último clique registrado elegível da mesma conta nos sete dias anteriores; sem clique, orgânico. Não atribuir historicamente por aproximação.
- Testes e sondas não criam pagamento real ou envio; o usuário realiza a nova conta e a compra após o segundo incremento publicado. Não alterar credenciais/permissões nem publicar mudanças alheias.

## Review Focus

- Pedido pago com SKU alheio ou vários itens: excluir e marcar pendente, mesmo quando `code` e usuário coincidirem (Tarefa 3).
- Duas anuidades sobrepostas e estorno da mais recente: apenas uma vigência atual; a anterior ainda válida reaparece (Tarefa 4).
- Reprocessamento do pedido com outro `charge_id` ou versão desordenada: não reverter saldo sem prova nem duplicar pedido (Tarefas 3–4).
- Página incompleta/erro no histórico Pagar.me: não marcar a janela como coberta nem apresentar zero como ausência de compras (Tarefa 5).
- Clique de teste, posterior ao pagamento, de outra conta ou de campanha não vinculada: nenhuma atribuição comercial (Tarefa 4).

## Mapa de arquivos e interfaces

- R `services/crm/CrmProgramService.cfc`: leitura da base, série de inícios, cobertura, perfil e paginação de usuários da iniciativa. `report(from,to,bucket)` e `users(source,page)`; código fixo `todosantodia`.
- R `services/crm/CrmProgramFinanceService.cfc`: projeção dos pedidos comprovados, vigências, renovações e upgrades. `summary(from,to,bucket)` e `membership(userId,asOf)`.
- R `services/crm/CrmCheckoutIdentityService.cfc`, `CrmPagarmeSnapshotService.cfc`, `CrmPagarmeReconciliationService.cfc`, `CrmConversionService.cfc`: ampliar os arquivos locais ainda não publicados; conservar contratos já usados nos testes R6.
- R `services/crm/CrmPagarmeBackfillService.cfc`: listagem histórica paginada, checkpoint e cobertura auditável, sem vincular identidade antiga por e-mail.
- R `services/crm/CrmAdminService.cfc`, `api/crm-interno/worker.cfm`: ações assinadas `programs.report`, `programs.users`, `programs.link`, `programs.reconcile`, `programs.backfill`; a última dupla apenas no worker.
- R `_codex/sql/migrations/2026-09-25_crm_tsd_program.sql`: vínculo opcional campanha→iniciativa, metadados financeiros e checkpoints. Manter as migrations locais anteriores com seus checksums; nunca editá-las após aplicadas.
- R `carteira/parts/transacao_pix.cfm`, `carteira/parts/transacao_cc.cfm`: reserva de identidade com SKU validado antes do POST ao Pagar.me e vínculo do pedido na resposta; conferir diff e runtime publicado antes de editar.
- B `crm-interno/crm-program.js`: painel responsivo carregado sob demanda, sem misturar código da iniciativa ao editor de campanhas; `index.cfm`, `crm.js` e `crm.css` só recebem pontos de integração/estilo.
- B `api/crm-interno-commerce.cfm`, `administracao/cron-jobs/crm_interno_jobs.sql`: job assinado e sem contatos para conciliar pedidos vinculados e histórico em lotes limitados; instalação inicialmente inativa.
- B `docs/crm-interno-operacao.md` e R `_codex/docs/crm_interno_evolucao.md`: fontes, limites, rotina de conciliação, reversão e recibos de release.

---

### Task 1: Iniciativa contínua e fonte de cadastros

**Files:** Create R `services/crm/CrmProgramService.cfc`; modify R `services/crm/CrmAdminService.cfc`, R `_codex/tests/crm-interno/run.cfm`; use the current R `challenge_signup_source`, `challenge_signup_events` and `public.desafios`. No migration or checkout change in this task.

**Interfaces:** `report(required string from,required string to,string bucket='week') -> {code,status,coverage,totals,series,profile}`; `users(required string source,numeric page=1) -> {items,total,page}`. Allowed `source`: `registrants`, `signup_starts`. `CrmAdminService.dispatch` exposes `programs.report` and `programs.users` after existing `requireActor`.

- [ ] **Step 1: Add failing fixture checks.** After a fresh and a repeated `startSignup`, assert current registrants count distinct `id_usuario`, signup starts count once, source timestamp is present, and `from > to`, unsupported bucket/source and non-admin actor fail. Include profile rows for SC/SP, missing city/age, and page 2 empty.

```cfml
program=new services.crm.CrmProgramService().init('crm_test');
period={from='2026-09-01',to='2026-09-30',bucket='week'};
overview=program.report(period.from,period.to,period.bucket);
check(overview.code=='todosantodia' && overview.totals.registrants>=1,'current base is available');
check(overview.coverage.signups_from!='','signup coverage is explicit');
reject(function(){program.report('2026-10-01','2026-09-01','week');},'invalid_payload');
reject(function(){admin.dispatch({actor_id=104,action='programs.report',input=period});},'forbidden');
```

- [ ] **Step 2: Run** `python3 _codex/scripts/test_crm_interno.py` from B; expect failure because `CrmProgramService` does not exist.
- [ ] **Step 3: Implement read-only queries** with bound dates (maximum 366 days), `count(DISTINCT id_usuario)` on `lower(desafio)='todosantodia'`, signup series on immutable `occurred_at`, weekly/monthly São Paulo buckets, and demographic aggregation from current `tb_usuarios` fields. Return `source_status='unavailable'` instead of zero when a source cannot be read. `users` must use `LIMIT 25 OFFSET :offset` and never expose Pagar.me payloads.

```sql
SELECT count(DISTINCT d.id_usuario) AS registrants
FROM public.desafios d
WHERE lower(d.desafio)='todosantodia';
SELECT date_trunc('week', e.occurred_at AT TIME ZONE 'America/Sao_Paulo') AS bucket,
       count(*) AS signup_starts
FROM crm_interno.challenge_signup_events e
WHERE e.challenge_code='todosantodia'
  AND e.occurred_at>=:from_at AND e.occurred_at<:to_exclusive
GROUP BY 1 ORDER BY 1;
```

- [ ] **Step 4: Re-run** `python3 _codex/scripts/test_crm_interno.py` from B; expect all domain checks to pass. Compare cohort totals with fixture SQL, not a historical reconstruction of `data_inscricao`. Verify a product launch date against source documentation before showing it; otherwise show “lançamento não verificado”.

### Task 2: Painel do programa em Campanhas

**Files:** Create B `crm-interno/crm-program.js`; modify B `crm-interno/index.cfm`, `crm-interno/crm.js`, `crm-interno/crm.css`; add browser fixture assertion to B `_codex/scripts/crm_ui_fixture.py` or its existing focused UI harness.

**Interfaces:** `initProgram({api,escape,date,openProfile,notify})` mounts a single campaign-list row and a details section. Calls `programs.report` and `programs.users`; does not call `campaigns.save/preview/confirm` or delivery workers. The row is labeled “Campanha contínua · Ativa · acompanhamento”; promotional campaigns stay in their existing list.

- [ ] **Step 1: Add a failing UI fixture** with zero signups, 1 current registrant, unavailable finance, and one missing city; assert visible labels “Base cadastrada atual”, “Inícios desde”, “Compras ainda não conciliadas” and “Não informado”. Assert click on the program row does not invoke `campaigns.confirm` and that the users table paginates.
- [ ] **Step 2: Run** the focused browser fixture in desktop and 390 px; expect missing program row/section.
- [ ] **Step 3: Add a read-only panel** with period and week/month controls, source badges, summary, series table/chart, demographic breakdown and paginated users. Render server values using the existing `escape` helper. Keep `newCampaign` and the existing review dialog unchanged. A loading error shows “Indisponível” plus the last successful refresh; empty data shows 0 with coverage dates.

```js
export function initProgram({api,escape,date,openProfile,notify}) {
  const root=document.querySelector('#crmProgram');
  return {open:async({from,to,bucket='week'})=>{
    const data=await api('programs.report',{from,to,bucket});
    root.querySelector('[data-program-status]').textContent=data.status==='active_tracking'
      ? 'Ativa · acompanhamento' : 'Indisponível';
    root.querySelector('[data-registrants]').textContent=Number(data.totals.registrants).toLocaleString('pt-BR');
    root.querySelector('[data-signups-from]').textContent=data.coverage.signups_from
      ? date(data.coverage.signups_from) : 'Indisponível';
    return data;
  }};
}
```

- [ ] **Step 4: Run** `node --check crm-interno/crm-program.js` from B and browser fixture at desktop/390 px; expect no console error or horizontal overflow and the existing campaign form/review flow still available. Publish increment 1 only after the release checks in Tarefa 6.

### Task 3: Vínculo seguro e classificação de compras futuras

**Files:** Modify R `CrmCheckoutIdentityService.cfc`, `CrmPagarmeSnapshotService.cfc`, `CrmPagarmeReconciliationService.cfc`, `CrmConversionService.cfc`, two `carteira/parts/transacao_*.cfm`, R `_codex/tests/crm-interno/run.cfm`; create R `_codex/sql/migrations/2026-09-25_crm_tsd_program.sql`. The existing local `2026-09-25_crm_checkout_identity.sql` and `2026-09-25_crm_conversion_ledger.sql` remain their baseline; apply them only if production has no matching marker or objects.

**Interfaces:** `reserve(userId,sku)` stores allowed SKU; `bind(orderCode,providerOrderId,responseCode)` remains idempotent; `classify(providerOrder,identity)` returns `{order_key,sku,user_id,status,paid_at,gross_amount_minor,net_amount_minor,currency,provider_updated_at}` only for one exact allowed item and one supported charge. `reconcile(orderId)` persists current verified state plus product metadata atomically. Financial metadata fields on `conversion_order_state`: `product_code`, `paid_at`, `provider_updated_at`, `last_checked_at`, `classification`, `coverage_kind`. `pagarme_order_audit` records provider order ID, origin, última verificação comprovada, última tentativa, classificação e motivo sanitizado. Resposta válida mas financeiramente ambígua marca `pending` e exclui o pedido dos indicadores confirmados; falha transitória de transporte preserva a última classificação comprovada com alerta de atraso.

- [ ] **Step 1: Add failing tests** for Básica/VIP/upgrade SKUs, invalid SKU, order/item mismatch, two items, two charges, reprocessamento com novo `charge_id`, chargeback, partial refund, non-BRL, duplicate `bind`, provider ID conflict, and full refund. Include checkout fixture asserting both PIX/card pass `FORM.produto_codigo` into `reserve` before `cfhttp`.

```cfml
identity=checkoutIdentity.reserve(102,'todosantodia');
reject(function(){checkoutIdentity.reserve(102,'foreign-sku');},'invalid_payload');
paid=snapshot.classify(fixtureOrder,checkoutIdentity.bind(identity.code,fixtureOrder.id,identity.code));
check(paid.sku=='todosantodia' && paid.status=='confirmed','only the bound product is paid');
```

- [ ] **Step 2: Run** `python3 _codex/scripts/test_crm_interno.py` from B; expect SKU validation/classification tests to fail.
- [ ] **Step 3: Add migration** with additive nullable finance columns, CHECK for the three SKUs, unique provider order keys, `campaign_program_links(campaign_id PRIMARY KEY REFERENCES crm_interno.campaigns,program_code CHECK='todosantodia')`, `pagarme_order_audit` keyed by provider order ID, and a coverage/checkpoint table keyed by `(source,window_start,window_end)`. Update the isolated test runner to apply this migration twice and assert its checksum marker; do not rewrite migrations already applied in production.

```sql
ALTER TABLE crm_interno.checkout_order_identity
  ADD COLUMN IF NOT EXISTS product_code text;
ALTER TABLE crm_interno.conversion_order_state
  ADD COLUMN IF NOT EXISTS product_code text,
  ADD COLUMN IF NOT EXISTS paid_at timestamptz,
  ADD COLUMN IF NOT EXISTS provider_updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_checked_at timestamptz,
  ADD COLUMN IF NOT EXISTS classification text,
  ADD COLUMN IF NOT EXISTS coverage_kind text;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='crm_checkout_product_code') THEN
    ALTER TABLE crm_interno.checkout_order_identity
      ADD CONSTRAINT crm_checkout_product_code
      CHECK (product_code IS NULL OR product_code IN ('todosantodia','todosantodiavip','todosantodiaupg'));
  END IF;
END $$;
CREATE TABLE IF NOT EXISTS crm_interno.campaign_program_links (
  campaign_id bigint PRIMARY KEY REFERENCES crm_interno.campaigns(id),
  program_code text NOT NULL CHECK (program_code='todosantodia')
);
CREATE TABLE IF NOT EXISTS crm_interno.pagarme_order_audit (
  provider_order_id varchar(100) PRIMARY KEY,
  coverage_kind text NOT NULL CHECK (coverage_kind IN ('linked_future','provider_historical')),
  classification text NOT NULL CHECK (classification IN ('pending','confirmed','refunded')),
  reason_code varchar(64) NOT NULL DEFAULT '',
  last_attempt_at timestamptz NOT NULL DEFAULT now(),
  last_verified_at timestamptz
);
CREATE TABLE IF NOT EXISTS crm_interno.program_coverage (
  source text NOT NULL CHECK (source IN ('pagarme_historical')),
  window_start date NOT NULL,
  window_end date NOT NULL,
  cursor text NOT NULL DEFAULT '',
  status text NOT NULL CHECK (status IN ('running','complete','failed')),
  scanned integer NOT NULL DEFAULT 0,
  accepted integer NOT NULL DEFAULT 0,
  pending integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (source,window_start,window_end),
  CHECK (window_start<=window_end)
);
```

- [ ] **Step 4: Implement checkout and classifier** by comparing reserved SKU to the single `items[1].code`, `items[1].amount`/quantity to order amount, order code/ID, charge/currency and supported status from authenticated GET. Preserve the checkout response even if CRM reservation/binding fails; log sanitized failure and mark the order outside personal metrics. A valid but ambiguous GET updates `pagarme_order_audit` to `pending` and suppresses that order in the financial projection, without overwriting the ledger with a guessed value. A transport failure records only the attempt and delay; it does not alter the last verified classification. Do not derive financial truth from `public.desafios.status` or saved webhooks.

```cfml
if(!structKeyExists(providerOrder,'items') || !isArray(providerOrder.items) ||
   arrayLen(providerOrder.items)!=1 || providerOrder.items[1].code!=identity.product_code ||
   !listFind('todosantodia,todosantodiavip,todosantodiaupg',identity.product_code))
  fail('source_unavailable');
```
- [ ] **Step 5: Re-run** domain suite and a production-baseline read-only check of the deployed checkout and existing Pagar.me configuration contract. Verify no key value is printed. If the published checkout contract differs materially, merge only the required change against that baseline before release; if no usable credential source exists, publish the panel increment and report finance blocked without changing credentials.

### Task 4: Conciliação, vigência e atribuição

**Files:** Create R `services/crm/CrmProgramFinanceService.cfc`; modify R `CrmPagarmeReconciliationService.cfc`, `CrmConversionService.cfc`, `CrmAdminService.cfc`, `api/crm-interno/worker.cfm`, `CrmProgramService.cfc`, R tests; create B `api/crm-interno-commerce.cfm`, update B `administracao/cron-jobs/crm_interno_jobs.sql` and the panel module.

**Interfaces:** `membership(userId,asOf) -> {active,tier,starts_at,ends_at,source_order_id}`; `summary(from,to,bucket) -> {paid_orders,identified_buyers,active_terms,renewals,upgrades,refunded_orders,amount_by_currency,series,coverage}`. Worker `programs.reconcile` processes at most 20 bound orders per run, ordered by stale `last_checked_at` and ID; response includes `{checked,pending,failed,next_due}`. `CrmProgramService.linkCampaign(actorId,campaignId,expectedRevision) -> {campaign_id,program_code}` backs `programs.link`, writes an optional link for an existing campaign, audits the operator and never transitions it.

- [ ] **Step 1: Add failing tests** for 29/02/2024→28/02/2025, renewal while an earlier term is active, full refund of the latest purchase, upgrade inside/outside the term, upgrade refund, current profile missing locality, and orgânico/last eligible click. Exercise wrong actor, test click, click after paid_at, other user, and campaign without program link.

```cfml
// Fixture: Basic paid 2026-09-26 12:00 São Paulo; paid VIP upgrade afterward.
current=finance.membership(102,createDateTime(2027,9,25,12,0,0));
check(current.active && current.tier=='vip','verified upgrade changes the current tier');
check(finance.membership(102,createDateTime(2027,9,26,12,0,0)).active==false,'anniversary is exclusive');
```

- [ ] **Step 2: Run** `python3 _codex/scripts/test_crm_interno.py` from B; expect missing finance service/worker action.
- [ ] **Step 3: Implement projection** using paid product events with safe user linkage, current verified classification and `paid_at` in São Paulo; only `classification='confirmed'` can create an active term. Choose the latest still-valid annual order as current term and apply only its non-refunded upgrades. Group by order for money and distinct user for buyers. On full refund, preserve audit event, zero current balance and recompute membership; pending orders are excluded even if they previously had a confirmed balance, with the discrepancy shown explicitly. Scope paid attribution to linked campaigns (or the existing Todo Santo Dia signup goal) and reuse the existing seven-day recorded-click rule, never infer a click from registration. In the Business program panel, show a separate “Vincular campanha” action that calls `programs.link` for a chosen existing campaign and its current revision; show the link as metadata, with no activation action attached.

```sql
SELECT s.order_key,s.product_code,s.paid_at,
       ((s.paid_at AT TIME ZONE 'America/Sao_Paulo') + interval '1 year')
         AT TIME ZONE 'America/Sao_Paulo' AS ends_at
FROM crm_interno.conversion_order_state s
JOIN crm_interno.pagarme_order_audit a ON a.provider_order_id=s.order_key
WHERE s.user_id=:user_id AND s.source='pagarme'
  AND s.product_code IN ('todosantodia','todosantodiavip')
  AND s.status='confirmed' AND a.classification='confirmed'
  AND s.paid_at<=:as_of
  AND ((s.paid_at AT TIME ZONE 'America/Sao_Paulo') + interval '1 year')
        AT TIME ZONE 'America/Sao_Paulo'>:as_of
ORDER BY s.paid_at DESC,s.order_key DESC LIMIT 1;
```
- [ ] **Step 4: Add signed no-contact worker** in RoadRunners and Business with existing `CrmJobSecurity`/`CrmClient` and scheduler identity. Install cron inactive, validate 403 for unsigned/wrong scope, execute one fixture batch, then enable only after production read/compile/smoke checks. Do not schedule emails or purchases. Retries must re-read the provider and be idempotent; failure must not advance a checkpoint.
- [ ] **Step 5: Re-run** full `crm_test` suite, `node --check` and browser checks. Release increment 2; inspect read-only health and at least one already-bound non-test order if available. Tell the user the checkout is ready for their own new-account purchase only after deployed identity, classification, job and admin panel all pass.

### Task 5: Histórico comprovado desde o início do produto

**Files:** Create R `services/crm/CrmPagarmeBackfillService.cfc`; modify R `CrmPagarmeSnapshotService.cfc`, `CrmProgramFinanceService.cfc`, `api/crm-interno/worker.cfm`, migrations/tests; modify B `api/crm-interno-commerce.cfm`, panel and operational docs.

**Interfaces:** `runBatch(from,to,cursor='',limit=30) -> {scanned,accepted,pending,next_cursor,complete}` and `coverage(from,to) -> {status,scanned,accepted,pending,updated_at}`. Only after a complete provider page sequence and successful per-order GET may a coverage window become `complete`. Historical unmatched orders use `user_id=NULL`, `match_basis='unmatched'`, `coverage_kind='provider_historical'`; they contribute to verified order aggregates, never buyer profile, renewal or contact attribution.

- [ ] **Step 1: Add failing provider-list fixtures** for two pages with duplicate order ID, three allowed SKUs, another product, refund, unsupported multiple charge, HTTP 429, and missing next page. Assert that duplicates count once, other product stays out, a failed page leaves coverage incomplete and identity remains unmatched.

```cfml
batch=backfill.runBatch('2025-01-01','2025-01-31','',30);
check(batch.scanned<=30 && batch.complete==false,'a partial page never closes coverage');
check(backfill.coverage('2025-01-01','2025-01-31').status!='complete','no false historical zero');
```

- [ ] **Step 2: Run** domain suite; expect missing backfill service.
- [ ] **Step 3: Implement paginated provider listing** with bounded page size 30, deterministic date windows, persisted cursor and rate-limit backoff. Each candidate receives authenticated GET and the same SKU/financial classifier as future purchases. Persist safe aggregate facts only; deduplicate by provider order ID; report skipped/ambiguous counts. Do not import webhook values as payment proof or backfill a user by e-mail.

```sql
INSERT INTO crm_interno.program_coverage
  (source,window_start,window_end,cursor,status,scanned,accepted,pending)
VALUES ('pagarme_historical',:from_day,:to_day,:next_cursor,'running',:scanned,:accepted,:pending)
ON CONFLICT (source,window_start,window_end) DO UPDATE
SET cursor=excluded.cursor,status='running',
    scanned=crm_interno.program_coverage.scanned+excluded.scanned,
    accepted=crm_interno.program_coverage.accepted+excluded.accepted,
    pending=crm_interno.program_coverage.pending+excluded.pending,
    updated_at=now();
```
- [ ] **Step 4: Run** domain suite plus a read-only production sample audit of provider pagination/shape before enabling backfill. If full historic coverage cannot be proven, mark only verified windows complete and show gaps prominently; no invented launch date or total. Release increment 3 and verify the documented covered range in the live panel.

### Task 6: Publicação, documentação e aceite operacional

**Files:** Update B `docs/crm-interno-operacao.md`, R `_codex/docs/crm_interno_evolucao.md`, B release manifest/tooling under `_codex/scripts/` and receipts under `.superpowers/sdd/2026-09-25-crm-todo-santo-dia/`; no unrelated runtime paths.

**Interfaces:** Three release manifests list only the files for their increment. For each, record `{site,path,before_sha256,after_sha256,backup_path,compiled,smoke_status}`. DB migration markers include version and checksum. A rollback restores only files still matching that increment's published hash; additive schema/data remains.

- [ ] **Step 1: Before each increment**, inspect `git status` and relevant diffs in B/R, compare every target's production SHA/baseline, and build a recoverable backup outside the webroot. Reject conflicts rather than overwriting new production changes. Apply only allowlisted additive migrations in a transaction, with checksum and local `crm_test` proof.
- [ ] **Step 2: Validate** targeted CFML/PostgreSQL suite, Business JS syntax/browser desktop+390 px, admin HMAC/CSRF/ADMIN-DEV real context, native Adobe compilation of selected CFML, and no delivery rows created by opening the initiative.
- [ ] **Step 3: Publish** each increment's exact manifest in safe order: database → RoadRunners service/API → Business panel/job. Keep commerce job inactive until its smoke passes. Verify remote hashes, signed read-only report, coverage timestamps, no campaign deliveries/sends, and log only counts/status, never credentials or personal order payloads.
- [ ] **Step 4: Document** source coverage, pending classifications, annuality rule, job monitoring, rollback, and the user's manual test steps: register a new account with another e-mail, start Todo Santo Dia, pay by choice, wait for reconciliation, confirm SKU/user/paid_at/term and orgânico status when no eligible click. The agent does not perform or trigger this purchase.
- [ ] **Step 5: Report** each increment separately as published or blocked with its receipt and observed production behavior. Completion means panel and finance are live, historical coverage is honestly marked, and the user's real purchase can be checked once they make it; do not claim an unperformed purchase succeeded.
