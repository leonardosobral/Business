<!--- Physical occupation is independent of ad-delivery counts and billing. --->
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfscript>
audOccupancyReady = structKeyExists(VARIABLES,"audienceOccupancyStatus") AND VARIABLES.audienceOccupancyStatus EQ "ready"
    AND structKeyExists(VARIABLES,"audienceOccupancyQuery");
audOccupancyRows = {};
if (audOccupancyReady) {
    for (audOccupancyRow in VARIABLES.audienceOccupancyQuery) audOccupancyRows[audOccupancyRow.format] = audOccupancyRow;
    audOccupancyReady = structKeyExists(audOccupancyRows,"all") AND structKeyExists(audOccupancyRows,"ads")
        AND structKeyExists(audOccupancyRows,"banners") AND structKeyExists(audOccupancyRows,"other");
}
if (audOccupancyReady) audOccupancyTotal = audOccupancyRows.all;
</cfscript>
<section class="audience-occupancy" aria-label="Oportunidades e ocupação dos espaços">
    <div class="audience-occupancy-top">
        <cfif audOccupancyReady>
            <cfoutput>
            <div class="audience-kpi audience-kpi-primary"><div class="audience-meta">Oportunidades de entrega</div><div class="audience-value" data-occupancy="potential">#audienceCount(audOccupancyTotal.potential)#</div><div class="audience-meta">Posições/páginas aplicáveis no período</div></div>
            <div class="audience-kpi"><div class="audience-meta">Preenchidas</div><div class="audience-value" data-occupancy="filled">#audienceCount(audOccupancyTotal.filled)#</div><div class="audience-meta"><strong data-occupancy-rate="filled">#audienceRate(audOccupancyTotal.filled,audOccupancyTotal.potential)#</strong> das oportunidades · inclui institucionais</div></div>
            <div class="audience-kpi"><div class="audience-meta">Sem anúncio</div><div class="audience-value" data-occupancy="empty">#audienceCount(audOccupancyTotal.empty)#</div><div class="audience-meta"><strong data-occupancy-rate="empty">#audienceRate(audOccupancyTotal.empty,audOccupancyTotal.potential)#</strong> das oportunidades · sem campanha elegível</div></div>
            </cfoutput>
        <cfelse>
            <div class="audience-kpi audience-occupancy-unavailable" role="status">Resumo de ocupação indisponível no momento.<div class="audience-meta">Os demais dados de audiência continuam abaixo. Não há estimativa substituta de preenchimento.</div></div>
        </cfif>
        <div class="audience-kpi audience-people" data-audience-people>
            <div class="audience-meta">Audiência</div>
            <cfoutput><div class="audience-people-values">
                <div><strong>#audienceCount(audStats.visitors)#</strong><span class="audience-meta">visitantes estimados</span></div>
                <div><strong>#audienceCount(audStats.sessions)#</strong><span class="audience-meta">sessões</span></div>
            </div><div class="audience-meta">#audienceCount(audStats.engaged_sessions)# sessões qualificadas<br>#audienceCount(audStats.active_pages)# páginas com atividade</div></cfoutput>
        </div>
    </div>
    <cfif audOccupancyReady>
        <div class="audience-occupation-breakdown">
            <p class="audience-meta audience-occupation-definition">Uma oportunidade corresponde a uma posição por página aplicável, com ou sem peça. Não exige visibilidade e não é garantia futura de entrega nem equivale a créditos.</p>
            <cfoutput><p class="audience-meta audience-note">Anúncios vistos por 1s: <strong data-occupancy-ad-views>#audienceCount(audStats.ad_views)#</strong> <span>(ao menos 50% da peça por 1 segundo; etapa separada, não soma nem taxa das oportunidades).</span></p></cfoutput>
            <cfif val(audOccupancyTotal.unclassified) GT 0><p class="audience-meta audience-note"><cfoutput><strong data-occupancy="unclassified">#audienceCount(audOccupancyTotal.unclassified)#</strong> oportunidades (#audienceRate(audOccupancyTotal.unclassified,audOccupancyTotal.potential)#) sem confirmação. Falhas, posições desligadas ou pendentes não são ausência de anunciante e não entram em “Sem anúncio”.</cfoutput></p></cfif>
            <cfif NOT val(audOccupancyTotal.registered)>
                <p class="audience-meta" role="status">Nenhuma posição registrada neste recorte. Ainda não há base para medir ocupação.</p>
            <cfelseif NOT val(audOccupancyTotal.potential)>
                <p class="audience-meta" role="status">Há posições registradas, mas nenhuma oportunidade aplicável neste recorte; posições não aplicáveis ficam excluídas.</p>
            </cfif>
            <div class="audience-occupation-formats">
            <cfloop list="ads,banners,other" index="audOccupancyFormat">
                <cfset audOccupancyItem = audOccupancyRows[audOccupancyFormat]/>
                <cfset audOccupancyLabel = audOccupancyFormat EQ "ads" ? "Ads" : (audOccupancyFormat EQ "banners" ? "Banners" : "Outros formatos")/>
                <cfif audOccupancyFormat NEQ "other" OR val(audOccupancyItem.registered) GT 0>
                    <cfoutput><div class="audience-occupation-format" data-occupancy-format="#audOccupancyFormat#">
                        <div class="audience-occupation-heading"><strong>#audOccupancyLabel#</strong><span class="audience-meta">#audienceCount(audOccupancyItem.potential)# oportunidades</span></div>
                        <cfif val(audOccupancyItem.potential) GT 0>
                            <div class="audience-occupation-bar" role="img" aria-label="#audOccupancyLabel#: #audienceCount(audOccupancyItem.filled)# oportunidades preenchidas (#audienceRate(audOccupancyItem.filled,audOccupancyItem.potential)#), #audienceCount(audOccupancyItem.empty)# sem anúncio (#audienceRate(audOccupancyItem.empty,audOccupancyItem.potential)#), #audienceCount(audOccupancyItem.unclassified)# sem confirmação (#audienceRate(audOccupancyItem.unclassified,audOccupancyItem.potential)#).">
                                <cfloop list="filled,empty,unclassified" index="audOccupancySegment"><cfif val(audOccupancyItem[audOccupancySegment]) GT 0><span class="audience-occupation-segment audience-occupation-#audOccupancySegment#" data-occupancy-segment="#audOccupancySegment#" style="width:#numberFormat(100 * val(audOccupancyItem[audOccupancySegment])/val(audOccupancyItem.potential),'0.0000')#%"></span></cfif></cfloop>
                            </div>
                            <div class="audience-occupation-legend audience-meta">
                                <span><i class="audience-occupation-filled" aria-hidden="true"></i>#audienceCount(audOccupancyItem.filled)# preenchidas <strong>#audienceRate(audOccupancyItem.filled,audOccupancyItem.potential)#</strong></span>
                                <span><i class="audience-occupation-empty" aria-hidden="true"></i>#audienceCount(audOccupancyItem.empty)# sem anúncio <strong>#audienceRate(audOccupancyItem.empty,audOccupancyItem.potential)#</strong></span>
                                <cfif val(audOccupancyItem.unclassified) GT 0><span><i class="audience-occupation-unclassified" aria-hidden="true"></i>#audienceCount(audOccupancyItem.unclassified)# sem confirmação <strong>#audienceRate(audOccupancyItem.unclassified,audOccupancyItem.potential)#</strong></span></cfif>
                            </div>
                        <cfelse><p class="audience-meta mb-0">Sem oportunidades aplicáveis; percentual indisponível.</p></cfif>
                    </div></cfoutput>
                </cfif>
            </cfloop>
            </div>
        </div>
    </cfif>
    <details class="audience-occupation-diagnostics" data-occupancy-diagnostics>
        <summary>Detalhes da medição e contadores técnicos</summary>
        <div class="audience-meta">
            <cfif audOccupancyReady><cfoutput><p>#audienceCount(audOccupancyTotal.registered)# posições/páginas registradas; #audienceCount(val(audOccupancyTotal.registered)-val(audOccupancyTotal.potential))# não aplicáveis excluídas das oportunidades.</p></cfoutput></cfif>
            <p>Preenchida significa que há anúncio, peça institucional ou sinal de veiculação/renderização, mesmo sem visualização por 1 segundo. “Sem anúncio” exige estado explícito de vazio, sem campanha elegível; falhas, posições desligadas ou pendentes ficam sem confirmação. Isso não comprova faturamento nem mede o tempo de cada criativo.</p>
            <p>A origem são sinais de inventário. Uma oportunidade vazia não precisa ter sido vista para entrar no recorte. Mudanças sem sinal persistido não são reconstruídas. Trocas de anúncio e atividade em várias UFs não duplicam a mesma posição/página no total selecionado.</p>
            <p>Ads e banners são separados pelas posições e formatos conhecidos. Formatos não reconhecidos ou conflitantes permanecem em “Outros formatos”. Os mesmos filtros do relatório valem para a ocupação.</p>
            <cfoutput><dl class="audience-technical-counts">
                <div><dt>Posições registradas — sinais</dt><dd>#audienceCount(audStats.opportunities)#</dd></div>
                <div><dt>Posições vistas por 1s — sinais</dt><dd>#audienceCount(audStats.slot_views)#</dd></div>
                <div><dt>Anúncios vistos por 1s — sinais</dt><dd>#audienceCount(audStats.ad_views)#</dd></div>
                <div><dt>Anúncios renderizados — sinais</dt><dd>#audienceCount(audStats.ad_renders)#</dd></div>
                <div><dt>Aberturas de página</dt><dd>#audienceCount(audStats.pageviews)#</dd></div>
            </dl></cfoutput>
            <p class="mb-0">Esses sinais técnicos têm outra unidade e podem superar as oportunidades físicas. Não são somados diretamente ao numerador ou denominador da ocupação.</p>
        </div>
    </details>
</section>
