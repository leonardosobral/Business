<cfparam name="URL.route_geometry" default=""/>
<cfif URL.route_geometry EQ "1">
    <!---
        Endpoint alternativo no proprio caminho do evento. Isso evita depender
        de uma nova regra de roteamento para /api e funciona sem reiniciar o CF.
    --->
    <cfinclude template="../api/events/route-geometry.cfm"/>
    <cfabort/>
</cfif>

<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TERMO DE BUSCA --->
<cfif isDefined("URL.termo") AND isDefined("URL.escopo") AND URL.escopo EQ "site">
    <cfset VARIABLES.eventSearchRedirectPath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("search") : "/busca/"/>
    <cflocation addtoken="false" url="#VARIABLES.eventSearchRedirectPath#?termo=#URL.termo#&redirect=true"/>
</cfif>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/evento/"/>
<cfset VARIABLES.routeKey = "event" />

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_feed.cfm"/>
<cfif fileExists(expandPath("/config/event-route-mapbox-runtime.cfm"))>
    <cfinclude template="../config/event-route-mapbox-runtime.cfm"/>
<cfelseif
    NOT structKeyExists(APPLICATION, "eventRouteMapbox")
    OR NOT isStruct(APPLICATION.eventRouteMapbox)
    OR NOT structKeyExists(APPLICATION.eventRouteMapbox, "enabled")
    OR NOT structKeyExists(APPLICATION.eventRouteMapbox, "publicToken")
    OR NOT structKeyExists(APPLICATION.eventRouteMapbox, "storagePath")
    OR NOT structKeyExists(APPLICATION.eventRouteMapbox, "libraryVersion")
>
    <!--- Um deploy parcial nao deve impedir a pagina do evento de carregar. --->
    <cfset APPLICATION.eventRouteMapbox = {
        "enabled" = false,
        "publicToken" = "",
        "storagePath" = "",
        "libraryVersion" = "3.25.0"
    }/>
</cfif>
<cfinclude template="../includes/backend/backend_evento.cfm"/>

<!--- META INFO --->
<cfset REQUEST.currentRouteKey = VARIABLES.routeKey />
<cfset REQUEST.currentRouteParams = { "tag" = URL.tag } />
<cfset eventCatalog = REQUEST.i18n.event />
<cfset eventActions = eventCatalog.actions />
<cfset eventMetaCatalog = eventCatalog.meta />
<cfset eventSections = eventCatalog.sections />
<cfset eventDescriptionCatalog = eventCatalog.description />
<cfset eventSuppliersCatalog = eventCatalog.suppliers />
<cfset VARIABLES.eventRoutes = [] />
<cfset VARIABLES.eventRouteMapboxConfigured = structKeyExists(APPLICATION, "eventRouteMapbox")
    AND isStruct(APPLICATION.eventRouteMapbox)
    AND APPLICATION.eventRouteMapbox.enabled />
<cfset VARIABLES.eventRouteHasMapbox = false />
<cfif len(trim(qEvento.lista_percursos & "")) AND isJSON(qEvento.lista_percursos)>
    <cfset VARIABLES.eventRoutes = deserializeJSON(qEvento.lista_percursos) />
</cfif>
<cfif VARIABLES.eventRouteMapboxConfigured AND isArray(VARIABLES.eventRoutes)>
    <cfloop array="#VARIABLES.eventRoutes#" item="VARIABLES.eventRouteCandidate">
        <cfif
            structKeyExists(VARIABLES.eventRouteCandidate, "arquivo_percurso")
            AND !isNull(VARIABLES.eventRouteCandidate.arquivo_percurso)
            AND isStruct(VARIABLES.eventRouteCandidate.arquivo_percurso)
            AND structKeyExists(VARIABLES.eventRouteCandidate.arquivo_percurso, "disponivel")
            AND VARIABLES.eventRouteCandidate.arquivo_percurso.disponivel
            AND structKeyExists(VARIABLES.eventRouteCandidate.arquivo_percurso, "geometria_url")
            AND len(trim(VARIABLES.eventRouteCandidate.arquivo_percurso.geometria_url & ""))
        >
            <cfset VARIABLES.eventRouteHasMapbox = true />
            <cfbreak />
        </cfif>
    </cfloop>
</cfif>
<cfset VARIABLES.eventRouteMapboxAssets = VARIABLES.eventRouteHasMapbox />
<cfscript>
VARIABLES.eventLocationMapboxConfigured = structKeyExists(APPLICATION, "eventRouteMapbox")
    && isStruct(APPLICATION.eventRouteMapbox)
    && structKeyExists(APPLICATION.eventRouteMapbox, "publicToken")
    && left(trim(APPLICATION.eventRouteMapbox.publicToken & ""), 3) == "pk.";
VARIABLES.eventLocationCoordinates = [];
VARIABLES.eventLocationCoordinateParts = listToArray(trim(qEvento.coordenadas & ""), ",", false, true);

if (arrayLen(VARIABLES.eventLocationCoordinateParts) >= 2) {
    VARIABLES.eventLocationLatitudeRaw = trim(VARIABLES.eventLocationCoordinateParts[1] & "");
    VARIABLES.eventLocationLongitudeRaw = trim(VARIABLES.eventLocationCoordinateParts[2] & "");

    if (
        isValid("numeric", VARIABLES.eventLocationLatitudeRaw)
        && isValid("numeric", VARIABLES.eventLocationLongitudeRaw)
        && abs(val(VARIABLES.eventLocationLatitudeRaw)) <= 90
        && abs(val(VARIABLES.eventLocationLongitudeRaw)) <= 180
    ) {
        // Mapbox usa a ordem longitude, latitude.
        VARIABLES.eventLocationCoordinates = [
            val(VARIABLES.eventLocationLongitudeRaw),
            val(VARIABLES.eventLocationLatitudeRaw)
        ];
    }
}

VARIABLES.eventLocationHasData = arrayLen(VARIABLES.eventLocationCoordinates) == 2
    || len(trim(qEvento.endereco & ""))
    || len(trim(qEvento.cidade & ""));
VARIABLES.eventLocationAssets = VARIABLES.eventLocationHasData;
VARIABLES.eventLocationMapboxAssets = VARIABLES.eventLocationMapboxConfigured
    && VARIABLES.eventLocationHasData;
VARIABLES.eventMapboxAssets = VARIABLES.eventRouteMapboxAssets
    || VARIABLES.eventLocationMapboxAssets;
</cfscript>
<cfset eventCouponRichLabel = "" />
<cfset VARIABLES.eventFocoBadge = "" />
<cfset VARIABLES.eventFocoValor = "" />
<cfset VARIABLES.eventFocoGalleryToken = "" />
<cfset VARIABLES.eventFocoGalleries = [] />
<cfif len(trim(qEvento.badges))>
    <cfloop array="#deserializeJSON(qEvento.badges)#" item="badge">
        <cfif structKeyExists(badge, "badge") AND badge.badge EQ "foco">
            <cfset VARIABLES.eventFocoBadge = badge />
        </cfif>
    </cfloop>
