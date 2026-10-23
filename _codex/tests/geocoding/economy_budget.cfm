<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
transaction{
 b=new services.geocoding.AIBudget("fixture-" & createUUID());
 r=b.reserve("a","gpt-6.1-sol","default",1.2);check(r.created,"Reserva inicial.");
 check(!b.reserve("b","gpt-6-astra","default",0.9).allowed,"Não ultrapassar USD2.");
 check(!b.reserve("a","gpt-6.1-sol","default",1.2).created,"Idempotência: não reenviar.");
 b.settle("a",{ok=true,usage={input_tokens=1000,output_tokens=100},model="gpt-6.1-sol"});
 check(b.status().pending_usd EQ 0 AND b.status().day_usd GT 0 AND b.status().day_usd LT 1.2,"Liquidar pelo limite conservador de tokens reais.");
 r=b.reserve("b","gpt-6.1-sol","batch",1.9);check(r.created,"Reserva Batch após liquidação.");
 b.update("b",{state="uncertain"});check(!b.reserve("c","gpt-6.1-sol","default",0.2).allowed,"Incerteza não libera saldo.");
 check(b.status().day_limit EQ 2 AND b.status().month_limit EQ 30,"Tetos fixos.");
 transaction action="rollback";
}
writeOutput("GEO_ECONOMY_BUDGET_PASSED");
</cfscript>
