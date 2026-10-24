<!--- Promote one suggestion by request; never mutate the cached event query. --->
<cfscript>
VARIABLES.liveCircuitFeaturedRow = 0;
VARIABLES.liveCircuitBestRank = 0;
VARIABLES.liveCircuitLocation = structKeyExists(REQUEST,"LocationContext") && isStruct(REQUEST.LocationContext)
    ? REQUEST.LocationContext : {};
VARIABLES.liveCircuitNormalize = function(any value="") {
    if (isNull(arguments.value) || !isSimpleValue(arguments.value)) return "";
    var normalized = createObject("java","java.text.Normalizer").normalize(
        javaCast("string",left(trim(arguments.value & ""),120)),
        createObject("java","java.text.Normalizer$Form").NFD);
    normalized = javaCast("string",normalized).replaceAll("\p{M}","");
    return trim(reReplace(lCase(normalized),"[^a-z0-9]+"," ","all"));
};
VARIABLES.liveCircuitCouponCards = structKeyExists(VARIABLES,"qAgrega") && isQuery(qAgrega) && qAgrega.recordCount && qAgrega.tag[1] == "live-run-xp";
VARIABLES.liveCircuitCitySlug = function(any city="",any uf="") {
    return replace(VARIABLES.liveCircuitNormalize(arguments.city)," ","-","all") & "-" & lCase(trim(arguments.uf & ""));
};
VARIABLES.liveCircuitCities = {};
if (VARIABLES.liveCircuitCouponCards) {
    for (VARIABLES.liveCircuitCityRow in qEventosAba) {
        VARIABLES.liveCircuitCities[liveCircuitCitySlug(liveCircuitCityRow.cidade,liveCircuitCityRow.estado)] = liveCircuitCityRow.cidade & " — " & liveCircuitCityRow.estado;
    }
}
VARIABLES.liveCircuitCityKeys = structKeyArray(VARIABLES.liveCircuitCities);
arraySort(VARIABLES.liveCircuitCityKeys,"textnocase");
VARIABLES.liveCircuitValidLocation = structKeyExists(VARIABLES,"qAgrega") && isQuery(qAgrega) && qAgrega.recordCount
    && qAgrega.tag[1] == "live-run-xp"
    && structKeyExists(liveCircuitLocation,"pais") && isSimpleValue(liveCircuitLocation.pais) && uCase(trim(liveCircuitLocation.pais & "")) == "BR"
    && structKeyExists(liveCircuitLocation,"uf") && isSimpleValue(liveCircuitLocation.uf)
    && listFind("AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO",uCase(trim(liveCircuitLocation.uf & "")))
    && structKeyExists(liveCircuitLocation,"isFallback") && isBoolean(liveCircuitLocation.isFallback) && !liveCircuitLocation.isFallback;
if (liveCircuitValidLocation) {
    VARIABLES.liveCircuitUf = uCase(trim(liveCircuitLocation.uf & ""));
    VARIABLES.liveCircuitCity = structKeyExists(liveCircuitLocation,"cidade") ? liveCircuitNormalize(liveCircuitLocation.cidade) : "";
    for (VARIABLES.liveCircuitRow=1; liveCircuitRow <= qEventosAba.recordCount; liveCircuitRow++) {
        if (isNull(qEventosAba.data_inicial[liveCircuitRow]) || !isDate(qEventosAba.data_inicial[liveCircuitRow])
            || isNull(qEventosAba.data_final[liveCircuitRow]) || !isDate(qEventosAba.data_final[liveCircuitRow])
            || dateCompare(qEventosAba.data_inicial[liveCircuitRow],now(),"d") < 0
            || dateCompare(qEventosAba.data_final[liveCircuitRow],qEventosAba.data_inicial[liveCircuitRow],"d") < 0
            || lCase(trim(qEventosAba.status_evento[liveCircuitRow] & "")) == "cancelado"
            || !reFind("^[1-9][0-9]{0,9}$",qEventosAba.id_evento[liveCircuitRow] & "")
            || !reFind("^[a-zA-Z0-9_-]+$",qEventosAba.tag[liveCircuitRow] & "")
            || uCase(trim(qEventosAba.estado[liveCircuitRow] & "")) != liveCircuitUf) continue;
        VARIABLES.liveCircuitRank = len(liveCircuitCity) && liveCircuitCity == liveCircuitNormalize(qEventosAba.cidade[liveCircuitRow]) ? 2 : 1;
        if (liveCircuitRank > liveCircuitBestRank
            || (liveCircuitRank == liveCircuitBestRank && (dateCompare(qEventosAba.data_inicial[liveCircuitRow],qEventosAba.data_inicial[liveCircuitFeaturedRow]) < 0
                || (dateCompare(qEventosAba.data_inicial[liveCircuitRow],qEventosAba.data_inicial[liveCircuitFeaturedRow]) == 0
                    && val(qEventosAba.id_evento[liveCircuitRow]) < val(qEventosAba.id_evento[liveCircuitFeaturedRow]))))) {
            VARIABLES.liveCircuitFeaturedRow = liveCircuitRow;
            VARIABLES.liveCircuitBestRank = liveCircuitRank;
        }
    }
}
</cfscript>

