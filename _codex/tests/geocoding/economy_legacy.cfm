<cfscript>
// Read only: known consumption before this rollout must not reset the monthly cap.
limits=new services.geocoding.AIBudget().status();
if(!structKeyExists(limits,"legacy_month_usd") OR limits.legacy_month_usd LTE 30 OR limits.month_usd LT limits.legacy_month_usd)throw(type="EconomyTest",message="Incluir consumo conhecido anterior no teto mensal, sem duplicá-lo.");
transaction{
 captured=new services.geocoding.AIBudget().initialize();
 if(abs(captured.month_usd-limits.month_usd) GT 0.00001 OR !captured.blocked)throw(type="EconomyTest",message="Congelar histórico sem duplicar consumo e manter bloqueio mensal.");
 transaction action="rollback";
}
writeOutput("GEO_ECONOMY_LEGACY_PASSED");
</cfscript>
