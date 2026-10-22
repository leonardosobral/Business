<cfscript>
qPerfil=queryNew("is_admin");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",URL.testcase NEQ "denied");
if(URL.testcase EQ "delegated")REQUEST.businessAccessContext={accessMode="DELEGATED"};
if(URL.testcase EQ "filters")URL.pagina="wrong";
include "../administracao/geolocalizacao/includes/backend.cfm";
writeOutput("GEO_ACCESS_PASSED");
</cfscript>
