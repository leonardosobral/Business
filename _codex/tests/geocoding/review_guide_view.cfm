<cfinclude template="view.cfm">
<cfscript>
VARIABLES.geoGuided=true;VARIABLES.geoTab="revisao";VARIABLES.geoAIReady=true;
VARIABLES.geoConfig={aiModel="gpt-6-astra",aiDailyLimit=1000};VARIABLES.geoAIStats={calls=0,cooldown=0};
VARIABLES.geoSelected={id=91,id_evento=92,nome_evento="<script>Evento</script>",proposal_revision=4,status="needs_review",cidade="São Paulo",estado="SP",changed_at="22/10/2026 10:00:00"};
VARIABLES.geoCurrent={organizador="Organização atual"};VARIABLES.geoGuide=new services.geocoding.ReviewGuide();
VARIABLES.geoDecision={enrichment={fields=[{field="organizador",label="Organizador",status="needs_review",trusted=true,current="Antigo",value="<img src=x onerror=alert(1)>",evidence={url="https://example.com/oficial",excerpt="Organização da fonte"},reasons=[]}]}};
VARIABLES.geoReviewTasks=VARIABLES.geoGuide.tasks(VARIABLES.geoSelected,VARIABLES.geoDecision,VARIABLES.geoCurrent);
VARIABLES.geoReviewTask=VARIABLES.geoReviewTasks[1];VARIABLES.geoReviewQueue=queryNew("work_id,id_evento,nome_evento,cidade,estado,starts,total");
VARIABLES.geoReviewTotal=1;VARIABLES.geoReviewSkipped=2;VARIABLES.geoReviewDone=3;VARIABLES.geoReviewStale=false;
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(find("Cadastro atual",rendered) AND find("Informação encontrada",rendered) AND find(encodeForHTML("Organização atual"),rendered),"A focused comparison explains the specific review decision");
check(find('value="approve_field"',rendered) AND find('value="reject_field"',rendered) AND find('value="skip_review"',rendered),"Accept, keep and skip are available together in the guided flow");
check(find('name="guided" value="1"',rendered) AND find('name="revision" value="4"',rendered),"Guided submissions preserve the proposal revision and sequential continuation");
check(!find("<img src=x",rendered) AND !find("<script>Evento",rendered),"The new decision screen cannot execute event or source content");
check(!find('name="reason"',rendered) AND !find('geo-tab-fields',rendered),"Review requires no typed justification or hidden decision tab");
check(find('name="edited_value"',rendered) AND find('value="correct_field"',rendered),"Quick review offers an inline editor and a separate save-and-continue action");
VARIABLES.geoReviewTask.canApprove=false;savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(!find('value="approve_field"',rendered) AND find('value="reject_field"',rendered),"Unconfirmed evidence has no accept button but still permits keeping the registration");
check(find('name="edited_value"',rendered) AND find('value="correct_field"',rendered),"Untrusted source data may be manually corrected without becoming trusted AI evidence");
VARIABLES.geoEditValue="Texto digitado <script> inseguro";VARIABLES.geoEditPosted=true;VARIABLES.geoEditTaskKey="field-1";
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(find(encodeForHTMLAttribute(VARIABLES.geoEditValue),rendered) AND !find('Texto digitado <script>',rendered),"A rejected edit remains safely encoded in the editor for correction");
VARIABLES.geoReviewStale=true;savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(find(encodeForHTML(VARIABLES.geoEditValue),rendered) AND find('readonly',rendered) AND !find('value="correct_field"',rendered),"A concurrent change leaves the unsaved draft visible but cannot be overwritten");
VARIABLES.geoReviewStale=false;VARIABLES.geoEditObsolete=true;VARIABLES.geoReviewTask.field="regras_participacao";VARIABLES.geoReviewTask.title="Regras de participação";
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(find(encodeForHTML(VARIABLES.geoEditValue),rendered) AND find('readonly',rendered) AND !find('name="edited_value"',rendered) AND !find('value="correct_field"',rendered),"A revision that reorders fields cannot attach an old draft to the new field at the same index");
VARIABLES.geoSelected={};VARIABLES.geoReviewTask={};VARIABLES.geoReviewTasks=[];VARIABLES.geoReviewTotal=0;
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(find("Retomar adiados",rendered) AND find('value="resume_reviews"',rendered),"An empty sequence offers a clear way to resume skipped events");
check(find(encodeForHTML(VARIABLES.geoEditValue),rendered) AND find('readonly',rendered),"A resolved or missing proposal does not discard the submitted draft");
writeOutput("GEO_REVIEW_GUIDE_VIEW_PASSED");
</cfscript>
