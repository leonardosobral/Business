<cfscript>
failures=[];function check(required boolean condition,required string label){if(!condition)arrayAppend(failures,label);writeOutput((condition ? "PASS " : "FAIL ") & label & chr(10));}
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};
function fixture(required numeric id){queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});}
function reviewable(required numeric id){
 fixture(id);var ids=store.enqueue([id],"fixture");var work=store.claim(ids[1]);var source=store.snapshot(store.event(id));var reader=new FixtureAIReader();var research=reader.read(source,getTickCount()+45000);var reply=new FixtureAI().extract(source,research.documents);var worker=new OptimizationWorker(ids);var progress=worker.initialProgress(source,research,reply);
 progress.targets=[progress.targets[1]];progress.targets[1].status="needs_review";
 progress.targets[1].candidate=new services.geocoding.Policy().evaluate(progress.targets[1].context,progress.targets[1].query,new FixtureAIGeo().search(progress.targets[1].query,"fixture").results).candidate;
 progress.status="needs_review";progress.analysis_complete=false;progress.retry_after_seconds=60;progress.enrichment.published=true;store.finish(work,progress,"fixture");return ids;
}
transaction {
 ids=reviewable(2147001401);work=store.detail(ids[1]);
 store.reviewTarget(ids[1],1,"approve","fixture",work.proposal_revision & "");
 queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 check(!structIsEmpty(store.claim(ids[1])),"Approving a partial result does not disable its automatic research retry");
 transaction action="rollback";
}
transaction {
 ids=reviewable(2147001402);
 prior=deserializeJSON(store.detail(ids[1]).decision);prior.enrichment.fields=[{field="organizador",label="Organizador",value="Associação Flores",current="",trusted=true,status="needs_review",evidence={},reasons=[]}];
 queryExecute("UPDATE public.tb_evento_geocoding SET decision=CAST(:body AS jsonb) WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"},body={value=serializeJSON(store.lowerKeys(prior)),cfsqltype="cf_sql_longvarchar"}},db);
 queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 worker=new OptimizationWorker(ids);worker.setConflictingAI();result=worker.run(1);progress=deserializeJSON(store.detail(ids[1]).decision);
 staleTrust=false;for(target in progress.targets)if(target.trusted AND listFind("needs_review,auto_applied,approved",target.status))staleTrust=true;
 check(!staleTrust AND !len(store.event(2147001402).coordenadas),"Recovered conflicting sources cannot regain stale trust or publish a prior proposal");
 staleField=false;for(field in progress.enrichment.fields)if(field.trusted AND field.status EQ "needs_review")staleField=true;
 check(!staleField,"Recovered conflicting fields cannot regain stale approval eligibility");
 transaction action="rollback";
}
transaction {
 ids=reviewable(2147001403);work=store.detail(ids[1]);store.reviewTarget(ids[1],1,"reject","fixture",work.proposal_revision & "");
 queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 worker=new OptimizationWorker(ids);worker.throwOnRead();result=worker.run(1);work=store.detail(ids[1]);progress=deserializeJSON(work.decision);
 check(work.status EQ "error" AND structKeyExists(progress,"targets") AND arrayLen(progress.targets) EQ 1 AND progress.targets[1].status EQ "rejected" AND work.attempts EQ 1,"An exception preserves the operator rejection and consumes a normal retry");
 transaction action="rollback";
}
transaction {
 ids=reviewable(2147001404);fixture(2147001405);fresh=store.enqueue([2147001405],"fixture");
 queryExecute("UPDATE public.tb_evento_geocoding SET priority=-2000000000,next_retry_at=CASE WHEN id=:old THEN clock_timestamp()-interval '1 hour' ELSE NULL END WHERE id_evento IN(2147001404,2147001405)",{old={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 claimed=store.claim();check(claimed.id EQ ids[1],"Overdue research is not starved by newer pending arrivals of the same priority");
 transaction action="rollback";
}
if(arrayLen(failures))throw(type="Test.Failed",message=arrayToList(failures," | "));writeOutput("GEO_OPTIMIZATION_RETRY_PASSED");
</cfscript>
