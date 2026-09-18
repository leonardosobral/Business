(() => {
  'use strict';
  const root = document.getElementById('aiMails');
  if (!root) return;
  const $ = id => document.getElementById(id);
  const filters = $('mailFilters');
  const priorities = {critical: 'Crítica', high: 'Alta', normal: 'Normal', informational: 'Para ciência', low: 'Baixa relevância'};
  const categories = {operacao: 'Operação', financeiro: 'Financeiro', comercial: 'Comercial', suporte: 'Suporte', seguranca: 'Segurança', juridico: 'Jurídico', outros: 'Outros'};
  const states = {pending: 'Pendente', in_progress: 'Em andamento', resolved: 'Resolvido'};
  const operations = {resolve: 'Marcou como resolvido', reopen: 'Reabriu', assign: 'Alterou responsável', note: 'Atualizou observação', classify: 'Corrigiu classificação', reanalyze: 'Solicitou nova análise', analyzed: 'Análise atualizada', reopened_new_request: 'Reaberto por novo pedido'};
  let status = null, view = 'pending', offset = 0, current = null, generation = 0, busy = false;
  const date = value => value ? new Intl.DateTimeFormat('pt-BR', {dateStyle: 'short', timeStyle: 'short', timeZone: 'America/Sao_Paulo'}).format(new Date(value)) : '—';
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
  function link(text, url) { const a = el('a', text, 'btn btn-outline-light'); a.href = url; a.target = '_blank'; a.rel = 'noopener noreferrer'; return a; }
  function badges(item) {
    const n = el('div', null, 'mail-badges');
    n.append(el('span', priorities[item.priority] || 'Em análise', 'mail-badge mail-badge-' + item.priority));
    if (item.needs_response) n.append(el('span', 'Requer resposta', 'mail-badge'));
    if (item.needs_review) n.append(el('span', 'Revisão necessária', 'mail-badge mail-badge-review'));
    if (item.queued) n.append(el('span', 'Atualização em fila', 'mail-badge'));
    n.append(el('span', states[item.state] || item.state, 'mail-badge'));
    return n;
  }
  async function loadStatus() {
    status = await api('status');
    const c = status.config;
    $('mailStatus').textContent = !status.connected ? 'Gmail: autorização pendente' : !c.enabled ? 'Gmail autorizado · monitor pausado' : 'Monitor ativo · Gmail: ' + (c.last_sync_at ? 'sincronizado em ' + date(c.last_sync_at) : 'primeira coleta pendente');
    $('mailSetup').hidden = status.connected && c.enabled;
    $('mailConnect').hidden = status.connected;
    $('mailSetupText').textContent = !status.connected ? 'Autorize a leitura do Gmail nesta integração para começar. Agenda, Meet e Documentos continuam disponíveis.' : 'Gmail autorizado. Abra Configurações, confirme o processamento pela IA e ative o monitor.';
    for (const [key, id] of Object.entries({pending: 'metricPending', urgent: 'metricUrgent', response: 'metricResponse', overdue: 'metricOverdue'})) $(id).textContent = status.metrics[key];
    const progress = [status.queue.total + ' conversa(s) na fila de análise', status.queue.errors + ' com falha ou aguardando nova tentativa'];
    if (!c.initial_complete) progress.push('Carga inicial em andamento: ' + c.collected + ' conversa(s) coletada(s)');
    if (status.usage.limited) progress.push('Limite diário atingido; fila preservada');
    if (!status.ai_configured) progress.push('OpenAI não configurada');
    if (c.last_error) progress.push(c.last_error);
    if (status.jobs.length !== 2 || status.jobs.some(j => !j.active)) progress.push('Atenção: agendamento incompleto ou desativado');
    $('mailProgress').textContent = progress.join(' · ');
    const selected = filters.elements.assignee.value;
    $('mailAssignee').replaceChildren(new Option('Todos', ''), new Option('Não atribuído', 'none'));
    status.actors.forEach(a => $('mailAssignee').add(new Option(a.name, String(a.id))));
    filters.elements.assignee.value = selected;
  }
  async function loadList() {
    const gen = ++generation;
    $('mailItems').setAttribute('aria-busy', 'true');
    try {
      const data = await api('list', {view, offset, ...Object.fromEntries(new FormData(filters))});
      if (gen !== generation) return;
      $('mailItems').replaceChildren();
      data.items.forEach(item => {
        const card = el('article', null, 'mail-card'); card.dataset.priority = item.priority;
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
        side.append(actions); card.append(main, side); $('mailItems').append(card);
      });
      if (!data.items.length) {
        const empty = el('div', null, 'mail-empty');
        const ready = status?.connected && status?.config.enabled && status?.config.initial_complete && !status?.queue.total && !status?.config.last_error;
        empty.append(el('h3', ready ? 'Nenhuma conversa nesta visão' : 'Ainda não há resumos nesta visão'), el('p', ready ? 'Ajuste os filtros ou consulte a Revisão da triagem.' : 'Confira a conexão, a ativação e o andamento da fila acima. Ausência de resumos não significa ausência de pendências.'));
        $('mailItems').append(empty);
      }
      $('mailCount').textContent = data.total + ' conversa(s)' + (view === 'review' ? ' · baixa relevância, incertezas e fontes indisponíveis' : '');
      $('mailPage').textContent = 'Página ' + (Math.floor(offset / 30) + 1) + ' de ' + Math.max(1, Math.ceil(data.total / 30));
      $('mailPrev').disabled = offset === 0; $('mailNext').disabled = offset + 30 >= data.total;
    } finally { if (gen === generation) $('mailItems').setAttribute('aria-busy', 'false'); }
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
  async function showSettings() {
    await loadStatus(); const form = $('mailConfigForm');
    for (const key of ['model', 'daily_limit', 'initial_days', 'retention_days']) form.elements[key].value = status.config[key];
    form.elements.enabled.checked = status.config.enabled; form.elements.consent.checked = status.config.enabled;
    $('mailUsage').textContent = 'Hoje: ' + status.usage.total + '/' + status.config.daily_limit + ' tentativas de análise · ' + status.usage.input_tokens + ' tokens de entrada · ' + status.usage.output_tokens + ' de saída. Tentativas com falha também contam no limite.';
    if (Number.isFinite(status.usage.estimated_usd)) $('mailUsage').textContent += ' Estimativa de texto: US$ ' + status.usage.estimated_usd.toFixed(4) + (status.usage.estimate_incomplete ? ' (parcial).' : '.') + ' Referência 17/09/2026, sem descontos de cache e sem custos da base RAG; não substitui a fatura OpenAI.';
    $('mailConfigError').textContent = ''; $('mailConfig').showModal();
  }
  async function connect() { const data = await api('connect'); const u = new URL(data.url); if (u.origin !== 'https://accounts.google.com') throw new Error('Endereço de autorização inválido.'); window.location.assign(u.href); }
  $('mailConnect').addEventListener('click', e => run(connect, e.currentTarget));
  $('mailReconnect').addEventListener('click', e => run(connect, e.currentTarget));
  $('mailSettings').addEventListener('click', e => run(showSettings, e.currentTarget));
  $('mailRefresh').addEventListener('click', e => run(async () => { const d = await api('refresh'); notify(d.message); await refresh(); }, e.currentTarget));
  $('mailConfigForm').addEventListener('submit', e => { e.preventDefault(); run(async () => {
    const f = e.currentTarget;
    try { const d = await api('settings', {...Object.fromEntries(new FormData(f)), enabled: String(f.elements.enabled.checked), consent: String(f.elements.consent.checked)}); $('mailConfig').close(); notify(d.message); await refresh(); }
    catch (error) { $('mailConfigError').textContent = error.message; }
  }, e.submitter); });
  root.querySelectorAll('[data-close]').forEach(b => b.addEventListener('click', () => b.closest('dialog').close()));
  root.querySelectorAll('[data-view]').forEach(b => b.addEventListener('click', () => { view = b.dataset.view; offset = 0; root.querySelectorAll('[data-view]').forEach(v => v.setAttribute('aria-pressed', String(v === b))); run(loadList); }));
  root.querySelectorAll('[data-metric]').forEach(b => b.addEventListener('click', () => { view = 'pending'; offset = 0; filters.elements.attention.value = b.dataset.metric; root.querySelectorAll('[data-view]').forEach(v => v.setAttribute('aria-pressed', String(v.dataset.view === view))); run(loadList); }));
  filters.addEventListener('submit', e => e.preventDefault()); let timer;
  filters.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(() => { offset = 0; run(loadList); }, 350); });
  filters.addEventListener('reset', () => setTimeout(() => { offset = 0; run(loadList); }, 0));
  $('mailPrev').addEventListener('click', () => { offset = Math.max(0, offset - 30); run(loadList); });
  $('mailNext').addEventListener('click', () => { offset += 30; run(loadList); });
  run(refresh);
  setInterval(() => { if (!document.hidden && !$('mailConfig').open) run(refresh); }, 45000);
  document.addEventListener('visibilitychange', () => { if (!document.hidden) run(refresh); });
})();
