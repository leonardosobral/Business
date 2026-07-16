<cfsetting requesttimeout="20" showdebugoutput="false"/>
<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../../includes/backend/agenda_service.cfm"/>

<cfparam name="URL.agenda" default=""/>
<cfparam name="URL.visao" default=""/>
<cfparam name="URL.token" default=""/>
<cfset VARIABLES.agendaXmlStartedAt = getTickCount()/>

<cfscript>
function agendaXmlError(required string message, numeric statusCode = 400, string statusText = "Bad Request") output="true" {
    cfheader(statuscode=arguments.statusCode, statustext=arguments.statusText);
    cfcontent(type="application/xml; charset=utf-8", reset="true");
    writeOutput('<?xml version="1.0" encoding="UTF-8"?><error><message>' & xmlFormat(arguments.message) & '</message></error>');
    abort;
}
</cfscript>

<cfif NOT agendaServiceTablesReady()>
    <cfset agendaServiceLogAccess(0, "xml", URL.visao, 503, 0, getTickCount() - VARIABLES.agendaXmlStartedAt)/>
    <cfset agendaXmlError("A estrutura de Agendas ainda nao foi criada.", 503, "Service Unavailable")/>
</cfif>

<cfset qAgendaXmlAgenda = agendaServiceGetAgendaByKey(trim(URL.agenda), true)/>
<cfif NOT qAgendaXmlAgenda.recordcount>
    <cfset agendaServiceLogAccess(0, "xml", URL.visao, 404, 0, getTickCount() - VARIABLES.agendaXmlStartedAt)/>
    <cfset agendaXmlError("Agenda nao encontrada ou indisponivel.", 404, "Not Found")/>
</cfif>

<cfif agendaServiceRateLimitExceeded(qAgendaXmlAgenda.id_agenda)>
    <cfset agendaServiceLogAccess(qAgendaXmlAgenda.id_agenda, "xml", URL.visao, 429, 0, getTickCount() - VARIABLES.agendaXmlStartedAt)/>
    <cfheader name="Retry-After" value="60"/>
    <cfset agendaXmlError("Limite temporario de requisicoes excedido.", 429, "Too Many Requests")/>
</cfif>

<cfset VARIABLES.agendaXmlToken = len(trim(URL.token)) ? trim(URL.token) : agendaServiceRequestHeader("X-RR-Agenda-Token")/>
<cfif NOT agendaServiceTokenValid(qAgendaXmlAgenda.id_agenda, VARIABLES.agendaXmlToken)>
    <cfset agendaServiceLogAccess(qAgendaXmlAgenda.id_agenda, "xml", URL.visao, 401, 0, getTickCount() - VARIABLES.agendaXmlStartedAt)/>
    <cfset agendaXmlError("Credencial XML invalida ou ausente.", 401, "Unauthorized")/>
</cfif>

<cfset VARIABLES.agendaXmlSource = agendaServiceRequestSource()/>
<cfif len(VARIABLES.agendaXmlSource.host) AND NOT agendaServiceHostAllowed(qAgendaXmlAgenda.dominio_permitido, agendaServiceNormalizeBoolean(qAgendaXmlAgenda.permitir_subdominios), VARIABLES.agendaXmlSource.host)>
    <cfset agendaServiceLogAccess(qAgendaXmlAgenda.id_agenda, "xml", URL.visao, 403, 0, getTickCount() - VARIABLES.agendaXmlStartedAt)/>
    <cfset agendaXmlError("Este dominio nao esta autorizado a consumir a Agenda.", 403, "Forbidden")/>
</cfif>

