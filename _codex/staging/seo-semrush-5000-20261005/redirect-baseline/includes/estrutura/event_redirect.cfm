<cfif reFindNoCase("[/\\]event_redirect\.cfm$", CGI.SCRIPT_NAME)>
    <cfheader statuscode="404" statustext="Not Found"/><cfabort/>
</cfif>
<cfscript>
VARIABLES.eventRedirectService = new services.EventRedirectService();
if (structKeyExists(URL, "tag") && structKeyExists(REQUEST, "i18nBuildPath")
    && VARIABLES.eventRedirectService.isReadRequest(CGI.REQUEST_METHOD, URL)) {
    VARIABLES.eventRedirectTarget = VARIABLES.eventRedirectService.resolveTarget(URL.tag & "");
    if (len(VARIABLES.eventRedirectTarget)) {
        REQUEST.currentRouteParams = {tag=replace(encodeForURL(VARIABLES.eventRedirectTarget), "+", "%20", "all")};
        VARIABLES.eventRedirectPath = REQUEST.i18nBuildPath("event");
        location(url=VARIABLES.eventRedirectPath, addtoken=false, statuscode=301);
    }
}
</cfscript>
