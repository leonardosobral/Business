const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const businessRoot = path.resolve(__dirname, "../..");
const roadRunnersRoot = path.resolve(__dirname, "../../../RoadRunners");

function read(root, relativePath) {
    const filePath = path.join(root, relativePath);

    assert.ok(fs.existsSync(filePath), `${relativePath} precisa existir`);
    return fs.readFileSync(filePath, "utf8");
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
    assert.match(
        repository,
        /"openResultsEnabled"\s*=\s*\{[\s\S]*?"cfsqltype"\s*=\s*"cf_sql_bit"/
    );
    assert.doesNotMatch(repository, /cf_sql_boolean/);
});

test("keeps a legacy hash path and appends the boolean only to the new hash", () => {
    const service = read(roadRunnersRoot, "services/ResultImportSubmissionService.cfc");

    assert.match(service, /buildPayloadHash\(submission,\s*true\)/);
    assert.match(service, /buildPayloadHash\(submission,\s*false\)/);
    assert.match(service, /includeOpenResultsEnabled/);
});

test("documents open_results_enabled in request, response and playground", () => {
    const openapi = JSON.parse(read(roadRunnersRoot, "public-api/openapi.json"));
    const requestProperties = openapi.components.schemas.ResultImportRequest.properties;
    const responseProperties = openapi.components.schemas.ResultImportSubmission.properties;
    const requestProperty = requestProperties.open_results_enabled;
    const responseProperty = responseProperties.open_results_enabled;
    const docs = read(roadRunnersRoot, "public-api/index.cfm");
    const playground = read(roadRunnersRoot, "public-api/assets/playground.js");

    assert.ok(requestProperty, "ResultImportRequest precisa declarar open_results_enabled");
    assert.ok(responseProperty, "ResultImportSubmission precisa declarar open_results_enabled");
    assert.equal(requestProperties.openResultsEnabled, undefined);
    assert.equal(responseProperties.openResultsEnabled, undefined);
    assert.equal(requestProperty.type, "boolean");
    assert.equal(requestProperty.default, true);
    assert.equal(responseProperty.type, "boolean");
    assert.ok(openapi.components.schemas.ResultImportSubmission.required.includes("open_results_enabled"));
    assert.ok(!openapi.components.schemas.ResultImportSubmission.required.includes("openResultsEnabled"));
    assert.match(docs, /open_results_enabled/);
    assert.match(playground, /openResultsEnabledInput/);
    assert.match(playground, /open_results_enabled:\s*openResultsEnabledInput\.checked/);
});

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

test("passes the persisted intent to the RaceTag processor and lets event.json prevail", () => {
    const backend = read(businessRoot, "racetag/includes/backend.cfm");
    const form = read(businessRoot, "racetag/form.cfm");

    assert.match(backend, /open_results_enabled/);
    assert.match(backend, /raceTagPayloadIntentAvailable/);
    assert.match(backend, /raceTagPayloadOpenResultsEnabled/);
    assert.match(form, /hasPersistedPayload/);
    assert.match(form, /decisionSource/);
    assert.match(form, /divergent/);
    assert.match(form, /event_json/);
    assert.match(form, /Intenção recebida pela API/);
});
