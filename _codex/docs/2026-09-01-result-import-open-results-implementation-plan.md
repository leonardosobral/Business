# Result Import Open Results Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persistir `open_results_enabled` no recebimento da API, exibir a intenção na fila Business sem fetch remoto e manter o `openResultsEnabled` do `event.json` como fonte autoritativa no processamento RaceTag.

**Architecture:** Uma coluna booleana aditiva, `open_results_enabled`, guarda o valor efetivo do payload com default `true`. A API valida o literal JSON, inclui a flag no hash novo e preserva retries de hashes legados; o Business lê apenas o banco para a fila, enquanto o processador combina a intenção persistida com o `event.json` atual conforme a tabela de precedência da especificação.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL, JavaScript sem framework, Node.js `node:test`, OpenAPI 3.1, shell/SSH/rsync para validação e publicação.

**Spec:** `_codex/docs/2026-09-01-result-import-open-results-design.md`

## Global Constraints

- O nome público do campo é exatamente `open_results_enabled`; o `event.json` externo continua usando `openResultsEnabled`.
- O campo aceita somente booleanos JSON; omissão equivale a `true`.
- A fila Business não consulta `event.json` nem qualquer URL externa.
- Booleano válido do `event.json` prevalece; campo ausente usa o payload persistido como fallback; valor inválido bloqueia.
- Override continua exclusivo para administrador interno, com confirmação explícita, CSRF e log.
- A migração de banco precisa preceder qualquer código que selecione ou insira a nova coluna.
- Preservar todas as alterações não relacionadas já existentes nos dois worktrees.
- Não criar commit nem fazer push sem autorização explícita do usuário.

---

### Task 1: Migração e referências de schema

**Files:**
- Create: `/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-09-01_result_import_open_results.sql`
- Create: `/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-09-01_verify_result_import_open_results.sql`
- Modify: `/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/schema.sql`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/sql/ddl.sql`
- Create: `/Users/Shared/Projects/RunnerHub/Business/_codex/tests/result-import-open-results-contract.test.js`

**Interfaces:**
- Consumes: tabela existente `public.tb_resultados_importacoes`.
- Produces: coluna `open_results_enabled boolean NOT NULL DEFAULT true` disponível para API e Business.

- [ ] **Step 1: Escrever o teste contratual de schema**

Criar o teste Node com leitura dos arquivos reais dos dois repositórios:

```js
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const businessRoot = path.resolve(__dirname, "../..");
const roadRunnersRoot = path.resolve(__dirname, "../../../RoadRunners");

function read(root, relativePath) {
    return fs.readFileSync(path.join(root, relativePath), "utf8");
}

test("defines an idempotent non-null open-results column with default true", () => {
    const migration = read(roadRunnersRoot, "_codex/sql/2026-09-01_result_import_open_results.sql");
    const verification = read(roadRunnersRoot, "_codex/sql/2026-09-01_verify_result_import_open_results.sql");
    const apiSchema = read(roadRunnersRoot, "_codex/sql/schema.sql");
    const businessSchema = read(businessRoot, "_codex/sql/ddl.sql");

    assert.match(migration, /add column if not exists open_results_enabled boolean/i);
    assert.match(migration, /alter column open_results_enabled set default true/i);
    assert.match(migration, /alter column open_results_enabled set not null/i);
    assert.match(verification, /open_results_enabled/i);
    assert.match(apiSchema, /open_results_enabled\s+boolean\s+default true\s+not null/i);
    assert.match(businessSchema, /open_results_enabled\s+boolean\s+default true\s+not null/i);
});
```

- [ ] **Step 2: Rodar o teste e confirmar a falha correta**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js
```

Expected: FAIL porque os scripts e a coluna ainda não existem.

- [ ] **Step 3: Criar a migração idempotente**

Usar transação e tornar seguro um ambiente que já possua a coluna nullable:

```sql
begin;

alter table public.tb_resultados_importacoes
    add column if not exists open_results_enabled boolean;

update public.tb_resultados_importacoes
set open_results_enabled = true
where open_results_enabled is null;

alter table public.tb_resultados_importacoes
    alter column open_results_enabled set default true;

alter table public.tb_resultados_importacoes
    alter column open_results_enabled set not null;

commit;
```

- [ ] **Step 4: Criar a verificação executável**

O script deve falhar se tipo, nulabilidade, default ou dados estiverem incorretos:

