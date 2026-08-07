<cfscript>
function chatPercent(required numeric value, required numeric total) {
    return arguments.total GT 0 ? (arguments.value / arguments.total) * 100 : 0;
}
function chatDuration(any minutesValue) {
    var minutes = val(arguments.minutesValue);
    if (minutes LTE 0) return "—";
    if (minutes LT 60) return numberFormat(minutes, "9") & " min";
    if (minutes LT 1440) return numberFormat(minutes / 60, "9.9") & " h";
    return numberFormat(minutes / 1440, "9.9") & " d";
}
function chatOriginLabel(required string origin) {
    return arguments.origin EQ "follower" ? "Contatos" : "Não contatos";
}
chatSummary = VARIABLES.chatReady AND qChatSummary.recordCount ? qChatSummary : queryNew("");
chatMessages = chatSummary.recordCount ? val(chatSummary.messages) : 0;
chatMaxTimeline = 1;
for (timelineRow in qChatTimeline) chatMaxTimeline = max(chatMaxTimeline, val(timelineRow.messages));
chatMaxIcon = 1;
for (iconRow in qChatIcons) chatMaxIcon = max(chatMaxIcon, val(iconRow.total));
chatMaxDepth = 1;
for (depthRow in qChatDepth) chatMaxDepth = max(chatMaxDepth, val(depthRow.total));
chatPeriodLabel = VARIABLES.chatAllTime ? "Todo o período" : "Últimos " & VARIABLES.chatPeriod & " dias";
</cfscript>

