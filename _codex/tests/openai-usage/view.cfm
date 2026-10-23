<cfscript>
function usageAssert(required boolean ok,required string message){if(!ok)throw(type="UsageTest.Failed",message=message);}
usageStore=new __GEO_TEST_PACKAGE__.services.openaiUsage.Store();usageFilters=usageStore.filters({period="7"});usageTab="overview";usageCatalog=new __GEO_TEST_PACKAGE__.services.openaiUsage.Catalog().modules();
usageData=usageStore.summarize([],usageFilters);usageData.warnings=[];usageData.trackedSince=0;usageData.updatedAt=createObject("java","java.lang.System").currentTimeMillis();usageData.collectorAvailable=false;
function usageLink(required string tab,numeric page=1){return "?aba=" & tab & "&pagina=" & page;}
include "formatters.cfm";
usageAssert(usageMoney(44.89) EQ "US$ 44,89" AND usageMoney(0.00057) EQ "US$ 0,000570" AND usageNumber(2527243) EQ "2.527.243","Formatação real pt-BR, sem zeros à esquerda nos custos.");
savecontent variable="rendered" {include "../administracao/consumo-openai/includes/view.cfm";}
usageAssert(find("Visão geral",decodeForHTML(rendered)) AND find("Histórico",decodeForHTML(rendered)) AND find("Cobertura",rendered),"Navegação por abas.");
usageAssert(find("Estimativa",rendered) AND findNoCase("faturamento",rendered),"Nunca apresentar estimativa como fatura.");
usageAssert(find("Leitura de cache",decodeForHTML(rendered)) AND find("Escrita 30 min",decodeForHTML(rendered)),"Detalhar tokens de cache no painel.");
usageData.days[1].records=1;usageData.days[1].unpriced=1;usageData.days[1].unknown=1;
savecontent variable="rendered" {include "../administracao/consumo-openai/includes/view.cfm";}
usageAssert(!find('US$ 0,00',rendered) AND find("Não informado",decodeForHTML(rendered)),"Dia sem tarifa não pode apresentar custo zero.");
usageTab="history";usageData.history=[{at_ms=1,label='<script>alert(1)</script>',operation="draft",model="gpt-6.1-sol",status="error",http_status=429,tokens_known=false,input_tokens=0,output_tokens=0,cost_known=false,estimated_usd=0,source="ledger"}];usageData.totalRows=1;
savecontent variable="rendered" {include "../administracao/consumo-openai/includes/view.cfm";}
usageAssert(!find('<script>alert(1)</script>',rendered) AND find("&lt;script&gt;",rendered),"Histórico deve escapar conteúdo.");
usageAssert(find("Não informado",rendered),"Token/custo ausente não pode ser desenhado como zero.");
writeOutput("GEO_VIEW_PASSED");
</cfscript>
