<cfscript>
fixtureStore=new services.geocoding.LocationStore();fixtureId=2147000001;fixtureOptions={datasource="runner_dba"};
transaction {
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Falha isolada Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWorker=new FixtureAIWorker(fixtureIds[1]);fixtureWorker.setUnavailableAI();fixtureResult=fixtureWorker.run(1);
 if(fixtureResult.status NEQ "ai_unavailable")throw(type="Test.Failed",message="Provider failure changed into " & fixtureResult.status);transaction action="rollback";
}
writeOutput("GEO_AI_PROVIDER_FAILURE_PASSED");
</cfscript>
