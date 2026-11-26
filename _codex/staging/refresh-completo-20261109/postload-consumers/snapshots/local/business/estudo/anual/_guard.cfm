<cfinclude template="../../estudos/_context.cfm"/>
<cfscript>
if(listLast(getBaseTemplatePath(),'/')=='_guard.cfm'){cfheader(statuscode=404);abort;}
if(CGI.request_method!='GET'){cfheader(statuscode=405);abort;}
for(key in URL)if(key!='ano' || !isSimpleValue(URL[key]) || URL[key]!='2026'){cfheader(statuscode=400);abort;}
if(!studyActor){cfheader(statuscode=401);writeOutput('Entre com sua conta de administrador no Business.');abort;}
try{annualIdentity=studyService.dashboard(studyActor).user;}catch(any e){cfheader(statuscode=403);abort;}
if(!annualIdentity.is_admin){cfheader(statuscode=403);writeOutput('Rascunho anual disponível somente para administradores.');abort;}
</cfscript>