```sql
do $$
declare
    v_type text;
    v_nullable text;
    v_default text;
    v_nulls bigint;
begin
    select data_type, is_nullable, column_default
      into v_type, v_nullable, v_default
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'tb_resultados_importacoes'
       and column_name = 'open_results_enabled';

    if v_type is distinct from 'boolean'
       or v_nullable is distinct from 'NO'
       or coalesce(v_default, '') not ilike '%true%' then
        raise exception 'open_results_enabled invalida: type=%, nullable=%, default=%',
            v_type, v_nullable, v_default;
    end if;

    select count(*) into v_nulls
      from public.tb_resultados_importacoes
     where open_results_enabled is null;

    if v_nulls <> 0 then
        raise exception 'open_results_enabled possui % nulos', v_nulls;
    end if;
end $$;

select current_database() as database,
       current_user as role,
       count(*) as total,
       count(*) filter (where open_results_enabled) as enabled,
       count(*) filter (where not open_results_enabled) as disabled
from public.tb_resultados_importacoes;
```

- [ ] **Step 5: Atualizar os dois schemas de referência**

Adicionar a coluna junto de `status_publicacao` nos dois `CREATE TABLE`:

```sql
open_results_enabled boolean default true not null,
```

- [ ] **Step 6: Rodar o teste contratual**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js
```

Expected: PASS no teste de schema.

- [ ] **Step 7: Revisar o diff sem commit**

Run:

```bash
git -C /Users/Shared/Projects/RunnerHub/RoadRunners diff --check
git -C /Users/Shared/Projects/RunnerHub/Business diff --check
```

Expected: ambos com exit 0 e sem saída.

---

### Task 2: Validação, persistência e idempotência da API

**Files:**
- Modify: `/Users/Shared/Projects/RunnerHub/RoadRunners/services/ResultImportSubmissionService.cfc`
- Modify: `/Users/Shared/Projects/RunnerHub/RoadRunners/repositories/ResultImportRepository.cfc`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/tests/result-import-open-results-contract.test.js`

**Interfaces:**
- Consumes: `open_results_enabled boolean NOT NULL DEFAULT true` da Task 1.
- Produces: `validation.openResultsEnabled:boolean`, `submission.openResultsEnabled:boolean`, hash canônico novo e resposta com `open_results_enabled:boolean`.

- [ ] **Step 1: Acrescentar testes contratuais da API**

Adicionar testes que leem os CFML reais e exigem todos os pontos de integração:

```js
test("accepts and returns open_results_enabled while keeping the internal boolean flow", () => {
    const service = read(roadRunnersRoot, "services/ResultImportSubmissionService.cfc");
    const repository = read(roadRunnersRoot, "repositories/ResultImportRepository.cfc");

    assert.match(service, /getPayloadBoolean\(arguments\.payload,\s*"open_results_enabled",\s*true\)/);
    assert.match(service, /"open_results_enabled"\s*=\s*getRowValue/);
    assert.match(service, /serializeJSON\(arguments\.payload\[arguments\.key\]\)/);
    assert.match(service, /submission\.openResultsEnabled/);
    assert.match(service, /legacyPayloadHash/);
    assert.match(service, /open_results_enabled/);
    assert.match(repository, /open_results_enabled/);
    assert.match(repository, /:openResultsEnabled/);
    assert.match(repository, /cf_sql_bit/);
});
```

Adicionar também um teste de ordem do hash para impedir que a flag seja omitida do canônico novo:

```js
test("keeps a legacy hash path and appends the boolean only to the new hash", () => {
    const service = read(roadRunnersRoot, "services/ResultImportSubmissionService.cfc");

    assert.match(service, /buildPayloadHash\(submission,\s*true\)/);
    assert.match(service, /buildPayloadHash\(submission,\s*false\)/);
    assert.match(service, /includeOpenResultsEnabled/);
});
```

- [ ] **Step 2: Rodar os testes e confirmar a falha**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js
```

Expected: FAIL nas asserções de serviço e repositório.

- [ ] **Step 3: Implementar parsing booleano estrito**

Adicionar `open_results_enabled` a `allowedPayloadKeys` e criar um helper que não use `isBoolean`, pois CFML aceita algumas strings como booleanas:

```cfml
private struct function getPayloadBoolean(
    required struct payload,
    required string key,
    boolean defaultValue = true
) output="false" {
    var serialized = "";

    if (!structKeyExists(arguments.payload, arguments.key)) {
        return { "success" = true, "value" = arguments.defaultValue };
    }

    if (isNull(arguments.payload[arguments.key])) {
        return { "success" = false, "value" = arguments.defaultValue };
    }

    try {
        serialized = lCase(trim(serializeJSON(arguments.payload[arguments.key])));
    } catch (any invalidBoolean) {
        return { "success" = false, "value" = arguments.defaultValue };
    }

    if (serialized EQ "true" || serialized EQ "false") {
        return { "success" = true, "value" = serialized EQ "true" };
    }

    return { "success" = false, "value" = arguments.defaultValue };
}
```

Em `validateSubmission`, chamar o helper, retornar HTTP 400 com código
`invalid_open_results_enabled` quando `success=false` e atribuir o booleano a
`result.openResultsEnabled`.

```cfml
var openResultsValidation = getPayloadBoolean(
    arguments.payload,
    "open_results_enabled",
    true
);

