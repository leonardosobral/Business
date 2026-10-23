<cfscript>
function usageAssert(required boolean ok,required string message){if(!ok)throw(type="UsageTest.Failed",message=message);}
a=new __GEO_TEST_PACKAGE__.services.openaiUsage.Access();
usageAssert(a.allowed(true,true,false) AND !a.allowed(true,false,false) AND !a.allowed(true,true,true) AND !a.allowed(false,false,false),"Somente admin global efetivo, nunca conta/delegação.");
s=new __GEO_TEST_PACKAGE__.services.openaiUsage.Store(getTempDirectory(),"runner_dba");
f=s.filters({period="7",module="all",model="",status="all",page="1"});usageAssert(f.toMs GT f.fromMs AND f.toMs-f.fromMs LTE 8*86400000,"Filtro de 7 dias válido.");
bad=false;try{s.filters({period="7",module="../../secrets",page="1"});}catch(any denied){bad=true;}usageAssert(bad,"Rejeitar filtro módulo desconhecido.");
bad=false;try{s.filters({period="custom",start="2026-01-01",end="2026-10-23",page="1"});}catch(any denied){bad=true;}usageAssert(bad,"Intervalo máximo de 90 dias.");
rows=[{id="a",at_ms=f.fromMs+100,module="helpdesk",model="gpt-6.1-sol",operation="draft",status="success",http_status=200,tokens_known=true,input_tokens=100,output_tokens=10,cached_tokens=0,write_30m_tokens=0,write_12h_tokens=0,cost_known=true,estimated_usd=0.0003,partial_cost=false,source="ledger"},{id="b",at_ms=f.fromMs+200,module="helpdesk",model="gpt-6.1-sol",operation="draft",status="error",http_status=429,tokens_known=false,input_tokens=0,output_tokens=0,cached_tokens=0,write_30m_tokens=0,write_12h_tokens=0,cost_known=false,estimated_usd=0,partial_cost=true,source="ledger"}];
r=s.summarize(rows,f);
usageAssert(r.summary.tokens EQ 110 AND r.summary.unknown EQ 1 AND abs(r.summary.usd-0.0003) LT 0.00000001,"Dados ausentes não zeram gasto conhecido nem viram medição.");
usageAssert(arrayLen(r.modules) EQ 8 AND arrayLen(r.history) EQ 2 AND r.history[1].id EQ "b","Módulos sem dados e histórico cronológico visíveis.");
usageDailyTokens=0;usageDailyCost=0;for(usageDailyRow in r.days){usageDailyTokens+=usageDailyRow.tokens;usageDailyCost+=usageDailyRow.usd;}
usageAssert(usageDailyTokens EQ r.summary.tokens AND abs(usageDailyCost-r.summary.usd) LT 1E-12,"Os totais diários devem reconciliar com os tokens e custos medidos.");
usageAssert(rows[1].day EQ f.start AND r.days[1].tokens EQ 110,"Agrupar pelo dia local ISO, nunca pelo builtin day() do ColdFusion.");
rows[1].estimated_usd=1.2E-8;r=s.summarize(rows,f);usageAssert(abs(r.summary.usd-1.2E-8) LT 1E-12,"Custos pequenos em notação científica não podem ser truncados por val().");
f.module="ai-mails";r=s.summarize(rows,f);usageAssert(r.summary.records EQ 0,"Aplicar filtros antes de agregar.");
writeOutput("GEO_STORE_PASSED");
</cfscript>