<cfset VARIABLES.agendaXmlView = agendaServiceNormalizeView(URL.visao, "futuros")/>
<cfset qAgendaXmlEvents = agendaServiceResolveEvents(qAgendaXmlAgenda.id_agenda, VARIABLES.agendaXmlView, qAgendaXmlAgenda.limite_eventos)/>
<cfset VARIABLES.agendaXmlItems = agendaServiceEventsToArray(qAgendaXmlEvents)/>
<cfset VARIABLES.agendaXmlTheme = agendaServiceNormalizeTheme(agendaServiceQueryValue(qAgendaXmlAgenda, "tema_embed", 1))/>
<cfset VARIABLES.agendaXmlDateColor = agendaServiceNormalizeHexColor(agendaServiceQueryValue(qAgendaXmlAgenda, "cor_card_data", 1))/>
<cfset VARIABLES.agendaXmlDateTextColor = agendaServiceContrastColor(VARIABLES.agendaXmlDateColor)/>
<cfset VARIABLES.agendaXmlCardFont = agendaServiceNormalizeCardFont(agendaServiceQueryValue(qAgendaXmlAgenda, "fonte_cards", 1))/>
<cfset VARIABLES.agendaXmlCardRadius = agendaServiceNormalizeCardRadius(agendaServiceQueryValue(qAgendaXmlAgenda, "raio_cards", 1))/>
<cfset VARIABLES.agendaXmlOutput = '<?xml version="1.0" encoding="UTF-8"?>' & chr(10)/>
<cfset VARIABLES.agendaXmlOutput &= '<rrAgenda xmlns="https://roadrunners.run/schemas/agenda/v1" version="1.0" generatedAt="' & xmlFormat(dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss")) & '" view="' & xmlFormat(VARIABLES.agendaXmlView) & '">' & chr(10)/>
<cfset VARIABLES.agendaXmlOutput &= '  <metadata><id>' & qAgendaXmlAgenda.id_agenda & '</id><key>' & xmlFormat(qAgendaXmlAgenda.chave_publica) & '</key><name>' & xmlFormat(qAgendaXmlAgenda.nome) & '</name><mode>' & xmlFormat(qAgendaXmlAgenda.modo) & '</mode><owner id="' & qAgendaXmlAgenda.id_usuario & '">' & xmlFormat(qAgendaXmlAgenda.usuario_nome) & '</owner><appearance theme="' & xmlFormat(VARIABLES.agendaXmlTheme) & '" background="transparent" dateCardColor="' & xmlFormat(VARIABLES.agendaXmlDateColor) & '" dateTextColor="' & xmlFormat(VARIABLES.agendaXmlDateTextColor) & '" cardFont="' & xmlFormat(VARIABLES.agendaXmlCardFont) & '" cardRadius="' & xmlFormat(VARIABLES.agendaXmlCardRadius) & '"/></metadata>' & chr(10)/>
<cfset VARIABLES.agendaXmlOutput &= '  <events total="' & arrayLen(VARIABLES.agendaXmlItems) & '">' & chr(10)/>

<cfloop array="#VARIABLES.agendaXmlItems#" index="agendaXmlEvent">
    <cfset VARIABLES.agendaXmlOutput &= '    <event id="' & agendaXmlEvent.id & '"><name>' & xmlFormat(agendaXmlEvent.name) & '</name><slug>' & xmlFormat(agendaXmlEvent.slug) & '</slug><url>' & xmlFormat(agendaXmlEvent.url) & '</url><startDate>' & xmlFormat(agendaXmlEvent.startDate) & '</startDate><endDate>' & xmlFormat(agendaXmlEvent.endDate) & '</endDate><type>' & xmlFormat(agendaXmlEvent.type) & '</type>'/>
    <cfset VARIABLES.agendaXmlOutput &= '<location><city>' & xmlFormat(agendaXmlEvent.location.city) & '</city><state>' & xmlFormat(agendaXmlEvent.location.state) & '</state><country>' & xmlFormat(agendaXmlEvent.location.country) & '</country></location>'/>
    <cfset VARIABLES.agendaXmlOutput &= '<distances>'/>
    <cfloop array="#agendaXmlEvent.distances#" index="agendaXmlDistance">
        <cfset VARIABLES.agendaXmlOutput &= '<distance unit="' & xmlFormat(agendaXmlDistance.unidade & "") & '" type="' & xmlFormat(agendaXmlDistance.tipo & "") & '">' & xmlFormat(agendaXmlDistance.distancia & "") & '</distance>'/>
    </cfloop>
    <cfset VARIABLES.agendaXmlOutput &= '</distances><image>' & xmlFormat(agendaXmlEvent.imageUrl) & '</image><results published="' & (agendaXmlEvent.results.published ? "true" : "false") & '" finishers="' & agendaXmlEvent.results.finishers & '"><url>' & xmlFormat(agendaXmlEvent.results.url) & '</url></results></event>' & chr(10)/>
</cfloop>

<cfset VARIABLES.agendaXmlOutput &= '  </events>' & chr(10) & '</rrAgenda>'/>
<cfset VARIABLES.agendaXmlEtag = 'W/"' & lCase(hash(qAgendaXmlAgenda.versao & ":" & VARIABLES.agendaXmlView & ":" & serializeJSON(VARIABLES.agendaXmlItems), "SHA-256")) & '"'/>

<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfheader name="Cache-Control" value="private, max-age=120"/>
<cfheader name="ETag" value="#VARIABLES.agendaXmlEtag#"/>
<cfif agendaServiceRequestHeader("If-None-Match") EQ VARIABLES.agendaXmlEtag>
    <cfset agendaServiceLogAccess(qAgendaXmlAgenda.id_agenda, "xml", VARIABLES.agendaXmlView, 304, arrayLen(VARIABLES.agendaXmlItems), getTickCount() - VARIABLES.agendaXmlStartedAt)/>
    <cfheader statuscode="304" statustext="Not Modified"/>
    <cfcontent reset="true"/>
    <cfabort/>
</cfif>

<cfset agendaServiceLogAccess(qAgendaXmlAgenda.id_agenda, "xml", VARIABLES.agendaXmlView, 200, arrayLen(VARIABLES.agendaXmlItems), getTickCount() - VARIABLES.agendaXmlStartedAt)/>
<cfcontent type="application/xml; charset=utf-8" reset="true"/>
<cfoutput>#VARIABLES.agendaXmlOutput#</cfoutput>
