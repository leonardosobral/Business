<cfprocessingdirective pageencoding="utf-8"/>
<cfif NOT isDefined("verifiedData")><cfheader statuscode="403"/><cfabort/></cfif>
<cfset verifiedSelectionCategories=verifiedService.selectionCategories()/>
<cfoutput>
<link rel="stylesheet" href="/assets/css/business-ui.css"/>
<link rel="stylesheet" href="/portal/verificados/verified.css?v=20261124"/>
<script src="/portal/verificados/verified.js?v=20261124" defer></script>
<section class="business-page verified-page" aria-labelledby="verified-title">
    <header class="verified-heading">
        <div><p class="verified-eyebrow">PORTAL · ROAD RUNNERS</p><h1 id="verified-title">Selos verificados</h1><p class="text-muted">Veja por que cada pessoa tem o selo, até quando ele vale e o histórico de cada origem.</p></div>
        <span class="verified-readonly">Classificar um motivo não altera o selo</span>
    </header>
    <cfif len(verifiedError)><div class="alert alert-danger" role="alert">#encodeForHTML(verifiedError)#</div></cfif>
    <cfif verifiedQuickCount GT 0 AND NOT len(verifiedError)><div class="alert alert-success" role="status">#verifiedQuickCount# <cfif verifiedQuickCount EQ 1>pessoa classificada<cfelse>pessoas classificadas</cfif>. Quem já tem motivo registrado saiu da fila “A classificar”.</div></cfif>
    <cfif verifiedSaved><div class="alert alert-success" role="status">Motivo registrado. A validade e os benefícios do selo foram preservados.</div></cfif>
    <div class="business-kpi-grid verified-kpis" aria-label="Resumo geral dos selos">
        <a class="business-kpi" href="#encodeForHTMLAttribute(verifiedUrl({filter_status='active',filter_origin='',pagina=1,user_busca=''}))#"><small>Selos ativos</small><strong>#verifiedData.totals.active#</strong></a>
        <a class="business-kpi" href="#encodeForHTMLAttribute(verifiedUrl({filter_status='active',filter_origin='manual',pagina=1,user_busca=''}))#"><small>Sem vencimento</small><strong>#verifiedData.totals.permanent#</strong></a>
        <div class="business-kpi"><small>Ativos com prazo</small><strong>#verifiedData.totals.annual#</strong></div>
        <a class="business-kpi verified-kpi-attention" href="#encodeForHTMLAttribute(verifiedUrl({filter_status='unclassified',filter_origin='',pagina=1,user_busca=''}))#"><small>Motivo a classificar</small><strong>#verifiedData.totals.unclassified#</strong></a>
    </div>
    <nav class="verified-tabs" aria-label="Situação do selo">
        <cfloop array="#[{key='active',label='Ativos'},{key='unclassified',label='A classificar'},{key='inactive',label='Inativos'},{key='all',label='Todos / histórico'}]#" index="tabItem">
            <a <cfif verifiedFilters.status EQ tabItem.key>aria-current="page"</cfif> href="#encodeForHTMLAttribute(verifiedUrl({filter_status=tabItem.key,pagina=1,page_id=''}))#">#tabItem.label#</a>
        </cfloop>
    </nav>
    <form method="get" action="/portal/verificados/" class="business-panel verified-filters">
        <input type="hidden" name="filter_status" value="#encodeForHTMLAttribute(verifiedFilters.status)#"/>
        <div class="verified-filter-main">
            <div><label for="verified-search">Buscar pessoa</label><input class="form-control" id="verified-search" name="user_busca" value="#encodeForHTMLAttribute(verifiedFilters.search)#" placeholder="Nome, e-mail, perfil ou ID" maxlength="120"/></div>
            <div><label for="verified-origin">Origem ou motivo</label><select id="verified-origin" class="form-select" name="filter_origin"><option value="">Todas as origens</option>
                <cfloop array="#[['manual','Concessão permanente'],['vip','Todo Santo Dia · VIP ativo'],['upgrade','Todo Santo Dia · Upgrade VIP ativo'],['annual','Compra anual ativa'],['refunded','Com estorno no histórico'],['elite','Atleta de elite'],['influencer','Influencer / criador'],['imprensa','Imprensa'],['parceiro','Parceiro'],['equipe','Equipe'],['cortesia','Cortesia'],['outro','Outro motivo'],['nao_informado','Motivo não informado']]#" index="optionItem"><option value="#optionItem[1]#" <cfif verifiedFilters.origin EQ optionItem[1]>selected</cfif>>#optionItem[2]#</option></cfloop>
            </select></div>
            <button class="btn btn-warning" type="submit">Filtrar</button><a class="btn btn-outline-secondary" href="/portal/verificados/">Limpar</a>
        </div>
        <details class="verified-advanced" <cfif len(verifiedFilters.desafio) OR len(verifiedFilters.produto) OR verifiedFilters.admin OR verifiedFilters.dev OR verifiedFilters.partner>open</cfif>><summary>Filtros de cadastro</summary>
            <p class="text-muted small">Participação em desafio e permissões de conta são dados de cadastro; não comprovam o motivo do selo.</p>
            <div class="verified-filter-main"><div><label for="filter-desafio">Desafio</label><input class="form-control" id="filter-desafio" name="filter_desafio" value="#encodeForHTMLAttribute(verifiedFilters.desafio)#"/></div>
                <div><label for="filter-produto">Produto no cadastro</label><select id="filter-produto" name="filter_produto" class="form-select"><option value="">Todos</option><cfloop query="qVerifiedChallengeProducts"><option value="#encodeForHTMLAttribute(qVerifiedChallengeProducts.produto)#" <cfif verifiedFilters.produto EQ qVerifiedChallengeProducts.produto>selected</cfif>>#encodeForHTML(qVerifiedChallengeProducts.desafio & ' · ' & qVerifiedChallengeProducts.nome_produto)#</option></cfloop></select></div>
                <div><label for="filter-logic">Combinação</label><select id="filter-logic" name="filter_logic" class="form-select"><option value="any" <cfif verifiedFilters.logic EQ 'any'>selected</cfif>>Qualquer regra</option><option value="all" <cfif verifiedFilters.logic EQ 'all'>selected</cfif>>Todas as regras</option></select></div>
            </div>
            <div class="verified-flags"><cfloop array="#[['admin','Administrador'],['dev','Desenvolvedor'],['partner','Parceiro no cadastro']]#" index="flagItem"><label><input type="checkbox" name="filter_#flagItem[1]#" value="true" <cfif verifiedFilters[flagItem[1]]>checked</cfif>/> #flagItem[2]#</label></cfloop></div>
        </details>
    </form>
    <cfif structKeyExists(verifiedDetail,"profile")>
        <cfset selectedProfile=verifiedDetail.profile/>
        <article class="business-panel verified-detail" id="detalhes" aria-labelledby="verified-detail-title">
            <div class="verified-detail-heading"><div><p class="verified-eyebrow">ORIGENS DO SELO · PERFIL #selectedProfile.profile_id#</p><h2 id="verified-detail-title">#encodeForHTML(selectedProfile.name)#</h2>
                <p><cfif selectedProfile.permanent><span class="verified-pill">Sem vencimento</span><cfelseif selectedProfile.active><span class="verified-pill">Ativo até #selectedProfile.valid_until#</span><cfelse><span class="verified-pill is-muted">Selo inativo</span></cfif> <a href="#encodeForHTMLAttribute(verifiedProfileUrl(selectedProfile))#" target="_blank" rel="noopener">Abrir perfil ↗</a></p></div>
                <a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(verifiedUrl())#">Fechar detalhes</a></div>
            <div class="verified-source-grid">
                <cfloop array="#verifiedDetail.sources#" index="sourceItem">
                    <section class="verified-source"><h3>#encodeForHTML(verifiedOrigins[sourceItem.kind])#</h3>
                        <p><span class="verified-pill <cfif NOT sourceItem.active>is-muted</cfif>"><cfif sourceItem.active>Origem ativa<cfelseif sourceItem.source_state EQ 'paid'>Fora do período de validade<cfelse>#encodeForHTML(verifiedStates[sourceItem.source_state] ?: sourceItem.source_state)#</cfif></span></p>
                        <cfif sourceItem.kind EQ 'manual'><p>#encodeForHTML(verifiedCategories[verifiedDetail.current.category])#</p><p class="text-muted">#encodeForHTML(len(verifiedDetail.current.reason) ? verifiedDetail.current.reason : 'A concessão existe, mas o motivo não foi registrado no histórico disponível.')#</p>
                        <cfelse><dl><dt>Pagamento</dt><dd>#encodeForHTML(len(sourceItem.paid_at) ? sourceItem.paid_at : 'Ainda não confirmado')#</dd><dt>Valor</dt><dd>R$ #replace(numberFormat(sourceItem.amount_cents/100,'0.00'),'.',',')#</dd><dt>Validade concedida</dt><dd>#encodeForHTML(len(sourceItem.ends_at) ? sourceItem.ends_at : 'Ainda não concedida')#</dd><dt>Pedido</dt><dd class="verified-order">#encodeForHTML(len(sourceItem.order_id) ? sourceItem.order_id : 'Ainda não criado')#</dd></dl><cfif sourceItem.source_state EQ 'refunded'><p class="text-muted small">Este pagamento foi estornado e não mantém o selo ativo.</p></cfif></cfif>
                    </section>
                </cfloop>
                <cfif NOT arrayLen(verifiedDetail.sources)><p class="text-muted">Não há concessão ou compra de selo registrada para este perfil.</p></cfif>
            </div>
            <cfif selectedProfile.permanent>
                <details class="verified-classification" <cfif verifiedDetail.current.category EQ 'nao_informado' OR len(verifiedError)>open</cfif>><summary>Classificar a concessão permanente</summary>
                    <p class="text-muted">Informe o motivo conhecido. VIP, upgrade e compras são identificados pelo pagamento e permanecem separados.</p>
                    <cfif verifiedData.ready>
                        <form method="post" action="#encodeForHTMLAttribute(verifiedUrl({page_id=selectedProfile.profile_id}))#">
                            <input type="hidden" name="verified_action" value="classify"/><input type="hidden" name="verified_csrf" value="#encodeForHTMLAttribute(verifiedCsrf)#"/><input type="hidden" name="profile_id" value="#selectedProfile.profile_id#"/><input type="hidden" name="revision" value="#verifiedDetail.current.revision#"/>
                            <label for="classification-category">Motivo da concessão</label><select name="category" id="classification-category" class="form-select" required><cfloop list="nao_informado,#verifiedSelectionCategories#" index="categoryKey"><option value="#categoryKey#" <cfif verifiedDetail.current.category EQ categoryKey>selected</cfif>>#encodeForHTML(verifiedCategories[categoryKey])#</option></cfloop></select>
                            <label for="classification-reason">Detalhes e referência</label><textarea id="classification-reason" name="reason" class="form-control" rows="3" minlength="5" maxlength="2000" required placeholder="Ex.: imprensa — veículo ou contato que motivou a concessão.">#encodeForHTML(verifiedDetail.current.reason)#</textarea>
                            <p class="text-muted small">A anotação fica visível somente para administradores, com autor e data.</p><button type="submit" class="btn btn-warning">Salvar motivo</button>
                        </form>
                    <cfelse><p class="verified-pending">O cadastro de motivos aguarda a preparação do banco. A consulta de origens e validades já está disponível.</p></cfif>
                </details>
            </cfif>
            <cfif arrayLen(verifiedDetail.history)><details class="verified-classification"><summary>Histórico de classificação (#arrayLen(verifiedDetail.history)#)</summary><ol class="verified-audit"><cfloop array="#verifiedDetail.history#" index="auditItem"><li><strong>#encodeForHTML(verifiedCategories[auditItem.category])#</strong><p>#encodeForHTML(auditItem.reason)#</p><small>#encodeForHTML(auditItem.actor)# · #auditItem.recorded_at#</small></li></cfloop></ol></details></cfif>
        </article>
    </cfif>
    <cfif verifiedFilters.status NEQ 'unclassified' AND verifiedData.totals.unclassified GT 0><p class="verified-cleanup-link"><a href="#encodeForHTMLAttribute(verifiedUrl({filter_status='unclassified',filter_origin='',pagina=1,user_busca=''}))#">Classificar os #verifiedData.totals.unclassified# motivos pendentes →</a></p></cfif>
    <cfif verifiedData.totals.unclassified GT 0>
        <form id="verified-bulk-form" class="business-panel verified-quick-panel" method="post" action="#encodeForHTMLAttribute(verifiedUrl({page_id=''}))#" data-quick-form>
            <input type="hidden" name="verified_action" value="quick"/><input type="hidden" name="verified_csrf" value="#encodeForHTMLAttribute(verifiedCsrf)#"/>
            <div class="verified-quick-heading"><div><h2>Classificação rápida</h2><p class="text-muted">Marque as pessoas com o mesmo motivo e salve de uma vez. Apenas os perfis marcados nesta página serão classificados.</p></div><span id="verified-selected-count" role="status" aria-live="polite">0 selecionados</span></div>
            <cfif NOT verifiedData.ready><p class="verified-pending">Falta executar o SQL dos motivos no DataGrip para habilitar o salvamento.</p></cfif>
            <fieldset <cfif NOT verifiedData.ready>disabled</cfif>>
                <div class="verified-quick-fields"><div><label for="bulk-category">Motivo em comum</label><select id="bulk-category" name="category" class="form-select" required data-quick-category><option value="">Escolha o motivo</option><cfloop list="#verifiedSelectionCategories#" index="categoryKey"><option value="#categoryKey#" <cfif verifiedQuickCategory EQ categoryKey>selected</cfif>>#encodeForHTML(verifiedCategories[categoryKey])#</option></cfloop></select></div>
                <div><label for="bulk-note">Vínculo ou observação <span data-note-optional>(opcional)</span></label><input id="bulk-note" name="note" class="form-control" maxlength="1800" value="#encodeForHTMLAttribute(verifiedQuickNote)#" placeholder="Ex.: nome do veículo, canal ou parceria" data-quick-note/></div>
                <button class="btn btn-warning" type="submit" id="verified-bulk-submit">Salvar selecionados</button></div>
            </fieldset>
        </form>
    </cfif>
    <div class="verified-list-heading" id="lista-motivos"><h2>#verifiedData.total# <cfif verifiedData.total EQ 1>perfil encontrado<cfelse>perfis encontrados</cfif></h2><span class="text-muted small">Uma pessoa pode ter mais de uma origem ativa.</span></div>
    <div class="business-panel verified-table-wrap"><table class="table verified-table"><thead><tr><th class="verified-select-cell"><input type="checkbox" id="verified-select-all" aria-label="Selecionar todos os pendentes desta página" <cfif NOT verifiedData.ready>disabled</cfif>/></th><th>Pessoa</th><th>Origem e motivo do selo</th><th>Situação e validade</th><th><span class="visually-hidden">Detalhes</span></th></tr></thead><tbody>
        <cfloop array="#verifiedData.rows#" index="profileItem"><tr id="perfil-#profileItem.profile_id#">
            <td class="verified-select-cell"><cfif profileItem.permanent AND profileItem.category EQ 'nao_informado'><label><input type="checkbox" form="verified-bulk-form" name="selection" value="#profileItem.profile_id#:#profileItem.revision#" class="verified-row-select" aria-label="Selecionar #encodeForHTMLAttribute(profileItem.name)#" <cfif NOT verifiedData.ready>disabled</cfif>/><span class="verified-mobile-label">Selecionar para classificar</span></label></cfif></td>
            <td><a class="verified-person" href="#encodeForHTMLAttribute(verifiedUrl({page_id=profileItem.profile_id}))###detalhes">#encodeForHTML(profileItem.name)#</a><small class="verified-email">#encodeForHTML(profileItem.email)#</small><small class="text-muted">Perfil #profileItem.profile_id# · Usuário #profileItem.user_id#</small></td>
            <td><div class="verified-origin-list"><cfif profileItem.permanent><span class="verified-pill <cfif profileItem.category EQ 'nao_informado'>is-attention</cfif>">#encodeForHTML(verifiedCategories[profileItem.category])#</span><small class="text-muted">Concessão permanente</small><cfif len(profileItem.reason)><p class="verified-reason">#encodeForHTML(profileItem.reason)#</p></cfif></cfif><cfif profileItem.vip><span class="verified-pill">Todo Santo Dia · VIP</span></cfif><cfif profileItem.upgrade><span class="verified-pill">Todo Santo Dia · Upgrade VIP</span></cfif><cfif profileItem.annual><span class="verified-pill">Compra anual do selo</span></cfif><cfif NOT profileItem.active><span class="text-muted">Sem origem ativa</span></cfif></div><cfif profileItem.has_refund><small class="text-muted">Possui estorno no histórico</small></cfif>
                <cfif profileItem.permanent AND profileItem.category EQ 'nao_informado'>
                    <form method="post" action="#encodeForHTMLAttribute(verifiedUrl({page_id=''}))#" class="verified-inline-form" data-quick-form>
                        <input type="hidden" name="verified_action" value="quick"/><input type="hidden" name="verified_csrf" value="#encodeForHTMLAttribute(verifiedCsrf)#"/><input type="hidden" name="selection" value="#profileItem.profile_id#:#profileItem.revision#"/>
                        <fieldset <cfif NOT verifiedData.ready>disabled</cfif>>
                            <div class="verified-inline-controls"><select class="form-select form-select-sm" name="category" aria-label="Motivo do selo de #encodeForHTMLAttribute(profileItem.name)#" required data-quick-category><option value="">Escolha o motivo</option><cfloop list="#verifiedSelectionCategories#" index="categoryKey"><option value="#categoryKey#">#encodeForHTML(verifiedCategories[categoryKey])#</option></cfloop></select><button type="submit" class="btn btn-sm btn-warning" aria-label="Salvar motivo de #encodeForHTMLAttribute(profileItem.name)#">Salvar</button></div>
                            <input class="form-control form-control-sm" name="note" maxlength="1800" placeholder="Vínculo ou observação (opcional)" aria-label="Vínculo ou observação de #encodeForHTMLAttribute(profileItem.name)#" data-quick-note/>
                        </fieldset>
                    </form>
                </cfif>
            </td>
            <td><cfif profileItem.permanent><strong>Sem vencimento</strong><cfelseif profileItem.active><strong>Ativo</strong><small class="verified-email">Até #profileItem.valid_until#</small><cfelse><strong class="text-muted">Inativo</strong><cfif len(profileItem.valid_until)><small class="verified-email">Prazo encerrado em #profileItem.valid_until#</small></cfif></cfif></td>
            <td><a class="btn btn-sm btn-outline-warning" aria-label="Ver origens de #encodeForHTMLAttribute(profileItem.name)#" href="#encodeForHTMLAttribute(verifiedUrl({page_id=profileItem.profile_id}))###detalhes">Ver origens</a></td>
        </tr></cfloop>
        <cfif NOT arrayLen(verifiedData.rows)><tr><td colspan="5" class="verified-empty">Nenhum perfil encontrado com esses filtros.</td></tr></cfif>
    </tbody></table></div>
    <a id="verified-bulk-jump" class="verified-bulk-jump" href="##verified-bulk-form" hidden>Voltar à classificação do lote ↑</a>
    <nav class="verified-pagination" aria-label="Páginas da lista"><span>Página #verifiedData.page# de #verifiedData.pages#</span><div><cfif verifiedData.page GT 1><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(verifiedUrl({pagina=verifiedData.page-1}))#">Anterior</a></cfif><cfif verifiedData.page LT verifiedData.pages><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(verifiedUrl({pagina=verifiedData.page+1}))#">Próxima</a></cfif></div></nav>
    <p class="text-muted small">As origens pagas usam a confirmação do pagamento. Estornos ficam no histórico. Datas no horário de Brasília.</p>
</section>
</cfoutput>
