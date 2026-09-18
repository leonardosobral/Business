<cfscript>
// The test session is an internal admin; permission/scoping cases are covered
// through the real service in result-import-groups.cfm. No action is posted.
function businessHasPermission(required string code) { return true; }
transaction {
    queryExecute("UPDATE tb_resultados_importacoes SET status_processamento='processado' WHERE id_resultado_importacao=8");
    queryExecute("UPDATE tb_resultados_importacoes SET status_processamento='falhou' WHERE id_resultado_importacao=9");
    queueCases=[
        {params={},wantStatus='pendente',wantIds='6,7'},
        {params={status=''},wantStatus='',wantIds='6,7,8,9'},
        {params={status='falhou'},wantStatus='falhou',wantIds='9'},
        {params={grupo=record.event_group},wantStatus='',wantIds='1,2,3,4,5,6'}
    ];
    for(queueCase in queueCases) {
        structClear(URL);structAppend(URL,queueCase.params);URL.periodo='0';structClear(FORM);
        savecontent variable='backendWhitespace' { include 'administracao/importacoes-resultados/includes/backend.cfm'; }
        check(resultImportSchemaReady AND !len(resultImportError),'Queue backend executes against the real service: ' & resultImportError);
        check(resultImportStatus EQ queueCase.wantStatus,'Default status must be pending, but explicit All and event history must remain available. Got: ' & resultImportStatus);
        check(listSort(valueList(qResultImports.id_resultado_importacao),'numeric') EQ queueCase.wantIds,'Default/explicit filters return only the expected real submissions');
        if(!len(queueCase.wantStatus)) {
            nextQueueUrl=resultImportQueueUrl({pagina=2});
            check(reFind('[?&]status=(&|$)',nextQueueUrl)>0,'All must remain explicit across pagination/refresh instead of reverting to pending');
        }
    }
    transaction action='rollback';
}
writeOutput('PASS: pending default, explicit All, failures, full history and persistent filter URLs. ');
</cfscript>
