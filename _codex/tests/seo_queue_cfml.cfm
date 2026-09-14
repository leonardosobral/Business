<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
if (!structKeyExists(VARIABLES,"seoTestCase")) throw(type="SEOQueueTest",message="Test scenario is required.");
VARIABLES.seoTestAssertions = 0;
function seoTestAssert(required boolean condition, required string message) {
    if (!arguments.condition) throw(type="SEOQueueTest",message=arguments.message);
    VARIABLES.seoTestAssertions++;
}
function seoTestIds(required array items) {
    var ids = [];
    for (var item in arguments.items) arrayAppend(ids,item.id);
    arraySort(ids,"textnocase");
    return arrayToList(ids);
}
VARIABLES.qPerfil = queryNew("is_admin","bit");
queryAddRow(VARIABLES.qPerfil,{is_admin=true});
if (left(VARIABLES.seoTestCase,9) EQ "anonymous") {
    structDelete(VARIABLES,"qPerfil");
} else if (left(VARIABLES.seoTestCase,16) EQ "effective-denied") {
    VARIABLES.businessEffectiveIsAdmin = false;
} else {
    VARIABLES.businessEffectiveIsAdmin = true;
}
</cfscript>
<cfif structKeyExists(VARIABLES,"seoTestTarget")>
    <cfinclude template="#VARIABLES.seoTestTarget#"/>
    <cfoutput>SEO_QUEUE_ACCESS_GRANTED</cfoutput>
    <cfabort/>
</cfif>
<cfif VARIABLES.seoTestCase EQ "contract">
    <cfscript>
    VARIABLES.seoTestFilters = [
        {site="all",priority="all",ids="OR-01,OR-02,RR-01,RR-02,RR-03,RR-04,SH-01"},
        {site="all",priority="p1",ids="RR-01,RR-02"},
        {site="all",priority="p2",ids="OR-01,RR-03,RR-04"},
        {site="all",priority="p3",ids="SH-01"},
        {site="all",priority="review",ids="OR-02"},
        {site="roadrunners",priority="all",ids="RR-01,RR-02,RR-03,RR-04,SH-01"},
        {site="roadrunners",priority="p1",ids="RR-01,RR-02"},
        {site="roadrunners",priority="p2",ids="RR-03,RR-04"},
        {site="roadrunners",priority="p3",ids="SH-01"},
        {site="roadrunners",priority="review",ids=""},
        {site="openresults",priority="all",ids="OR-01,OR-02,SH-01"},
        {site="openresults",priority="p1",ids=""},
        {site="openresults",priority="p2",ids="OR-01"},
        {site="openresults",priority="p3",ids="SH-01"},
        {site="openresults",priority="review",ids="OR-02"}
    ];
    </cfscript>
    <cfloop array="#VARIABLES.seoTestFilters#" index="seoTestFilter">
        <cfset URL.site=seoTestFilter.site/>
        <cfset URL.prioridade=seoTestFilter.priority/>
        <cfinclude template="portal/includes/seo_queue_backend.cfm"/>
        <cfscript>
        seoTestAssert(arrayLen(VARIABLES.seoQueueSnapshot.runs) EQ 2,"Snapshot requires two distinct site runs.");
        seoTestAssert(arrayLen(VARIABLES.seoQueueSnapshot.items) EQ 7,"Snapshot requires seven reviewed items.");
        seoTestAssert(VARIABLES.seoQueueTotal EQ 7,"Global total must not shrink with a filter.");
        seoTestAssert(structKeyExists(VARIABLES,"seoQueueOpenTotal") AND structKeyExists(VARIABLES,"seoQueueResolvedTotal"),"The queue must expose separate pending and resolved totals.");
        seoTestAssert(VARIABLES.seoQueueOpenTotal EQ 7 AND VARIABLES.seoQueueResolvedTotal EQ 0,"Missing resolved fields must default to pending.");
        seoTestAssert(VARIABLES.seoQueueHighPriorityTotal EQ 2,"The two pending P1 issues contribute to the global high-priority total.");
        seoTestAssert(VARIABLES.seoQueueSiteFilter EQ seoTestFilter.site,"Site filter must retain its valid selection.");
        seoTestAssert(VARIABLES.seoQueuePriorityFilter EQ seoTestFilter.priority,"Priority filter must retain its valid selection.");
        seoTestAssert(seoTestIds(VARIABLES.seoQueueItems) EQ seoTestFilter.ids,"Incorrect combined site/priority selection: " & seoTestFilter.site & "/" & seoTestFilter.priority);
        </cfscript>
    </cfloop>
    <cfset URL.site="../../secrets"/>
    <cfset URL.prioridade="<script>unexpected</script>"/>
    <cfinclude template="portal/includes/seo_queue_backend.cfm"/>
    <cfscript>
    seoTestAssert(VARIABLES.seoQueueSiteFilter EQ "all" AND VARIABLES.seoQueuePriorityFilter EQ "all","Unknown filter strings must normalize to safe defaults.");
    seoTestAssert(arrayLen(VARIABLES.seoQueueItems) EQ 7,"Invalid filters cannot select a file or hide the snapshot.");
    </cfscript>
    <cfset URL.site=["roadrunners"]/>
    <cfset URL.prioridade={bad="p1"}/>
    <cfinclude template="portal/includes/seo_queue_backend.cfm"/>
    <cfscript>
    seoTestAssert(VARIABLES.seoQueueSiteFilter EQ "all" AND VARIABLES.seoQueuePriorityFilter EQ "all","Complex filter values must not cause conversion errors.");
    writeOutput("SEO_QUEUE_CONTRACT_PASSED:" & VARIABLES.seoTestAssertions);
    </cfscript>
    <cfabort/>
