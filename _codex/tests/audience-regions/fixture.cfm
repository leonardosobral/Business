<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
VARIABLES.businessEffectiveIsAdmin = true;
function audienceCount(value) { return numberFormat(val(arguments.value), "__,___,___,___"); }
function audienceRate(numerator,denominator) { return val(arguments.denominator) GT 0 ? numberFormat(100*val(arguments.numerator)/val(arguments.denominator),"0.0") & "%" : "—"; }
function audienceDate(value) { return isDate(arguments.value) ? dateTimeFormat(arguments.value,"dd/mm HH:nn","America/Sao_Paulo") : "—"; }
VARIABLES.audienceQueries = {"regions"=queryNew("audience_uf,active_pages,visitors,opportunities,slot_views","varchar,integer,integer,integer,integer")};
queryAddRow(VARIABLES.audienceQueries.regions,{"audience_uf"="SC","active_pages"=8,"visitors"=5,"opportunities"=400,"slot_views"=2});
</cfscript>
<cfinclude template="region-data.cfm"/>
<cfset fixtureOriginal = serializeJSON(VARIABLES.audienceRegionOccupancyQuery)/>
<div data-fixture="observed">
    <cfif fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "portal/audiencia/regions.cfm")><cfinclude template="portal/audiencia/regions.cfm"/></cfif>
    <cfif fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "portal/audiencia/coverage_paths.cfm")><cfinclude template="portal/audiencia/coverage_paths.cfm"/></cfif>
</div>
<cfif fixtureOriginal NEQ serializeJSON(VARIABLES.audienceRegionOccupancyQuery)><cfthrow message="Rendering must not mutate regional query"/></cfif>
<cfset VARIABLES.audienceRegionOccupancyStatus = "unavailable"/>
<cfset VARIABLES.audienceCoveragePathsStatus = "unavailable"/>
<div data-fixture="unavailable">
    <cfif fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "portal/audiencia/regions.cfm")><cfinclude template="portal/audiencia/regions.cfm"/></cfif>
    <cfif fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "portal/audiencia/coverage_paths.cfm")><cfinclude template="portal/audiencia/coverage_paths.cfm"/></cfif>
</div>
<cfset VARIABLES.audienceRegionOccupancyStatus = "ready"/>
<cfset VARIABLES.audienceCoveragePathsStatus = "ready"/>
<cfset VARIABLES.audienceRegionOccupancyQuery = queryNew("audience_uf,format,registered,potential,filled,empty,unclassified")/>
<cfset VARIABLES.audienceCoveragePathsQuery = queryNew("page_folder,pageviews,pages_with_slots,opportunities,slot_views,last_received")/>
<div data-fixture="empty">
    <cfif fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "portal/audiencia/regions.cfm")><cfinclude template="portal/audiencia/regions.cfm"/></cfif>
    <cfif fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "portal/audiencia/coverage_paths.cfm")><cfinclude template="portal/audiencia/coverage_paths.cfm"/></cfif>
</div>
