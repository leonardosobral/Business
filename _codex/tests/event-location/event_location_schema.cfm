<cfscript>
db={datasource="runner_dba"};
cols=queryExecute("SELECT column_name,data_type,character_maximum_length,is_nullable,column_default FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' AND column_name IN('pais','estado','cidade','cod_cidade','endereco','coordenadas') ORDER BY column_name",[],db);
event=queryExecute("SELECT id_evento,pais,estado,cidade,cod_cidade FROM public.tb_evento_corridas WHERE id_evento=38202",[],db);
writeOutput(serializeJSON({columns=cols,event=event}));writeOutput("GEO_EVENT_LOCATION_SCHEMA_PASSED");
</cfscript>
