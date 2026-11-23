<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false">
<cfheader name="Cache-Control" value="private, no-store"><cfheader name="X-Content-Type-Options" value="nosniff"><cfheader name="Referrer-Policy" value="same-origin">
<cfscript>
teamSvc=new services.teams.Service();teamBoundary=new services.teams.Boundary();
teamUser={};teamError='';teamSuccess='';teamLoginReturn='/teams/';teamTitle='Road Runners Teams';
if(structKeyExists(REQUEST,'businessIdentity')&&structKeyExists(REQUEST.businessIdentity,'id'))teamUser=teamSvc.actor(REQUEST.businessIdentity.id);
include '../../includes/backend/business_internal_privileges.cfm';
// Teams belongs to the signed-in person, not the selected Business account.
// Stop before any global redirect, workspace lookup or mutation during simulation.
if(!structIsEmpty(teamUser)&&teamUser.is_admin&&!VARIABLES.businessInternalPrivilegesAllowed){
 if(CGI.request_method!='GET'){cfheader(statuscode=403);writeOutput('Volte ao acesso interno do Business para alterar seus Teams.');abort;}
 teamReady=true;teamTitle='Meus Teams';
 include 'header.cfm';
 writeOutput('<section class="teams-panel"><h1>Meus Teams</h1><p>Teams são vinculados ao seu login individual, não à conta empresarial selecionada.</p><p>Para acessar os Teams que você administra, encerre a simulação escolhendo Administração RunnerHub.</p><a class="teams-button" href="/selecionar-conta/">Escolher meu acesso</a> <a class="teams-button secondary" href="/">Voltar ao Business</a></section>');
 include 'footer.cfm';abort;
}
teamReady=teamSvc.ready();teamCsrf='';if(!structIsEmpty(teamUser))teamCsrf=teamBoundary.token(SESSION,teamUser.id);
teamStatusLabels={PENDING='Aguardando análise',ACTIVE='Ativo',CHANGES='Ajustes solicitados',REJECTED='Recusado',SUSPENDED='Suspenso',ARCHIVED='Encerrado'};
teamTypeLabels={TREINADOR='Treinador',ASSESSORIA='Assessoria',CLUBE='Clube',ACADEMIA='Academia',GRUPO='Grupo / running crew',EMPRESA='Empresa'};
function teamLabel(required string value){return structKeyExists(teamStatusLabels,value)?teamStatusLabels[value]:value;}
function teamPost(){if(CGI.request_method!='POST'||structIsEmpty(teamUser)||!teamBoundary.valid(SESSION,FORM,teamUser.id))throw(type='Teams.Forbidden',message='Sua sessão expirou. Recarregue a página e tente novamente.');}
</cfscript>
