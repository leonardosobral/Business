<cfif NOT structKeyExists(VARIABLES,"template") OR VARIABLES.template NEQ "/" OR NOT structKeyExists(VARIABLES,"qEventosBase") OR NOT isQuery(VARIABLES.qEventosBase)>
    <cfheader statuscode="403"/><cfcontent type="text/plain; charset=utf-8" reset="true"/>Acesso negado.<cfabort/>
</cfif>
<cfscript>
if (structKeyExists(VARIABLES,"eventCatalogSnapshot") && !len(trim(URL.badges))) {
 VARIABLES.homeCityCatalog=VARIABLES.eventCatalogSnapshot.cities;
} else {
 VARIABLES.homeCityCatalog=new services.EventCatalogSource().buildCities(VARIABLES.qEventosBase,now());
}
VARIABLES.homeCitySearchData = [];
for (VARIABLES.homeCityRow in VARIABLES.homeCityCatalog.cities) {
    arrayAppend(VARIABLES.homeCitySearchData,{name=VARIABLES.homeCityRow.name,uf=VARIABLES.homeCityRow.uf,slug=VARIABLES.homeCityRow.slug,total=VARIABLES.homeCityRow.total});
}
VARIABLES.homeCityJson = replace(serializeJSON(VARIABLES.homeCitySearchData),"<","\u003c","all");
</cfscript>
