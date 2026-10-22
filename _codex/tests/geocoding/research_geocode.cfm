<cfinclude template="/services/geocoding/config.cfm">
<cfscript>
// Explicit research only: five counted public-place lookups, zero event/proposal writes.
store=new services.geocoding.Store();geoClient=new services.geocoding.GeoapifyClient();policy=new services.geocoding.Policy();out=[];
lookups=[
 {id=49279,local="Rua dos Tupis, 337",text="Shopping Cidade, Rua dos Tupis, 337, Belo Horizonte, MG, BR",cidade="Belo Horizonte",estado="MG"},
 {id=49280,local="Administração do Parque Madureira",text="Administração do Parque Madureira, Rio de Janeiro, RJ, BR",cidade="Rio de Janeiro",estado="RJ"},
 {id=49278,local="Centro Administrativo Governador Virgílio Távora",text="Centro Administrativo Governador Virgílio Távora, Fortaleza, CE, BR",cidade="Fortaleza",estado="CE"},
 {id=49281,local="Buscapé Eventos",text="Buscapé Eventos, Edealina, GO, BR",cidade="Edealina",estado="GO"},
 {id=49282,local="Rua Prof Dom Albina",text="Rua Prof Dom Albina, Vila Luiza, Jataí, GO, BR",cidade="Jataí",estado="GO"}
];
for(item in lookups){
 reservation=store.reserveCall(store.settings().dailyLimit);
 if(!reservation.allowed AND reservation.reason EQ "pacing"){sleep(min(1100,reservation.waitMs+10));reservation=store.reserveCall(store.settings().dailyLimit);}
 if(!reservation.allowed)throw(type="Research.Wait",message="Provider state: " & reservation.reason);
 reply=geoClient.search({kind="specific",text=item.text,country="BR"},VARIABLES.geoConfig.apiKey);
 store.completeCall(reservation.token,reply.code,reply.ok ? 0 : reply.retryAfter);
 if(!reply.ok)throw(type="Research.Provider",message="Safe provider status: " & reply.code);
 compatible=[];for(candidate in reply.results)if(policy.sameRegion({cidade=item.cidade,estado=item.estado,pais="BR"},candidate))arrayAppend(compatible,candidate);
 arrayAppend(out,{id_evento=item.id,query=item.text,compatible_candidates=compatible});
}
writeOutput(serializeJSON({results=out,events_changed=0,proposals_changed=0,calls=arrayLen(out)}) & chr(10));writeOutput("GEO_RESEARCH_GEOCODE_PASSED");
</cfscript>
