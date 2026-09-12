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
<div class="row g-2" data-live-circuit-events>
    <cfif VARIABLES.liveCircuitFeaturedRow>
        <cfoutput query="qEventosAba" startrow="#VARIABLES.liveCircuitFeaturedRow#" maxrows="1">
            <div class="col-12 mb-1">
                <section class="live-circuit-highlight" aria-labelledby="live-circuit-highlight-title" data-highlighted-event="#HTMLEditFormat(id_evento)#">
                    <h2 class="live-circuit-highlight-label" id="live-circuit-highlight-title">Etapa em destaque</h2>
                    <div class="row g-0"><cfinclude template="../includes/card_evento_live.cfm"/></div>
                </section>
            </div>
        </cfoutput>
    </cfif>
    <cfoutput query="qEventosAba">
        <cfif qEventosAba.currentRow NEQ VARIABLES.liveCircuitFeaturedRow>
            <cfinclude template="../includes/card_evento_live.cfm"/>
        </cfif>
    </cfoutput>
</div>
