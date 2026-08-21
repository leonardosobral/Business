# Ads V1 Canonical Business Pilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar no Business um painel administrativo isolado para operar e observar campanhas canônicas Ads V1 sem modificar o Turbinado legado.

**Architecture:** A rota `/ads/canonical/` reutiliza autenticação, layout e seletor de conta do Business, mas mantém backend e interface próprios. Leituras usam tabelas qualificadas do schema `ads`; mutações usam somente as seis funções SQL aprovadas, com conta efetiva, CSRF, parâmetros tipados e Post/Redirect/Get.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL, datasource `runnerhub`, Bootstrap/MDB existente, Bash/Ripgrep para auditoria estática.

**Spec:** `_codex/docs/publicidade_ads_v1_piloto_canonical_design.md`

## Global Constraints

- O banco permanece como schema `ads` dentro do PostgreSQL principal `runnerhub`.
- Nenhum arquivo pode usar o datasource `runner_dba` para a Ads V1.
- Nenhuma mutação pode executar DML direto em tabelas canônicas.
- Não há dual-write, migração de dados legados nem mudança no serving do RoadRunners neste incremento.
- Toda mutação usa POST, token CSRF, parâmetros SQL tipados e Post/Redirect/Get após sucesso.
- A identidade administrativa é `VARIABLES.businessRealIsAdmin`; `businessEffectiveIsAdmin` não serve como guard durante simulação de conta.
- A operação exige um único `VARIABLES.businessActiveAccountId` válido.
- Campanhas EVENT podem selecionar um ou mais dos cinco placements nativos permitidos; banner não é aceito nesse formulário. O destino é derivado no servidor como `https://roadrunners.run/evento/<tag>/`.
- Campanhas e lançamentos nunca são apagados; usam status ou estorno compensatório.
- Não criar commit, branch, tag ou push sem solicitação explícita do usuário.

---

### Task 1: Guard administrativo, readiness e auditoria estática inicial

**Files:**
- Create: `ads/canonical/index.cfm`
- Create: `ads/canonical/includes/backend.cfm`
- Create: `_codex/scripts/audit_ads_v1_business_pilot_static.sh`

**Interfaces:**
- Consumes: `VARIABLES.businessRealIsAdmin`, `VARIABLES.businessActiveAccountId`, `qPerfil.id`, datasource `runnerhub`.
- Produces: `VARIABLES.adsV1ApiReady`, `VARIABLES.adsV1HasAccount`, `VARIABLES.adsV1CanMutate`, `VARIABLES.adsV1AccountId`, `VARIABLES.adsV1Csrf`.

- [ ] **Step 1: Criar o audit estático em estado vermelho**

O script deve terminar com erro enquanto a rota ou os contratos ainda estiverem ausentes e verificar estes padrões:

```bash
test -f ads/canonical/index.cfm
test -f ads/canonical/includes/backend.cfm
test -f ads/canonical/includes/home.cfm
! rg -n 'datasource="runner_dba"' ads/canonical
rg -n 'datasource="runnerhub"' ads/canonical/includes/backend.cfm
rg -n 'ads\.(save_event_campaign|replace_campaign_placements|activate_campaign|change_campaign_status|credit_account|reverse_click_debit)' ads/canonical/includes/backend.cfm
! rg -n '(INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM)[[:space:]]+ads\.(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)' ads/canonical --glob '*.cfm'
```

- [ ] **Step 2: Executar o audit e confirmar a falha esperada**

Run: `bash _codex/scripts/audit_ads_v1_business_pilot_static.sh`

Expected: `FAIL` porque os arquivos da rota e da interface ainda não existem.

- [ ] **Step 3: Criar a entrada da rota e o guard local**

`ads/canonical/index.cfm` deve incluir, nesta ordem:

```cfm
<cfset VARIABLES.template = "/ads/canonical/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfif NOT isDefined("VARIABLES.businessRealIsAdmin") OR NOT VARIABLES.businessRealIsAdmin>
    <cfcontent reset="true"/>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <!doctype html><html lang="pt-br"><body>Acesso restrito.</body></html>
    <cfabort/>
</cfif>
<cfinclude template="includes/backend.cfm"/>
<cfinclude template="../../includes/estrutura/head.cfm"/>
```

O guard é local e não modifica `includes/backend/require_admin.cfm`.

- [ ] **Step 4: Implementar contexto, CSRF e readiness**

