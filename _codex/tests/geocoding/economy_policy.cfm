<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
p=new services.geocoding.EconomyPolicy();
check(p.model() EQ "gpt-6.1-sol","Sol é o padrão.");
check(p.historical({start_date="2025-01-01"}) AND !p.historical({start_date="2099-01-01"}),"Histórico vai para Batch.");
emptyDocuments=[];refusal={ok=false,code="ai_refusal"};quota={ok=false,code="ai_rate_limited"};
refusalEscalates=p.escalate(refusal,emptyDocuments);quotaEscalates=p.escalate(quota,emptyDocuments);
check(!refusalEscalates AND !quotaEscalates,"Não contornar recusa ou quota.");
documentText=repeatString("Publicidade irrelevante. ",5000) & " Largada: Praça Central, Curitiba, PR. Retirada de kit: Ginásio Municipal.";
docs=[];arrayAppend(docs,{url="https://example.org/event",text=documentText,sha256="a"});
body=p.body({nome_evento="Corrida",start_date="2026-11-01",cidade="Curitiba",estado="PR",pais="BR"},docs,p.model());
check(body.model EQ p.model() AND body.service_tier EQ "default" AND body.reasoning.effort EQ "low" AND body.max_output_tokens EQ 2000,"Modelo, tier e saída limitados.");
check(len(body.input) LT 24000 AND find("Praça Central",body.input),"Recortar sem perder o trecho de largada.");
check(p.reserveUSD(body,"default") GT 0 AND p.reserveUSD(body,"batch") EQ p.reserveUSD(body,"default")/2,"Reservar custo pessimista e desconto Batch.");
twoDocs=duplicate(docs);arrayAppend(twoDocs,duplicate(docs[1]));
conflict={ok=true,facts={event_name="Corrida",event_date="2026-11-01",locations=[{certainty="undefined"}],attributes=[{field="data_inicial",certainty="conflicting"}]}};
check(!p.escalate(conflict,twoDocs),"Conflito factual em atributo não deve provocar escalada para Astra.");
writeOutput("GEO_ECONOMY_POLICY_PASSED");
</cfscript>
