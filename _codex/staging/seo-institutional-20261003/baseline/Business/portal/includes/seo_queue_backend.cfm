<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfabort/>
</cfif>
<cfif structKeyExists(CGI, "request_method") AND compareNoCase(CGI.request_method, "GET") NEQ 0>
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfheader name="Allow" value="GET"/>
    <cfabort/>
</cfif>

<cfinclude template="seo_queue_data.cfm"/>

<cfscript>
VARIABLES.seoQueueSiteFilter = "all";
VARIABLES.seoQueuePriorityFilter = "all";

if (structKeyExists(URL, "site") AND isSimpleValue(URL.site)) {
    VARIABLES.seoQueueSiteInput = lCase(trim(URL.site & ""));
    if (listFind("all,roadrunners,openresults", VARIABLES.seoQueueSiteInput)) {
        VARIABLES.seoQueueSiteFilter = VARIABLES.seoQueueSiteInput;
    }
}
if (structKeyExists(URL, "prioridade") AND isSimpleValue(URL.prioridade)) {
    VARIABLES.seoQueuePriorityInput = lCase(trim(URL.prioridade & ""));
    if (listFind("all,p1,p2,p3,review", VARIABLES.seoQueuePriorityInput)) {
        VARIABLES.seoQueuePriorityFilter = VARIABLES.seoQueuePriorityInput;
    }
}

// Totais globais não mudam com os filtros; o item compartilhado conta uma vez.
VARIABLES.seoQueueTotal = arrayLen(VARIABLES.seoQueueSnapshot.items);
VARIABLES.seoQueueOpenTotal = 0;
VARIABLES.seoQueueResolvedTotal = 0;
VARIABLES.seoQueueHighPriorityTotal = 0;
VARIABLES.seoQueueItems = [];

for (VARIABLES.seoQueueItemIndex = 1; VARIABLES.seoQueueItemIndex LTE VARIABLES.seoQueueTotal; VARIABLES.seoQueueItemIndex++) {
    VARIABLES.seoQueueItem = VARIABLES.seoQueueSnapshot.items[VARIABLES.seoQueueItemIndex];
    VARIABLES.seoQueueItemResolved = structKeyExists(VARIABLES.seoQueueItem, "resolved")
        AND isBoolean(VARIABLES.seoQueueItem.resolved) AND VARIABLES.seoQueueItem.resolved;
    if (VARIABLES.seoQueueItemResolved) {
        VARIABLES.seoQueueResolvedTotal++;
    } else {
        VARIABLES.seoQueueOpenTotal++;
    }
    if (VARIABLES.seoQueueItem.priority EQ "p1" AND NOT VARIABLES.seoQueueItemResolved) {
        VARIABLES.seoQueueHighPriorityTotal++;
    }

    // A curadoria futura também permanece limitada aos domínios públicos previstos.
    for (VARIABLES.seoQueueUrlIndex = 1; VARIABLES.seoQueueUrlIndex LTE arrayLen(VARIABLES.seoQueueItem.urls); VARIABLES.seoQueueUrlIndex++) {
        VARIABLES.seoQueuePublicUrl = VARIABLES.seoQueueItem.urls[VARIABLES.seoQueueUrlIndex].url;
        if (NOT reFindNoCase("^https://(roadrunners[.]run|openresults[.]run)/", VARIABLES.seoQueuePublicUrl)
            OR reFind("[\x00-\x20\x7F\\]", VARIABLES.seoQueuePublicUrl)) {
            throw(type = "SEOQueueContract", message = "A fila SEO contém uma URL pública inválida.");
        }
    }

    VARIABLES.seoQueueMatchesSite = VARIABLES.seoQueueSiteFilter EQ "all"
        OR arrayFindNoCase(VARIABLES.seoQueueItem.sites, VARIABLES.seoQueueSiteFilter) GT 0;
    VARIABLES.seoQueueMatchesPriority = VARIABLES.seoQueuePriorityFilter EQ "all"
        OR VARIABLES.seoQueueItem.priority EQ VARIABLES.seoQueuePriorityFilter;
    if (VARIABLES.seoQueueMatchesSite AND VARIABLES.seoQueueMatchesPriority) {
        arrayAppend(VARIABLES.seoQueueItems, VARIABLES.seoQueueItem);
    }
}
</cfscript>
