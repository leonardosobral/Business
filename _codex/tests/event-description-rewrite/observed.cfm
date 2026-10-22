<cfscript>
// Private fixtures captured during the approved diagnosis; read-only regression.
observed=deserializeJSON(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "observed.json","utf-8"));
for(eventFixture in observed) {
    if(eventFixture.id EQ 43916) {
        check(service.validateRewrite(eventFixture.source,eventFixture.candidate).valid,"Observed event 43916 accepts equivalent duration in the completed candidate");
    } else {
        fixture=createObject("component","services.ProviderFixture").init([]);
        try {fixture.rewrite(eventFixture.source,"SENSITIVE_FIXTURE");check(false,"Observed template must reject before AI");}
        catch(EventDescriptionRewrite.Validation sourceIssue) {
            check(service.validationDetails(sourceIssue).code EQ "source_placeholder","Observed event " & eventFixture.id & " requires useful editorial source");
        }
        check(arrayLen(fixture.getRequests()) EQ 0,"Observed template " & eventFixture.id & " does not spend AI credits");
    }
}
</cfscript>
