<cfscript>
fixtureRoot = getDirectoryFromPath(getCurrentTemplatePath());
fixtureMappings = duplicate(getApplicationSettings().mappings);
fixtureMappings['/services'] = fixtureRoot & 'services';
application action='update' mappings=fixtureMappings datasources={runner_dba={
    class='org.postgresql.Driver', bundleName='org.postgresql.jdbc', bundleVersion='42.2.20',
    connectionString='jdbc:postgresql://127.0.0.1:' & createObject('java', 'java.lang.System').getenv('EVENT_DESCRIPTION_TEST_PG_PORT') & '/postgres',
    username='rewrite_test', password=''
}};
function fixtureSql(required string statement, struct params={}) {
    return queryExecute(arguments.statement, arguments.params, {datasource='runner_dba'});
}
fixtureSql('CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY, descricao_original text, descricao text, categorias text, data_inicial date, data_final date)');
fixtureSql(fileRead(fixtureRoot & 'schema.sql'));
fixtureSql(fileRead(fixtureRoot & 'schema.sql'));
fixtureSource = repeatString('Corrida de 5 km. Largada às 07:00 na Praça Central. ', 6);
function resetFixture() {
    fixtureSql('TRUNCATE public.tb_evento_descricao_translations, public.tb_evento_descricao_rewrites, public.tb_evento_corridas RESTART IDENTITY');
    fixtureSql("INSERT INTO public.tb_evento_corridas (id_evento,descricao_original,descricao,categorias,data_inicial,data_final) VALUES (1,:source,NULL,'5 km',current_date,current_date)", {source={value=VARIABLES.fixtureSource, cfsqltype='cf_sql_longvarchar'}});
    REQUEST.fixtureProviderMode = 'success';
    REQUEST.fixtureProviderCalls = 0;
}
function invokeFixture(string body='{"dryRun":false,"language":"pt-BR"}') {
    return runCase('POST', arguments.body, signedHeaders(arguments.body), true, true);
}
resetFixture();
result = invokeFixture('{}');
check(result.code EQ 200 AND result.payload.dryRun AND result.payload.results[1].status EQ 'preview', 'Default dryRun produces preview');
check(fixtureSql('SELECT * FROM public.tb_evento_descricao_rewrites').recordCount EQ 0 AND fixtureSql('SELECT descricao IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Preview writes neither source nor audit');

resetFixture();
result = invokeFixture();
check(result.code EQ 200 AND result.payload.updated EQ 1 AND result.payload.processed EQ 1, 'Validated event is saved');
audit = fixtureSql('SELECT *,description_before IS NULL AS was_null FROM public.tb_evento_descricao_rewrites');
check(audit.recordCount EQ 1 AND audit.was_null[1] AND audit.status[1] EQ 'updated', 'Audit preserves NULL before-value and successful state');
event = fixtureSql('SELECT * FROM public.tb_evento_corridas');
check(event.descricao_original[1] EQ fixtureSource AND event.categorias[1] EQ '5 km' AND event.descricao[1] EQ audit.description_after[1], 'Only description changes');
result = invokeFixture();
check(result.code EQ 200 AND result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 1, 'Repeated request does not call provider or rewrite again');

resetFixture();
REQUEST.fixtureProviderMode = 'reject';
result = invokeFixture();
check(result.code EQ 422 AND result.payload.errors EQ 1 AND fixtureSql('SELECT status FROM public.tb_evento_descricao_rewrites').status[1] EQ 'rejected', 'Factual rejection audits but does not publish');
result = invokeFixture();
check(result.payload.selected EQ 0 AND REQUEST.fixtureProviderCalls EQ 1, 'Rejected source is excluded from automatic retries');

resetFixture();
REQUEST.fixtureProviderMode = 'provider-error';
result = invokeFixture();
check(result.code EQ 502 AND fixtureSql('SELECT status FROM public.tb_evento_descricao_rewrites').status[1] EQ 'error', 'Provider error persists audit and returns failure');
check(!find('DO_NOT_EXPOSE', serializeJSON(result)) AND !find('DO_NOT_EXPOSE', serializeJSON(fixtureSql('SELECT * FROM public.tb_evento_descricao_rewrites'))), 'Provider errors stay sanitized');

resetFixture();
REQUEST.fixtureProviderMode = 'changed-source';
result = invokeFixture();
check(result.code EQ 200 AND result.payload.updated EQ 0 AND result.payload.skipped EQ 1 AND fixtureSql('SELECT descricao IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Changed source is not overwritten');
check(fixtureSql('SELECT status FROM public.tb_evento_descricao_rewrites').status[1] EQ 'source_changed', 'Changed source is audited');

resetFixture();
REQUEST.fixtureProviderMode = 'manual-description';
result = invokeFixture();
check(result.code EQ 200 AND result.payload.updated EQ 0 AND fixtureSql('SELECT descricao FROM public.tb_evento_corridas').descricao[1] EQ 'Descrição manual.', 'Concurrent manual description wins');

resetFixture();
REQUEST.fixtureProviderMode = 'unexpected-error';
result = invokeFixture();
check(result.code EQ 503 AND fixtureSql('SELECT * FROM public.tb_evento_descricao_rewrites').recordCount EQ 0 AND fixtureSql('SELECT descricao IS NULL AS untouched FROM public.tb_evento_corridas').untouched[1], 'Unexpected failures roll back before any confirmed change');
check(!find('DO_NOT_EXPOSE', serializeJSON(result)), 'Unexpected errors are sanitized');

resetFixture();
REQUEST.fixtureLockReady = false;
thread action='run' name='descriptionFixtureLock' {
    transaction {
        queryExecute('SELECT pg_advisory_xact_lock(1380472914,1)', [], {datasource='runner_dba'});
        REQUEST.fixtureLockReady = true;
        sleep(2000);
    }
}
fixtureWaitStarted = getTickCount();
while (!REQUEST.fixtureLockReady AND getTickCount()-fixtureWaitStarted LT 2000) sleep(20);
check(REQUEST.fixtureLockReady, 'Concurrent lock fixture started');
result = invokeFixture();
thread action='join' name='descriptionFixtureLock' timeout=5000;
check(result.code EQ 409 AND result.payload.status EQ 'locked' AND REQUEST.fixtureProviderCalls EQ 0, 'Concurrent runner is rejected before selecting or spending provider requests');
check(fixtureSql('SELECT * FROM public.tb_evento_descricao_rewrites').recordCount EQ 0, 'Blocked runner leaves audit untouched');

include 'translation-integration.cfm';
resetFixture();
fixtureSql('DROP TABLE public.tb_evento_descricao_rewrites');
result = invokeFixture();
check(result.code EQ 503 AND result.payload.status EQ 'schema_required' AND REQUEST.fixtureProviderCalls EQ 0, 'Missing audit schema prevents provider calls');
writeOutput('Endpoint database flow passed: 10' & chr(10));
</cfscript>