</cfif>
<cfif isStruct(VARIABLES.eventFocoBadge)>
    <cfif structKeyExists(VARIABLES.eventFocoBadge, "valor_badge") AND len(trim(VARIABLES.eventFocoBadge.valor_badge & ""))>
        <cfset VARIABLES.eventFocoValor = trim(VARIABLES.eventFocoBadge.valor_badge & "") />
    </cfif>
    <cfif structKeyExists(VARIABLES.eventFocoBadge, "complemento_badge") AND len(trim(VARIABLES.eventFocoBadge.complemento_badge & "")) AND trim(VARIABLES.eventFocoBadge.complemento_badge & "") NEQ "numero">
        <cfset VARIABLES.eventFocoGalleryToken = trim(VARIABLES.eventFocoBadge.complemento_badge & "") />
    <cfelseif len(trim(VARIABLES.eventFocoValor))>
        <cfset VARIABLES.eventFocoGalleryToken = VARIABLES.eventFocoValor />
    </cfif>
</cfif>
<cfif isDefined("qEventoFocoVinculos") AND qEventoFocoVinculos.recordCount>
    <cfloop query="qEventoFocoVinculos">
        <cfset VARIABLES.eventFocoPayload = {} />
        <cfif len(trim(qEventoFocoVinculos.payload & "")) AND isJSON(trim(qEventoFocoVinculos.payload & ""))>
            <cfset VARIABLES.eventFocoPayload = deserializeJSON(trim(qEventoFocoVinculos.payload & "")) />
        </cfif>
        <cfset VARIABLES.eventFocoPublicUrl = "" />
        <cfset VARIABLES.eventFocoPath = trim(qEventoFocoVinculos.competition_path & "") />
        <cfif !len(VARIABLES.eventFocoPath) AND structKeyExists(VARIABLES.eventFocoPayload, "competition_path")>
            <cfset VARIABLES.eventFocoPath = trim(VARIABLES.eventFocoPayload.competition_path & "") />
        </cfif>
        <cfif !len(VARIABLES.eventFocoPath) AND len(trim(qEventoFocoVinculos.identification_type & "")) AND trim(qEventoFocoVinculos.identification_type & "") NEQ "numero">
            <cfset VARIABLES.eventFocoPath = trim(qEventoFocoVinculos.identification_type & "") />
        </cfif>
        <cfset VARIABLES.eventFocoCompetitionId = trim(qEventoFocoVinculos.competition_id & "") />
        <cfif len(VARIABLES.eventFocoPath)>
            <cfif left(lCase(VARIABLES.eventFocoPath), 4) EQ "http">
                <cfset VARIABLES.eventFocoPublicUrl = VARIABLES.eventFocoPath />
            <cfelseif left(VARIABLES.eventFocoPath, 1) EQ "/">
                <cfset VARIABLES.eventFocoPublicUrl = "https://www.focoradical.com.br#VARIABLES.eventFocoPath#" />
            <cfelseif left(lCase(VARIABLES.eventFocoPath), 6) EQ "prova/">
                <cfset VARIABLES.eventFocoPublicUrl = "https://www.focoradical.com.br/#VARIABLES.eventFocoPath#" />
            <cfelse>
                <cfset VARIABLES.eventFocoPublicUrl = "https://www.focoradical.com.br/prova/#VARIABLES.eventFocoPath#" />
            </cfif>
        <cfelseif len(VARIABLES.eventFocoCompetitionId)>
            <cfset VARIABLES.eventFocoPublicUrl = "https://www.focoradical.com.br/busca-numero?type=1&competition_id=#VARIABLES.eventFocoCompetitionId#" />
        <cfelse>
            <cfset VARIABLES.eventFocoPublicUrl = "https://www.focoradical.com.br" />
        </cfif>

        <cfset VARIABLES.eventFocoName = trim(qEventoFocoVinculos.competition_name & "") />
        <cfif !len(VARIABLES.eventFocoName) AND structKeyExists(VARIABLES.eventFocoPayload, "competition_name")>
            <cfset VARIABLES.eventFocoName = trim(VARIABLES.eventFocoPayload.competition_name & "") />
        </cfif>
        <cfset VARIABLES.eventFocoDate = trim(qEventoFocoVinculos.competition_date & "") />
        <cfif !len(VARIABLES.eventFocoDate) AND structKeyExists(VARIABLES.eventFocoPayload, "date")>
            <cfset VARIABLES.eventFocoDate = trim(VARIABLES.eventFocoPayload.date & "") />
        </cfif>
        <cfset VARIABLES.eventFocoPlace = trim(qEventoFocoVinculos.place & "") />
        <cfif !len(VARIABLES.eventFocoPlace) AND structKeyExists(VARIABLES.eventFocoPayload, "place")>
            <cfset VARIABLES.eventFocoPlace = trim(VARIABLES.eventFocoPayload.place & "") />
        </cfif>
        <cfset VARIABLES.eventFocoUf = trim(qEventoFocoVinculos.uf & "") />
        <cfif !len(VARIABLES.eventFocoUf) AND structKeyExists(VARIABLES.eventFocoPayload, "UF")>
            <cfset VARIABLES.eventFocoUf = trim(VARIABLES.eventFocoPayload.UF & "") />
        </cfif>
        <cfset VARIABLES.eventFocoLocation = VARIABLES.eventFocoPlace />
        <cfif len(VARIABLES.eventFocoUf)>
            <cfset VARIABLES.eventFocoLocation = len(VARIABLES.eventFocoLocation) ? "#VARIABLES.eventFocoLocation# - #VARIABLES.eventFocoUf#" : VARIABLES.eventFocoUf />
        </cfif>

        <cfset arrayAppend(VARIABLES.eventFocoGalleries, {
            "id" = VARIABLES.eventFocoCompetitionId,
            "name" = len(VARIABLES.eventFocoName) ? VARIABLES.eventFocoName : qEvento.nome_evento,
            "date" = isDate(VARIABLES.eventFocoDate) ? lsDateFormat(VARIABLES.eventFocoDate, "dd/mm/yyyy") : VARIABLES.eventFocoDate,
            "location" = VARIABLES.eventFocoLocation,
            "url" = VARIABLES.eventFocoPublicUrl,
            "source" = "vinculo"
        }) />
    </cfloop>
<cfelseif isStruct(VARIABLES.eventFocoBadge) AND len(trim(VARIABLES.eventFocoGalleryToken))>
    <cfset VARIABLES.eventFocoPublicUrl = "" />
    <cfif left(lCase(VARIABLES.eventFocoGalleryToken), 4) EQ "http">
        <cfset VARIABLES.eventFocoPublicUrl = VARIABLES.eventFocoGalleryToken />
    <cfelseif left(VARIABLES.eventFocoGalleryToken, 1) EQ "/">
        <cfset VARIABLES.eventFocoPublicUrl = "https://www.focoradical.com.br#VARIABLES.eventFocoGalleryToken#" />
    <cfelse>
        <cfset VARIABLES.eventFocoPublicUrl = "https://www.focoradical.com.br/prova/#VARIABLES.eventFocoGalleryToken#" />
    </cfif>
    <cfset arrayAppend(VARIABLES.eventFocoGalleries, {
        "id" = VARIABLES.eventFocoValor,
        "name" = qEvento.nome_evento,
        "date" = isDate(qEvento.data_final) ? lsDateFormat(qEvento.data_final, "dd/mm/yyyy") : "",
        "location" = "#qEvento.cidade# - #qEvento.estado#",
        "url" = VARIABLES.eventFocoPublicUrl,
        "source" = "badge"
    }) />
