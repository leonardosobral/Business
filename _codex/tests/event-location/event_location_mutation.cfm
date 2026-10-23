<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
include '../eventos/includes/backend/event_delegation.cfm';include '../eventos/includes/backend/event_mutations.cfm';
db={datasource="runner_dba"};id=2147001901;REQUEST.businessIdentity={id=1};state={adminIsAdmin=true};
function posted(){return {action="editar_evento_basico",id_evento=id & "",nome_evento="Evento internacional fixture",tag="evento-internacional-fixture-2147001901",tipo_corrida="rua",data_inicial="2026-11-08",data_final="2026-11-08",pais="PT",cidade="Porto",estado="13",regiao_internacional="Distrito do Porto",endereco="Avenida da Boavista",coordenadas="41.1579,-8.6291",url_inscricao="https://example.com/inscricao",url_hotsite="https://example.com/evento"};}
transaction {
 check(!queryExecute('SELECT 1 FROM tb_evento_corridas WHERE id_evento=:id',{id={value=id,cfsqltype="cf_sql_integer"}},db).recordCount,"An existing event is never replaced by the fixture");
 queryExecute("INSERT INTO tb_evento_corridas(id_evento,nome_evento,pais,estado,cidade,cod_cidade,data_inicial,data_final,localizacoes) VALUES(:id,'Evento internacional fixture','BR','SC','Florianópolis',4205407,CURRENT_DATE,CURRENT_DATE,CAST(:locations AS jsonb))",{id={value=id,cfsqltype="cf_sql_integer"},locations={value='{"kit":[{"nome_local":"Kit preservado"}]}',cfsqltype="cf_sql_longvarchar"}},db);
 structClear(FORM);structAppend(FORM,posted());failed=false;why="";try{eventMutationEdit({datasource="runner_dba"},state);}catch(any failure){failed=true;why=failure.type & ": " & failure.message;}
 check(!failed,"The actual event save accepts a foreign city without IBGE: " & why);
 saved=queryExecute("SELECT *,cod_cidade IS NULL AS no_ibge,localizacoes->'administrativo'->>'estado_nome' AS region FROM tb_evento_corridas WHERE id_evento=:id",{id={value=id,cfsqltype="cf_sql_integer"}},db);
 check(saved.pais[1] EQ "PT" AND saved.cidade[1] EQ "Porto" AND saved.estado[1] EQ "13" AND saved.no_ibge[1] AND saved.region[1] EQ "Distrito do Porto","Country, foreign city, optional short code, full subdivision and null IBGE persist");
 for(savedRow in saved)check(new services.EventLocationPolicy().currentRegion(savedRow) EQ "Distrito do Porto","The editor reloads the full subdivision from the actual JDBC JSONB value");
 check(deserializeJSON(saved.localizacoes[1] & "").kit[1].nome_local EQ "Kit preservado","Changing administrative geography does not overwrite race/kit location metadata");
 FORM.pais="BR";FORM.estado="SC";FORM.cidade="4205407";FORM.regiao_internacional="";eventMutationEdit({datasource="runner_dba"},state);
 saved=queryExecute("SELECT *,jsonb_exists(localizacoes,'administrativo') AS stale_region FROM tb_evento_corridas WHERE id_evento=:id",{id={value=id,cfsqltype="cf_sql_integer"}},db);
 check(saved.pais[1] EQ "BR" AND saved.cod_cidade[1] EQ 4205407 AND saved.cidade[1] EQ "Florianópolis" AND !saved.stale_region[1],"Returning to Brazil restores a valid municipality and removes foreign-only subdivision metadata");
 transaction action="rollback";
}
transaction {
 structClear(FORM);structAppend(FORM,posted());FORM.id_evento="0";FORM.tag="codex-international-fixture-" & lCase(replace(createUUID(),"-","","all"));FORM.pais="SG";FORM.cidade="Singapore";FORM.estado="";FORM.regiao_internacional="";FORM.coordenadas="";
 eventMutationEdit({datasource="runner_dba"},state);
 saved=queryExecute("SELECT pais,cidade,estado IS NULL AS no_region,cod_cidade IS NULL AS no_ibge FROM tb_evento_corridas WHERE id_evento=:id",{id={value=state.qInsert.id_evento,cfsqltype="cf_sql_integer"}},db);
 check(saved.pais[1] EQ "SG" AND saved.cidade[1] EQ "Singapore" AND saved.no_region[1] AND saved.no_ibge[1],"The actual create path saves an international event with optional subdivision and no Brazilian city code");
 transaction action="rollback";
}
transaction {
 structClear(FORM);structAppend(FORM,posted());state={adminIsAdmin=false,qEventosConta=queryNew("id_evento")};denied=false;
 try{eventMutationEdit({datasource="runner_dba"},state);}catch(BusinessDelegation.NotFound blocked){denied=true;}
 check(denied,"International fields do not bypass existing account/event authorization");transaction action="rollback";
}
writeOutput("GEO_EVENT_LOCATION_MUTATION_PASSED");
</cfscript>
