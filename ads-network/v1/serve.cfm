<cfinclude template="../includes/request.cfm"/>
<cfscript>
networkParams.device={value=reFindNoCase('mobile|android|iphone|ipad|ipod',networkUa) ? 'MOBILE' : 'DESKTOP',cfsqltype='cf_sql_varchar'};
networkResult=queryExecute('SELECT CAST(ads.publisher_deliver(:site,:spot,:origin,:device) AS text) AS payload',networkParams,{datasource='runnerhub',timeout=8});
writeOutput(networkResult.payload[1]);
</cfscript>