O backend inicializa queries vazias para que a interface tolere indisponibilidade, gera `SESSION.adsV1CanonicalCsrf` e resolve a conta exclusivamente de `businessActiveAccountId`:

```cfm
<cfset VARIABLES.adsV1AccountId = isDefined("VARIABLES.businessActiveAccountId")
    AND isNumeric(VARIABLES.businessActiveAccountId)
    ? val(VARIABLES.businessActiveAccountId) : 0/>
<cfset VARIABLES.adsV1HasAccount = VARIABLES.adsV1AccountId GT 0/>
```

A query de readiness usa `to_regprocedure` com as assinaturas completas e `has_function_privilege(current_user, procedure_oid, 'EXECUTE')`. Qualquer exceção deixa `adsV1ApiReady=false`; `adsV1CanMutate` só é verdadeiro com identidade administrativa real, conta única e API pronta.

- [ ] **Step 5: Rodar verificações do primeiro recorte**

Run:

```bash
bash _codex/scripts/audit_ads_v1_business_pilot_static.sh
git diff --check
```

Expected: o audit ainda pode falhar apenas pela ausência de `home.cfm`; `git diff --check` deve passar.

### Task 2: Leituras canônicas isoladas por conta

**Files:**
- Modify: `ads/canonical/includes/backend.cfm`

**Interfaces:**
- Consumes: `VARIABLES.adsV1AccountId`, `VARIABLES.adsV1ApiReady`, `VARIABLES.roadRunnersBaseUrl`.
- Produces: `qAdsV1Account`, `qAdsV1Events`, `qAdsV1Campaigns`, `qAdsV1Ledger`, `qAdsV1ReversibleDebits`, `qAdsV1StatusHistory`, `VARIABLES.adsV1Summary`.

- [ ] **Step 1: Acrescentar assertions estáticas para isolamento por conta**

O audit deve exigir `c.account_id = <cfqueryparam`, `ledger.account_id = <cfqueryparam` e o vínculo de evento `ce.id_conta = <cfqueryparam` no backend.

- [ ] **Step 2: Executar o audit e confirmar a falha esperada**

Run: `bash _codex/scripts/audit_ads_v1_business_pilot_static.sh`

Expected: `FAIL` nas leituras ainda ausentes.

- [ ] **Step 3: Consultar conta e eventos elegíveis**

Somente quando houver uma conta ativa, carregar conta `ATIVA` e eventos com vínculo `ATIVO`:

```sql
SELECT evt.id_evento, evt.nome_evento, evt.tag, evt.data_inicial,
       evt.data_final, evt.cidade, evt.estado
FROM public.tb_conta_eventos ce
JOIN public.tb_evento_corridas evt ON evt.id_evento = ce.id_evento
WHERE ce.id_conta = :account_id
  AND ce.status = 'ATIVO'::public.status_conta_evento
  AND evt.ativo
ORDER BY evt.data_inicial DESC NULLS LAST, evt.nome_evento
```

- [ ] **Step 4: Consultar campanhas, saldo e métricas**

A consulta deve partir de `ads.campaigns c`, filtrar `c.account_id=:account_id` e `c.billing_model='CPC'`, e fazer joins/laterais qualificados com `ads.advertisements`, `ads.creatives`, `ads.campaign_placements`, `ads.placements`, `ads.campaign_budget_state`, `ads.daily_metrics` e `public.tb_evento_corridas`. Saldo vem de `ads.account_balances` com `COALESCE(...,0)`.

- [ ] **Step 5: Consultar ledger, débitos reversíveis e histórico**

O ledger deve ser limitado aos 50 lançamentos mais recentes. Débitos reversíveis são `DEBIT/CLICK` sem linha `REVERSAL` cujo `reference_entry_id` aponte para o débito. O histórico deve ser filtrado pela mesma conta e limitado aos 50 registros mais recentes.

- [ ] **Step 6: Executar o audit**

Run: `bash _codex/scripts/audit_ads_v1_business_pilot_static.sh`

Expected: passam os checks de datasource, schema qualificado e filtro por conta.

### Task 3: Mutações somente pela API SQL

**Files:**
- Modify: `ads/canonical/includes/backend.cfm`

