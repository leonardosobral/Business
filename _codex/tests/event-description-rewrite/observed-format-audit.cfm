<cfscript>
// Read-only replay of the exact rejection placed in scope by the user. The
// provider reviewer is simulated: this proves local guards, NOT semantic approval.
formatAudit=queryExecute("SELECT description_after FROM public.tb_evento_descricao_translations
    WHERE id=:id AND id_evento=:event_id AND language='en' AND status='rejected'",{
    id={value=13435,cfsqltype="cf_sql_bigint"},event_id={value=39412,cfsqltype="cf_sql_integer"}
},{datasource="runner_dba"});
check(formatAudit.recordCount EQ 1 AND isJSON(formatAudit.description_after),"The exact reported translation audit remains available");
formatEnvelope=deserializeJSON(formatAudit.description_after);
check(formatEnvelope.version EQ 1 AND len(formatEnvelope.source) LTE 20000 AND len(formatEnvelope.candidate) LTE 60000,"Observed source and candidate have bounded private evidence");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao=formatEnvelope.candidate}),responseFor({preserved=true,target_language=true,reason="Fixture only; independent live review remains mandatory."})]);
formatObserved=fixture.translate(formatEnvelope.source,"en","SENSITIVE_FIXTURE");
check(arrayLen(fixture.getRequests()) EQ 2 AND find("7.000",formatObserved.text) AND find("21/08/2026",formatObserved.text),"Audit 13435 now passes deterministic checks with source spellings restored");
formatObservedDelta=service.compareAuditFacts(formatEnvelope.source,formatEnvelope.candidate,"en");
for(formatKind in formatObservedDelta) check(!formatObservedDelta[formatKind].missingTotal AND !formatObservedDelta[formatKind].addedTotal,"Observed audit has no changed fact after safe format equivalence: " & formatKind);
writeOutput("OBSERVED_FORMAT_AUDIT_PASSED (read-only; no provider calls or content writes)" & chr(10));
</cfscript>
