# Pending Business Ads and Voucher Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Permitir que o OWNER de uma conta Business nova e pendente reserve um voucher e prepare uma campanha para um evento pendente, mantendo crédito, revisão e veiculação em espera até as aprovações corretas.

**Architecture:** A preparação usa as tabelas canônicas de campanhas, mantendo ads.campaigns.status = DRAFT, e acrescenta entidades separadas para reserva de voucher e revisão administrativa. Funções PostgreSQL transacionais concentram estados e idempotência; o ColdFusion deriva o contexto autorizado, chama essas funções e apresenta os estados. Pedido de acesso a conta existente permanece sem workspace provisório.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL (schemas ads e public), shell tests com rg, Bootstrap/MDB existente.

**Spec:** docs/superpowers/specs/2026-08-23-pending-business-ads-voucher-flow-design.md

## Global Constraints

- Preparar não significa efetivar: reserva não cria saldo e campanha preparada permanece DRAFT.
- Somente administrador RunnerHub aprova publicidade para veiculação.
- Nenhuma campanha fica ACTIVE sem conta ativa, evento ativo, revisão APPROVED, saldo suficiente e período válido.
- Pedido de acesso a conta existente não recebe acesso provisório; somente OWNER da conta ou administrador RunnerHub pode aprová-lo.
- Toda mutação exige sessão autenticada, CSRF válido e escopo server-side de conta, ator e papel.
- O destino do voucher reservado é sempre a conta provisória criada na solicitação.
- Registros recusados, expirados ou cancelados permanecem para auditoria.
- Preservar as alterações locais já existentes; não resetar nem sobrescrever mudanças fora deste fluxo.
- Não criar worktree: executar no workspace atual, conforme preferência expressa do usuário.
- Todas as mensagens novas devem usar português com acentuação correta.

## File Structure

- _codex/sql/2026-08-24_ads_pending_onboarding.sql: migration, índices, grants e funções transacionais.
- _codex/scripts/test_ads_pending_onboarding_schema.sh: gates da migration e invariantes financeiras.
- _codex/scripts/test_ads_pending_onboarding_access.sh: autorização de conta provisória versus conta existente.
- _codex/scripts/test_ads_pending_onboarding_campaigns.sh: rascunho, envio, revisão e proibição de ativação pelo cliente.
- _codex/scripts/test_ads_pending_onboarding_approvals.sh: integração com decisões de conta e evento.
- includes/backend/backend_login.cfm: rota /ads/ somente para conta nova provisória.
- includes/backend/business_account_context.cfm: contexto provisório separado da conta ativa.
- ads/includes/access.cfm: capacidades provisórias restritas.
- ads/includes/backend.cfm: readiness, queries e actions.
- ads/includes/payments_home.cfm: reserva e estado do voucher.
- ads/includes/workspace_campaign_form.cfm: evento pendente, rascunho e envio.
- ads/includes/workspace_campaigns.cfm: estados e motivos da revisão.
- ads/includes/workspace_admin.cfm: fila global e decisão RunnerHub.
- ads/home.cfm: navegação e avisos persistentes.
- includes/estrutura/home_pending_account.cfm: etapas progressivas.
- includes/estrutura/sidenav.cfm: links ativos somente no caso autorizado.
- administracao/contas/includes/backend.cfm: aplicar/liberar reserva e reavaliar campanhas.
- eventos/includes/backend/backend_evento_solicitacoes.cfm: reavaliar campanhas após decisão do evento.
- _codex/docs/publicidade_ads_phase2_business.md: matriz operacional final.

---

### Task 1: Persistência transacional de reservas e revisões

**Files:**
- Create: _codex/sql/2026-08-24_ads_pending_onboarding.sql
- Create: _codex/scripts/test_ads_pending_onboarding_schema.sh

**Interfaces:**
- Consumes: ads.tb_ad_vouchers, ads.redeem_voucher(bigint,text,integer), ads.activate_campaign(uuid,integer,text), ads.campaigns, ads.advertisements, public.tb_contas e public.tb_conta_eventos.
- Produces: ads.reserve_voucher(bigint,bigint,text,integer), ads.apply_voucher_reservation(bigint,integer), ads.release_voucher_reservation(bigint,integer,text), ads.submit_campaign_review(uuid,bigint,integer,integer), ads.refresh_campaign_review_prerequisites(bigint,integer), ads.cancel_open_campaign_reviews(bigint,integer,text) e ads.review_campaign(uuid,text,integer,text,text).

- [ ] **Step 1: Escrever o teste estático que falha sem a migration**

Criar o script com set -uo pipefail e helpers require_pattern/reject_pattern iguais aos testes Ads existentes. Incluir:

