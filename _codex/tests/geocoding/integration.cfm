<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.Store();policy=new services.geocoding.Policy();fixtureId=2147000001;options={datasource="runner_dba"};
function createFixture(){
    var collision=queryExecute("SELECT id_evento FROM public.tb_evento_corridas WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},options);
    check(!collision.recordCount,"Fixture refuses to replace a real event");
    queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,endereco,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado de geolocalização','São Paulo','SP','BR','Avenida Paulista, 1578',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},options);
}
check(store.isReady(),"Geocoding migration is installed without runtime DDL");
city={lat=-23.55,lon=-46.63,city="São Paulo",state_code="SP",country_code="br",result_type="city",rank={confidence=1,confidence_city_level=1}};
candidate={lat=-23.5614,lon=-46.6559,city="São Paulo",state_code="SP",country_code="br",result_type="building",housenumber="1578",street="Avenida Paulista",rank={confidence=1,confidence_city_level=1,confidence_building_level=1}};
// A nested CF transaction failure rolls back its outer transaction too.
// Each expected exception is last in its own fixture; never reuse rolled-back rows.
transaction {
    createFixture();ids=store.enqueue([fixtureId],"fixture");check(arrayLen(ids) EQ 1,"Explicit enqueue captures one current source version");
    work=store.claim(ids[1]);check(!structIsEmpty(work) AND work.status EQ "running","Lease claim is explicit and tokenized");
    captured=deserializeJSON(work.source_snapshot & "");check(arrayFindNoCase(captured.nulls,"coordenadas") GT 0,"Snapshot preserves database NULL independently of CF null support");
    store.finish(work,{status="city_suggestion",candidate=city,candidates=[city],reasons=["city_only"]},"fixture");
    check(!len(policy.text(store.event(fixtureId),"coordenadas")),"City suggestion never fills public event coordinates");
    oldRevision=store.detail(ids[1]).proposal_revision & "";
    ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);
    store.finish(work,{status="city_suggestion",candidate=city,candidates=[city],reasons=["city_only"]},"fixture");
    declined=false;try{store.review(ids[1],"reject","fixture","Conferência de teste",oldRevision);}catch(Geocoding.Validation e){declined=true;}
    check(declined,"Requeue invalidates an old review form even with unchanged source");
    transaction action="rollback";
}
transaction {
    createFixture();ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);
    queryExecute("UPDATE public.tb_evento_geocoding SET attempts=3,lease_until=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=work.id,cfsqltype="cf_sql_bigint"}},options);
    check(structIsEmpty(store.claim(work.id)) AND store.detail(work.id).status EQ "errors_exhausted","An expired third lease is finalized instead of stuck running");
    ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);
    queryExecute("UPDATE public.tb_evento_corridas SET endereco='Outro local' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},options);
    result=store.finish(work,{status="auto_applied",candidate=candidate,candidates=[candidate],reasons=["specific_location_confirmed"]},"fixture");
    check(result.status EQ "conflict" AND !len(policy.text(store.event(fixtureId),"coordenadas")),"Edited source invalidates application atomically");
    queryExecute("UPDATE public.tb_evento_corridas SET endereco='Avenida Paulista, 1578' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},options);
    ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);
    result=store.finish(work,{status="auto_applied",candidate=candidate,candidates=[candidate],reasons=["specific_location_confirmed"]},"fixture");
    check(result.status EQ "auto_applied" AND store.event(fixtureId).coordenadas EQ "-23.5614000,-46.6559000","Specific result applies coordinates in lat/lng order");
    audit=queryExecute("SELECT id FROM public.tb_evento_geocoding_audit WHERE work_id=:id AND action='auto_applied'",{id={value=work.id,cfsqltype="cf_sql_bigint"}},options);
    check(audit.recordCount EQ 1,"Coordinate publication has an atomic permanent audit");
    transaction action="rollback";
}
transaction {
    createFixture();ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);stale=duplicate(work);stale.lease_token="not-the-lease";
    rejected=false;try{store.finish(stale,{status="city_suggestion",candidate=city},"fixture");}catch(Geocoding.Validation e){rejected=true;}
    check(rejected,"A stale worker cannot finalize another lease");transaction action="rollback";
}
transaction {
    createFixture();ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);store.finish(work,{status="city_suggestion",candidate=city,candidates=[city],reasons=["city_only"]},"fixture");
    declined=false;try{store.review(ids[1],"approve","fixture","Conferência de teste",store.detail(ids[1]).proposal_revision & "");}catch(Geocoding.Validation e){declined=true;}
    check(declined,"City suggestion cannot be promoted by manual approval");transaction action="rollback";
}
transaction {
    createFixture();ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);
    store.finish(work,{status="needs_review",candidate=candidate,candidates=[candidate],reasons=["low_confidence"]},"fixture");
    result=store.review(ids[1],"approve","fixture","",store.detail(ids[1]).proposal_revision & "");
    check(result.status EQ "approved" AND store.event(fixtureId).coordenadas EQ "-23.5614000,-46.6559000","Current specific proposal can be approved with the displayed revision");
    audit=queryExecute("SELECT actor,details::text AS details FROM public.tb_evento_geocoding_audit WHERE work_id=:id AND action='approved'",{id={value=work.id,cfsqltype="cf_sql_bigint"}},options);
    check(audit.recordCount EQ 1 AND audit.actor[1] EQ "fixture" AND len(deserializeJSON(audit.details[1]).reviewReason) GT 0,"Review without typed reason still records author, default action and timestamp");
    transaction action="rollback";
}
transaction {
    createFixture();ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);
    store.finish(work,{status="city_suggestion",candidate=city,reasons=["city_only"],sourceRetry=true},"fixture");
    queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=work.id,cfsqltype="cf_sql_bigint"}},options);
    check(!structIsEmpty(store.claim(work.id)),"A transient source failure can retry automatically while retaining a municipal suggestion");
    transaction action="rollback";
}
transaction {
    createFixture();ids=store.enqueue([fixtureId],"fixture");work=store.claim(ids[1]);
    store.finish(work,{status="needs_review",candidate=candidate,reasons=["low_confidence"]},"fixture");
    check(store.page("revisao",1,fixtureId & "","todos","todos","").recordCount EQ 1,"Current pipeline specific candidates are available in quick review");
    queryExecute("UPDATE public.tb_evento_geocoding SET source_snapshot=source_snapshot-'VERSION'-'version' WHERE id=:id",{id={value=work.id,cfsqltype="cf_sql_bigint"}},options);
    check(store.page("revisao",1,fixtureId & "","todos","todos","").recordCount EQ 0,"Legacy proposals awaiting automatic research are not presented as mandatory human reviews");
    transaction action="rollback";
}
transaction {
    queryExecute("UPDATE public.tb_geocoding_cache SET last_call_at=NULL,cooldown_until=NULL,provider_lease_token=NULL,provider_lease_until=NULL WHERE cache_key='__control__'",[],options);
    queryExecute("INSERT INTO public.tb_geocoding_usage_daily(usage_date,provider,calls) VALUES((clock_timestamp() AT TIME ZONE 'UTC')::date,'geoapify',0) ON CONFLICT(usage_date,provider) DO UPDATE SET calls=0",[],options);
    reservation=store.reserveCall(2);check(reservation.allowed,"First provider call reserves quota before HTTP");
    queryExecute("UPDATE public.tb_geocoding_cache SET last_call_at=NULL WHERE cache_key='__control__'",[],options);
    concurrent=store.reserveCall(2);check(!concurrent.allowed AND concurrent.reason EQ "provider_busy","Another call cannot run while the first HTTP lease is in flight");
    store.completeCall(reservation.token,"rate_limited",600);
    check(!store.completeCall(reservation.token,"ok",0,"old-fingerprint") AND store.providerState().cooldown GT 590,"A late response cannot clear a current provider cooldown");
    queryExecute("UPDATE public.tb_geocoding_cache SET cooldown_until=NULL,last_call_at=NULL WHERE cache_key='__control__'",[],options);
    check(!store.reserveCall(1).allowed,"Exhausted daily quota prevents another call");
    lookup={kind="city",text="TEST " & createUUID(),country="BR"};store.cachePut(lookup,[city]);check(store.cacheGet(lookup).found,"Cache reuses a municipal lookup without provider consumption");
    transaction action="rollback";
}
check(!store.event(fixtureId).exists,"Rollback leaves no fixture event");writeOutput("GEO_INTEGRATION_PASSED");
</cfscript>
