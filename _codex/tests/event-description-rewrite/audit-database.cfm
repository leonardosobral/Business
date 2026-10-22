<cfscript>
// Only explicit unused audit IDs are inserted on this connection, then rolled
// back. No schema/permission/event writes, and sequences are not advanced.
dbOptions={datasource="runner_dba"};fixtureAuditId=999000000000001;
transaction {
    collision=queryExecute("SELECT id FROM public.tb_evento_descricao_rewrites WHERE id=:id UNION ALL SELECT id FROM public.tb_evento_descricao_translations WHERE id=:id",{id={value=fixtureAuditId,cfsqltype="cf_sql_bigint"}},dbOptions);
    check(!collision.recordCount,"Rollback audit fixture refuses to overwrite an existing record");
    beforeEvent=queryExecute("SELECT md5(COALESCE(descricao_original,'')||COALESCE(descricao,'')||COALESCE(descricao_en,'')||COALESCE(descricao_es,'')||COALESCE(descricao_traducoes_meta::text,'')) AS fingerprint FROM public.tb_evento_corridas WHERE id_evento=48091",[],dbOptions);
    check(beforeEvent.recordCount EQ 1,"Rollback fixture binds the event already placed in scope by the user");
    fixtureSource="Corrida de 5 km. Auditoria isolada " & createUUID();
    sourceParams={id={value=fixtureAuditId,cfsqltype="cf_sql_bigint"},source={value=fixtureSource,cfsqltype="cf_sql_longvarchar"}};
    queryExecute("INSERT INTO public.tb_evento_descricao_rewrites(id,id_evento,source_hash,source_text,status,model) VALUES(:id,48091,md5(:source),:source,'running','test-only')",sourceParams,dbOptions);
    queryExecute("INSERT INTO public.tb_evento_descricao_translations(id,id_evento,language,source_hash,source_text,status,model) VALUES(:id,48091,'en',md5(:source),:source,'running','test-only')",sourceParams,dbOptions);
    fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="PRIVATE_REJECTED 15 km."})]);
    try {fixture.rewrite(fixtureSource,"API_KEY_NEVER_AUDIT");} catch(EventDescriptionRewrite.Validation expectedRejection) {}
    VARIABLES.rewriteResult={status="rejected"};VARIABLES.rewriteOutput={};VARIABLES.rewriteRejectedEvidence=serializeJSON(fixture.getRejectionEvidence());
    VARIABLES.rewriteErrorCode="numbers_changed";VARIABLES.rewriteAuditId=fixtureAuditId;VARIABLES.rewriteDbOptions=dbOptions;
    include "audit-pt-write.cfm";
    saved=queryExecute("SELECT status,description_after FROM public.tb_evento_descricao_rewrites WHERE id=:id",{id=sourceParams.id},dbOptions);
    check(saved.status[1] EQ "rejected" AND isJSON(saved.description_after[1]) AND deserializeJSON(saved.description_after[1]).candidate EQ "PRIVATE_REJECTED 15 km.","Actual Portuguese audit SQL retains private rejected text");
    outcome={result={status="rejected"}};output={};rejectedEvidence=VARIABLES.rewriteRejectedEvidence;errorCode="numbers_changed";auditId=fixtureAuditId;
    include "audit-translation-write.cfm";
    saved=queryExecute("SELECT status,description_after FROM public.tb_evento_descricao_translations WHERE id=:id",{id=sourceParams.id},dbOptions);
    check(saved.status[1] EQ "rejected" AND deserializeJSON(saved.description_after[1]).candidate EQ "PRIVATE_REJECTED 15 km.","Actual translation audit SQL retains its private rejection envelope");
    cached=queryExecute("SELECT id FROM public.tb_evento_descricao_translations WHERE id=:id AND status IN ('updated','source_changed') AND btrim(COALESCE(description_after,''))<>''",{id=sourceParams.id},dbOptions);
    check(!cached.recordCount,"Saved rejection cannot satisfy the existing validated-output cache predicate");
    qPerfil=queryNew("is_admin");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",true);
    URL.audit_id=fixtureAuditId & "";URL.language="pt-BR";URL.event_id="48091";URL.pagina="1";URL.view="facts";
    include "audit-backend-runtime.cfm";
    check(!len(VARIABLES.auditError) AND VARIABLES.auditEvidence.candidate EQ "PRIVATE_REJECTED 15 km.","Global-admin reader loads the exact private audit envelope with bound IDs");
    check(arrayFind(VARIABLES.auditDifferences.distances.missing,"5 km") GT 0 AND VARIABLES.auditDifferences.distances.added[1] EQ "15 km","Private reader exposes the real persisted factual differences");
    afterEvent=queryExecute("SELECT md5(COALESCE(descricao_original,'')||COALESCE(descricao,'')||COALESCE(descricao_en,'')||COALESCE(descricao_es,'')||COALESCE(descricao_traducoes_meta::text,'')) AS fingerprint FROM public.tb_evento_corridas WHERE id_evento=48091",[],dbOptions);
    check(beforeEvent.fingerprint[1] EQ afterEvent.fingerprint[1],"Event source, published descriptions and metadata remain unchanged");
    transaction action="rollback";
}
afterRollback=queryExecute("SELECT id FROM public.tb_evento_descricao_rewrites WHERE id=:id UNION ALL SELECT id FROM public.tb_evento_descricao_translations WHERE id=:id",{id={value=fixtureAuditId,cfsqltype="cf_sql_bigint"}},dbOptions);
check(!afterRollback.recordCount,"Rollback removed all fixture audit rows without advancing sequences");
writeOutput("AUDIT_DATABASE_PASSED" & chr(10));
</cfscript>