<cfif VARIABLES.liveCircuitFeaturedRow>
    <style>
        .live-circuit-highlight { border: 2px solid #fab120; border-radius: 12px; background: #fff8e6; overflow: hidden; }
        .live-circuit-highlight-label { margin: 0; padding: .85rem .95rem .25rem; color: #604400; font-size: .78rem; font-weight: 800; letter-spacing: .04em; text-transform: uppercase; }
        .live-circuit-highlight .live-event-card { border: 0; background: transparent; }
        .live-circuit-highlight .live-event-card-body { padding-top: .55rem; }
        .live-circuit-highlight .live-event-card-link:focus-visible { outline: 3px solid #604400; outline-offset: -3px; border-radius: 8px; }
    </style>
</cfif>
<cfif VARIABLES.liveCircuitCouponCards AND qEventosAba.recordCount>
    <style>
        .live-circuit-browser [hidden] { display: none !important; }
        .live-circuit-browser .live-event-card-body { padding: .75rem; }
        .live-circuit-browser .live-event-card-top { grid-template-columns: 48px minmax(0, 1fr); gap: .65rem; }
        .live-circuit-browser .live-event-card-date .day { padding-top: .5rem; font-size: 1.15rem; }
        .live-circuit-browser .live-event-card-title { font-size: .94rem; }
        .live-circuit-browser .live-event-card-flags, .live-circuit-browser .live-event-card-distances { margin-top: .45rem; gap: .3rem; }
        .live-circuit-browser .live-event-flag, .live-circuit-browser .live-event-distance { padding: .32rem .45rem; }
        .live-circuit-browser .live-event-card-badges { margin-top: .5rem; padding-top: .5rem; }
        .live-circuit-browser .live-event-card-cta { display: block; margin-top: .6rem; font-size: .82rem; font-weight: 700; color: #604400; }
        .live-circuit-browser a:focus-visible { outline: 3px solid #604400; outline-offset: 2px; border-radius: 10px; }
    </style>
    <div class="live-circuit-browser" data-live-circuit-browser>
        <div class="mb-3" data-live-city-controls hidden>
            <label for="live-city-select" class="form-label fw-bold">Escolha sua cidade</label>
            <select id="live-city-select" class="form-select" data-live-city-select aria-controls="live-city-events">
                <option value="">Todas as cidades</option>
                <cfoutput><cfloop array="#VARIABLES.liveCircuitCityKeys#" index="VARIABLES.liveCircuitCityKey">
                    <option value="#encodeForHTMLAttribute(VARIABLES.liveCircuitCityKey)#">#encodeForHTML(VARIABLES.liveCircuitCities[VARIABLES.liveCircuitCityKey])#</option>
                </cfloop></cfoutput>
            </select>
            <p class="small text-muted mt-1 mb-0" role="status" aria-live="polite" data-live-city-count></p>
        </div>
</cfif>
<div class="row g-2" data-live-circuit-events<cfif VARIABLES.liveCircuitCouponCards> id="live-city-events"</cfif>>
    <cfif VARIABLES.liveCircuitFeaturedRow>
        <cfoutput query="qEventosAba" startrow="#VARIABLES.liveCircuitFeaturedRow#" maxrows="1">
            <div class="col-12 mb-1" data-live-city="#encodeForHTMLAttribute(liveCircuitCitySlug(cidade,estado))#">
                <section class="live-circuit-highlight" aria-labelledby="live-circuit-highlight-title" data-highlighted-event="#encodeForHTMLAttribute(id_evento)#">
                    <h2 class="live-circuit-highlight-label" id="live-circuit-highlight-title">Etapa em destaque</h2>
                    <div class="row g-0"><cfinclude template="../includes/card_evento_live.cfm"/></div>
                </section>
            </div>
        </cfoutput>
    </cfif>
    <cfoutput query="qEventosAba">
        <cfif qEventosAba.currentRow NEQ VARIABLES.liveCircuitFeaturedRow>
            <cfif VARIABLES.liveCircuitCouponCards><div class="col-12" data-live-city="#encodeForHTMLAttribute(liveCircuitCitySlug(cidade,estado))#"></cfif>
            <cfinclude template="../includes/card_evento_live.cfm"/>
            <cfif VARIABLES.liveCircuitCouponCards></div></cfif>
        </cfif>
    </cfoutput>
</div>

<cfif VARIABLES.liveCircuitCouponCards AND qEventosAba.recordCount>
    </div>
    <script src="/assets/js/rr-live-funnel-ui.js?v=20261020" defer></script>
</cfif>
<cfset VARIABLES.liveCircuitCouponCards = false/>
