<cfscript>
q=queryExecute("SELECT current_user AS role,inet_server_addr()::text AS host,current_database() AS db,has_schema_privilege(current_user,'public','CREATE') AS may_create",[],{datasource="runner_dba"});
for(row in q)writeOutput(serializeJSON(row) & chr(10));
try {
 dss=createObject("java","coldfusion.server.ServiceFactory").getDataSourceService();
 sources=dss.getDatasources();
 writeOutput("Source metadata keys: " & structKeyList(sources["runner_dba"]) & chr(10));
 for(method in dss.getClass().getMethods())if(reFindNoCase("(connection|datasource)",method.getName()))writeOutput(method.getName() & chr(10));
}catch(any capability){writeOutput("Administrative connection probe: " & capability.type & ": " & left(capability.message,500) & chr(10));}
writeOutput("GEO_CAPABILITY_PASSED");
</cfscript>