</cfif>

<!--- NOME --->
<cfset VARIABLES.description = REQUEST.t("event.meta.happens", { "name" = qEvento.nome_evento }) />
<!--- DATA --->
<cfif qEvento.data_inicial NEQ qEvento.data_final>
    <cfset VARIABLES.description = VARIABLES.description & "#eventMetaCatalog.from# #lsDateFormat(qEvento.data_inicial, 'dd')# #lcase(lsDateFormat(qEvento.data_inicial, 'mmmm'))# #eventMetaCatalog.to# #lsDateFormat(qEvento.data_final, 'dd')# #lcase(lsDateFormat(qEvento.data_final, 'mmmm'))# #lsDateFormat(qEvento.data_final, 'yyyy')#"/>
<cfelse>
    <cfset VARIABLES.description = VARIABLES.description & "#eventMetaCatalog.on# #lsDateFormat(qEvento.data_inicial, 'dd')# #lcase(lsDateFormat(qEvento.data_inicial, 'mmmm'))# #lsDateFormat(qEvento.data_final, 'yyyy')#"/>
</cfif>
<!--- ENDERECO --->
<cfif len(trim(qEvento.endereco))>
    <cfset VARIABLES.description = VARIABLES.description & ", #eventMetaCatalog.in# #qEvento.endereco# - #qEvento.cidade# - #qEvento.estado#."/>
<cfelse>
    <cfset VARIABLES.description = VARIABLES.description & ", #eventMetaCatalog.in# #qEvento.cidade# - #qEvento.estado#."/>
</cfif>
<cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey) />
<cfset VARIABLES.eventTitleTypeLabel = ""/>
<cfswitch expression="#lCase(trim(qEvento.tipo_corrida & ""))#">
    <cfcase value="rua">
        <cfset VARIABLES.eventTitleTypeLabel = "corrida de rua"/>
    </cfcase>
    <cfcase value="trail,trailrun">
        <cfset VARIABLES.eventTitleTypeLabel = "Trailrun"/>
    </cfcase>
    <cfcase value="treino">
        <cfset VARIABLES.eventTitleTypeLabel = "Treino gratuito"/>
    </cfcase>
</cfswitch>
<cfset VARIABLES.eventTitleTypeSegment = len(trim(VARIABLES.eventTitleTypeLabel)) ? " - #VARIABLES.eventTitleTypeLabel#" : ""/>
<!--- CALCULANDO O TAMANHO DO TITULO < 70 CARACTERES --->
<cfif len(qEvento.nome_evento & VARIABLES.eventTitleTypeLabel & APPLICATION.nomeSite) GT 60>
    <cfset VARIABLES.title = "#Left(qEvento.nome_evento,50)##VARIABLES.eventTitleTypeSegment# - #APPLICATION.nomeSite#"/>
<cfelseif len(qEvento.nome_evento & qEvento.cidade & qEvento.estado & VARIABLES.eventTitleTypeLabel & APPLICATION.nomeSite) GT 60>
    <cfset VARIABLES.title = "#qEvento.nome_evento##VARIABLES.eventTitleTypeSegment# - #APPLICATION.nomeSite#"/>
<cfelse>
    <cfset VARIABLES.title = "#qEvento.nome_evento# - #qEvento.cidade# #qEvento.estado##VARIABLES.eventTitleTypeSegment# - #APPLICATION.nomeSite#"/>
</cfif>
<cfset VARIABLES.keywords = eventCatalog.meta.keywords />

<!--- STRUCTURED DATA --->
<cfscript>
    VARIABLES.eventSchema = structNew("ordered");
    VARIABLES.eventSchema["@context"] = "https://schema.org";
    VARIABLES.eventSchema["@type"] = "SportsEvent";
    VARIABLES.eventSchema["@id"] = VARIABLES.canonical;
    VARIABLES.eventSchema.name = qEvento.nome_evento & "";
    VARIABLES.eventSchema.description = reReplace(VARIABLES.description & "", "<[^>]*>", "", "all");
    VARIABLES.eventSchema.url = VARIABLES.canonical;
    VARIABLES.eventSchema.startDate = dateFormat(qEvento.data_inicial, "yyyy-mm-dd");
    VARIABLES.eventSchema.endDate = dateFormat(qEvento.data_final, "yyyy-mm-dd");
    VARIABLES.eventSchema.eventAttendanceMode = "https://schema.org/OfflineEventAttendanceMode";
    VARIABLES.eventSchema.eventStatus = lCase(trim(qEvento.status_evento & "")) EQ "cancelado"
        ? "https://schema.org/EventCancelled"
        : "https://schema.org/EventScheduled";

    if (len(trim(qEvento.url_imagem & ""))) {
        VARIABLES.eventSchemaImageUrl = trim(qEvento.url_imagem & "");
        if (left(VARIABLES.eventSchemaImageUrl, 1) EQ "/") {
            VARIABLES.eventSchemaImageUrl = REQUEST.currentBaseUrl & VARIABLES.eventSchemaImageUrl;
        }
        VARIABLES.eventSchema.image = [VARIABLES.eventSchemaImageUrl];
    }

    VARIABLES.eventSchema.location = structNew("ordered");
    VARIABLES.eventSchema.location["@type"] = "Place";
    VARIABLES.eventSchema.location.name = len(trim(qEvento.endereco & ""))
        ? trim(qEvento.endereco & "")
        : trim(qEvento.cidade & ", " & qEvento.estado);

    VARIABLES.eventSchema.location.address = structNew("ordered");
    VARIABLES.eventSchema.location.address["@type"] = "PostalAddress";
    VARIABLES.eventSchema.location.address.addressLocality = trim(qEvento.cidade & "");
    VARIABLES.eventSchema.location.address.addressRegion = trim(qEvento.estado & "");
    VARIABLES.eventSchema.location.address.addressCountry = len(trim(qEvento.pais & "")) ? trim(qEvento.pais & "") : "BR";

    if (len(trim(qEvento.endereco & ""))) {
        VARIABLES.eventSchema.location.address.streetAddress = trim(qEvento.endereco & "");
    }

    if (len(trim(qEvento.coordenadas & "")) AND listLen(qEvento.coordenadas, ",") GTE 2) {
        VARIABLES.eventSchema.location.geo = structNew("ordered");
        VARIABLES.eventSchema.location.geo["@type"] = "GeoCoordinates";
        VARIABLES.eventSchema.location.geo.latitude = trim(listGetAt(qEvento.coordenadas, 1, ","));
        VARIABLES.eventSchema.location.geo.longitude = trim(listGetAt(qEvento.coordenadas, 2, ","));
    }

    if (len(trim(qEvento.url_inscricao & ""))) {
        VARIABLES.eventSchemaOfferUrl = trim(qEvento.url_inscricao & "");
        if (left(VARIABLES.eventSchemaOfferUrl, 1) EQ "/") {
            VARIABLES.eventSchemaOfferUrl = REQUEST.currentBaseUrl & VARIABLES.eventSchemaOfferUrl;
        }
        VARIABLES.eventSchema.offers = structNew("ordered");
        VARIABLES.eventSchema.offers["@type"] = "Offer";
        VARIABLES.eventSchema.offers.url = VARIABLES.eventSchemaOfferUrl;
        VARIABLES.eventSchema.offers.availability = (qEvento.data_inicial GT now() AND lCase(trim(qEvento.status_evento & "")) NEQ "cancelado")
            ? "https://schema.org/InStock"
            : "https://schema.org/SoldOut";
    }

    if (qFornecedores.recordcount) {
        VARIABLES.eventSchema.organizer = structNew("ordered");
        VARIABLES.eventSchema.organizer["@type"] = "Organization";
        VARIABLES.eventSchema.organizer.name = qFornecedores.nome_fornecedor & "";
        if (len(trim(qFornecedores.site_fornecedor & ""))) {
            VARIABLES.eventSchema.organizer.url = trim(qFornecedores.site_fornecedor & "");
        }
    }

    VARIABLES.structuredDataJsonLd = serializeJSON(VARIABLES.eventSchema);
