<cfscript>
ns="fixture-concurrent-" & createUUID();names=[];
try{
 for(i=1;i LTE 2;i++){
  threadName="geoBudget" & replace(createUUID(),"-","","all");arrayAppend(names,threadName);
  thread name=threadName action="run" budgetNamespace=ns requestId="parallel-#i#" {
   thread.result=new services.geocoding.AIBudget(attributes.budgetNamespace).reserve(attributes.requestId,"gpt-6.1-sol","default",1.2);
  }
 }
 thread action="join" name=arrayToList(names) timeout=20000;
 allowed=0;for(threadName in names){if(!structKeyExists(cfthread[threadName],"result"))throw(type="EconomyTest",message="Thread deve concluir sem erro.");if(cfthread[threadName].result.created)allowed++;}
 if(allowed NEQ 1 OR new services.geocoding.AIBudget(ns).status().pending_usd NEQ 1.2)throw(type="EconomyTest",message="Reservas concorrentes não podem superar USD2.");
}finally{
 // Only this generated fixture namespace; no event or production budget rows.
 queryExecute("DELETE FROM public.tb_geocoding_cache WHERE query_text IN(:ns,:control)",{ns={value=ns,cfsqltype="cf_sql_varchar"},control={value=ns & "-lock",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
}
writeOutput("GEO_ECONOMY_CONCURRENT_PASSED");
</cfscript>