</cfif>
<cfif VARIABLES.seoTestCase EQ "resolved-contract">
    <cfloop array="#[{site='all',priority='all',ids='OR-01,OR-02,RR-01,RR-02,RR-03,RR-04,SH-01'},{site='roadrunners',priority='p1',ids='RR-01,RR-02'}]#" index="seoTestFilter">
        <cfset URL.site=seoTestFilter.site/>
        <cfset URL.prioridade=seoTestFilter.priority/>
        <cfinclude template="portal/includes/seo_queue_backend.cfm"/>
        <cfscript>
        seoTestAssert(VARIABLES.seoQueueTotal EQ 7,"Resolving an issue must not remove it from the total.");
        seoTestAssert(VARIABLES.seoQueueOpenTotal EQ 6,"Resolving RR-02 must leave six pending issues.");
        seoTestAssert(VARIABLES.seoQueueResolvedTotal EQ 1,"Resolving RR-02 must count one completed issue.");
        seoTestAssert(VARIABLES.seoQueueHighPriorityTotal EQ 1,"A resolved P1 must stop contributing to pending high priority.");
        seoTestAssert(seoTestIds(VARIABLES.seoQueueItems) EQ seoTestFilter.ids,"Resolved RR-02 must remain visible in matching filters.");
        </cfscript>
    </cfloop>
    <cfoutput>SEO_QUEUE_RESOLVED_PASSED:#VARIABLES.seoTestAssertions#</cfoutput>
    <cfabort/>
</cfif>
<cfif VARIABLES.seoTestCase EQ "invalid-urls">
    <cfset VARIABLES.seoTestRejectedUrls = ["javascript:alert(1)","data:text/html,bad","file:///tmp/private","https://outside.test/a","https://roadrunners.run.outside.test/a","https://roadrunners.run/a" & chr(10) & "b","https://roadrunners.run/a" & chr(92) & "b"]/>
    <cfset VARIABLES.seoTestRejectedCount=0/>
    <cfloop array="#VARIABLES.seoTestRejectedUrls#" index="seoTestMaliciousUrl">
        <cftry>
            <cfinclude template="portal/includes/seo_queue_backend.cfm"/>
            <cfthrow type="SEOQueueTest" message="Invalid evidence URL was accepted."/>
            <cfcatch type="SEOQueueContract"><cfset VARIABLES.seoTestRejectedCount++/></cfcatch>
        </cftry>
    </cfloop>
    <cfoutput>SEO_QUEUE_INVALID_URLS_PASSED:#VARIABLES.seoTestRejectedCount#</cfoutput>
    <cfabort/>
