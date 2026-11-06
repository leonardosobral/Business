<cfscript>
writeOutput(serializeJSON(queryExecute("SELECT table_name,column_name,data_type FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('desafios','desafios_obs') ORDER BY table_name,ordinal_position",{},{datasource='runner_dba'})));
writeOutput(serializeJSON(queryExecute("SELECT count(DISTINCT id_usuario) AS delivered FROM desafios_obs WHERE produto='circuitobrasilgigante' AND obs='mandala_entregue'",{},{datasource='runner_dba'})));
writeOutput('CBG_MANDALA_SOURCE_PASSED');
</cfscript>
