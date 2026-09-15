<cfif NOT structKeyExists(VARIABLES,"helpdeskCanManage") OR NOT VARIABLES.helpdeskCanManage><cfheader statuscode="403" statustext="Forbidden"/><cfabort/></cfif>
<link rel="stylesheet" href="/helpdesk/assets/workspace.css?v=20260914-1"/>
<section class="hd-workspace" aria-label="Central de atendimento">
<cfoutput>
  <header class="hd-header">
    <div class="hd-heading"><span class="hd-brand-icon" aria-hidden="true"><i class="fa-solid fa-headset"></i></span><div><div class="hd-kicker">Relacionamento com o usuário</div><h1>Central de atendimento</h1><p>Contexto, organização e respostas melhores em um só lugar.</p></div></div>
    <div class="hd-header-actions"><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(hdUrl({ticket_id=val(URL.ticket_id ?: 0)}))#"><i class="fa-solid fa-arrows-rotate me-2" aria-hidden="true"></i>Atualizar</a><a class="btn btn-warning" href="#encodeForHTMLAttribute(hdUrl({ticket_novo=1}))#">Novo chamado</a><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(hdUrl({gestao=1}))###hd-setores">Setores</a></div>
  </header>
  <cfif NOT VARIABLES.helpdeskTablesReady>
    <div class="alert alert-warning">A estrutura do helpdesk ainda não está disponível. Solicite a configuração à equipe técnica.</div>
  <cfelse>
    <div class="hd-overview-label"><span>Visão geral · #LSNumberFormat(hdData.stats.total)# chamados no histórico</span><span>Atualizado às #timeFormat(now(),"HH:nn")# · indicadores não usam os filtros da fila</span></div>
    <div class="hd-stats">
      <article class="hd-stat hd-stat-amber"><span>A responder</span><strong>#LSNumberFormat(hdData.stats.pendentes)#</strong><small>Abertos + usuário respondeu</small></article>
      <article class="hd-stat hd-stat-blue"><span>Em atendimento</span><strong>#LSNumberFormat(hdData.stats.em_atendimento)#</strong><small>Tratativas em andamento</small></article>
      <article class="hd-stat"><span>Aguardando usuário</span><strong>#LSNumberFormat(hdData.stats.aguardando_cliente)#</strong><small>Retorno solicitado ao usuário</small></article>
      <article class="hd-stat hd-stat-green"><span>Concluídos</span><strong>#LSNumberFormat(hdData.stats.encerrados)#</strong><small>Resolvidos + fechados</small></article>
      <article class="hd-stat hd-stat-red"><span>Sem atualização · 48 h</span><strong>#LSNumberFormat(hdData.stats.sem_atualizacao)#</strong><small>Não concluídos · não é um SLA</small></article>
    </div>
    <cfif len(hdError)><div class="alert alert-warning" role="alert">#encodeForHTML(hdError)#</div></cfif>
    <cfif (URL.salvo ?: "") EQ "resposta"><div class="alert alert-success" role="status">Resposta registrada no chamado.</div><cfelseif (URL.salvo ?: "") EQ "status"><div class="alert alert-success" role="status">Status e setor atualizados. Nenhuma mensagem foi enviada.</div></cfif>
    <section class="hd-filters" aria-label="Filtros da fila">
      <nav class="hd-views" aria-label="Visões da fila">
        <cfloop array="#[{key='',label='Todos'},{key='pendentes',label='A responder'},{key='meus',label='Meus setores'},{key='sem_atualizacao',label='Sem atualização há 48 h'}]#" item="hdView">
          <a class="<cfif hdFilters.fila EQ hdView.key>is-active</cfif>" <cfif hdFilters.fila EQ hdView.key>aria-current="page"</cfif> href="#encodeForHTMLAttribute(hdUrl({fila=hdView.key,pagina=1,status=''}))#">#hdView.label#</a>
        </cfloop>
      </nav>
      <form method="get" action="./" class="hd-filter-grid" role="search">
        <input type="hidden" name="fila" value="#encodeForHTMLAttribute(hdFilters.fila)#"/>
        <div class="hd-search"><label for="hd-search">Buscar chamado</label><input type="search" class="form-control" id="hd-search" name="busca" value="#encodeForHTMLAttribute(hdFilters.busca)#" maxlength="160" placeholder="Protocolo, assunto, nome ou e-mail"/></div>
        <div><label for="hd-status-filter">Status</label><select class="form-select" id="hd-status-filter" name="status"><option value="">Todos os status</option><cfloop list="aberto,cliente_respondeu,em_atendimento,aguardando_cliente,resolvido,fechado" item="hdOption"><option value="#hdOption#" <cfif hdFilters.status EQ hdOption>selected</cfif>>#hdStatus(hdOption)#</option></cfloop></select></div>
        <div><label for="hd-sector-filter">Setor</label><select class="form-select" id="hd-sector-filter" name="setor"><option value="0">Todos os setores</option><cfloop query="qHelpdeskSetores"><option value="#qHelpdeskSetores.id_setor#" <cfif hdFilters.setor EQ qHelpdeskSetores.id_setor>selected</cfif>>#encodeForHTML(qHelpdeskSetores.nome_setor)#<cfif NOT qHelpdeskSetores.ativo> (inativo)</cfif></option></cfloop></select></div>
        <div><label for="hd-order">Ordenar por</label><select class="form-select" id="hd-order" name="ordem"><option value="prioridade" <cfif hdFilters.ordem EQ 'prioridade'>selected</cfif>>Precisa de atenção</option><option value="recentes" <cfif hdFilters.ordem EQ 'recentes'>selected</cfif>>Atualização recente</option><option value="antigos" <cfif hdFilters.ordem EQ 'antigos'>selected</cfif>>Abertura mais antiga</option></select></div>
        <div class="hd-filter-buttons"><button class="btn btn-warning" type="submit">Filtrar</button><a class="btn btn-link" href="./">Limpar</a></div>
      </form>
      <p class="hd-filter-help">“Meus setores” considera o responsável padrão do setor. “Precisa de atenção” prioriza retornos do usuário e chamados abertos, começando pelos sem atualização há mais tempo.</p>
    </section>
    <div class="hd-desk">
      <aside class="hd-queue" aria-label="Fila de chamados">
        <div class="hd-panel-heading"><h2>Fila de atendimento</h2><span class="hd-count">#LSNumberFormat(hdData.total)#</span></div>
        <div class="hd-queue-list">
        <cfif NOT qHelpdeskChamados.recordcount><div class="hd-empty"><i class="fa-regular fa-circle-check" aria-hidden="true"></i><h3>Nenhum chamado nesta seleção</h3><p>Altere os filtros ou limpe a busca para consultar outros chamados.</p><a href="./">Ver todos os chamados</a></div></cfif>
        <cfloop query="qHelpdeskChamados">
          <a class="hd-ticket <cfif val(URL.ticket_id ?: 0) EQ qHelpdeskChamados.id_chamado>is-active</cfif>" href="#encodeForHTMLAttribute(hdUrl({ticket_id=qHelpdeskChamados.id_chamado}))###hd-conversa" <cfif val(URL.ticket_id ?: 0) EQ qHelpdeskChamados.id_chamado>aria-current="page"</cfif>>
            <div class="hd-ticket-top"><span class="hd-protocol">#encodeForHTML(qHelpdeskChamados.protocolo)#</span><span class="hd-badge" data-status="#encodeForHTMLAttribute(qHelpdeskChamados.status)#">#encodeForHTML(hdStatus(qHelpdeskChamados.status))#</span></div>
            <h3>#encodeForHTML(qHelpdeskChamados.assunto)#</h3>
            <div class="hd-requester"><span class="hd-avatar" aria-hidden="true">#encodeForHTML(uCase(left(qHelpdeskChamados.nome_usuario,1)))#</span><span>#encodeForHTML(qHelpdeskChamados.nome_usuario)#<small>#encodeForHTML(qHelpdeskChamados.nome_setor)#</small></span></div>
            <div class="hd-ticket-bottom"><span title="#encodeForHTMLAttribute(dateTimeFormat(qHelpdeskChamados.updated_at,'dd/mm/yyyy HH:nn'))#">Atualizado #hdAge(qHelpdeskChamados.updated_at)#</span><span>#qHelpdeskChamados.mensagens# mensagens</span></div>
            <cfif qHelpdeskChamados.sem_atualizacao><div class="hd-stale"><i class="fa-regular fa-clock" aria-hidden="true"></i> Sem atualização há mais de 48 h</div></cfif>
          </a>
        </cfloop>
        </div>
        <nav class="hd-pagination" aria-label="Páginas da fila"><cfif hdData.page GT 1><a href="#encodeForHTMLAttribute(hdUrl({pagina=hdData.page-1}))#" aria-label="Página anterior"><i class="fa-solid fa-chevron-left" aria-hidden="true"></i></a><cfelse><span aria-hidden="true">—</span></cfif><span>Página #hdData.page# de #hdData.pages# · até 20 por página</span><cfif hdData.page LT hdData.pages><a href="#encodeForHTMLAttribute(hdUrl({pagina=hdData.page+1}))#" aria-label="Próxima página"><i class="fa-solid fa-chevron-right" aria-hidden="true"></i></a><cfelse><span aria-hidden="true">—</span></cfif></nav>
      </aside>
      <section class="hd-detail" id="hd-conversa" aria-label="Conversa e atendimento">
        <cfif qHelpdeskTicketEdit.recordcount>
          <header class="hd-detail-header"><div class="hd-ticket-top"><span class="hd-protocol">#encodeForHTML(qHelpdeskTicketEdit.protocolo)#</span><span class="hd-badge" data-status="#encodeForHTMLAttribute(qHelpdeskTicketEdit.status)#">#encodeForHTML(hdStatus(qHelpdeskTicketEdit.status))#</span></div><h2>#encodeForHTML(qHelpdeskTicketEdit.assunto)#</h2><div class="hd-contact"><strong>#encodeForHTML(qHelpdeskTicketEdit.nome_usuario)#</strong><span>#encodeForHTML(qHelpdeskTicketEdit.email_usuario)#</span></div><div class="hd-detail-meta"><span>Aberto em #dateTimeFormat(qHelpdeskTicketEdit.created_at,'dd/mm/yyyy HH:nn')#</span><span>Setor: #encodeForHTML(qHelpdeskTicketEdit.nome_setor)#</span><span>Responsável do setor: #len(trim(qHelpdeskTicketEdit.nome_responsavel)) ? encodeForHTML(qHelpdeskTicketEdit.nome_responsavel) : 'Não definido'#</span></div><a class="hd-jump" href="##hd-editor">Ir para a resposta <i class="fa-solid fa-arrow-down" aria-hidden="true"></i></a></header>
          <div class="hd-thread" aria-label="Histórico da conversa">
            <cfif NOT qHelpdeskMensagens.recordcount><p class="text-muted">Nenhuma mensagem registrada.</p></cfif>
            <cfloop query="qHelpdeskMensagens"><article class="hd-message <cfif qHelpdeskMensagens.is_admin>is-team</cfif>"><header><span class="hd-avatar" aria-hidden="true">#encodeForHTML(uCase(left(qHelpdeskMensagens.nome_usuario,1)))#</span><div><strong>#encodeForHTML(qHelpdeskMensagens.nome_usuario)#</strong><small><cfif qHelpdeskMensagens.is_admin>Equipe de atendimento<cfelse>Solicitante</cfif></small></div><time datetime="#dateTimeFormat(qHelpdeskMensagens.created_at,"yyyy-mm-dd'T'HH:nn:ss")#">#dateTimeFormat(qHelpdeskMensagens.created_at,'dd/mm HH:nn')#</time></header><div class="hd-message-body">#encodeForHTML(qHelpdeskMensagens.mensagem)#</div></article></cfloop>
          </div>
          <form method="post" action="#encodeForHTMLAttribute(hdUrl({ticket_id=qHelpdeskTicketEdit.id_chamado}))###hd-editor" class="hd-editor" id="hd-editor" data-hd-reply>
            <input type="hidden" name="helpdesk_csrf" value="#encodeForHTMLAttribute(SESSION.helpdeskCsrf)#"/><input type="hidden" name="ticket_id" value="#qHelpdeskTicketEdit.id_chamado#"/><input type="hidden" name="ticket_revision" value="#encodeForHTMLAttribute(qHelpdeskTicketEdit.revision)#"/><input type="hidden" name="ticket_last_message" value="#qHelpdeskTicketEdit.last_message_id#"/>
            <div class="hd-panel-heading"><h3>Responder ao usuário</h3><span class="hd-public-label"><i class="fa-regular fa-eye" aria-hidden="true"></i> Mensagem pública</span></div>
            <div class="hd-routing"><div><label for="hd-ticket-status">Status após a ação</label><select class="form-select" id="hd-ticket-status" name="ticket_status"><cfloop list="aberto,cliente_respondeu,em_atendimento,aguardando_cliente,resolvido,fechado" item="hdOption"><option value="#hdOption#" <cfif (len(hdError) ? (FORM.ticket_status ?: qHelpdeskTicketEdit.status) : qHelpdeskTicketEdit.status) EQ hdOption>selected</cfif>>#hdStatus(hdOption)#</option></cfloop></select></div><div><label for="hd-ticket-sector">Encaminhar para o setor</label><select class="form-select" id="hd-ticket-sector" name="ticket_setor_id"><cfloop query="qHelpdeskSetores"><cfif qHelpdeskSetores.ativo OR qHelpdeskSetores.id_setor EQ qHelpdeskTicketEdit.id_setor><option value="#qHelpdeskSetores.id_setor#" <cfif (len(hdError) ? val(FORM.ticket_setor_id ?: qHelpdeskTicketEdit.id_setor) : qHelpdeskTicketEdit.id_setor) EQ qHelpdeskSetores.id_setor>selected</cfif>>#encodeForHTML(qHelpdeskSetores.nome_setor)#</option></cfif></cfloop></select></div></div>
