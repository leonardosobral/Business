<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureStore=new services.geocoding.LocationStore();fixtureId=2147000091;fixtureOptions={datasource="runner_dba"};fixturePolicy=new services.geocoding.EnrichmentPolicy();
function makeEvent(){check(!fixtureStore.event(fixtureId).exists,"No real event replaced");queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);}
function makeProgress(required struct work){
 var s=deserializeJSON(work.source_snapshot & "");var identity=s.nome_evento & " " & s.start_date;
 var docs=[{url="https://example.com/regulamento",sha256=repeatString("a",64),text=identity & ". Organizador: Associação Flores. Largada na Avenida das Flores, 123, São Paulo/SP. Horários de largada: 5 km às 07:00."}];
 var facts={event_name=s.nome_evento,event_date=s.start_date,identity_document=1,identity_quote=identity,locations=[],attributes=[{field="organizador",value="Associação Flores",quote="Organizador: Associação Flores.",document_index=1,certainty="confirmed"},{field="endereco",value="Avenida das Flores, 123",quote="Largada na Avenida das Flores, 123, São Paulo/SP.",document_index=1,certainty="confirmed"},{field="horarios_largada",value="5 km às 07:00",quote="Horários de largada: 5 km às 07:00.",document_index=1,certainty="confirmed"}]};
 return {analysis_complete=true,model="fixture",targets=[],documents=docs,enrichment=fixturePolicy.validate(s,docs,facts)};
}
transaction {
 makeEvent();fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWork=fixtureStore.claim(fixtureIds[1]);fixtureProgress=makeProgress(fixtureWork);
 fixtureUpdate=fixtureStore.publishEnrichment(fixtureWork,fixtureProgress,"fixture");fixtureEvent=fixtureStore.event(fixtureId);fixtureLocations=deserializeJSON(fixtureEvent.localizacoes & "");
 check(fixtureEvent.organizador EQ "Associação Flores" AND fixtureEvent.endereco EQ "Avenida das Flores, 123","Trusted native blanks are filled without a geocoding call");
 check(fixtureLocations.enriquecimento.fields.horarios_largada.value EQ "5 km às 07:00" AND len(fixtureLocations.enriquecimento.fields.organizador.evidence.sha256),"Complementary values and field-level evidence persist in event JSONB");
 check(structKeyExists(fixtureStore.snapshot(fixtureEvent).localizacoes,"enriquecimento"),"A populated JDBC JSONB value remains in the destination snapshot (simple=" & isSimpleValue(fixtureEvent.localizacoes) & ")");
 fixtureStored=fixtureStore.detail(fixtureWork.id);check(fixtureStored.source_hash EQ fixtureWork.source_hash AND fixtureStore.sourceHash(fixtureStore.snapshot(fixtureEvent)) EQ fixtureStore.expectedHash(fixtureStored,deserializeJSON(fixtureStored.source_snapshot & "")),"Own native fills settle the snapshot without mutating the unique original work key");
 fixtureUpdate2=fixtureStore.publishEnrichment(fixtureUpdate.work,fixtureUpdate.progress,"fixture");
 fixtureAudit=queryExecute("SELECT count(*) AS n FROM public.tb_evento_geocoding_audit WHERE work_id=:id AND action='event_enriched'",{id={value=fixtureWork.id,cfsqltype="cf_sql_bigint"}},fixtureOptions);check(fixtureAudit.n[1] EQ 1,"Resume does not repeat enrichment writes or permanent audit entries");
 transaction action="rollback";
}
transaction {
 makeEvent();queryExecute("UPDATE public.tb_evento_corridas SET organizador='Cadastro manual' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWork=fixtureStore.claim(fixtureIds[1]);fixtureUpdate=fixtureStore.publishEnrichment(fixtureWork,makeProgress(fixtureWork),"fixture");
 check(fixtureStore.event(fixtureId).organizador EQ "Cadastro manual" AND fixtureUpdate.progress.enrichment.fields[1].status EQ "needs_review","Real native divergence is preserved for explicit review");
 fixtureStore.finish(fixtureUpdate.work,{status="city_suggestion",targets=[],enrichment=fixtureUpdate.progress.enrichment},"fixture");fixtureReview=fixtureStore.detail(fixtureWork.id);
 check(fixtureReview.status EQ "needs_review","Field divergences appear in the review queue even without a precise location (actual " & fixtureReview.status & ")");
 fixtureStore.reviewField(fixtureWork.id,1,"approve","fixture",fixtureReview.proposal_revision & "");check(fixtureStore.event(fixtureId).organizador EQ "Associação Flores","A current explicit human approval can resolve the real divergence");
 fixtureRejected=false;try{fixtureStore.reviewField(fixtureWork.id,1,"approve","fixture","999999");}catch(Geocoding.Validation old){fixtureRejected=true;}
 check(fixtureRejected,"Obsolete review is rejected (nested CF rollback also removes this isolated fixture)");
 transaction action="rollback";
}
transaction {
 makeEvent();fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWork=fixtureStore.claim(fixtureIds[1]);fixtureProgress=makeProgress(fixtureWork);
 queryExecute("UPDATE public.tb_evento_corridas SET organizador='Operador concorrente' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureRejected=false;try{fixtureStore.publishEnrichment(fixtureWork,fixtureProgress,"fixture");}catch(Geocoding.Validation changed){fixtureRejected=true;}
 check(fixtureRejected,"Concurrent native changes reject the stale analysis before publication");
 transaction action="rollback";
}
check(!fixtureStore.event(fixtureId).exists,"All enrichment fixture writes rolled back");writeOutput("GEO_ENRICHMENT_INTEGRATION_PASSED");
</cfscript>
