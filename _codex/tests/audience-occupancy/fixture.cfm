<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
VARIABLES.audienceOccupancyStatus = "ready";
function audienceCount(value) { return numberFormat(val(arguments.value),"__,___,___,___"); }
function audienceRate(numerator,denominator) { return val(arguments.denominator) GT 0 ? numberFormat(100 * val(arguments.numerator)/val(arguments.denominator),"0.0") & "%" : "—"; }
audStats = {visitors=1106,sessions=1551,engaged_sessions=869,active_pages=5338,pageviews=5336,opportunities=5923,slot_views=1719,ad_views=1740,ad_renders=2526};
VARIABLES.audienceOccupancyQuery = queryNew("format,registered,potential,filled,empty,unclassified","varchar,bigint,bigint,bigint,bigint,bigint",[
    {format="all",registered=200,potential=100,filled=60,empty=30,unclassified=10},
    {format="ads",registered=150,potential=70,filled=50,empty=15,unclassified=5},
    {format="banners",registered=40,potential=20,filled=10,empty=10,unclassified=0},
    {format="other",registered=10,potential=10,filled=0,empty=5,unclassified=5}
]);
</cfscript>
<!doctype html><html lang="pt-br"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Ocupação — dados sintéticos de teste</title>
<link rel="stylesheet" href="/assets/css/mdb.min.css"/><link rel="stylesheet" href="/assets/css/business-ui.css"/><link rel="stylesheet" href="/assets/css/audience-dashboard.css"/></head>
<body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4 audience-page">
<h1 class="h4">Ocupação — dados sintéticos de teste</h1>
<div data-fixture="observed"><cfinclude template="portal/audiencia/occupancy.cfm"/></div>
<cfscript>
audStats.slot_views = 0;
audStats.ad_views = 0;
audStats.ad_renders = 0;
VARIABLES.audienceOccupancyQuery = queryNew("format,registered,potential,filled,empty,unclassified","varchar,bigint,bigint,bigint,bigint,bigint",[
    {format="all",registered=200,potential=200,filled=0,empty=200,unclassified=0},
    {format="ads",registered=120,potential=120,filled=0,empty=120,unclassified=0},
    {format="banners",registered=80,potential=80,filled=0,empty=80,unclassified=0},
    {format="other",registered=0,potential=0,filled=0,empty=0,unclassified=0}
]);
</cfscript>
<div data-fixture="applicable-empty-no-views"><cfinclude template="portal/audiencia/occupancy.cfm"/></div>
<cfscript>
audStats.ad_renders = 40;
VARIABLES.audienceOccupancyQuery = queryNew("format,registered,potential,filled,empty,unclassified","varchar,bigint,bigint,bigint,bigint,bigint",[
    {format="all",registered=200,potential=200,filled=40,empty=160,unclassified=0},
    {format="ads",registered=120,potential=120,filled=40,empty=80,unclassified=0},
    {format="banners",registered=80,potential=80,filled=0,empty=80,unclassified=0},
    {format="other",registered=0,potential=0,filled=0,empty=0,unclassified=0}
]);
</cfscript>
<div data-fixture="served-no-views"><cfinclude template="portal/audiencia/occupancy.cfm"/></div>
<cfscript>
audStats.ad_renders = 0;
VARIABLES.audienceOccupancyQuery = queryNew("format,registered,potential,filled,empty,unclassified","varchar,bigint,bigint,bigint,bigint,bigint",[
    {format="all",registered=200,potential=200,filled=0,empty=190,unclassified=10},
    {format="ads",registered=120,potential=120,filled=0,empty=115,unclassified=5},
    {format="banners",registered=80,potential=80,filled=0,empty=75,unclassified=5},
    {format="other",registered=0,potential=0,filled=0,empty=0,unclassified=0}
]);
</cfscript>
<div data-fixture="unknown-state"><cfinclude template="portal/audiencia/occupancy.cfm"/></div>
<cfloop from="1" to="#VARIABLES.audienceOccupancyQuery.recordcount#" index="rowIndex"><cfloop list="registered,potential,filled,empty,unclassified" index="metric"><cfset querySetCell(VARIABLES.audienceOccupancyQuery,metric,0,rowIndex)/></cfloop></cfloop>
<div data-fixture="empty"><cfinclude template="portal/audiencia/occupancy.cfm"/></div>
<cfset querySetCell(VARIABLES.audienceOccupancyQuery,"registered",10,1)/><cfset querySetCell(VARIABLES.audienceOccupancyQuery,"registered",10,2)/>
<div data-fixture="excluded"><cfinclude template="portal/audiencia/occupancy.cfm"/></div>
<cfset VARIABLES.audienceOccupancyStatus = "unavailable"/>
<div data-fixture="unavailable"><cfinclude template="portal/audiencia/occupancy.cfm"/></div>
</main></body></html>
