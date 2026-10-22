<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
VARIABLES.geoCanAdmin=true;VARIABLES.geoReady=false;VARIABLES.geoConfigured=false;VARIABLES.geoTab="configuracoes";VARIABLES.geoNotice="";VARIABLES.geoError="";
VARIABLES.geoStats={missing=0,queued=0,review=0,suggestions=0,analyzed=0,applied=0,calls=0};VARIABLES.geoSettings={enabled=false,dailyLimit=1000};VARIABLES.geoState={cooldown=0};VARIABLES.geoKeyValidated=false;VARIABLES.geoNextReview=0;VARIABLES.geoReviewBase="?aba=revisao&periodo=todos";
VARIABLES.geoRows=queryNew("id_evento,nome_evento,cidade,estado,endereco,status,work_id,starts");VARIABLES.geoHasNext=false;VARIABLES.geoPage=1;VARIABLES.geoSearch="";VARIABLES.geoStatus="todos";VARIABLES.geoPeriod="proximos";VARIABLES.geoUf="";VARIABLES.geoSelected={};VARIABLES.geoDecision={};VARIABLES.geoReasonLabels={};
savecontent variable="rendered" {include "view-runtime.cfm";}
check(find("Configuração pendente",rendered) GT 0,"Missing setup remains explicit instead of a broken page");
check(find("geoapifyApiKey",rendered) GT 0 AND !find("NEVER_COPY",rendered),"Configuration help does not render a secret");
VARIABLES.geoTab="revisao";VARIABLES.geoSelected={id=1,id_evento=48091,nome_evento="<script>alert(1)</script>",status="city_suggestion",changed_at="17/10/2026 10:00:00"};
VARIABLES.geoDecision={candidate={lat=-23.5,lon=-46.6,formatted="<img src=x onerror=alert(1)>",result_type="city",datasource={attribution="© OpenStreetMap contributors"}},reasons=["city_only"]};VARIABLES.geoMayApprove=false;
savecontent variable="rendered" {include "view-runtime.cfm";}
check(!find("<script>alert",rendered) AND !find("<img src=x",rendered),"Provider and event HTML cannot execute in review");
check(find("Localização aproximada da cidade",rendered) GT 0 AND !find('value="approve"',rendered),"City detail has no approval action");
VARIABLES.geoReady=true;VARIABLES.geoSelected.status="needs_review";VARIABLES.geoSelected.proposal_revision=1;VARIABLES.geoMayApprove=true;
savecontent variable="rendered" {include "view-runtime.cfm";}
check(find("Aprovar e próxima",rendered) GT 0 AND !reFind('(?s)name="reason"[^>]*required',rendered) AND !find('name="confirmed" value="1" required',rendered),"Quick review can submit without typed reason or a second checkbox");
VARIABLES.geoTab="cidades";VARIABLES.geoSelected={};savecontent variable="rendered" {include "view-runtime.cfm";}
check(find("sem revisão obrigatória",rendered) GT 0,"Municipal suggestions are explicitly separate from required review");
check(find("novas análises não retiram",rendered) GT 0 AND find("não é um total acumulado",rendered) GT 0,"Counter definitions distinguish durable outcomes from the current review queue");
VARIABLES.geoAIReady=true;VARIABLES.geoConfig={aiModel="gpt-6-astra",aiDailyLimit=1000};VARIABLES.geoAIStats={calls=0,cooldown=3600,code="ai_quota_exhausted"};VARIABLES.geoStats.deferred=3;
savecontent variable="rendered" {include "view-runtime.cfm";}
check(find("sugestões municipais continuam",rendered) GT 0 AND find("3 pesquisa(s)",rendered) GT 0,"Deferred AI research is visible separately from human review");
writeOutput("GEO_VIEW_PASSED");
</cfscript>
