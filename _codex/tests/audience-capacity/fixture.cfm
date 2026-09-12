<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
VARIABLES.audienceDays = 30;
VARIABLES.audienceUf = "SC";
VARIABLES.audienceCapacityStatus = "ready";
function audienceCount(value) { return numberFormat(val(arguments.value),"__,___,___,___"); }
function audienceDate(value) { return isDate(arguments.value) ? dateTimeFormat(arguments.value,"dd/mm HH:nn","America/Sao_Paulo") : "—"; }
function audienceLabel(value) { return arguments.value EQ "home" ? "Home" : arguments.value; }
VARIABLES.audienceCapacityQuery = queryNew("row_type,audience_uf,slot_key,page_family,device_class,opportunities,renders,slot_views,first_day,last_received,days_observed,missing_days_14,baseline_days,baseline_views,low_30,base_30,total_rows",
    "varchar,varchar,varchar,varchar,varchar,bigint,bigint,bigint,varchar,timestamp,integer,integer,integer,bigint,bigint,bigint,integer");
queryAddRow(VARIABLES.audienceCapacityQuery,{
    row_type="total",audience_uf="",slot_key="",page_family="",device_class="",
    opportunities=420,renders=300,slot_views=210,first_day="2026-09-01",last_received=now(),
    days_observed=14,missing_days_14=0,baseline_days=0,baseline_views=0,total_rows=2
});
queryAddRow(VARIABLES.audienceCapacityQuery,{
    row_type="detail",audience_uf="SC",slot_key='home-<script>alert(1)</script>',page_family="home",device_class="DESKTOP",
    opportunities=420,renders=300,slot_views=210,first_day="2026-09-01",last_received=now(),
    days_observed=14,missing_days_14=0,baseline_days=14,baseline_views=210,low_30=300,base_30=450,total_rows=2
});
queryAddRow(VARIABLES.audienceCapacityQuery,{
    row_type="detail",audience_uf="--",slot_key="sidebar-new",page_family="news_detail",device_class="MOBILE",
    opportunities=9,renders=5,slot_views=2,first_day="2026-09-12",last_received=now(),
    days_observed=0,missing_days_14=14,baseline_days=0,baseline_views=0,total_rows=2
});
</cfscript>
<!doctype html><html lang="pt-br"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Capacidade — dados sintéticos de teste</title>
<link rel="stylesheet" href="/assets/css/mdb.min.css"/><link rel="stylesheet" href="/assets/css/business-ui.css"/><link rel="stylesheet" href="/assets/css/audience-dashboard.css"/></head>
<body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4 audience-page">
<h1 class="h4">Capacidade — dados sintéticos de teste</h1>
<div data-fixture="observed"><cfinclude template="portal/audiencia/capacity.cfm"/></div>
<cfset VARIABLES.audienceDays = 7/>
<cfset querySetCell(VARIABLES.audienceCapacityQuery,"baseline_days",0,2)/>
<cfset querySetCell(VARIABLES.audienceCapacityQuery,"missing_days_14",8,2)/>
<cfset querySetCell(VARIABLES.audienceCapacityQuery,"low_30",javacast("null",""),2)/>
<cfset querySetCell(VARIABLES.audienceCapacityQuery,"base_30",javacast("null",""),2)/>
<div data-fixture="short"><cfinclude template="portal/audiencia/capacity.cfm"/></div>
<cfset VARIABLES.audienceCapacityStatus = "not_commercial"/>
<div data-fixture="noncommercial"><cfinclude template="portal/audiencia/capacity.cfm"/></div>
<cfset VARIABLES.audienceCapacityStatus = "unavailable"/>
<div data-fixture="unavailable"><cfinclude template="portal/audiencia/capacity.cfm"/></div>
<cfset VARIABLES.audienceCapacityStatus = "ready"/>
<cfset queryDeleteRow(VARIABLES.audienceCapacityQuery,3)/>
<cfset queryDeleteRow(VARIABLES.audienceCapacityQuery,2)/>
<cfloop list="opportunities,renders,slot_views,total_rows" index="metric"><cfset querySetCell(VARIABLES.audienceCapacityQuery,metric,0,1)/></cfloop>
<div data-fixture="empty"><cfinclude template="portal/audiencia/capacity.cfm"/></div>
</main></body></html>
