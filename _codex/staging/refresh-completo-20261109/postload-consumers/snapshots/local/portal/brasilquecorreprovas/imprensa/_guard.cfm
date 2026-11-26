<cfinclude template="_context.cfm"/>
<cfscript>
if(!structKeyExists(VARIABLES,'pressJson'))pressJson=false;
if(CGI.REQUEST_METHOD!='GET'){cfheader(statuscode=405);abort;}
pressReadAllowed=false;
try{pressReadAllowed=structKeyExists(VARIABLES,'pressScope')&&pressService.canRead(pressScope);}catch(any denied){pressReadAllowed=false;}
if(!pressReadAllowed){
 if(pressJson){cfheader(statuscode=403);cfcontent(type='application/json; charset=utf-8',reset=true);writeOutput('{"error":"Acesse a área de imprensa com a conta do seu convite."}');abort;}
 cflocation(url='/brasilquecorreprovas/imprensa/',addtoken=false,statuscode=302);abort;
}
</cfscript>