<cfinclude template="ai-editor.cfm"/>
            <div class="hd-quick-replies"><label for="hd-quick-reply">Respostas rápidas</label><select class="form-select" id="hd-quick-reply" data-hd-template><option value="">Escolha um ponto de partida…</option><option value="contexto">Pedir informações para investigar</option><option value="andamento">Informar que estamos verificando</option><option value="confirmacao">Pedir confirmação da solução</option></select><button class="btn btn-outline-secondary btn-sm" type="button" data-hd-insert>Inserir no texto</button></div>
            <label for="helpdesk-reply-message">Nova mensagem</label><textarea class="form-control" id="helpdesk-reply-message" name="ticket_mensagem" rows="7" maxlength="12000" placeholder="Escreva uma resposta clara: o que foi verificado e qual é o próximo passo."><cfif len(hdError)>#encodeForHTML(FORM.ticket_mensagem ?: '')#</cfif></textarea>
            <div class="hd-editor-hint"><span>Revise antes de enviar. Não inclua senhas ou dados sensíveis.</span><span data-hd-count>0 / 12.000</span></div>
            <div class="hd-editor-actions"><button type="submit" name="helpdesk_action" value="responder_ticket" class="btn btn-warning"><i class="fa-regular fa-paper-plane me-2" aria-hidden="true"></i>Enviar resposta</button><button type="submit" name="helpdesk_action" value="atualizar_ticket" class="btn btn-outline-secondary">Salvar somente status e setor</button></div><p class="hd-action-note">Salvar somente status e setor não envia mensagem ao usuário.</p><div class="small" role="status" aria-live="polite" data-hd-feedback></div>
          </form>
        <cfelseif val(URL.ticket_novo ?: 0) EQ 1>
          <div class="hd-new-ticket"><h2>Novo chamado manual</h2><p class="text-muted">O chamado será aberto em nome do seu usuário administrativo.</p><form method="post" action="#encodeForHTMLAttribute(hdUrl())#"><input type="hidden" name="helpdesk_action" value="novo_ticket"/><input type="hidden" name="helpdesk_csrf" value="#encodeForHTMLAttribute(SESSION.helpdeskCsrf)#"/><label for="hd-new-sector">Setor</label><select class="form-select mb-3" id="hd-new-sector" name="ticket_setor_id" required><option value="">Selecione</option><cfloop query="qHelpdeskSetores"><cfif qHelpdeskSetores.ativo><option value="#qHelpdeskSetores.id_setor#">#encodeForHTML(qHelpdeskSetores.nome_setor)#</option></cfif></cfloop></select><label for="hd-new-subject">Assunto</label><input class="form-control mb-3" id="hd-new-subject" name="ticket_assunto" maxlength="180" required/><label for="hd-new-message">Mensagem inicial</label><textarea class="form-control mb-3" id="hd-new-message" name="ticket_mensagem" maxlength="12000" rows="7" required></textarea><button type="submit" class="btn btn-warning">Abrir chamado</button></form></div>
        <cfelse><div class="hd-empty hd-empty-detail"><span class="hd-brand-icon"><i class="fa-regular fa-comments" aria-hidden="true"></i></span><h2><cfif val(URL.ticket_id ?: 0)>Chamado não encontrado<cfelse>Um atendimento por vez, com todo o contexto</cfif></h2><p>Selecione um chamado na fila para ler a conversa, gerar um rascunho com IA e definir o próximo passo.</p><div class="hd-empty-tips"><span><i class="fa-solid fa-filter" aria-hidden="true"></i> Priorize quem espera uma resposta</span><span><i class="fa-solid fa-wand-magic-sparkles" aria-hidden="true"></i> Use a IA e revise antes de enviar</span><span><i class="fa-regular fa-circle-check" aria-hidden="true"></i> Mantenha o status atualizado</span></div></div></cfif>
      </section>
    </div>
<cfinclude template="workspace-sectors.cfm"/>
  </cfif>
</cfoutput>
</section>
<script src="/helpdesk/assets/workspace.js?v=20260914-1" defer></script>
