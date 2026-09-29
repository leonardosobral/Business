<cfif NOT structKeyExists(VARIABLES,"requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed><cfheader statuscode="403"/><cfabort/></cfif>
<div class="card shadow-0 mb-4"><div class="card-body"><section class="triage-workspace" aria-labelledby="triage-heading">
  <h2 id="triage-heading" class="h4">Acompanhamento de erros</h2>
  <p class="text-muted">Classifique os problemas, registre a investigação e acompanhe a correção até a verificação.</p>
  <cfif len(etError)><cfoutput><div class="alert alert-danger" role="alert">#etHtml(etError)# Seu texto foi preservado quando aplicável.</div></cfoutput></cfif>
  <cfif NOT etReady>
    <div class="alert alert-info">A instalação do acompanhamento está pendente. A consulta dos logs continua disponível na aba Logs.</div>
  <cfelse>
    <cfset etQueue=etService.list(etFilters)/>
    <cfif etProblemId EQ 0>
    <cfoutput>
    <div class="row g-3 mb-3">
      <div class="col-sm-4"><div class="border rounded p-3"><div class="small text-muted">Problemas registrados</div><strong class="fs-4">#etQueue.stats.total#</strong></div></div>
      <div class="col-sm-4"><div class="border rounded p-3"><div class="small text-muted">Pendentes de verificação</div><strong class="fs-4">#etQueue.stats.pending#</strong></div></div>
      <div class="col-sm-4"><div class="border rounded p-3"><div class="small text-muted">Ocorrências dos problemas exibidos</div><strong class="fs-4">#etQueue.stats.occurrences#</strong></div></div>
    </div>
    <div class="d-flex flex-wrap align-items-center gap-3 mb-3">
      <form method="post" action="./" data-triage-write><input type="hidden" name="csrf" value="#etCsrf#"/><input type="hidden" name="triage_action" value="collect"/><button class="btn btn-warning" type="submit">Processar próximo lote</button></form>
      <div class="small text-muted">Até 200 logs por lote, dos mais recentes para os mais antigos. <strong>#etQueue.pendingLogs# logs aguardando coleta neste recorte.</strong>
      <cfif etQueue.collector.recordCount><br/>Coleta a partir de #etDate(etQueue.collector.started_at)#. Histórico anterior preservado. Horários no fuso #etHtml(etQueue.collector.timezone)#.<cfelse><br/>O primeiro lote começa pelos últimos 7 dias.</cfif></div>
    </div>
    </cfoutput>
    </cfif>
    <cfif structKeyExists(SESSION,"errorTriageReceipt")>
      <cfset etReceipt=duplicate(SESSION.errorTriageReceipt)/><cfset structDelete(SESSION,"errorTriageReceipt")/>
      <cfoutput><div class="alert alert-info" role="status">Lote concluído: #etReceipt.processed# ocorrências, #etReceipt.newProblems# novos problemas e #etReceipt.reopened# reaberturas. <cfif etReceipt.remaining>Há mais logs a processar. Execute o próximo lote.<cfelse>O lote alcançou os logs disponíveis nessa leitura. Novas ocorrências serão coletadas na próxima rodada.</cfif></div></cfoutput>
    </cfif>
    <cfif etProblemId GT 0>
      <cfset etDetail=etService.detail(etProblemId,max(1,int(val(URL.occurrence_page ?: 1))))/>
      <cfif NOT etDetail.problem.recordCount><div class="alert alert-warning">Problema não encontrado.</div><cfelse>
        <cfset etProblem=etDetail.problem/>
        <cfoutput>
        <div class="border rounded p-3 mb-4">
          <div class="d-flex flex-wrap justify-content-between gap-2 mb-3"><h3 class="h5 mb-0">Problema ###etProblem.id# · #etHtml(etProblem.site)#</h3><a href="./" class="btn btn-sm btn-outline-light">Voltar à fila</a></div>
          <p class="small text-muted">#etProblem.occurrences# ocorrências · Primeira: #etDate(etProblem.first_seen)# · Última: #etDate(etProblem.last_seen)# · Versão #etProblem.version#</p>
          <cfif etProblem.occurrences EQ 0><div class="alert alert-secondary">Sem ocorrências vinculadas. O registro permanece disponível para preservar o histórico.</div></cfif>
          <cfset etDetailTab=(structKeyExists(URL,"occurrence_page") OR listFind("move,split",FORM.triage_action ?: "")) ? "ocorrencias" : "tratamento"/>
          <div data-error-tabs data-tab-default="#etDetailTab#">
          <nav class="error-tabs mb-3" role="tablist" aria-label="Detalhes do problema">
            <button type="button" id="tab-tratamento" role="tab" aria-controls="problem-tratamento" data-error-tab="tratamento">Tratamento</button>
            <button type="button" id="tab-ocorrencias" role="tab" aria-controls="problem-ocorrencias" data-error-tab="ocorrencias">Ocorrências (#etProblem.occurrences#)</button>
            <button type="button" id="tab-historico" role="tab" aria-controls="problem-historico" data-error-tab="historico">Histórico</button>
          </nav>
          <div id="problem-tratamento" role="tabpanel" aria-labelledby="tab-tratamento" data-error-panel="tratamento">
          <cfset etPublicationDefault=len(etProblem.published_text & "") ? etProblem.published_text : etQueue.collector.database_now[1]/>
          <cfset etPublicationValue=replace(etField('published_at',etPublicationDefault),' ','T')/>
          <form method="post" action="./?problem_id=#etProblem.id#" data-triage-write data-triage-treatment>
            <p class="small text-muted" data-triage-required-summary>Campos com * são obrigatórios. Publicado exige evidência e horário; verificado exige evidência e publicação já registrada; ignorado/reaberto exige motivo.</p>
            <input type="hidden" name="csrf" value="#etCsrf#"/><input type="hidden" name="triage_action" value="save"/><input type="hidden" name="problem_id" value="#etProblem.id#"/>
            <input type="hidden" name="version" value="#etHtml(etField('version',etProblem.version))#"/>
            <div class="row g-3">
              <div class="col-12"><label class="form-label" for="et-title">Título *</label><input id="et-title" class="form-control" name="title" maxlength="180" required value="#etHtml(etField('title',etProblem.title))#"/></div>
              <div class="col-md-4"><label class="form-label" for="et-status">Status *</label><select id="et-status" class="form-select" name="status" required><cfloop collection="#etStatuses#" item="etKey"><option value="#lCase(etKey)#"<cfif etField('status',etProblem.status) EQ etKey> selected</cfif>>#etStatuses[etKey]#</option></cfloop></select></div>
              <div class="col-md-4"><label class="form-label" for="et-category">Categoria *</label><select id="et-category" class="form-select" name="category" required><cfloop collection="#etCategories#" item="etKey"><option value="#lCase(etKey)#"<cfif etField('category',etProblem.category) EQ etKey> selected</cfif>>#etCategories[etKey]#</option></cfloop></select><div class="small text-muted mt-1">Sugestão inicial: #etHtml(etLabel(etCategories,etProblem.suggested_category))#</div></div>
              <div class="col-md-4"><label class="form-label" for="et-owner">Responsável (opcional)</label><select id="et-owner" class="form-select" name="owner_id"><option value="">Sem responsável</option><cfloop query="etOwners"><option value="#etOwners.id#"<cfif etField('owner_id',etProblem.owner_id) EQ etOwners.id> selected</cfif>>#etHtml(etOwners.name)#</option></cfloop></select></div>
              <div class="col-md-6"><label class="form-label" for="et-analysis">Análise / diagnóstico (opcional)</label><textarea id="et-analysis" class="form-control" name="analysis" maxlength="8000">#etHtml(etField('analysis',etProblem.analysis))#</textarea></div>
              <div class="col-md-6"><label class="form-label" for="et-proposal">Correção proposta (opcional)</label><textarea id="et-proposal" class="form-control" name="proposal" maxlength="8000">#etHtml(etField('proposal',etProblem.proposal))#</textarea></div>
              <div class="col-md-6"><label class="form-label" for="et-evidence">Evidências da publicação / verificação<span data-triage-required="evidence" hidden> *</span></label><textarea id="et-evidence" class="form-control" name="evidence" maxlength="8000">#etHtml(etField('evidence',etProblem.evidence))#</textarea><div class="small text-muted">Descreva o que foi publicado e como foi testado. Obrigatório para publicado ou verificado.</div></div>
              <div class="col-md-6"><label class="form-label" for="et-published">Horário efetivo da publicação<span data-triage-required="published_at" hidden> *</span></label><input id="et-published" type="datetime-local" step="1" class="form-control" name="published_at" value="#etHtml(etPublicationValue)#"/><div class="small text-muted mb-3">Fuso: #etHtml(etQueue.collector.timezone)#. Obrigatório para publicado. Quando ainda não registrado, sugerimos o horário atual; ajuste se a publicação ocorreu antes. Um erro posterior a esse horário reabre o problema quando coletado.</div><label class="form-label" for="et-reason">Motivo da alteração<span data-triage-required="reason" hidden> *</span></label><textarea id="et-reason" class="form-control" name="reason" maxlength="8000">#etHtml(etField('reason',''))#</textarea><div class="small text-muted">Obrigatório para ignorar ou reabrir.</div></div>
              <div class="col-12"><button class="btn btn-warning" type="submit">Salvar acompanhamento</button><span class="small text-muted ms-2">Salvar um status registra o acompanhamento; não executa a correção.</span></div>
            </div>
          </form>
          </div>
          <div id="problem-historico" role="tabpanel" aria-labelledby="tab-historico" data-error-panel="historico">
            <h4 class="h6">Histórico de alterações (até 100 mais recentes)</h4>
            <cfif NOT etDetail.history.recordCount><p class="text-muted">Nenhuma alteração registrada.</p></cfif>
            <cfloop query="etDetail.history"><cfset etHistory=etDetail.history/>
              <div class="border-bottom py-2"><strong>#etDate(etHistory.created_at)#</strong> · Administrador ###etHistory.actor_id# · #etHtml(etLabel(etStatuses,etHistory.from_status))# → #etHtml(etLabel(etStatuses,etHistory.to_status))#
              <cfif isJSON(etHistory.note)><cfset etNote=deserializeJSON(etHistory.note)/><cfset etNoteLabels={reason="Motivo",title="Título",category="Categoria",owner="Responsável (ID)",analysis="Análise",proposal="Proposta",evidence="Evidências",published_at="Publicação"}/><cfloop collection="#etNoteLabels#" item="etKey"><cfif structKeyExists(etNote,etKey) AND len(etNote[etKey])><div class="small triage-text"><strong>#etNoteLabels[etKey]#:</strong> #etHtml(etNote[etKey])#</div></cfif></cfloop><cfelse><div class="small triage-text">#etHtml(etHistory.note)#</div></cfif>
              </div>
            </cfloop>
          </div>
          <div id="problem-ocorrencias" role="tabpanel" aria-labelledby="tab-ocorrencias" data-error-panel="ocorrencias">
          <h4 class="h6">Ocorrências vinculadas</h4>
          <div class="table-responsive"><table class="table table-sm triage-table"><thead><tr><th>Log</th><th>Horário</th><th>Local / mensagem</th><th>Agrupamento</th></tr></thead><tbody>
          <cfloop query="etDetail.occurrences"><cfset etOccurrence=etDetail.occurrences/>
            <tr><td><a href="./?aba=logs&amp;problem_id=#etProblem.id#&amp;log_id=#etOccurrence.id_log#">###etOccurrence.id_log#</a></td><td>#etDate(etOccurrence.occurred_at)#</td><td class="triage-title">#etHtml(etOccurrence.path)#<div class="small text-muted">#etHtml(etOccurrence.technical_message)#</div><cfif etOccurrence.original_available><details class="mt-2"><summary>Log original</summary><pre class="small triage-text">#etHtml(etOccurrence.original_log)#</pre></details><cfelse><div class="small text-muted">Log original indisponível; exibindo o resumo armazenado.</div></cfif></td><td><cfif etOccurrence.confidence EQ "individual">Individual · revisar<cfelseif etOccurrence.confidence EQ "path">Caminho 404<cfelse>Identidade técnica</cfif></td></tr>
          </cfloop>
          </tbody></table></div>
          <div class="d-flex gap-2"><cfif val(URL.occurrence_page ?: 1) GT 1><a class="btn btn-sm btn-outline-light" href="./?problem_id=#etProblem.id#&amp;occurrence_page=#max(1,int(val(URL.occurrence_page))-1)#">Ocorrências anteriores</a></cfif><cfif max(1,int(val(URL.occurrence_page ?: 1)))*25 LT etProblem.occurrences><a class="btn btn-sm btn-outline-light" href="./?problem_id=#etProblem.id#&amp;occurrence_page=#max(1,int(val(URL.occurrence_page ?: 1)))+1#">Próximas ocorrências</a></cfif></div>
          <details class="mt-3"><summary>Corrigir o agrupamento de uma ocorrência</summary>
            <form method="post" action="./?problem_id=#etProblem.id#" class="row g-2 mt-2" data-triage-write>
              <input type="hidden" name="csrf" value="#etCsrf#"/><input type="hidden" name="problem_id" value="#etProblem.id#"/><input type="hidden" name="version" value="#etProblem.version#"/>
              <div class="col-md-3"><label class="form-label">ID do log</label><input class="form-control" type="number" name="log_id" min="1" required/></div>
              <div class="col-md-3"><label class="form-label">Problema de destino</label><input class="form-control" type="number" name="target_id" min="1"/></div>
              <div class="col-md-3"><label class="form-label">Versão do destino</label><input class="form-control" type="number" name="target_version" min="1"/></div>
              <div class="col-12"><label class="form-label">Justificativa</label><input class="form-control" name="reason" maxlength="8000" required/></div>
              <div class="col-12 d-flex flex-wrap gap-2"><button class="btn btn-sm btn-outline-warning" name="triage_action" value="move">Vincular ao destino</button><button class="btn btn-sm btn-outline-light" name="triage_action" value="split">Separar em novo problema</button></div>
              <div class="small text-muted">Para vincular, consulte o ID e a versão no detalhe do destino. Para separar, basta informar o log e a justificativa.</div>
            </form>
          </details>
          </div>
          </div>
        </div>
        </cfoutput>
      </cfif>
    </cfif>
    <cfif etProblemId EQ 0>
    <cfoutput>
    <form method="get" action="./" class="row g-2 mb-3">
      <div class="col-12"><label class="form-label" for="et-filter-scope">Período do acompanhamento</label><select id="et-filter-scope" name="scope" class="form-select"><option value="recent"<cfif etFilters.scope EQ "recent"> selected</cfif>>Recorte atual da coleta</option><option value="all"<cfif etFilters.scope EQ "all"> selected</cfif>>Todo o histórico já processado</option></select><div class="small text-muted">O recorte atual mostra problemas com ocorrências após a data de início da coleta. Contagens por problema preservam seu histórico.</div></div>
      <div class="col-md-3"><label class="form-label" for="et-filter-status">Status</label><select id="et-filter-status" name="status" class="form-select"><option value="">Todos</option><cfloop collection="#etStatuses#" item="etKey"><option value="#lCase(etKey)#"<cfif etFilters.status EQ etKey> selected</cfif>>#etStatuses[etKey]#</option></cfloop></select></div>
      <div class="col-md-4"><label class="form-label" for="et-filter-category">Categoria</label><select id="et-filter-category" name="category" class="form-select"><option value="">Todas</option><cfloop collection="#etCategories#" item="etKey"><option value="#lCase(etKey)#"<cfif etFilters.category EQ etKey> selected</cfif>>#etCategories[etKey]#</option></cfloop></select></div>
      <div class="col-md-3"><label class="form-label" for="et-filter-site">Site</label><input id="et-filter-site" name="triage_site" class="form-control" maxlength="32" value="#etHtml(etFilters.site)#" placeholder="RR, OR, CT..."/></div>
      <div class="col-md-2 d-flex align-items-end"><button class="btn btn-outline-warning w-100" type="submit">Filtrar fila</button></div>
    </form>
    <form method="post" action="export.cfm" id="triage-export" data-triage-export>
      <input type="hidden" name="csrf" value="#etCsrf#"/>
      <div class="table-responsive"><table class="table table-hover triage-table"><thead><tr><th><span class="visually-hidden">Selecionar</span></th><th>Problema</th><th>Categoria</th><th>Status</th><th>Ocorrências</th><th>Última</th></tr></thead><tbody>
      <cfloop query="etQueue.items"><cfset etItem=etQueue.items/>
        <tr><td><input class="form-check-input" type="checkbox" name="ids" value="#etItem.id#" aria-label="Selecionar problema #etItem.id#"/></td><td class="triage-title"><a href="./?problem_id=#etItem.id#">###etItem.id# · #etHtml(etItem.title)#</a><div class="small text-muted">#etHtml(etItem.site)#</div></td><td>#etHtml(etLabel(etCategories,etItem.category))#</td><td><span class="triage-status">#etHtml(etLabel(etStatuses,etItem.status))#</span></td><td>#etItem.occurrences#</td><td>#etDate(etItem.last_seen)#</td></tr>
      </cfloop>
      <cfif NOT etQueue.items.recordCount><tr><td colspan="6">Nenhum problema neste filtro. Processe um lote para trazer os logs à fila.</td></tr></cfif>
      </tbody></table></div>
      <div class="d-flex flex-wrap align-items-center gap-3"><button class="btn btn-outline-light" type="submit">Exportar selecionados para o Codex</button><span class="small text-muted">Até 20 problemas. Inclui títulos, anotações e até 25 amostras por problema com o log original disponível.</span></div>
      <div data-triage-feedback class="text-warning mt-2" role="alert"></div>
    </form>
    <cfset etFilterQuery="scope=" & urlEncodedFormat(etFilters.scope) & "&status=" & urlEncodedFormat(etFilters.status) & "&category=" & urlEncodedFormat(etFilters.category) & "&triage_site=" & urlEncodedFormat(etFilters.site)/>
    <div class="d-flex flex-wrap align-items-center gap-3 mt-3"><span class="small text-muted">#etQueue.total# problemas · Página #etQueue.page# de #max(1,ceiling(etQueue.total/25))#</span><cfif etQueue.page GT 1><a class="btn btn-sm btn-outline-light" href="./?#etHtml(etFilterQuery)#&amp;page=#etQueue.page-1#">Anterior</a></cfif><cfif etQueue.page*25 LT etQueue.total><a class="btn btn-sm btn-outline-light" href="./?#etHtml(etFilterQuery)#&amp;page=#etQueue.page+1#">Próxima</a></cfif></div>
    </cfoutput>
    </cfif>
  </cfif>
</section></div></div>

