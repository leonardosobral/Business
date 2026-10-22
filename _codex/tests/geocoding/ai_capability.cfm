<cfscript>
// Read-only capability/credential presence check. Never returns a key or calls APIs.
options={datasource="runner_dba"};columns=[];
for(row in queryExecute("SELECT column_name,data_type,COALESCE(character_maximum_length,0) AS max_length FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' ORDER BY ordinal_position",[],options))arrayAppend(columns,{name=row.column_name,type=row.data_type,max_length=row.max_length});
model=queryExecute("SELECT model FROM public.tb_vicky_config WHERE id_config=1",[],options);
configured=structKeyExists(application,"vickyKnowledge") AND structKeyExists(application.vickyKnowledge,"configured") AND application.vickyKnowledge.configured;
writeOutput(serializeJSON({openai_existing_integration_configured=configured,model=model.recordCount ? model.model[1] : "",event_columns=columns}) & chr(10));
writeOutput("GEO_AI_CAPABILITY_PASSED");
</cfscript>
