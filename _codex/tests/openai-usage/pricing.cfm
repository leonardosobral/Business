<cfscript>
function usageAssert(required boolean ok,required string message){if(!ok)throw(type="UsageTest.Failed",message=message);}
p=new __GEO_TEST_PACKAGE__.services.openaiUsage.Pricing();
sample={input_tokens=12000,output_tokens=1000,input_tokens_details={cached_tokens=4000,cache_write_tokens=7000,cache_write_tokens_details={ttl_30m_tokens=3000,ttl_12h_tokens=4000}},output_tokens_details={reasoning_tokens=500}};
r=p.estimate("gpt-6-astra",sample,"default");
usageAssert(r.known AND abs(r.usd-0.2015) LT 0.00000001,"Astra: input comum/read/write30m/write12h + output, sem duplicar reasoning/cache.");
r=p.estimate("gpt-4.1-mini-2025-04-14",{input_tokens=1000,output_tokens=200,input_tokens_details={cached_tokens=500}},"default");
usageAssert(r.known AND abs(r.usd-0.00057) LT 0.00000001,"Snapshot mini deve usar tarifa correta e desconto de cache.");
usageAssert(!p.estimate("not-a-priced-model",sample,"default").known,"Modelo desconhecido não pode parecer grátis.");
usageAssert(!p.estimate("gpt-6-astra",{},"default").known,"Uso ausente não pode parecer zero.");
usageAssert(!p.estimate("gpt-6-astra",{input_tokens=10,output_tokens=2,input_tokens_details={cached_tokens=20}},"default").known,"Rejeitar decomposição impossível.");
usageAssert(!p.estimate("gpt-6-astra",sample,"unknown-tier").known,"Tier não reconhecido precisa continuar desconhecido.");
writeOutput("GEO_PRICING_PASSED");
</cfscript>
