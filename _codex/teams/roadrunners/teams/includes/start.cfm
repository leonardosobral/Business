<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false">
<cfset VARIABLES.template='/teams/'>
<cfinclude template="../../includes/estrutura/variaveis.cfm">
<cfheader name="Cache-Control" value="private, no-store"><cfheader name="X-Content-Type-Options" value="nosniff"><cfheader name="Referrer-Policy" value="same-origin">
<cfscript>
teamSvc=new services.teams.Service();teamBoundary=new services.teams.Boundary();teamIdentity=new services.teams.Identity();
teamUser={};teamError='';teamSuccess='';teamTitle='Road Runners Teams';teamReady=teamSvc.ready();teamCsrf='';
teamProof={};teamProofLock='RoadRunners.ComparadorIdentity.v1.' & hash(getApplicationMetadata().name);
if(listFirst(CGI.http_host,':')=='roadrunners.run'){
 lock name=teamProofLock type='exclusive' timeout=5 {
  if(!structKeyExists(APPLICATION,'comparadorIdentityStateV1'))APPLICATION.comparadorIdentityStateV1={};
  teamProtocol=createObject('component','services.ComparadorIdentityProtocol').init(APPLICATION.comparadorIdentityStateV1);
  teamProof=teamIdentity.browser(teamProtocol,createObject('component','services.ComparadorIdentityAccounts').init('runner_dba'),COOKIE);
 }
}
if(!structIsEmpty(teamProof)){teamUser=teamSvc.actor(teamProof.id);teamCsrf=teamBoundary.token(SESSION,teamUser.id);if(teamReady && CGI.request_method=='GET')teamSvc.recordReturn(teamUser.id);}
teamTypeLabels={TREINADOR='Treinador',ASSESSORIA='Assessoria',CLUBE='Clube',ACADEMIA='Academia',GRUPO='Grupo / running crew',EMPRESA='Empresa'};
function teamPost(){if(CGI.request_method!='POST'||structIsEmpty(teamUser)||!teamBoundary.valid(SESSION,FORM,teamUser.id))throw(type='Teams.Forbidden',message='Sua sessão expirou. Recarregue a página e tente novamente.');}
</cfscript>
