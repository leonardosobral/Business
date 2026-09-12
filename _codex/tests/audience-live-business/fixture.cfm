<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
VARIABLES.audienceDays = 7;
VARIABLES.audienceDimension = "market";
VARIABLES.audienceUf = "SC";
VARIABLES.audienceFamily = "";
VARIABLES.audienceEnvironment = "prod";
VARIABLES.audienceDevice = "MOBILE";
VARIABLES.audienceIncludeInternal = false;
VARIABLES.audienceLiveSource = "google";
VARIABLES.audienceLiveCampaign = 'live_<script>alert(1)</script>';
VARIABLES.audienceLiveCity = "";
VARIABLES.audienceLiveEvent = "";
VARIABLES.audienceLiveUnavailable = false;
function audienceCount(value) { return numberFormat(val(arguments.value),"__,___,___,___"); }
function audienceDate(value) { return isDate(arguments.value) ? dateTimeFormat(arguments.value,"dd/mm HH:nn","America/Sao_Paulo") : "—"; }
function audienceRate(numerator,denominator) { return val(arguments.denominator) GT 0 ? numberFormat(100*val(arguments.numerator)/val(arguments.denominator),"0.0") & "%" : "—"; }
VARIABLES.audienceLiveQuery = queryNew("row_type,source,medium,campaign,content_id,event_name,event_tag,event_city,event_uf,pageviews,sessions,qualified_sessions,event_sessions,outbound_sessions,matched_outbound_sessions,unmatched_outbound_sessions,first_outbound,last_outbound,last_received",
    "varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,bigint,bigint,bigint,bigint,bigint,bigint,bigint,timestamp,timestamp,timestamp");
for (fixtureType in ["campaign","event"]) {
    queryAddRow(VARIABLES.audienceLiveQuery,{
        row_type=fixtureType,source="google",medium="cpc",campaign=VARIABLES.audienceLiveCampaign,
        content_id=fixtureType EQ "event" ? "101" : "",event_name="Live <teste>",event_tag="live-teste",
        event_city="Jaraguá do Sul",event_uf="SC",pageviews=fixtureType EQ "event" ? 3 : 7,
        sessions=fixtureType EQ "event" ? 2 : 4,qualified_sessions=2,event_sessions=2,
        outbound_sessions=2,matched_outbound_sessions=1,unmatched_outbound_sessions=1,
        first_outbound=now(),last_outbound=now(),last_received=now()
    });
}
</cfscript>
<!doctype html><html lang="pt-br"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Fixture sintética LIVE</title>
<link rel="stylesheet" href="/assets/css/mdb.min.css"/><link rel="stylesheet" href="/assets/css/business-ui.css"/><link rel="stylesheet" href="/assets/css/audience-dashboard.css"/></head>
<body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4 audience-page">
<div data-fixture="observed"><cfinclude template="portal/audiencia/live_journey.cfm"/></div>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"outbound_sessions",0,1)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"matched_outbound_sessions",0,1)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"unmatched_outbound_sessions",0,1)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"first_outbound",javacast("null",""),1)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"sessions",0,2)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"event_sessions",0,2)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"matched_outbound_sessions",0,2)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"event_city","",2)/>
<cfset querySetCell(VARIABLES.audienceLiveQuery,"event_tag","javascript:alert(1)",2)/>
<div data-fixture="historical"><cfinclude template="portal/audiencia/live_journey.cfm"/></div>
<cfset VARIABLES.audienceLiveUnavailable = true/>
<div data-fixture="unavailable"><cfinclude template="portal/audiencia/live_journey.cfm"/></div>
</main></body></html>
