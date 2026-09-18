<cfscript>
testRoot=getDirectoryFromPath(getCurrentTemplatePath());
testMappings=duplicate(getApplicationSettings().mappings);
testMappings['/services']=testRoot & 'services';
application action='update' sessionManagement=true mappings=testMappings datasource='runner_dba' datasources={runner_dba={
 class='org.postgresql.Driver',bundleName='org.postgresql.jdbc',bundleVersion='42.2.20',
 connectionString='jdbc:postgresql://127.0.0.1:' & createObject('java','java.lang.System').getenv('RESULT_IMPORT_TEST_PORT') & '/postgres',username='postgres',password=''
}};
function check(required boolean ok,required string message) { if(!arguments.ok) throw(type='TestFailure',message=arguments.message); }
service=createObject('component','services.ResultImportQueueService');
filters={days=0,search='',status='',status_publicacao='',cod_timer='',client_id='',event_group='',page=1};
result=service.queue(filters,true,0);
check(result.total EQ 4 AND result.rows.recordcount EQ 4,'Queue groups the six URL submissions and isolates three other scopes');
check(result.summary.arquivados EQ 2,'Existing obsolete backlog is excluded without a write');
check(result.rows.id_resultado_importacao[4] EQ 6 OR listFind(valueList(result.rows.id_resultado_importacao),'6'),'Newest update is the actionable representative');
record=service.submission('00000000-0000-4000-8000-000000000006',true,0);
check(record.suggested_event_id EQ 42 AND record.link_source EQ 'history','Processor receives the same historical suggestion');
check(!record.open_results_enabled,'Latest false intention remains visible, never replaced by an older true submission');
source={url_resultado=record.url_resultado,url_resultado_publica=record.url_resultado_publica,external_event_id=''};
check(service.sameSource(source,source.url_resultado,'ABC','setembro-2026'),'Source URL with no external_event_id still identifies the selected event');
check(!service.sameSource(source,source.url_resultado,'DIFFERENT','another-event'),'Selecting another event cannot mark the original submission successful');
check(!service.sameSource(source,'https://other.example/data/ABC/event.json','ABC','setembro-2026'),'Changing the source cannot archive the original event');
filters.event_group=record.event_group;
result=service.queue(filters,true,0);
check(result.total EQ 6,'History preserves every submission including archived and running');
filters.status='arquivado';result=service.queue(filters,true,0);
check(result.total EQ 2,'Archive filter exposes both obsolete records');
filters.event_group='';filters.status='pendente';
check(service.queue(filters,false,2).total EQ 1,'Scoped account sees only its own pending event');
check(service.queue(filters,false,3).total EQ 0,'Inactive integration is denied');
filters.search="' OR true --";
check(service.queue(filters,true,0).total EQ 0,'Search text is bound as data');
filters.search='';filters.status='';filters.page=100;
check(service.queue(filters,true,0).page EQ 1,'Pagination clamps to actual grouped page count');
queryExecute("UPDATE tb_resultados_importacoes SET status_publicacao='extraoficial' WHERE id_resultado_importacao=5");
filters.status_publicacao='extraoficial';
check(service.queue(filters,true,0).total EQ 0,'Publication filters cannot promote an older submission as the latest');
filters.status_publicacao='';
// Render the production template with the real service output, not a copied view.
filters.page=1;result=service.queue(filters,true,0);
qResultImports=result.rows;qResultImportSummary=result.summary;qResultImportTimers=result.timers;qResultImportClients=result.clients;
qResultImportDetail=record;
resultImportSearch='';resultImportStatus='';resultImportPublicationStatus='';resultImportTimer='';resultImportClient='';
resultImportPeriodDays=0;resultImportPage=1;resultImportSelectedId='';resultImportGroup='';resultImportTotal=result.total;resultImportTotalPages=1;
resultImportDiscardOutcome='';resultImportUnscopedAccess=true;resultImportError='';resultImportDetailError='';resultImportCanProcess=true;resultImportQueueCsrf='fixture-not-a-real-session';
savecontent variable='rendered' {include 'administracao/importacoes-resultados/home.cfm';}
check(find('Histórico: 6 chamada(s)',rendered)>0,'Grouped history link renders with full count');
check(find('Pré-selecionado pelo histórico',rendered)>0,'Queue explains the proposed internal linkage');
check(find('Não importar',rendered)>0,'Persisted false flag is rendered prominently');
check(arrayLen(reMatch('data-result-import-row ',rendered)) EQ 4,'Render has one main row per scoped event');
fileWrite(testRoot & 'rendered.html','<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"></head><body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4">' & rendered & '</main></body></html>','utf-8');
// Opening the real importer backend must preselect and refuse archived work.
structClear(FORM);URL.submission_id='00000000-0000-4000-8000-000000000006';
businessEffectiveIsAdmin=true;businessPermissionAccountId=0;
include 'racetag/includes/backend.cfm';
check(FORM.id_evento EQ 42 AND raceTagSubmissionCanProcess,'Importer preselects the known event without external_event_id: ' & serializeJSON({id=FORM.id_evento,canProcess=raceTagSubmissionCanProcess,error=raceTagError,submissionId=raceTagSubmissionId}));
URL.submission_id='00000000-0000-4000-8000-000000000001';structClear(FORM);
include 'racetag/includes/backend.cfm';
check(!raceTagSubmissionCanProcess,'Direct old links cannot reprocess an archived call');
transaction {
    check(service.archivePrevious('00000000-0000-4000-8000-000000000004',true,0) EQ 2,'Successful import archives only two eligible older calls');
    transaction action='rollback';
}
check(queryExecute("SELECT status_processamento FROM tb_resultados_importacoes WHERE id_resultado_importacao=1").status_processamento EQ 'pendente','Failure/rollback restores the archive together with the import');
check(service.submission('00000000-0000-4000-8000-000000000003',true,0).is_superseded,'A previously claimed running call detects newer success after acquiring the event lock');
include 'racetag-candidates.cfm';
processLinks=reMatch('<a[^>]*href="/racetag/[^>]*>',rendered);
check(arrayLen(processLinks) EQ 3,'Only the three eligible RaceTag events have processing links');
for(processLink in processLinks) {
    check(reFindNoCase('target\s*=\s*"_blank"',processLink) EQ 0,'Manual processing must open in the same tab');
}
include 'result-import-default-filter.cfm';
writeOutput('PASS: CFML service, filters, scope, preselection, intent, archive guards and real template render');
</cfscript>
