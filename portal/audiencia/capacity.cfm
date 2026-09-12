<cfinclude template="../../includes/backend/require_admin.cfm"/>
<section class="audience-panel" id="capacidade" aria-labelledby="audience-capacity-title">
    <h2 id="audience-capacity-title" class="h5">Capacidade em exposições</h2>
    <cfif VARIABLES.audienceCapacityStatus EQ "not_commercial">
        <p class="audience-meta mb-0" role="status">Para analisar capacidade comercial, use <strong>Contexto comercial</strong>, ambiente <strong>prod</strong> e desmarque <strong>Incluir acessos internos</strong>. Os demais relatórios continuam disponíveis com os filtros atuais.</p>
    <cfelseif VARIABLES.audienceCapacityStatus NEQ "ready">
        <p class="audience-meta mb-0" role="status">A capacidade está indisponível nesta consulta; isso não significa audiência zero. Os contadores das outras seções são independentes.</p>
    <cfelse>
        <cfscript>
            audCapacityTotal = {};
            audCapacityRows = [];
            for (audCapacityRow in VARIABLES.audienceCapacityQuery) {
                if (audCapacityRow.row_type EQ "total") audCapacityTotal = audCapacityRow;
                else if (audCapacityRow.row_type EQ "detail") arrayAppend(audCapacityRows,audCapacityRow);
            }
        </cfscript>
        <cfif NOT structKeyExists(audCapacityTotal,"opportunities")>
            <p class="audience-meta mb-0" role="status">Resumo de capacidade indisponível; não há total confirmado para esta consulta.</p>
        <cfelseif NOT val(audCapacityTotal.opportunities)>
            <p class="audience-meta mb-0" role="status">Nenhuma posição registrada neste recorte. Isso não comprova audiência zero nas áreas sem medição; ainda não há base para projetar exposições.</p>
        <cfelse>
            <p class="audience-meta">Exposições de posições físicas, com ou sem campanha. Visibilidade exige 50% da área por 1 segundo contínuo; não representa pessoas únicas nem inventário livre para venda.</p>
            <cfoutput>
            <div class="row g-3 mb-3" aria-label="Capacidade observada no período selecionado">
                <div class="col-12 col-sm-4"><div class="audience-meta">Exposições visíveis observadas</div><div class="audience-value text-warning" data-capacity="views">#audienceCount(audCapacityTotal.slot_views)#</div></div>
                <div class="col-6 col-sm-4"><div class="audience-meta">Posições montadas</div><div class="audience-value" data-capacity="renders">#audienceCount(audCapacityTotal.renders)#</div></div>
                <div class="col-6 col-sm-4"><div class="audience-meta">Posições registradas</div><div class="audience-value" data-capacity="opportunities">#audienceCount(audCapacityTotal.opportunities)#</div></div>
            </div>
            <p class="audience-meta">#VARIABLES.audienceDays# dias selecionados · UF comercial: <cfif NOT len(VARIABLES.audienceUf)>todas<cfelseif VARIABLES.audienceUf EQ "--">desconhecida<cfelse>#encodeForHtml(VARIABLES.audienceUf)#</cfif> · Última recepção: #audienceDate(audCapacityTotal.last_received)# · Brasília · cache de até 1 minuto.</p>
            </cfoutput>
            <p class="audience-note audience-meta">Os totais acima contam cada posição uma vez por página no recorte. A mesma posição pode participar de SC e SP quando o contexto muda; por isso, as linhas regionais não devem ser somadas para obter o total físico.</p>
            <cfif VARIABLES.audienceDays LT 15><p class="audience-meta" role="status">Selecione <strong>30 ou 90 dias</strong> para incluir a janela necessária aos cenários. As contagens observadas continuam disponíveis nos 7 dias.</p></cfif>
            <p class="audience-meta">Cenários de exposição se o ritmo se repetir; não são garantia de entrega. A base exige sinais diários, mas não comprova coleta sem interrupções.</p>
            <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Capacidade por UF e posição, role horizontalmente para consultar os cenários">
                <table class="table table-sm mb-0 audience-capacity-table">
                    <thead><tr><th scope="col">UF comercial</th><th scope="col">Posição / página</th><th scope="col">Dispositivo</th><th scope="col">Registradas</th><th scope="col">Montadas</th><th scope="col">Exposições</th><th scope="col">Histórico disponível</th><th scope="col">Cenários para 30 dias</th></tr></thead>
                    <tbody><cfloop from="1" to="#min(arrayLen(audCapacityRows),200)#" index="audCapacityIndex"><cfset audCapacityRow = audCapacityRows[audCapacityIndex]/><cfoutput>
                        <tr>
                            <td><cfif audCapacityRow.audience_uf EQ "--">Desconhecida<cfelse>#encodeForHtml(audCapacityRow.audience_uf)#</cfif></td>
                            <td class="audience-text">#encodeForHtml(audCapacityRow.slot_key)#<div class="audience-meta">#encodeForHtml(audienceLabel(audCapacityRow.page_family))#</div></td>
                            <td>#encodeForHtml(audienceLabel(audCapacityRow.device_class))#</td>
                            <td>#audienceCount(audCapacityRow.opportunities)#</td><td>#audienceCount(audCapacityRow.renders)#</td><td>#audienceCount(audCapacityRow.slot_views)#</td>
                            <td><cfif isDate(audCapacityRow.first_day)>Desde #dateFormat(audCapacityRow.first_day,"dd/mm/yyyy")#<cfelse>Sem data confirmada</cfif><div class="audience-meta">#audienceCount(audCapacityRow.days_observed)# dias encerrados com sinais</div>
                                <cfif val(audCapacityRow.missing_days_14) GT 0><div class="audience-meta">#audienceCount(audCapacityRow.missing_days_14)# dos últimos 14 dias sem base utilizável</div></cfif>
                            </td>
                            <td>
                                <cfif val(audCapacityRow.baseline_days) GTE 14 AND val(audCapacityRow.baseline_views) GT 0 AND structKeyExists(audCapacityRow,"low_30") AND isNumeric(audCapacityRow.low_30) AND structKeyExists(audCapacityRow,"base_30") AND isNumeric(audCapacityRow.base_30)>
                                    <div class="text-nowrap"><span data-scenario="low">#audienceCount(audCapacityRow.low_30)#</span> / <span data-scenario="base">#audienceCount(audCapacityRow.base_30)#</span></div>
                                    <div class="audience-meta">Semana mais fraca / ritmo médio<br>Base: #audCapacityRow.baseline_days# dias</div>
                                <cfelseif val(audCapacityRow.baseline_days) GTE 14 AND NOT val(audCapacityRow.baseline_views)>
                                    <span class="audience-meta">Sem exposição observada na base</span>
                                <cfelse><span class="audience-meta">Histórico insuficiente</span></cfif>
                            </td>
                        </tr>
                    </cfoutput></cfloop></tbody>
                </table>
            </div>
            <cfif val(audCapacityTotal.total_rows) GT 200><p class="audience-meta mt-2">Exibindo as 200 combinações com mais registros. Os totais acima incluem todas as posições do recorte. Use os filtros para consultar outros grupos.</p></cfif>
            <details class="mt-3"><summary>Como os cenários são calculados e quais são os limites</summary>
                <div class="audience-definition-grid audience-meta">
                    <p><strong>Base recente por posição e UF</strong><br>Usamos os últimos 28 dias encerrados quando há sinais da posição em todos eles; caso contrário, os últimos 14. Hoje e o primeiro dia observado no recorte ficam fora da base, pois podem ser parciais. Dias ausentes não viram zero.</p>
                    <p><strong>Se o ritmo observado se repetir</strong><br>O ritmo médio é a exposição da base dividida por seus dias e multiplicada por 30. O cenário inferior usa a semana de menor volume entre os blocos de 7 dias dessa mesma base. Valores são arredondados para baixo; não são intervalo de confiança nem garantia de entrega.</p>
                    <p><strong>Limites para uso comercial</strong><br>Sinais diários não comprovam coleta contínua. Falhas, mudanças de apresentação e sazonalidade podem alterar o resultado. Há posições ocupadas, institucionais ou indisponíveis: o cenário não desconta concorrência nem compromissos e não estima cliques ou créditos.</p>
                </div>
            </details>
        </cfif>
    </cfif>
</section>
