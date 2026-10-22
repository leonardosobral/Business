<cfscript>
// This gate runs before any audit query, including direct detail URLs.
VARIABLES.descriptionAuditCanAdmin=isDefined("qPerfil") AND qPerfil.recordCount
    AND !isNull(qPerfil.is_admin) AND (isBoolean(qPerfil.is_admin)
        ? qPerfil.is_admin : listFindNoCase("true,t,1,yes,sim",trim(qPerfil.is_admin & "")) GT 0);
cfheader(name="Cache-Control",value="private, no-store");
cfheader(name="X-Robots-Tag",value="noindex, nofollow");
if(!VARIABLES.descriptionAuditCanAdmin) {cfheader(statuscode=403);writeOutput("Acesso restrito a administradores globais.");abort;}
if(CGI.request_method NEQ "GET") {cfheader(statuscode=405);cfheader(name="Allow",value="GET");abort;}
param name="URL.audit_id" default="";
param name="URL.event_id" default="";
param name="URL.language" default="";
param name="URL.pagina" default="1";
param name="URL.view" default="facts";
if((len(URL.audit_id) AND !reFind("^[1-9][0-9]{0,14}$",URL.audit_id))
    OR (len(URL.event_id) AND !reFind("^[1-9][0-9]{0,9}$",URL.event_id))
    OR (len(URL.event_id) AND val(URL.event_id) GT 2147483647)
    OR !reFind("^[1-9][0-9]{0,3}$",URL.pagina) OR (len(URL.language) AND !listFind("pt-BR,en,es",URL.language))
    OR !listFind("facts,texts",URL.view)) {
    cfheader(statuscode=400);writeOutput("Filtros de auditoria inválidos.");abort;
}
VARIABLES.auditId=val(URL.audit_id);VARIABLES.auditEventId=val(URL.event_id);VARIABLES.auditPage=val(URL.pagina);
VARIABLES.auditLanguage=URL.language;VARIABLES.auditView=URL.view;
VARIABLES.auditRows=queryNew("id,id_evento,language,occurred_at,error_code,has_output,nome_evento");
VARIABLES.auditSelected={};VARIABLES.auditEvidence={};VARIABLES.auditDifferences={};VARIABLES.auditHasNext=false;VARIABLES.auditError="";
VARIABLES.auditService=new services.EventDescriptionRewriteService();
try {
    VARIABLES.auditRows=queryExecute("SELECT logs.*,COALESCE(evt.nome_evento,'Evento') AS nome_evento FROM (
        SELECT id,id_evento,'pt-BR' AS language,to_char(created_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS occurred_at,
            created_at,error_code,btrim(COALESCE(description_after,'')) <> '' AS has_output
        FROM public.tb_evento_descricao_rewrites WHERE status='rejected' AND (:event_id=0 OR id_evento=:event_id)
          AND (:language='' OR :language='pt-BR')
        UNION ALL
        SELECT id,id_evento,language,to_char(created_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS occurred_at,
            created_at,error_code,btrim(COALESCE(description_after,'')) <> '' AS has_output
        FROM public.tb_evento_descricao_translations WHERE status='rejected' AND (:event_id=0 OR id_evento=:event_id)
          AND (:language='' OR language=:language)
        ) logs JOIN public.tb_evento_corridas evt ON evt.id_evento=logs.id_evento
        ORDER BY logs.created_at DESC,logs.id DESC,logs.language LIMIT 21 OFFSET :offset",{
            event_id={value=VARIABLES.auditEventId,cfsqltype="cf_sql_integer"},
            language={value=VARIABLES.auditLanguage,cfsqltype="cf_sql_varchar"},
            offset={value=(VARIABLES.auditPage-1)*20,cfsqltype="cf_sql_integer"}
        },{datasource="runner_dba"});
    VARIABLES.auditHasNext=VARIABLES.auditRows.recordCount GT 20;
    if(VARIABLES.auditId GT 0) {
        if(!len(VARIABLES.auditLanguage)) VARIABLES.auditLanguage="pt-BR";
        // Only this server-owned whitelist selects the table; values remain bound parameters.
        VARIABLES.auditTable=VARIABLES.auditLanguage EQ "pt-BR" ? "tb_evento_descricao_rewrites" : "tb_evento_descricao_translations";
        VARIABLES.auditRecord=queryExecute("SELECT audit.*,COALESCE(evt.nome_evento,'Evento') AS nome_evento,
            to_char(audit.created_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS occurred_at
            FROM public." & VARIABLES.auditTable & " audit JOIN public.tb_evento_corridas evt ON evt.id_evento=audit.id_evento
            WHERE audit.id=:audit_id AND audit.status='rejected'" & (VARIABLES.auditLanguage EQ "pt-BR" ? "" : " AND audit.language=:language"),{
                audit_id={value=VARIABLES.auditId,cfsqltype="cf_sql_bigint"},language={value=VARIABLES.auditLanguage,cfsqltype="cf_sql_varchar"}
            },{datasource="runner_dba"});
        if(!VARIABLES.auditRecord.recordCount) {cfheader(statuscode=404);VARIABLES.auditError="Registro de rejeição não encontrado.";}
        else {
            for(VARIABLES.auditRecordRow in VARIABLES.auditRecord) VARIABLES.auditSelected=VARIABLES.auditRecordRow;
            VARIABLES.auditSelected.language=VARIABLES.auditLanguage;
            VARIABLES.auditRaw=isNull(VARIABLES.auditSelected.description_after) ? "" : VARIABLES.auditSelected.description_after;
            if(len(VARIABLES.auditRaw) LTE 1500000 AND isJSON(VARIABLES.auditRaw)) {
                VARIABLES.auditParsed=deserializeJSON(VARIABLES.auditRaw);
                if(isStruct(VARIABLES.auditParsed) AND structKeyExists(VARIABLES.auditParsed,"version") AND VARIABLES.auditParsed.version EQ 1
                    AND structKeyExists(VARIABLES.auditParsed,"source") AND isSimpleValue(VARIABLES.auditParsed.source) AND len(VARIABLES.auditParsed.source) LTE 20000
                    AND structKeyExists(VARIABLES.auditParsed,"candidate") AND isSimpleValue(VARIABLES.auditParsed.candidate) AND len(VARIABLES.auditParsed.candidate) LTE 200000) {
                    VARIABLES.auditEvidence=VARIABLES.auditParsed;
                    VARIABLES.auditEvidence.reviewReason=structKeyExists(VARIABLES.auditParsed,"reviewReason") AND isSimpleValue(VARIABLES.auditParsed.reviewReason)
                        ? left(VARIABLES.auditParsed.reviewReason,2000) : "";
                    VARIABLES.auditDifferences=VARIABLES.auditService.compareAuditFacts(VARIABLES.auditEvidence.source,VARIABLES.auditEvidence.candidate,VARIABLES.auditLanguage);
                }
            }
        }
    }
} catch(any unavailableAudit) {
    cfheader(statuscode=503);VARIABLES.auditError="Não foi possível consultar a auditoria agora. Nenhum conteúdo foi alterado.";
}
</cfscript>
