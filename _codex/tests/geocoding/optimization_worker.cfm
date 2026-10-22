<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};
function insertFixture(required numeric id){queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=id,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});}
transaction {
 insertFixture(2147001202);ids=store.enqueue([2147001202],"fixture");worker=new OptimizationWorker(ids);worker.blockAI();result=worker.run(1);
 check(result.processed EQ 1 AND result.suggestions EQ 1,"AI cooldown still produces a private municipal suggestion");
 check(worker.aiCallCount() EQ 0 AND worker.sourceCallCount() EQ 0,"Known AI cooldown consumes neither AI credits nor official-source downloads");
 work=store.detail(ids[1]);progress=deserializeJSON(work.decision);
 check(!progress.analysis_complete AND isDate(work.next_retry_at) AND work.attempts EQ 0,"Incomplete research is scheduled automatically with durable progress");
 check(!len(store.event(2147001202).coordenadas),"Municipal fallback is never a canonical race point");
 transaction action="rollback";
}
transaction {
 insertFixture(2147001203);insertFixture(2147001204);ids=store.enqueue([2147001203,2147001204],"fixture");worker=new OptimizationWorker(ids);worker.failFirst();result=worker.run(2);
 check(result.processed EQ 2 AND worker.aiCallCount() EQ 1,"One unavailable source does not block the next event in the batch");
 check(!len(store.event(2147001203).coordenadas) AND len(store.event(2147001204).coordenadas),"Only the second event with verified evidence receives canonical coordinates");
 transaction action="rollback";
}
transaction {
 insertFixture(2147001205);ids=store.enqueue([2147001205],"fixture");worker=new OptimizationWorker(ids);worker.setTemporarySource(true);result=worker.run(1);
 check(worker.aiCallCount() EQ 1 AND len(store.event(2147001205).coordenadas),"Readable official evidence is used even if a different source is temporarily unavailable");
 progress=deserializeJSON(store.detail(ids[1]).decision);
 check(!progress.analysis_complete AND progress.retry_after_seconds GTE 21600,"Partial research is retained and automatically retried with bounded backoff");
 transaction action="rollback";
}
writeOutput("GEO_OPTIMIZATION_WORKER_PASSED");
</cfscript>
