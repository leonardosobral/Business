<cfscript>
fixtureSchema=queryExecute("SELECT data_type,is_nullable,column_default FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' AND column_name='localizacoes'",[],{datasource="runner_dba"});
if(fixtureSchema.recordCount NEQ 1 OR fixtureSchema.data_type[1] NEQ "jsonb" OR fixtureSchema.is_nullable[1] NEQ "NO")throw(type="Test.Failed",message="Location migration not ready");
writeOutput("GEO_AI_SCHEMA_PASSED");
</cfscript>
