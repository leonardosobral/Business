(() => {
  'use strict';
  const root = document.getElementById('aiMails');
  if (!root) return;
  const $ = id => document.getElementById(id);
  const filters = $('mailFilters');
  const priorities = {critical: 'Crítica', high: 'Alta', normal: 'Normal', informational: 'Para ciência', low: 'Baixa relevância'};
  const categories = {operacao: 'Operação', financeiro: 'Financeiro', comercial: 'Comercial', suporte: 'Suporte', seguranca: 'Segurança', juridico: 'Jurídico', outros: 'Outros'};
  const states = {pending: 'Pendente', in_progress: 'Em andamento', resolved: 'Resolvido'};
  const batchStates = {open: 'Aberto', in_progress: 'Em tratamento', resolved: 'Resolvido'};
  const relationships = {primary: 'Sinal principal', duplicate: 'Duplicidade', consequence: 'Consequência', context: 'Contexto', unrelated: 'Não relacionada'};
  const operations = {
    resolve: 'Marcou como resolvido', reopen: 'Reabriu', assign: 'Alterou responsável', note: 'Atualizou observação', classify: 'Corrigiu classificação',
    reanalyze: 'Solicitou nova análise', analyzed: 'Análise atualizada', reopened_new_request: 'Reaberto por novo pedido', batch_grouped: 'Incluiu em um lote',
    created: 'Criou e analisou o lote', batch_assign: 'Alterou o responsável do lote', batch_classify: 'Alterou a prioridade do lote',
    batch_note: 'Atualizou a observação do lote', batch_start: 'Iniciou o tratamento do lote', batch_resolve: 'Resolveu o lote', batch_reopen: 'Reabriu o lote'
  };
  let status = null, view = 'pending', offset = 0, current = null, currentBatch = null, currentItems = [], generation = 0, busy = false;
  const selected = new Map();
  const date = value => value ? new Intl.DateTimeFormat('pt-BR', {dateStyle: 'short', timeStyle: 'short', timeZone: 'America/Sao_Paulo'}).format(new Date(value)) : '—';
  const dateMillis = value => Number(value) > 0 ? date(Number(value)) : 'agora';
  function el(tag, text, cls) { const n = document.createElement(tag); if (text != null) n.textContent = text; if (cls) n.className = cls; return n; }
  function button(text, handler, cls = 'btn btn-outline-light') { const b = el('button', text, cls); b.type = 'button'; b.addEventListener('click', () => run(handler, b)); return b; }
  function notify(text) { $('mailMessage').textContent = text; $('mailMessage').hidden = !text; }
  async function run(fn, target) { if (target) target.disabled = true; try { await fn(); } catch (e) { notify(e.message); } finally { if (target) target.disabled = false; } }
  async function api(action, values = {}) {
    const response = await fetch('/administracao/ai-mails/api.cfm', {method: 'POST', credentials: 'same-origin', cache: 'no-store', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: new URLSearchParams({action, csrf_token: root.dataset.csrf, ...values})});
    let data; try { data = await response.json(); } catch { throw new Error('A sessão pode ter expirado. Recarregue a página para continuar.'); }
    if (!response.ok || !data.success) throw new Error(data.message || 'Não foi possível consultar o AI-mails.');
    return data;
  }
  function gmail(thread, message) {
    const id = message || thread.thread_id;
    if (!/^[a-zA-Z0-9_-]{1,100}$/.test(id)) return '';
    return 'https://mail.google.com/mail/u/?authuser=contato%40runnerhub.run#all/' + encodeURIComponent(id);
  }
  function link(text, url, cls = 'btn btn-outline-light') { const a = el('a', text, cls); a.href = url; a.target = '_blank'; a.rel = 'noopener noreferrer'; return a; }
  function badges(item) {
    const n = el('div', null, 'mail-badges');
    n.append(el('span', priorities[item.priority] || 'Em análise', 'mail-badge mail-badge-' + item.priority));
    if (item.needs_response) n.append(el('span', 'Requer resposta', 'mail-badge'));
    if (item.needs_review) n.append(el('span', 'Revisão necessária', 'mail-badge mail-badge-review'));
    if (item.queued) n.append(el('span', 'Atualização em fila', 'mail-badge'));
    if (Number(item.open_batch_count) > 0) n.append(el('span', Number(item.open_batch_count) + (Number(item.open_batch_count) === 1 ? ' lote aberto' : ' lotes abertos'), 'mail-badge mail-badge-review'));
    n.append(el('span', states[item.state] || item.state, 'mail-badge'));
    return n;
  }
  function batchBadges(item) {
    const n = el('div', null, 'mail-badges');
    n.append(el('span', priorities[item.priority] || item.priority, 'mail-badge mail-badge-' + item.priority));
    n.append(el('span', batchStates[item.state] || item.state, 'mail-badge'));
    n.append(el('span', Number(item.member_count) + (Number(item.member_count) === 1 ? ' conversa' : ' conversas'), 'mail-badge'));
    if (item.needs_review) n.append(el('span', 'Revisão necessária', 'mail-badge mail-badge-review'));
    return n;
  }
  function activateView(next) {
    view = next; offset = 0;
    root.querySelectorAll('[data-view]').forEach(v => v.setAttribute('aria-pressed', String(v.dataset.view === view)));
    filters.hidden = view === 'batches';
    $('mailBatchBar').hidden = view === 'batches';
  }
  function syncBatchBar() {
    if (view === 'batches') { $('mailBatchBar').hidden = true; return; }
    $('mailBatchBar').hidden = false;
    const count = selected.size;
    $('mailSelectedCount').textContent = count ? count + (count === 1 ? ' conversa selecionada' : ' conversas selecionadas') + ' · mínimo 2, máximo 50' : 'Selecione mensagens relacionadas para criar uma análise consolidada';
    $('mailAnalyzeBatch').disabled = count < 2;
    $('mailClearSelection').disabled = count === 0;
    const eligible = currentItems.filter(item => item.analyzed_at && item.source_available && !item.content_expired);
    const marked = eligible.filter(item => selected.has(Number(item.id))).length;
    $('mailSelectPage').checked = eligible.length > 0 && marked === eligible.length;
    $('mailSelectPage').indeterminate = marked > 0 && marked < eligible.length;
    $('mailSelectPage').disabled = !eligible.length;
  }
  function setSelected(item, checked, checkbox, card) {
    const id = Number(item.id);
    if (checked && !selected.has(id) && selected.size >= 50) {
      checkbox.checked = false; notify('Cada lote pode reunir no máximo 50 conversas.'); return;
    }
    if (checked) selected.set(id, {id, subject: item.subject || 'Sem assunto'}); else selected.delete(id);
    card.classList.toggle('mail-card-selected', checked);
    syncBatchBar();
  }
  async function loadStatus() {
    status = await api('status');
    const c = status.config;
    $('mailStatus').textContent = !status.connected ? 'Gmail: autorização pendente' : !c.enabled ? 'Gmail autorizado · monitor pausado' : 'Monitor ativo · novas mensagens desde ' + dateMillis(c.monitor_since_ms) + (c.last_sync_at ? ' · Gmail sincronizado em ' + date(c.last_sync_at) : '');
    $('mailSetup').hidden = status.connected && c.enabled;
    $('mailConnect').hidden = status.connected;
    $('mailSetupText').textContent = !status.connected ? 'Autorize a leitura do Gmail nesta integração para começar. Agenda, Meet e Documentos continuam disponíveis.' : 'Gmail autorizado. Abra Configurações, confirme o processamento pela IA e ative o monitor. Somente novas mensagens serão analisadas.';
    for (const [key, id] of Object.entries({pending: 'metricPending', urgent: 'metricUrgent', response: 'metricResponse', overdue: 'metricOverdue'})) $(id).textContent = status.metrics[key];
    $('mailBatchOpenCount').textContent = status.batches?.open || 0;
    const progress = [status.queue.total + ' conversa(s) na fila de análise', status.queue.errors + ' com falha ou aguardando nova tentativa'];
    if (Number(c.monitor_since_ms) > 0) progress.push('Corte de entrada: ' + dateMillis(c.monitor_since_ms));
    if (status.usage.limited) progress.push('Limite diário atingido; fila preservada');
    if (!status.ai_configured) progress.push('OpenAI não configurada');
    if (c.last_error) progress.push(c.last_error);
    if (status.jobs.length !== 2 || status.jobs.some(j => !j.active)) progress.push('Atenção: agendamento incompleto ou desativado');
    $('mailProgress').textContent = progress.join(' · ');
    const currentAssignee = filters.elements.assignee.value;
    $('mailAssignee').replaceChildren(new Option('Todos', ''), new Option('Não atribuído', 'none'));
    status.actors.forEach(a => $('mailAssignee').add(new Option(a.name, String(a.id))));
    filters.elements.assignee.value = currentAssignee;
  }
  function renderThreadCard(item) {
    const card = el('article', null, 'mail-card'); card.dataset.priority = item.priority;
    const selectWrap = el('label', null, 'mail-card-select');
    const checkbox = el('input'); checkbox.type = 'checkbox'; checkbox.setAttribute('aria-label', 'Selecionar ' + (item.subject || 'conversa'));
    const eligible = item.analyzed_at && item.source_available && !item.content_expired;
    checkbox.disabled = !eligible; checkbox.checked = selected.has(Number(item.id));
    if (!eligible) checkbox.title = 'A conversa precisa estar analisada e com origem disponível para entrar em um lote.';
    selectWrap.append(checkbox); card.classList.toggle('mail-card-selected', checkbox.checked);
    checkbox.addEventListener('change', () => setSelected(item, checkbox.checked, checkbox, card));
    const main = el('div', null, 'mail-card-main');
    main.append(badges(item), button(item.subject || 'Sem assunto', () => openDetail(item.id), 'mail-card-title'), el('p', item.sender || 'Origem indisponível', 'mail-sender'), el('p', item.summary || (item.source_available ? 'Aguardando análise. Esta conversa ainda não foi classificada.' : 'A origem foi removida, enviada à lixeira ou marcada como spam. O conteúdo local foi expurgado.')));
    if (item.actions?.length) main.append(el('p', 'Próximo passo: ' + item.actions[0].text));
    const meta = el('div', null, 'mail-card-meta');
    meta.append(el('span', categories[item.category] || 'Outros'), el('span', item.assignee_name || 'Não atribuído'), el('span', item.deadline_at ? 'Prazo: ' + date(item.deadline_at) : item.deadline_text || 'Sem prazo informado'));
    if (!item.in_inbox && item.source_available) meta.append(el('span', 'Fora da caixa de entrada'));
    main.append(meta);
    const side = el('div', null, 'mail-card-side'); side.append(el('time', date(item.last_message_at)));
    const actions = el('div', null, 'mail-actions'); actions.append(button('Ver análise', () => openDetail(item.id)));
    if (item.source_available) actions.append(link('Gmail ↗', gmail(item)));
    side.append(actions); card.append(selectWrap, main, side); return card;
  }
  function renderBatchCard(item) {
    const card = el('article', null, 'mail-card mail-batch-card'); card.dataset.priority = item.priority;
    const main = el('div', null, 'mail-card-main');
    main.append(batchBadges(item), button(item.title || 'Lote sem título', () => openBatch(item.id), 'mail-card-title'), el('p', item.summary || 'Análise consolidada indisponível.'));
    if (item.pattern) main.append(el('p', 'Padrão identificado: ' + item.pattern));
    const meta = el('div', null, 'mail-card-meta');
    meta.append(el('span', categories[item.category] || 'Outros'), el('span', item.assignee_name || 'Não atribuído'), el('span', Number(item.open_threads) + ' conversa(s) ainda aberta(s)'));
    main.append(meta);
    const side = el('div', null, 'mail-card-side'); side.append(el('time', 'Atualizado em ' + date(item.updated_at)), button('Abrir lote', () => openBatch(item.id), 'btn btn-warning'));
    card.append(main, side); return card;
  }
  async function loadThreads(gen) {
    const data = await api('list', {view, offset, ...Object.fromEntries(new FormData(filters))});
    if (gen !== generation) return;
    currentItems = data.items;
    $('mailItems').replaceChildren(...data.items.map(renderThreadCard));
    if (!data.items.length) {
      const empty = el('div', null, 'mail-empty');
      const ready = status?.connected && status?.config.enabled && status?.config.initial_complete && !status?.queue.total && !status?.config.last_error;
      empty.append(el('h3', ready ? 'Nenhuma conversa nesta visão' : 'Ainda não há resumos nesta visão'), el('p', ready ? 'Ajuste os filtros ou consulte a Revisão da triagem.' : 'Confira a conexão, a ativação e o andamento da fila acima. Ausência de resumos não significa ausência de pendências.'));
      $('mailItems').append(empty);
    }
    $('mailCount').textContent = data.total + ' conversa(s)' + (view === 'review' ? ' · baixa relevância, incertezas e fontes indisponíveis' : '');
    $('mailPage').textContent = 'Página ' + (Math.floor(offset / 30) + 1) + ' de ' + Math.max(1, Math.ceil(data.total / 30));
    $('mailPrev').disabled = offset === 0; $('mailNext').disabled = offset + 30 >= data.total;
    syncBatchBar();
  }
  async function loadBatches(gen) {
    const data = await api('batches', {offset});
    if (gen !== generation) return;
    currentItems = [];
    $('mailItems').replaceChildren(...data.items.map(renderBatchCard));
    if (!data.items.length) {
      const empty = el('div', null, 'mail-empty');
      empty.append(el('h3', 'Nenhum lote criado'), el('p', 'Volte às conversas, selecione mensagens relacionadas e use “Analisar como lote”.'));
      $('mailItems').append(empty);
    }
    $('mailCount').textContent = data.total + (data.total === 1 ? ' lote analisado' : ' lotes analisados');
    $('mailPage').textContent = 'Página ' + (Math.floor(offset / 30) + 1) + ' de ' + Math.max(1, Math.ceil(data.total / 30));
    $('mailPrev').disabled = offset === 0; $('mailNext').disabled = offset + 30 >= data.total;
  }
  async function loadList() {
    const gen = ++generation;
    filters.hidden = view === 'batches'; $('mailBatchBar').hidden = view === 'batches';
    $('mailItems').setAttribute('aria-busy', 'true');
    try { if (view === 'batches') await loadBatches(gen); else await loadThreads(gen); }
    finally { if (gen === generation) $('mailItems').setAttribute('aria-busy', 'false'); }
  }
  async function refresh() { if (busy) return; busy = true; try { await loadStatus(); await loadList(); } finally { busy = false; } }
  async function mutate(action, extra = {}) {
    const id = current.id;
    const data = await api(action, {id, version: current.version, ...extra});
    notify(data.message); await openDetail(id); await refresh();
  }
  async function openDetail(id) {
    const data = await api('detail', {id}); current = data.item; const item = current;
    const body = $('mailDetailBody'); body.replaceChildren();
    const title = el('h2', item.subject || 'Sem assunto'); title.id = 'mailDetailTitle';
    body.append(badges(item), title, el('p', item.sender, 'mail-muted'), el('p', 'Última mensagem: ' + date(item.last_message_at) + ' · ' + (item.in_inbox ? 'Na caixa de entrada' : 'Fora da caixa de entrada'), 'mail-muted'));
    const source = el('div', null, 'mail-actions');
    if (item.source_available) {
      source.append(link('Abrir conversa no Gmail ↗', gmail(item)));
      if (item.source_message_id) source.append(link('Mensagem de origem ↗', gmail(item, item.source_message_id)));
      if (item.rfc_message_id) source.append(link('Localizar pelo Message-ID ↗', 'https://mail.google.com/mail/u/?authuser=contato%40runnerhub.run#search/' + encodeURIComponent('rfc822msgid:' + item.rfc_message_id.replace(/[<>]/g, ''))));
    }
    body.append(source, el('h3', 'O que está acontecendo'), el('p', item.summary || 'Análise pendente ou origem indisponível.'), el('h3', 'Por que merece atenção'), el('p', item.reason || 'Ainda não classificado.'));
    if (item.actions?.length) { const list = el('ol'); item.actions.forEach(a => { const li = el('li', a.text + ' '); li.append(link('Origem ↗', gmail(item, a.source_message_id))); list.append(li); }); body.append(el('h3', 'Ações sugeridas — não executadas'), list); }
    body.append(el('h3', 'Prazo informado'), el('p', item.deadline_at ? date(item.deadline_at) + (item.deadline_text ? ' · “' + item.deadline_text + '”' : '') : item.deadline_text || 'Sem prazo informado.'));
    (item.warnings || []).forEach(w => body.append(el('p', w, 'mail-notice')));
    if (item.sources?.length) body.append(el('p', 'Referências institucionais: ' + item.sources.join(' · '), 'mail-muted'));
    const controls = el('div', null, 'mail-actions');
    controls.append(button(item.state === 'resolved' ? 'Reabrir conversa' : 'Marcar como resolvido', () => mutate(item.state === 'resolved' ? 'reopen' : 'resolve'), 'btn btn-warning'));
    if (item.state !== 'resolved') controls.append(button('Assumir', () => mutate('assign')));
    if (item.source_available) controls.append(button('Reanalisar', () => mutate('reanalyze')));
    body.append(el('h3', 'Atendimento compartilhado'), controls);
    const assigneeLabel = el('label', 'Responsável'); const assignee = el('select', null, 'form-select'); assignee.add(new Option('Não atribuído', '0'));
    (status?.actors || []).forEach(a => assignee.add(new Option(a.name, String(a.id)))); assignee.value = String(item.assignee_id || 0); assigneeLabel.append(assignee);
    body.append(assigneeLabel, button('Salvar responsável', () => mutate('assign', {assignee_id: assignee.value})));
    const noteLabel = el('label', 'Observação interna'); const note = el('textarea', null, 'form-control'); note.maxLength = 4000; note.value = item.note || ''; noteLabel.append(note);
    body.append(noteLabel, button('Salvar observação', () => mutate('note', {note: note.value})));
    const priorityLabel = el('label', 'Corrigir prioridade / relevância'); const priority = el('select', null, 'form-select'); Object.entries(priorities).forEach(([v, l]) => priority.add(new Option(l, v))); priority.value = item.priority; priorityLabel.append(priority);
    body.append(priorityLabel, button('Aplicar classificação manual', () => mutate('classify', {priority: priority.value})), el('p', 'A classificação manual é preservada nas próximas análises. Baixa relevância move para Revisão da triagem.', 'mail-muted'));
    body.append(el('h3', 'Histórico')); const history = el('ul', null, 'mail-history'); data.history.forEach(h => history.append(el('li', date(h.created_at) + ' · ' + (h.actor_name || 'Monitor IA') + ' · ' + (operations[h.action] || h.action)))); body.append(history);
    body.append(el('p', 'Análise: ' + date(item.analyzed_at) + ' · ' + (item.analysis_model || 'pendente') + '. Brasília (UTC−3).', 'mail-muted'));
    if (!$('mailDetail').open) $('mailDetail').showModal();
  }
  function openBatchCreate() {
    if (selected.size < 2) { notify('Selecione pelo menos duas conversas analisadas.'); return; }
    const form = $('mailBatchCreateForm'); form.reset();
    $('mailBatchCreateCount').textContent = selected.size + ' conversas serão comparadas e vinculadas ao novo lote.';
    $('mailBatchCreateStatus').textContent = '';
    $('mailBatchCreate').showModal();
  }
  async function batchMutate(action, extra = {}) {
    const id = currentBatch.id;
    const data = await api(action, {id, version: currentBatch.version, ...extra});
    notify(data.message); await openBatch(id); await refresh();
  }
  async function openBatch(id) {
    const data = await api('batch_detail', {id}); currentBatch = data.batch; const batch = currentBatch;
    const body = $('mailBatchDetailBody'); body.replaceChildren();
    const title = el('h2', batch.title || 'Lote sem título'); title.id = 'mailBatchDetailTitle';
    body.append(batchBadges(batch), title, el('p', 'Criado por ' + (batch.created_by_name || 'Admin global') + ' em ' + date(batch.created_at) + ' · análise ' + (batch.analysis_model || 'indisponível'), 'mail-muted'));
    const summary = el('div', null, 'mail-batch-summary');
    for (const [heading, value] of [['Resumo executivo', batch.summary], ['Padrão ou causa provável', batch.pattern], ['Impacto conjunto', batch.impact]]) {
      const section = el('section'); section.append(el('h3', heading), el('p', value || 'Não identificado.')); summary.append(section);
    }
    if (batch.instruction) { const section = el('section'); section.append(el('h3', 'Foco solicitado pelo atendente'), el('p', batch.instruction)); summary.append(section); }
    body.append(summary);
    if (batch.actions?.length) {
      body.append(el('h3', 'Plano sugerido — não executado'));
      const list = el('ol');
      batch.actions.forEach(action => {
        const li = el('li', action.text + ' '); const evidence = el('span', null, 'mail-actions');
        (action.evidence_thread_ids || []).forEach(threadId => evidence.append(button('Conversa #' + threadId, async () => { $('mailBatchDetail').close(); await openDetail(threadId); }, 'btn btn-sm btn-outline-light')));
        li.append(evidence); list.append(li);
      }); body.append(list);
    }
    body.append(el('h3', 'Conversas agrupadas'));
    const members = el('div', null, 'mail-batch-members');
    data.items.forEach(item => {
      const member = el('article', null, 'mail-batch-member');
      const copy = el('div'); copy.append(el('span', relationships[item.relationship] || item.relationship, 'mail-relationship'), el('strong', item.subject || 'Sem assunto'), el('p', item.finding || item.summary || 'Sem observação específica.'), el('span', (states[item.state] || item.state) + ' · ' + (priorities[item.priority] || item.priority), 'mail-muted'));
      const actions = el('div', null, 'mail-actions');
      actions.append(button('Ver análise', async () => { $('mailBatchDetail').close(); await openDetail(item.id); }, 'btn btn-sm btn-outline-light'));
      actions.append(link('Gmail ↗', gmail(item), 'btn btn-sm btn-outline-light'));
      member.append(copy, actions); members.append(member);
    });
    body.append(members, el('h3', 'Tratar todo o lote'));
    const stateActions = el('div', null, 'mail-actions');
    if (batch.state === 'resolved') stateActions.append(button('Reabrir lote e conversas', () => batchMutate('batch_reopen'), 'btn btn-warning'));
    else {
      if (batch.state === 'open') stateActions.append(button('Iniciar tratamento', () => batchMutate('batch_start')));
      stateActions.append(button('Resolver lote e conversas', () => batchMutate('batch_resolve'), 'btn btn-warning'));
    }
    body.append(stateActions, el('p', 'As ações de status, responsável e prioridade são aplicadas às ' + batch.member_count + ' conversas do lote. O Gmail não é alterado.', 'mail-muted'));
    const controls = el('div', null, 'mail-batch-controls');
    const responsibleBox = el('div'); const assigneeLabel = el('label', 'Responsável do lote'); const assignee = el('select', null, 'form-select'); assignee.add(new Option('Não atribuído', '0'));
    (status?.actors || []).forEach(a => assignee.add(new Option(a.name, String(a.id)))); assignee.value = String(batch.assignee_id || 0); assigneeLabel.append(assignee);
    responsibleBox.append(assigneeLabel, button('Aplicar a todas', () => batchMutate('batch_assign', {assignee_id: assignee.value})));
    const priorityBox = el('div'); const priorityLabel = el('label', 'Prioridade do lote'); const priority = el('select', null, 'form-select'); Object.entries(priorities).forEach(([v, l]) => priority.add(new Option(l, v))); priority.value = batch.priority; priorityLabel.append(priority);
    priorityBox.append(priorityLabel, button('Aplicar a todas', () => batchMutate('batch_classify', {priority: priority.value})));
    controls.append(responsibleBox, priorityBox); body.append(controls);
    const noteLabel = el('label', 'Observação do lote'); const note = el('textarea', null, 'form-control'); note.maxLength = 5000; note.value = batch.note || ''; noteLabel.append(note);
    body.append(noteLabel, button('Salvar observação do lote', () => batchMutate('batch_note', {note: note.value})), el('p', 'A observação fica no lote e não sobrescreve as anotações individuais.', 'mail-muted'));
    body.append(el('h3', 'Histórico do lote')); const history = el('ul', null, 'mail-history'); data.audit.forEach(h => history.append(el('li', date(h.created_at) + ' · ' + (h.actor_name || 'Monitor IA') + ' · ' + (operations[h.action] || h.action)))); body.append(history);
    if (!$('mailBatchDetail').open) $('mailBatchDetail').showModal();
  }
  async function showSettings() {
    await loadStatus(); const form = $('mailConfigForm');
    for (const key of ['model', 'daily_limit', 'retention_days']) form.elements[key].value = status.config[key];
    form.elements.enabled.checked = status.config.enabled; form.elements.consent.checked = status.config.enabled;
    $('mailUsage').textContent = 'Cota automática atual: ' + status.usage.thread_total + '/' + status.config.daily_limit + ' · ' + status.usage.thread_today + ' tentativa(s) automática(s) registrada(s) hoje · ' + status.usage.batch_total + '/' + status.usage.batch_limit + ' análises em lote · ' + status.usage.input_tokens + ' tokens de entrada · ' + status.usage.output_tokens + ' de saída. Tentativas com falha também contam no respectivo limite.';
    if (Number.isFinite(status.usage.estimated_usd)) $('mailUsage').textContent += ' Estimativa de texto: US$ ' + status.usage.estimated_usd.toFixed(4) + (status.usage.estimate_incomplete ? ' (parcial).' : '.') + ' Referência 17/09/2026, sem descontos de cache e sem custos da base RAG; não substitui a fatura OpenAI.';
    $('mailConfigError').textContent = ''; $('mailConfig').showModal();
  }
  async function connect() { const data = await api('connect'); const u = new URL(data.url); if (u.origin !== 'https://accounts.google.com') throw new Error('Endereço de autorização inválido.'); window.location.assign(u.href); }
  $('mailConnect').addEventListener('click', e => run(connect, e.currentTarget));
  $('mailReconnect').addEventListener('click', e => run(connect, e.currentTarget));
  $('mailSettings').addEventListener('click', e => run(showSettings, e.currentTarget));
  $('mailRefresh').addEventListener('click', e => run(async () => { const d = await api('refresh'); notify(d.message); await refresh(); }, e.currentTarget));
  $('mailAnalyzeBatch').addEventListener('click', openBatchCreate);
  $('mailClearSelection').addEventListener('click', () => { selected.clear(); loadList(); });
  $('mailSelectPage').addEventListener('change', e => {
    const eligible = currentItems.filter(item => item.analyzed_at && item.source_available && !item.content_expired);
    if (e.currentTarget.checked) {
      for (const item of eligible) { if (selected.size >= 50) break; selected.set(Number(item.id), {id: Number(item.id), subject: item.subject || 'Sem assunto'}); }
      if (eligible.length && selected.size >= 50 && eligible.some(item => !selected.has(Number(item.id)))) notify('O limite de 50 conversas foi atingido.');
    } else eligible.forEach(item => selected.delete(Number(item.id)));
    loadList();
  });
  $('mailBatchCreateForm').addEventListener('submit', e => { e.preventDefault(); run(async () => {
    $('mailBatchCreateStatus').textContent = 'Comparando as conversas e preparando o plano consolidado. Isso pode levar alguns segundos…';
    const values = Object.fromEntries(new FormData(e.currentTarget));
    try {
      const data = await api('batch_create', {...values, thread_ids: [...selected.keys()].join(',')});
      $('mailBatchCreate').close(); selected.clear(); activateView('batches'); notify(data.message); await loadStatus(); await loadList(); await openBatch(data.batch_id);
    } catch (error) { $('mailBatchCreateStatus').textContent = error.message; }
  }, e.submitter); });
  $('mailConfigForm').addEventListener('submit', e => { e.preventDefault(); run(async () => {
    const f = e.currentTarget;
    try { const d = await api('settings', {...Object.fromEntries(new FormData(f)), enabled: String(f.elements.enabled.checked), consent: String(f.elements.consent.checked)}); $('mailConfig').close(); notify(d.message); await refresh(); }
    catch (error) { $('mailConfigError').textContent = error.message; }
  }, e.submitter); });
  root.querySelectorAll('[data-close]').forEach(b => b.addEventListener('click', () => b.closest('dialog').close()));
  root.querySelectorAll('[data-view]').forEach(b => b.addEventListener('click', () => { activateView(b.dataset.view); run(loadList); }));
  root.querySelectorAll('[data-metric]').forEach(b => b.addEventListener('click', () => { activateView('pending'); filters.elements.attention.value = b.dataset.metric; run(loadList); }));
  filters.addEventListener('submit', e => e.preventDefault()); let timer;
  filters.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(() => { offset = 0; run(loadList); }, 350); });
  filters.addEventListener('reset', () => setTimeout(() => { offset = 0; run(loadList); }, 0));
  $('mailPrev').addEventListener('click', () => { offset = Math.max(0, offset - 30); run(loadList); });
  $('mailNext').addEventListener('click', () => { offset += 30; run(loadList); });
  run(refresh);
  setInterval(() => { if (!document.hidden && !root.querySelector('dialog[open]')) run(refresh); }, 45000);
  document.addEventListener('visibilitychange', () => { if (!document.hidden && !root.querySelector('dialog[open]')) run(refresh); });
})();
