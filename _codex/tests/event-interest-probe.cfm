<cfinclude template="../../includes/backend/backend_login.cfm">
<cfinclude template="../../includes/backend/require_admin.cfm">
<cfscript>
started=getTickCount();
params={days={value=7,cfsqltype="cf_sql_integer"},include_internal={value=false,cfsqltype="cf_sql_bit"},term={value="",cfsqltype="cf_sql_varchar"},uf={value="",cfsqltype="cf_sql_varchar"},stage={value="all",cfsqltype="cf_sql_varchar"},event_id={value="",cfsqltype="cf_sql_varchar"},offset={value=0,cfsqltype="cf_sql_integer"}};
statement=fileRead(expandPath('../audiencia/queries/event_interest.sql'),'UTF-8');
try {
 result=queryExecute(statement,params,{datasource='runnerhub',timeout=8});
 report=deserializeJSON(result.report[1]);
 output={elapsed_ms=getTickCount()-started,summary=report.summary,meta=report.meta};
}catch(any e){output={elapsed_ms=getTickCount()-started,type=e.type,message=e.message,detail=e.detail};}
</cfscript>
<cfcontent type="text/html; charset=utf-8" reset="true"><!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>Diagnóstico administrativo</title></head><body><pre><cfoutput>#encodeForHTML(serializeJSON(output))#</cfoutput></pre></body></html>