if (!openResultsValidation.success) {
    return errorResult(
        400,
        "invalid_open_results_enabled",
        "open_results_enabled deve ser um booleano JSON."
    );
}

result.openResultsEnabled = openResultsValidation.value;
```

- [ ] **Step 4: Incorporar a flag ao objeto e aos hashes**

Adicionar ao objeto `submission`:

```cfml
"openResultsEnabled" = validation.openResultsEnabled
```

Alterar o hash para aceitar a opção explícita:

```cfml
private string function buildPayloadHash(
    required struct submission,
    boolean includeOpenResultsEnabled = true
) output="false" {
    var parts = [
        arguments.submission.clientId,
        arguments.submission.timerCode,
        arguments.submission.eventIdHint,
        arguments.submission.eventTagHint,
        arguments.submission.externalAccountId,
        arguments.submission.externalEventId,
        arguments.submission.resultUrl,
        arguments.submission.publicResultUrl,
        arguments.submission.publicationStatus
    ];

    if (arguments.includeOpenResultsEnabled) {
        arrayAppend(parts, arguments.submission.openResultsEnabled ? "true" : "false");
    }

    return lCase(hash(arrayToList(parts, chr(30)), "SHA-256"));
}
```

Antes de `createOrFind`, calcular:

```cfml
submission.payloadHash = buildPayloadHash(submission, true);
submission.legacyPayloadHash = buildPayloadHash(submission, false);
```

No conflito de uma linha existente, aceitar somente:

```cfml
storedHash EQ submission.payloadHash
|| (submission.openResultsEnabled && storedHash EQ submission.legacyPayloadHash)
```

- [ ] **Step 5: Persistir a coluna no repositório**

Adicionar `open_results_enabled` à lista do `INSERT`, `:openResultsEnabled` aos
valores e o parâmetro:

```cfml
"openResultsEnabled" = {
    "value" = arguments.submission.openResultsEnabled,
    "cfsqltype" = "cf_sql_bit"
}
```

- [ ] **Step 6: Retornar a flag em submit e status**

Adicionar ao payload de `mapSubmission`:

```cfml
"openResultsEnabled" = getRowValue(
    arguments.sourceQuery,
    row,
    "open_results_enabled",
    true
) EQ true
```

- [ ] **Step 7: Rodar os testes focados e a checagem de diff**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js
git -C /Users/Shared/Projects/RunnerHub/RoadRunners diff --check
```

Expected: PASS e `diff --check` limpo.

---

### Task 3: OpenAPI, documentação pública e playground

