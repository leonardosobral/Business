<cfscript>
VARIABLES.businessEffectiveIsAdmin=true;
VARIABLES.fixtureCalls=[];
VARIABLES.fixtureFailure="";
VARIABLES.fixtureValue=9;
VARIABLES.fixtureResults=[];
function homeFixtureQuery(required string statement,required struct params,required struct options) {
    var source="users";
    if (find("FROM audience.events",arguments.statement)) source="audience";
    else if (find("FROM ads.daily_metrics",arguments.statement)) source="ads";
    else if (find("FROM public.tb_contas",arguments.statement)) source="accounts";
    arrayAppend(VARIABLES.fixtureCalls,{source=source,days=arguments.params.days.value,type=arguments.params.days.cfsqltype,timeout=arguments.options.timeout,cache=arguments.options.cachedWithin,datasource=arguments.options.datasource});
    if (source==VARIABLES.fixtureFailure) throw(type="Database",message="Synthetic unavailable source: credentials must not leak");
    var columns=[];
    for (var key in VARIABLES.businessHomeMetrics[source]) if (key!="loaded") arrayAppend(columns,key);
    var result=queryNew(arrayToList(columns));queryAddRow(result,1);
    for (var column in columns) querySetCell(result,column,findNoCase("comparison_ready",column) ? true : VARIABLES.fixtureValue,1);
    return result;
}
for (VARIABLES.fixturePeriod in ["30","7","30junk","30.0","-1","",[30]]) {
    URL.periodo=VARIABLES.fixturePeriod;
    include "includes/backend/business_home_metrics.cfm";
    arrayAppend(VARIABLES.fixtureResults,{input=VARIABLES.fixturePeriod,metrics=duplicate(VARIABLES.businessHomeMetrics)});
}
structDelete(URL,"periodo");
include "includes/backend/business_home_metrics.cfm";
arrayAppend(VARIABLES.fixtureResults,{input="missing",metrics=duplicate(VARIABLES.businessHomeMetrics)});
URL.periodo="30";
for (VARIABLES.fixtureFailure in ["audience","ads","accounts","users"]) {
    include "includes/backend/business_home_metrics.cfm";
    arrayAppend(VARIABLES.fixtureResults,{failed=VARIABLES.fixtureFailure,metrics=duplicate(VARIABLES.businessHomeMetrics)});
}
VARIABLES.fixtureFailure="";VARIABLES.fixtureValue=0;
include "includes/backend/business_home_metrics.cfm";
arrayAppend(VARIABLES.fixtureResults,{zero=true,metrics=duplicate(VARIABLES.businessHomeMetrics)});
writeOutput("HOME_METRICS_RESULT=" & serializeJSON({results=VARIABLES.fixtureResults,calls=VARIABLES.fixtureCalls}));
</cfscript>
