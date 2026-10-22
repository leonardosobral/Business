<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};fixtureId=2147001801;
check(structKeyExists(store,"correctField"),"Quick review supports a separate human correction, not an approval of untrusted AI evidence");
input=new services.geocoding.ReviewInput();
for(sample in [{field="estado",value="Santa Catarina",want="SC"},{field="pais",value="Brasil",want="BR"},{field="tipo_corrida",value="trail",want="trail"},{field="data_inicial",value="2026-11-15",want="2026-11-15"},{field="regras_participacao",value="  Apenas maiores de 18 anos.  ",want="Apenas maiores de 18 anos."}])check(input.validate(sample.field,sample.value,{}) EQ sample.want,"Manual input is normalized for " & sample.field);
for(sample in [{field="coordenadas",value="-23,-46"},{field="organizador",value=" "},{field="organizador",value=repeatString("x",121)},{field="organizador",value="<script>alert(1)</script>"},{field="data_inicial",value="2026-02-30"},{field="data_final",value="2026-10-01",event={data_inicial=createDate(2026,11,15)}},{field="estado",value="inexistente"},{field="pais",value="ZZ"},{field="tipo_corrida",value="invalido"},{field="url_hotsite",value="javascript:alert(1)"},{field="url_regulamento",value="https://localhost/reg"},{field="url_inscricao",value="https://127.0.0.1/"}]){
 denied=false;try{input.validate(sample.field,sample.value,sample.event ?: {});}catch(Geocoding.Validation invalid){denied=true;}check(denied,"Invalid manual value cannot be saved: " & sample.field & " / " & left(sample.value,25));
}
function fixture(){
 check(!store.event(fixtureId).exists,"No existing event is replaced by the rollback fixture");
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo,organizador) VALUES(:id,'Correção humana fixture','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true,'Antes')",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
 var ids=store.enqueue([fixtureId],"fixture");
 var decision={analysis_complete=true,targets=[],enrichment={fields=[{field="regras_participacao",label="Regras",status="needs_review",trusted=false,value="Versão da fonte A",evidence={excerpt="Original A"},reasons=["conflicting_sources"]},{field="regras_participacao",label="Regras",status="needs_review",trusted=false,value="Versão da fonte B",evidence={excerpt="Original B"},reasons=["conflicting_sources"]},{field="organizador",label="Organizador",status="needs_review",trusted=false,value="Organizador errado",evidence={},reasons=[]}]}};
 queryExecute("UPDATE public.tb_evento_geocoding SET status='needs_review',decision=CAST(:body AS jsonb) WHERE id=:id",{body={value=serializeJSON(store.lowerKeys(decision)),cfsqltype="cf_sql_longvarchar"},id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 return store.detail(ids[1]);
}
transaction {
 work=fixture();store.correctField(work.id,2,"Maiores de 18 anos, com documento.","fixture-human",work.proposal_revision & "");
 saved=store.detail(work.id);decision=deserializeJSON(saved.decision & "");locations=deserializeJSON(store.event(fixtureId).localizacoes & "");
 check(locations.enriquecimento.fields.regras_participacao.value EQ "Maiores de 18 anos, com documento." AND locations.enriquecimento.fields.regras_participacao.origin EQ "human_corrected","The edited complementary value is stored as human-reviewed data");
 check(!decision.enrichment.fields[2].trusted AND decision.enrichment.fields[2].value EQ "Versão da fonte B" AND decision.enrichment.fields[2].evidence.excerpt EQ "Original B","Manual correction preserves the AI proposal and never upgrades its trust");
 guide=new services.geocoding.ReviewGuide();next=guide.continuation(store,work.id,"Correção humana fixture","todos","",[]);
 check(next.id EQ work.id AND next.key EQ "field-3","A correction resolves duplicate variants and automatically opens the next different pending field");
 audit=queryExecute("SELECT actor,created_at,details FROM public.tb_evento_geocoding_audit WHERE work_id=:id AND action='field_corrected'",{id={value=work.id,cfsqltype="cf_sql_bigint"}},db);
 check(audit.recordCount EQ 1 AND audit.actor[1] EQ "fixture-human" AND isDate(audit.created_at[1]) AND find("Maiores de 18 anos",audit.details[1] & ""),"Permanent audit contains the actual human value, author and timestamp");
 store.correctField(work.id,3,"Organização revisada","fixture-human",saved.proposal_revision & "");
 saved=store.detail(work.id);check(store.event(fixtureId).organizador EQ "Organização revisada" AND saved.source_hash EQ work.source_hash,"A native correction settles the snapshot without changing the original work identity");
 check(!guide.isStale(store,saved,store.event(fixtureId)) AND guide.continuation(store,work.id,"Correção humana fixture","todos","",[]).id EQ 0,"The last correction completes the sequence and leaves a current snapshot");
 check(!len(store.event(fixtureId).coordenadas ?: ""),"Editing a field never invents or approves approximate coordinates");
 transaction action="rollback";
}
transaction {
 work=fixture();progress=deserializeJSON(work.decision & "");source=deserializeJSON(work.source_snapshot & "");
 progress.enrichment.fields=[{field="data_inicial",label="Data inicial",status="needs_review",trusted=false,value=source.start_date,evidence={},reasons=[]}];
 queryExecute("UPDATE public.tb_evento_geocoding SET decision=CAST(:body AS jsonb) WHERE id=:id",{body={value=serializeJSON(store.lowerKeys(progress)),cfsqltype="cf_sql_longvarchar"},id={value=work.id,cfsqltype="cf_sql_bigint"}},db);
 newDate=dateFormat(dateAdd("d",-1,now()),"yyyy-mm-dd");store.correctField(work.id,1,newDate,"fixture-human",work.proposal_revision & "");
 saved=store.detail(work.id);progress=deserializeJSON(saved.decision & "");
 check(progress.enrichment.fields[1].manual.source_date EQ newDate AND dateFormat(store.event(fixtureId).data_inicial,"yyyy-mm-dd") EQ newDate AND saved.status EQ "pending","Correcting the event date binds the human decision to the new edition and schedules fresh location research");
 transaction action="rollback";
}
for(scenario in ["revision","coordinates","jsonb","native","running"]){
 transaction {
  work=fixture();
  if(scenario EQ "coordinates")queryExecute("UPDATE public.tb_evento_corridas SET coordenadas='-23.5,-46.6' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
  if(scenario EQ "jsonb")queryExecute("UPDATE public.tb_evento_corridas SET localizacoes=jsonb_build_object('manual',true) WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
  if(scenario EQ "native")queryExecute("UPDATE public.tb_evento_corridas SET organizador='Alterado por outro operador' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
  if(scenario EQ "running")queryExecute("UPDATE public.tb_evento_geocoding SET status='running' WHERE id=:id",{id={value=work.id,cfsqltype="cf_sql_bigint"}},db);
  denied=false;try{store.correctField(work.id,2,"Correção que não deve gravar","fixture-human",scenario EQ "revision" ? "999999" : work.proposal_revision & "");}catch(Geocoding.Validation invalid){denied=true;}
  check(denied,"A human edit cannot bypass " & scenario & " concurrency protection");transaction action="rollback";
 }
}
check(!store.event(fixtureId).exists,"All manual-review fixture writes are rolled back");writeOutput("GEO_REVIEW_EDIT_PASSED");
</cfscript>
