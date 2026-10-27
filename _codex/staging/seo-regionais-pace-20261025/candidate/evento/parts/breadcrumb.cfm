<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
VARIABLES.eventBreadcrumbLabels = {
    "pt-br"={home="Início", navigation="Caminho de navegação"},
    en={home="Home", navigation="Breadcrumb"},
    es={home="Inicio", navigation="Ruta de navegación"}
};
VARIABLES.eventBreadcrumbLang = structKeyExists(REQUEST, "lang") ? lCase(REQUEST.lang) : "pt-br";
if (!structKeyExists(VARIABLES.eventBreadcrumbLabels, VARIABLES.eventBreadcrumbLang)) VARIABLES.eventBreadcrumbLang = "pt-br";
VARIABLES.eventBreadcrumbText = VARIABLES.eventBreadcrumbLabels[VARIABLES.eventBreadcrumbLang];
VARIABLES.eventBreadcrumbs = [{"@type"="ListItem", position=1, name=VARIABLES.eventBreadcrumbText.home, item=REQUEST.i18nBuildAbsoluteUrl("home")}];
VARIABLES.eventBreadcrumbUf = uCase(trim(qEvento.estado[1] & ""));
// Regional pages currently exist only in Portuguese; never invent translated routes or infer the country.
if (compareNoCase(trim(qEvento.pais[1] & ""), "BR") EQ 0
    AND listFind("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO", VARIABLES.eventBreadcrumbUf)) {
    VARIABLES.eventBreadcrumbStateName = new services.LocationResolver().getEstadoNome(VARIABLES.eventBreadcrumbUf);
    arrayAppend(VARIABLES.eventBreadcrumbs, {"@type"="ListItem", position=2,
        name=VARIABLES.eventBreadcrumbStateName,
        item=REQUEST.currentBaseUrl & "/estado/" & lCase(VARIABLES.eventBreadcrumbUf) & "/"});
    if (listFindNoCase(qEvento.columnList,"tag_cidade") && reFind("^[a-z0-9-]+$",qEvento.tag_cidade[1] & "") && len(trim(qEvento.cidade[1] & ""))) {
        arrayAppend(VARIABLES.eventBreadcrumbs, {"@type"="ListItem", position=arrayLen(VARIABLES.eventBreadcrumbs)+1,
            name=trim(qEvento.cidade[1]), item=REQUEST.currentBaseUrl & "/estado/" & lCase(VARIABLES.eventBreadcrumbUf) & "/" & qEvento.tag_cidade[1] & "/"});
    }
}
arrayAppend(VARIABLES.eventBreadcrumbs, {"@type"="ListItem", position=arrayLen(VARIABLES.eventBreadcrumbs)+1,
    name=qEvento.nome_evento[1] & "", item=VARIABLES.canonical});
VARIABLES.eventBreadcrumbJson = serializeJSON({"@context"="https://schema.org", "@type"="BreadcrumbList", itemListElement=VARIABLES.eventBreadcrumbs});
</cfscript>
<cfoutput>
<nav class="event-breadcrumb" aria-label="#encodeForHTMLAttribute(VARIABLES.eventBreadcrumbText.navigation)#">
    <ol><cfloop array="#VARIABLES.eventBreadcrumbs#" index="eventBreadcrumb">
        <li><cfif eventBreadcrumb.position EQ arrayLen(VARIABLES.eventBreadcrumbs)><span class="event-breadcrumb-current" aria-current="page" title="#encodeForHTMLAttribute(eventBreadcrumb.name)#">#encodeForHTML(eventBreadcrumb.name)#</span><cfelse><a href="#encodeForHTMLAttribute(eventBreadcrumb.item)#"<cfif eventBreadcrumb.position GT 1> hreflang="pt-BR"</cfif>><cfif eventBreadcrumb.position EQ 1><i class="fa-solid fa-house event-breadcrumb-home-icon" aria-hidden="true"></i><span class="event-breadcrumb-home-label">#encodeForHTML(eventBreadcrumb.name)#</span><cfelse>#encodeForHTML(eventBreadcrumb.name)#</cfif></a></cfif></li>
    </cfloop></ol>
</nav>
<script type="application/ld+json">#replace(VARIABLES.eventBreadcrumbJson, "<", "\u003c", "all")#</script>
</cfoutput>
