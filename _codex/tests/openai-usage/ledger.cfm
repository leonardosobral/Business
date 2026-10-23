<cfscript>
function usageAssert(required boolean ok,required string message){if(!ok)throw(type="UsageTest.Failed",message=message);}
testDir=getTempDirectory() & "usage-ledger-" & createUUID();directoryCreate(testDir);
try{
 o=new __GEO_TEST_PACKAGE__.services.openaiUsage.Observer(testDir);s=new __GEO_TEST_PACKAGE__.services.openaiUsage.Store(testDir);f=s.filters({period="7"});
 usageAssert(o.observe("geolocation","extract","gpt-6-astra",{statusCode="200",fileContent='{"usage":{"input_tokens":100,"output_tokens":20}}'},1),"Escrita real do diário.");
 usageLedgerPath=directoryList(testDir,false,"path","*.jsonl")[1];
 fileAppend(usageLedgerPath,'{"schema_version":1,"module":"geolocation","at_ms":' & createObject("java","java.lang.System").currentTimeMillis() & '}' & chr(10),"utf-8");
 r=s.ledger(f);usageAssert(arrayLen(r.rows) EQ 1 AND arrayLen(r.warnings) GTE 1,"Linha JSON incompleta deve ser isolada sem quebrar os agregados.");
 result=s.summarize(r.rows,f);usageAssert(result.summary.tokens EQ 120,"Medição válida preservada junto de uma linha corrompida.");
 usageAssert(r.cutoff EQ 0 AND arrayLen(r.warnings) GTE 2,"Sem marco de ativação, não misturar legado sobreposto ao diário.");
 fileWrite(testDir & "/tracking.json",'{"since_ms":"invalid"}',"utf-8");
 r=s.ledger(f);usageAssert(r.cutoff EQ 0 AND arrayLen(r.warnings) GTE 2,"Marco inválido deve bloquear mistura com legado.");
 fileWrite(testDir & "/tracking.json",serializeJSON({since_ms=f.fromMs+1000}),"utf-8");
 r=s.ledger(f);usageAssert(r.cutoff EQ f.fromMs+1000 AND arrayLen(r.warnings) EQ 1,"Marco válido deve estabelecer o corte exato. " & serializeJSON({cutoff=r.cutoff,expected=f.fromMs+1000,warnings=r.warnings,marker=fileRead(testDir & "/tracking.json","utf-8")}));
}finally{directoryDelete(testDir,true);}
writeOutput("GEO_LEDGER_PASSED");
</cfscript>