</cfif>
<cfif VARIABLES.seoTestCase EQ "score-contract">
    <cfset URL.site="openresults"/>
    <cfset URL.prioridade="p3"/>
    <cfinclude template="portal/includes/seo_queue_backend.cfm"/>
    <cfset URL.verificacao="all"/>
    <cfinclude template="portal/includes/seo_score_backend.cfm"/>
    <cfscript>
    seoTestAssert(arrayLen(VARIABLES.seoScoreSnapshot.sites) EQ 2,"Score snapshot requires two independently identified sites.");
    seoTestAssert(len(VARIABLES.seoScoreSnapshot.methodVersion) GT 0,"Scoring needs a versioned method for future history comparisons.");
    VARIABLES.seoTestScoreBaseline = duplicate(VARIABLES.seoScoreSnapshot.sites);
    VARIABLES.seoTestScoreFilters = ["all","pass","warning","error","unknown","invalid",["error"],{bad="error"}];
    </cfscript>
    <cfloop array="#VARIABLES.seoTestScoreFilters#" index="seoTestScoreInput">
        <cfset URL.verificacao=seoTestScoreInput/>
        <cfinclude template="portal/includes/seo_score_backend.cfm"/>
        <cfscript>
        VARIABLES.seoTestExpectedFilter = isSimpleValue(seoTestScoreInput) AND listFind("all,pass,warning,error,unknown",seoTestScoreInput) ? seoTestScoreInput : "all";
        seoTestAssert(VARIABLES.seoScoreFilter EQ VARIABLES.seoTestExpectedFilter,"Invalid and complex check filters must normalize safely.");
        VARIABLES.seoTestVisibleSum = 0;
        for (VARIABLES.seoTestSiteIndex = 1; VARIABLES.seoTestSiteIndex LTE arrayLen(VARIABLES.seoScoreSnapshot.sites); VARIABLES.seoTestSiteIndex++) {
            VARIABLES.seoTestScoreSite = VARIABLES.seoScoreSnapshot.sites[VARIABLES.seoTestSiteIndex];
            VARIABLES.seoTestBaselineSite = VARIABLES.seoTestScoreBaseline[VARIABLES.seoTestSiteIndex];
            seoTestAssert(VARIABLES.seoTestScoreSite.id EQ VARIABLES.seoTestBaselineSite.id,"Filters cannot reorder or replace source sites.");
            seoTestAssert(VARIABLES.seoTestScoreSite.scoreLabel EQ VARIABLES.seoTestBaselineSite.scoreLabel,"Filtering checks cannot improve or change a site score.");
            seoTestAssert(serializeJSON(VARIABLES.seoTestScoreSite.counts) EQ serializeJSON(VARIABLES.seoTestBaselineSite.counts),"Filter must retain all global status counts.");
            seoTestAssert(serializeJSON(VARIABLES.seoTestScoreSite.criteria) EQ serializeJSON(VARIABLES.seoTestBaselineSite.criteria),"The source evidence must remain intact under filtering.");
            seoTestAssert(serializeJSON(VARIABLES.seoTestScoreSite.history) EQ serializeJSON(VARIABLES.seoTestBaselineSite.history),"Filter must preserve the dated score history.");
            VARIABLES.seoTestExpectedChecks = [];
            for (VARIABLES.seoTestCriterion in VARIABLES.seoTestScoreSite.criteria) {
                if (VARIABLES.seoScoreFilter EQ "all" OR VARIABLES.seoTestCriterion.status EQ VARIABLES.seoScoreFilter) arrayAppend(VARIABLES.seoTestExpectedChecks,VARIABLES.seoTestCriterion);
            }
            seoTestAssert(seoTestIds(VARIABLES.seoTestScoreSite.visibleCriteria) EQ seoTestIds(VARIABLES.seoTestExpectedChecks),"Visible checks must exactly match the selected status.");
            seoTestAssert(VARIABLES.seoTestScoreSite.visibleCount EQ arrayLen(VARIABLES.seoTestExpectedChecks),"Site visible count must describe its own filtered checks.");
            VARIABLES.seoTestVisibleSum += arrayLen(VARIABLES.seoTestExpectedChecks);
        }
        seoTestAssert(VARIABLES.seoScoreVisibleTotal EQ VARIABLES.seoTestVisibleSum,"Visible report total must match the site checklists.");
        seoTestAssert(VARIABLES.seoQueueSiteFilter EQ "openresults" AND VARIABLES.seoQueuePriorityFilter EQ "p3","Check filtering must retain independent queue filters.");
        seoTestAssert(seoTestIds(VARIABLES.seoQueueItems) EQ "SH-01","Check filtering must not change queue results.");
        </cfscript>
    </cfloop>
    <cfoutput>SEO_SCORE_CONTRACT_PASSED:#VARIABLES.seoTestAssertions#</cfoutput>
    <cfabort/>
