<cfinclude template="../_context.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
if(!studyActor){cfheader(statuscode=401);writeOutput('{"error":"Entre no Business para acessar o estudo."}');abort;}
if(structKeyExists(URL,'ano') && (!isSimpleValue(URL.ano) || URL.ano!='2026')) {cfheader(statuscode=400);writeOutput('{"error":"Esta prévia corresponde a janeiro–setembro de 2026."}');abort;}
try {result=studyService.read(studyActor,'previa-2026-q3');writeOutput(result.payload_json);}
catch(any denied){cfheader(statuscode=403);writeOutput('{"error":"Acesso indisponível. Confira seu convite na biblioteca."}');}
</cfscript>
