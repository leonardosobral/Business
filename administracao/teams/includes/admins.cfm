<cfscript>
teamMembersAction=teamAdminUrl(teamId,'equipe');teamMemberBase='/administracao/teams/';
teamMemberFilters={team=teamId,tab='equipe',q=teamSearch,status=teamStatus,type=teamType,uf=teamUf,page=teamPage,aq=teamAthleteSearch,apage=teamAthletePage};
</cfscript>
<cfinclude template="../../../teams/includes/admins.cfm">
