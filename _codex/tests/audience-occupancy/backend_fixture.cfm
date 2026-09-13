<cfsetting showdebugoutput="false" requesttimeout="45"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
VARIABLES.occupancyFixtureMode = "ready";
VARIABLES.occupancyFixtureCalls = 0;
VARIABLES.occupancyFixtureSchemaReady = true;
VARIABLES.occupancyFixtureCapacityFail = false;
VARIABLES.occupancyFixtureExpected = {days=30,environment="prod",include_internal=false,region_dimension="market",uf="SC",page_family="event",device_class="MOBILE"};
// Only the external database call is simulated. Production URL normalization,
// authorization, file loading, result validation and error handling stay real.
function occupancyFixtureQuery(required string sql, struct params={}, struct options={}) {
    if (findNoCase("to_regclass",arguments.sql)) {
        return queryNew("ready,retention_ready","boolean,boolean",[{ready=VARIABLES.occupancyFixtureSchemaReady,retention_ready=false}]);
    }
    if (find("/* AUDIENCE_CAPACITY */",arguments.sql) AND VARIABLES.occupancyFixtureCapacityFail) {
        throw(type="CapacityFixtureReadFailure",message="Synthetic capacity-only query failure");
    }
    if (find("/* AUDIENCE_OCCUPANCY */",arguments.sql)) {
        VARIABLES.occupancyFixtureCalls++;
        if (arguments.options.datasource NEQ "runnerhub" OR arguments.options.timeout NEQ 15 OR arguments.options.cachedwithin NEQ createTimeSpan(0,0,1,0)) {
            throw(type="OccupancyFixtureBindingFailure",message="Occupancy changed read connection, timeout or cache");
        }
        var types = {days="cf_sql_integer",environment="cf_sql_varchar",include_internal="cf_sql_bit",region_dimension="cf_sql_varchar",uf="cf_sql_varchar",page_family="cf_sql_varchar",device_class="cf_sql_varchar"};
        if (structCount(arguments.params) NEQ 7) throw(type="OccupancyFixtureBindingFailure",message="Occupancy requires exactly seven audience filters");
        for (var key in types) {
            if (arguments.params[key].cfsqltype NEQ types[key] OR arguments.params[key].value NEQ VARIABLES.occupancyFixtureExpected[key]) {
                throw(type="OccupancyFixtureBindingFailure",message="Occupancy filter or SQL type changed: " & key);
            }
        }
        if (VARIABLES.occupancyFixtureMode EQ "error") throw(type="OccupancyFixtureReadFailure",message="Synthetic occupancy-only query failure; do not expose raw query details");
        if (VARIABLES.occupancyFixtureMode EQ "missing_column") return queryNew("format,registered,potential,filled,empty","varchar,integer,integer,integer,integer",[
            {format="all",registered=120,potential=100,filled=60,empty=30},
            {format="ads",registered=80,potential=70,filled=50,empty=15},
            {format="banners",registered=40,potential=30,filled=10,empty=15},
            {format="other",registered=0,potential=0,filled=0,empty=0}
        ]);
        var data = queryNew("format,registered,potential,filled,empty,unclassified","varchar,integer,integer,integer,integer,integer",[
            {format="all",registered=120,potential=100,filled=60,empty=30,unclassified=10},
            {format="ads",registered=80,potential=70,filled=50,empty=15,unclassified=5},
            {format="banners",registered=40,potential=30,filled=10,empty=15,unclassified=5},
            {format="other",registered=0,potential=0,filled=0,empty=0,unclassified=0}
        ]);
        if (VARIABLES.occupancyFixtureMode EQ "incomplete") queryDeleteRow(data,4);
        if (VARIABLES.occupancyFixtureMode EQ "duplicate") querySetCell(data,"format","ads",4);
        if (VARIABLES.occupancyFixtureMode EQ "inconsistent") querySetCell(data,"empty",100,1);
        if (VARIABLES.occupancyFixtureMode EQ "negative") querySetCell(data,"unclassified",-1,4);
        if (VARIABLES.occupancyFixtureMode EQ "zero") {
            for (var metric in ["registered","potential","filled","empty","unclassified"]) {
                for (var row=1;row LTE 4;row++) querySetCell(data,metric,0,row);
            }
        }
        return data;
    }
    return queryNew("first_event,last_received,pageviews","timestamp,timestamp,integer",[{first_event=now(),last_received=now(),pageviews=42}]);
}
function occupancyCheck(required boolean condition, required string label) {
    if (!arguments.condition) throw(type="OccupancyFixtureAssertion",message=arguments.label);
    writeOutput("PASS " & arguments.label & chr(10));
}
URL.dias="30";URL.ambiente="prod";URL.uf="SC";URL.regiao="market";URL.pagina="event";URL.dispositivo="MOBILE";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(structKeyExists(VARIABLES,"audienceOccupancyStatus"),"Backend exposes independent occupancy state");
occupancyCheck(VARIABLES.audienceOccupancyStatus EQ "ready" AND VARIABLES.occupancyFixtureCalls EQ 1,"Successful occupancy read receives all typed filters and bounded read options");
occupancyCheck(VARIABLES.audienceOccupancyQuery.recordcount EQ 4 AND VARIABLES.audienceOccupancyQuery.potential[1] EQ 100,"Backend exposes complete occupancy query");
occupancyCheck(NOT VARIABLES.audienceUnavailable AND VARIABLES.audienceSummary.pageviews EQ 42 AND structCount(VARIABLES.audienceQueries) EQ 7,"Occupancy preserves all existing reports and totals");
VARIABLES.occupancyFixtureMode = "error";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(VARIABLES.audienceOccupancyStatus EQ "unavailable","Occupancy query failure has explicit unavailable state");
occupancyCheck(NOT VARIABLES.audienceUnavailable AND VARIABLES.audienceSummary.pageviews EQ 42 AND structCount(VARIABLES.audienceQueries) EQ 7 AND VARIABLES.audienceCapacityStatus EQ "ready","Occupancy failure preserves seven reports, summary and capacity");
occupancyCheck(VARIABLES.audienceOccupancyQuery.recordcount EQ 0,"Failed refresh cannot expose stale occupancy counts");
VARIABLES.occupancyFixtureMode = "ready";
VARIABLES.occupancyFixtureCapacityFail = true;
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(VARIABLES.audienceOccupancyStatus EQ "ready" AND VARIABLES.audienceCapacityStatus EQ "unavailable","Capacity failure does not hide occupancy");
VARIABLES.occupancyFixtureCapacityFail = false;
URL.ambiente="dev";URL.internos="1";URL.regiao="visitor";
VARIABLES.occupancyFixtureExpected.environment="dev";VARIABLES.occupancyFixtureExpected.include_internal=true;VARIABLES.occupancyFixtureExpected.region_dimension="visitor";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(VARIABLES.audienceOccupancyStatus EQ "ready" AND VARIABLES.audienceCapacityStatus EQ "not_commercial","Occupancy allows nonproduction, internal traffic and visitor-region diagnostics");
VARIABLES.occupancyFixtureMode="zero";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(VARIABLES.audienceOccupancyStatus EQ "ready" AND VARIABLES.audienceOccupancyQuery.potential[1] EQ 0,"A complete zero result is available, distinct from a query failure");
</cfscript>
<cfloop list="incomplete,duplicate,missing_column,inconsistent,negative" index="occupancyInvalidMode">
    <cfset VARIABLES.occupancyFixtureMode=occupancyInvalidMode/>
    <cfinclude template="portal/includes/audience_backend.cfm"/>
    <cfset occupancyCheck(VARIABLES.audienceOccupancyStatus EQ "unavailable" AND VARIABLES.audienceOccupancyQuery.recordcount EQ 0 AND NOT VARIABLES.audienceUnavailable AND structCount(VARIABLES.audienceQueries) EQ 7,"Malformed occupancy result stays unavailable: " & occupancyInvalidMode)/>
</cfloop>
<cfscript>
VARIABLES.occupancyFixtureSchemaReady=false;
VARIABLES.occupancyFixtureCalls=0;
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(VARIABLES.audienceOccupancyStatus EQ "unavailable" AND VARIABLES.occupancyFixtureCalls EQ 0,"Uninstalled audience schema leaves occupancy unavailable without reading it");
occupancyCheck(VARIABLES.audienceOccupancyQuery.recordcount EQ 0,"Uninstalled schema cannot reuse earlier occupancy values");
writeOutput("OCCUPANCY_BACKEND_PASS_17");
</cfscript>
