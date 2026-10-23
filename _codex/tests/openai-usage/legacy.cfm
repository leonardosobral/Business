<cfscript>
function usageAssert(required boolean ok,required string message){if(!ok)throw(type="UsageTest.Failed",message=message);}
s=new __GEO_TEST_PACKAGE__.services.openaiUsage.Store();f=s.filters({period="7"});
legacyFixture=new __GEO_TEST_PACKAGE__.services.openaiUsage.Legacy();
usageAssert(structIsEmpty(legacyFixture.legacyUsage({input_tokens=0,output_tokens=0,status="completed"})),"Zeros legados sem evidência de uso devem permanecer desconhecidos.");
usageAssert(legacyFixture.legacyUsage({input_tokens=10,output_tokens=1,status="completed"}).input_tokens EQ 10,"Uso legado positivo deve ser preservado.");
transaction{
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 r=new __GEO_TEST_PACKAGE__.services.openaiUsage.Legacy().load(f,f.toMs);
 usageAssert(!arrayLen(r.warnings),"Todas as consultas legadas devem funcionar: " & serializeJSON(r.warnings));
 usageAssert(arrayLen(r.rows) GT 0,"Histórico real precisa estar disponível.");
 summary=s.summarize(r.rows,f);usageAssert(summary.summary.legacy GT 0 AND summary.summary.requests EQ 0,"Execuções legadas não podem ser rotuladas como chamadas HTTP.");
 usageAssert(!arrayLen(new __GEO_TEST_PACKAGE__.services.openaiUsage.Legacy().load(f,f.fromMs).rows),"Cutover não pode incluir legado posterior à coleta.");
 writeOutput(serializeJSON({records=summary.summary.records,tokens=summary.summary.tokens,unknown=summary.summary.unknown}));
}
writeOutput("GEO_LEGACY_PASSED");
</cfscript>
