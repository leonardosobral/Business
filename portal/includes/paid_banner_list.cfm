<cfif NOT arrayLen(VARIABLES.paidBannerRows)><p class="text-muted py-3">Nenhum banner cadastrado. Crie uma campanha para divulgar sua marca ou parceiro.</p></cfif>
<cfoutput><cfloop array="#VARIABLES.paidBannerRows#" index="paidBannerRowItem">
    <cfset paidBannerScope=bannerScopeFromMetadata(paidBannerRowItem.metadata)/>
    <details class="banner-operation">
        <summary class="paid-banner-summary">
            <span class="banner-row-name">#htmlEditFormat(paidBannerRowItem.name)#<small class="d-block text-muted fw-normal">#htmlEditFormat(paidBannerRowItem.account_name)#</small></span>
            <span><span class="badge <cfif paidBannerRowItem.status EQ 'ACTIVE'>badge-success<cfelseif paidBannerRowItem.review_status EQ 'PENDING_REVIEW'>badge-info<cfelse>badge-secondary</cfif>">#htmlEditFormat(paidBannerStatus(paidBannerRowItem.status,paidBannerRowItem.review_status))#</span></span>
            <span><small class="d-block text-muted">Investimento</small>R$ #LSNumberFormat(paidBannerRowItem.spent_total,'9,999.00')#<small class="d-block">de R$ #LSNumberFormat(paidBannerRowItem.budget_total,'9,999.00')#</small></span>
            <span><strong>#LSNumberFormat(paidBannerRowItem.impressions,'9,999')#</strong> impressões<small class="d-block">#LSNumberFormat(paidBannerRowItem.clicks,'9,999')# cliques</small></span>
            <span><small class="d-block text-muted">CTR / CPC médio</small><cfif paidBannerRowItem.impressions GT 0>#LSNumberFormat(paidBannerRowItem.clicks*100/paidBannerRowItem.impressions,'9.99')#%<cfelse>—</cfif><small class="d-block"><cfif paidBannerRowItem.billable_clicks GT 0>R$ #LSNumberFormat(paidBannerRowItem.cost/paidBannerRowItem.billable_clicks,'9.99')#<cfelse>—</cfif></small></span>
            <span class="banner-row-toggle"><span class="banner-show-label">Ver detalhes</span><span class="banner-hide-label">Recolher</span> <i class="fas fa-chevron-down" aria-hidden="true"></i></span>
        </summary>
        <div class="banner-row-details">
            <div class="banner-detail-grid">
                <div class="portal-banner-thumb-set"><cfloop list="desktop,mobile" index="paidBannerKind"><div><span class="portal-banner-thumb-label">#paidBannerKind#</span><div class="portal-banner-thumb"><img loading="lazy" src="#htmlEditFormat(paidBannerRowItem['image_url_' & paidBannerKind])#" alt="#htmlEditFormat(paidBannerRowItem.alt_text)#"/></div></div></cfloop></div>
                <dl class="banner-facts">
                    <div><dt>Estados</dt><dd>#paidBannerScope.regions_mode EQ 'ALL' ? 'Todo o Brasil' : htmlEditFormat(arrayToList(paidBannerScope.regions,', '))#</dd></div>
                    <div><dt>Páginas</dt><dd>#paidBannerScope.pages_mode EQ 'ALL' ? 'Todas as páginas compatíveis' : htmlEditFormat(bannerDashboardScopeLabel(paidBannerScope,'pages'))#</dd></div>
                    <div><dt>Período</dt><dd>#dateTimeFormat(paidBannerRowItem.starts_at,'dd/mm/yyyy HH:nn')# a #dateTimeFormat(paidBannerRowItem.ends_at,'dd/mm/yyyy HH:nn')# (Brasília)</dd></div>
                    <div><dt>Dispositivo</dt><dd>#paidBannerRowItem.target_device EQ 'ALL' ? 'Todos' : (paidBannerRowItem.target_device EQ 'MOBILE' ? 'Celular' : 'Desktop')#</dd></div>
                    <div><dt>Lance máximo</dt><dd>R$ #LSNumberFormat(paidBannerRowItem.cpc_bid,'9.99')# por clique</dd></div>
                    <div><dt>Limite diário</dt><dd><cfif isNumeric(paidBannerRowItem.budget_daily)>R$ #LSNumberFormat(paidBannerRowItem.budget_daily,'9,999.00')#<cfelse>Sem limite adicional</cfif></dd></div>
                    <div class="banner-fact-wide"><dt>Destino · #paidBannerRowItem.open_new_tab EQ '1' ? 'Nova aba' : 'Mesma aba'#</dt><dd>#htmlEditFormat(paidBannerRowItem.destination_url)#</dd></div>
                    <div class="banner-fact-wide"><dt>Descrição da imagem</dt><dd>#htmlEditFormat(paidBannerRowItem.alt_text)#</dd></div>
                </dl>
            </div>
            <cfif len(paidBannerRowItem.review_reason)><p class="alert alert-info">Revisão: #htmlEditFormat(paidBannerRowItem.review_reason)#</p></cfif>
            <div class="banner-actions">
                <a class="btn btn-sm btn-outline-info" href="/portal/banners/?banner=#encodeForURL(paidBannerRowItem.campaign_id)#&amp;periodo=30##paid-banner-performance">Ver desempenho</a>
                <cfif VARIABLES.paidBannerContext.canManage AND paidBannerRowItem.account_id EQ VARIABLES.paidBannerContext.accountId AND listFind('DRAFT,ACTIVE,PAUSED',paidBannerRowItem.status)>
                    <cfif paidBannerRowItem.status EQ 'DRAFT' AND NOT listFind('PENDING_REVIEW,WAITING_PREREQUISITES,APPROVED',paidBannerRowItem.review_status)>
                        <a class="btn btn-sm btn-outline-light" href="/portal/banners/?edit=#encodeForURL(paidBannerRowItem.campaign_id)#&##paid-banner-form">Editar</a>
                    </cfif>
                    <form method="post" action="/portal/banners/" class="d-flex flex-wrap gap-2">
                        <input type="hidden" name="paid_banner_csrf" value="#htmlEditFormat(VARIABLES.paidBannerCsrf)#"/><input type="hidden" name="campaign_id" value="#htmlEditFormat(paidBannerRowItem.campaign_id)#"/>
                        <cfif paidBannerRowItem.status NEQ 'DRAFT' OR listFind('PENDING_REVIEW,WAITING_PREREQUISITES,APPROVED',paidBannerRowItem.review_status)><button class="btn btn-sm btn-outline-light" type="submit" name="paid_banner_action" value="prepare">#paidBannerRowItem.status EQ 'ACTIVE' ? 'Pausar e editar' : 'Retirar da análise e editar'#</button>
                        <cfelse><button class="btn btn-sm btn-info" name="paid_banner_action" value="submit">Enviar para análise</button></cfif>
                        <cfif paidBannerRowItem.status EQ 'ACTIVE'><button class="btn btn-sm btn-outline-warning" name="paid_banner_action" value="pause">Pausar</button></cfif>
                        <cfif paidBannerRowItem.status EQ 'PAUSED' AND paidBannerRowItem.review_status EQ 'APPROVED'><button class="btn btn-sm btn-outline-success" name="paid_banner_action" value="resume">Retomar</button></cfif>
                        <button class="btn btn-sm btn-outline-danger" name="paid_banner_action" value="end" onclick="return confirm('Encerrar este banner?');">Encerrar</button>
                    </form>
                </cfif>
            </div>
            <cfif VARIABLES.paidBannerContext.canReview AND paidBannerRowItem.review_status EQ 'PENDING_REVIEW'>
                <form method="post" action="/portal/banners/" class="mt-3 border rounded p-3">
                    <h3 class="h6">Revisão RunnerHub</h3><p class="small">Confira as duas imagens, o destino e o escopo. Aprovar libera a veiculação conforme o período, saldo e orçamento.</p>
                    <input type="hidden" name="paid_banner_action" value="review"/><input type="hidden" name="paid_banner_csrf" value="#htmlEditFormat(VARIABLES.paidBannerCsrf)#"/><input type="hidden" name="campaign_id" value="#htmlEditFormat(paidBannerRowItem.campaign_id)#"/><input type="hidden" name="review_id" value="#val(paidBannerRowItem.review_id)#"/>
                    <label class="form-label" for="review-reason-#paidBannerRowItem.campaign_id#">Comentário (obrigatório para solicitar ajustes)</label><textarea class="form-control mb-2" name="reason" maxlength="1000" id="review-reason-#paidBannerRowItem.campaign_id#"></textarea>
                    <button class="btn btn-sm btn-success" name="decision" value="APPROVE">Aprovar banner</button> <button class="btn btn-sm btn-outline-warning" name="decision" value="REQUEST_CHANGES">Solicitar ajustes</button>
                </form>
            </cfif>
            <p class="small text-muted mt-3 mb-0">#val(paidBannerRowItem.deliveries)# entregas · #val(paidBannerRowItem.billable_clicks)# cliques cobrados · CPC · ID #htmlEditFormat(paidBannerRowItem.campaign_id)#. Entregas não são impressões.</p>
        </div>
    </details>
</cfloop></cfoutput>
