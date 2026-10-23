<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
p=new services.EventLocationPolicy();problem={};
try{p.resolve({pais="PT",estado="XX",cidade="Porto",endereco="",coordenadas="inválidas"},{});}catch(BusinessDelegation.Validation failure){problem=failure;}
check((problem.errorCode ?: "") EQ "event_location","Location validation is distinguishable from authorization failures for clear user feedback");
VARIABLES.eventLocationErrorMessage=problem.message;VARIABLES.eventLocationErrorEventId="38202";
savecontent variable="rendered"{include '../eventos/includes/event_location_error.cfm';}
check(find(encodeForHTML(problem.message),rendered) AND !find("confira seu acesso",rendered) AND find('id_evento=38202',rendered),"The actual error view explains the correction and offers a return to the event");
VARIABLES.eventLocationErrorMessage='<script>alert(1)</script>';
savecontent variable="rendered"{include '../eventos/includes/event_location_error.cfm';}
check(!find('<script>',rendered) AND find(encodeForHTML(VARIABLES.eventLocationErrorMessage),rendered),"Validation feedback is HTML-escaped");
writeOutput("GEO_EVENT_LOCATION_ERROR_PASSED");
</cfscript>
