<cfset VARIABLES.audit=VARIABLES.vickyAudit/>
<cfset VARIABLES.auditState=VARIABLES.audit.state/>
<link rel="stylesheet" href="/administracao/vicky/assets/audit.css?v=20261010"/>
<div class="vp-audit" id="vp-audit-chat" data-vp-audit>
  <header class="vp-audit-intro">
    <div><div class="vp-audit-eyebrow">QUALIDADE DO ATENDIMENTO</div><h2>Auditoria de conversas</h2><p>Encontre um usuário e acompanhe suas interações com a Vicky.</p></div>
    <span class="vp-audit-private"><i class="fa-solid fa-shield-halved" aria-hidden="true"></i> Acesso restrito e registrado</span>
  </header>
  <cfif isDefined("qVickySummary") AND qVickySummary.recordCount>
    <cfoutput><div class="vp-audit-metrics" aria-label="Métricas do período, antes dos filtros">
      <span><strong>#numberFormat(qVickySummary.users,'_,___')#</strong> usuários</span><span><strong>#numberFormat(qVickySummary.runs,'_,___')#</strong> interações</span>
      <span><strong>#numberFormat(val(qVickySummary.fallbacks),'_,___')#</strong> não concluídas</span>
      <details><summary>Métricas técnicas</summary><div>#numberFormat(qVickySummary.tool_calls,'_,___')# chamadas de ferramentas · #numberFormat(qVickySummary.input_tokens+qVickySummary.output_tokens,'_,___')# tokens · #numberFormat(qVickySummary.median_latency_ms,'_,___')# ms de latência p50</div></details>
    </div></cfoutput>
  </cfif>
  <cfoutput><form class="vp-audit-filters" method="get" aria-label="Filtrar auditoria">
    <input type="hidden" name="secao" value="auditoria">
    <label class="vp-audit-search">Buscar usuário<input class="form-control" type="search" name="busca" value="#encodeForHtmlAttribute(VARIABLES.auditState.search)#" maxlength="100" placeholder="Nome ou ID do usuário"></label>
    <label>Período<select class="form-select" name="periodo"><cfloop list="7,30,90" index="VARIABLES.auditPeriod"><option value="#VARIABLES.auditPeriod#"<cfif VARIABLES.auditState.period EQ val(VARIABLES.auditPeriod)> selected</cfif>>Últimos #VARIABLES.auditPeriod# dias</option></cfloop></select></label>
    <label>Canal<select class="form-select" name="canal"><option value="">Todos os canais</option><cfloop list="web,whatsapp,instagram,manychat" index="VARIABLES.auditChannel"><option value="#VARIABLES.auditChannel#"<cfif VARIABLES.auditState.channel EQ VARIABLES.auditChannel> selected</cfif>>#VARIABLES.auditChannel EQ 'web'?'Chat web':(VARIABLES.auditChannel EQ 'whatsapp'?'WhatsApp':(VARIABLES.auditChannel EQ 'instagram'?'Instagram':'Manychat'))#</option></cfloop></select></label>
    <label>Situação<select class="form-select" name="situacao"><option value="todos">Todas as interações</option><option value="falhas"<cfif VARIABLES.auditState.status EQ 'falhas'> selected</cfif>>Não concluídas</option></select></label>
    <button class="btn btn-warning" type="submit"><i class="fa-solid fa-filter me-1" aria-hidden="true"></i>Filtrar</button>
    <a class="btn btn-outline-light" href="?secao=auditoria">Limpar</a>
  </form></cfoutput>
  <div class="vp-audit-workspace">
    <aside class="vp-audit-users" aria-label="Usuários por interação mais recente">
      <header><h3>Usuários recentes</h3><span><cfoutput>#VARIABLES.audit.userTotal#</cfoutput> no filtro</span></header>
      <div class="vp-audit-user-list">
        <cfoutput query="VARIABLES.audit.users">
          <a class="vp-audit-user<cfif id_usuario EQ VARIABLES.auditState.userId> is-selected</cfif>" data-vp-user="#id_usuario#" href="#encodeForHtmlAttribute(vickyAuditUrl(VARIABLES.auditState,{usuario=id_usuario,historico=1,snapshot=0,antes=0}))#"<cfif id_usuario EQ VARIABLES.auditState.userId> aria-current="true"</cfif>>
            <img class="vp-audit-avatar" src="#encodeForHtmlAttribute(vickyAuditAvatar(avatar))#" alt="" loading="lazy" referrerpolicy="no-referrer">
            <span class="vp-audit-user-copy"><strong>#encodeForHtml(user_name)#</strong><time datetime="#dateTimeFormat(last_at,"yyyy-mm-dd'T'HH:nn:ss")#">#dateTimeFormat(last_at,'dd/mm · HH:nn')#</time><small>#interactions# interação(ões) · #encodeForHtml(channels)#</small><cfif issues GT 0><span class="vp-audit-issue">#issues# não concluída(s)</span></cfif></span>
            <i class="fa-solid fa-chevron-right" aria-hidden="true"></i>
          </a>
        </cfoutput>
        <cfif NOT VARIABLES.audit.users.recordCount><div class="vp-audit-empty small"><i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i><strong>Nenhum usuário neste filtro</strong><span>Tente outro período ou limpe a busca.</span></div></cfif>
      </div>
      <cfoutput><nav class="vp-audit-user-pages" aria-label="Páginas de usuários">
        <cfif VARIABLES.auditState.userPage GT 1><a class="btn btn-sm btn-outline-light" href="#encodeForHtmlAttribute(vickyAuditUrl(VARIABLES.auditState,{pagina_usuarios=VARIABLES.auditState.userPage-1}))#" aria-label="Usuários anteriores"><i class="fa-solid fa-chevron-left" aria-hidden="true"></i></a></cfif>
        <span>#VARIABLES.auditState.userPage# / #VARIABLES.audit.userPages#</span>
        <cfif VARIABLES.auditState.userPage LT VARIABLES.audit.userPages><a class="btn btn-sm btn-outline-light" href="#encodeForHtmlAttribute(vickyAuditUrl(VARIABLES.auditState,{pagina_usuarios=VARIABLES.auditState.userPage+1}))#" aria-label="Próximos usuários"><i class="fa-solid fa-chevron-right" aria-hidden="true"></i></a></cfif>
      </nav></cfoutput>
    </aside>
    <section class="vp-audit-conversation" aria-label="Histórico do usuário">
      <cfif VARIABLES.audit.selected.recordCount>
        <cfoutput><header class="vp-audit-chat-head"><img class="vp-audit-avatar" src="#encodeForHtmlAttribute(vickyAuditAvatar(VARIABLES.audit.selected.avatar))#" alt="" referrerpolicy="no-referrer"><div><h3>#encodeForHtml(VARIABLES.audit.selected.user_name)#</h3><p>Usuário ###VARIABLES.auditState.userId# · #VARIABLES.audit.turnTotal# interação(ões) neste recorte</p></div><a class="btn btn-sm btn-outline-light" href="#encodeForHtmlAttribute(vickyAuditUrl(VARIABLES.auditState,{historico=1,snapshot=0,antes=0}))#" title="Consultar as interações mais recentes"><i class="fa-solid fa-rotate me-1" aria-hidden="true"></i>Atualizar</a></header></cfoutput>
        <p class="vp-audit-sensitive"><i class="fa-solid fa-lock" aria-hidden="true"></i> Cada interação aberta é registrada. Use as conversas apenas para segurança, qualidade ou atendimento autorizado.</p>
        <cfif VARIABLES.audit.outsidePeriod><div class="alert alert-warning small mx-3">Este link abriu uma execução anterior ao período selecionado.</div></cfif>
        <div class="vp-audit-chat-scroll" data-vp-chat-scroll>
          <div data-vp-history-controls>
            <cfoutput><cfif VARIABLES.audit.hasOlder AND VARIABLES.audit.turns.recordCount><a class="vp-audit-older btn btn-sm btn-outline-light" data-vp-older href="#encodeForHtmlAttribute(vickyAuditUrl(VARIABLES.auditState,{historico=VARIABLES.auditState.historyPage+1,antes=VARIABLES.audit.turns.id_vicky_execucao[1]}))#">Carregar interações anteriores</a><cfelse><p class="vp-audit-start">Início do histórico disponível neste recorte</p></cfif>
            <cfif VARIABLES.auditState.historyPage GT 1><a class="vp-audit-newer" href="#encodeForHtmlAttribute(vickyAuditUrl(VARIABLES.auditState,{historico=1,antes=0}))#">Ver interações recentes</a></cfif></cfoutput>
          </div>
          <p class="vp-audit-load-message" data-vp-history-status role="status" aria-live="polite"></p>
          <div data-vp-turns data-vp-user-id="<cfoutput>#VARIABLES.auditState.userId#</cfoutput>">
            <cfoutput query="VARIABLES.audit.turns">
              <cfset VARIABLES.auditTurnStatus=vickyAuditStatus(status&'')/>
              <article class="vp-audit-turn<cfif id_vicky_execucao EQ VARIABLES.auditState.executionId> is-highlighted</cfif>" id="vp-run-#id_vicky_execucao#" data-vp-turn="#id_vicky_execucao#">
                <div class="vp-audit-turn-divider"><time datetime="#dateTimeFormat(created_at,"yyyy-mm-dd'T'HH:nn:ss")#">#dateTimeFormat(created_at,'dd/mm/yyyy · HH:nn:ss')#</time><span>#encodeForHtml(channel EQ 'web'?'Chat web':channel)#</span></div>
                <div class="vp-audit-message is-user"><div class="vp-audit-message-label">#encodeForHtml(VARIABLES.audit.selected.user_name)#</div><div class="vp-audit-bubble"><cfif len(trim(user_content&''))>#encodeForHtml(user_content&'')#<cfelse><span class="vp-audit-unavailable">Mensagem indisponível. Pode ter sido removida pela política de retenção.</span></cfif></div><cfif isDate(user_created_at)><time>#timeFormat(user_created_at,'HH:nn:ss')#</time></cfif></div>
                <div class="vp-audit-message is-vicky"><div class="vp-audit-message-label"><i class="fa-solid fa-wand-magic-sparkles" aria-hidden="true"></i> Vicky Pacer</div><div class="vp-audit-bubble"><cfif len(trim(assistant_content&''))>#encodeForHtml(assistant_content&'')#<cfelse><span class="vp-audit-unavailable"><cfif status EQ 'started'>Resposta ainda em processamento.<cfelse>Não há resposta disponível para esta execução.</cfif></span></cfif></div><cfif isDate(assistant_created_at)><time>#timeFormat(assistant_created_at,'HH:nn:ss')#</time></cfif></div>
                <div class="vp-audit-turn-footer"><span class="badge text-bg-#VARIABLES.auditTurnStatus.tone#">#encodeForHtml(VARIABLES.auditTurnStatus.label)#</span><details class="vp-audit-technical"><summary>Detalhes técnicos · execução ###id_vicky_execucao#</summary><div class="vp-audit-technical-body"><div class="vp-audit-tech-values"><span>Modelo <strong>#encodeForHtml(model&'')#</strong></span><span>Tokens <strong>#val(input_tokens)+val(output_tokens)#</strong></span><span>Latência <strong>#val(latency_ms)# ms</strong></span><span>Ferramentas <strong>#val(tool_calls)#</strong></span></div>
                  <cfif len(error_code&'')><p class="text-danger mb-2">Erro: #encodeForHtml(error_code&'')#</p></cfif><cfif len(fallback_reason&'')><p class="vp-muted mb-2">Motivo: #encodeForHtml(fallback_reason&'')#</p></cfif>
                  <cfset VARIABLES.auditTurnId=id_vicky_execucao/>
                  <cfloop query="VARIABLES.audit.tools"><cfif id_vicky_execucao EQ VARIABLES.auditTurnId><div class="vp-audit-tool"><strong>#encodeForHtml(tool_name)#</strong> · #encodeForHtml(status)# · #val(latency_ms)# ms<dl><dt>Argumentos sanitizados</dt><dd><code>#encodeForHtml(arguments_summary&'')#</code></dd><dt>Resultado resumido</dt><dd><code>#encodeForHtml(result_summary&'')#</code></dd></dl></div></cfif></cfloop>
                  <a class="vp-audit-permalink" href="#encodeForHtmlAttribute(vickyAuditUrl(VARIABLES.auditState,{execucao=VARIABLES.auditTurnId}))#">Link direto desta interação</a>
                </div></details></div>
              </article>
            </cfoutput>
          </div>
          <cfif NOT VARIABLES.audit.turns.recordCount><div class="vp-audit-empty"><i class="fa-regular fa-comments" aria-hidden="true"></i><strong>Nenhuma interação neste recorte</strong><span>Altere o período, o canal ou a situação para ver outras interações.</span></div></cfif>
        </div>
        <footer class="vp-audit-chat-foot"><cfoutput>Bloco #VARIABLES.auditState.historyPage# de #VARIABLES.audit.historyPages# · até 20 interações por carregamento</cfoutput><span>Somente leitura</span></footer>
      <cfelse>
        <div class="vp-audit-empty"><i class="fa-regular fa-comments" aria-hidden="true"></i><h3>Selecione um usuário para auditar</h3><p>A lista começa por quem interagiu mais recentemente.<br>As mensagens só são abertas após a seleção.</p><cfif VARIABLES.auditState.userId GT 0><span class="text-warning">O usuário solicitado não foi encontrado.</span></cfif></div>
      </cfif>
    </section>
  </div>
</div>
<script src="/administracao/vicky/assets/audit.js?v=20261010" defer></script>
