<cfscript>
repo=createObject('component','cbgPublishedRR.repositories.VickyBrasilGiganteRepository').init('runner_dba','meta_cloud');
today=queryExecute("SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today",{},{datasource='runner_dba'});
q=queryExecute("SELECT channel,count(*) candidates FROM (" & repo.candidatesSql() & ") c GROUP BY channel ORDER BY channel",{today={value=today.today,cfsqltype='cf_sql_date'}},{datasource='runner_dba',timeout=15});writeOutput('CANDIDATES ' & serializeJSON(q));
fake=new FakeRepository();
service=createObject('component','cbgPublishedRR.services.VickyProactiveService').init({provider='meta_cloud'},fake);
request=service.whatsappTemplate({rule_code='brasil_gigante_d7',provider_template_name='atualize_cbg'},{});
if(request.name NEQ 'atualize_cbg' OR arrayLen(request.components))throw(message='Published Meta payload mismatch');
result=service.run(1);if(result.generatedBrasilGigante NEQ 5 OR result.completed NEQ 1)throw(message='Published orchestration failed');
writeOutput('VICKY_CBG_RUNTIME_PASSED no real delivery invoked');
</cfscript>