**Files:**
- Modify: `/Users/Shared/Projects/RunnerHub/RoadRunners/public-api/openapi.json`
- Modify: `/Users/Shared/Projects/RunnerHub/RoadRunners/public-api/index.cfm`
- Modify: `/Users/Shared/Projects/RunnerHub/RoadRunners/public-api/assets/playground.js`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/tests/result-import-open-results-contract.test.js`

**Interfaces:**
- Consumes: campo público `open_results_enabled:boolean` da Task 2.
- Produces: contrato OpenAPI e playground capazes de enviar e mostrar a flag.

- [ ] **Step 1: Escrever os testes de documentação e playground**

```js
test("documents open_results_enabled in request, response and playground", () => {
    const openapi = JSON.parse(read(roadRunnersRoot, "public-api/openapi.json"));
    const requestProperty = openapi.components.schemas.ResultImportRequest.properties.open_results_enabled;
    const responseProperty = openapi.components.schemas.ResultImportSubmission.properties.open_results_enabled;
    const docs = read(roadRunnersRoot, "public-api/index.cfm");
    const playground = read(roadRunnersRoot, "public-api/assets/playground.js");

    assert.equal(requestProperty.type, "boolean");
    assert.equal(requestProperty.default, true);
    assert.equal(responseProperty.type, "boolean");
    assert.match(docs, /open_results_enabled/);
    assert.match(playground, /openResultsEnabledInput/);
    assert.match(playground, /open_results_enabled:\s*openResultsEnabledInput\.checked/);
});
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js
```

Expected: FAIL porque o OpenAPI e o playground não conhecem o campo.

- [ ] **Step 3: Atualizar os schemas OpenAPI**

Em `ResultImportRequest.properties`:

```json
"open_results_enabled": {
  "type": "boolean",
  "default": true,
  "description": "Intent received from the timing provider. When omitted, it defaults to true. The processor still revalidates the current event.json before importing."
}
```

Em `ResultImportSubmission.required`, adicionar `open_results_enabled`; em
`properties`, adicionar:

```json
"open_results_enabled": {
  "type": "boolean"
}
```

- [ ] **Step 4: Atualizar a documentação HTML e exemplos**

Adicionar uma linha opcional à tabela, incluir `"open_results_enabled": false` no
`curl` e explicar:

```text
Se omitido, assume true. O valor indica a intenção recebida e aparece na fila;
o processador consulta novamente o event.json, cujo booleano válido prevalece.
```

- [ ] **Step 5: Atualizar o formulário e o JavaScript do playground**

Adicionar checkbox com `id="result-import-open-results-enabled"`, marcado por
padrão. No JavaScript:

```js
const openResultsEnabledInput = document.getElementById("result-import-open-results-enabled");
```

E no payload base:

```js
open_results_enabled: openResultsEnabledInput.checked
```

Atualizar `playgroundScriptPath` em `public-api/index.cfm` para uma versão nova,
evitando cache do JavaScript anterior.

- [ ] **Step 6: Validar JSON, JavaScript e testes**

Run:

```bash
node -e 'JSON.parse(require("node:fs").readFileSync("/Users/Shared/Projects/RunnerHub/RoadRunners/public-api/openapi.json", "utf8")); console.log("openapi ok")'
node --check /Users/Shared/Projects/RunnerHub/RoadRunners/public-api/assets/playground.js
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js
```

Expected: `openapi ok`, JavaScript sem erro e testes PASS.

---

### Task 4: Intenção recebida na fila Business

**Files:**
- Modify: `/Users/Shared/Projects/RunnerHub/Business/administracao/importacoes-resultados/includes/backend.cfm`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/administracao/importacoes-resultados/home.cfm`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/tests/result-import-open-results-contract.test.js`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/docs/result_import_queue.md`

**Interfaces:**
- Consumes: `tb_resultados_importacoes.open_results_enabled` da Task 1.
- Produces: badge **Importar** ou **Não importar** na lista e valor detalhado sem HTTP externo.

- [ ] **Step 1: Escrever os testes da fila**

```js
test("reads the persisted intent and never fetches event.json from the queue", () => {
    const backend = read(businessRoot, "administracao/importacoes-resultados/includes/backend.cfm");
    const home = read(businessRoot, "administracao/importacoes-resultados/home.cfm");

    assert.match(backend, /open_results_enabled/);
    assert.match(home, /Intenção recebida/);
    assert.match(home, /Não importar/);
    assert.match(home, /Importar/);
    assert.doesNotMatch(backend, /<cfhttp/i);
    assert.doesNotMatch(home, /<cfhttp/i);
});
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js
```

Expected: FAIL nas referências da fila.

- [ ] **Step 3: Incluir a coluna em todos os modelos e SELECTs da fila**

Adicionar `open_results_enabled` a `qResultImports`, `qResultImportDetail` e aos
SELECTs de lista/detalhe. Como a coluna é `NOT NULL`, não usar fallback SQL.

```cfml
<cfset qResultImports = queryNew(
    "id_resultado_importacao,submission_id,id_evento,id_evento_informado,tag_evento_informada,client_id,cod_timer,external_account_id,external_event_id,url_resultado,url_resultado_publica,status_publicacao,open_results_enabled,status_processamento,idempotency_key,tentativas,total_resultados,erro_codigo,erro_detalhe,data_recebimento,data_inicio,data_processamento,data_atualizacao,nome_evento,event_tag,event_city,event_state,event_date"
)/>
```

Em cada projeção de submissão, manter a coluna junto do status de publicação:

```sql
imp.status_publicacao,
imp.open_results_enabled,
imp.status_processamento,
```

- [ ] **Step 4: Criar metadados de apresentação no servidor**

Em `home.cfm`, adicionar:

```cfml
function resultImportOpenResultsMeta(required boolean enabled) {
    return arguments.enabled
        ? { label = "Importar", className = "success" }
        : { label = "Não importar", className = "danger" };
}
```