~~~bash
schema="_codex/sql/2026-08-24_ads_pending_onboarding.sql"
require_pattern "$schema" 'CREATE TABLE IF NOT EXISTS ads\.voucher_reservations' "reservas possuem tabela própria"
require_pattern "$schema" 'CHECK.*RESERVED.*APPLIED.*RELEASED.*EXPIRED' "status de reserva é fechado"
require_pattern "$schema" 'CREATE UNIQUE INDEX.*id_ad_voucher.*WHERE.*RESERVED' "voucher tem uma reserva ativa"
require_pattern "$schema" 'CREATE UNIQUE INDEX.*id_solicitacao_cadastro.*WHERE.*RESERVED' "solicitação tem uma reserva ativa"
require_pattern "$schema" 'CREATE TABLE IF NOT EXISTS ads\.campaign_review_requests' "revisões possuem tabela própria"
require_pattern "$schema" 'WAITING_PREREQUISITES.*PENDING_REVIEW.*CHANGES_REQUESTED.*APPROVED.*CANCELED' "status de revisão é fechado"
require_pattern "$schema" 'CREATE TABLE IF NOT EXISTS ads\.campaign_review_history' "histórico imutável existe"
require_pattern "$schema" 'CREATE OR REPLACE FUNCTION ads\.reserve_voucher\(bigint,bigint,text,integer\)' "reserva atômica existe"
require_pattern "$schema" 'FOR UPDATE' "funções bloqueiam concorrência"
require_pattern "$schema" 'CREATE OR REPLACE FUNCTION ads\.apply_voucher_reservation\(bigint,integer\)' "aplicação idempotente existe"
require_pattern "$schema" 'CREATE OR REPLACE FUNCTION ads\.release_voucher_reservation\(bigint,integer,text\)' "liberação auditável existe"
require_pattern "$schema" 'CREATE OR REPLACE FUNCTION ads\.submit_campaign_review\(uuid,bigint,integer,integer\)' "envio existe"
require_pattern "$schema" 'CREATE OR REPLACE FUNCTION ads\.refresh_campaign_review_prerequisites\(bigint,integer\)' "reavaliação existe"
require_pattern "$schema" 'CREATE OR REPLACE FUNCTION ads\.cancel_open_campaign_reviews\(bigint,integer,text\)' "cancelamento em lote existe"
require_pattern "$schema" 'CREATE OR REPLACE FUNCTION ads\.review_campaign\(uuid,text,integer,text,text\)' "decisão administrativa existe"
reject_pattern "$schema" 'UPDATE[[:space:]]+ads\.campaign_review_history' "histórico não é alterado"
reject_pattern "$schema" 'DELETE[[:space:]]+FROM[[:space:]]+ads\.campaign_review_history' "histórico não é apagado"
~~~

- [ ] **Step 2: Executar o teste para confirmar a falha inicial**

Run: bash _codex/scripts/test_ads_pending_onboarding_schema.sh

Expected: FAIL porque a migration ainda não existe.

- [ ] **Step 3: Criar tabelas, constraints, índices e grants**

Implementar:

~~~sql
BEGIN;

