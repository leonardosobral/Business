<cfinclude template="../../includes/backend/require_admin.cfm"/>
<link rel="stylesheet" href="/assets/css/audience-dashboard.css?v=20260907"/>
<script defer src="/assets/js/audience-dashboard.js?v=20260907"></script>
<div class="audience-page">
    <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
        <div><div class="audience-eyebrow">ROADRUNNERS / BUSINESS</div>
            <h1 class="audience-title mb-2">Audiência e inventário</h1>
            <p class="text-muted mb-0">De onde vem o público, quais regiões ele procura e quanto cada posição pode entregar.</p>
        </div>
        <div class="d-flex gap-2 flex-wrap"><a href="?dias=30&amp;uf=SC&amp;regiao=market" class="btn btn-outline-warning btn-sm">Ver piloto SC</a><a href="/ads/" class="btn btn-outline-secondary btn-sm">Campanhas Ads</a></div>
    </div>

    <form method="get" class="audience-panel" aria-label="Filtros de audiência">
        <cfif structKeyExists(VARIABLES,"audienceLiveSource")><cfoutput>
            <input type="hidden" name="live_origem" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveSource)#"/>
            <input type="hidden" name="live_campanha" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveCampaign)#"/>
            <input type="hidden" name="live_cidade" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveCity)#"/>
            <input type="hidden" name="live_prova" value="#encodeForHtmlAttribute(VARIABLES.audienceLiveEvent)#"/>
        </cfoutput></cfif>
        <div class="row g-3 align-items-end">
            <div class="col-6 col-md-2"><label for="aud-days" class="form-label small">Período</label>
                <select id="aud-days" name="dias" class="form-select form-select-sm"><cfoutput><cfloop list="7,30,90" index="audOption"><option value="#audOption#" <cfif val(audOption) EQ VARIABLES.audienceDays>selected</cfif>>#audOption# dias</option></cfloop></cfoutput></select></div>
            <div class="col-6 col-md-3"><label for="aud-region" class="form-label small">Interpretar região por</label>
                <select id="aud-region" name="regiao" class="form-select form-select-sm">
                    <option value="market" <cfif VARIABLES.audienceDimension EQ "market">selected</cfif>>Contexto comercial</option>
                    <option value="visitor" <cfif VARIABLES.audienceDimension EQ "visitor">selected</cfif>>UF do acesso</option>
                    <option value="profile" <cfif VARIABLES.audienceDimension EQ "profile">selected</cfif>>UF do perfil</option>
                    <option value="context" <cfif VARIABLES.audienceDimension EQ "context">selected</cfif>>UF da página / busca</option>
                </select></div>
            <div class="col-6 col-md-2"><label for="aud-uf" class="form-label small">UF</label>
                <select id="aud-uf" name="uf" class="form-select form-select-sm"><option value="">Todas</option><cfoutput><cfloop list="#VARIABLES.audienceUfList#" index="audOption"><option value="#audOption#" <cfif audOption EQ VARIABLES.audienceUf>selected</cfif>><cfif audOption EQ "--">Desconhecida<cfelse>#audOption#</cfif></option></cfloop></cfoutput></select></div>
            <div class="col-6 col-md-3"><label for="aud-family" class="form-label small">Página</label>
                <select id="aud-family" name="pagina" class="form-select form-select-sm"><option value="">Todas</option><cfoutput><cfloop list="#VARIABLES.audienceFamilies#" index="audOption"><option value="#audOption#" <cfif audOption EQ VARIABLES.audienceFamily>selected</cfif>>#encodeForHtml(audienceLabel(audOption))#</option></cfloop></cfoutput></select></div>
            <div class="col-6 col-md-2"><label for="aud-device" class="form-label small">Dispositivo</label>
                <select id="aud-device" name="dispositivo" class="form-select form-select-sm"><option value="">Todos</option><cfoutput><cfloop list="MOBILE,TABLET,DESKTOP,UNKNOWN" index="audOption"><option value="#audOption#" <cfif audOption EQ VARIABLES.audienceDevice>selected</cfif>>#audienceLabel(audOption)#</option></cfloop></cfoutput></select></div>
            <div class="col-6 col-md-2"><button type="submit" class="btn btn-warning btn-sm w-100">Aplicar filtros</button></div>
            <div class="col-6 col-md-2"><a href="/portal/audiencia/" class="btn btn-link btn-sm">Limpar filtros</a></div>
        </div>
        <details class="audience-advanced" <cfif VARIABLES.audienceEnvironment NEQ "prod" OR VARIABLES.audienceIncludeInternal>open</cfif>><summary>Ambiente e acessos internos</summary><div class="row g-3 align-items-end">
            <div class="col-6 col-md-2"><label for="aud-env" class="form-label small">Ambiente</label>
                <select id="aud-env" name="ambiente" class="form-select form-select-sm"><cfoutput><cfloop list="prod,beta,dev" index="audOption"><option value="#audOption#" <cfif audOption EQ VARIABLES.audienceEnvironment>selected</cfif>>#audOption#</option></cfloop></cfoutput></select></div>
            <div class="col-6 col-md-3"><label class="form-check-label small"><input type="checkbox" name="internos" value="1" class="form-check-input me-1" <cfif VARIABLES.audienceIncludeInternal>checked</cfif>> Incluir acessos internos</label></div>
        </div></details>
        <p class="audience-meta mt-3 mb-0"><strong>Contexto comercial:</strong> buscar provas em SC conta para SC, mesmo com acesso de SP. As UFs de origem, perfil e contexto permanecem separadas.</p>
    </form>

    <cfif VARIABLES.audienceUnavailable>
        <div class="alert alert-warning" role="status">Não foi possível consultar a medição agora. Os dados estão indisponíveis; isso não significa ausência de acessos. Tente novamente após verificar a coleta.</div>
    <cfelseif NOT VARIABLES.audienceReady>
        <div class="audience-panel py-5 text-center"><i class="fa-solid fa-chart-simple fa-2x text-warning mb-3" aria-hidden="true"></i><h2 class="h5">Medição aguardando instalação</h2><p class="text-muted mb-0">A base de audiência ainda não está disponível. Após a instalação e ativação da coleta no RoadRunners, os acessos e as posições aparecerão aqui.</p></div>
    <cfelse>
        <cfset audStats = VARIABLES.audienceSummary/>
        <cfset audDaily = VARIABLES.audienceQueries.daily/>
        <cfset audRegions = VARIABLES.audienceQueries.regions/>
        <cfscript>
            audChartData = {"daily"=[],"regions"=[]};
            for (audChartRow in audDaily) {
                arrayAppend(audChartData.daily,{"day"=dateFormat(audChartRow.day,"yyyy-mm-dd"),
                    "pageviews"=val(audChartRow.pageviews),"opportunities"=val(audChartRow.opportunities),
                    "slot_views"=val(audChartRow.slot_views),"ad_views"=val(audChartRow.ad_views)});
            }
            for (audChartRow in audRegions) arrayAppend(audChartData.regions,{
                "audience_uf"=audChartRow.audience_uf,"active_pages"=val(audChartRow.active_pages),
                "visitors"=val(audChartRow.visitors),"opportunities"=val(audChartRow.opportunities),
                "slot_views"=val(audChartRow.slot_views),"ad_views"=val(audChartRow.ad_views)});
            audChartJson = replace(replace(replace(serializeJSON(audChartData),"<","\u003c","all"),">","\u003e","all"),"&","\u0026","all");
        </cfscript>
        <script type="application/json" id="audience-chart-data"><cfoutput>#audChartJson#</cfoutput></script>
        <cfif NOT val(audStats.active_pages)>
            <div class="alert alert-info" role="status">Nenhum acesso confirmado para estes filtros. A coleta pode estar recém-ativada ou ainda sem tráfego; não há histórico de visibilidade anterior à instrumentação.</div>
        </cfif>
        <div class="row g-3 mb-3"><cfoutput>
            <div class="col-6 col-lg-2"><div class="audience-kpi audience-kpi-primary"><div class="audience-meta">Posições visíveis</div><div class="audience-value text-warning">#audienceCount(audStats.slot_views)#</div><div class="audience-meta">50% por 1 segundo contínuo</div></div></div>
            <div class="col-6 col-lg-2"><div class="audience-kpi"><div class="audience-meta">Visitantes estimados</div><div class="audience-value">#audienceCount(audStats.visitors)#</div></div></div>
            <div class="col-6 col-lg-2"><div class="audience-kpi"><div class="audience-meta">Páginas com atividade</div><div class="audience-value">#audienceCount(audStats.active_pages)#</div><div class="audience-meta">#audienceCount(audStats.pageviews)# aberturas neste contexto</div></div></div>
            <div class="col-6 col-lg-2"><div class="audience-kpi"><div class="audience-meta">Sessões</div><div class="audience-value">#audienceCount(audStats.sessions)#</div><div class="audience-meta">#audienceCount(audStats.engaged_sessions)# com uso qualificado</div></div></div>
            <div class="col-6 col-lg-2"><div class="audience-kpi"><div class="audience-meta">Posições registradas</div><div class="audience-value">#audienceCount(audStats.opportunities)#</div><div class="audience-meta">inclui vazias / indisponíveis</div></div></div>
            <div class="col-6 col-lg-2"><div class="audience-kpi"><div class="audience-meta">Anúncios visíveis</div><div class="audience-value">#audienceCount(audStats.ad_views)#</div><div class="audience-meta">#audienceCount(audStats.ad_renders)# renderizados</div></div></div>
        </cfoutput></div>
        <div class="audience-health"><cfoutput><span class="audience-pill">#encodeForHtml(VARIABLES.audienceEnvironment)# · #VARIABLES.audienceDays# dias<cfif len(VARIABLES.audienceUf)> · #encodeForHtml(VARIABLES.audienceUf)#</cfif></span><span class="audience-meta">Última recepção: #audienceDate(audStats.last_received)# · Brasília · cache de até 1 minuto</span></cfoutput></div>
        <nav class="audience-nav" aria-label="Seções do relatório"><a class="btn btn-outline-secondary btn-sm" href="#inventario">Posições</a><a class="btn btn-outline-secondary btn-sm" href="#regioes">Regiões</a><a class="btn btn-outline-secondary btn-sm" href="#conteudo">Conteúdo</a><a class="btn btn-outline-secondary btn-sm" href="#aquisicao">Aquisição</a><cfif structKeyExists(VARIABLES,"audienceLiveUnavailable")><a class="btn btn-outline-secondary btn-sm" href="#jornada-live">Jornada LIVE!</a></cfif><a class="btn btn-outline-secondary btn-sm" href="#cobertura">Cobertura</a></nav>

        <div class="audience-chart-grid">
            <section class="audience-panel" aria-labelledby="audience-daily-title"><h2 id="audience-daily-title" class="audience-section-title">Acessos e posições visíveis por dia</h2><p class="audience-meta">Contagens nos dias observados · horário de Brasília. Dias sem medição não são preenchidos com zeros.</p>
                <div class="audience-chart-frame" data-audience-chart hidden><canvas id="audience-daily-chart" role="img" aria-label="Evolução diária de aberturas de página e posições visíveis; valores na tabela abaixo"></canvas></div>
                <details <cfif audDaily.recordcount LT 2>open</cfif>><summary>Ver valores por dia</summary><div class="table-responsive audience-table-scroll"><table class="table table-sm"><thead><tr><th scope="col">Dia</th><th scope="col">Aberturas</th><th scope="col">Posições</th><th scope="col">Visíveis</th></tr></thead><tbody>
                    <cfoutput query="audDaily"><tr><td>#dateFormat(day,"dd/mm")#</td><td>#audienceCount(pageviews)#</td><td>#audienceCount(opportunities)#</td><td>#audienceCount(slot_views)#</td></tr></cfoutput><cfif NOT audDaily.recordcount><tr><td colspan="4">Aguardando os primeiros eventos.</td></tr></cfif>
                </tbody></table></div></details>
            </section>
            <section class="audience-panel" aria-labelledby="audience-region-title"><h2 id="audience-region-title" class="audience-section-title">Posições visíveis por UF</h2><p class="audience-meta">Até 6 UFs com mais exposições · dimensão regional selecionada no filtro.</p>
                <div class="audience-chart-frame" data-audience-chart hidden><canvas id="audience-region-chart" role="img" aria-label="Posições visíveis por UF; valores completos em Regiões"></canvas></div>
                <cfif NOT val(audStats.slot_views)><p class="audience-meta py-4">Ainda sem exposições visíveis confirmadas neste recorte.</p></cfif>
                <a href="#regioes" class="audience-meta">Consultar todas as UFs e os valores →</a>
            </section>
        </div>

        <details class="audience-panel"><summary>Como interpretar o potencial comercial</summary><div class="audience-definition-grid audience-meta">
            <p><strong>Registrada → montada → visível</strong><br>Registrar uma posição ou pedir um anúncio não prova exposição. “Visível” exige 50% da área por 1 segundo contínuo, aba ativa e imagem carregada.</p>
            <p><strong>Espaço não é anúncio</strong><br>Uma posição vazia pode ser montada e vista. Isso ajuda a medir inventário, mas não cobra créditos e não garante a entrega de uma campanha.</p>
            <p><strong>UF comercial não é origem</strong><br>A busca por SC conta para SC. Uma mesma página pode ter atividade em mais de uma UF; visitantes, sessões e páginas regionais não devem ser somados.</p>
        </div></details>

        <section class="audience-panel" id="inventario"><h2 class="h5">Inventário por posição e página</h2><p class="audience-meta">Uma posição vazia ou colapsada pode ser registrada sem renderização nem exposição. “A confirmar” indica carregamento assíncrono sem estado final recebido, não espaço comprovadamente vazio. Entrega do servidor não comprova que o anúncio apareceu na tela.</p>
            <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Inventário detalhado, role horizontalmente para todas as métricas"><table class="table table-sm mb-0"><thead><tr><th>Posição</th><th>Página</th><th>Dispositivo</th><th>Registradas</th><th>Pagas / institucionais</th><th>Pedidos</th><th>Entregas</th><th>Montadas</th><th>Visíveis</th><th>Anúncios renderizados / visíveis</th><th>Vazias / a confirmar</th><th>Indisponíveis</th><th>Erros</th></tr></thead><tbody>
            <cfset audInventory = VARIABLES.audienceQueries.inventory/>
            <cfoutput query="audInventory" maxrows="200"><tr><td class="audience-text">#encodeForHtml(slot_key)#<div class="audience-meta">#encodeForHtml(placement_key)#</div></td><td>#encodeForHtml(audienceLabel(page_family))#</td><td>#encodeForHtml(audienceLabel(device_class))#</td><td>#audienceCount(opportunities)#</td><td>#audienceCount(filled_slots)# / #audienceCount(house_slots)#</td><td>#audienceCount(requests)#</td><td>#audienceCount(served)#</td><td>#audienceCount(renders)#</td><td class="text-warning">#audienceCount(slot_views)#</td><td>#audienceCount(ad_renders)# / #audienceCount(ad_views)#</td><td>#audienceCount(empty_slots)# / #audienceCount(pending_slots)#</td><td>#audienceCount(unavailable_slots)#</td><td>#audienceCount(errors)#</td></tr></cfoutput>
            <cfif NOT audInventory.recordcount><tr><td colspan="13" class="text-muted">Ainda sem posições registradas neste recorte.</td></tr></cfif>
            </tbody></table></div><cfif audInventory.recordcount GT 200><p class="audience-meta mt-2 mb-0">Exibindo as 200 combinações com mais registros. Os indicadores superiores usam o período inteiro.</p></cfif>
        </section>

        <section class="audience-panel" id="regioes"><h2 class="h5">Regiões do público</h2><p class="audience-meta">Páginas e visitantes com atividade no recorte, inclusive posições carregadas depois da abertura inicial. O total geral é deduplicado.</p><div class="table-responsive"><table class="table table-sm"><thead><tr><th>UF</th><th>Páginas com atividade</th><th>Visitantes</th><th>Posições</th><th>Visíveis</th></tr></thead><tbody>
            <cfset audRegions = VARIABLES.audienceQueries.regions/><cfoutput query="audRegions"><tr><td><cfif audience_uf EQ "--">Desconhecida<cfelse>#encodeForHtml(audience_uf)#</cfif></td><td>#audienceCount(active_pages)#</td><td>#audienceCount(visitors)#</td><td>#audienceCount(opportunities)#</td><td>#audienceCount(slot_views)#</td></tr></cfoutput>
            <cfif NOT audRegions.recordcount><tr><td colspan="5" class="text-muted">Sem dados para o período.</td></tr></cfif></tbody></table></div></section>

        <section class="audience-panel" id="conteudo">
            <h2 class="h5">Conteúdo individual</h2>
            <p class="audience-meta">Cartão exposto exige ao menos 50% visível por 1 segundo contínuo e conta páginas distintas por conteúdo; alcance exposto conta navegadores distintos. Profundidade é o trecho da notícia alcançado na tela, não leitura comprovada. Quando a instrumentação for ativada, esses sinais editoriais começarão naquele momento, sem histórico retroativo; “—” indica ausência do novo sinal ou métrica não aplicável.</p>
            <p class="audience-meta">Abrir um vídeo não significa reproduzi-lo. A reprodução só aparece quando há evento confirmado do player. Identificadores referem-se ao conteúdo visitado, não ao anunciante.</p>
            <div class="table-responsive audience-table-scroll" tabindex="0" role="region" aria-label="Conteúdo detalhado, role horizontalmente para todas as métricas"><table class="table table-sm mb-0"><thead><tr><th>Conteúdo</th><th>Tipo</th><th>Cartões expostos</th><th>Alcance exposto</th><th>Páginas</th><th>Aberturas</th><th>Visitantes da abertura</th><th>Inícios de vídeo</th><th>Conclusões</th><th>Profundidade da notícia</th><th>Uso ativo</th></tr></thead><tbody>
            <cfset audContent = VARIABLES.audienceQueries.content/>
            <cfoutput query="audContent" maxrows="100"><tr>
                <td class="audience-text">#encodeForHtml(content_id)#<div class="audience-meta"><cfif len(trim(page_path))>#encodeForHtml(page_path)#<cfelse>—</cfif></div></td>
                <td>#encodeForHtml(content_type)#</td>
                <td><cfif val(card_views)>#audienceCount(card_views)#<cfelse><span class="text-muted" title="Sinal editorial ainda ausente">—</span></cfif></td>
                <td><cfif val(card_views)>#audienceCount(exposed_visitors)#<cfelse><span class="text-muted" title="Sinal editorial ainda ausente">—</span></cfif></td>
                <td>#audienceCount(pageviews)#</td><td>#audienceCount(opens)#</td><td>#audienceCount(visitors)#</td>
                <td>#audienceCount(video_starts)#</td><td>#audienceCount(video_completions)#</td>
                <td><cfif content_type NEQ "news"><span class="text-muted" title="Não se aplica a vídeo, evento ou perfil">—</span><cfelseif val(depth_25)><div class="d-flex flex-wrap gap-2 audience-meta" aria-label="Páginas distintas que alcançaram cada trecho"><span class="text-nowrap"><strong>25%</strong> #audienceCount(depth_25)#</span><span class="text-nowrap"><strong>50%</strong> #audienceCount(depth_50)#</span><span class="text-nowrap"><strong>75%</strong> #audienceCount(depth_75)#</span><span class="text-nowrap"><strong>100%</strong> #audienceCount(depth_100)#</span></div><cfelse><span class="text-muted" title="Profundidade indisponível: ainda sem sinal editorial de progresso">—</span></cfif></td>
                <td>#audienceCount(int(val(active_ms)/60000))# min</td>
            </tr></cfoutput><cfif NOT audContent.recordcount><tr><td colspan="11" class="text-muted">Ainda sem consumo de conteúdo identificado neste recorte.</td></tr></cfif></tbody></table></div>
            <cfif audContent.recordcount GT 100><p class="audience-meta mt-2 mb-0">Exibindo os 100 conteúdos com mais páginas, aberturas ou exposições qualificadas, incluindo itens apenas expostos.</p></cfif>
        </section>

        <section class="audience-panel" id="aquisicao"><h2 class="h5">Aquisição e testes de mensagem</h2><p class="audience-meta">Compare “Ache sua corrida” e “Monte seu histórico” por campanha e variante UTM. Sessão qualificada: 30 segundos ativos ou duas páginas distintas neste recorte. Sem gasto importado, não há custo de aquisição calculado.</p><div class="table-responsive"><table class="table table-sm"><thead><tr><th>Origem / meio</th><th>Campanha</th><th>Criativo / variante</th><th>Páginas com atividade</th><th>Visitantes</th><th>Sessões</th><th>Qualificadas</th><th>Uso ativo</th></tr></thead><tbody>
            <cfset audAcquisition = VARIABLES.audienceQueries.acquisition/><cfoutput query="audAcquisition" maxrows="100"><tr><td>#encodeForHtml(source)#<div class="audience-meta">#encodeForHtml(medium)#</div></td><td class="audience-text">#encodeForHtml(campaign)#</td><td class="audience-text">#encodeForHtml(creative)#</td><td>#audienceCount(active_pages)#</td><td>#audienceCount(visitors)#</td><td>#audienceCount(sessions)#</td><td>#audienceCount(engaged_sessions)#<div class="audience-meta">#audienceRate(engaged_sessions,sessions)#</div></td><td>#audienceCount(int(val(active_ms)/60000))# min</td></tr></cfoutput><cfif NOT audAcquisition.recordcount><tr><td colspan="8" class="text-muted">Ainda sem sessões identificadas neste recorte.</td></tr></cfif></tbody></table></div><cfif audAcquisition.recordcount GT 100><p class="audience-meta">Exibindo as 100 combinações com mais páginas.</p></cfif></section>

        <cfif structKeyExists(VARIABLES,"audienceLiveUnavailable")><cfinclude template="live_journey.cfm"/></cfif>

        <section class="audience-panel" id="cobertura"><h2 class="h5">Cobertura observada</h2><p class="audience-meta">Mostra somente as famílias que enviaram eventos. A ausência de uma família pode indicar falta de acesso ou instrumentação; não comprova audiência zero. Totais sem amostragem de linhas.</p><div class="table-responsive"><table class="table table-sm"><thead><tr><th>Página</th><th>Páginas vistas</th><th>Páginas com posições</th><th>Posições</th><th>Visíveis</th><th>Última recepção</th></tr></thead><tbody>
            <cfset audCoverage = VARIABLES.audienceQueries.coverage/><cfoutput query="audCoverage"><tr><td>#encodeForHtml(audienceLabel(page_family))#</td><td>#audienceCount(pageviews)#</td><td>#audienceCount(pages_with_slots)#</td><td>#audienceCount(opportunities)#</td><td>#audienceCount(slot_views)#</td><td>#audienceDate(last_received)#</td></tr></cfoutput><cfif NOT audCoverage.recordcount><tr><td colspan="6" class="text-muted">Sem cobertura observada no recorte.</td></tr></cfif></tbody></table></div>
            <p class="audience-meta mb-0">Visitantes são estimados por navegador. Sessões com uso qualificado atingem 30 segundos ativos ou duas páginas distintas no recorte. Bloqueios, opt-out e falhas de coleta limitam a cobertura. Cliques faturáveis e consumo de créditos permanecem no painel de campanhas.</p>
            <p class="audience-meta mt-2 mb-0"><cfoutput>Primeiro evento no recorte: #audienceDate(audStats.first_event)# · #audienceCount(audStats.unknown_location)# aberturas sem UF de acesso; #audienceCount(audStats.unknown_market)# sem UF comercial. Política para eventos detalhados: 90 dias; o cumprimento depende da rotina e do estado operacional abaixo. Não há reconstrução de exposições anteriores à ativação.</cfoutput></p>
            <div class="audience-note audience-meta mt-3" role="status">
                <strong>Política de retenção: 90 dias · operação da base inteira</strong><br>
                <cfswitch expression="#VARIABLES.audienceRetention.state#">
                    <cfcase value="not_installed">Retenção ainda não instalada. É necessário instalar e agendar a rotina antes da coleta pública.</cfcase>
                    <cfcase value="never">Rotina instalada, ainda sem execução confirmada.</cfcase>
                    <cfcase value="ok">Em dia: última execução concluída. A agenda horária prevê tolerância de até 1 hora, sem fila.</cfcase>
                    <cfcase value="stale">Atenção: última execução bem-sucedida há mais de 2 horas. Verifique a agenda.</cfcase>
                    <cfcase value="backlog">Atenção: ainda há eventos vencidos aguardando os próximos lotes de exclusão.</cfcase>
                    <cfcase value="error">A rotina informou erro. A retenção exige intervenção operacional.</cfcase>
                    <cfdefaultcase>Não foi possível verificar a retenção agora; isso não indica execução bem-sucedida.</cfdefaultcase>
                </cfswitch>
                <cfif isDate(VARIABLES.audienceRetention.lastSuccess)><cfoutput> Último sucesso: #audienceDate(VARIABLES.audienceRetention.lastSuccess)# · Brasília.</cfoutput></cfif>
            </div>
        </section>
    </cfif>
</div>
