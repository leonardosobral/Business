<cfinclude template="../../includes/backend/require_admin.cfm"/>
<section class="audience-panel" id="jornada-live">
    <h2 class="h5">Caminho até a inscrição LIVE!</h2>
    <p class="audience-meta">Campanhas identificadas por UTM: chegada ao Road Runners, visita à prova e clique de saída para a LIVE!. Saída é um encaminhamento; não confirma carregamento no parceiro, inscrição paga ou receita.</p>
    <form method="get" action="/portal/audiencia/#jornada-live" aria-label="Filtros da jornada LIVE!" class="mb-3">
        <cfoutput>
            <input type="hidden" name="dias" value="#VARIABLES.audienceDays#"/>
            <input type="hidden" name="regiao" value="#encodeForHtmlAttribute(VARIABLES.audienceDimension)#"/>
            <input type="hidden" name="uf" value="#encodeForHtmlAttribute(VARIABLES.audienceUf)#"/>
            <input type="hidden" name="pagina" value="#encodeForHtmlAttribute(VARIABLES.audienceFamily)#"/>
            <input type="hidden" name="dispositivo" value="#encodeForHtmlAttribute(VARIABLES.audienceDevice)#"/>
            <input type="hidden" name="ambiente" value="#encodeForHtmlAttribute(VARIABLES.audienceEnvironment)#"/>
            <cfif VARIABLES.audienceIncludeInternal><input type="hidden" name="internos" value="1"/></cfif>
            <div class="row g-2 align-items-end">
                <div class="col-6 col-lg-2"><label for="live-source" class="form-label small">Origem exata</label><input id="live-source" name="live_origem" class="form-control form-control-sm" maxlength="100" placeholder="Todas" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveSource)#"/></div>
                <div class="col-6 col-lg-3"><label for="live-campaign" class="form-label small">Campanha contém</label><input id="live-campaign" name="live_campanha" class="form-control form-control-sm" maxlength="100" placeholder="Todas" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveCampaign)#"/></div>
                <div class="col-6 col-lg-3"><label for="live-city" class="form-label small">Cidade da prova contém</label><input id="live-city" name="live_cidade" class="form-control form-control-sm" maxlength="100" placeholder="Todas" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveCity)#"/></div>
                <div class="col-6 col-lg-2"><label for="live-event" class="form-label small">ID da prova</label><input id="live-event" name="live_prova" class="form-control form-control-sm" maxlength="10" inputmode="numeric" pattern="[1-9][0-9]{0,9}" placeholder="Todas" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveEvent)#"/></div>
                <div class="col-12 col-lg-2"><button type="submit" class="btn btn-outline-warning btn-sm w-100">Filtrar jornada</button></div>
            </div>
        </cfoutput>
    </form>
    <p class="audience-meta">Período, região, página, dispositivo e acessos internos seguem os filtros gerais. Cidade e ID restringem somente o detalhe por prova; o resumo conserva todas as chegadas da campanha no recorte. Cidade da prova não é localização do visitante.</p>
    <cfif VARIABLES.audienceLiveUnavailable>
        <div class="alert alert-warning mb-0" role="status">A jornada LIVE! está indisponível agora. Isso não significa ausência de visitas ou saídas. Os demais relatórios permanecem independentes.</div>
    <cfelse>
        <cfset audLiveRows = VARIABLES.audienceLiveQuery/>
        <cfquery name="audLiveCampaigns" dbtype="query">SELECT * FROM audLiveRows WHERE row_type='campaign' ORDER BY sessions DESC,source,medium,campaign</cfquery>
        <cfquery name="audLiveEvents" dbtype="query">SELECT * FROM audLiveRows WHERE row_type='event' ORDER BY event_sessions DESC,source,medium,campaign,content_id</cfquery>
        <h3 class="h6">Resumo por campanha</h3>
        <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Resumo da jornada por campanha">
            <table class="table table-sm mb-0"><thead><tr><th scope="col">Campanha / origem</th><th scope="col">Sessões com abertura</th><th scope="col">Aberturas no Road Runners</th><th scope="col">Qualificadas</th><th scope="col">Sessões com prova LIVE!</th><th scope="col">Sessões com saída</th><th scope="col">Visita à prova + saída</th><th scope="col">Chegada → prova → saída</th></tr></thead><tbody>
                <cfoutput query="audLiveCampaigns" maxrows="100"><tr>
                    <td class="audience-text">#encodeForHtml(campaign)#<div class="audience-meta">#encodeForHtml(source)# / #encodeForHtml(medium)#</div><div class="audience-meta">Recepção: #audienceDate(last_received)#</div></td>
                    <td>#audienceCount(sessions)#</td><td>#audienceCount(pageviews)#</td><td>#audienceCount(qualified_sessions)#</td><td>#audienceCount(event_sessions)#</td>
                    <td>#audienceCount(outbound_sessions)#<cfif val(unmatched_outbound_sessions)><div class="audience-meta">#audienceCount(unmatched_outbound_sessions)# sem abertura correspondente</div></cfif><div class="audience-meta"><cfif val(outbound_sessions)>Primeira saída recebida no recorte: #audienceDate(first_outbound)#<cfelse>Nenhuma saída recebida; cobertura ainda não comprovada.</cfif></div></td>
                    <td>#audienceCount(matched_outbound_sessions)#</td><td><cfif val(outbound_sessions)>#audienceRate(matched_outbound_sessions,sessions)#<cfelse>—</cfif></td>
                </tr></cfoutput>
                <cfif NOT audLiveCampaigns.recordcount><tr><td colspan="8" class="text-muted">Nenhuma atividade com campanha UTM identificada neste recorte.</td></tr></cfif>
            </tbody></table>
        </div>
        <cfif audLiveCampaigns.recordcount GT 100><p class="audience-meta mt-2">Exibindo as 100 campanhas/origens com mais sessões. Cada linha conserva o total integral da campanha no recorte.</p></cfif>
        <h3 class="h6 mt-4">Visitas e saídas por prova</h3>
        <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Jornada LIVE por prova e cidade">
            <table class="table table-sm mb-0"><thead><tr><th scope="col">Campanha / origem</th><th scope="col">Prova / cidade</th><th scope="col">Aberturas da prova</th><th scope="col">Sessões com visita</th><th scope="col">Sessões com saída</th><th scope="col">Visita + saída</th><th scope="col">Visita → saída</th></tr></thead><tbody>
                <cfoutput query="audLiveEvents" maxrows="200"><tr>
                    <td class="audience-text">#encodeForHtml(campaign)#<div class="audience-meta">#encodeForHtml(source)# / #encodeForHtml(medium)#</div></td>
                    <td class="audience-text"><cfif reFind("^[a-zA-Z0-9_-]+$",event_tag)><a href="https://roadrunners.run/evento/#encodeForHtmlAttribute(event_tag)#/" target="_blank" rel="noopener noreferrer">#encodeForHtml(event_name)#</a><cfelse>#encodeForHtml(event_name)#</cfif><div class="audience-meta"><cfif len(trim(event_city))>#encodeForHtml(event_city)#<cfelse>Cidade não informada</cfif><cfif len(trim(event_uf))> / #encodeForHtml(event_uf)#</cfif> · ID #encodeForHtml(content_id)#</div></td>
                    <td>#audienceCount(pageviews)#</td><td>#audienceCount(event_sessions)#</td><td>#audienceCount(outbound_sessions)#<cfif val(unmatched_outbound_sessions)><div class="audience-meta">#audienceCount(unmatched_outbound_sessions)# sem abertura correspondente</div></cfif></td><td>#audienceCount(matched_outbound_sessions)#</td><td><cfif val(outbound_sessions)>#audienceRate(matched_outbound_sessions,event_sessions)#<cfelse>—</cfif></td>
                </tr></cfoutput>
                <cfif NOT audLiveEvents.recordcount><tr><td colspan="7" class="text-muted">Nenhuma visita ou saída LIVE! identificada para estas provas no recorte.</td></tr></cfif>
            </tbody></table>
        </div>
        <cfif audLiveEvents.recordcount GT 200><p class="audience-meta mt-2">Exibindo as 200 combinações com mais sessões de visita. Os totais por campanha não são limitados por este detalhamento.</p></cfif>
        <div class="audience-note audience-meta mt-3">
            <p class="mb-2">Repetir uma saída conta uma vez por sessão e prova. O resumo deduplica também entre provas e variantes; não some as linhas de cidades como pessoas distintas. Uma sessão pode ter saídas com e sem abertura correspondente em provas diferentes.</p>
            <p class="mb-2">As taxas usam somente sessões com abertura confirmada da prova e saída correspondente. Saídas sem essa abertura são mostradas à parte: podem partir do modal no circuito sem abrir o detalhe da prova ou refletir perda de coleta. Sessões qualificadas têm 30 segundos ativos ou duas páginas abertas distintas no recorte.</p>
            <p class="mb-0">Zero significa nenhuma saída recebida; sem saída recebida na linha, a taxa fica indisponível (—). Antes da implantação dessa medição não há histórico de saídas; a primeira recepção não comprova a data de ativação nem cobertura completa. Bloqueios, recusa e falhas de coleta limitam os números. A UTM conserva a origem do início da sessão; não representa último clique pago. Compras e comissão exigem conciliação com a LIVE!.</p>
        </div>
    </cfif>
</section>
