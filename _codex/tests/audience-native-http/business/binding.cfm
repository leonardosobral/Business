<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
if (!structKeyExists(REQUEST,"audienceNativeHttpFixtureAuthorized") || !REQUEST.audienceNativeHttpFixtureAuthorized) {
    cfheader(statuscode=403); writeOutput('{"error":"fixture_guard"}'); abort;
}
bindingParams={"n"={"value"=1,"cfsqltype"="cf_sql_integer"}};
bindingCases=[
    {"label"="single", "sql"="SELECT :n AS value"},
    {"label"="repeated", "sql"="SELECT :n AS value WHERE :n = 1"},
    {"label"="cte", "sql"="WITH t AS (SELECT :n AS value) SELECT * FROM t"},
    {"label"="dash_literal", "sql"="SELECT '--' AS unknown, :n AS value"},
    {"label"="empty_literal", "sql"="SELECT '' AS unknown, :n AS value"}
];
bindingResults=[];
for(bindingCase in bindingCases) {
    bindingResult={"case"=bindingCase.label,"passed"=false};
    try {
        bindingQuery=queryExecute(bindingCase.sql,bindingParams,{"datasource"="__DATASOURCE_BUSINESS__","timeout"=3});
        bindingResult.passed=bindingQuery.value[1]==1;
    } catch(any bindingFailure) {
        bindingResult["message"]=left(bindingFailure.message & " " & bindingFailure.detail,250);
    }
    arrayAppend(bindingResults,bindingResult);
}
writeOutput(serializeJSON(bindingResults));
</cfscript>
