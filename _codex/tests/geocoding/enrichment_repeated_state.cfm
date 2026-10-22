<cfscript>
include "enrichment_integration.cfm";
transaction {
 makeEvent();queryExecute("UPDATE public.tb_evento_corridas SET endereco='Avenida das Flores, 123' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixturePrevious=fixtureStore.enqueue([fixtureId],"fixture");
 queryExecute("UPDATE public.tb_evento_corridas SET endereco=NULL WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWork=fixtureStore.claim(fixtureIds[1]);fixtureUpdate=fixtureStore.publishEnrichment(fixtureWork,makeProgress(fixtureWork),"fixture");
 check(fixtureStore.event(fixtureId).endereco EQ "Avenida das Flores, 123","Returning to an earlier native input state does not collide with the unique work key");
 check(fixtureStore.detail(fixturePrevious[1]).id EQ fixturePrevious[1],"The previous work and its history are retained");
 transaction action="rollback";
}
writeOutput("GEO_ENRICHMENT_REPEATED_STATE_PASSED");
</cfscript>
