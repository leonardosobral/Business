<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false">
<cfheader name="Cache-Control" value="private, no-store"><cfheader name="X-Content-Type-Options" value="nosniff"><cfheader name="Referrer-Policy" value="same-origin">
<cfscript>
teamSvc=new services.teams.Service();teamBoundary=new services.teams.Boundary();
teamUser={};teamError='';teamSuccess='';teamLoginReturn='/teams/';teamTitle='Road Runners Teams';
if(structKeyExists(REQUEST,'businessIdentity')&&structKeyExists(REQUEST.businessIdentity,'id'))teamUser=teamSvc.actor(REQUEST.businessIdentity.id);
teamReady=teamSvc.ready();teamCsrf='';if(!structIsEmpty(teamUser))teamCsrf=teamBoundary.token(SESSION,teamUser.id);
teamStatusLabels={PENDING='Aguardando análise',ACTIVE='Ativo',CHANGES='Ajustes solicitados',REJECTED='Recusado',SUSPENDED='Suspenso',ARCHIVED='Encerrado'};
teamTypeLabels={TREINADOR='Treinador',ASSESSORIA='Assessoria',CLUBE='Clube',ACADEMIA='Academia',GRUPO='Grupo / running crew',EMPRESA='Empresa'};
function teamLabel(required string value){return structKeyExists(teamStatusLabels,value)?teamStatusLabels[value]:value;}
function teamPost(){if(CGI.request_method!='POST'||structIsEmpty(teamUser)||!teamBoundary.valid(SESSION,FORM,teamUser.id))throw(type='Teams.Forbidden',message='Sua sessão expirou. Recarregue a página e tente novamente.');}
</cfscript>
