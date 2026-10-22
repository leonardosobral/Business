<cfscript>
// Execute the exact validation catch bodies extracted from the runtime endpoint.
rejectedDescription={extendedInfo='["numbers_changed","times_changed"]',message="SENSITIVE_FIXTURE",detail="SENSITIVE_FIXTURE"};
VARIABLES.rewriteResult={};VARIABLES.rewriteResponse={errors=0};VARIABLES.rewriteHttpStatus=200;
VARIABLES.rewriteService=service;VARIABLES.rewriteRejectedEvidence="";
include "rewrite-catch.cfm";
check(VARIABLES.rewriteResult.status EQ "rejected" AND VARIABLES.rewriteErrorCode EQ "numbers_changed","Portuguese cron audit stores the specific safe reason");
check(structKeyExists(VARIABLES.rewriteResult,"validationReasons") AND arrayLen(VARIABLES.rewriteResult.validationReasons) EQ 2,"Portuguese cron history retains every validation reason");
check(structKeyExists(VARIABLES.rewriteResult,"message") AND !find("SENSITIVE_FIXTURE",serializeJSON(VARIABLES.rewriteResult)),"Portuguese cron explains rejection without raw exception content");
check(VARIABLES.rewriteResponse.errors EQ 1 AND VARIABLES.rewriteHttpStatus EQ 422,"Portuguese rejection preserves existing HTTP and error semantics");

rejectedTranslation={extendedInfo='["units_changed"]',message="SENSITIVE_FIXTURE",detail="SENSITIVE_FIXTURE"};
outcome={result={},errors=0,httpStatus=200};errorCode="";
rejectedEvidence="";
include "translation-catch.cfm";
check(outcome.result.status EQ "rejected" AND errorCode EQ "units_changed","Translation audit stores the specific safe reason");
check(structKeyExists(outcome.result,"validationReasons") AND outcome.result.validationReasons[1] EQ "units_changed","Translation history retains validation reasons");
check(structKeyExists(outcome.result,"message") AND !find("SENSITIVE_FIXTURE",serializeJSON(outcome.result)),"Translation diagnostics never expose exception or provider text");

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="PRIVATE_CANDIDATE 15 km."})]);
try {fixture.rewrite("Corrida de 5 km.","API_KEY_NEVER_AUDIT");} catch(EventDescriptionRewrite.Validation capture) {rejectedDescription=capture;}
VARIABLES.rewriteService=fixture;VARIABLES.rewriteResult={};VARIABLES.rewriteResponse={errors=0};VARIABLES.rewriteHttpStatus=200;VARIABLES.rewriteRejectedEvidence="";
include "rewrite-catch.cfm";
check(isJSON(VARIABLES.rewriteRejectedEvidence) AND find("PRIVATE_CANDIDATE",VARIABLES.rewriteRejectedEvidence) GT 0,"Portuguese catch prepares private evidence for the audit write");
check(!find("PRIVATE_CANDIDATE",serializeJSON(VARIABLES.rewriteResult)),"Cron response never includes the private rejected text");
fixture.init([responseFor({descricao="PRIVATE_TRANSLATION 15 km."})]);
try {fixture.translate("Corrida de 5 km.","en","API_KEY_NEVER_AUDIT");} catch(EventDescriptionRewrite.Validation capture) {rejectedTranslation=capture;}
service=fixture;outcome={result={},errors=0,httpStatus=200};errorCode="";rejectedEvidence="";
include "translation-catch.cfm";
check(isJSON(rejectedEvidence) AND find("PRIVATE_TRANSLATION",rejectedEvidence) GT 0,"Translation catch prepares its own private audit evidence");
check(!find("PRIVATE_TRANSLATION",serializeJSON(outcome.result)),"Translation response never includes rejected text");
service=createObject("component","services.EventDescriptionRewriteService");
</cfscript>