- [ ] **Step 5: Renderizar lista e detalhes**

Adicionar a coluna **Intenção recebida** antes de **Resultados**. Para cada linha:

```cfml
<cfset resultImportRowIntent = resultImportOpenResultsMeta(open_results_enabled)/>
<span class="badge badge-#resultImportRowIntent.className#">#resultImportRowIntent.label#</span>
<small class="text-muted d-block"><code>open_results_enabled</code></small>
```

Nos detalhes, mostrar o mesmo badge e a observação de que o `event.json` será
revalidado no processamento.

- [ ] **Step 6: Atualizar a documentação operacional da fila**

Registrar que a coluna vem do payload persistido, usa default `true`, não causa
fetch remoto e não substitui a validação do processador.

- [ ] **Step 7: Rodar os testes focados**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/result-import-open-results-contract.test.js _codex/tests/result-import-queue.test.js
```

Expected: todos PASS.

---

### Task 5: Precedência e divergência no processador RaceTag

**Files:**
- Modify: `/Users/Shared/Projects/RunnerHub/Business/assets/js/racetag-open-results.js`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/tests/racetag-open-results.test.js`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/racetag/includes/backend.cfm`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/racetag/form.cfm`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/tests/result-import-open-results-contract.test.js`
- Modify: `/Users/Shared/Projects/RunnerHub/Business/_codex/docs/racetag_manual_importer.md`

**Interfaces:**
- Consumes: `qRaceTagSubmission.open_results_enabled` e o estado atual do `event.json`.
- Produces: `effectiveDecision(eventState, payloadEnabled, hasPersistedPayload, isInternalAdmin, overrideConfirmed)` com `allowed`, `overrideAvailable`, `mode`, `source` e `divergent`.

- [ ] **Step 1: Escrever os testes de precedência no JavaScript**

Adicionar:

```js
test("lets a valid event.json boolean override the persisted API intent", () => {
    const policy = loadPolicy();

    assert.equal(policy.effectiveDecision("enabled", false, true, false, false).allowed, true);
    assert.equal(policy.effectiveDecision("enabled", false, true, false, false).divergent, true);
    assert.equal(policy.effectiveDecision("disabled", true, true, false, false).allowed, false);
    assert.equal(policy.effectiveDecision("disabled", true, true, false, false).source, "event_json");
});

test("falls back to the payload only when event.json omits the flag", () => {
    const policy = loadPolicy();

    assert.equal(policy.effectiveDecision("missing", false, true, false, false).allowed, false);
    assert.equal(policy.effectiveDecision("missing", true, true, false, false).allowed, true);
    assert.equal(policy.effectiveDecision("missing", false, false, false, false).allowed, true);
});

test("blocks invalid event.json values and limits override to internal admins", () => {
    const policy = loadPolicy();

    assert.equal(policy.effectiveDecision("invalid", true, true, false, true).allowed, false);
    assert.equal(policy.effectiveDecision("invalid", true, true, true, false).allowed, false);
    assert.equal(policy.effectiveDecision("invalid", true, true, true, true).mode, "override");
});
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/racetag-open-results.test.js
```

Expected: FAIL porque `effectiveDecision` não existe.

- [ ] **Step 3: Implementar a função JavaScript mínima**

```js
function effectiveDecision(
    eventState,
    payloadEnabled,
    hasPersistedPayload,
    isInternalAdmin,
    overrideConfirmed
) {
    const eventBooleanPresent = eventState === "enabled" || eventState === "disabled";
    const divergent = eventBooleanPresent
        && Boolean(payloadEnabled) !== (eventState === "enabled");
    const source = eventState === "missing" && hasPersistedPayload ? "payload" : "event_json";
    const standardAllowed = eventState === "enabled"
        || (eventState === "missing" && (!hasPersistedPayload || Boolean(payloadEnabled)));
    const blocked = eventState === "disabled"
        || eventState === "invalid"
        || !standardAllowed;
    const overrideAvailable = blocked && Boolean(isInternalAdmin);
    const overrideAccepted = overrideAvailable && Boolean(overrideConfirmed);

    return {
        allowed: standardAllowed || overrideAccepted,
        overrideAvailable,
        mode: overrideAccepted ? "override" : (standardAllowed ? "standard" : "blocked"),
        source,
        divergent
    };
}
```

Exportar a função mantendo `classify`, `processingDecision` e `initialize` para
não quebrar testes ou chamadas existentes.

- [ ] **Step 4: Rodar os testes JavaScript**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/racetag-open-results.test.js
```

Expected: PASS.

