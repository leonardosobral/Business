<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
function stateRow(required query rows,required string code){for(var item in rows)if(item.state_code EQ code)return item;return {eligible_total=0,mapped_total=0,confirmed_total=0,legacy_total=0,suspicious_total=0,absent_total=0};}
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};prefix="RadarFixture20261020";
check(store.radarReady(),"Radar coverage detects the shared coordinate schema");
check(queryExecute("SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' AND column_name IN('latitude','longitude','localizacoes') GROUP BY table_name HAVING count(*)=3",[],db).recordCount EQ 1,"Shared event schema exposes normalized coordinates and provenance");
baseline=store.radarCoverage();baselineStates=store.radarCoverageByState();baselineSc=stateRow(baselineStates,"SC");baselinePr=stateRow(baselineStates,"PR");
transaction {
    queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,tag,cidade,estado,pais,endereco,data_inicial,data_final,ativo,coordenadas,localizacoes) VALUES
        (2147001001,:n1,'radar-fixture-1','Florianópolis','SC','BR','',CURRENT_DATE+10,CURRENT_DATE+10,true,'-27.1000000,-48.1000000',CAST(:l1 AS jsonb)),
        (2147001002,:n2,'radar-fixture-2','Florianópolis','SC','BR','',CURRENT_DATE+10,CURRENT_DATE+10,true,'-27.2000000,-48.2000000','{}'::jsonb),
        (2147001003,:n3,'radar-fixture-3','Florianópolis','SC','BR','',CURRENT_DATE+10,CURRENT_DATE+10,true,'','{}'::jsonb),
        (2147001004,:n4,'radar-fixture-4','Florianópolis','SC','BR','',CURRENT_DATE+60,CURRENT_DATE+60,true,'0,0','{}'::jsonb),
        (2147001005,:n5,'radar-fixture-5','Florianópolis','SC','BR','',CURRENT_DATE+60,CURRENT_DATE+60,true,'-27.3000000,-48.3000000',CAST(:l5 AS jsonb)),
        (2147001006,:n6,'radar-fixture-6','Florianópolis','SC','BR','',CURRENT_DATE+60,CURRENT_DATE+60,true,'-27.4000000,-48.4000000','{}'::jsonb),
        (2147001007,:n7,'radar-fixture-7','Florianópolis','SC','BR','',CURRENT_DATE+120,CURRENT_DATE+120,true,'-27.4000000,-48.4000000','{}'::jsonb),
        (2147001008,:n8,'radar-fixture-8','Florianópolis','SC','BR','',CURRENT_DATE+120,CURRENT_DATE+120,true,'-27.5000000,-48.5000000','{}'::jsonb),
        (2147001009,:n9,'radar-fixture-9','Curitiba','PR','BR','',CURRENT_DATE+120,CURRENT_DATE+120,true,'-27.5000000,-48.5000000','{}'::jsonb)",{
            n1={value=prefix & " Confirmed",cfsqltype="cf_sql_varchar"},n2={value=prefix & " Legacy",cfsqltype="cf_sql_varchar"},n3={value=prefix & " Absent",cfsqltype="cf_sql_varchar"},n4={value=prefix & " Null Island",cfsqltype="cf_sql_varchar"},n5={value=prefix & " Mismatch",cfsqltype="cf_sql_varchar"},n6={value=prefix & " Same Venue A",cfsqltype="cf_sql_varchar"},n7={value=prefix & " Same Venue B",cfsqltype="cf_sql_varchar"},n8={value=prefix & " Cross City A",cfsqltype="cf_sql_varchar"},n9={value=prefix & " Cross City B",cfsqltype="cf_sql_varchar"},
            l1={value='{"evento":{"precisao":"local_confirmado","coordenadas":"-27.1000000,-48.1000000"}}',cfsqltype="cf_sql_longvarchar"},
            l5={value='{"evento":{"precisao":"local_confirmado","coordenadas":"-27.3100000,-48.3100000"}}',cfsqltype="cf_sql_longvarchar"}
        },db);
    stats=store.radarCoverage();
    check(stats.total-baseline.total EQ 9,"Coverage counts only the nine eligible fixtures");
    check(stats.mapped-baseline.mapped EQ 8,"Coverage counts eight published coordinate pairs");
    check(stats.confirmed-baseline.confirmed EQ 1,"Matching structured provenance is confirmed");
    check(stats.legacy-baseline.legacy EQ 3,"Legacy includes a valid pair and two legitimate same-city venue rows");
    check(stats.suspicious-baseline.suspicious EQ 4,"Null island, provenance mismatch and two cross-city duplicates are suspicious");
    check(stats.absent-baseline.absent EQ 1,"Missing coordinates remain absent");
    check(stats.next30-baseline.next30 EQ 3 AND stats.next90-baseline.next90 EQ 3 AND stats.later-baseline.later EQ 3,"Coverage separates 30-day, 90-day and later horizons");
    states=store.radarCoverageByState();sc=stateRow(states,"SC");pr=stateRow(states,"PR");
    check(sc.eligible_total-baselineSc.eligible_total EQ 8 AND pr.eligible_total-baselinePr.eligible_total EQ 1,"State coverage groups eligible events by UF");
    rows=store.radarCoveragePage(1,prefix,"all","all","");
    check(rows.recordCount EQ 9 AND rows.recordCount LTE 21,"Coverage page is search-scoped and bounded to 21 rows");
    suspicious=store.radarCoveragePage(1,prefix,"suspicious","all","");
    check(suspicious.recordCount EQ 4,"Quality filter returns only suspicious fixtures");
    legacy=store.radarCoveragePage(1,prefix,"legacy","all","SC");
    check(legacy.recordCount EQ 3,"Same-city shared coordinates remain legacy instead of suspicious");
    transaction action="rollback";
}
check(queryExecute("SELECT 1 FROM public.tb_evento_corridas WHERE nome_evento LIKE :prefix",{prefix={value=prefix & "%",cfsqltype="cf_sql_varchar"}},db).recordCount EQ 0,"Coverage fixtures are rolled back");
writeOutput("GEO_RADAR_COVERAGE_PASSED");
</cfscript>
