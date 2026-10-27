<!--- Returning Teams-only users stay in their own tenant domain. No business permissions are granted. --->
<cfif CGI.request_method EQ 'GET' AND isDefined('REQUEST.businessIdentity.id') AND NOT structKeyExists(URL,'action') AND NOT structKeyExists(URL,'logout') AND (NOT structKeyExists(REQUEST,'businessAccessContext') OR REQUEST.businessAccessContext.accessMode NEQ 'DELEGATED')>
<cftry>
<cfset homeTeams=new services.teams.Service()>
<cfif homeTeams.ready()>
<cfset homeTeamsActor=homeTeams.actor(REQUEST.businessIdentity.id)>
<cfif NOT homeTeamsActor.is_admin AND NOT homeTeamsActor.is_dev>
<cfquery name="qTeamsBusinessAccess" datasource="runner_dba">SELECT 1 FROM public.tb_conta_usuarios cu JOIN public.tb_contas t ON t.id_conta=cu.id_conta WHERE cu.id_usuario=<cfqueryparam value="#homeTeamsActor.id#" cfsqltype="cf_sql_integer"> AND cu.status='ATIVO' AND t.status IN ('ATIVA','PENDENTE') LIMIT 1</cfquery>
<cfif NOT qTeamsBusinessAccess.recordCount AND homeTeams.myTeams(homeTeamsActor.id).recordCount><cflocation url="/teams/" addtoken="false"></cfif>
</cfif></cfif><cfcatch type="any"><cflog file="teams" type="error" text="home_return_unavailable #cfcatch.type#"></cfcatch></cftry>
</cfif>
