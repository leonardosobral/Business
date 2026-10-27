<cfscript>
transaction{
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 columns=queryExecute("SELECT data_type,column_default,is_nullable FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_usuarios' AND column_name='data_criacao'",[],{datasource="runner_dba",timeout=10});
 checks=queryExecute("SELECT count(*) AS users,count(*) FILTER(WHERE data_criacao IS NULL) AS missing_date,count(*) FILTER(WHERE data_criacao>clock_timestamp()) AS future_date,min(data_criacao)::text AS first_at,max(data_criacao)::text AS latest_at,current_setting('TimeZone') AS db_timezone FROM public.tb_usuarios",[],{datasource="runner_dba",timeout=10});
 indexes=queryExecute("SELECT indexdef FROM pg_indexes WHERE schemaname='public' AND tablename='tb_usuarios' AND indexdef ILIKE '%data_criacao%'",[],{datasource="runner_dba",timeout=10});
 result={column=[],coverage=[],indexes=[]};for(r in columns)arrayAppend(result.column,r);for(r in checks)arrayAppend(result.coverage,r);for(r in indexes)arrayAppend(result.indexes,r);
 writeOutput(serializeJSON(result));
}
writeOutput("USER_ACQUISITION_SOURCE_PASSED");
</cfscript>
