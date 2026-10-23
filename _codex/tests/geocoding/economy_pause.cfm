<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
store=new services.geocoding.LocationStore();settings=store.settings();check(!settings.enabled,"O sistema real deve continuar pausado.");
before=new services.geocoding.AIBudget().status();economy=new services.geocoding.Economy({aiKey="fixture-never-sent"});
context={nome_evento="Fixture",start_date="2026-11-01"};documents=[];arrayAppend(documents,{url="https://example.org",text="Fonte sintética",sha256="x"});
result=economy.extract(context,documents);check(result.code EQ "disabled" AND result.paid_calls EQ 0,"Pausa bloqueia geração sem depender da chave.");
check(economy.pollPending(getTickCount()+45000) EQ 0,"Pausa bloqueia polling Batch.");
after=new services.geocoding.AIBudget().status();check(before.pending_usd EQ after.pending_usd,"Pausa não cria reservas.");
writeOutput("GEO_ECONOMY_PAUSE_PASSED");
</cfscript>
