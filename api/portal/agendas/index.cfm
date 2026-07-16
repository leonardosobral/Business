<cfsetting requesttimeout="20" showdebugoutput="false"/>
<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../../includes/backend/agenda_service.cfm"/>

<cfparam name="URL.agenda" default=""/>
<cfparam name="URL.visao" default=""/>
<cfset VARIABLES.agendaApiStartedAt = getTickCount()/>

<cfscript>
function agendaApiWrite(required struct payload, numeric statusCode = 200, string statusText = "OK") output="true" {
    cfheader(statuscode=arguments.statusCode, statustext=arguments.statusText);
    cfcontent(type="application/json; charset=utf-8", reset="true");
    writeOutput(serializeJSON(arguments.payload));
    abort;
}
</cfscript>

<cfif NOT agendaServiceTablesReady()>
    <cfset agendaServiceLogAccess(0, "json", URL.visao, 503, 0, getTickCount() - VARIABLES.agendaApiStartedAt)/>
    <cfset agendaApiWrite({success=false, status="tables_missing", message="A estrutura de Agendas ainda nao foi criada."}, 503, "Service Unavailable")/>
</cfif>

<cfset VARIABLES.agendaApiKey = trim(URL.agenda)/>
<cfset qAgendaApiAgenda = agendaServiceGetAgendaByKey(VARIABLES.agendaApiKey, true)/>

<cfif NOT qAgendaApiAgenda.recordcount>
    <cfset agendaServiceLogAccess(0, "json", URL.visao, 404, 0, getTickCount() - VARIABLES.agendaApiStartedAt)/>
    <cfset agendaApiWrite({success=false, status="not_found", message="Agenda nao encontrada ou indisponivel."}, 404, "Not Found")/>
</cfif>

<cfif agendaServiceRateLimitExceeded(qAgendaApiAgenda.id_agenda)>
    <cfset agendaServiceLogAccess(qAgendaApiAgenda.id_agenda, "json", URL.visao, 429, 0, getTickCount() - VARIABLES.agendaApiStartedAt)/>
    <cfheader name="Retry-After" value="60"/>
    <cfset agendaApiWrite({success=false, status="rate_limited", message="Limite temporario de requisicoes excedido."}, 429, "Too Many Requests")/>
</cfif>

<cfset VARIABLES.agendaApiSource = agendaServiceRequestSource()/>
<cfset VARIABLES.agendaApiAllowed = agendaServiceHostAllowed(qAgendaApiAgenda.dominio_permitido, agendaServiceNormalizeBoolean(qAgendaApiAgenda.permitir_subdominios), VARIABLES.agendaApiSource.host)/>

<cfif NOT VARIABLES.agendaApiAllowed>
    <cfset agendaServiceLogAccess(qAgendaApiAgenda.id_agenda, "json", URL.visao, 403, 0, getTickCount() - VARIABLES.agendaApiStartedAt)/>
    <cfset agendaApiWrite({success=false, status="domain_denied", message="Este dominio nao esta autorizado a consumir a Agenda."}, 403, "Forbidden")/>
</cfif>

<cfif len(VARIABLES.agendaApiSource.origin)>
    <cfheader name="Access-Control-Allow-Origin" value="#VARIABLES.agendaApiSource.origin#"/>
    <cfheader name="Vary" value="Origin"/>
</cfif>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfheader name="Referrer-Policy" value="strict-origin-when-cross-origin"/>
<cfheader name="Cache-Control" value="public, max-age=120, stale-while-revalidate=300"/>

<cfset VARIABLES.agendaApiView = agendaServiceNormalizeView(URL.visao, "futuros")/>
<cfset qAgendaApiEvents = agendaServiceResolveEvents(qAgendaApiAgenda.id_agenda, VARIABLES.agendaApiView, qAgendaApiAgenda.limite_eventos)/>
<cfset VARIABLES.agendaApiItems = agendaServiceEventsToArray(qAgendaApiEvents)/>
<cfset VARIABLES.agendaApiPayload = {
    success=true,
    status="ok",
    version="1.0",
    generatedAt=dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss"),
    agenda={
        id=qAgendaApiAgenda.id_agenda,
        key=qAgendaApiAgenda.chave_publica,
        name=qAgendaApiAgenda.nome,
        description=agendaServiceQueryValue(qAgendaApiAgenda, "descricao", 1) & "",
        mode=qAgendaApiAgenda.modo,
        view=VARIABLES.agendaApiView,
        owner={id=qAgendaApiAgenda.id_usuario, name=qAgendaApiAgenda.usuario_nome},
        appearance={
            theme=agendaServiceNormalizeTheme(agendaServiceQueryValue(qAgendaApiAgenda, "tema_embed", 1)),
            background="transparent",
            dateCardColor=agendaServiceNormalizeHexColor(agendaServiceQueryValue(qAgendaApiAgenda, "cor_card_data", 1)),
            dateTextColor=agendaServiceContrastColor(agendaServiceQueryValue(qAgendaApiAgenda, "cor_card_data", 1)),
            cardFont=agendaServiceNormalizeCardFont(agendaServiceQueryValue(qAgendaApiAgenda, "fonte_cards", 1)),
            cardRadius=agendaServiceNormalizeCardRadius(agendaServiceQueryValue(qAgendaApiAgenda, "raio_cards", 1))
        }
    },
    total=arrayLen(VARIABLES.agendaApiItems),
    events=VARIABLES.agendaApiItems
}/>
<cfset VARIABLES.agendaApiSerialized = serializeJSON(VARIABLES.agendaApiPayload)/>
<cfset VARIABLES.agendaApiEtag = 'W/"' & lCase(hash(qAgendaApiAgenda.versao & ":" & VARIABLES.agendaApiView & ":" & serializeJSON(VARIABLES.agendaApiItems), "SHA-256")) & '"'/>
<cfheader name="ETag" value="#VARIABLES.agendaApiEtag#"/>

<cfif agendaServiceRequestHeader("If-None-Match") EQ VARIABLES.agendaApiEtag>
    <cfset agendaServiceLogAccess(qAgendaApiAgenda.id_agenda, "json", VARIABLES.agendaApiView, 304, arrayLen(VARIABLES.agendaApiItems), getTickCount() - VARIABLES.agendaApiStartedAt)/>
    <cfheader statuscode="304" statustext="Not Modified"/>
    <cfcontent reset="true"/>
    <cfabort/>
</cfif>

<cfset agendaServiceLogAccess(qAgendaApiAgenda.id_agenda, "json", VARIABLES.agendaApiView, 200, arrayLen(VARIABLES.agendaApiItems), getTickCount() - VARIABLES.agendaApiStartedAt)/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfoutput>#VARIABLES.agendaApiSerialized#</cfoutput>
