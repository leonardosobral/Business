<cfscript>
// Installed runtime only. No calls to either provider; do not add to generic all.
include "/services/geocoding/config.cfm";
runtimeStore=createObject("component","services" & ".geocoding.LocationStore");
if(runtimeStore.settings().enabled)throw(type="EconomyTest",message="O módulo deve continuar pausado.");
if(VARIABLES.geoConfig.aiModel NEQ "gpt-6.1-sol")throw(type="EconomyTest",message="Sol não foi publicado.");
runtimeBudget=createObject("component","services" & ".geocoding.AIBudget");
runtimeLimits=runtimeBudget.initialize();
runtimeWorker=createObject("component","services" & ".geocoding.LocationWorker").init(VARIABLES.geoConfig);
runtimeSummary=runtimeWorker.run(1);
if(runtimeSummary.status NEQ "disabled" OR runtimeSummary.ai_calls NEQ 0 OR runtimeSummary.calls NEQ 0 OR runtimeLimits.day_limit NEQ 2 OR runtimeLimits.month_limit NEQ 30 OR runtimeStore.settings().enabled)throw(type="EconomyTest",message="Pausa ou teto incorreto no runtime instalado.");
writeOutput(serializeJSON({paused=true,model=VARIABLES.geoConfig.aiModel,daily_limit=runtimeLimits.day_limit,monthly_limit=runtimeLimits.month_limit,known_month_upper_usd=runtimeLimits.month_usd,pending_usd=runtimeLimits.pending_usd,provider_calls=runtimeSummary.ai_calls+runtimeSummary.calls}));
writeOutput("GEO_ECONOMY_ACCEPTANCE_PASSED");
</cfscript>