**Interfaces:**
- Consumes: `FORM.ads_v1_action`, `FORM.ads_v1_csrf`, `VARIABLES.adsV1AccountId`, `qPerfil.id`.
- Produces: redirects `./?success=<code>`; em erro de validação, `VARIABLES.adsV1Error` e valores do formulário preservados.
- SQL contracts:
  - `ads.save_event_campaign(uuid,bigint,integer,text,text,text,numeric,numeric,numeric,timestamptz,timestamptz,text,character,text,integer)`
  - `ads.activate_campaign(uuid,integer,text)`
  - `ads.change_campaign_status(uuid,text,integer,text)`
  - `ads.credit_account(bigint,numeric,text,text,integer,jsonb)`
  - `ads.reverse_click_debit(uuid,text,integer,text)`

- [ ] **Step 1: Fazer o audit exigir POST, CSRF e as cinco funções**

O script deve exigir `FORM.ads_v1_action`, `FORM.ads_v1_csrf`, comparação com `VARIABLES.adsV1Csrf` e cada chamada `SELECT * FROM ads.<funcao>`.

- [ ] **Step 2: Executar o audit e confirmar a falha esperada**

Run: `bash _codex/scripts/audit_ads_v1_business_pilot_static.sh`

Expected: `FAIL` nas funções ainda não chamadas.

- [ ] **Step 3: Implementar validação comum das ações**

Antes do switch de ação:

```cfm
<cfif len(trim(FORM.ads_v1_action & ""))>
    <cfif NOT VARIABLES.adsV1CanMutate><cfthrow type="AdsV1.Validation" message="Operação indisponível."/></cfif>
    <cfif compare(trim(FORM.ads_v1_csrf & ""), VARIABLES.adsV1Csrf) NEQ 0><cfthrow type="AdsV1.Validation" message="A sessão do formulário expirou."/></cfif>
</cfif>
```

O operador vem de `qPerfil.id`. UUIDs devem passar por regex antes de qualquer cast SQL.

- [ ] **Step 4: Implementar salvar campanha**

Validar evento pertencente à conta, nome, CPC positivo com duas casas, orçamento total positivo, orçamento diário opcional e não maior que o total, janela de datas, device, região e ao menos um placement da allowlist EVENT. Derivar destino de `qAdsV1EventTarget.tag` e chamar `ads.save_event_campaign` e `ads.replace_campaign_placements` na mesma transação. `campaign_id` vazio cria `DRAFT`; preenchido só edita campanha `DRAFT` ou `PAUSED` da conta.

- [ ] **Step 5: Implementar crédito idempotente**

Validar valor e justificativa, aceitar apenas uma chave `business:manual-credit:<account_id>:<uuid>` criada pelo servidor e chamar:

```sql
SELECT *
FROM ads.credit_account(
    CAST(:account_id AS bigint), CAST(:amount AS numeric),
    CAST(:idempotency_key AS text), CAST('MANUAL' AS text),
    CAST(:actor_id AS integer), CAST(:metadata AS jsonb)
)
```

- [ ] **Step 6: Implementar ativar, pausar e finalizar**

Confirmar que a campanha pertence à conta. `activate_campaign` aceita `DRAFT` ou `PAUSED`; `change_campaign_status` recebe somente `PAUSED` ou `ENDED`, de acordo com o estado atual. Motivo é obrigatório para encerrar.

- [ ] **Step 7: Implementar estorno idempotente**

Confirmar que o ledger original pertence à conta, é `DEBIT/CLICK` e não tem estorno. Chamar `ads.reverse_click_debit` com motivo obrigatório e chave `business:click-reversal:<ledger_entry_id>:<uuid>` gerada pelo servidor.

- [ ] **Step 8: Registrar falhas sem expor detalhes e aplicar PRG**

Em sucesso, redirecionar para `./?success=campaign-saved|credited|activated|paused|ended|reversed`. Em exceção, usar `cflog file="business_ads_v1" type="error"` com ação, conta, operador e mensagem técnica; mostrar ao usuário texto de validação conhecido ou mensagem genérica.

- [ ] **Step 9: Executar audit e diff check**

Run:

```bash
bash _codex/scripts/audit_ads_v1_business_pilot_static.sh
git diff --check
```

Expected: passam os checks de POST, CSRF, funções e ausência de DML direto.

### Task 4: Interface administrativa responsiva

**Files:**
- Create: `ads/canonical/includes/home.cfm`

**Interfaces:**
- Consumes: todas as variáveis e queries públicas produzidas por `backend.cfm`.
- Produces: formulários POST com `ads_v1_action`, `ads_v1_csrf` e chaves idempotentes; nenhum link GET mutável.

- [ ] **Step 1: Criar estados explícitos da página**