</cfif>
<cfif VARIABLES.seoTestCase EQ "score-invalid-data">
    <cfset VARIABLES.seoTestScoreRejectedUrls = ["javascript:alert(1)","data:text/html,bad","file:///tmp/private","https://outside.test/a","https://roadrunners.run.outside.test/a","https://roadrunners.run/a" & chr(10) & "b","https://roadrunners.run/a" & chr(92) & "b"]/>
    <cfset VARIABLES.seoTestScoreRejectedCount=0/>
    <cfloop array="#VARIABLES.seoTestScoreRejectedUrls#" index="seoTestScoreInvalidUrl">
        <cftry>
            <cfinclude template="portal/includes/seo_score_backend.cfm"/>
            <cfthrow type="SEOQueueTest" message="Invalid score evidence URL was accepted."/>
            <cfcatch type="SEOScoreContract"><cfset VARIABLES.seoTestScoreRejectedCount++/></cfcatch>
        </cftry>
    </cfloop>
    <cfset structDelete(VARIABLES,"seoTestScoreInvalidUrl")/>
    <cfloop array="#["unsupported","pass alert-danger"]#" index="seoTestScoreInvalidStatus">
        <cftry>
            <cfinclude template="portal/includes/seo_score_backend.cfm"/>
            <cfthrow type="SEOQueueTest" message="Invalid criterion status was accepted."/>
            <cfcatch type="SEOScoreContract"><cfset VARIABLES.seoTestScoreRejectedCount++/></cfcatch>
        </cftry>
    </cfloop>
    <cfoutput>SEO_SCORE_INVALID_DATA_PASSED:#VARIABLES.seoTestScoreRejectedCount#</cfoutput>
    <cfabort/>
</cfif>
<cfset URL.site=listFind("render-filtered,render-empty",VARIABLES.seoTestCase) ? "openresults" : "all"/>
<cfset URL.prioridade=VARIABLES.seoTestCase EQ "render-filtered" ? "p3" : (VARIABLES.seoTestCase EQ "render-empty" ? "p1" : "all")/>
<cfset URL.verificacao=VARIABLES.seoTestCase EQ "render-score-filtered" ? "error" : "all"/>
<!doctype html><html lang="pt-br"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Fila SEO — validação local isolada</title><link rel="stylesheet" href="/assets/css/mdb.min.css"/><link rel="stylesheet" href="/assets/css/business-ui.css"/></head>
<body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4">
<cfinclude template="portal/conteudo/seo.cfm"/>
</main><!-- SEO_QUEUE_RENDER_PASSED --></body></html>
<cfscript>
// Compare each source date in its HTML representation, without duplicating an entity decoder.
VARIABLES.seoTestAuditLabels = [];
for (seoTestRun in VARIABLES.seoScoreSnapshot.sites) {
    arrayAppend(VARIABLES.seoTestAuditLabels, encodeForHtml(seoTestRun.auditLabel));
}
VARIABLES.seoTestScoreStatusLabels = [];
for (seoTestStatus in VARIABLES.seoScoreStatuses) {
    arrayAppend(VARIABLES.seoTestScoreStatusLabels,{id=seoTestStatus.id,label=encodeForHtml(seoTestStatus.label),icon=encodeForHtml(seoTestStatus.icon)});
}
</cfscript>
<cfoutput><!-- SEO_QUEUE_RENDER_DATA:#toBase64(serializeJSON({auditLabels=VARIABLES.seoTestAuditLabels,runs=VARIABLES.seoScoreSnapshot.sites}),"UTF-8")# --></cfoutput>
<cfoutput><!-- SEO_SCORE_RENDER_DATA:#toBase64(serializeJSON({sites=VARIABLES.seoScoreSnapshot.sites,filter=VARIABLES.seoScoreFilter,statuses=VARIABLES.seoTestScoreStatusLabels}),"UTF-8")# --></cfoutput>
