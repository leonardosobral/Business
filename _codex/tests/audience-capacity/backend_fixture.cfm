<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
VARIABLES.capacityFixtureFail = false;
VARIABLES.capacityFixtureCalls = 0;
// Replace only the external database operation. All real backend parsing,
// authorization, query loading and error handling remain under test.
function capacityFixtureQuery(required string sql, struct params={}, struct options={}) {
    if (findNoCase("to_regclass",arguments.sql)) {
        return queryNew("ready,retention_ready","boolean,boolean",[{ready=true,retention_ready=false}]);
    }
    if (find("/* AUDIENCE_CAPACITY */",arguments.sql)) {
        VARIABLES.capacityFixtureCalls++;
        if (arguments.options.datasource NEQ "runnerhub") throw(message="Capacity changed the existing read DSN");
        if (arguments.params.days.cfsqltype NEQ "cf_sql_integer" OR arguments.params.days.value NEQ 30) throw(message="Invalid typed period binding");
        if (arguments.params.uf.value NEQ "SC" OR arguments.params.region_dimension.value NEQ "market") throw(message="Commercial scope not bound");
        if (arguments.params.include_internal.value) throw(message="Internal data included in commercial capacity");
        if (VARIABLES.capacityFixtureFail) throw(type="CapacityFixtureReadFailure",message="Synthetic capacity-only query failure");
    }
    return queryNew("first_event,last_received,pageviews","timestamp,timestamp,integer",[{first_event=now(),last_received=now(),pageviews=42}]);
}
function capacityCheck(required boolean condition, required string label) {
    if (!arguments.condition) throw(type="CapacityFixtureAssertion",message=arguments.label);
    writeOutput("PASS " & arguments.label & chr(10));
}
URL.dias="30";URL.uf="SC";URL.regiao="market";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
capacityCheck(structKeyExists(VARIABLES,"audienceCapacityStatus"),"Backend exposes independent capacity state");
capacityCheck(VARIABLES.audienceCapacityStatus EQ "ready" AND VARIABLES.capacityFixtureCalls EQ 1,"Successful capacity read receives typed commercial filters");
capacityCheck(NOT VARIABLES.audienceUnavailable AND VARIABLES.audienceSummary.pageviews EQ 42,"Existing totals survive successful extension");
VARIABLES.capacityFixtureFail = true;
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
capacityCheck(VARIABLES.audienceCapacityStatus EQ "unavailable","Capacity failure has explicit unavailable status");
capacityCheck(NOT VARIABLES.audienceUnavailable AND VARIABLES.audienceSummary.pageviews EQ 42 AND structCount(VARIABLES.audienceQueries) EQ 7,"Capacity failure preserves all seven existing reports");
VARIABLES.capacityFixtureCalls = 0;
URL.regiao="visitor";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
capacityCheck(VARIABLES.audienceCapacityStatus EQ "not_commercial" AND VARIABLES.capacityFixtureCalls EQ 0,"Visitor UF cannot trigger commercial projection");
URL.regiao="market";URL.internos="1";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
capacityCheck(VARIABLES.audienceCapacityStatus EQ "not_commercial" AND VARIABLES.capacityFixtureCalls EQ 0,"Internal traffic cannot trigger commercial projection");
structDelete(URL,"internos");URL.ambiente="dev";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
capacityCheck(VARIABLES.audienceCapacityStatus EQ "not_commercial" AND VARIABLES.capacityFixtureCalls EQ 0,"Nonproduction cannot trigger commercial projection");
writeOutput("CAPACITY_BACKEND_PASS_8");
</cfscript>
