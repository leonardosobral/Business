<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.Store();options={datasource="runner_dba"};
// Real database accounting, always rolled back; no HTTP/provider calls.
transaction {
 settings=store.settings();accepted=true;
 try{store.saveSettings(settings.enabled,3000,settings.validatedFingerprint);}catch(Geocoding.Validation invalidLimit){accepted=false;}
 check(accepted AND store.settings().dailyLimit EQ 3000,"The existing settings path can persist a 3,000-call daily budget");
 transaction action="rollback";
}
transaction {
 queryExecute("UPDATE public.tb_geocoding_cache SET response=jsonb_set(response,'{dailyLimit}','3000'::jsonb),last_call_at=NULL,cooldown_until=NULL,provider_lease_token=NULL,provider_lease_until=NULL WHERE cache_key='__control__'",[],options);
 queryExecute("INSERT INTO public.tb_geocoding_usage_daily(usage_date,provider,calls) VALUES((clock_timestamp() AT TIME ZONE 'UTC')::date,'geoapify',2000) ON CONFLICT(usage_date,provider) DO UPDATE SET calls=2000",[],options);
 extra=store.reserveCall(3000);check(extra.allowed AND extra.calls EQ 2001,"The expanded shared budget permits consultation 2,001");
 overlapping=store.reserveCall(3000);check(!overlapping.allowed AND overlapping.reason EQ "provider_busy","The expanded budget never permits simultaneous provider calls");
 store.completeCall(extra.token,"ok");paced=store.reserveCall(3000);check(!paced.allowed AND paced.reason EQ "pacing" AND paced.waitMs GT 0,"One-second pacing still applies after an HTTP call completes");
 queryExecute("UPDATE public.tb_geocoding_cache SET last_call_at=NULL WHERE cache_key='__control__'",[],options);
 queryExecute("UPDATE public.tb_geocoding_usage_daily SET calls=2999 WHERE provider='geoapify' AND usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],options);
 last=store.reserveCall(99999);check(last.allowed AND last.calls EQ 3000,"The 3,000th shared consultation can be reserved");store.completeCall(last.token,"ok");
 queryExecute("UPDATE public.tb_geocoding_cache SET last_call_at=NULL WHERE cache_key='__control__'",[],options);
 queryExecute("UPDATE public.tb_geocoding_cache SET response=jsonb_set(response,'{dailyLimit}','99999'::jsonb) WHERE cache_key='__control__'",[],options);
 blocked=store.reserveCall(99999);check(!blocked.allowed AND blocked.reason EQ "daily_limit","Consultation 3,001 is blocked even when the caller requests a higher ceiling");
 consumed=queryExecute("SELECT calls FROM public.tb_geocoding_usage_daily WHERE provider='geoapify' AND usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],options);
 check(consumed.calls[1] EQ 3000,"A denied reservation never increments the shared daily usage");
 transaction action="rollback";
}
transaction {
 settings=store.settings();rejected=false;try{store.saveSettings(settings.enabled,3001,settings.validatedFingerprint);}catch(Geocoding.Validation beyondCap){rejected=true;}
 check(rejected,"Configuration cannot authorize a budget above 3,000");transaction action="rollback";
}
writeOutput("GEO_QUOTA_3000_PASSED");
</cfscript>
