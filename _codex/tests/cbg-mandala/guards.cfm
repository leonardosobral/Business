<cfscript>
VARIABLES.businessCanManageBrasilGiganteChallenge=URL.admin EQ '1';VARIABLES.challengeMedalCsrf='fixture-token';VARIABLES.challengeMandalaError='';
qPerfil=queryNew('id','integer',[{id=17}]);
if(CGI.request_method EQ 'GET')structAppend(FORM,URL,true);
include '../desafios/includes/brasil_gigante_mandala_action.cfm';
if(!len(VARIABLES.challengeMandalaError))throw(message='Expected request rejection');
writeOutput('CBG_MANDALA_GUARDS_PASSED');
</cfscript>
