<cfscript>
// Reports use synthetic data only, never a live query.
VARIABLES.audienceCapacityStatus = "ready";
VARIABLES.audienceLiveUnavailable = true;
VARIABLES.audienceLiveSource = "fixture-source";
VARIABLES.audienceLiveCampaign = "fixture-campaign";
VARIABLES.audienceLiveCity = "Campinas";
VARIABLES.audienceLiveEvent = "102";
</cfscript>
<cfinclude template="capacity-data.cfm"/>
<cfinclude template="occupancy-data.cfm"/>
<cfinclude template="base-fixture.cfm"/>