- [ ] **Step 5: Carregar a flag persistida no backend CFML**

Adicionar `open_results_enabled` ao `queryNew` e ao SELECT da submissão. Definir:

```cfml
VARIABLES.raceTagPayloadIntentAvailable = VARIABLES.raceTagSubmissionReady;
VARIABLES.raceTagPayloadOpenResultsEnabled = VARIABLES.raceTagSubmissionReady
    ? qRaceTagSubmission.open_results_enabled
    : true;
```

- [ ] **Step 6: Espelhar a precedência no servidor**

Ampliar `raceTagOpenResultsPolicy` para receber a intenção persistida e retornar
`eventState`, `decisionSource` e `divergent`, mantendo a decisão de segurança no
CFML. Atualizar todas as chamadas iniciais e posteriores ao parse do
`event.json`; nenhum POST pode depender do JavaScript para autorizar.

```cfml
function raceTagOpenResultsPolicy(
    required struct eventPayload,
    boolean payloadEnabled = true,
    boolean hasPersistedPayload = false,
    boolean isInternalAdmin = false,
    boolean overrideRequested = false
) {
    var eventState = "missing";
    var serializedValue = "";
    var eventBooleanPresent = false;
    var standardAllowed = true;
    var decisionSource = "event_json";
    var divergent = false;
    var overrideAvailable = false;
    var overrideAccepted = false;

    if (structKeyExists(arguments.eventPayload, "openResultsEnabled")) {
        try {
            serializedValue = lCase(trim(serializeJSON(
                arguments.eventPayload.openResultsEnabled
            )));
        } catch (any invalidOpenResultsValue) {
            serializedValue = "";
        }

        if (serializedValue EQ "true") {
            eventState = "enabled";
        } else if (serializedValue EQ "false") {
            eventState = "disabled";
        } else {
            eventState = "invalid";
        }
    }

    eventBooleanPresent = listFindNoCase("enabled,disabled", eventState) GT 0;
    divergent = eventBooleanPresent
        AND arguments.hasPersistedPayload
        AND arguments.payloadEnabled NEQ (eventState EQ "enabled");

    if (eventState EQ "enabled") {
        standardAllowed = true;
    } else if (eventState EQ "missing") {
        decisionSource = arguments.hasPersistedPayload ? "payload" : "legacy";
        standardAllowed = !arguments.hasPersistedPayload OR arguments.payloadEnabled;
    } else {
        standardAllowed = false;
    }

    overrideAvailable = arguments.isInternalAdmin AND NOT standardAllowed;
    overrideAccepted = overrideAvailable AND arguments.overrideRequested;

    return {
        eventState = eventState,
        standardAllowed = standardAllowed,
        processingAllowed = standardAllowed OR overrideAccepted,
        decisionSource = decisionSource,
        divergent = divergent,
        overrideAvailable = overrideAvailable,
        overrideAccepted = overrideAccepted
    };
}
```

- [ ] **Step 7: Renderizar intenção, estado atual, divergência e decisão**

Na tela do processador:

- mostrar **Intenção recebida pela API** para submissões da fila;
- manter o destaque do `event.json` atual;
- exibir alerta amarelo quando os booleanos divergirem;
- quando `event.json` estiver ausente, informar que a decisão veio do payload;
- manter o botão padrão somente quando `standardAllowed=true`;
- manter o override somente quando `overrideAvailable=true`.

- [ ] **Step 8: Adicionar teste contratual do CFML e atualizar documentação**

```js
test("loads payload intent and keeps server-side event.json precedence", () => {
    const backend = read(businessRoot, "racetag/includes/backend.cfm");
    const form = read(businessRoot, "racetag/form.cfm");

    assert.match(backend, /open_results_enabled/);
    assert.match(form, /raceTagPayloadOpenResultsEnabled/);
    assert.match(form, /decisionSource/);
    assert.match(form, /divergent/);
    assert.match(form, /result_import_csrf/);
    assert.match(form, /business_result_imports/);
});
```

Atualizar `racetag_manual_importer.md` com a tabela de precedência completa.

