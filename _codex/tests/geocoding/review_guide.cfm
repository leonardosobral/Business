<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
guide=new services.geocoding.ReviewGuide();
current={organizador="Organização atual",coordenadas="",endereco="Avenida atual"};
work={id=10,status="needs_review",proposal_revision=3};
decision={targets=[{role="evento",status="city_suggestion",trusted=false,facts={},context={},candidate={result_type="city",lat=-23,lon=-46},evidence={}}],enrichment={fields=[
 {field="organizador",label="Organizador",status="needs_review",trusted=true,current="Valor antigo do snapshot",value="Organização da fonte",evidence={excerpt="Organizador: Organização da fonte.",url="https://example.com/regulamento"},reasons=[]},
 {field="pais",label="País",status="equivalent",trusted=true,current="BR",value="Brasil",evidence={},reasons=[]},
 {field="horarios_largada",label="Horários",status="needs_review",trusted=false,current="",value="07:00",evidence={},reasons=["conflicting_sources"]}
]}};
tasks=guide.tasks(work,decision,current,false);
check(arrayLen(tasks) EQ 2 AND tasks[1].key EQ "field-1" AND tasks[2].key EQ "field-3","Only actionable divergences become review steps; cities and equivalent facts do not");
check(tasks[1].current EQ "Organização atual" AND tasks[1].proposed EQ "Organização da fonte","The comparison uses the current event value, not a stale snapshot");
check(tasks[1].canApprove AND !tasks[2].canApprove AND tasks[2].canReject,"Conflicting evidence cannot be accepted but the current registration can be kept");
check(guide.active(tasks,"field-3").key EQ "field-3" AND guide.active(tasks,"missing").key EQ "field-1","Direct links select a pending step and stale step links safely select the next remaining step");
work.status="running";check(!arrayLen(guide.tasks(work,decision,current,false)),"A currently processing work item offers no competing review action");work.status="needs_review";
legacy={candidate={formatted="Cidade aproximada",result_type="city",lat=-23,lon=-46},reasons=["city_only"]};
tasks=guide.tasks(work,legacy,current,false);check(arrayLen(tasks) EQ 1 AND !tasks[1].canApprove,"Legacy municipal proposals cannot gain an approval button");
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};fixtureId=2147001601;
transaction {
 check(!store.event(fixtureId).exists,"A real event is not replaced");
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Revisão guiada fixture','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 ids=store.enqueue([fixtureId],"fixture");
 decision.enrichment.fields[1].evidence.event_date=store.snapshot(store.event(fixtureId)).start_date;
 queryExecute("UPDATE public.tb_evento_geocoding SET status='needs_review',decision=CAST(:body AS jsonb) WHERE id=:id",{body={value=serializeJSON(store.lowerKeys(decision)),cfsqltype="cf_sql_longvarchar"},id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 queue=guide.queue("Revisão guiada fixture","todos","",[]);
 check(queue.recordCount EQ 1 AND queue.work_id[1] EQ ids[1],"The filtered guide opens the actual latest reviewable event");
 skipped=guide.queue("Revisão guiada fixture","todos","",[fixtureId]);
 check(!skipped.recordCount AND store.detail(ids[1]).status EQ "needs_review","Skipping an event changes navigation only, not its proposal or registration");
 work=store.detail(ids[1]);store.reviewField(ids[1],1,"approve","fixture",work.proposal_revision & "");
 following=guide.continuation(store,ids[1],"Revisão guiada fixture","todos","",[]);
 check(following.id EQ ids[1] AND following.key EQ "field-3" AND store.event(fixtureId).organizador EQ "Organização da fonte","Accepting one field opens the next actual pending decision in the same event");
 work=store.detail(ids[1]);store.reviewField(ids[1],3,"reject","fixture",work.proposal_revision & "");
 following=guide.continuation(store,ids[1],"Revisão guiada fixture","todos","",[]);
 check(following.id EQ 0,"Resolving the final pending decision finishes the filtered review sequence");
 queryExecute("UPDATE public.tb_evento_geocoding SET status='needs_review' WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 queryExecute("UPDATE public.tb_evento_geocoding SET decision=CAST(:body AS jsonb) WHERE id=:id",{body={value=serializeJSON(store.lowerKeys({targets=decision.targets})),cfsqltype="cf_sql_longvarchar"},id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 check(!guide.queue("Revisão guiada fixture","todos","",[]).recordCount,"A city-only stale parent review status does not create a fake human decision");
 transaction action="rollback";
}
transaction {
 fixtureId=2147001602;
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo,endereco) VALUES(:id,'Skip de evento fixture','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true,'Antes')",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 ids=store.enqueue([fixtureId],"fixture");work=store.detail(ids[1]);
 check(!guide.isStale(store,work,store.event(fixtureId)),"An unchanged source and destinations remain reviewable");
 queryExecute("UPDATE public.tb_evento_corridas SET coordenadas='-23.5,-46.6' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 check(guide.isStale(store,work,store.event(fixtureId)),"A coordinates-only edit requires fresh analysis rather than an impossible review");
 queryExecute("UPDATE public.tb_evento_corridas SET coordenadas='',localizacoes=jsonb_build_object('manual',true) WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 check(guide.isStale(store,work,store.event(fixtureId)),"A JSONB destination-only edit requires fresh analysis");
 queryExecute("UPDATE public.tb_evento_corridas SET endereco='Depois',localizacoes='{}'::jsonb WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 newer=store.enqueue([fixtureId],"fixture");
 queryExecute("UPDATE public.tb_evento_geocoding SET status='needs_review',decision=CAST(:body AS jsonb) WHERE id=:id",{body={value=serializeJSON(store.lowerKeys(decision)),cfsqltype="cf_sql_longvarchar"},id={value=newer[1],cfsqltype="cf_sql_bigint"}},db);
 check(newer[1] NEQ ids[1] AND !guide.queue("Skip de evento fixture","todos","",[fixtureId]).recordCount,"A skipped event remains skipped when the worker creates a newer proposal");
 transaction action="rollback";
}
writeOutput("GEO_REVIEW_GUIDE_PASSED");
</cfscript>
