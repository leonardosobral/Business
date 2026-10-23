<cfscript>
function usageAssert(required boolean ok,required string message){if(!ok)throw(type="UsageTest.Failed",message=message);}
o=new __GEO_TEST_PACKAGE__.services.openaiUsage.Observer();
e=o.normalize("geolocation","extract","gpt-6-astra",{statusCode="200 OK",fileContent=serializeJSON({id="resp_test_1",model="gpt-6-astra",status="incomplete",usage={input_tokens=1000,output_tokens=30,input_tokens_details={cached_tokens=100,cache_write_tokens=0},output_tokens_details={reasoning_tokens=10}},output=[{text="PRIVATE-CONTENT sk-proj-very-private-secret"}]})},50);
usageAssert(e.tokens_known AND e.input_tokens EQ 1000 AND e.output_tokens EQ 30 AND e.status EQ "incomplete","Contar uso mesmo quando a resposta for incompleta.");
usageAssert(!find("PRIVATE-CONTENT",serializeJSON(e)) AND !find("sk-proj",serializeJSON(e)),"Nunca guardar texto de resposta ou segredo.");
e=o.normalize("ai-mails","analyze","gpt-5.6-luna",{statusCode="429 Too Many Requests",fileContent='{"error":{"code":"insufficient_quota","message":"PRIVATE-CONTENT"}}'},20);
usageAssert(!e.tokens_known AND !e.cost_known AND e.status EQ "error" AND e.error_code EQ "insufficient_quota","429 sem uso é desconhecido, não grátis.");
e=o.normalize("helpdesk","draft","gpt-6.1-sol",{},30);
usageAssert(e.http_status EQ 0 AND !e.tokens_known,"Timeout sem resposta deve ser visível.");
e=o.normalize("geolocation","extract","gpt-6-astra",{statusCode="200",fileContent='{"status":"failed","usage":{"input_tokens":100,"output_tokens":10}}'},1);
usageAssert(e.status EQ "error" AND e.tokens_known,"Falha da resposta HTTP 200 deve preservar uso e status correto.");
e=o.normalize("geolocation","extract","gpt-6-astra",{statusCode="200",fileContent='{"status":"in_progress"}'},1);
usageAssert(e.status EQ "incomplete","Resposta ainda em processamento não é concluída.");
testDir=getTempDirectory() & "usage-test-" & createUUID();directoryCreate(testDir);
try{
 disk=new __GEO_TEST_PACKAGE__.services.openaiUsage.Observer(testDir);
 usageAssert(disk.observe("helpdesk","draft","gpt-6.1-sol",{statusCode="200",fileContent='{"status":"completed","usage":{"input_tokens":100,"output_tokens":10}}'},5),"Registrar evento no diário privado.");
 files=directoryList(testDir,false,"path","*.jsonl");usageAssert(arrayLen(files) EQ 1,"Um arquivo diário.");
 usageAssert(isJSON(trim(fileRead(files[1],"utf-8"))),"JSONL válido.");
 usageThreads=[];
 for(usageIndex=1;usageIndex LTE 12;usageIndex++){
  usageThreadName="usage_" & replace(createUUID(),"-","","all");arrayAppend(usageThreads,usageThreadName);
  thread name=usageThreadName usageDirectory=testDir {
   new __GEO_TEST_PACKAGE__.services.openaiUsage.Observer(attributes.usageDirectory).observe("helpdesk","draft","gpt-6.1-sol",{statusCode="200",fileContent='{"usage":{"input_tokens":10,"output_tokens":1}}'},1);
  }
 }
 thread action="join" name=arrayToList(usageThreads) timeout=10000;
 usageLines=listToArray(trim(fileRead(files[1],"utf-8")),chr(10));usageAssert(arrayLen(usageLines) EQ 13,"Escrita concorrente não pode perder eventos.");
 for(usageLine in usageLines)usageAssert(isJSON(usageLine),"Escrita concorrente não pode intercalar JSON.");
 usageAssert(!new __GEO_TEST_PACKAGE__.services.openaiUsage.Observer(testDir & "/missing").observe("helpdesk","draft","gpt-6.1-sol",{},1),"Falha de telemetria não pode lançar exceção.");
}finally{directoryDelete(testDir,true);}
writeOutput("GEO_OBSERVER_PASSED");
</cfscript>
