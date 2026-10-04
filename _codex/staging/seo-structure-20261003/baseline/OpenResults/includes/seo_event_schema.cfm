<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
    <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<!--- Public event metadata only: dates remain date-only when no start time is known. --->
<cfscript>
VARIABLES.eventSchemaJsonLd = "";
if (qEvento.recordCount EQ 1 AND isDate(qEvento.data_inicial)) {
    seoEvent = structNew("ordered");
    seoEvent["@context"] = "https://schema.org";
    seoEvent["@type"] = "SportsEvent";
    seoEvent["@id"] = VARIABLES.canonical;
    seoEvent["url"] = VARIABLES.canonical;
    seoEvent["name"] = qEvento.nome_evento & "";
    seoEvent["description"] = qEvento.nome_evento & " em " & qEvento.cidade & "/" & qEvento.estado & ". " & VARIABLES.eventoStatusTitulo & ". " & VARIABLES.eventoStatusDescricao;
    seoEvent["startDate"] = dateFormat(qEvento.data_inicial, "yyyy-mm-dd");
    if (isDate(qEvento.data_final) AND dateCompare(qEvento.data_final, qEvento.data_inicial, "d") GTE 0) {
        seoEvent["endDate"] = dateFormat(qEvento.data_final, "yyyy-mm-dd");
    }
    if (lCase(trim(qEvento.status_evento & "")) EQ "cancelado") seoEvent["eventStatus"] = "https://schema.org/EventCancelled";
    if (len(trim(qEvento.cidade & ""))) {
        seoPlace = structNew("ordered");
        seoPlace["@type"] = "Place";
        seoPlace["name"] = trim(qEvento.cidade & "") & (len(trim(qEvento.estado & "")) ? ", " & trim(qEvento.estado & "") : "");
        seoAddress = structNew("ordered");
        seoAddress["@type"] = "PostalAddress";
        seoAddress["addressLocality"] = trim(qEvento.cidade & "");
        if (len(trim(qEvento.estado & ""))) seoAddress["addressRegion"] = trim(qEvento.estado & "");
        if (len(trim(qEvento.pais & ""))) seoAddress["addressCountry"] = trim(qEvento.pais & "");
        seoPlace["address"] = seoAddress;
        seoEvent["location"] = seoPlace;
    }
    for (seoRow = 1; seoRow LTE qFornecedores.recordCount; seoRow++) {
        if (qFornecedores.id_fornecedor_tipo[seoRow] EQ 1 AND len(trim(qFornecedores.nome_fornecedor[seoRow] & ""))) {
            seoOrganizer = structNew("ordered");
            seoOrganizer["@type"] = "Organization";
            seoOrganizer["name"] = qFornecedores.nome_fornecedor[seoRow] & "";
            seoEvent["organizer"] = seoOrganizer;
            break;
        }
    }
    // Escaping '<' prevents event text from closing the script element.
    VARIABLES.eventSchemaJsonLd = replace(serializeJSON(seoEvent), "<", "\u003C", "all");
}
</cfscript>