CREATE TABLE IF NOT EXISTS ads.voucher_reservations (
    voucher_reservation_id bigserial PRIMARY KEY,
    id_ad_voucher integer NOT NULL REFERENCES ads.tb_ad_vouchers(id_ad_voucher),
    id_conta bigint NOT NULL REFERENCES public.tb_contas(id_conta),
    id_solicitacao_cadastro bigint NOT NULL REFERENCES public.tb_conta_cadastro_solicitacoes(id_solicitacao),
    reserved_by integer NOT NULL REFERENCES public.tb_usuarios(id),
    status text NOT NULL CHECK (status IN ('RESERVED','APPLIED','RELEASED','EXPIRED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    applied_at timestamptz,
    released_at timestamptz,
    expires_at timestamptz,
    transition_reason text
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_ads_voucher_reservation_open_voucher
    ON ads.voucher_reservations (id_ad_voucher) WHERE status = 'RESERVED';
CREATE UNIQUE INDEX IF NOT EXISTS uq_ads_voucher_reservation_open_registration
    ON ads.voucher_reservations (id_solicitacao_cadastro) WHERE status = 'RESERVED';

CREATE TABLE IF NOT EXISTS ads.campaign_review_requests (
    campaign_review_request_id bigserial PRIMARY KEY,
    campaign_id uuid NOT NULL REFERENCES ads.campaigns(campaign_id),
    account_id bigint NOT NULL REFERENCES public.tb_contas(id_conta),
    core_event_id integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento),
    status text NOT NULL CHECK (status IN ('WAITING_PREREQUISITES','PENDING_REVIEW','CHANGES_REQUESTED','APPROVED','CANCELED')),
    requested_by integer NOT NULL REFERENCES public.tb_usuarios(id),
    reviewed_by integer REFERENCES public.tb_usuarios(id),
    submitted_at timestamptz NOT NULL DEFAULT now(),
    reviewed_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now(),
    review_reason text,
    approval_idempotency_key text
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_ads_campaign_review_open
    ON ads.campaign_review_requests (campaign_id)
    WHERE status IN ('WAITING_PREREQUISITES','PENDING_REVIEW','CHANGES_REQUESTED');

CREATE TABLE IF NOT EXISTS ads.campaign_review_history (
    campaign_review_history_id bigserial PRIMARY KEY,
    campaign_review_request_id bigint NOT NULL REFERENCES ads.campaign_review_requests(campaign_review_request_id),
    from_status text,
    to_status text NOT NULL,
    actor_id integer NOT NULL REFERENCES public.tb_usuarios(id),
    reason text,
    changed_at timestamptz NOT NULL DEFAULT now()
);
~~~

Conceder SELECT/INSERT/UPDATE somente nas tabelas mutáveis, SELECT/INSERT no histórico, USAGE/SELECT nas sequences e EXECUTE nas funções para runner. Não conceder DELETE ou UPDATE no histórico.

- [ ] **Step 4: Implementar funções SQL com bloqueio e idempotência**

reserve_voucher deve bloquear solicitação e voucher, confirmar PENDENTE + conta provisória + OWNER do ator, validar código/validade/disponibilidade e repetir a mesma reserva sem duplicá-la. Não pode chamar credit_account ou redeem_voucher.

apply_voucher_reservation deve bloquear a reserva RESERVED da solicitação, garantir que reserva.id_conta = solicitação.id_conta, chamar ads.redeem_voucher para essa conta e mudar para APPLIED apenas após sucesso. Repetição em APPLIED não cria ledger.

release_voucher_reservation deve mudar RESERVED para RELEASED/EXPIRED com motivo e liberar o voucher sem apagar histórico.

submit_campaign_review deve bloquear campanha/anúncio, validar account_id/core_event_id/ator e manter campanha DRAFT. Deve escolher PENDING_REVIEW somente com conta e evento ATIVOS; nos demais casos, WAITING_PREREQUISITES.

refresh_campaign_review_prerequisites deve avançar ou devolver todas as revisões abertas no escopo informado e registrar histórico.

review_campaign deve aceitar apenas APPROVE, REQUEST_CHANGES ou CANCEL. APPROVE revalida conta, evento, período, orçamento, CPC, placement e saldo >= CPC antes de chamar ads.activate_campaign uma vez. REQUEST_CHANGES exige motivo e mantém DRAFT.

Também substituir ads.redeem_voucher com CREATE OR REPLACE para rejeitar voucher que tenha reserva RESERVED em outro fluxo.

- [ ] **Step 5: Executar testes de schema e regressão financeira**

~~~bash
bash _codex/scripts/test_ads_pending_onboarding_schema.sh
bash _codex/scripts/test_ads_voucher_balance_bridge.sh
bash _codex/scripts/test_ads_phase2_payment_services.sh
git diff --check
~~~

Expected: todos PASS; git diff --check sem saída.

- [ ] **Step 6: Commit**

~~~bash
git add _codex/sql/2026-08-24_ads_pending_onboarding.sql _codex/scripts/test_ads_pending_onboarding_schema.sh
git commit -m "feat: add pending ads reservation workflow"
~~~

---

### Task 2: Contexto e autorização do workspace provisório

**Files:**
- Create: _codex/scripts/test_ads_pending_onboarding_access.sh
- Modify: includes/backend/backend_login.cfm
- Modify: includes/backend/business_account_context.cfm
- Modify: ads/includes/access.cfm
- Modify: ads/includes/backend.cfm

**Interfaces:**
- Consumes: businessPendingWorkspace, businessPendingExistingAccountRequest, businessPendingAccountId, businessPendingRegistrationId e qPerfil.id.
- Produces: adsAccessIsPendingNewAccount, adsAccessRegistrationId, adsAccessCanReserveVoucher e adsAccessCanPrepareCampaign.

- [ ] **Step 1: Escrever o teste de acesso**

~~~bash
require_pattern "includes/backend/backend_login.cfm" '"/,/eventos/,/ads/,/faq/,/suporte/"' "ads liberado para conta nova pendente"
require_pattern "ads/includes/access.cfm" 'adsAccessIsPendingNewAccount' "acesso distingue conta nova"
require_pattern "ads/includes/access.cfm" 'businessPendingExistingAccountRequest' "conta existente permanece bloqueada"
require_pattern "ads/includes/access.cfm" 'adsAccessCanReserveVoucher' "reserva tem capacidade própria"
require_pattern "ads/includes/access.cfm" 'adsAccessCanPrepareCampaign' "preparo tem capacidade própria"
reject_pattern "ads/includes/access.cfm" 'adsAccessCanActivateCampaign.*adsAccessIsPendingNewAccount' "pendência nunca permite ativação"
require_pattern "ads/includes/backend.cfm" 'id_solicitacao_cadastro' "backend carrega solicitação proprietária"
require_pattern "ads/includes/backend.cfm" "papel.*OWNER" "backend confirma OWNER"
~~~

- [ ] **Step 2: Rodar o teste e observar a falha**

Run: bash _codex/scripts/test_ads_pending_onboarding_access.sh

Expected: FAIL nas capacidades e na rota /ads/.

- [ ] **Step 3: Liberar /ads/ somente para conta nova provisória**

Em backend_login.cfm:

~~~cfml
<cfset VARIABLES.businessPendingAllowedTemplates = VARIABLES.businessPendingExistingAccountRequest
    ? "/,/faq/,/suporte/"
    : "/,/eventos/,/ads/,/faq/,/suporte/"/>
~~~

Em business_account_context.cfm, expor a conta e a solicitação provisórias separadamente. Não inserir a conta pendente em businessEffectiveAccountIds.

- [ ] **Step 4: Derivar capacidades provisórias e revalidá-las no POST**

Em ads/includes/access.cfm:

~~~cfml
<cfset VARIABLES.adsAccessIsPendingNewAccount = false/>
<cfset VARIABLES.adsAccessRegistrationId = 0/>
<cfset VARIABLES.adsAccessCanReserveVoucher = false/>
<cfset VARIABLES.adsAccessCanPrepareCampaign = false/>

<cfif isDefined("VARIABLES.businessPendingWorkspace")
    AND VARIABLES.businessPendingWorkspace
    AND NOT VARIABLES.businessPendingExistingAccountRequest
    AND isNumeric(VARIABLES.businessPendingAccountId)
    AND isNumeric(VARIABLES.businessPendingRegistrationId)>
    <cfset VARIABLES.adsAccessAccountId = val(VARIABLES.businessPendingAccountId)/>
    <cfset VARIABLES.adsAccessRegistrationId = val(VARIABLES.businessPendingRegistrationId)/>
    <cfset VARIABLES.adsAccessRole = "OWNER"/>
    <cfset VARIABLES.adsAccessIsPendingNewAccount = true/>
</cfif>

<cfset VARIABLES.adsAccessCanReserveVoucher = VARIABLES.adsAccessIsPendingNewAccount AND VARIABLES.adsAccessHasActor/>
<cfset VARIABLES.adsAccessCanPrepareCampaign = VARIABLES.adsAccessIsPendingNewAccount AND VARIABLES.adsAccessHasActor/>
~~~

Antes de mutação provisória, backend.cfm deve consultar solicitação, conta e vínculo e confirmar simultaneamente: solicitação PENDENTE, mesma conta, mesmo usuário, conta não ATIVA e vínculo OWNER do ator. Falha retorna 403 e aborta.

- [ ] **Step 5: Executar testes**

~~~bash
bash _codex/scripts/test_ads_pending_onboarding_access.sh
bash _codex/scripts/test_business_login_routing.sh
bash _codex/scripts/test_business_pending_workspace.sh
bash _codex/scripts/test_ads_phase2_business_access.sh
~~~

Expected: todos PASS.

- [ ] **Step 6: Commit**

~~~bash
git add includes/backend/backend_login.cfm includes/backend/business_account_context.cfm ads/includes/access.cfm ads/includes/backend.cfm _codex/scripts/test_ads_pending_onboarding_access.sh
git commit -m "feat: authorize pending account ads workspace"
~~~

---

### Task 3: Reserva de voucher na conta pendente

**Files:**
- Modify: ads/includes/backend.cfm
- Modify: ads/includes/payments_home.cfm
- Modify: ads/home.cfm
- Modify: _codex/scripts/test_ads_pending_onboarding_access.sh
- Modify: _codex/scripts/test_ads_voucher_balance_bridge.sh

**Interfaces:**
- Consumes: ads.reserve_voucher(bigint,bigint,text,integer) e adsAccessCanReserveVoucher.
- Produces: action reserve_voucher, qAdsV1VoucherReservation e notices de reserva.

- [ ] **Step 1: Acrescentar testes do formulário e da chamada SQL**

~~~bash
require_pattern "$backend" 'adsV1VoucherActions.*redeem_voucher,reserve_voucher' "backend separa resgate e reserva"
require_pattern "$backend" '<cfcase[[:space:]]+value="reserve_voucher".*ads\.reserve_voucher' "reserva usa função transacional"
require_pattern "$payments_home" 'name="ads_v1_action"[[:space:]]+value="reserve_voucher"' "conta pendente envia reserva"
require_pattern "$payments_home" 'Voucher reservado' "interface mostra reserva"
reject_pattern "$backend" '<cfcase[[:space:]]+value="reserve_voucher".*ads\.(credit_account|redeem_voucher)' "reserva não credita"
~~~

- [ ] **Step 2: Rodar e confirmar falha**

Run: bash _codex/scripts/test_ads_pending_onboarding_access.sh

Expected: FAIL na action e no formulário.

- [ ] **Step 3: Implementar action e carregar estado**

~~~cfml
<cfset VARIABLES.adsV1VoucherActions = "redeem_voucher,reserve_voucher"/>
<cfset qAdsV1VoucherReservation = QueryNew("voucher_reservation_id,codigo,credito,status,expires_at,transition_reason")/>

<cfcase value="reserve_voucher">
    <cfif NOT VARIABLES.adsAccessCanReserveVoucher>
        <cfheader statuscode="403" statustext="Forbidden"/>
        <cfthrow type="Ads.PendingVoucher.Forbidden" message="Esta conta não pode reservar voucher."/>
    </cfif>
    <cfquery name="qAdsV1ReserveVoucher" datasource="runnerhub">
        SELECT * FROM ads.reserve_voucher(
            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsAccessRegistrationId#"/> AS bigint),
            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(FORM.voucher_code)#" maxlength="160"/> AS text),
            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer)
        )
    </cfquery>
    <cflocation addtoken="false" url="./?view=payments&success=voucher-reserved#ads-voucher-form"/>
</cfcase>
~~~

Carregar reserva por id_conta + id_solicitacao_cadastro; nunca apenas pelo código do browser.

- [ ] **Step 4: Adaptar payments_home.cfm**

Para conta pendente: título Reservar voucher; texto de que o crédito será aplicado após aprovação; badge Reservado; formulário reserve_voucher; esconder compra de crédito e saldo disponível. Para conta ativa, preservar redeem_voucher e pagamentos atuais.

- [ ] **Step 5: Testar e conferir diff**

~~~bash
bash _codex/scripts/test_ads_pending_onboarding_access.sh
bash _codex/scripts/test_ads_voucher_balance_bridge.sh
bash _codex/scripts/test_ads_phase2_payment_panel.sh
git diff --check
~~~

Expected: todos PASS.

- [ ] **Step 6: Commit**

~~~bash
git add ads/includes/backend.cfm ads/includes/payments_home.cfm ads/home.cfm _codex/scripts/test_ads_pending_onboarding_access.sh _codex/scripts/test_ads_voucher_balance_bridge.sh
git commit -m "feat: reserve vouchers for pending accounts"
~~~

---

### Task 4: Preparação e envio de campanha sem ativação direta

**Files:**
- Create: _codex/scripts/test_ads_pending_onboarding_campaigns.sh
- Modify: ads/includes/backend.cfm
- Modify: ads/includes/workspace_campaign_form.cfm
- Modify: ads/includes/workspace_campaigns.cfm
- Modify: ads/home.cfm
- Modify: _codex/scripts/test_ads_phase2_business_routes.sh
- Modify: _codex/scripts/test_ads_phase2_business_access.sh

**Interfaces:**
- Consumes: ads.save_event_campaign, ads.replace_campaign_placements e ads.submit_campaign_review.
- Produces: action submit_campaign_review, review_status/review_reason e eventos pendentes autorizados.

- [ ] **Step 1: Escrever gates da campanha**

~~~bash
require_pattern "$backend" 'adsV1CampaignActions.*save_campaign,submit_campaign_review,change_campaign_status' "cliente não ativa"
reject_pattern "$backend" '<cfcase[[:space:]]+value="activate_campaign">' "backend comum não ativa"
require_pattern "$backend" '<cfcase[[:space:]]+value="submit_campaign_review".*ads\.submit_campaign_review' "envio cria revisão"
require_pattern "$backend" 'ce\.status::text.*IN.*ATIVO.*PENDENTE' "lista inclui evento pendente"
require_pattern "$backend" 'id_usuario_solicitante.*adsV1ActorId' "evento pendente pertence ao ator"
require_pattern "$form" 'Salvar rascunho' "formulário salva rascunho"
require_pattern "$form" 'Enviar para análise' "formulário envia separado"
require_pattern "$campaigns" 'WAITING_PREREQUISITES|Aguardando pré-requisitos' "lista mostra espera"
require_pattern "$campaigns" 'CHANGES_REQUESTED|Ajustes solicitados' "lista mostra ajustes"
~~~

- [ ] **Step 2: Rodar e confirmar falha**

Run: bash _codex/scripts/test_ads_pending_onboarding_campaigns.sh

Expected: FAIL.

- [ ] **Step 3: Incluir eventos pendentes com escopo estrito**

qAdsV1Events e a validação POST devem aceitar:

~~~sql
WHERE ce.id_conta = :account_id
  AND evt.ativo = true
  AND (
      ce.status::text = 'ATIVO'
      OR (
          :is_pending_new_account = true
          AND ce.status::text = 'PENDENTE'
          AND EXISTS (
              SELECT 1 FROM public.tb_conta_evento_solicitacoes req
              WHERE req.id_conta = ce.id_conta
                AND req.id_evento = ce.id_evento
                AND req.id_usuario_solicitante = :actor_id
                AND req.status = 'PENDENTE'
          )
      )
  )
~~~

- [ ] **Step 4: Separar salvar de enviar**

save_campaign mantém DRAFT. Adicionar:

~~~cfml
<cfcase value="submit_campaign_review">
    <cfquery name="qAdsV1SubmitReview" datasource="runnerhub">
        SELECT * FROM ads.submit_campaign_review(
            CAST(<cfqueryparam cfsqltype="cf_sql_uuid" value="#FORM.campaign_id#"/> AS uuid),
            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.core_event_id#"/> AS integer)
        )
    </cfquery>
    <cflocation addtoken="false" url="./?view=campaigns&success=campaign-submitted"/>
</cfcase>
~~~

Remover activate_campaign das actions e UI comuns. change_campaign_status jamais transforma DRAFT em ACTIVE.

- [ ] **Step 5: Mostrar revisão e dependências**

Adicionar às queries: campaign_review_request_id, review_status, review_reason, submitted_at, reviewed_at, event_link_status e account_status.

Mapear: WAITING_PREREQUISITES = Aguardando conta e/ou evento; PENDING_REVIEW = Em análise pela RunnerHub; CHANGES_REQUESTED = Ajustes solicitados + motivo; APPROVED = estado canônico; sem revisão = Rascunho. Dados em CHANGES_REQUESTED permanecem editáveis.

- [ ] **Step 6: Executar testes**

~~~bash
bash _codex/scripts/test_ads_pending_onboarding_campaigns.sh
bash _codex/scripts/test_ads_phase2_business_routes.sh
bash _codex/scripts/test_ads_phase2_business_access.sh
bash _codex/scripts/test_ads_advertiser_workspace_ui.sh
git diff --check
~~~

Expected: todos PASS.

- [ ] **Step 7: Commit**

~~~bash
git add ads/includes/backend.cfm ads/includes/workspace_campaign_form.cfm ads/includes/workspace_campaigns.cfm ads/home.cfm _codex/scripts/test_ads_pending_onboarding_campaigns.sh _codex/scripts/test_ads_phase2_business_routes.sh _codex/scripts/test_ads_phase2_business_access.sh
git commit -m "feat: submit pending campaigns for review"
~~~

---

### Task 5: Decisão de conta/evento e reavaliação automática

**Files:**
- Create: _codex/scripts/test_ads_pending_onboarding_approvals.sh
- Modify: administracao/contas/includes/backend.cfm
- Modify: eventos/includes/backend/backend_evento_solicitacoes.cfm
- Modify: _codex/scripts/test_ads_voucher_balance_bridge.sh

**Interfaces:**
- Consumes: apply_voucher_reservation, release_voucher_reservation, cancel_open_campaign_reviews e refresh_campaign_review_prerequisites.
- Produces: aplicação única na aprovação, liberação na recusa e avanço/devolução de revisão após evento.

- [ ] **Step 1: Escrever gates das aprovações**

~~~bash
require_pattern "$accounts_backend" 'accountRegistrationAction.*aprovar.*ads\.apply_voucher_reservation' "aprovação aplica reserva"
require_pattern "$accounts_backend" 'accountRegistrationAction.*recusar.*ads\.release_voucher_reservation' "recusa libera reserva"
require_pattern "$accounts_backend" 'ads\.refresh_campaign_review_prerequisites' "conta reavalia campanhas"
require_pattern "$events_backend" 'evento_solicitacao_action.*aprovar.*ads\.refresh_campaign_review_prerequisites' "evento aprovado reavalia"
require_pattern "$events_backend" 'evento_solicitacao_action.*negar.*ads\.refresh_campaign_review_prerequisites' "evento negado devolve"
reject_pattern "$accounts_backend" 'apply_voucher_reservation.*accountRegistrationExistingAccountId' "voucher não muda de conta"
~~~

- [ ] **Step 2: Rodar e confirmar falha**

Run: bash _codex/scripts/test_ads_pending_onboarding_approvals.sh

Expected: FAIL.

- [ ] **Step 3: Integrar decisão da conta na transação existente**

Na aprovação de conta nova:

~~~cfml
SELECT * FROM ads.apply_voucher_reservation(:registration_id, :actor_id);
SELECT ads.refresh_campaign_review_prerequisites(:target_account_id, NULL::integer);
~~~

Na recusa:

~~~cfml
SELECT ads.release_voucher_reservation(:registration_id, :actor_id, 'Conta recusada');
SELECT ads.cancel_open_campaign_reviews(:account_id, :actor_id, 'Conta recusada');
~~~

Pedido de acesso a conta existente não dispara aplicação.

- [ ] **Step 4: Integrar decisão do evento**

Após atualizar tb_conta_eventos e a solicitação:

~~~cfml
SELECT ads.refresh_campaign_review_prerequisites(:account_id, :event_id);
~~~

Evento aprovado avança para PENDING_REVIEW somente se conta ativa. Evento negado/inativo muda revisão aberta para CHANGES_REQUESTED e usa observação do revisor ou Evento não aprovado; escolha outro evento.

- [ ] **Step 5: Rodar testes**

~~~bash
bash _codex/scripts/test_ads_pending_onboarding_approvals.sh
bash _codex/scripts/test_ads_voucher_balance_bridge.sh
bash _codex/scripts/test_business_existing_account_access_request.sh
bash _codex/scripts/test_event_onboarding_progressive_steps.sh
bash _codex/scripts/test_event_request_copy_accents.sh
git diff --check
~~~

Expected: todos PASS.

- [ ] **Step 6: Commit**

~~~bash
git add administracao/contas/includes/backend.cfm eventos/includes/backend/backend_evento_solicitacoes.cfm _codex/scripts/test_ads_pending_onboarding_approvals.sh _codex/scripts/test_ads_voucher_balance_bridge.sh
git commit -m "feat: advance pending ads on approvals"
~~~

---

### Task 6: Fila administrativa e ativação revisada

**Files:**
- Modify: ads/includes/access.cfm
- Modify: ads/includes/backend.cfm
- Modify: ads/includes/workspace_admin.cfm
- Modify: ads/home.cfm
- Modify: _codex/scripts/test_ads_pending_onboarding_campaigns.sh

**Interfaces:**
- Consumes: ads.review_campaign(uuid,text,integer,text,text) e businessRealIsAdmin.
- Produces: approve_campaign_review, request_campaign_changes, cancel_campaign_review e qAdsV1CampaignReviewQueue.

- [ ] **Step 1: Acrescentar testes de admin real**

~~~bash
require_pattern "$access" 'adsAccessCanReviewCampaign.*adsAccessRealIsAdmin' "somente admin real revisa"
require_pattern "$backend" 'approve_campaign_review,request_campaign_changes,cancel_campaign_review' "ações administrativas existem"
require_pattern "$backend" '<cfcase[[:space:]]+value="approve_campaign_review".*ads\.review_campaign' "aprovação usa função canônica"
require_pattern "$backend" 'FROM[[:space:]]+ads\.campaign_review_requests' "fila lê revisões globais"
require_pattern "$admin_home" 'Campanhas aguardando análise' "admin mostra fila"
require_pattern "$admin_home" 'name="review_reason"[^>]*required' "ajustes exigem motivo"
reject_pattern "$campaign_form" 'activate_campaign' "cliente não vê ativação"
~~~

- [ ] **Step 2: Rodar e confirmar falha**

Run: bash _codex/scripts/test_ads_pending_onboarding_campaigns.sh

Expected: FAIL.

- [ ] **Step 3: Criar capacidade e actions**

~~~cfml
<cfset VARIABLES.adsAccessCanReviewCampaign = VARIABLES.adsAccessHasActor AND VARIABLES.adsAccessRealIsAdmin/>
<cfset VARIABLES.adsV1ReviewActions = "approve_campaign_review,request_campaign_changes,cancel_campaign_review"/>
~~~

Cada action valida CSRF, UUID e admin real. Motivo é obrigatório para ajustes/cancelamento, entre 5 e 1000 caracteres. APPROVE envia chave estável business:campaign-review:<review_id>.

- [ ] **Step 4: Carregar e apresentar fila global**

Consultar PENDING_REVIEW com campanha, conta, evento, datas, CPC, orçamento, placements e saldo. Cada solicitação vira um único card com resumo, dependências, aprovação, ajustes e histórico. WAITING_PREREQUISITES aparece informativamente e sem botão de aprovação.

- [ ] **Step 5: Executar testes**

~~~bash
bash _codex/scripts/test_ads_pending_onboarding_campaigns.sh
bash _codex/scripts/test_ads_phase2_business_access.sh
bash _codex/scripts/test_ads_phase2_business_routes.sh
bash _codex/scripts/audit_ads_phase2_business_static.sh
git diff --check
~~~

Expected: todos PASS.

- [ ] **Step 6: Commit**

~~~bash
git add ads/includes/access.cfm ads/includes/backend.cfm ads/includes/workspace_admin.cfm ads/home.cfm _codex/scripts/test_ads_pending_onboarding_campaigns.sh
git commit -m "feat: add RunnerHub campaign review queue"
~~~

---

### Task 7: Home progressiva, navegação e cópia

**Files:**
- Modify: includes/estrutura/home_pending_account.cfm
- Modify: includes/estrutura/sidenav.cfm
- Modify: ads/home.cfm
- Modify: _codex/scripts/test_business_pending_workspace.sh
- Modify: _codex/tests/business-sidenav.test.js

**Interfaces:**
- Consumes: estados de reserva, solicitações de evento e revisões.
- Produces: CTAs ativos Reservar voucher e Preparar campanha somente quando autorizados.

- [ ] **Step 1: Estender testes de UI**

~~~bash
require_pattern "$home_pending" 'href="/ads/\?view=payments#ads-voucher-form"' "etapa três abre reserva"
require_pattern "$home_pending" 'href="/ads/\?view=campaigns&amp;mode=new#campaign-form"' "etapa quatro abre campanha"
require_pattern "$home_pending" 'Reservado|Aguardando conta|Aguardando evento|Em análise|Ajustes solicitados' "home mostra estados"
require_pattern "$sidenav" 'href="/ads/' "conta nova pendente possui publicidade"
require_pattern "$sidenav" 'businessPendingExistingAccountRequest.*disabled' "conta existente permanece bloqueada"
~~~

No teste JS, incluir item ativo e item aria-disabled=true sem navegação.

- [ ] **Step 2: Rodar e confirmar falha**

~~~bash
bash _codex/scripts/test_business_pending_workspace.sh
node --test _codex/tests/business-sidenav.test.js
~~~

Expected: FAIL nos novos CTAs/estados.

- [ ] **Step 3: Carregar progresso real**

Uma query retorna event_requests, voucher_status, voucher_amount, campaign_count, campaign_review_status e campaign_review_reason.

Etapa 3 fica ativa desde a criação da conta; mostra Reservado quando RESERVED. Etapa 4 fica ativa após event_requests > 0; antes disso fica alpha/disabled com Vincule um evento primeiro. CHANGES_REQUESTED mostra motivo e Corrigir campanha. Pedido em conta existente mostra Aguardando OWNER ou equipe RunnerHub.

- [ ] **Step 4: Atualizar sidenav e aviso de Ads**

Conta nova: Reservar voucher aponta para /ads/?view=payments#ads-voucher-form; Publicidade aponta para /ads/?view=campaigns. Pedido em conta existente mantém ambos aria-disabled=true.

Aviso persistente:

~~~text
Você pode preparar tudo agora. O voucher só vira saldo após a aprovação da conta, e a campanha só poderá entrar no ar após a aprovação da conta, do evento e da equipe RunnerHub.
~~~

- [ ] **Step 5: Executar testes**

~~~bash
bash _codex/scripts/test_business_pending_workspace.sh
node --test _codex/tests/business-sidenav.test.js
bash _codex/scripts/test_event_onboarding_progressive_steps.sh
bash _codex/scripts/test_ads_advertiser_workspace_ui.sh
git diff --check
~~~

Expected: todos PASS.

- [ ] **Step 6: Commit**

~~~bash
git add includes/estrutura/home_pending_account.cfm includes/estrutura/sidenav.cfm ads/home.cfm _codex/scripts/test_business_pending_workspace.sh _codex/tests/business-sidenav.test.js
git commit -m "feat: expose pending ads onboarding steps"
~~~

---

### Task 8: Verificação integrada, documentação e implantação

**Files:**
- Modify: _codex/docs/publicidade_ads_phase2_business.md
- Modify: docs/superpowers/plans/2026-08-24-pending-business-ads-voucher-flow.md

**Interfaces:**
- Consumes: Tasks 1–7.
- Produces: evidência reproduzível, matriz de estados e checklist de rollout.

- [ ] **Step 1: Documentar a matriz final**

| Conta | Evento | Revisão | Campanha | Resultado |
|---|---|---|---|---|
| Pendente | Pendente | WAITING_PREREQUISITES | DRAFT | Preparável, fora do ar |
| Ativa | Pendente | WAITING_PREREQUISITES | DRAFT | Aguarda evento |
| Pendente | Ativo | WAITING_PREREQUISITES | DRAFT | Aguarda conta |
| Ativa | Ativo | PENDING_REVIEW | DRAFT | Aguarda RunnerHub |
| Ativa | Ativo | CHANGES_REQUESTED | DRAFT | Usuário corrige |
| Ativa | Ativo | APPROVED | ACTIVE | Elegível ao delivery se saldo/período válidos |

Registrar que pedido de acesso a conta existente não entra nessa matriz até OWNER/admin aprovar.

- [ ] **Step 2: Executar a suíte relacionada**

~~~bash
bash _codex/scripts/test_ads_pending_onboarding_schema.sh
bash _codex/scripts/test_ads_pending_onboarding_access.sh
bash _codex/scripts/test_ads_pending_onboarding_campaigns.sh
bash _codex/scripts/test_ads_pending_onboarding_approvals.sh
bash _codex/scripts/test_ads_voucher_balance_bridge.sh
bash _codex/scripts/test_ads_phase2_business_access.sh
bash _codex/scripts/test_ads_phase2_business_routes.sh
bash _codex/scripts/test_ads_advertiser_workspace_ui.sh
bash _codex/scripts/test_business_login_routing.sh
bash _codex/scripts/test_business_pending_workspace.sh
bash _codex/scripts/test_business_existing_account_access_request.sh
bash _codex/scripts/test_event_onboarding_progressive_steps.sh
bash _codex/scripts/test_event_request_copy_accents.sh
node --test _codex/tests/business-sidenav.test.js
git diff --check
~~~

Expected: todos PASS e diff check limpo.

- [ ] **Step 3: Compilar ColdFusion no servidor antes de publicar**

~~~bash
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/business.roadrunners.run -dir /var/www/business.roadrunners.run/ads
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/business.roadrunners.run -dir /var/www/business.roadrunners.run/administracao/contas
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/business.roadrunners.run -dir /var/www/business.roadrunners.run/eventos
~~~

Expected: exit code 0 nos três diretórios.

- [ ] **Step 4: Validar jornada real com dados controlados**

1. Entrar com Google sem conta e criar conta provisória.
2. Solicitar evento e confirmar que aparece no formulário.
3. Reservar voucher e confirmar que saldo não mudou.
4. Salvar campanha, enviar e confirmar WAITING_PREREQUISITES + ausência no delivery.
5. Aprovar conta e confirmar APPLIED uma vez, campanha ainda DRAFT.
6. Aprovar evento e confirmar PENDING_REVIEW, ainda fora do ar.
7. Solicitar ajuste e confirmar motivo/dados preservados.
8. Reenviar e aprovar como admin; confirmar APPROVED + ativação canônica única.
9. Repetir aprovação e confirmar idempotência.
10. Criar pedido para conta existente e confirmar /ads/ bloqueado até OWNER/admin.
11. Repetir em desktop e largura mobile.

- [ ] **Step 5: Conferir banco e delivery**

~~~sql
SELECT status, count(*) FROM ads.voucher_reservations GROUP BY status ORDER BY status;
SELECT status, count(*) FROM ads.campaign_review_requests GROUP BY status ORDER BY status;
SELECT campaign_id, from_status, to_status, actor_id, changed_at
FROM ads.campaign_review_history
ORDER BY campaign_review_history_id DESC LIMIT 20;
SELECT c.campaign_id, c.status, r.status AS review_status
FROM ads.campaigns c
JOIN ads.campaign_review_requests r USING (campaign_id)
WHERE r.campaign_review_request_id = :tested_review_id;
~~~

Expected: uma reserva aplicada, histórico completo, nenhuma duplicidade e ACTIVE somente após APPROVED.

- [ ] **Step 6: Registrar resultados e commit final**

Marcar os checkboxes executados, registrar comandos/horários/resultados reais e:

~~~bash
git add _codex/docs/publicidade_ads_phase2_business.md docs/superpowers/plans/2026-08-24-pending-business-ads-voucher-flow.md
git commit -m "docs: record pending ads rollout checks"
~~~
