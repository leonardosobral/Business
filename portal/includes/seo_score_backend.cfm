<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfabort/>
</cfif>
<cfif structKeyExists(CGI, "request_method") AND compareNoCase(CGI.request_method, "GET") NEQ 0>
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfheader name="Allow" value="GET"/>
    <cfabort/>
</cfif>
<cfinclude template="seo_score_data.cfm"/>
<cfscript>
VARIABLES.seoScoreFilter = "all";
VARIABLES.seoScoreStatuses = [
    {id="error",label="Erro",icon="×"},
    {id="warning",label="Atenção",icon="!"},
    {id="pass",label="Certo",icon="✓"},
    {id="unknown",label="Não medido",icon="—"}
];
if (structKeyExists(URL,"verificacao") AND isSimpleValue(URL.verificacao)) {
    VARIABLES.seoScoreFilterInput = lCase(trim(URL.verificacao & ""));
    if (listFind("all,pass,warning,error,unknown", VARIABLES.seoScoreFilterInput)) {
        VARIABLES.seoScoreFilter = VARIABLES.seoScoreFilterInput;
    }
}

// Filtros alteram apenas a lista visível. Nota, distribuição e histórico retêm a auditoria inteira.
VARIABLES.seoScoreVisibleTotal = 0;
for (VARIABLES.seoScoreSite in VARIABLES.seoScoreSnapshot.sites) {
    if (NOT listFind("roadrunners,openresults",VARIABLES.seoScoreSite.id)) {
        throw(type="SEOScoreContract",message="Site inválido no relatório SEO.");
    }
    VARIABLES.seoScoreSite.visibleCriteria = [];
    for (VARIABLES.seoScoreCriterion in VARIABLES.seoScoreSite.criteria) {
        if (NOT listFind("pass,warning,error,unknown",VARIABLES.seoScoreCriterion.status)
            OR NOT reFind("^[a-z][a-z0-9_-]*$",VARIABLES.seoScoreCriterion.id)) {
            throw(type="SEOScoreContract",message="Verificação inválida no relatório SEO.");
        }
        for (VARIABLES.seoScoreCaseStatus in ["pass","warning","error","unknown"]) {
            for (VARIABLES.seoScoreCaseUrl in VARIABLES.seoScoreCriterion.cases[VARIABLES.seoScoreCaseStatus]) {
                if (NOT reFindNoCase("^https://(roadrunners[.]run|openresults[.]run)/",VARIABLES.seoScoreCaseUrl)
                    OR reFind("[\x00-\x20\x7F\\]",VARIABLES.seoScoreCaseUrl)) {
                    throw(type="SEOScoreContract",message="URL pública inválida no relatório SEO.");
                }
            }
        }
        if (VARIABLES.seoScoreFilter EQ "all" OR VARIABLES.seoScoreCriterion.status EQ VARIABLES.seoScoreFilter) {
            arrayAppend(VARIABLES.seoScoreSite.visibleCriteria,VARIABLES.seoScoreCriterion);
            VARIABLES.seoScoreVisibleTotal++;
        }
    }
    VARIABLES.seoScoreSite.visibleCount = arrayLen(VARIABLES.seoScoreSite.visibleCriteria);
}
</cfscript>
