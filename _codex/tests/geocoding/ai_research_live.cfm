<cfscript>
// One bounded public-source interpretation. Counts OpenAI; never writes event locations.
fixtureStore=new services.geocoding.LocationStore();
fixtureRows=queryExecute("SELECT e.id_evento FROM public.tb_evento_corridas e JOIN public.tb_evento_geocoding g ON g.id_evento=e.id_evento WHERE g.status IN('auto_applied','approved') AND jsonb_array_length(COALESCE(g.decision->'RESEARCH'->'EVIDENCE',g.decision->'research'->'evidence','[]'::jsonb))>0 ORDER BY e.data_inicial DESC,g.id DESC LIMIT 1",[],{datasource="runner_dba"});
if(!fixtureRows.recordCount)throw(type="Test.Failed",message="No researched public source fixture available");
fixtureSource=fixtureStore.snapshot(fixtureStore.event(fixtureRows.id_evento[1]));fixtureResearch=new services.geocoding.DocumentReader().read(fixtureSource,getTickCount()+45000);
fixtureReport={id_evento=fixtureRows.id_evento[1],document_count=arrayLen(fixtureResearch.documents),diagnostics=fixtureResearch.diagnostics,locations_written=0};
if(arrayLen(fixtureResearch.documents) AND !(fixtureResearch.temporary ?: false)){
 fixtureReservation=fixtureStore.reserveAI(1000);if(!fixtureReservation.allowed)throw(type="Test.Failed",message=fixtureReservation.reason);
 fixtureReply=new services.geocoding.AIClient(application.vickyKnowledge.apiKey).extract({nome_evento=fixtureSource.nome_evento,start_date=fixtureSource.start_date,cidade=fixtureSource.cidade,estado=fixtureSource.estado,pais=fixtureSource.pais},fixtureResearch.documents);fixtureStore.completeAI(fixtureReply);
 if(!fixtureReply.ok)throw(type="Test.Failed",message=fixtureReply.code);
 fixtureDecision=new services.geocoding.LocationPolicy().validate(fixtureSource,fixtureResearch.documents,fixtureReply.facts);fixtureReport.model=fixtureReply.model;fixtureReport.usage=fixtureReply.usage;fixtureReport.targets=[];
 for(fixtureTarget in fixtureDecision.targets)arrayAppend(fixtureReport.targets,{role=fixtureTarget.role,trusted=fixtureTarget.trusted,name=fixtureTarget.facts.name,city=fixtureTarget.facts.city,reasons=fixtureTarget.reasons});
 fixtureReport.diagnostics=fixtureDecision.diagnostics;
}
writeOutput(serializeJSON(fixtureReport));writeOutput("GEO_AI_RESEARCH_LIVE_PASSED");
</cfscript>
