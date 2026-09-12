<!--- Additive analytics must never block the rendered page or query the database. --->
<cfscript>
if (!structKeyExists(REQUEST,"audienceMeasurementBootstrapped")) {
    REQUEST.audienceMeasurementBootstrapped=true;
    try {
        if (structKeyExists(APPLICATION,"audienceMeasurement") && isStruct(APPLICATION.audienceMeasurement)) {
            VARIABLES.audienceMeasurementControl=createObject("component","services.AudienceRequestControlService").init(APPLICATION.audienceMeasurement);
            VARIABLES.audienceMeasurementHeaders=getHTTPRequestData(false).headers;
            VARIABLES.audienceMeasurementDecision=VARIABLES.audienceMeasurementControl.evaluate(CGI,VARIABLES.audienceMeasurementHeaders);
            if (VARIABLES.audienceMeasurementDecision.allowed) {
                VARIABLES.audienceMeasurementSecret=VARIABLES.audienceMeasurementDecision.hostConfig.secret;
                VARIABLES.audienceMeasurementService=createObject("component","services.AudienceMeasurementService").init({"enabled"=true,"secret"=VARIABLES.audienceMeasurementSecret});
                VARIABLES.audienceMeasurementSecret="";
                if (VARIABLES.audienceMeasurementService.isEnabled()) {
                    REQUEST.audienceMeasurementContext=VARIABLES.audienceMeasurementService.buildContext(VARIABLES,REQUEST,CGI);
                    writeOutput('<script>window.RoadRunnersAudienceConfig=' & VARIABLES.audienceMeasurementService.configJson(REQUEST.audienceMeasurementContext) & ';</script><script src="/assets/js/rr-audience.js?v=62bc8dc568f4" defer></script>');
                }
            }
        }
    } catch(any ignoredAudienceBootstrap) {
        // Deliberately no raw context, user or credential logging on a public page.
    }
}
</cfscript>
