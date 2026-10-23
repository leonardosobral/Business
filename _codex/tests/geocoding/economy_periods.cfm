<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
transaction{
 ns="fixture-" & createUUID();budget=new services.geocoding.AIBudget(ns);
 budget.reserve("old","gpt-6.1-sol","batch",1.8);
 queryExecute("UPDATE public.tb_geocoding_cache SET response=jsonb_set(response,'{created_day}',to_jsonb('2025-01-01'::text)) WHERE query_text=:ns",{ns={value=ns,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
 check(!budget.reserve("new","gpt-6.1-sol","default",0.3).allowed,"Reserva anterior continua retida na virada do dia e do mês.");
 permanent=queryExecute("SELECT count(*) AS n FROM public.tb_geocoding_cache WHERE query_text=:ns AND expires_at='infinity'",{ns={value=ns,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});check(permanent.n[1] EQ 1,"Controle financeiro não pode expirar como cache comum.");
 budget.settle("old",{ok=true,model="gpt-6.1-sol",usage={input_tokens=100,output_tokens=10}});
 settled=budget.get("old");check(settled.settled_day EQ budget.status().day AND budget.status().day_usd GT 0,"Batch é liquidado no dia do resultado, sem liberar valor na virada.");
 // Synthetic history: 15 settled requests in the current month, not today.
 queryExecute("DELETE FROM public.tb_geocoding_cache WHERE query_text=:ns",{ns={value=ns,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
 for(i=1;i LTE 15;i++){
  budget.reserve("m-" & i,"gpt-6.1-sol","default",0.01);
  key=lCase(hash(ns & "|m-" & i,"SHA-256"));
  queryExecute("UPDATE public.tb_geocoding_cache SET response=jsonb_build_object('state','done','charged_micros',1990000,'reserved_micros',10000,'settled_day',to_char((clock_timestamp() AT TIME ZONE 'UTC')::date,'YYYY-MM')||'-01') WHERE cache_key=:id",{id={value=key,cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
 }
 check(budget.status().month_usd EQ 29.85 AND !budget.reserve("month-over","gpt-6.1-sol","default",0.2).allowed,"Teto mensal de USD30 é independente do teto diário.");
 transaction action="rollback";
}
writeOutput("GEO_ECONOMY_PERIODS_PASSED");
</cfscript>
