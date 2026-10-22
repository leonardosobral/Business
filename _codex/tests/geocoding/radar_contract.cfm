<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};prefix="RadarContract20261020";
usageBefore=queryExecute("SELECT COALESCE(sum(calls),0) AS calls FROM public.tb_geocoding_usage_daily WHERE provider='geoapify'",[],db).calls[1];
transaction {
    queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,tag,cidade,estado,pais,endereco,data_inicial,data_final,ativo,coordenadas,localizacoes) VALUES
      (2147001101,:name1,'radar-contract-1','Florianópolis','SC','BR','',CURRENT_DATE+10,CURRENT_DATE+10,true,'','{}'::jsonb),
      (2147001102,:name2,'radar-contract-2','Florianópolis','SC','BR','',CURRENT_DATE+10,CURRENT_DATE+10,true,'','{}'::jsonb)",{name1={value=prefix & " Confirmed",cfsqltype="cf_sql_varchar"},name2={value=prefix & " City Suggestion",cfsqltype="cf_sql_varchar"}},db);
    absent=store.radarCoveragePage(1,prefix & " Confirmed","absent","all","SC");
    check(absent.recordCount EQ 1 AND absent.quality[1] EQ "absent","Future public event without published coordinates is absent from Radar coverage");
    queryExecute("INSERT INTO public.tb_evento_geocoding(id_evento,source_hash,source_snapshot,source_values,status,decision) VALUES(2147001102,:hash,'{}'::jsonb,'[]'::jsonb,'city_suggestion',CAST(:decision AS jsonb))",{hash={value=repeatString("a",64),cfsqltype="cf_sql_char"},decision={value='{"status":"city_suggestion","candidate":{"lat":-27.59,"lon":-48.55,"result_type":"city"}}',cfsqltype="cf_sql_longvarchar"}},db);
    citySuggestion=store.radarCoveragePage(1,prefix & " City Suggestion","absent","all","SC");
    check(citySuggestion.recordCount EQ 1 AND citySuggestion.quality[1] EQ "absent" AND citySuggestion.geocoding_status[1] EQ "city_suggestion","Private city suggestion does not become a public coordinate");
    queryExecute("UPDATE public.tb_evento_corridas SET localizacoes=CAST(:locations AS jsonb),coordenadas='-27.5900000,-48.5500000' WHERE id_evento=2147001101",{locations={value='{"evento":{"precisao":"local_confirmado","coordenadas":"-27.5900000,-48.5500000"}}',cfsqltype="cf_sql_longvarchar"}},db);
    normalized=queryExecute("SELECT latitude,longitude FROM public.tb_evento_corridas WHERE id_evento=2147001101",[],db);
    check(normalized.latitude[1] EQ -27.59 AND normalized.longitude[1] EQ -48.55,"Shared trigger normalizes a confirmed Business coordinate");
    confirmed=store.radarCoveragePage(1,prefix & " Confirmed","confirmed","all","SC");
    check(confirmed.recordCount EQ 1 AND confirmed.quality[1] EQ "confirmed","Canonical Business location becomes confirmed Radar coverage");
    transaction action="rollback";
}
check(queryExecute("SELECT 1 FROM public.tb_evento_corridas WHERE nome_evento LIKE :prefix",{prefix={value=prefix & "%",cfsqltype="cf_sql_varchar"}},db).recordCount EQ 0,"Cross-system fixtures are rolled back");
usageAfter=queryExecute("SELECT COALESCE(sum(calls),0) AS calls FROM public.tb_geocoding_usage_daily WHERE provider='geoapify'",[],db).calls[1];
check(usageAfter EQ usageBefore,"Cross-system verification makes no provider call");
writeOutput("GEO_RADAR_CONTRACT_PASSED");
</cfscript>