- [ ] **Step 9: Rodar testes focados**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/racetag-open-results.test.js _codex/tests/result-import-open-results-contract.test.js
node --check assets/js/racetag-open-results.js
```

Expected: todos PASS.

---

### Task 6: Validação completa e revisão de segurança

**Files:**
- Review: todos os arquivos modificados nas Tasks 1–5.
- Test: `/Users/Shared/Projects/RunnerHub/Business/_codex/tests/*.test.js`

**Interfaces:**
- Consumes: implementação completa local.
- Produces: diff validado e apto para migração/publicação.

- [ ] **Step 1: Rodar toda a suíte Node do Business**

Run:

```bash
cd /Users/Shared/Projects/RunnerHub/Business
node --test _codex/tests/*.test.js
```

Expected: zero falhas.

- [ ] **Step 2: Validar JavaScript e OpenAPI**

Run:

```bash
node --check /Users/Shared/Projects/RunnerHub/Business/assets/js/racetag-open-results.js
node --check /Users/Shared/Projects/RunnerHub/Business/assets/js/result-import-queue.js
node --check /Users/Shared/Projects/RunnerHub/RoadRunners/public-api/assets/playground.js
node -e 'JSON.parse(require("node:fs").readFileSync("/Users/Shared/Projects/RunnerHub/RoadRunners/public-api/openapi.json", "utf8")); console.log("openapi ok")'
```

Expected: todos com exit 0.

- [ ] **Step 3: Validar tags CFML pareadas e whitespace**

Rodar o contador de tags nos CFML modificados e:

```bash
perl -0777 -e 'for $f (@ARGV) { open my $fh, "<", $f or die "$f: $!"; local $/; my $s=<$fh>; for my $t (qw(cfif cfloop cftry cfcatch cftransaction cfoutput cfquery cfhttp)) { my $o=()=$s=~/<$t(?=[\s>])/gi; my $c=()=$s=~/<\/$t>/gi; if ($o != $c) { print STDERR "$f $t open=$o close=$c\n"; $bad=1; } } } exit($bad ? 1 : 0);' /Users/Shared/Projects/RunnerHub/RoadRunners/services/ResultImportSubmissionService.cfc /Users/Shared/Projects/RunnerHub/RoadRunners/repositories/ResultImportRepository.cfc /Users/Shared/Projects/RunnerHub/RoadRunners/public-api/index.cfm /Users/Shared/Projects/RunnerHub/Business/administracao/importacoes-resultados/includes/backend.cfm /Users/Shared/Projects/RunnerHub/Business/administracao/importacoes-resultados/home.cfm /Users/Shared/Projects/RunnerHub/Business/racetag/includes/backend.cfm /Users/Shared/Projects/RunnerHub/Business/racetag/form.cfm
git -C /Users/Shared/Projects/RunnerHub/RoadRunners diff --check
git -C /Users/Shared/Projects/RunnerHub/Business diff --check
```

Expected: nenhuma tag sem fechamento e nenhum erro de whitespace.

- [ ] **Step 4: Revisar o diff de segurança**

Usar `codex-security:security-diff-scan` com foco em:

- bypass de validação booleana;
- quebra de idempotência legada;
- autorização do override;
- CSRF;
- possibilidade de o payload substituir indevidamente `event.json`;
- exposição de conteúdo remoto e regressões de SSRF/XSS.

Expected: nenhum achado reportável antes da publicação. Se houver achado,
interromper e obter autorização antes da correção sugerida pelo scan.

- [ ] **Step 5: Revisar alterações preexistentes**

Confirmar com `git status --short` que apenas os arquivos deste plano e as
alterações anteriores do usuário estão presentes; não apagar `__pycache__`,
documentos ou mudanças não relacionadas.

---

### Task 7: Migração e publicação controlada

**Files:**
- Deploy RoadRunners root: `/var/www/roadrunners.com.br`
- Deploy Business root: `/var/www/business.roadrunners.run`
- Backup directory: `/var/backups`

**Interfaces:**
- Consumes: implementação validada e script SQL da Task 1.
- Produces: banco, API pública e Business em produção com a mesma versão do contrato.

- [ ] **Step 1: Executar a migração no banco de produção**

Executar `_codex/sql/2026-09-01_result_import_open_results.sql` na base
`runnerhub` com o papel administrativo já usado para DDL. Em seguida executar
`2026-09-01_verify_result_import_open_results.sql`.

Expected: saída final identifica `runnerhub`, papel administrativo, total de
linhas, todas inicialmente habilitadas e zero desabilitadas antes dos novos
testes.

- [ ] **Step 2: Criar backups remotos datados**

Antes do rsync, copiar para `/var/backups`:

- `/var/www/roadrunners.com.br/services/ResultImportSubmissionService.cfc`;
- `/var/www/roadrunners.com.br/repositories/ResultImportRepository.cfc`;
- `/var/www/roadrunners.com.br/public-api/openapi.json`;
- `/var/www/roadrunners.com.br/public-api/index.cfm`;
- `/var/www/roadrunners.com.br/public-api/assets/playground.js`;
- `/var/www/business.roadrunners.run/administracao/importacoes-resultados/includes/backend.cfm`;
- `/var/www/business.roadrunners.run/administracao/importacoes-resultados/home.cfm`;
- `/var/www/business.roadrunners.run/racetag/includes/backend.cfm`;
- `/var/www/business.roadrunners.run/racetag/form.cfm`;
- `/var/www/business.roadrunners.run/assets/js/racetag-open-results.js`.

Usar prefixo `before-open-results-payload-YYYYMMDD-HHMMSS` nos nomes.

- [ ] **Step 3: Publicar primeiro a API**

Enviar os cinco arquivos RoadRunners com `rsync -az` e normalizar owner
`root:root`, modo `644`.

- [ ] **Step 4: Compilar os componentes e a API**

No servidor:

```bash
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/roadrunners.com.br -dir /var/www/roadrunners.com.br/services
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/roadrunners.com.br -dir /var/www/roadrunners.com.br/repositories
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/roadrunners.com.br -dir /var/www/roadrunners.com.br/public-api
```

Expected: todos os arquivos compilados com sucesso. Em falha, restaurar os
backups da API antes de continuar.

- [ ] **Step 5: Validar o contrato publicado sem criar submissão**

Run:

```bash
curl -sS https://api.roadrunners.run/openapi.json
curl -sS https://api.roadrunners.run/ | rg 'open_results_enabled'
```

Expected: OpenAPI válido e documentação contendo o campo.

- [ ] **Step 6: Executar testes reais de submissão**

Com o token operacional em `RR_RESULT_IMPORT_TEST_TOKEN`, enviar três requests
com chaves novas e este payload técnico homologado como base:

```json
{
  "external_account_id": "mycrono-test",
  "external_event_id": "1BHI0J1",
  "cod_timer": "racezone",
  "url_resultado": "https://resultados.racetag.com.br/mycrono-test/data/1BHI0J1/event.json",
  "url_resultado_publica": "https://resultados.racetag.com.br/mycrono-test/#/1BHI0J1",
  "status_publicacao": "atualizacao"
}
```

Definir `RR_OPEN_RESULTS_TEST_RUN` com `date +%Y%m%d%H%M%S` e usar as chaves
`open-results:<run>:default`, `open-results:<run>:false` e
`open-results:<run>:invalid`:

1. campo omitido: HTTP 202 e resposta `open_results_enabled: true`;
2. campo `false`: HTTP 202 e resposta `open_results_enabled: false`;
3. campo `"false"`: HTTP 400 e `invalid_open_results_enabled`.

Consultar os dois UUIDs aceitos em `/v1/result-imports/status.cfm` e confirmar os
mesmos booleanos. Marcar as duas submissões de teste como `cancelado` por update
SQL restrito às `Idempotency-Key` criadas para a verificação; não apagá-las.

- [ ] **Step 7: Publicar o Business**

Enviar os cinco arquivos Business listados no Step 2, normalizar owner/mode e
compilar:

```bash
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/business.roadrunners.run -dir /var/www/business.roadrunners.run/administracao/importacoes-resultados
/opt/ColdFusion/cfusion/bin/cfcompile.sh -cfruntimeuser nobody -webroot /var/www/business.roadrunners.run -dir /var/www/business.roadrunners.run/racetag
```

Expected: compilação integral sem erro. Em falha, restaurar os backups Business.

- [ ] **Step 8: Verificar hashes e HTTP**

Comparar SHA-256 local/remoto de todos os arquivos publicados. Validar:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://api.roadrunners.run/openapi.json
curl -sS -o /dev/null -w '%{http_code}\n' https://business.roadrunners.run/assets/js/racetag-open-results.js
curl -sS -o /dev/null -w '%{http_code}\n' https://business.roadrunners.run/administracao/importacoes-resultados/
```

Expected: `200`, `200` e `302` sem sessão, respectivamente.

- [ ] **Step 9: Validar visualmente com sessão autenticada**

Na fila Business, confirmar:

- submissão omitida/true mostra **Importar**;
- submissão false mostra **Não importar** em vermelho;
- nenhum request do navegador é feito para o domínio Racezone;
- detalhes explicam que o valor veio do payload.

No processador RaceTag, confirmar os casos de precedência e que apenas o
administrador interno vê a confirmação de override.

- [ ] **Step 10: Registrar o resultado da implantação**

Documentar no handoff final: horário, scripts SQL executados, totais da
verificação, testes, hashes, compilação, backups e URLs verificadas. Não criar
commit nem push sem nova autorização explícita.
