<cfscript>
runtime=createObject("component","services" & ".UserAcquisitionMetrics");
for(days in [7,30,90,365]){
 result=runtime.load(days);
 if(arrayLen(result.rows) NEQ 365 OR result.summary.days NEQ days OR result.summary.total LT 0)throw(type="Test.Failed",message="Runtime instalado não atende ao intervalo.");
}
if(createObject("component","services" & ".geocoding.Store").settings().enabled)throw(type="Test.Failed",message="Geolocalização deve permanecer pausada.");
writeOutput("USER_ACQUISITION_ACCEPTANCE_PASSED");
</cfscript>
