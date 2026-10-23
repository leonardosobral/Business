<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
transaction{
 b=new services.geocoding.AIBudget("fixture-" & createUUID());p=new services.geocoding.EconomyPolicy();body=p.body({},[]);b.reserve("paused-upload",body.model,"batch",p.reserveUSD(body,"batch"));
 gate=new EconomyFixtureStore();transport=new PausingBatchTransport(gate);temp=getTempDirectory() & "geo-pause-fixture-" & createUUID();directoryCreate(temp);
 try{
  batchFixture=new services.geocoding.BatchClient(b,transport,temp,transport,gate);
  result=batchFixture.submit("paused-upload",body);
  check(result.code EQ "disabled" AND arrayLen(transport.calls()) EQ 1 AND transport.calls()[1].path EQ "files","Pausar durante upload deve impedir criação paga do lote.");
  check(b.get("paused-upload").state EQ "uploaded" AND b.status().pending_usd GT 0,"Upload confirmado mantém reserva e pode retomar sem novo upload.");
  gate.resume();batchFixture.submit("paused-upload",body);check(arrayLen(transport.calls()) EQ 2 AND transport.calls()[2].path EQ "batches","Retomar somente criação ainda não enviada.");
  gate2=new EconomyFixtureStore();pollTransport=new PausingBatchTransport(gate2,"batches/batch_fixture");
  pollFixture=new services.geocoding.BatchClient(b,pollTransport,temp,pollTransport,gate2);
  result=pollFixture.poll(b.get("paused-upload"));check(result.code EQ "disabled" AND arrayLen(pollTransport.calls()) EQ 1,"Pausar no status deve impedir consulta seguinte ao resultado.");
 }finally{directoryDelete(temp,true);}
 transaction action="rollback";
}
writeOutput("GEO_ECONOMY_BATCH_PAUSE_PASSED");
</cfscript>