</cfscript>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/assets/css/runnerhub-event-chat-share.css?v=2"/>

<body <cfif qTema.recordcount>style="background-color:<cfoutput>#qTema.cor_fundo#</cfoutput>"</cfif>>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .event-page-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
            overflow: hidden;
        }

        .event-page-card + .event-page-card {
            margin-top: 0.5rem;
        }

        .event-page-card-body {
            padding: 1rem;
        }

        .event-page-card-body.is-map {
            padding: 0;
        }

        .event-page-card-head {
            padding: 0.95rem 1rem;
            border-bottom: 1px solid rgba(51, 51, 51, 0.08);
            background-color: #efefef;
        }

        .event-page-card-title {
            color: #333333;
            font-size: 0.78rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            margin: 0;
        }

        .event-action-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 0.55rem;
        }

        .event-action-grid .full {
            grid-column: 1 / -1;
        }

        .event-action-grid .btn {
            box-shadow: none;
            border-radius: 8px;
        }

        .event-result-action-row {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 0.55rem;
            margin-top: 0.5rem;
        }

        .event-result-action-row .btn {
            margin-top: 0 !important;
        }

        .event-info-copy {
            color: rgba(51, 51, 51, 0.88);
            font-size: 0.92rem;
            line-height: 1.6;
        }

        .event-info-copy a {
            color: #333333;
        }

        .event-linked-video-trigger {
            color: #333333;
            display: grid;
            grid-template-columns: minmax(0, 0.95fr) minmax(0, 1fr);
            text-decoration: none;
        }

        .event-linked-video-trigger:hover {
            color: #333333;
        }

        .event-linked-video-media {
            background-color: #efefef;
            overflow: hidden;
            position: relative;
        }

        .event-linked-video-image,
        .event-linked-video-placeholder {
            aspect-ratio: 16 / 9;
            display: block;
            height: 100%;
            object-fit: cover;
            width: 100%;
        }

        .event-linked-video-placeholder {
            align-items: center;
            background:
                radial-gradient(circle at top right, rgba(250, 177, 32, 0.36), transparent 28%),
                linear-gradient(135deg, #f1f1f1 0%, #e5e5e5 100%);
            color: rgba(51, 51, 51, 0.7);
            display: none;
            font-size: 2rem;
            justify-content: center;
        }

        .event-linked-video-media.is-image-fallback .event-linked-video-image {
            display: none;
        }

        .event-linked-video-media.is-image-fallback .event-linked-video-placeholder {
            display: flex;
        }

        .event-linked-video-play {
            align-items: center;
            display: flex;
            inset: 0;
            justify-content: center;
            pointer-events: none;
            position: absolute;
        }

        .event-linked-video-play span {
            align-items: center;
            background-color: rgba(255, 255, 255, 0.76);
            border-radius: 999px;
            box-shadow: 0 10px 20px rgba(17, 17, 17, 0.08);
            color: rgba(51, 51, 51, 0.72);
            display: flex;
            font-size: 1.05rem;
            height: 52px;
            justify-content: center;
            width: 52px;
        }

        .event-linked-video-copy {
            align-content: center;
            display: grid;
            gap: 0.38rem;
            padding: 1rem;
        }

        .event-linked-video-kicker {
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.72rem;
            font-weight: 700;
            line-height: 1.2;
        }

        .event-linked-video-kicker i {
            color: #fab120;
        }

        .event-linked-video-title {
            color: #333333;
            font-size: 1.02rem;
            font-weight: 700;
            line-height: 1.22;
        }

        .event-linked-video-channel {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.8rem;
            line-height: 1.3;
        }

        .event-suppliers {
            display: grid;
            gap: 0.45rem;
            margin-top: 0.85rem;
            padding-top: 0.85rem;
            border-top: 1px solid rgba(51, 51, 51, 0.08);
        }

        @media (max-width: 575.98px) {
            .event-linked-video-trigger {
                grid-template-columns: 1fr;
            }

            .event-linked-video-copy {
                padding: 0.88rem;
            }
        }

        .event-supplier-item {
            color: rgba(51, 51, 51, 0.76);
            font-size: 0.82rem;
            line-height: 1.35;
        }

        .event-supplier-item i {
            color: #fab120;
            width: 14px;
        }

        .event-route-shell .nav-tabs {
            border-bottom: 0;
            gap: 0.32rem;
            padding: 0.75rem 0.85rem;
        }

        .event-route-shell .nav-tabs .nav-link {
            border: 1px solid rgba(51, 51, 51, 0.08) !important;
            border-radius: 7px !important;
            background-color: #efefef;
            color: #333333;
            font-size: 0.86rem;
            font-weight: 700;
            line-height: 1;
            margin: 0 !important;
            padding: 0.46rem 0.68rem;
        }

        .event-route-shell .nav-tabs .nav-link.active,
        .event-route-shell .nav-tabs .nav-link:hover,
        .event-route-shell .nav-tabs .nav-link:focus {
            border-color: #fab120 !important;
            background-color: #ffffff;
            color: #333333;
        }

        .event-route-shell .tab-content {
            padding: 0 1rem 1rem;
        }

        .event-theme-shell {
            margin: 0;
            padding: 0;
        }

        @media (max-width: 991.98px) {
            .home-mobile-section {
                margin-top: 0.75rem;
            }
        }

        @media (max-width: 767.98px) {
            .event-action-grid {
                grid-template-columns: 1fr;
            }

            .event-mobile-follow-shell {
                margin-top: 0.5rem;
            }

            .event-mobile-follow-shell .home-side-block:last-child {
                margin-bottom: 0 !important;
            }
        }
    </style>


    <!--- CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <!--- CONTEUDO --->

        <div class="row g-2">


            <!--- PROFILE MINI --->

            <div class="d-none d-lg-block col-lg-3 col-xl-3 order-lg-1 home-mobile-section">

                <cfset VARIABLES.homeSidebarAsyncFooter = "0"/>
                <cfinclude template="../includes/estrutura/home_sidebar_async_slot.cfm"/>

            </div>


            <!--- LISTA DE EVENTOS DE CORRIDA --->

            <div class="col-12 col-md-8 col-lg-6 col-xl-6 px-lg-3 order-1 order-md-2">

                <!--- HEADER DO TEMA--->
                <cfif qTema.recordcount AND qTema.id_tema GT 1>
                    <div class="event-theme-shell">
                        <cfset VARIABLES.eventThemeHeaderCompact = true/>
                        <cfinclude template="../includes/estrutura/header_tema.cfm"/>
                    </div>
                </cfif>



                <!--- HEADER DO EVENTO --->
                <cfoutput query="qEvento">
                    <cfinclude template="../includes/card_evento_individual.cfm"/>
                </cfoutput>

                <!---DADOS DO EVENTO--->
                <div class="event-page-card mt-2">

                    <div class="event-page-card-body">

                        <!--- BARRA DE ACOES DO EVENTO --->
                        <div class="event-action-grid mb-3">


                            <!--- INSCRICAO --->

                            <div class="full">

                                <cfif VARIABLES.eventoUsuarioInscritoInternamente OR len(trim(qEvento.url_inscricao)) OR len(trim(qEvento.url_hotsite))>

                                    <cfif qEvento.data_final GT now()>

                                        <cfif VARIABLES.eventoUsuarioInscritoInternamente AND qEvento.status_evento NEQ 'cancelado'>

                                            <!--- CHECK-IN DE INSCRICAO INTERNA --->

                                            <button type="button" class="btn btn-primary w-100 shadow-0"
                                                data-mdb-ripple-init
                                                data-mdb-modal-init
                                                data-mdb-target="#modalTreinoCheckin">
                                                <i class="fa-solid fa-qrcode me-2"></i>EFETUAR CHECK-IN
                                            </button>

                                        <cfelseif qCupom.recordcount AND qEvento.status_evento NEQ 'cancelado'>

                                            <!--- INSCRICAO COM CUPOM --->

                                            <!---<cfif Usuario.logado>--->
                                                <button type="button" class="btn btn-primary w-100 shadow-0"
                                                    data-mdb-modal-init
                                                    data-mdb-target="#modal_cupom_link"
                                                    data-mdb-id-cupom="<cfoutput>#qCupom.id_cupom#</cfoutput>">
                                                    <cfset eventCouponRichLabel = "<b>" & qCupom.condicoes & "</b>" />
                                                    <cfoutput>#REQUEST.t("event.actions.registerWithCoupon", { "coupon" = eventCouponRichLabel })#</cfoutput>
                                                </button>
                                            <!---<cfelse>
                                                <button type="button" class="btn btn-primary w-100 shadow-0"
                                                    data-mdb-modal-init
                                                    data-mdb-target="#modalLogin"
                                                    data-mdb-acao="perfil">
                                                    Me inscrever com cupom de <b><cfoutput>#qCupom.condicoes#</cfoutput></b>
                                                </button>
                                            </cfif>--->

                                        <cfelse>

                                            <!--- INSCRICAO NORMAL --->

                                            <cfif qEvento.status_evento NEQ 'cancelado'>
                                                <!---<cfif Usuario.logado>--->
                                                    <a class="btn btn-primary w-100 shadow-0"
                                                        href="<cfoutput>#Len(trim(qEvento.url_inscricao)) ? qEvento.url_inscricao : qEvento.url_hotsite#</cfoutput>" target="_blank">
                                                        <cfoutput>#eventActions.register#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon>
                                                    </a>
                                                <!---<cfelse>
                                                    <button type="button" class="btn btn-primary w-100 shadow-0"
                                                        data-mdb-modal-init
                                                        data-mdb-target="#modalLogin"
                                                        data-mdb-acao="perfil">
                                                        Me inscrever&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon>
                                                    </button>
                                                </cfif>--->
                                            </cfif>

                                        </cfif>

                                    </cfif>

                                <cfelse>

                                    <!--- SEM LINK DE INSCRICAO --->

                                    <cfif qEvento.data_inicial GT now()>
                                        <button type="button" class="btn disabled w-50 btn-secondary w-100 shadow-0"><cfoutput>#eventActions.registrationsSoon#</cfoutput></button>
                                    </cfif>

                                </cfif>

                                <!--- RESULTADOS --->

                                <cfif qEvento.concluintes GT 0>

                                    <cfif qEvento.data_final LT now() AND arrayLen(VARIABLES.eventFocoGalleries)>
                                        <div class="event-result-action-row">
                                            <a href="https://openresults.run/evento/<cfoutput>#qEvento.tag#</cfoutput>" target="_blank"
                                                class="btn btn-primary w-100 shadow-0"><cfoutput>#eventActions.results#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></a>
                                            <cfoutput>
                                                <button type="button"
                                                    class="btn btn-light w-100 shadow-0"
                                                    data-mdb-ripple-init
                                                    data-mdb-valor-badge="#HTMLEditFormat(VARIABLES.eventFocoValor)#"
                                                    data-mdb-numero-peito=""
                                                    data-mdb-complemento-badge="#HTMLEditFormat(VARIABLES.eventFocoGalleryToken)#"
                                                    data-mdb-foco-galleries="#HTMLEditFormat(serializeJSON(VARIABLES.eventFocoGalleries))#"
                                                    data-mdb-modal-init
                                                    data-mdb-target="##modal_cupom_foco"
                                                    title="#HTMLEditFormat(eventActions.photos)#">
                                                    <i class="fa-solid fa-camera"></i> #eventActions.photos#
                                                </button>
                                            </cfoutput>
                                        </div>
                                    <cfelse>
                                        <a href="https://openresults.run/evento/<cfoutput>#qEvento.tag#</cfoutput>" target="_blank"
                                            class="btn btn-primary w-100 shadow-0 mt-2"><cfoutput>#eventActions.results#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></a>
                                    </cfif>

                                    <!--- SUGERE O RESULTADO DO USUARIO NESTA PROVA, QUANDO HOUVER RESULTADOS PUBLICADOS --->

                                    <cfif Usuario.logado AND qEvento.concluintes GT 0 AND qEvento.data_final LT now()>

                                        <div id="event-result-suggestion-shell" class="mt-2 d-none"></div>

                                        <script>
                                            document.addEventListener('DOMContentLoaded', () => {
                                                const suggestionShell = document.getElementById('event-result-suggestion-shell');
                                                const resultActionPath = '<cfoutput>#JSStringFormat(REQUEST.i18nBuildPath("results"))#</cfoutput>';

                                                const buildEventSuggestionUrl = () => {
                                                    const params = new URLSearchParams({
                                                        id_evento: '<cfoutput>#qEvento.id_evento#</cfoutput>',
                                                        nome: '<cfoutput>#JSStringFormat(Usuario.name)#</cfoutput>',
                                                        aka: '<cfoutput>#JSStringFormat(Usuario.aka)#</cfoutput>',
                                                        assessoria: '<cfoutput>#JSStringFormat(Usuario.assessoria)#</cfoutput>',
                                                        ano_nascimento: '<cfoutput>#JSStringFormat(Usuario.ano_nascimento)#</cfoutput>',
                                                        similaridade: '0.35',
                                                        i18n_lang: '<cfoutput>#JSStringFormat(REQUEST.lang)#</cfoutput>'
                                                    });

                                                    return '/api/resultados_sugeridos.cfm?' + params.toString();
                                                };

                                                const buildResultActionUrl = (action, idResultado) => {
                                                    const params = new URLSearchParams({
                                                        action: action === 'vincular' ? 'vincularcorrida' : 'desvincularcorrida',
                                                        filtro: 'resultados',
                                                        id_resultado: idResultado,
                                                        rr_ajax: Date.now().toString()
                                                    });

                                                    return resultActionPath + '?' + params.toString();
                                                };

                                                const loadEventResultSuggestion = async () => {
                                                    if (!suggestionShell) {
                                                        return;
                                                    }

                                                    const response = await fetch(buildEventSuggestionUrl(), {
                                                        credentials: 'same-origin',
                                                        headers: {
                                                            'X-Requested-With': 'XMLHttpRequest'
                                                        }
                                                    });

                                                    if (!response.ok) {
                                                        throw new Error(response.status + ' ' + response.statusText);
                                                    }

                                                    const html = await response.text();
                                                    suggestionShell.innerHTML = html;

                                                    const hasSuggestion = Boolean(html.trim().length && suggestionShell.querySelector('.result-suggestion-card'));
                                                    suggestionShell.classList.toggle('d-none', !hasSuggestion);

                                                    if (hasSuggestion && typeof colorirDistancias === 'function') {
                                                        colorirDistancias();
                                                    }
                                                };

                                                document.addEventListener('click', async (event) => {
                                                    const trigger = event.target.closest('#event-result-suggestion-shell [data-resultado-sugestao-action]');

                                                    if (!trigger) {
                                                        return;
                                                    }

                                                    event.preventDefault();
                                                    event.stopPropagation();

                                                    const action = trigger.getAttribute('data-resultado-sugestao-action');
                                                    const idResultado = trigger.getAttribute('data-resultado-id');

                                                    if (!action || !idResultado) {
                                                        return;
                                                    }

                                                    const card = trigger.closest('.result-suggestion-card');
                                                    const actionControls = card ? card.querySelectorAll('button, a') : [trigger];

                                                    actionControls.forEach((control) => {
                                                        if (control.tagName === 'BUTTON') {
                                                            control.disabled = true;
                                                        }

                                                        control.classList.add('disabled');
                                                    });

                                                    try {
                                                        const response = await fetch(buildResultActionUrl(action, idResultado), {
                                                            credentials: 'same-origin',
                                                            headers: {
                                                                'X-Requested-With': 'XMLHttpRequest'
                                                            }
                                                        });

                                                        if (!response.ok) {
                                                            throw new Error(response.status + ' ' + response.statusText);
                                                        }

                                                        window.location.reload();
                                                    } catch (err) {
                                                        console.warn('Algo deu errado.', err);
                                                    } finally {
                                                        actionControls.forEach((control) => {
                                                            if (control.tagName === 'BUTTON') {
                                                                control.disabled = false;
                                                            }

                                                            control.classList.remove('disabled');
                                                        });
                                                    }
                                                });

                                                loadEventResultSuggestion().catch((err) => {
                                                    console.warn('Algo deu errado.', err);
                                                });
                                            });
                                        </script>

                                    </cfif>

                                </cfif>

                            </div>

                            <!--- INFOS --->

                            <div<cfif NOT (qEvento.data_final GT now())> class="full"</cfif>>

                                <!---<cfif Usuario.logado>--->
                                    <a class="btn btn-secondary px-1 w-100"
                                        href="<cfoutput>#Len(trim(qEvento.url_hotsite)) ? qEvento.url_hotsite : qEvento.url_inscricao#</cfoutput>" target="_blank">
                                        <cfoutput>#eventActions.learnMore#</cfoutput>&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon></a>
                                <!---<cfelse>
                                    <button type="button" class="btn btn-secondary px-1 w-100"
                                        data-mdb-modal-init
                                        data-mdb-target="#modalLogin"
                                        data-mdb-acao="perfil">
                                        Informações&nbsp;&nbsp;<icon class="fa fa-up-right-from-square"></icon>
                                    </button>
                                </cfif>--->

                            </div>

                            <!--- FAVORITAR EVENTOS --->

                            <cfif qEvento.data_inicial GT now()>

                                <div>
                                    <div class="d-flex btn-group shadow-0">
                                        <cfif Usuario.logado>
                                            <!--- QUERO IR --->
                                            <!---<button type="button" class="btn btn-secondary px-1 <cfif isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount>text-warning fw-bold</cfif>" onclick="location.href='./?acao=<cfif isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount>remover<cfelse>calendario</cfif>'">--->
                                                <!---<cfif isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount><i class="fa-regular fa-bookmark"></i><cfelse><i class="fa-regular fa-bookmark"></i></cfif> Quero ir</button>--->
                                            <!--- SALVAR NA AGENDA --->
                                            <button type="button" class="btn btn-secondary px-1" onclick="location.href='./?acao=<cfif isDefined("qCheckingInscricao") AND qCheckingInscricao.recordcount>remover<cfelse>inscricao</cfif>'">
                                                <cfif isDefined("qCheckingInscricao") AND qCheckingInscricao.recordcount><i class="fa-solid fa-calendar"></i> <cfoutput>#eventActions.remove#</cfoutput><cfelse><i class="fa-regular fa-calendar"></i> <cfoutput>#eventActions.save#</cfoutput></cfif></button>
                                            <!--- ENVIAR PELO CHAT --->
                                            <button type="button" class="btn btn-secondary px-1 border-start" data-mdb-modal-init data-mdb-target="#eventChatShareModal">
                                                <i class="fa-solid fa-paper-plane"></i> <cfoutput>#eventActions.send#</cfoutput></button>
                                            <!--- COMPARTILHAR FORA DO CHAT --->
                                            <button type="button" class="btn btn-secondary px-2 border-start" data-mdb-modal-init data-mdb-target="#shareModal" aria-label="<cfoutput>#REQUEST.t('common.shareModal.title')#</cfoutput>" title="<cfoutput>#REQUEST.t('common.shareModal.title')#</cfoutput>">
                                                <i class="fa-solid fa-share-nodes"></i></button>
                                            <!--- AGENDA DA PAGINA --->
                                            <!---<button type="button" class="btn btn-light" onclick="">Agenda pública</button>--->
                                        <cfelse>
                                            <!--- QUERO IR --->
                                            <button type="button" class="btn btn-secondary px-1" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="calendario"><i class="fa-regular fa-bookmark"></i> <cfoutput>#eventActions.wantToGo#</cfoutput></button>
                                            <!--- JA INSCRITO --->
                                            <button type="button" class="btn btn-secondary px-1 border-start" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="inscricao"><i class="fa-regular fa-square-check"></i> <cfoutput>#eventActions.iAmGoing#</cfoutput></button>
                                            <button type="button" class="btn btn-secondary px-1 border-start" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="mensagem"><i class="fa-solid fa-paper-plane"></i> <cfoutput>#eventActions.send#</cfoutput></button>
                                        </cfif>
                                        <!--- REMOVER --->
                                        <!---<cfif (isDefined("qCheckingCalendario") AND qCheckingCalendario.recordcount) OR (isDefined("qCheckingInscricao") AND qCheckingInscricao.recordcount)>--->
                                            <!---<button type="button" style="width: 16%" class="btn btn-light" <cfif Usuario.logado>onclick="location.href='./?acao=remover'"<cfelse> data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="remover"</cfif>>--->
                                                <!---<icon class="fa fa-trash"></icon>--->
                                            <!---</button>--->
                                        <!---</cfif>--->
                                    </div>
                                </div>

                                <!---div class="d-flex btn-group shadow-0">
                                    <!--- AGENDA PUBLICA --->
                                    <button type="button" class="btn btn-light active" onclick=""><i class="fa-solid fa-calendar-check"></i><span class="d-none d-md-inline"> Agenda do</span> perfil</button>
                                    <button type="button" class="btn btn-light" onclick=""><i class="fa-regular fa-calendar"></i><span class="d-none d-md-inline"> Agenda do</span> clube</button>
                                </div--->

                            </cfif>

                        </div>

                        <!--- World Athletics Race Label (.wa-label-race race/gold/elite/platinum) --->
                        <!---div class="wa-label-race p-5 mt-3" title="World Athletics Race Label"></div--->

                        <!---IMAGEM DE CAPA--->
                        <cfif len(trim(qEvento.url_imagem))>
                            <div class="mt-3">
                                <img class="img-fluid rounded-3 w-100" src="<cfoutput>#qEvento.url_imagem#</cfoutput>" onerror="this.src='/assets/error.png';this.height='0';this.style='display:none'"/>
                            </div>
                        </cfif>

                        <!--- DESCRICAO --->
                        <div class="event-info-copy mt-3">

                                <cfif len(trim(qEvento.descricao)) EQ 0>
                                    <cfoutput>
                                        <div>
                                            #VARIABLES.description#
                                        </div>
                                        <!--- percurso --->
                                        <!---<cfif arraylen(listToArray(qEvento.categorias, ",")) GT 1>
                                            <div>
                                                Os percursos serão:
                                                <cfloop list="#qEvento.categorias#" delimiters="," index="i" item="distancia">#trim(REReplace(distancia,"[^0-9.]", "","ALL"))#<cfif i LT arraylen(listToArray(qEvento.categorias, ","))>km, <cfelseif i EQ arraylen(listToArray(qEvento.categorias, ","))-2>km e </cfif></cfloop>km.
                                            </div>
                                        <cfelse>
                                            <cfif Len(qEvento.lista_percursos)>
                                                <div>O percurso será de #qEvento.categorias#km.</div>
                                            <cfelse>
                                                <div>As distâncias ainda não foram informadas.</div>
                                            </cfif>
                                        </cfif>--->

                                    </cfoutput>
                                </cfif>

                                <cfset qEvento.descricao = Replace(qEvento.descricao, #chr(10)#, "<br/>" ,"all")>

                                <cfoutput>
                                    <div>
                                        #qEvento.descricao#
                                    </div>
                                    <!--- percurso --->
                                    <cfif qEvento.tipo_corrida NEQ "treino">
                                        <cfif arraylen(listToArray(qEvento.categorias, ",")) GT 1>
                                                <div>
                                                    #eventDescriptionCatalog.routesManyLead#
                                                <cfloop list="#qEvento.categorias#" delimiters="," index="i" item="distancia">#trim(REReplace(distancia,"[^0-9.]", "","ALL"))#<cfif i LT arraylen(listToArray(qEvento.categorias, ","))>km, <cfelseif i EQ arraylen(listToArray(qEvento.categorias, ","))-2>km e </cfif></cfloop>km.
                                            </div>
                                        <cfelse>
                                            <cfif Len(qEvento.lista_percursos)>
                                                    <div>#REQUEST.t("event.description.routesSingle", { "distance" = qEvento.categorias })#</div>
                                            <cfelse>
                                                    <div>#eventDescriptionCatalog.routesPending#</div>
                                            </cfif>
                                        </cfif>
                                    </cfif>
                                </cfoutput>

                        </div>

                    </div>

                    <!--- ORGANIZADOR E CRONOMETRADOR --->
                    <cfif qFornecedores.recordcount>
                        <div class="event-page-card-body pt-0">
                            <div class="event-suppliers">
                                <cfoutput query="qFornecedores">
                                    <div class="event-supplier-item">
                                        <i class="fa-solid fa-<cfif #qFornecedores.descricao_tipo# EQ "Organização">building<cfelseif #qFornecedores.descricao_tipo# EQ "Cronometragem">stopwatch</cfif>"></i>
                                        <cfif qFornecedores.descricao_tipo EQ "Organização">#eventSuppliersCatalog.organizer#<cfelseif qFornecedores.descricao_tipo EQ "Cronometragem">#eventSuppliersCatalog.timer#<cfelse>#qFornecedores.descricao_tipo#</cfif>:&nbsp;
                                        <a href="/<cfif #qFornecedores.tag_tipo# EQ "org">org<cfelse>timer</cfif>/#qFornecedores.tag_fornecedor#/" class="link-dark">
                                            #qFornecedores.nome_fornecedor#
                                        </a>
                                    </div>
                                </cfoutput>
                            </div>
                        </div>
                    </cfif>

                </div>

                <cfif qEventoVideo.recordcount>
                    <cfoutput query="qEventoVideo">
                        <cfset VARIABLES.eventVideoTitleJs = HTMLEditFormat(JSStringFormat(media_titulo)) />
                        <cfset VARIABLES.eventVideoChannelJs = HTMLEditFormat(JSStringFormat(media_canal_nome)) />
                        <div class="event-page-card mt-2 event-linked-video-card">
                            <a href="##" class="event-linked-video-trigger" onclick="changeVideo('#HTMLEditFormat(media_url)#','#VARIABLES.eventVideoTitleJs#','#VARIABLES.eventVideoChannelJs#'); return false;">
                                <div class="event-linked-video-media">
                                    <img src="https://img.youtube.com/vi/#HTMLEditFormat(media_url)#/sddefault.jpg" alt="#HTMLEditFormat(media_titulo)#" class="event-linked-video-image" loading="lazy" onerror="this.onerror=null; this.parentNode.classList.add('is-image-fallback');" />
                                    <div class="event-linked-video-placeholder"><i class="fa-solid fa-person-running"></i></div>
                                    <div class="event-linked-video-play"><span><i class="fa-solid fa-play"></i></span></div>
                                </div>
                                <div class="event-linked-video-copy">
                                    <div class="event-linked-video-kicker"><i class="fa-brands fa-youtube me-1"></i>RunTV</div>
                                    <div class="event-linked-video-title">#HTMLEditFormat(media_titulo)#</div>
                                    <cfif len(trim(media_canal_nome))>
                                        <div class="event-linked-video-channel">#HTMLEditFormat(media_canal_nome)#</div>
                                    </cfif>
                                </div>
                            </a>
                        </div>
                    </cfoutput>
                </cfif>

                <!---
                <cfset VARIABLES.adMockSlotName = "event-after-description" />
                <cfset VARIABLES.adMockFormat = "Native module | Desktop inline | Mobile inline" />
                <cfset VARIABLES.adMockContext = "Slot de consideracao apos a descricao do evento e antes de secoes secundarias." />
                <cfset VARIABLES.adMockClassName = "mt-2" />
                <cfset VARIABLES.adMockBadge = "Slot de anuncio" />
                <cfinclude template="../includes/estrutura/ad_slot_mock.cfm"/>
                --->

                <div class="d-block d-lg-none event-mobile-follow-shell">
                    <cfinclude template="parts/participantes_seguidos.cfm"/>
                </div>

                <cfif arrayLen(VARIABLES.eventoNoticiasRelacionadas)>
                    <cfset VARIABLES.eventRelatedNewsVariant = "mobile"/>
                    <cfinclude template="../includes/estrutura/evento_noticias_relacionadas.cfm"/>
                </cfif>

                <!--- EXIBE A EDICAO ATUAL E OUTRAS EDICOES DO MESMO AGREGADOR --->
                <cfinclude template="parts/edicoes_evento.cfm"/>

                <!--- DISTANCIAS --->
                <cfif qEvento.tipo_corrida NEQ "treino">
                    <div class="event-page-card mt-2 event-route-shell">
                        <div class="event-page-card-head">
                            <h6 class="event-page-card-title"><i class="fa-solid fa-route me-1"></i><cfoutput>#eventSections.routes#</cfoutput></h6>
                        </div>
                    <cfif arrayLen(VARIABLES.eventRoutes)>
                            <cfinclude template="parts/mapa_percurso_mapbox.cfm"/>
                        <cfelse>
                            <div class="event-page-card-body">
                                <p class="text-center text-gray-light mb-0"><cfoutput>#eventDescriptionCatalog.distancesUnavailable#</cfoutput></p>
                            </div>
                        </cfif>
                    </div>
                </cfif>
                        <!--- CLIMA --->

                        <!---cfinclude template="../includes/evento_clima.cfm"/--->

                <!--- HOSPEDAGEM --->
                <div class="event-page-card mt-2">

                    <div class="event-page-card-head">
                        <h6 class="event-page-card-title"><i class="fa-solid fa-location-dot me-1"></i><cfoutput>#eventSections.location#</cfoutput></h6>
                    </div>

                <!---<div style="filter: grayscale(1)">--->
                <div class="event-page-card-body is-map">
                    <cfif VARIABLES.eventLocationHasData>
                        <cfinclude template="parts/localizacao_mapbox.cfm"/>
                    <cfelse>
                        <p class="text-center text-gray-light mb-0"><cfoutput>#eventDescriptionCatalog.locationUnavailable#</cfoutput></p>
                    </cfif>
                </div>

                </div>

            </div>


            <!--- BARRA LATERAL --->

            <div class="d-none d-lg-block col-lg-3 order-3 home-mobile-section">
                <!---
                <cfset VARIABLES.adMockSlotName = "event-right-rail-banner" />
                <cfset VARIABLES.adMockFormat = "Desktop 300x250 | Desktop 300x600" />
                <cfset VARIABLES.adMockContext = "Slot principal de awareness e retargeting na lateral da pagina de evento." />
                <cfset VARIABLES.adMockClassName = "is-sidebar is-compact mb-2" />
                <cfset VARIABLES.adMockBadge = "Slot de anuncio" />
                <cfinclude template="../includes/estrutura/ad_slot_mock.cfm"/>
                --->
                <div class="d-none d-lg-block">
                    <cfinclude template="parts/participantes_seguidos.cfm"/>
                </div>
                <cfif arrayLen(VARIABLES.eventoNoticiasRelacionadas)>
                    <cfset VARIABLES.eventRelatedNewsVariant = "desktop"/>
                    <cfinclude template="../includes/estrutura/evento_noticias_relacionadas.cfm"/>
                </cfif>
                <cfset REQUEST.homeSidebarNoticiasExcludeSlugs = []/>
                <cfloop array="#VARIABLES.eventoNoticiasRelacionadas#" index="VARIABLES.eventRelatedNewsExcludedItem">
                    <cfif isStruct(VARIABLES.eventRelatedNewsExcludedItem)
                        AND structKeyExists(VARIABLES.eventRelatedNewsExcludedItem, "slug")
                        AND len(trim(VARIABLES.eventRelatedNewsExcludedItem.slug & ""))>
                        <cfset arrayAppend(REQUEST.homeSidebarNoticiasExcludeSlugs, lCase(trim(VARIABLES.eventRelatedNewsExcludedItem.slug & "")))/>
                    </cfif>
                </cfloop>
                <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"/>
                <div class="mt-2">
                    <cfinclude template="../includes/estrutura/side_footer.cfm"/>
                </div>
            </div>

        </div>

        </main>

    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL DE ENVIAR --->

    <cfinclude template="../includes/modal/modal_enviar.cfm"/>

    <cfif Usuario.logado>
        <cfinclude template="../includes/modal/modal_chat_evento.cfm"/>
    </cfif>


    <!--- MODAL DE BADGES --->

    <cfinclude template="../includes/modal/modal_badges.cfm"/>


    <!--- MODAL DE YOUTUBE --->

    <cfinclude template="../includes/modal/modal_youtube.cfm"/>


    <!--- MODAL FOCO --->

    <cfinclude template="../includes/modal/modal_cupom_foco.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL CUPOM --->

    <cfif qCupom.recordcount>

        <cfinclude template="../includes/modal/modal_cupom_link.cfm"/>

    </cfif>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- MODAL SEGUIDORES / SEGUINDO --->

    <cfinclude template="../includes/modal/modal_seguidores.cfm"/>


    <!--- MODAL PAGAMENTO --->

    <cfinclude template="../includes/modal/modal_pagamento.cfm"/>


    <!--- MODAL CHECK-IN DE INSCRICAO INTERNA --->

    <cfif VARIABLES.eventoUsuarioInscritoInternamente>
        <cfinclude template="../includes/modal/modal_treino_checkin.cfm"/>
    </cfif>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

    <cfif VARIABLES.eventMapboxAssets>
        <cfoutput>
            <script src="https://api.mapbox.com/mapbox-gl-js/v#APPLICATION.eventRouteMapbox.libraryVersion#/mapbox-gl.js" defer></script>
        </cfoutput>
    </cfif>
    <cfif VARIABLES.eventRouteMapboxAssets>
        <script src="/assets/js/event-route-mapbox.js?v=20260726-21" defer></script>
    </cfif>
    <cfif VARIABLES.eventLocationMapboxAssets>
        <script src="/assets/js/event-location-mapbox.js?v=20260727-2" defer></script>
    </cfif>
    <cfif Usuario.logado>
        <script src="/assets/js/runnerhub-event-chat-share.js?v=6" defer></script>
    </cfif>


    <!---script>

        <cfset jwtText = {
            "iss" = "runnerhub",
            "sub" = "public",
            "aud" = "#APPLICATION.codSite#",
            "exp" = "#DateAdd("n", 1, now())#",
            "id" = "#qEvento.id_evento#",
            "iat"="#DateAdd("n", -1, now())#"
        }>

        <!--- Base64 decode and import key --->
        <cfset rawKeyeyB64 = "ViHV9/ImYwwnx8GLevuR4oB8QYST4izOiJzi8CCT+Yc=">
        <cfset rawKey = binaryDecode(rawKeyeyB64, "base64" )>
        <cfset keySpec = createObject("java", "javax.crypto.spec.SecretKeySpec")>
        <cfset jwtK = keySpec.init(rawKey, "HmacSHA256")>

        <cfset jwtC = {
            "algorithm" = "HS256",
            "generateIssuedAt" = true,
            "generateJti" = true
        }>

        <cfset createjws = CreateSignedJWT(jwtText, jwtK, jwtC)>

        let jwtToken = '<cfoutput>#createjws#</cfoutput>';

        const res = await fetch("https://bits.abbit.io/runnerhub/v1/track", {
          headers: {
            "Authorization": "JWT " + jwtToken
          }
        });
        const resultado = await res.json();

    </script--->

</body>

</html>
