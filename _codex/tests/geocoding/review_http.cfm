<cfscript>
if(CGI.request_method EQ "POST"){
 qPerfil=queryNew("is_admin");queryAddRow(qPerfil);querySetCell(qPerfil,"is_admin",true);
 REQUEST.businessIdentity={id="fixture"};
 URL.aba="revisao";URL.periodo="todos";URL.busca="PRIVATE-REVIEW-HTTP-NO-REAL-EVENT";URL.uf="";
 FORM.csrf=URL.testcase EQ "csrf" ? "wrong" : csrfGenerateToken("event-geocoding");
 FORM.guided="1";FORM.id="2147001701";FORM.attribute=URL.testcase EQ "last" ? "2" : "1";FORM.confirmed="1";FORM.revision="3";
 FORM.action=URL.testcase EQ "skip" ? "skip_review" : (URL.testcase EQ "resume" ? "resume_reviews" : "reject_field");
 if(listFind("correct,correct_last,invalid_edit,obsolete_edit",URL.testcase)){
  FORM.action="correct_field";FORM.edited_value=URL.testcase EQ "invalid_edit" ? "Valor inválido preservado" : "Valor corrigido pelo operador";
  FORM.attribute=URL.testcase EQ "correct" ? "1" : "2";URL.etapa="field-1";
  if(URL.testcase EQ "obsolete_edit"){FORM.revision="2";FORM.attribute="1";}
 }
 if(URL.testcase EQ "stale")FORM.revision="2";
 if(URL.testcase EQ "delegated")REQUEST.businessAccessContext={accessMode="DELEGATED"};
 include "../administracao/geolocalizacao/includes/backend.cfm";
 if(URL.testcase EQ "stale"){
  if(structIsEmpty(VARIABLES.geoSelected) OR VARIABLES.geoSelected.id NEQ 2147001701 OR !len(VARIABLES.geoError) OR !arrayLen(VARIABLES.geoReviewTasks))throw(type="Test.Failed",message="A stale POST lost the actual proposal instead of rehydrating the review");
 }else if(URL.testcase EQ "invalid_edit"){
  if(!len(VARIABLES.geoError) OR !VARIABLES.geoEditPosted OR VARIABLES.geoEditValue NEQ "Valor inválido preservado" OR VARIABLES.geoReviewTask.key NEQ "field-2")throw(type="Test.Failed",message="The invalid human correction lost its text or reopened the wrong field");
 }else if(URL.testcase EQ "obsolete_edit"){
  if(!len(VARIABLES.geoError) OR !VARIABLES.geoEditPosted OR !VARIABLES.geoEditObsolete)throw(type="Test.Failed",message="An obsolete edit must remain a detached draft rather than bind to a reordered field");
 }else if(!listFind("csrf,delegated",URL.testcase))throw(type="Test.Failed",message="Guided POST did not redirect");
}
writeOutput("GEO_REVIEW_HTTP_PASSED");
</cfscript>
