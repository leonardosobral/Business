<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};fixtureId=2147001802;
transaction {
 check(!store.event(fixtureId).exists,"An existing event is not replaced");
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo,organizador) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true,'Organizador anterior')",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 ids=store.enqueue([fixtureId],"fixture");work=store.detail(ids[1]);source=deserializeJSON(work.source_snapshot & "");
 decision={analysis_complete=false,targets=[],enrichment={published=true,fields=[{field="organizador",label="Organizador",status="needs_review",trusted=false,value="Associação Flores",evidence={excerpt="Organizador: Associação Flores.",event_date=source.start_date},reasons=["conflicting_sources"]}]}};
 queryExecute("UPDATE public.tb_evento_geocoding SET status='needs_review',decision=CAST(:body AS jsonb) WHERE id=:id",{body={value=serializeJSON(store.lowerKeys(decision)),cfsqltype="cf_sql_longvarchar"},id={value=work.id,cfsqltype="cf_sql_bigint"}},db);
 store.correctField(work.id,1,"Organizador confirmado pelo atendente","fixture-human",work.proposal_revision & "");
 result=new FixtureEnrichmentWorker(work.id).run(1);saved=store.detail(work.id);progress=deserializeJSON(saved.decision & "");reopened=false;retained=false;
 for(field in progress.enrichment.fields)if(field.field EQ "organizador"){if(field.status EQ "needs_review")reopened=true;if(field.status EQ "corrected" AND (field.manual.value ?: "") EQ "Organizador confirmado pelo atendente")retained=true;}
 check(!result.errors AND retained AND !reopened AND store.event(fixtureId).organizador EQ "Organizador confirmado pelo atendente","Automatic research resumption preserves a human correction instead of reopening the same conflict");
 transaction action="rollback";
}
transaction {
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo,organizador) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true,'Organizador anterior')",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 ids=store.enqueue([fixtureId],"fixture");work=store.detail(ids[1]);decision.enrichment.fields[1].evidence={};
 arrayAppend(decision.enrichment.fields,{field="organizador",label="Organizador",status="needs_review",trusted=false,value="Outro organizador",evidence={},reasons=["conflicting_sources"]});
 queryExecute("UPDATE public.tb_evento_geocoding SET status='needs_review',decision=CAST(:body AS jsonb) WHERE id=:id",{body={value=serializeJSON(store.lowerKeys(decision)),cfsqltype="cf_sql_longvarchar"},id={value=work.id,cfsqltype="cf_sql_bigint"}},db);
 store.correctField(work.id,1,"Organizador confirmado pelo atendente","fixture-human",work.proposal_revision & "");
 result=new FixtureReviewCorrectionWorker(work.id).run(1);progress=deserializeJSON(store.detail(work.id).decision & "");reopened=false;corrected=0;
 for(field in progress.enrichment.fields)if(field.field EQ "organizador"){if(field.status EQ "needs_review")reopened=true;if(listFind("corrected,superseded",field.status))corrected++;}
 check(!result.errors AND !reopened AND corrected EQ 2,"A repeated untrusted conflict with empty evidence does not undo either human decision");
 transaction action="rollback";
}
writeOutput("GEO_REVIEW_EDIT_RESUME_PASSED");
</cfscript>
