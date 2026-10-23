<cfscript>
function usageAssert(required boolean ok,required string message){if(!ok)throw(type="UsageTest.Failed",message=message);}
function mailWire(required any value){return value;}
REQUEST.usageFixtureDir=getTempDirectory() & "usage-wrappers-" & createUUID();directoryCreate(REQUEST.usageFixtureDir);
REQUEST.usageFixtureConfig={configured=true,apiKey="synthetic",model="gpt-6.1-sol"};REQUEST.usageFixtureThrow=false;
REQUEST.usageFixtureResponse={statusCode="200 OK",fileContent=serializeJSON({id="resp_fixture",status="completed",model="gpt-6.1-sol",usage={input_tokens=1000,output_tokens=100,input_tokens_details={cached_tokens=200,cache_write_tokens=0}},output_text='{"summary":"synthetic"}',output=[{type="message",content=[{type="output_text",text='{"event_name":"Synthetic","event_date":"2026-10-23","identity_quote":"","locations":[]}'}]}]})};
try{
 include "ai-mails.cfm";
 mailOpenAI("responses",{model="gpt-6.1-sol"});
 new __GEO_TEST_PACKAGE__.tests.Rewrite().requestProvider({model="gpt-4.1-mini"},"synthetic");
 new __GEO_TEST_PACKAGE__.tests.Geo("synthetic","gpt-6-astra").extract({},[]);
 new __GEO_TEST_PACKAGE__.tests.Helpdesk("synthetic").exercise();
 new __GEO_TEST_PACKAGE__.tests.Vicky({}, {}, {}).exercise();
 new __GEO_TEST_PACKAGE__.tests.Summary().generate({},REQUEST.usageFixtureConfig);
 new __GEO_TEST_PACKAGE__.tests.Digest().createWeeklyDigest([],"synthetic");
 REQUEST.usageFixtureResponse={statusCode="200 OK",fileContent=charsetDecode("synthetic","utf-8")};
 new __GEO_TEST_PACKAGE__.tests.Audio().synthesize("synthetic",{apiKey="synthetic",model="gpt-4o-mini-tts",voice="alloy",speed=1});
 files=directoryList(REQUEST.usageFixtureDir,false,"path","*.jsonl");
 usageAssert(arrayLen(files) EQ 1,"Os wrappers reais devem registrar as chamadas no diário.");
 lines=listToArray(trim(fileRead(files[1],"utf-8")),chr(10));usageAssert(arrayLen(lines) EQ 8,"Uma observação por chamada, sem duplicar retorno/validação.");
 REQUEST.usageFixtureResponse={statusCode="429 Too Many Requests",fileContent='{"error":{"code":"insufficient_quota"}}'};
 try{new __GEO_TEST_PACKAGE__.tests.Rewrite().requestProvider({model="gpt-4.1-mini"},"synthetic");}catch(any expected){}
 REQUEST.usageFixtureThrow=true;
 try{new __GEO_TEST_PACKAGE__.tests.Helpdesk("synthetic").exercise();}catch(any expected){}
 lines=listToArray(trim(fileRead(files[1],"utf-8")),chr(10));usageAssert(arrayLen(lines) EQ 10,"429 e timeout também precisam ser registrados.");
 usageAssert(!deserializeJSON(lines[9]).tokens_known AND deserializeJSON(lines[10]).http_status EQ 0,"Falhas sem contagem não podem gerar tokens/custo fictícios.");
 usageAssert(!find("synthetic",fileRead(files[1],"utf-8")),"Não registrar input/payload/chave de teste.");
}finally{directoryDelete(REQUEST.usageFixtureDir,true);}
writeOutput("GEO_WRAPPERS_PASSED");
</cfscript>