A interface deve renderizar, sem consultar dados inexistentes:

1. aviso de API indisponível;
2. pedido para escolher uma conta no seletor superior;
3. painel operacional com conta válida.

- [ ] **Step 2: Criar resumo e lista de campanhas**

Mostrar saldo BRL, contagem por status, investimento e métricas canônicas. Cada campanha exibe evento, status, CPC, orçamento, gasto, janela e ações POST compatíveis: editar, ativar/retomar, pausar e encerrar.

- [ ] **Step 3: Criar formulário de campanha**

O formulário usa `<select>` preenchido por `qAdsV1Events`, campos monetários `step="0.01"`, datas `datetime-local`, device controlado, país `BR`, região opcional e hidden CSRF. Em edição, dados vêm da campanha selecionada por GET somente para leitura.

- [ ] **Step 4: Criar crédito e histórico financeiro**

O crédito manual contém valor, justificativa e chave idempotente hidden. O histórico distingue `CREDIT`, `DEBIT` e `REVERSAL`. Somente débitos presentes em `qAdsV1ReversibleDebits` recebem formulário de estorno.

- [ ] **Step 5: Validar encoding e ações**

Todo dado de banco ou formulário exibido usa `htmlEditFormat`; URLs/IDs usam valores validados. O audit deve confirmar que todos os formulários mutáveis usam `method="post"` e CSRF.

### Task 5: Entrada pelo legado, documentação e fechamento estático

**Files:**
- Modify: `ads/home.cfm:387-401`
- Create: `../RoadRunners/_codex/sql/2026-08-18_ads_v1_business_read_grants.sql`
- Modify: `_codex/docs/publicidade_ads_v1_piloto_canonical_design.md`
- Modify: `_codex/docs/publicidade_ads_schema_fase1_business.md`
- Modify: `_codex/scripts/audit_ads_v1_business_pilot_static.sh`

**Interfaces:**
- Consumes: rota pronta `/ads/canonical/`.
- Produces: acesso **Ads V1 Piloto**, registro dos arquivos/objetos/validações e audit final verde.

- [ ] **Step 1: Adicionar link administrativo no Turbinado legado**

Dentro do hero existente, mostrar o link somente quando `VARIABLES.businessRealIsAdmin` for verdadeiro:

```cfm
<cfif isDefined("VARIABLES.businessRealIsAdmin") AND VARIABLES.businessRealIsAdmin>
  <a class="btn btn-outline-info" href="/ads/canonical/">Ads V1 Piloto</a>
</cfif>
```

- [ ] **Step 2: Atualizar a documentação operacional da Fase 1**

Registrar arquivos criados/modificados, cinco funções consumidas, datasource `runnerhub`, ausência de dual-write, validações executadas, dependência futura do shadow mode e ordem de publicação Business → smoke test → RoadRunners shadow mode.

- [ ] **Step 3: Executar o conjunto estático final**

Run:

```bash
bash _codex/scripts/audit_ads_v1_business_pilot_static.sh
rg -n 'datasource="runner_dba"' ads/canonical
rg -n '(INSERT[[:space:]]+INTO|UPDATE|DELETE[[:space:]]+FROM)[[:space:]]+ads\.(campaigns|advertisements|creatives|campaign_placements|account_balances|credit_ledger|campaign_budget_state|campaign_status_history|daily_metrics)' ads/canonical --glob '*.cfm'
git diff --check
git status --short
```

Expected: audit `PASS`; os dois `rg` negativos não encontram ocorrências; `git diff --check` não produz saída; status lista somente os arquivos deste incremento.

- [ ] **Step 4: Preparar smoke test de produção**

Entregar ao usuário esta ordem, sem executar deploy nem mutações externas:

1. aplicar o grant mínimo de leitura e conferir `status = PASS`;
2. publicar os arquivos Business;
3. abrir `/ads/canonical/` como admin global sem conta e confirmar bloqueio;
4. selecionar conta controlada;
5. criar/editar campanha `DRAFT`;
6. creditar valor mínimo e repetir submissão idempotente;
7. ativar, pausar/retomar e encerrar;
8. executar estorno apenas se existir débito CPC de teste;
9. rodar o audit canônico no banco;
10. conferir o legado `/ads/` e os anúncios atuais do RoadRunners.

- [ ] **Step 5: Parar antes de commit ou deploy**

Apresentar os arquivos modificados, validações, riscos e instruções. Commit e publicação dependem de ação explícita do usuário.
