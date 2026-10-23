<cfscript>
// Read-only metadata and aggregate audit. No prompts, credentials or personal data.
transaction {
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 auditOptions={datasource="runner_dba",timeout=20};
 auditSchema=queryExecute("SELECT table_schema,table_name,column_name,data_type FROM information_schema.columns WHERE (table_schema='public' AND (table_name IN('tb_vicky_execucao','tb_vicky_config','tb_ai_mail_usage','tb_ai_mail_config','tb_evento_descricao_rewrites','tb_evento_descricao_translations','tb_geocoding_cache','tb_cron_jobs','tb_cron_job_runs') OR table_name LIKE '%helpdesk%')) OR (table_schema='news' AND (table_name LIKE '%summary%' OR table_name LIKE '%usage%')) ORDER BY table_schema,table_name,ordinal_position",[],auditOptions);
 auditTables={};for(auditCol in auditSchema){auditName=auditCol.table_schema & "." & auditCol.table_name;if(!structKeyExists(auditTables,auditName))auditTables[auditName]=[];arrayAppend(auditTables[auditName],auditCol.column_name & ":" & auditCol.data_type);}
 writeOutput(serializeJSON({utc=queryExecute("SELECT current_timestamp::text AS utc",[],auditOptions).utc,tables=auditTables}));
}
writeOutput("GEO_OPENAI_USAGE_SCHEMA_PASSED");
</cfscript>
