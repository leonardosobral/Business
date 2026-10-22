<cfsetting showdebugoutput="false" requesttimeout="30">
<cfscript>
if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR !structKeyExists(CGI,"http_x_rewrite_inspect") OR CGI.http_x_rewrite_inspect NEQ "@@NONCE@@"){cfheader(statuscode=404);abort;}
cfheader(name="Cache-Control",value="no-store");
result={ok=true,events=[],provider_calls=0};
try {
    service=createObject("component","services.EventDescriptionRewriteService");
    for(eventId in [43854,43916,44883,48090,48091]) {
        sourceQuery=queryExecute("SELECT id_evento,descricao_original,descricao,md5(COALESCE(descricao_original,'')) AS original_hash,md5(COALESCE(descricao,'')) AS description_hash FROM public.tb_evento_corridas WHERE id_evento=:id",{id={value=eventId,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        audit=queryExecute("SELECT id,status,error_code,created_at::text AS created_at,language,source_text,COALESCE(length(description_after),0) AS output_length FROM (SELECT id,status,error_code,created_at,'pt-BR' AS language,source_text,description_after FROM public.tb_evento_descricao_rewrites WHERE id_evento=:id UNION ALL SELECT id,status,error_code,created_at,language,source_text,description_after FROM public.tb_evento_descricao_translations WHERE id_evento=:id) logs ORDER BY created_at DESC,id DESC LIMIT 3",{id={value=eventId,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
        event={id=eventId,audits=[],original_hash=sourceQuery.original_hash[1],description_hash=sourceQuery.description_hash[1],description_present=len(trim(sourceQuery.descricao[1] ?: "")) GT 0};
        for(row in audit) arrayAppend(event.audits,{id=row.id,status=row.status,language=row.language,error_code=row.error_code ?: "",created_at=row.created_at,output_length=row.output_length});
        event.original=sourceQuery.descricao_original[1] ?: "";
        event.published=sourceQuery.descricao[1] ?: "";
        try {
            event.normalized=service.normalizeSource(event.original);
            event.identity_validation=service.validateRewrite(event.normalized,event.normalized);
            service.buildRewriteRequest(event.original);
            event.source_preflight="usable";
        } catch(EventDescriptionRewrite.Validation rejectedSource) {event.source_preflight=service.validationDetails(rejectedSource);}
        arrayAppend(result.events,event);
    }
} catch(any failure) {result={ok=false,error_type=failure.type ?: ""};}
cfcontent(type="application/json; charset=utf-8",reset=true);writeOutput(serializeJSON(result));
</cfscript>
