<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
transaction{
 b=new services.geocoding.AIBudget("fixture-" & createUUID());
 p=new services.geocoding.EconomyPolicy();body=p.body({nome_evento="Corrida",start_date="2025-01-01",cidade="São Paulo",estado="SP",pais="BR"},[]);
 reservation=b.reserve("batch-test",body.model,"batch",p.reserveUSD(body,"batch"));
 // Deliberately malformed identity must never be accepted as this request's result.
 transport=new FixtureBatchTransport('{"custom_id":"wrong-id","response":{"status_code":200,"body":{"status":"completed","usage":{"input_tokens":100,"output_tokens":10},"output":[]}}}');
 temp=getTempDirectory() & "geo-batch-fixture-" & createUUID();directoryCreate(temp);
 try{
  batchFixtureClient=new services.geocoding.BatchClient(b,transport,temp,transport,new EconomyFixtureStore());
  result=batchFixtureClient.submit("batch-test",body);check(result.code EQ "ai_batch_pending" AND b.get("batch-test").batch_id EQ "batch_fixture","Persistir lote e não cobrar geração síncrona.");
  batchFixtureClient.submit("batch-test",body);check(arrayLen(transport.calls()) EQ 2,"Não reenviar arquivo/lote em retomada.");
  result=batchFixtureClient.poll(b.get("batch-test"));check(result.code EQ "ai_batch_identity" AND b.status().pending_usd GT 0,"ID incompatível não publica nem libera reserva.");
 }finally{directoryDelete(temp,true);}
 // Valid output is recovered once; repeated polling never records a second bill.
 b.reserve("valid-batch",body.model,"batch",p.reserveUSD(body,"batch"));
 b.update("valid-batch",{state="submitted",custom_id="valid-id",batch_id="batch_fixture"});
 transport.setOutput('{"custom_id":"valid-id","response":{"status_code":200,"body":{"model":"gpt-6.1-sol","status":"completed","usage":{"input_tokens":100,"output_tokens":10},"output":[{"content":[{"type":"output_text","text":"{\"event_name\":\"Teste\",\"event_date\":\"2025-01-01\",\"identity_quote\":\"Teste\",\"locations\":[]}"}]}]}}}');
 valid=batchFixtureClient.poll(b.get("valid-batch"));check(valid.ok AND b.get("valid-batch").state EQ "done","Resultado válido deve liquidar a reserva e ficar durável.");
 callsBefore=arrayLen(transport.calls());batchFixtureClient.poll(b.get("valid-batch"));check(arrayLen(transport.calls()) EQ callsBefore,"Resultado concluído não deve ser consultado nem contabilizado novamente.");
 transaction action="rollback";
}
writeOutput("GEO_ECONOMY_BATCH_PASSED");
</cfscript>
