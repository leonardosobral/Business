<cfif NOT qBannerManagementList.recordcount>
    <div class="text-center text-muted py-4">Nenhum banner encontrado com os filtros atuais.</div>
<cfelse>
    <div class="banner-grid banner-list-header" aria-hidden="true"><span>Banner</span><span>Status</span><span>UFs</span><span>Impressões</span><span>Cliques</span><span>CTR</span><span>Detalhes</span></div>
    <cfoutput query="qBannerManagementList">
        <cfset VARIABLES.bannerRowRegions = 'Escopo inválido'/>
        <cfset VARIABLES.bannerRowPages = 'Revise o escopo do banner.'/>
        <cftry>
            <cfset VARIABLES.bannerRowScope = bannerScopeFromMetadata(qBannerManagementList.banner_metadata)/>
            <cfset VARIABLES.bannerRowRegions = bannerDashboardScopeLabel(VARIABLES.bannerRowScope,'regions')/>
            <cfset VARIABLES.bannerRowPages = bannerDashboardScopeLabel(VARIABLES.bannerRowScope,'pages')/>
            <cfcatch type="any"></cfcatch>
        </cftry>
        <details class="banner-operation">
            <summary class="banner-grid">
                <span class="banner-row-name">#htmlEditFormat(qBannerManagementList.nome)#</span>
                <span><span class="banner-row-label">Status</span><span class="badge <cfif qBannerManagementList.status EQ 'ACTIVE'>badge-success<cfelseif qBannerManagementList.status EQ 'PAUSED'>badge-warning<cfelse>badge-secondary</cfif>">#bannerManagementStatusLabel(qBannerManagementList.status)#</span></span>
                <span><span class="banner-row-label">UFs</span><span class="small">#htmlEditFormat(VARIABLES.bannerRowRegions)#</span></span>
                <span><span class="banner-row-label">Impressões</span>#LSNumberFormat(qBannerManagementList.views,'9,999,999')#</span>
                <span><span class="banner-row-label">Cliques</span>#LSNumberFormat(qBannerManagementList.clicks,'9,999,999')#</span>
                <span><span class="banner-row-label">CTR</span><cfif qBannerManagementList.views GT 0>#LSNumberFormat(qBannerManagementList.clicks * 100 / qBannerManagementList.views,'9.99')#%<cfelse><span title="CTR indisponível sem impressões">—</span></cfif></span>
                <span class="banner-row-toggle"><span class="banner-show-label">Ver detalhes</span><span class="banner-hide-label">Recolher</span><i class="fas fa-chevron-down" aria-hidden="true"></i><span class="visually-hidden"> de #htmlEditFormat(qBannerManagementList.nome)#</span></span>
            </summary>
            <div class="banner-row-details">
                <div class="banner-detail-grid">
                    <div class="portal-banner-thumb-set">
                        <div><span class="portal-banner-thumb-label">Desktop</span><div class="portal-banner-thumb"><img loading="lazy" src="#htmlEditFormat(bannerManagementBuildAssetUrl(qBannerManagementList.arquivo_path))#" alt="#htmlEditFormat(qBannerManagementList.nome)# — desktop"/></div></div>
                        <div><span class="portal-banner-thumb-label">Mobile</span><div class="portal-banner-thumb"><img loading="lazy" src="#htmlEditFormat(bannerManagementBuildAssetUrl(qBannerManagementList.arquivo_mobile_path))#" alt="#htmlEditFormat(qBannerManagementList.nome)# — mobile"/></div></div>
                    </div>
                    <dl class="banner-facts">
                        <div><dt>Páginas</dt><dd>#htmlEditFormat(VARIABLES.bannerRowPages)#</dd></div>
                        <div><dt>Estados</dt><dd>#htmlEditFormat(VARIABLES.bannerRowRegions)#</dd></div>
                        <div><dt>Início</dt><dd><cfif isDate(qBannerManagementList.inicio_exibicao)>#LSDateFormat(qBannerManagementList.inicio_exibicao,'dd/mm/yyyy')# às #LSTimeFormat(qBannerManagementList.inicio_exibicao,'HH:nn')#<cfelse>Não definido</cfif></dd></div>
                        <div><dt>Término</dt><dd><cfif isDate(qBannerManagementList.fim_exibicao)>#LSDateFormat(qBannerManagementList.fim_exibicao,'dd/mm/yyyy')# às #LSTimeFormat(qBannerManagementList.fim_exibicao,'HH:nn')#<cfelse>Sem término definido</cfif></dd></div>
                        <div class="banner-fact-wide"><dt>Destino · #bannerManagementTargetLabel(qBannerManagementList.abrir_nova_aba)#</dt><dd>#htmlEditFormat(qBannerManagementList.link_destino)#</dd></div>
                        <div class="banner-fact-wide"><dt>Descrição da imagem</dt><dd>#htmlEditFormat(qBannerManagementList.alt_text)#</dd></div>
                    </dl>
                </div>
                <div class="banner-actions">
                    <a class="btn btn-sm btn-outline-info" href="./?view=house&amp;banner=#encodeForURL(qBannerManagementList.id_banner)#&amp;periodo=30##banner-performance">Ver desempenho</a>
                    <cfif listFind('DRAFT,PAUSED',qBannerManagementList.status)>
                        <a class="btn btn-sm btn-outline-light" href="./?view=house&amp;banner_editar=#encodeForURL(qBannerManagementList.id_banner)#">Editar</a>
                        <form method="post" action="./?view=house">
                            <input type="hidden" name="acao" value="alterar_status"/>
                            <input type="hidden" name="banner_csrf" value="#htmlEditFormat(VARIABLES.bannerManagementCsrf)#"/>
                            <input type="hidden" name="banner_id" value="#htmlEditFormat(qBannerManagementList.id_banner)#"/>
                            <input type="hidden" name="target_status" value="ACTIVE"/>
                            <input type="hidden" name="reason" value="Ativacao manual do banner HOUSE pelo Business"/>
                            <button class="btn btn-sm btn-outline-success" type="submit">Ativar</button>
                        </form>
                    </cfif>
                    <cfif qBannerManagementList.status EQ 'ACTIVE'>
                        <form method="post" action="./?view=house">
                            <input type="hidden" name="acao" value="alterar_status"/>
                            <input type="hidden" name="banner_csrf" value="#htmlEditFormat(VARIABLES.bannerManagementCsrf)#"/>
                            <input type="hidden" name="banner_id" value="#htmlEditFormat(qBannerManagementList.id_banner)#"/>
                            <input type="hidden" name="target_status" value="PAUSED"/>
                            <input type="hidden" name="reason" value="Pausa manual do banner HOUSE pelo Business"/>
                            <button class="btn btn-sm btn-outline-warning" type="submit">Pausar</button>
                        </form>
                        <span class="small text-muted">Pause o banner para editar.</span>
                    </cfif>
                    <cfif listFind('DRAFT,ACTIVE,PAUSED',qBannerManagementList.status)>
                        <form method="post" action="./?view=house" onsubmit="return confirm('Tem certeza que deseja encerrar este banner?');">
                            <input type="hidden" name="acao" value="alterar_status"/>
                            <input type="hidden" name="banner_csrf" value="#htmlEditFormat(VARIABLES.bannerManagementCsrf)#"/>
                            <input type="hidden" name="banner_id" value="#htmlEditFormat(qBannerManagementList.id_banner)#"/>
                            <input type="hidden" name="target_status" value="ENDED"/>
                            <input type="hidden" name="reason" value="Encerramento manual do banner HOUSE pelo Business"/>
                            <button class="btn btn-sm btn-outline-danger" type="submit">Encerrar</button>
                        </form>
                    </cfif>
                </div>
                <details class="banner-technical"><summary>Informações técnicas</summary><div class="mt-2">ID #htmlEditFormat(qBannerManagementList.id_banner)# · HOUSE, sem cobrança<br/>Slot: #htmlEditFormat(qBannerManagementList.local_layout)#<br/>Desktop: #val(qBannerManagementList.largura)# × #val(qBannerManagementList.altura)# px · Mobile: #val(qBannerManagementList.largura_mobile)# × #val(qBannerManagementList.altura_mobile)# px<br/>Peso #val(qBannerManagementList.peso_exibicao)# · Prioridade #val(qBannerManagementList.prioridade)#</div></details>
            </div>
        </details>
    </cfoutput>
</cfif>
