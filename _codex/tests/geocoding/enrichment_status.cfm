<cfscript>
// Read-only post-publication evidence; no source bodies, names, secrets or provider calls.
transaction {
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 fixtureOptions={datasource="runner_dba",timeout=15};
 fixtureTotals=queryExecute("SELECT count(*) FILTER(WHERE localizacoes->'enriquecimento'->>'version'='1') AS enriched_events,COALESCE(sum((SELECT count(*) FROM jsonb_object_keys(CASE WHEN jsonb_typeof(localizacoes->'enriquecimento'->'fields')='object' THEN localizacoes->'enriquecimento'->'fields' ELSE '{}'::jsonb END))),0) AS fields FROM public.tb_evento_corridas",[],fixtureOptions);
 fixtureJob=queryExecute("SELECT ativo,interval_minutes,last_run_at,next_run_at FROM public.tb_cron_jobs WHERE id_cron_job=25",[],fixtureOptions);
 fixtureExamples=[];for(fixtureRow in queryExecute("SELECT g.id AS work_id,g.id_evento,g.status,g.decision->>'model' AS model,g.decision->'enrichment'->'fields' AS attributes FROM public.tb_evento_geocoding g WHERE g.decision->'enrichment'->>'published'='true' ORDER BY g.updated_at DESC LIMIT 3",[],fixtureOptions)){
  fixtureAttributes=[];for(fixtureFact in deserializeJSON(fixtureRow.attributes & ''))arrayAppend(fixtureAttributes,{field=fixtureFact.field,status=fixtureFact.status,reasons=fixtureFact.reasons});
  arrayAppend(fixtureExamples,{work_id=fixtureRow.work_id,id_evento=fixtureRow.id_evento,status=fixtureRow.status,model=fixtureRow.model,attributes=fixtureAttributes});
 }
 fixtureRuns=[];for(fixtureRow in queryExecute("SELECT id_cron_job_run,status,http_status,started_at,response_preview FROM public.tb_cron_job_runs WHERE id_cron_job=25 ORDER BY started_at DESC LIMIT 3",[],fixtureOptions)){
  fixtureSummary={};if(!isNull(fixtureRow.response_preview) AND isJSON(fixtureRow.response_preview)){fixtureBody=deserializeJSON(fixtureRow.response_preview);for(fixtureKey in ['status','model','processed','enriched_fields','field_reviews','errors','calls','ai_calls'])if(structKeyExists(fixtureBody,fixtureKey))fixtureSummary[fixtureKey]=fixtureBody[fixtureKey];}
  arrayAppend(fixtureRuns,{id=fixtureRow.id_cron_job_run,status=fixtureRow.status,http=fixtureRow.http_status,started=fixtureRow.started_at,summary=fixtureSummary});
 }
 writeOutput(serializeJSON({totals=fixtureTotals.getRow(1),examples=fixtureExamples,runs=fixtureRuns,job=fixtureJob.getRow(1)}));
}
writeOutput("GEO_ENRICHMENT_STATUS_PASSED");
</cfscript>
