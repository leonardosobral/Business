<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
transaction{
 budget=new services.geocoding.AIBudget("fixture-" & createUUID());
 fixtureStore=new EconomyFixtureStore();fixtureTransport=new FixtureBatchTransport();
 sol=new EconomyFixtureAI({ok=true,code="ok",model="gpt-6.1-sol",usage={input_tokens=100,output_tokens=10},facts={locations=[]}});
 astra=new EconomyFixtureAI({ok=true,code="ok",model="gpt-6-astra",usage={input_tokens=100,output_tokens=10},facts={locations=[]}});
 flow=new services.geocoding.Economy({aiKey="fixture-never-sent"},budget,fixtureTransport,sol,fixtureStore,astra);
 docs=[{url="https://example.org/1",text="Largada na praça central.",sha256="a"}];context={nome_evento="Teste",start_date="2099-01-01",cidade="São Paulo",estado="SP",pais="BR"};
 first=flow.extract(context,docs,{start_date="2099-01-01"});second=flow.extract(context,docs,{start_date="2099-01-01"});
 check(first.ok AND second.ok AND sol.calls() EQ 1 AND astra.calls() EQ 0 AND second.paid_calls EQ 0,"Sol por padrão; reaproveitar sem nova cobrança.");
 fixtureStore.pause();check(flow.extract(context,docs).code EQ "disabled" AND sol.calls() EQ 1,"Pausa bloqueia envio e reaproveitamento mutável.");
 transaction action="rollback";
}
transaction{
 budget=new services.geocoding.AIBudget("fixture-" & createUUID());fixtureStore=new EconomyFixtureStore();
 sol=new EconomyFixtureAI({ok=false,code="ai_invalid_response",retryAfter=300,usage={input_tokens=100,output_tokens=10}});
 astra=new EconomyFixtureAI({ok=true,code="ok",model="gpt-6-astra",usage={input_tokens=100,output_tokens=10},facts={locations=[]}});
 flow=new services.geocoding.Economy({aiKey="fixture-never-sent"},budget,fixtureTransport,sol,fixtureStore,astra);
 arrayAppend(docs,{url="https://example.org/2",text="Regulamento da mesma edição",sha256="b"});
 result=flow.extract(context,docs,{start_date="2099-01-01"});
 check(result.ok AND sol.calls() EQ 1 AND astra.calls() EQ 1 AND result.paid_calls EQ 2,"Astra seletivo após caso complexo; ambas as tentativas dentro do orçamento.");
 flow.extract(context,docs,{start_date="2099-01-01"});check(astra.calls() EQ 1,"Escalada também é idempotente.");
 transaction action="rollback";
}
transaction{
 budget=new services.geocoding.AIBudget("fixture-" & createUUID());fixtureStore=new EconomyFixtureStore();
 fixtureDir=getTempDirectory() & "geo-history-fixture-" & createUUID();directoryCreate(fixtureDir);
 try{
  history=new services.geocoding.Economy({aiKey="fixture-never-sent"},budget,fixtureTransport,sol,fixtureStore,astra,fixtureDir);
  historyResult=history.extract(context,docs,{start_date="2025-01-01"});
  check(historyResult.code EQ "ai_batch_pending" AND budget.status().batches EQ 1,"Histórico usa Batch, sem geração síncrona.");
 }finally{directoryDelete(fixtureDir,true);}
 transaction action="rollback";
}
writeOutput("GEO_ECONOMY_FLOW_PASSED");
</cfscript>
