<cfsetting showdebugoutput="false" requesttimeout="45"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
VARIABLES.occupancyFixtureMode = "ready";
VARIABLES.occupancyFixtureCalls = 0;
VARIABLES.occupancyFixtureSchemaReady = true;
VARIABLES.occupancyFixtureCapacityFail = false;
VARIABLES.regionFixtureMode = "ready";
VARIABLES.pathsFixtureMode = "ready";
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
    if (find("/* AUDIENCE_OCCUPANCY_REGIONS */",arguments.sql)) {
        if (find("/* AUDIENCE_OCCUPANCY_BASE */",arguments.sql) OR NOT find("WITH clock AS",arguments.sql)) throw(type="RegionFixtureComposition",message="Shared inventory SQL was not composed");
        if (arguments.options.datasource NEQ "runnerhub" OR arguments.options.timeout NEQ 15 OR arguments.options.cachedwithin NEQ createTimeSpan(0,0,1,0) OR structCount(arguments.params) NEQ 7) throw(type="RegionFixtureBinding",message="Regional read options changed");
        for (var key in VARIABLES.occupancyFixtureExpected) {
            if (arguments.params[key].value NEQ VARIABLES.occupancyFixtureExpected[key]) throw(type="RegionFixtureBinding",message="Regional filter changed");
        }
        if (VARIABLES.regionFixtureMode EQ "error") throw(type="RegionFixtureReadFailure",message="Synthetic region failure");
        var data=queryNew("audience_uf,format,registered,potential,filled,empty,unclassified","varchar,varchar,integer,integer,integer,integer,integer");
        if (VARIABLES.regionFixtureMode EQ "zero") return data;
        for (var uf in ["SC","SP"]) {
            queryAddRow(data,[
                {audience_uf=uf,format="all",registered=3,potential=2,filled=1,empty=1,unclassified=0},
                {audience_uf=uf,format="ads",registered=2,potential=1,filled=0,empty=1,unclassified=0},
                {audience_uf=uf,format="banners",registered=1,potential=1,filled=1,empty=0,unclassified=0},
                {audience_uf=uf,format="other",registered=0,potential=0,filled=0,empty=0,unclassified=0}
            ]);
        }
        if (VARIABLES.regionFixtureMode EQ "duplicate") querySetCell(data,"format","ads",4);
        if (VARIABLES.regionFixtureMode EQ "missing") queryDeleteRow(data,8);
        if (VARIABLES.regionFixtureMode EQ "bad_uf") querySetCell(data,"audience_uf","INVALID",1);
        if (VARIABLES.regionFixtureMode EQ "negative") querySetCell(data,"empty",-1,1);
        if (VARIABLES.regionFixtureMode EQ "inconsistent") querySetCell(data,"filled",2,1);
        return data;
    }
    if (find("/* AUDIENCE_COVERAGE_PATHS */",arguments.sql)) {
        if (find("/* AUDIENCE_FILTER */",arguments.sql) OR NOT find("WITH regional AS",arguments.sql)) throw(type="PathsFixtureComposition",message="Shared audience filter was not composed");
        if (arguments.options.datasource NEQ "runnerhub" OR arguments.options.timeout NEQ 15 OR structCount(arguments.params) NEQ 7) throw(type="PathsFixtureBinding",message="Paths read options changed");
        for (var key in VARIABLES.occupancyFixtureExpected) {
            if (arguments.params[key].value NEQ VARIABLES.occupancyFixtureExpected[key]) throw(type="PathsFixtureBinding",message="Paths filter changed");
        }
        if (VARIABLES.pathsFixtureMode EQ "error") throw(type="PathsFixtureReadFailure",message="Synthetic paths failure");
        var data=queryNew("page_folder,pageviews,pages_with_slots,opportunities,slot_views,last_received","varchar,integer,integer,integer,integer,timestamp");
        if (VARIABLES.pathsFixtureMode EQ "zero") return data;
        queryAddRow(data,[{page_folder="/treino/",pageviews=20,pages_with_slots=2,opportunities=3,slot_views=1,last_received=now()},
            {page_folder="",pageviews=1,pages_with_slots=0,opportunities=0,slot_views=0,last_received=now()}]);
        if (VARIABLES.pathsFixtureMode EQ "duplicate") querySetCell(data,"page_folder","/treino/",2);
        if (VARIABLES.pathsFixtureMode EQ "bad_path") querySetCell(data,"page_folder","/treino/?token=private",1);
        if (VARIABLES.pathsFixtureMode EQ "negative") querySetCell(data,"pageviews",-1,1);
        if (VARIABLES.pathsFixtureMode EQ "case_sensitive") queryAddRow(data,{page_folder="/Treino/",pageviews=2,pages_with_slots=0,opportunities=0,slot_views=0,last_received=now()});
        return data;
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
occupancyCheck(structKeyExists(VARIABLES,"audienceRegionOccupancyStatus") AND structKeyExists(VARIABLES,"audienceCoveragePathsStatus"),"Backend exposes separate regional and path reports");
occupancyCheck(VARIABLES.audienceRegionOccupancyStatus EQ "ready" AND VARIABLES.audienceRegionOccupancyQuery.recordcount EQ 8,"Regional counts retain four formats per UF with shared filters");
occupancyCheck(VARIABLES.audienceCoveragePathsStatus EQ "ready" AND VARIABLES.audienceCoveragePathsQuery.recordcount EQ 2,"Coverage exposes persisted folder detail independently");
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
occupancyCheck(VARIABLES.audienceRegionOccupancyStatus EQ "unavailable" AND VARIABLES.audienceRegionOccupancyQuery.recordcount EQ 0 AND VARIABLES.audienceCoveragePathsQuery.recordcount EQ 0,"Uninstalled schema cannot reuse either new report");
VARIABLES.occupancyFixtureSchemaReady=true;
VARIABLES.occupancyFixtureMode="ready";
</cfscript>
<cfloop list="error,duplicate,missing,bad_uf,negative,inconsistent" index="regionInvalidMode">
    <cfset VARIABLES.regionFixtureMode=regionInvalidMode/>
    <cfinclude template="portal/includes/audience_backend.cfm"/>
    <cfset occupancyCheck(VARIABLES.audienceRegionOccupancyStatus EQ "unavailable" AND VARIABLES.audienceRegionOccupancyQuery.recordcount EQ 0 AND VARIABLES.audienceOccupancyStatus EQ "ready" AND VARIABLES.audienceCoveragePathsStatus EQ "ready" AND NOT VARIABLES.audienceUnavailable,"Regional failure remains isolated without stale data: " & regionInvalidMode)/>
</cfloop>
<cfset VARIABLES.regionFixtureMode="ready"/>
<cfloop list="error,duplicate,bad_path,negative" index="pathInvalidMode">
    <cfset VARIABLES.pathsFixtureMode=pathInvalidMode/>
    <cfinclude template="portal/includes/audience_backend.cfm"/>
    <cfset occupancyCheck(VARIABLES.audienceCoveragePathsStatus EQ "unavailable" AND VARIABLES.audienceCoveragePathsQuery.recordcount EQ 0 AND VARIABLES.audienceOccupancyStatus EQ "ready" AND VARIABLES.audienceRegionOccupancyStatus EQ "ready" AND NOT VARIABLES.audienceUnavailable,"Path failure remains isolated without stale data: " & pathInvalidMode)/>
</cfloop>
<cfset VARIABLES.pathsFixtureMode="zero"/>
<cfset VARIABLES.regionFixtureMode="zero"/>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(VARIABLES.audienceCoveragePathsStatus EQ "ready" AND VARIABLES.audienceRegionOccupancyStatus EQ "ready" AND VARIABLES.audienceCoveragePathsQuery.recordcount EQ 0 AND VARIABLES.audienceRegionOccupancyQuery.recordcount EQ 0,"Empty optional reports are available and not failed");
VARIABLES.pathsFixtureMode="case_sensitive";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
occupancyCheck(VARIABLES.audienceCoveragePathsStatus EQ "ready" AND VARIABLES.audienceCoveragePathsQuery.recordcount EQ 3,"Distinct case-sensitive persisted folders remain available");
writeOutput("OCCUPANCY_BACKEND_PASS_33");
</cfscript>
