<!--- Global access is checked from the verified identity, before the shared Business shell. --->
<cfheader name="Cache-Control" value="private, no-store">
<cfif NOT structKeyExists(REQUEST,'businessIdentity') OR NOT structKeyExists(REQUEST.businessIdentity,'id')>
    <cfif CGI.request_method EQ 'GET'><cflocation url="/teams/" statuscode="303" addtoken="false"></cfif>
    <cfheader statuscode="403"><cfoutput><p>Entre com uma conta de administrador global.</p></cfoutput><cfabort>
</cfif>
<cfif (structKeyExists(REQUEST,'businessAccessContext') AND structKeyExists(REQUEST.businessAccessContext,'accessMode') AND REQUEST.businessAccessContext.accessMode NEQ 'DIRECT')
    OR (structKeyExists(SESSION,'businessAccessSelection') AND isStruct(SESSION.businessAccessSelection) AND structKeyExists(SESSION.businessAccessSelection,'accessMode') AND SESSION.businessAccessSelection.accessMode NEQ 'DIRECT')
    OR (structKeyExists(SESSION,'businessSimulatedAccountId') AND val(SESSION.businessSimulatedAccountId) GT 0)>
    <cfheader statuscode="403"><cfoutput><p>Volte ao acesso interno do Business para gerenciar Teams. <a href="/selecionar-conta/">Escolher acesso</a></p></cfoutput><cfabort>
