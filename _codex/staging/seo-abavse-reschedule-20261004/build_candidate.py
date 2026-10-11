from pathlib import Path
P=Path(__file__).resolve().parent
service='''component output="false" {
    public boolean function isReadRequest(required string method, required struct params) {
        if (!listFindNoCase("GET,HEAD", arguments.method)) return false;
        for (var key in arguments.params) {
            if (!listFindNoCase("tag,i18n_lang,i18n_route,route_geometry", key)) return false;
        }
        return !structKeyExists(arguments.params, "route_geometry")
            || !len(trim(arguments.params.route_geometry & ""));
    }

    // Shared by resolution and sitemap discovery: invalid mappings never hide a page.
    public string function validTargetSql(required string sourceAlias) {
        if (!reFind("^[a-zA-Z_][a-zA-Z0-9_]*$", arguments.sourceAlias)) {
            throw(type="EventRedirect.InvalidAlias", message="Invalid trusted SQL alias");
        }
        var source = arguments.sourceAlias;
        return "EXISTS (
            SELECT 1 FROM tb_evento_corridas redirect_target
            WHERE redirect_target.tag = trim(" & source & ".tag_301)
              AND redirect_target.ativo = true
              AND redirect_target.id_evento <> " & source & ".id_evento
              AND redirect_target.tag ~ '^[a-z0-9][a-z0-9-]{1,255}$'
              AND nullif(trim(redirect_target.tag_301), '') IS NULL
              AND (SELECT count(*) FROM tb_evento_corridas target_match
                   WHERE target_match.tag = redirect_target.tag) = 1
        ) AND (SELECT count(*) FROM tb_evento_corridas source_match
               WHERE source_match.tag = " & source & ".tag) = 1";
    }

    public string function resolveTarget(required string tag) {
        if (!len(arguments.tag) || len(arguments.tag) > 256) return "";
        var match = queryExecute(
            "SELECT trim(source_event.tag_301) AS target_tag
             FROM tb_evento_corridas source_event
             WHERE source_event.tag = :tag AND " & validTargetSql("source_event"),
            {tag={value=arguments.tag,cfsqltype="cf_sql_varchar"}}, {timeout=10}
        );
        return match.recordCount == 1 ? match.target_tag[1] & "" : "";
    }

    public struct function rescheduleEvidenceFor(required string tag, required string startDate, required string endDate) {
        // TicketSports 87181 official notice, checked 2026-10-04: 2026-08-09 -> 2027-05-02.
        // A redirect alone does not prove postponement; keep this evidence bound to its dates.
        if (arguments.tag == "2027-4-corrida-do-turismo-abavse-2026"
            && arguments.startDate == "2027-05-02" && arguments.endDate == "2027-05-02") {
            return {eventStatus="https://schema.org/EventRescheduled",previousStartDate="2026-08-09"};
        }
        return {};
    }
}
'''
include='''<cfif reFindNoCase("[/\\\\]event_redirect\\.cfm$", CGI.SCRIPT_NAME)>
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
'''
for name,content in [('services/EventRedirectService.cfc',service),('includes/estrutura/event_redirect.cfm',include)]:
 target=P/'candidate'/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content)
name='evento/index.cfm';text=(P/'baseline'/name).read_text();needle='\n<!doctype html>'
assert text.count(needle)==1
text=text.replace(needle,'\n<cfinclude template="../includes/estrutura/event_redirect.cfm"/>\n'+needle)
needle='        : "https://schema.org/EventScheduled";'
assert text.count(needle)==1
text=text.replace(needle,needle+'''
    VARIABLES.eventRescheduleEvidence = VARIABLES.eventRedirectService.rescheduleEvidenceFor(
        tag=qEvento.tag & "", startDate=VARIABLES.eventSchema.startDate, endDate=VARIABLES.eventSchema.endDate
    );
    if (VARIABLES.eventSchema.eventStatus != "https://schema.org/EventCancelled"
        && !structIsEmpty(VARIABLES.eventRescheduleEvidence)) {
        structAppend(VARIABLES.eventSchema, VARIABLES.eventRescheduleEvidence, true);
    }
''')
(P/'candidate'/name).write_text(text)
name='sitemaps/index.cfm';text=(P/'baseline'/name).read_text();text=text.replace('baseUrl = "https://roadrunners.run";','baseUrl = "https://roadrunners.run";\neventRedirectPolicy = new services.EventRedirectService().validTargetSql("sitemap_event");')
assert text.count('FROM tb_evento_corridas\n')==2
text=text.replace('FROM tb_evento_corridas\n','FROM tb_evento_corridas sitemap_event\n')
assert text.count("          AND trim(tag) <> ''")==2
text=text.replace("          AND trim(tag) <> ''", "          AND trim(tag) <> ''\n          AND NOT (#preserveSingleQuotes(eventRedirectPolicy)#)")
(P/'candidate'/name).write_text(text)
print('Built four narrowly scoped runtime candidates from production baseline')
