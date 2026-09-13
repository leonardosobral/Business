<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfscript>
audRegionOccupancyReady = structKeyExists(VARIABLES,"audienceRegionOccupancyStatus")
    AND VARIABLES.audienceRegionOccupancyStatus EQ "ready"
    AND structKeyExists(VARIABLES,"audienceRegionOccupancyQuery") AND isQuery(VARIABLES.audienceRegionOccupancyQuery);
audRegionFormats = ["all","ads","banners"];
audRegionFormatLabels = {"all"="Total","ads"="Ads","banners"="Banners","other"="Outros formatos"};
audRegionFormatRows = {"all"=[],"ads"=[],"banners"=[],"other"=[]};
audRegionHasOther = false;
if (audRegionOccupancyReady) {
    for (audRegionColumn in listToArray("audience_uf,format,registered,potential,filled,empty,unclassified")) {
        if (NOT listFindNoCase(VARIABLES.audienceRegionOccupancyQuery.columnList,audRegionColumn)) audRegionOccupancyReady = false;
    }
}
if (audRegionOccupancyReady) {
    for (audRegionSourceRow in VARIABLES.audienceRegionOccupancyQuery) {
        if (structKeyExists(audRegionFormatRows,audRegionSourceRow.format)) {
            audRegionItem = duplicate(audRegionSourceRow);
            audRegionItem.countsReady = true;
            for (audRegionColumn in listToArray("registered,potential,filled,empty,unclassified")) {
                if (NOT structKeyExists(audRegionItem,audRegionColumn) OR NOT isNumeric(audRegionItem[audRegionColumn]) OR val(audRegionItem[audRegionColumn]) LT 0) audRegionItem.countsReady = false;
            }
            arrayAppend(audRegionFormatRows[audRegionItem.format],audRegionItem);
            if (audRegionItem.format EQ "other" AND audRegionItem.countsReady AND val(audRegionItem.registered) GT 0) audRegionHasOther = true;
        }
    }
    if (audRegionHasOther) arrayAppend(audRegionFormats,"other");
    for (audRegionFormat in audRegionFormats) {
        // Sort fresh display arrays; other consumers retain the query's original rows.
        arraySort(audRegionFormatRows[audRegionFormat],function(a,b) {
            if (a.countsReady NEQ b.countsReady) return a.countsReady ? -1 : 1;
            if (a.countsReady AND val(a.empty) NEQ val(b.empty)) return val(a.empty) GT val(b.empty) ? -1 : 1;
            if (a.countsReady AND val(a.potential) NEQ val(b.potential)) return val(a.potential) GT val(b.potential) ? -1 : 1;
            return compare(a.audience_uf,b.audience_uf);
        });
    }
}
</cfscript>
<section class="audience-panel" id="regioes" aria-labelledby="audience-regions-title">
    <h2 id="audience-regions-title" class="h5">Ocupação por UF</h2>
    <p class="audience-meta">Oportunidades de entrega, preenchimento e espaços sem anúncio na dimensão regional selecionada. Os filtros de período, UF, página e dispositivo se aplicam a todas as linhas.</p>
    <p class="audience-meta audience-note">Uma mesma posição/página pode ter atividade em mais de uma UF. Os valores regionais não devem ser somados para obter o total geral, que permanece deduplicado na visão geral.</p>
    <cfif NOT audRegionOccupancyReady>
        <p class="audience-meta" role="status">A ocupação por UF está indisponível nesta consulta. Isso não significa ausência de oportunidades; os dados históricos disponíveis permanecem abaixo.</p>
    <cfelseif NOT VARIABLES.audienceRegionOccupancyQuery.recordcount>
        <p class="audience-meta" role="status">Nenhuma posição registrada por UF neste recorte. Ainda não há base para medir ocupação.</p>
    <cfelse>
        <nav class="audience-region-filters" data-region-filters aria-label="Formato da ocupação por UF">
            <cfoutput><cfloop array="#audRegionFormats#" index="audRegionFormat"><a href="##regioes-#audRegionFormat#" data-region-choice="#audRegionFormat#">#audRegionFormatLabels[audRegionFormat]#</a></cfloop></cfoutput>
        </nav>
        <div class="audience-occupation-legend audience-meta mb-3" aria-label="Legenda da ocupação">
            <span><i class="audience-occupation-filled" aria-hidden="true"></i>Preenchidas · inclui institucionais</span>
            <span><i class="audience-occupation-empty" aria-hidden="true"></i>Sem anúncio</span>
            <span><i class="audience-occupation-unclassified" aria-hidden="true"></i>Sem confirmação</span>
        </div>
        <cfloop array="#audRegionFormats#" index="audRegionFormat">
            <cfoutput><section id="regioes-#audRegionFormat#" data-region-format="#audRegionFormat#" aria-labelledby="regioes-#audRegionFormat#-title">
                <h3 id="regioes-#audRegionFormat#-title" class="audience-section-title">#audRegionFormatLabels[audRegionFormat]# por UF</h3>
                <p class="audience-meta">Ordenado pelo volume sem anúncio. Percentuais sobre as oportunidades aplicáveis de cada UF.</p>
                <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="#audRegionFormatLabels[audRegionFormat]# por UF; role horizontalmente para todas as métricas">
                    <table class="table table-sm audience-region-table"><thead><tr><th scope="col">UF</th><th scope="col">Oportunidades</th><th scope="col">Preenchidas</th><th scope="col">Sem anúncio</th><th scope="col">Sem confirmação</th><th scope="col">Ocupação</th></tr></thead><tbody>
                    <cfloop array="#audRegionFormatRows[audRegionFormat]#" index="audRegionItem">
                        <cfset audRegionUfLabel = audRegionItem.audience_uf EQ "--" ? "Desconhecida" : audRegionItem.audience_uf/>
                        <tr data-region-uf="#encodeForHtmlAttribute(audRegionItem.audience_uf)#">
                            <th scope="row">#encodeForHtml(audRegionUfLabel)#</th>
                            <cfif audRegionItem.countsReady>
                                <td><strong data-region-count="potential">#audienceCount(audRegionItem.potential)#</strong><cfif NOT val(audRegionItem.potential)><div class="audience-meta"><cfif val(audRegionItem.registered)>Sem aplicabilidade<cfelse>Sem posições registradas</cfif></div></cfif></td>
                                <cfloop list="filled,empty,unclassified" index="audRegionSegment"><td><span data-region-count="#audRegionSegment#">#audienceCount(audRegionItem[audRegionSegment])#</span><div class="audience-meta" data-region-rate="#audRegionSegment#">#audienceRate(audRegionItem[audRegionSegment],audRegionItem.potential)#</div></td></cfloop>
                                <td><cfif val(audRegionItem.potential) GT 0>
                                    <div class="audience-occupation-bar" role="img" aria-label="#encodeForHtmlAttribute(audRegionUfLabel)#, #audRegionFormatLabels[audRegionFormat]#: #audienceCount(audRegionItem.filled)# preenchidas (#audienceRate(audRegionItem.filled,audRegionItem.potential)#), #audienceCount(audRegionItem.empty)# sem anúncio (#audienceRate(audRegionItem.empty,audRegionItem.potential)#), #audienceCount(audRegionItem.unclassified)# sem confirmação (#audienceRate(audRegionItem.unclassified,audRegionItem.potential)#).">
                                        <cfloop list="filled,empty,unclassified" index="audRegionSegment"><cfif val(audRegionItem[audRegionSegment]) GT 0><span class="audience-occupation-segment audience-occupation-#audRegionSegment#" data-region-segment="#audRegionSegment#" style="width:#numberFormat(100*val(audRegionItem[audRegionSegment])/val(audRegionItem.potential),'0.0000')#%"></span></cfif></cfloop>
                                    </div>
                                <cfelse><span class="audience-meta">—</span></cfif></td>
                            <cfelse><td colspan="5" class="audience-meta">Contagens indisponíveis para esta UF.</td></cfif>
                        </tr>
                    </cfloop>
                    <cfif NOT arrayLen(audRegionFormatRows[audRegionFormat])><tr><td colspan="6" class="audience-meta">Sem dados disponíveis para este formato no recorte.</td></tr></cfif>
                    </tbody></table>
                </div>
            </section></cfoutput>
        </cfloop>
        <p class="audience-meta mt-3">“Sem anúncio” exige confirmação de ausência de campanha elegível. Falhas, posições desligadas e estados pendentes permanecem sem confirmação. Posições não aplicáveis ficam fora das oportunidades; “—” indica percentual sem base aplicável.</p>
    </cfif>
    <details class="audience-region-audience" data-region-audience>
        <summary>Regiões do público · páginas, visitantes e sinais históricos</summary>
        <p class="audience-meta">Páginas e visitantes com atividade no recorte, inclusive posições carregadas depois da abertura inicial. Os contadores de posições abaixo são sinais técnicos, com unidade diferente das oportunidades de entrega.</p>
        <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Audiência histórica por UF"><table class="table table-sm"><thead><tr><th scope="col">UF</th><th scope="col">Páginas com atividade</th><th scope="col">Visitantes</th><th scope="col">Posições registradas</th><th scope="col">Posições visíveis</th></tr></thead><tbody>
            <cfset audRegions = VARIABLES.audienceQueries.regions/><cfoutput query="audRegions"><tr><td><cfif audience_uf EQ "--">Desconhecida<cfelse>#encodeForHtml(audience_uf)#</cfif></td><td>#audienceCount(active_pages)#</td><td>#audienceCount(visitors)#</td><td>#audienceCount(opportunities)#</td><td>#audienceCount(slot_views)#</td></tr></cfoutput>
            <cfif NOT audRegions.recordcount><tr><td colspan="5" class="text-muted">Sem dados para o período.</td></tr></cfif>
        </tbody></table></div>
    </details>
</section>