</cfif>
<cftry><cfinclude template="../../../teams/includes/start.cfm"><cfcatch type="Teams.Forbidden"><cfheader statuscode="403"><cfoutput><p>Acesso restrito à administração global.</p></cfoutput><cfabort></cfcatch></cftry>
<cfif structIsEmpty(teamUser) OR NOT teamUser.is_admin><cfheader statuscode="403"><cfoutput><p>Acesso restrito à administração global.</p></cfoutput><cfabort></cfif>
<cfif NOT listFind('GET,POST',CGI.request_method)><cfheader statuscode="405"><cfheader name="Allow" value="GET, POST"><cfabort></cfif>
<cfscript>
teamCreate=false;teamId=0;teamTab='cadastro';teamSearch='';teamPage=1;teamStatus='';teamType='';teamUf='';teamWorkspace={};teamGlobal={};teamPostOperation='';teamCanWrite=true;teamAthleteSearch='';teamAthletePage=1;teamExistingSearch='';teamCandidateRows=queryNew('id,name,email');
teamGlobalTabs={cadastro='Cadastro',responsavel='Responsável técnico',revisao='Revisão',equipe='Equipe administrativa',atletas='Atletas',historico='Histórico'};
teamGlobalTabOrder=['cadastro','responsavel','revisao','equipe','atletas','historico'];
function teamAuditLabel(required string event) {
 var labels={TEAM_REGISTER='Cadastro solicitado',TEAM_REGISTER_MANUAL='Cadastro manual pela administração',TEAM_UPDATE='Cadastro atualizado',TEAM_APPROVE='Cadastro aprovado / reativado',TEAM_CHANGES='Ajustes solicitados',TEAM_REJECT='Cadastro recusado',TEAM_SUSPEND='Team suspenso',TEAM_ARCHIVE='Team encerrado',ATHLETE_JOIN='Atleta vinculado',ATHLETE_LEAVE='Atleta saiu do Team',ATHLETE_REMOVE='Vínculo de atleta removido',ATHLETE_UNBLOCK='Retorno de atleta liberado',ADMIN_ROLE_CHANGE='Papel administrativo alterado',ADMIN_ADD='Usuário existente adicionado à gestão',ADMIN_INVITE='Convite administrativo criado',ADMIN_ACCEPT='Convite administrativo aceito',ADMIN_INVITE_REVOKE='Convite administrativo revogado',ADMIN_REMOVE='Acesso administrativo removido'};
 return structKeyExists(labels,event)?labels[event]:'Atividade registrada';
}
function teamAdminUrl(numeric selectedTeam=0,string selectedTab='cadastro',numeric selectedPage=0) {
 var params='q=' & urlEncodedFormat(teamSearch) & '&status=' & urlEncodedFormat(teamStatus) & '&type=' & urlEncodedFormat(teamType) & '&uf=' & urlEncodedFormat(teamUf) & '&page=' & (selectedPage>0?selectedPage:teamPage);
 params&='&aq=' & urlEncodedFormat(teamAthleteSearch) & '&apage=' & teamAthletePage;
 if(len(teamExistingSearch))params&='&user_busca=' & urlEncodedFormat(teamExistingSearch);
 if(selectedTeam>0)params&='&team=' & selectedTeam & '&tab=' & urlEncodedFormat(selectedTab);
 return '/administracao/teams/?' & params;
}
try {
 teamCreate=teamBoundary.number(URL,'novo')==1;teamId=teamBoundary.number(URL,'team');if(teamCreate&&teamId>0)throw(type='Teams.Validation',message='Abra um novo cadastro sem selecionar um Team existente.');teamTab=teamBoundary.text(URL,'tab','cadastro');if(!structKeyExists(teamGlobalTabs,teamTab))teamTab='cadastro';
 teamSearch=left(teamBoundary.text(URL,'q'),100);teamPage=max(1,teamBoundary.number(URL,'page',1));teamStatus=uCase(teamBoundary.text(URL,'status'));teamType=uCase(teamBoundary.text(URL,'type'));teamUf=uCase(teamBoundary.text(URL,'uf'));teamAthleteSearch=left(teamBoundary.text(URL,'aq'),100);teamAthletePage=max(1,teamBoundary.number(URL,'apage',1));teamExistingSearch=left(teamBoundary.text(URL,'user_busca'),100);
 if(!teamReady)throw(type='Teams.Validation',message='A estrutura de Teams não está disponível.');
 // The service validates all filter enums and checks the actor again.
 teamGlobal=teamSvc.globalTeams(teamUser.id,teamSearch,teamStatus,teamType,teamUf,teamPage);teamPage=teamGlobal.page;
 if(teamId>0){teamWorkspace=teamSvc.workspace(teamUser.id,teamId,teamAthleteSearch,teamAthletePage);tt=teamWorkspace.team;tw=teamWorkspace;}
 if(teamId>0&&teamTab=='equipe')teamCandidateRows=teamSvc.adminCandidates(teamUser.id,teamId,teamExistingSearch);
 if(CGI.request_method=='POST'){
  teamPostOperation=teamBoundary.text(FORM,'operation');teamPost();
  if(teamPostOperation=='create'){
   teamCreate=true;
   if(teamId>0||teamBoundary.number(FORM,'team')>0)throw(type='Teams.Validation',message='Abra um novo cadastro sem selecionar um Team existente.');
   createdTeamId=teamSvc.registerGlobal(teamUser.id,FORM);
   location(url=teamAdminUrl(createdTeamId,'revisao') & '&created=1',statuscode=303,addtoken=false);
  }
  if(teamId<=0||teamBoundary.number(FORM,'team')!=teamId)throw(type='Teams.Validation',message='Selecione novamente o Team antes de registrar a alteração.');
  switch(teamPostOperation){
   case 'review':
    teamTab='revisao';
    if(teamBoundary.text(FORM,'decision')=='APPROVE'&&teamBoundary.text(FORM,'cref_active')!='yes')throw(type='Teams.Validation',message='Confirme a consulta do CREF ativo.');
    teamSvc.review(teamUser.id,teamId,teamBoundary.text(FORM,'decision'),teamBoundary.number(FORM,'version'),teamBoundary.text(FORM,'note'),teamBoundary.text(FORM,'evidence'));break;
   case 'save':teamTab='cadastro';teamSvc.updateTeam(teamUser.id,teamId,FORM,teamBoundary.number(FORM,'version'));break;
   case 'change_admin_role':teamTab='equipe';teamSvc.changeAdminRole(teamUser.id,teamId,teamBoundary.number(FORM,'member'),teamBoundary.text(FORM,'role'),teamBoundary.text(FORM,'expected_role'));break;
   case 'add_existing_admin':teamTab='equipe';teamSvc.addExistingAdmin(teamUser.id,teamId,teamBoundary.number(FORM,'member'),teamBoundary.text(FORM,'role'));break;
   case 'invite_admin':teamTab='equipe';teamSvc.inviteAdmin(teamUser.id,teamId,teamBoundary.text(FORM,'email'),teamBoundary.text(FORM,'role'));break;
   case 'remove_admin':teamTab='equipe';teamSvc.removeAdmin(teamUser.id,teamId,teamBoundary.number(FORM,'member'));break;
   case 'revoke_invite':teamTab='equipe';teamSvc.revokeInvite(teamUser.id,teamId,teamBoundary.number(FORM,'invite'));break;
   case 'remove_athlete':teamTab='atletas';teamSvc.removeAthlete(teamUser.id,teamId,teamBoundary.number(FORM,'athlete'));break;
   case 'unblock_athlete':teamTab='atletas';teamSvc.unblockAthlete(teamUser.id,teamId,teamBoundary.number(FORM,'athlete'));break;
   default:throw(type='Teams.Validation',message='Operação inválida.');
  }
  location(url=teamAdminUrl(teamId,teamTab) & '&saved=1',statuscode=303,addtoken=false);
 }
 if(structKeyExists(URL,'created'))teamSuccess='Team cadastrado. Confira o CREF na aba Revisão para liberar as adesões.';
 if(structKeyExists(URL,'saved'))teamSuccess='Alteração registrada.';
}catch(Teams.Validation failed){teamError=failed.message;cfheader(statuscode=400);}
catch(Teams.Forbidden failed){teamError=failed.message;cfheader(statuscode=403);}
catch(any failed){writeLog(file='teams',type='error',text='global_workspace_failed type=' & failed.type);teamError='Não foi possível carregar ou atualizar os Teams. Recarregue a página.';cfheader(statuscode=500);}
</cfscript>
