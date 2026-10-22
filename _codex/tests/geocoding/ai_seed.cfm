<cfscript>
fixtureSeed=new services.geocoding.LocationStore();fixtureCount=arrayLen(fixtureSeed.selectEvents(1));
if(fixtureCount LT 0 OR fixtureCount GT 1)throw(type="Test.Failed",message="Unbounded automatic selection");
fixturePage=fixtureSeed.page("fila",1,"","todos","proximos","");if(fixturePage.recordCount GT 21)throw(type="Test.Failed",message="Unbounded event page");
writeOutput("GEO_AI_SEED_PASSED");
</cfscript>