<style>
  .chat-analytics { --ca-border: rgba(255,255,255,.11); --ca-muted: rgba(255,255,255,.62); }
  .chat-analytics .ca-hero { background: linear-gradient(135deg, rgba(255,193,7,.14), rgba(255,255,255,.025)); border: 1px solid var(--ca-border); border-radius: 12px; }
  .chat-analytics .ca-metrics { border: 1px solid var(--ca-border); border-radius: 10px; display: grid; grid-template-columns: repeat(6,minmax(0,1fr)); overflow: hidden; }
  .chat-analytics .ca-metric { min-height: 112px; padding: 1rem; }
  .chat-analytics .ca-metric + .ca-metric { border-left: 1px solid var(--ca-border); }
  .chat-analytics .ca-label { color: var(--ca-muted); display: block; font-size: .7rem; font-weight: 700; letter-spacing: .035em; margin-bottom: .35rem; text-transform: uppercase; }
  .chat-analytics .ca-value { font-size: 1.7rem; font-weight: 750; line-height: 1.1; }
  .chat-analytics .ca-card { border: 1px solid var(--ca-border); border-radius: 10px; height: 100%; padding: 1.2rem; }
  .chat-analytics .ca-subtle { color: var(--ca-muted); }
  .chat-analytics .ca-bars { display: grid; gap: .75rem; }
  .chat-analytics .ca-bar-row { align-items: center; display: grid; gap: .7rem; grid-template-columns: minmax(82px,120px) minmax(0,1fr) 54px; }
  .chat-analytics .ca-track { background: rgba(255,255,255,.06); border-radius: 999px; height: 10px; overflow: hidden; }
  .chat-analytics .ca-fill { background: #ffc107; border-radius: inherit; height: 100%; min-width: 2px; }
  .chat-analytics .ca-fill-secondary { background: #54b4d3; }
  .chat-analytics .ca-timeline { align-items: end; display: flex; gap: 3px; height: 150px; overflow: hidden; padding-top: 1rem; }
  .chat-analytics .ca-day { background: #ffc107; border-radius: 3px 3px 0 0; flex: 1 1 4px; min-width: 3px; opacity: .82; position: relative; }
  .chat-analytics .ca-day:hover { opacity: 1; }
  .chat-analytics .ca-privacy { border-left: 3px solid #14a44d; }
  .chat-analytics table { font-size: .86rem; }
  @media(max-width: 1100px) { .chat-analytics .ca-metrics { grid-template-columns: repeat(3,minmax(0,1fr)); } .chat-analytics .ca-metric:nth-child(4) { border-left: 0; border-top: 1px solid var(--ca-border); } .chat-analytics .ca-metric:nth-child(5), .chat-analytics .ca-metric:nth-child(6) { border-top: 1px solid var(--ca-border); } }
  @media(max-width: 650px) { .chat-analytics .ca-metrics { grid-template-columns: repeat(2,minmax(0,1fr)); } .chat-analytics .ca-metric:nth-child(odd) { border-left: 0; } .chat-analytics .ca-metric:nth-child(n+3) { border-top: 1px solid var(--ca-border); } }
</style>

<section class="chat-analytics py-4 py-lg-5">
  <div class="ca-hero p-4 mb-4 d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
    <div>
      <div class="text-warning small fw-bold text-uppercase mb-2">Administração · Produto</div>
      <h1 class="h3 mb-2">Uso do Chat</h1>
      <p class="ca-subtle mb-0">Adoção, interação e eficiência da nova experiência de mensagens do Road Runners.</p>
    </div>
    <form method="get" class="d-flex gap-2 align-items-center">
      <label for="chatPeriod" class="small ca-subtle">Período</label>
      <select id="chatPeriod" name="periodo" class="form-select form-select-sm" onchange="this.form.submit()">
        <option value="7" <cfif VARIABLES.chatPeriod EQ "7">selected</cfif>>7 dias</option>
        <option value="30" <cfif VARIABLES.chatPeriod EQ "30">selected</cfif>>30 dias</option>
        <option value="90" <cfif VARIABLES.chatPeriod EQ "90">selected</cfif>>90 dias</option>
        <option value="all" <cfif VARIABLES.chatPeriod EQ "all">selected</cfif>>Todo o período</option>
      </select>
    </form>
  </div>

  <cfif NOT VARIABLES.chatReady>
    <div class="alert alert-warning">
      <strong>Painel indisponível.</strong> Falha na etapa <cfoutput><strong>#htmlEditFormat(VARIABLES.chatErrorStep)#</strong>.</cfoutput>
      <span class="d-block small mt-2"><cfoutput>#htmlEditFormat(VARIABLES.chatError)#<cfif len(VARIABLES.chatErrorDetail)> — #htmlEditFormat(VARIABLES.chatErrorDetail)#</cfif></cfoutput></span>
    </div>
  <cfelse>
    <div class="ca-privacy bg-success bg-opacity-10 rounded p-3 mb-4 d-flex gap-3">
      <i class="fa-solid fa-shield-halved text-success mt-1"></i>
      <div><strong>Privacidade por desenho</strong><div class="small ca-subtle">Nenhum texto, destinatário ou conversa individual é retornado. A listagem identifica somente o usuário remetente e seus totais agregados; ícones são reconhecidos pelo token técnico exato, sem leitura do texto livre.</div></div>
    </div>

    <div class="ca-metrics mb-4">
      <div class="ca-metric"><span class="ca-label">Mensagens enviadas</span><div class="ca-value"><cfoutput>#numberFormat(chatMessages,"_,___")#</cfoutput></div><small class="ca-subtle"><cfoutput>#chatPeriodLabel#</cfoutput></small></div>
      <div class="ca-metric"><span class="ca-label">Usuários ativos</span><div class="ca-value"><cfoutput>#numberFormat(val(chatSummary.active_users),"_,___")#</cfoutput></div><small class="ca-subtle">Enviaram ou receberam</small></div>
      <div class="ca-metric"><span class="ca-label">Remetentes ativos</span><div class="ca-value"><cfoutput>#numberFormat(val(chatSummary.active_senders),"_,___")#</cfoutput></div><small class="ca-subtle"><cfoutput>#numberFormat(val(chatSummary.avg_messages_per_sender),"9.9")# msg por remetente</cfoutput></small></div>
      <div class="ca-metric"><span class="ca-label">Conversas ativas</span><div class="ca-value"><cfoutput>#numberFormat(val(chatSummary.conversations),"_,___")#</cfoutput></div><small class="ca-subtle">Com envio no período</small></div>
      <div class="ca-metric"><span class="ca-label">Conversas recíprocas</span><div class="ca-value"><cfoutput>#numberFormat(chatPercent(val(chatSummary.reciprocal_conversations),val(chatSummary.conversations)),"9.9")#%</cfoutput></div><small class="ca-subtle">Ambas as pessoas enviaram</small></div>
      <div class="ca-metric"><span class="ca-label">Leitura estimada</span><div class="ca-value"><cfoutput>#numberFormat(chatPercent(val(chatSummary.read_messages),chatMessages),"9.9")#%</cfoutput></div><small class="ca-subtle">Pelo marcador de leitura</small></div>
    </div>

    <div class="row g-4 mb-4">
      <div class="col-12 col-xl-8"><div class="ca-card">
        <div class="d-flex justify-content-between align-items-start"><div><h2 class="h5 mb-1">Envios ao longo do tempo</h2><p class="small ca-subtle mb-0">Volume diário de mensagens válidas</p></div><span class="badge badge-warning"><cfoutput>#chatPeriodLabel#</cfoutput></span></div>
        <div class="ca-timeline">
          <cfoutput query="qChatTimeline"><div class="ca-day" style="height:#max(3,(val(messages)/chatMaxTimeline)*100)#%" title="#dateFormat(day,'dd/mm/yyyy')#: #numberFormat(messages,'_,___')# mensagens, #numberFormat(senders,'_,___')# remetentes"></div></cfoutput>
        </div>
        <div class="d-flex justify-content-between small ca-subtle mt-2"><span><cfif qChatTimeline.recordCount><cfoutput>#dateFormat(qChatTimeline.day[1],"dd/mm")#</cfoutput></cfif></span><span><cfif qChatTimeline.recordCount><cfoutput>#dateFormat(qChatTimeline.day[qChatTimeline.recordCount],"dd/mm")#</cfoutput></cfif></span></div>
      </div></div>
      <div class="col-12 col-xl-4"><div class="ca-card">
        <h2 class="h5 mb-1">Eficiência da interação</h2><p class="small ca-subtle mb-3">Sinais de resposta, leitura e continuidade</p>
        <div class="border-bottom pb-3 mb-3"><span class="ca-label">Tempo mediano de resposta</span><div class="h3 mb-0"><cfoutput>#chatDuration(chatSummary.median_response_minutes)#</cfoutput></div></div>
        <div class="d-flex justify-content-between mb-2"><span>Mensagens por conversa</span><strong><cfoutput>#numberFormat(chatMessages/max(1,val(chatSummary.conversations)),"9.9")#</cfoutput></strong></div>
        <div class="d-flex justify-content-between mb-2"><span>Uso de ícones</span><strong><cfoutput>#numberFormat(chatPercent(val(chatSummary.icon_messages),chatMessages),"9.9")#%</cfoutput></strong></div>
        <div class="d-flex justify-content-between mb-2"><span>Mensagens editadas</span><strong><cfoutput>#numberFormat(chatPercent(val(chatSummary.edited_messages),chatMessages),"9.9")#%</cfoutput></strong></div>
        <div class="d-flex justify-content-between"><span>Mensagens removidas</span><strong><cfoutput>#numberFormat(chatPercent(val(chatSummary.removed_messages),max(1,chatMessages+val(chatSummary.removed_messages))),"9.9")#%</cfoutput></strong></div>
      </div></div>
    </div>

    <div class="row g-4 mb-4">
      <div class="col-12 col-lg-6"><div class="ca-card">
        <h2 class="h5 mb-1">Contatos x não contatos</h2><p class="small ca-subtle mb-3">Origem da autorização da conversa</p>
        <div class="table-responsive"><table class="table table-sm align-middle mb-0"><thead><tr><th>Relação</th><th class="text-end">Mensagens</th><th class="text-end">Conversas</th><th class="text-end">Recíprocas</th></tr></thead><tbody>
          <cfoutput query="qChatOrigins"><tr><td>#chatOriginLabel(origin)#</td><td class="text-end">#numberFormat(messages,'_,___')# <small class="ca-subtle">(#numberFormat(chatPercent(messages,chatMessages),'9.9')#%)</small></td><td class="text-end">#numberFormat(conversations,'_,___')#</td><td class="text-end">#numberFormat(chatPercent(reciprocal_conversations,conversations),'9.9')#%</td></tr></cfoutput>
          <cfif NOT qChatOrigins.recordCount><tr><td colspan="4" class="text-center ca-subtle py-3">Sem atividade no período.</td></tr></cfif>
        </tbody></table></div>
      </div></div>
      <div class="col-12 col-lg-6"><div class="ca-card">
        <h2 class="h5 mb-1">Solicitações para não contatos</h2><p class="small ca-subtle mb-3">Conversas iniciadas sem vínculo prévio</p>
        <div class="row g-3 text-center mb-3"><div class="col-4"><span class="ca-label">Aceitas</span><div class="h4 text-success"><cfoutput>#numberFormat(val(qChatRequests.accepted),'_,___')#</cfoutput></div></div><div class="col-4"><span class="ca-label">Pendentes</span><div class="h4 text-warning"><cfoutput>#numberFormat(val(qChatRequests.pending),'_,___')#</cfoutput></div></div><div class="col-4"><span class="ca-label">Recusadas</span><div class="h4 text-danger"><cfoutput>#numberFormat(val(qChatRequests.rejected),'_,___')#</cfoutput></div></div></div>
        <div class="d-flex justify-content-between border-top pt-3"><span>Taxa de aceite</span><strong><cfoutput>#numberFormat(chatPercent(val(qChatRequests.accepted),val(qChatRequests.requests)),"9.9")#%</cfoutput></strong></div>
        <div class="d-flex justify-content-between mt-2"><span>Tempo mediano até aceite</span><strong><cfoutput>#chatDuration(qChatRequests.median_acceptance_minutes)#</cfoutput></strong></div>
      </div></div>
    </div>

    <div class="row g-4">
      <div class="col-12 col-lg-6"><div class="ca-card"><h2 class="h5 mb-1">Ícones mais enviados</h2><p class="small ca-subtle mb-3">Participação dos atalhos visuais no chat</p><div class="ca-bars">
        <cfoutput query="qChatIcons"><div class="ca-bar-row"><span>#htmlEditFormat(reReplace(icon_key,"-"," ","all"))#</span><div class="ca-track"><div class="ca-fill" style="width:#(val(total)/chatMaxIcon)*100#%"></div></div><strong class="text-end">#numberFormat(total,'_,___')#</strong></div></cfoutput>
        <cfif NOT qChatIcons.recordCount><div class="ca-subtle">Nenhum ícone enviado no período.</div></cfif>
      </div></div></div>
      <div class="col-12 col-lg-6"><div class="ca-card"><h2 class="h5 mb-1">Profundidade de uso</h2><p class="small ca-subtle mb-3">Distribuição dos remetentes por volume</p><div class="ca-bars">
        <cfoutput query="qChatDepth"><div class="ca-bar-row"><span>#htmlEditFormat(depth)#</span><div class="ca-track"><div class="ca-fill ca-fill-secondary" style="width:#(val(total)/chatMaxDepth)*100#%"></div></div><strong class="text-end">#numberFormat(total,'_,___')#</strong></div></cfoutput>
        <cfif NOT qChatDepth.recordCount><div class="ca-subtle">Nenhum remetente ativo no período.</div></cfif>
      </div></div></div>
    </div>

    <div class="ca-card mt-4">
      <div class="d-flex flex-column flex-md-row justify-content-between gap-2 align-items-md-end mb-3">
        <div><h2 class="h5 mb-1">Uso por usuário</h2><p class="small ca-subtle mb-0">Usuários que enviaram mensagens no período, ordenados por volume. Nenhum destinatário ou conteúdo é exibido.</p></div>
        <span class="small ca-subtle"><cfoutput>#numberFormat(VARIABLES.chatUsersTotal,'_,___')# usuários</cfoutput></span>
      </div>
      <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
          <thead><tr><th>ID</th><th>Usuário</th><th>Cidade/UF</th><th class="text-end">Chats</th><th class="text-end">Mensagens</th><th class="text-end">Ícones</th></tr></thead>
          <tbody>
            <cfoutput query="qChatUsers">
              <tr>
                <td class="ca-subtle">#numberFormat(id_usuario,'0')#</td>
                <td><cfif len(trim(tag & ''))><a href="https://roadrunners.run/atleta/#urlEncodedFormat(lCase(trim(tag)))#/" target="_blank" rel="noopener" class="fw-semibold">#htmlEditFormat(nome)# <i class="fa-solid fa-arrow-up-right-from-square ms-1 small"></i></a><cfelse><span class="fw-semibold">#htmlEditFormat(nome)#</span><div class="small ca-subtle">Perfil público não localizado</div></cfif></td>
                <td><cfif len(trim(cidade & ''))>#htmlEditFormat(cidade)#<cfif len(trim(uf & ''))>/#htmlEditFormat(uf)#</cfif><cfelseif len(trim(uf & ''))>#htmlEditFormat(uf)#<cfelse><span class="ca-subtle">—</span></cfif></td>
                <td class="text-end">#numberFormat(chats,'_,___')#</td>
                <td class="text-end fw-semibold">#numberFormat(messages,'_,___')#</td>
                <td class="text-end">#numberFormat(icons,'_,___')#</td>
              </tr>
            </cfoutput>
            <cfif NOT qChatUsers.recordCount><tr><td colspan="6" class="text-center ca-subtle py-4">Nenhum usuário enviou mensagens no período.</td></tr></cfif>
          </tbody>
        </table>
      </div>
      <cfif VARIABLES.chatUsersTotalPages GT 1>
        <nav class="d-flex justify-content-between align-items-center border-top pt-3 mt-3" aria-label="Paginação do uso por usuário">
          <cfoutput><a class="btn btn-sm btn-outline-light <cfif VARIABLES.chatUsersPage LTE 1>disabled</cfif>" href="?periodo=#urlEncodedFormat(VARIABLES.chatPeriod)#&pagina=#max(1,VARIABLES.chatUsersPage-1)#">Anterior</a><span class="small ca-subtle">Página #VARIABLES.chatUsersPage# de #VARIABLES.chatUsersTotalPages#</span><a class="btn btn-sm btn-outline-light <cfif VARIABLES.chatUsersPage GTE VARIABLES.chatUsersTotalPages>disabled</cfif>" href="?periodo=#urlEncodedFormat(VARIABLES.chatPeriod)#&pagina=#min(VARIABLES.chatUsersTotalPages,VARIABLES.chatUsersPage+1)#">Próxima</a></cfoutput>
        </nav>
      </cfif>
    </div>

    <p class="small ca-subtle mt-4 mb-0">Atualizado em <cfoutput>#dateFormat(now(),"dd/mm/yyyy")# às #timeFormat(now(),"HH:mm")#</cfoutput>. “Leitura estimada” usa o último marcador de leitura do destinatário; “recíproca” exige envio de ambas as pessoas no período selecionado.</p>
  </cfif>
</section>
