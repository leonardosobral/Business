(() => {
  'use strict';
  const root = document.getElementById('business-funnel');
  if (!root) return;
  const $ = selector => root.querySelector(selector);
  const form = $('#funnel-filters');
  const number = new Intl.NumberFormat('pt-BR');
  const count = value => Number.isFinite(value) && value >= 0 ? number.format(value) : '—';
  const truth = value => value === true || value === 1 || value === 'true' || value === 'YES';
  const lowerKeys = value => Array.isArray(value) ? value.map(lowerKeys) : value && typeof value === 'object'
    ? Object.fromEntries(Object.entries(value).map(([key, item]) => [key.toLowerCase(), lowerKeys(item)])) : value;
  const element = (tag, text, className) => {
    const node = document.createElement(tag);
    if (text !== undefined) node.textContent = text;
    if (className) node.className = className;
    return node;
  };
  const localDay = date => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  const today = localDay(new Date());
  const validDay = value => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
    const parsed = new Date(`${value}T12:00:00`);
    return !Number.isNaN(parsed.getTime()) && localDay(parsed) === value && value >= '2000-01-01';
  };
  const products = {
    athletes: [['desafio', 'Desafio Todo Santo Dia'], ['selo', 'Selo Verificado'], ['assinatura', 'Assinatura'], ['gorunners', 'Go Runners'], ['estudo', 'Estudos']],
    organizers: [['patrocinio', 'Patrocinado (banners / anúncios)'], ['transmissao', 'Transmissão'], ['estudo', 'Estudos'], ['dados', 'API / dashboard de dados']]
  };
  function configureProducts(audience, requested) {
    const select = form.elements.namedItem('produto');
    const options = products[audience] || products.athletes;
    select.replaceChildren(...options.map(([value, label]) => { const option = element('option', label); option.value = value; return option; }));
    select.value = options.some(([value]) => value === requested) ? requested : options[0][0];
  }
  function currentStages(data) {
    if (data.filters.publico !== 'organizers') {
      const challenge = data.filters.produto === 'desafio';
      return [['base', 'Usuários cadastrados'], ['related', data.filters.produto === 'gorunners' ? 'Com cadastro Go Runners vinculado' : 'Com vínculo ao produto'], ['paid', challenge ? 'Clientes históricos do Todo Santo Dia' : 'Clientes históricos'], ['active', 'Vigência na data final'], ['renewed', 'Renovação em validação']];
    }
    const label = data.filters.produto === 'patrocinio' ? 'Pagaram créditos de Patrocinado'
      : data.filters.produto === 'transmissao' ? 'Fecharam Transmissão' : 'Contratações do produto';
    return [['base', 'Contas com dono ativo'], ['paid', label]];
  }
  function configureStage(audience, product) {
    const select = $('#funnel-stage');
    const previous = select.value;
    const options = audience === 'organizers' ? [['base', 'Todas as contas'], ['paid', 'Clientes históricos']]
      : product === 'desafio' ? [['base', 'Todos os cadastrados'], ['related', 'Com vínculo'], ['unpaid', 'Com vínculo, sem compra identificada'], ['paid', 'Clientes históricos'], ['unproven', 'Compradores sem vigência comprovada'], ['active', 'Vigentes na data final'], ['monthly', 'Vigentes no mês da data final'], ['status_c', 'Todo Santo Dia com status C hoje'], ['expired', 'Última vigência identificada encerrada']]
      : [['base', 'Todos os cadastrados'], ['related', 'Com vínculo'], ['paid', 'Clientes históricos'], ['active', 'Vigentes na data final']];
    select.replaceChildren(...options.map(([value, label]) => { const option = element('option', label); option.value = value; return option; }));
    select.value = options.some(([value]) => value === previous) ? previous : 'base';
  }
  let report = null;
  let page = 1;
  let controller;
  let generalController;
  let uiReady = false;
  let selectedTab = 'journey';
  let appliedFilters;
  const url = new URL(window.location.href);
  const generalForm = $('#funnel-general-filters');
  const generalMonth = generalForm.elements.namedItem('mes');
  const suppliedMonth = url.searchParams.get('mes') || '';
  generalMonth.max = today.slice(0, 7);
  generalMonth.min = '2000-01';
  generalMonth.value = /^\d{4}-(0[1-9]|1[0-2])$/.test(suppliedMonth) && suppliedMonth >= generalMonth.min && suppliedMonth <= generalMonth.max ? suppliedMonth : generalMonth.max;
  const initial = {publico: 'athletes', produto: 'desafio', leitura: 'base', de: `${today.slice(0, 4)}-01-01`, ate: today};
  Object.entries(initial).forEach(([key, fallback]) => {
    if (key === 'produto') return;
    const field = form.elements.namedItem(key);
    const supplied = url.searchParams.get(key);
    const allowed = field.tagName === 'SELECT' ? [...field.options].some(option => option.value === supplied) : validDay(supplied || '');
    field.value = allowed ? supplied : fallback;
    if (field.type === 'date') field.max = today;
  });
  configureProducts(form.elements.publico.value, url.searchParams.get('produto'));
  configureStage(form.elements.publico.value, form.elements.produto.value);
  const initialStage = url.searchParams.get('etapa');
  if ([...$('#funnel-stage').options].some(option => option.value === initialStage)) $('#funnel-stage').value = initialStage;
  $('#funnel-search').value = (url.searchParams.get('busca') || '').slice(0, 80);
  function setTab(name, focus = false) {
    selectedTab = ['geral', 'journey', 'people', 'transmissions', 'retention'].includes(name) ? name : 'journey';
    root.querySelectorAll('[data-tab]').forEach(button => {
      const selected = button.dataset.tab === selectedTab;
      button.setAttribute('aria-selected', String(selected));
      button.tabIndex = selected ? 0 : -1;
      $(`#panel-${button.dataset.tab}`).hidden = !selected;
      if (selected && focus) button.focus();
    });
    const next = new URL(window.location.href);
    next.hash = selectedTab;
    window.history.replaceState(null, '', next);
    const isGeneral = selectedTab === 'geral';
    form.hidden = isGeneral;
    $('#funnel-context').hidden = isGeneral;
    $('#funnel-message').hidden = isGeneral;
    if (uiReady) {
      if (isGeneral) loadGeneral();
      else if (!report) load(true);
    }
  }
  root.querySelectorAll('[data-tab]').forEach(button => {
    button.addEventListener('click', () => setTab(button.dataset.tab));
    button.addEventListener('keydown', event => {
      const keys = ['ArrowRight', 'ArrowLeft', 'Home', 'End'];
      if (!keys.includes(event.key)) return;
      event.preventDefault();
      const tabs = [...root.querySelectorAll('[data-tab]')].filter(tab => !tab.hidden);
      const index = tabs.indexOf(button);
      const next = event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1
        : (index + (event.key === 'ArrowRight' ? 1 : -1) + tabs.length) % tabs.length;
      setTab(tabs[next].dataset.tab, true);
    });
  });
  window.addEventListener('hashchange', () => setTab(window.location.hash.slice(1)));
  setTab(window.location.hash.slice(1));
  function message(text, error = false) {
    $('#funnel-message').textContent = text;
    $('#funnel-message').dataset.error = String(error);
  }
  async function loadGeneral() {
    const month = generalMonth.value;
    const status = $('#funnel-general-message');
    generalController?.abort();
    ['total', 'new', 'linked', 'term', 'challenge', 'go', 'owners', 'accounts', 'live', 'ads'].forEach(key => { $(`#general-${key}`).textContent = '—'; });
    $('#general-live-note').textContent = 'Contas com evento associado no leaderboard.';
    if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month) || month < generalMonth.min || month > generalMonth.max) {
      generalController = undefined;
      $('#panel-geral').setAttribute('aria-busy', 'false');
      status.dataset.error = 'true';
      status.textContent = 'Escolha um mês válido que não esteja no futuro.';
      return;
    }
    const requestController = new AbortController();
    generalController = requestController;
    const next = new URL(window.location.href);
    next.searchParams.set('mes', month);
    window.history.replaceState(null, '', next);
    status.dataset.error = 'false';
    status.textContent = 'Consultando cadastros…';
    $('#panel-geral').setAttribute('aria-busy', 'true');
    try {
      const params = new URLSearchParams({visao: 'geral', mes: month});
      const response = await fetch(`/portal/funil/report.cfm?${params}`, {credentials: 'same-origin', cache: 'no-store', signal: requestController.signal, headers: {Accept: 'application/json'}});
      if (!response.headers.get('content-type')?.includes('application/json')) throw new Error('A sessão expirou ou esta conta não tem acesso ao funil. Recarregue o Business.');
      const data = lowerKeys(await response.json());
      if (!response.ok) throw new Error(data.error || 'Não foi possível consultar os dados.');
      if (requestController !== generalController) return;
      const fields = ['total', 'new_users', 'paid_people', 'challenge_paid', 'challenge_month', 'go_people', 'org_people', 'org_accounts', 'ads_accounts', 'live_accounts', 'unassigned_events'];
      if (data.month !== month || !validDay(data.through) || !data.through.startsWith(month) || data.through > today || !data.coverage || fields.some(key => data[key] == null || !Number.isInteger(Number(data[key])) || Number(data[key]) < 0) || Number(data.total) < Number(data.new_users) || Number(data.total) < Number(data.paid_people) || Number(data.challenge_paid) < Number(data.challenge_month)) throw new Error('A consulta não retornou o formato esperado. Verifique se todos os arquivos da atualização foram publicados.');
      const through = data.through.split('-').reverse().join('/');
      $('#general-total').textContent = count(Number(data.total));
      $('#general-new').textContent = count(Number(data.new_users));
      const coverage = data.coverage;
      const challenge = truth(coverage.challenge_payments), terms = truth(coverage.terms), go = truth(coverage.gorunners), owners = truth(coverage.owners), ads = truth(coverage.ads), live = truth(coverage.transmission);
      const show = (id, available, value) => { $(`#general-${id}`).textContent = available ? count(Number(value)) : '—'; };
      show('linked', challenge || (owners && (ads || live)), data.paid_people);
      show('term', terms, data.challenge_month);
      show('challenge', challenge, data.challenge_paid);
      show('go', go, data.go_people);
      show('owners', owners && (ads || live), data.org_people);
      show('accounts', ads || live, data.org_accounts);
      show('live', live, data.live_accounts);
      show('ads', ads, data.ads_accounts);
      if (live) $('#general-live-note').textContent = `Contas com evento associado no leaderboard. Eventos sem atribuição de conta: ${count(Number(data.unassigned_events))}.`;
      $('#general-total-note').textContent = `Cadastros existentes até ${through}.`;
      $('#general-new-note').textContent = `Cadastros de ${month.slice(5)}/${month.slice(0, 4)} até ${through}.`;
      const unavailable = [['Todo Santo Dia', challenge], ['vigência do Desafio', terms], ['Go Runners', go], ['donos de contas', owners], ['Patrocinado', ads], ['Transmissão', live]].filter(([, available]) => !available).map(([label]) => label);
      status.textContent = `Dados até ${through} · Consulta: ${data.generated_at}. Cobertura parcial; vigência não mede uso.${unavailable.length ? ` Fontes indisponíveis: ${unavailable.join(', ')}.` : ''}`;
    } catch (error) {
      if (error.name !== 'AbortError' && requestController === generalController) { status.dataset.error = 'true'; status.textContent = error.message || 'Falha ao consultar os cadastros.'; }
    } finally {
      if (requestController === generalController) $('#panel-geral').setAttribute('aria-busy', 'false');
    }
  }
  function clearResults() {
    ['#funnel-shape', '#funnel-groups', '#funnel-people', '#funnel-transmissions', '#funnel-retention', '#funnel-coverage'].forEach(selector => $(selector).replaceChildren());
    $('#funnel-page-label').textContent = '';
    $('#funnel-prev').disabled = true;
    $('#funnel-next').disabled = true;
    report = null;
  }
  function renderShape(data) {
    const host = $('#funnel-shape');
    host.replaceChildren();
    const stages = currentStages(data);
    stages.forEach(([key, label], index) => {
      const value = Number(data.metrics[key]);
      const base = Number(data.metrics.base);
      const independent = false;
      const button = element('button', undefined, `funnel-step${independent ? ' funnel-step-coupon' : ''}`);
      button.type = 'button';
      button.style.setProperty('--left', independent ? '0%' : `${index * 7}%`);
      button.style.setProperty('--right', independent ? '0%' : `${(index + 1) * 7}%`);
      button.style.setProperty('--alpha', String(Math.min(0.96, 0.36 + index * 0.12)));
      button.setAttribute('aria-label', `${label}: ${count(value)}. Ver pessoas desta etapa.`);
      const band = element('span', undefined, 'funnel-band');
      band.setAttribute('aria-hidden', 'true');
      const text = element('span', undefined, 'funnel-step-text');
      text.append(element('strong', count(value)), element('span', label));
      const rate = element('span', undefined, 'funnel-step-rate');
      const percentage = value >= 0 && base > 0 ? `${(100 * value / base).toLocaleString('pt-BR', {maximumFractionDigits: 1})}%` : '—';
      rate.append(element('strong', percentage), element('span', 'da base'));
      const previous = index ? Number(data.metrics[stages[index - 1][0]]) : base;
      if (index && !independent && value >= 0 && previous > 0) rate.append(element('small', `${(100 * value / previous).toLocaleString('pt-BR', {maximumFractionDigits: 1})}% da anterior`));
      if (independent && value >= 0) rate.append(element('small', 'Etapa independente'));
      if (value < 0) rate.append(element('small', key === 'renewed' ? 'Em validação' : 'Não mapeado'));
      button.append(band, text, rate);
      button.disabled = value < 0;
      button.addEventListener('click', () => {
        $('#funnel-stage').value = key;
        page = 1;
        setTab('people', true);
        load(false);
      });
      host.append(button);
    });
  }
  function renderGroups(data) {
    const host = $('#funnel-groups');
    host.replaceChildren();
    const organizers = data.filters.publico === 'organizers';
    const groups = organizers ? [['base', 'Contas com dono ativo', 'base', 'da base'], ['paid', data.filters.produto === 'transmissao' ? 'Contas que contrataram' : 'Contas que pagaram', 'base', 'da base']]
      : data.filters.produto === 'gorunners' ? [['registered_only', 'Sem cadastro Go Runners vinculado', 'base', 'dos cadastrados'], ['related', 'Com cadastro Go Runners vinculado', 'base', 'dos cadastrados']]
      : [['registered_only', 'Cadastro sem vínculo conhecido', 'base', 'dos cadastrados'], ['related_unpaid', 'Com vínculo, sem compra identificada', 'related', 'com vínculo'], ['paid_without_term', 'Compradores sem vigência comprovada', 'paid', 'dos compradores'], ['term_active', 'Com vigência comprovada', 'paid', 'dos compradores']];
    groups.forEach(([key, label, denominatorKey, denominatorLabel]) => {
      const value = Number(data.metrics[key]);
      const denominator = Number(data.metrics[denominatorKey]);
      const group = element('div', undefined, 'funnel-group');
      group.append(element('span', label), element('strong', count(value)));
      const track = element('div', undefined, 'funnel-group-bar');
      const bar = element('span');
      const percentage = value >= 0 && denominator > 0 ? Math.min(100, 100 * value / denominator) : null;
      bar.style.width = `${percentage ?? 0}%`;
      track.append(bar);
      group.append(track);
      group.append(element('small', percentage === null ? '—' : `${percentage.toLocaleString('pt-BR', {maximumFractionDigits: 1})}% ${denominatorLabel}`, 'funnel-group-note'));
      host.append(group);
    });
    if (!organizers && data.filters.produto === 'desafio') {
      const metric = element('div', undefined, 'funnel-event-metric');
      const heading = element('div', undefined, 'funnel-group');
      const month = data.filters.ate.slice(0, 7).split('-').reverse().join('/');
      const value = Number(data.metrics.monthly_active);
      heading.append(element('span', `Vigentes no mês ${month}`), element('strong', count(value)));
      metric.append(heading, element('p', 'Indicador separado: inclui quem esteve vigente em algum momento do mês, até a data final. Essas pessoas também podem estar nos grupos acima; não some os totais.', 'funnel-muted small mb-2'));
      const button = element('button', 'Ver clientes do mês', 'btn btn-sm btn-outline-warning');
      button.type = 'button'; button.disabled = !Number.isFinite(value) || value < 0;
      button.addEventListener('click', () => { $('#funnel-stage').value = 'monthly'; page = 1; setTab('people', true); load(false); });
      metric.append(button); host.append(metric);
    }
    if (organizers) {
      const card = element('div', undefined, 'funnel-event-metric');
      const heading = element('div', undefined, 'funnel-group');
      heading.append(element('span', 'Clientes ativos no mês'), element('strong', '—'));
      card.append(heading, element('p', 'Regra de vigência ou saldo histórico ainda não disponível para este serviço.', 'funnel-muted small mb-0'));
      host.append(card);
    }
    if (organizers && data.filters.produto === 'transmissao') {
      const total = Number(data.metrics.transmissions);
      const card = element('div', undefined, 'funnel-event-metric');
      const heading = element('div', undefined, 'funnel-group');
      heading.append(element('span', 'Transmissões por evento no período'), element('strong', count(total)));
      card.append(heading, element('p', 'Inclui eventos sem conta. As datas são da prova; não indicam quando ocorreu o pagamento.', 'funnel-muted small mb-2'));
      const button = element('button', 'Ver eventos', 'btn btn-sm btn-outline-warning');
      button.type = 'button'; button.disabled = total < 0;
      button.addEventListener('click', () => setTab('transmissions', true));
      card.append(button); host.append(card);
    }
    host.append(element('p', organizers ? 'Contas são acumuladas até a data final; transmissões são contadas por data da prova. Vínculos desconhecidos não comprovam ausência de compra.' : data.filters.produto === 'gorunners' ? 'Contamos somente identificadores vinculados. A ausência de vínculo não prova que a pessoa não tenha uma conta Go Runners.' : 'Os grupos não se sobrepõem. Sem vínculo ou compra identificada indica apenas ausência de evidência nas fontes consultadas; compradores sem vigência comprovada podem ter data desconhecida ou vigência encerrada.', 'funnel-muted small mb-0'));
  }
  function renderPeople(data) {
    const host = $('#funnel-people');
    host.replaceChildren();
    data.people.forEach(person => {
      const row = element('tr');
      const identity = element('td');
      identity.append(element('span', person.name || 'Sem nome'), element('span', `ID ${person.id}`, 'funnel-person-id'));
      if (person.owners) identity.append(element('span', `Donos: ${person.owners}`, 'funnel-person-id'));
      if (person.accounts) identity.append(element('span', person.accounts, 'funnel-person-id'));
      const organizer = data.filters.publico === 'organizers';
      if (organizer) {
        const status = !truth(data.coverage.payments_mapped) ? 'Não mapeado' : truth(person.paid) ? (data.filters.produto === 'transmissao' ? 'Fechado pelo leaderboard' : 'Pagamento com crédito confirmado') : 'Não identificado';
        if (data.filters.produto === 'transmissao') {
          const detail = element('td');
          const events = Array.isArray(person.event_details) ? person.event_details : [];
          if (truth(data.coverage.payments_mapped) && events.length) {
            const disclosure = element('details', undefined, 'funnel-event-details');
            disclosure.append(element('summary', `${count(Number(person.event_count))} ${Number(person.event_count) === 1 ? 'transmissão' : 'transmissões'}`));
            const list = element('ul');
            events.forEach(event => list.append(element('li', `${event.name} · ${event.day} · ID ${event.id}`)));
            disclosure.append(list); detail.append(disclosure);
          } else detail.textContent = truth(data.coverage.payments_mapped) ? '0 no período' : 'Não mapeado';
          row.append(identity, element('td', person.owners || '—'), element('td', status), detail, element('td', 'Data da prova'), element('td', truth(person.paid) ? 'Leaderboard / atribuição comercial' : '—'));
        } else row.append(identity, element('td', person.owners || '—'), element('td', status), element('td', '—'), element('td', '—'), element('td', truth(person.paid) ? 'Pagamento e lançamento de crédito' : '—'));
        host.append(row);
        return;
      }
      const payment = !truth(data.coverage.payments_mapped) ? 'Não mapeado' : truth(person.paid) ? 'Compra registrada' : 'Sem compra identificada';
      const recurrence = !truth(data.coverage.payments_mapped) ? 'Não mapeada' : truth(person.term_active) ? 'Vigência comprovada' : truth(person.paid) ? 'Vigência encerrada ou não comprovada' : '—';
      const origin = !truth(data.coverage.signup_mapped) || person.origin === 'unknown' ? 'Sem histórico' : person.origin === 'last_recorded_click_7d' ? `Campanha ${person.campaign_id} · clique em até 7 dias` : 'Sem clique registrado';
      const paymentCell = element('td', payment);
      if (truth(person.paid) && person.payment_sources) paymentCell.append(element('span', person.payment_sources === 'crm' ? 'CRM / auditoria' : person.payment_sources === 'legacy' ? 'Transação do fluxo antigo' : 'Fontes financeiras confirmadas', 'funnel-person-id'));
      if (truth(data.coverage.status_c_mapped) && truth(person.status_c)) paymentCell.append(element('span', 'Inscrição status C hoje · compra e acesso', 'funnel-person-id'));
      row.append(identity, element('td', !truth(data.coverage.related_mapped) ? 'Não mapeado' : truth(person.related) ? (data.filters.produto === 'gorunners' ? 'Conta Go Runners vinculada' : 'Todo Santo Dia') : 'Sem vínculo conhecido'), paymentCell, element('td', person.term_start && person.term_end ? `${person.term_start} → ${person.term_end}` : '—'), element('td', recurrence), element('td', origin));
      host.append(row);
    });
    if (!data.people.length) {
      const row = element('tr');
      const cell = element('td', 'Nenhuma pessoa nesta seleção. Etapas não mapeadas não permitem classificar clientes.', 'funnel-muted py-4');
      cell.colSpan = 6;
      row.append(cell);
      host.append(row);
    }
    $('#funnel-page-label').textContent = `${count(Number(data.total))} ${data.filters.publico === 'organizers' ? 'contas' : 'pessoas'} · Página ${data.page} de ${Math.max(1, Math.ceil(data.total / data.page_size))}`;
    $('#funnel-prev').disabled = data.page <= 1;
    $('#funnel-next').disabled = data.page * data.page_size >= data.total;
  }
  function renderTransmissions(data) {
    const host = $('#funnel-transmissions');
    host.replaceChildren();
    const isTransmission = data.filters.publico === 'organizers' && data.filters.produto === 'transmissao';
    $('#tab-transmissions').hidden = !isTransmission;
    if (!isTransmission) { if (selectedTab === 'transmissions') setTab('journey'); return; }
    const events = Array.isArray(data.transmission_events) ? data.transmission_events : [];
    events.forEach(event => {
      const row = element('tr');
      const name = element('td');
      name.append(element('span', event.name || 'Evento sem nome'), element('span', `ID ${event.id}`, 'funnel-person-id'));
      const account = event.buyer || (Number(event.accounts) > 1 ? 'Múltiplas contas' : 'Sem conta identificada');
      const status = event.buyer ? (truth(event.in_base) ? (truth(event.manual) ? 'Atribuição informada' : 'Conta vinculada') : 'Conta fora da base selecionada') : (Number(event.accounts) > 1 ? `A conferir: ${event.account_names}` : Number(event.accounts) === 1 ? `A conferir: ${event.account_names}` : 'Sem vínculo de conta');
      row.append(name, element('td', event.day || '—'), element('td', account), element('td', status));
      host.append(row);
    });
    if (!events.length) { const row = element('tr'); const cell = element('td', truth(data.coverage.payments_mapped) ? 'Nenhum evento no período selecionado.' : 'Fonte de transmissões indisponível.', 'funnel-muted py-4'); cell.colSpan = 4; row.append(cell); host.append(row); }
  }
  function renderRetention(data) {
    const host = $('#funnel-retention');
    host.replaceChildren();
    const cards = data.filters.publico === 'organizers' || data.filters.produto !== 'desafio' ? [] : [
      ['monthly_active', 'Vigentes no mês da data final', 'Vigência comprovada em algum momento do mês, até a data final selecionada.'],
      ['term_active', 'Vigência comprovada na data final', 'Compra anual do Todo Santo Dia com data que permite comprovar 12 meses de vigência.'],
      ['continuous', 'Vigentes durante todo o período', 'Vigências anuais confirmadas cobrem o intervalo completo, sem lacunas.'],
      ['renewed_period', 'Renovação', 'Em validação: uma compra de outro produto não é renovação.'],
      ['expired_period', 'Última vigência identificada encerrou', 'Não demonstra churn: pode haver pagamento ou renovação sem correspondência.']
    ];
    cards.forEach(([key, title, note]) => {
      const card = element('div', undefined, 'business-panel funnel-retention-card');
      card.append(element('h2', title), element('strong', count(Number(data.metrics[key]))), element('p', note, 'funnel-muted small mb-0'));
      host.append(card);
    });
    const coverage = $('#funnel-coverage');
    coverage.className = 'funnel-coverage funnel-muted';
    coverage.replaceChildren();
    if (truth(data.coverage.signup_mapped)) coverage.append(element('p', `Origem do vínculo ao Desafio: ${count(Number(data.metrics.campaign_origin))} por clique de campanha; ${count(Number(data.metrics.no_click_origin))} sem clique registrado; ${count(Number(data.metrics.unknown_origin))} sem histórico de origem.`));
    data.coverage.notes.forEach(note => coverage.append(element('p', note)));
  }
  async function load(apply = true) {
    const filters = apply || !appliedFilters ? Object.fromEntries(new FormData(form)) : appliedFilters;
    if (!validDay(filters.de) || !validDay(filters.ate) || filters.de > filters.ate || filters.ate > today) {
      controller?.abort();
      clearResults();
      $('#funnel-results').setAttribute('aria-busy', 'false');
      message('Confira as datas: a data final não pode estar no futuro nem ser anterior à inicial.', true);
      return;
    }
    if (apply) page = 1;
    appliedFilters = {...filters};
    controller?.abort();
    const requestController = new AbortController();
    controller = requestController;
    const params = new URLSearchParams({...filters, etapa: $('#funnel-stage').value, busca: $('#funnel-search').value.trim(), pagina: String(page)});
    params.set('mes', generalMonth.value);
    const next = new URL(window.location.href);
    next.search = params.toString();
    next.hash = selectedTab;
    window.history.replaceState(null, '', next);
    clearResults();
    $('#funnel-results').setAttribute('aria-busy', 'true');
    message('Consultando dados…');
    try {
      const response = await fetch(`/portal/funil/report.cfm?${params}`, {credentials: 'same-origin', cache: 'no-store', signal: requestController.signal, headers: {Accept: 'application/json'}});
      if (!response.headers.get('content-type')?.includes('application/json')) throw new Error('A sessão expirou ou esta conta não tem acesso ao funil. Recarregue o Business.');
      const data = lowerKeys(await response.json());
      if (!response.ok) throw new Error(data.error || 'Não foi possível consultar os dados.');
      if (requestController !== controller) return;
      if (!data.metrics || !Array.isArray(data.people) || !data.coverage || !Array.isArray(data.coverage.notes)) throw new Error('A consulta não retornou o formato esperado.');
      report = data;
      renderShape(data);
      renderGroups(data);
      renderPeople(data);
      renderTransmissions(data);
      renderRetention(data);
      const organizer = filters.publico === 'organizers';
      const audience = organizer ? 'Contas com dono ativo, sem funcionários' : 'Usuários cadastrados';
      $('#funnel-reading-help').textContent = organizer ? (filters.produto === 'transmissao' ? 'Um evento no leaderboard indica fechamento pela regra comercial informada. A conta é identificada por vínculo único ou atribuição comercial informada pela equipe; o dono é identificado pelo vínculo atual.' : filters.produto === 'patrocinio' ? 'No Patrocinado, o pagamento precisa estar confirmado e associado ao lançamento de crédito. Uma conta sem compra identificada ainda pode ter histórico fora desta fonte.' : 'A fonte deste produto ainda não foi reconciliada para identificar contratações.') : filters.produto === 'gorunners' ? 'Cadastro vinculado pelo ID RunnerHub registrado no Go Runners. Cadastro não comprova assinatura; contas sem vínculo de ID não entram na contagem.' : filters.produto === 'desafio' ? 'Cadastro sem vínculo conhecido significa que as fontes consultadas não encontraram relação com o produto. Vigência comprovada exige pagamento anual identificável com data; status C informa compra e acesso atuais, mas não comprova a data.' : 'A fonte deste produto ainda não foi reconciliada para identificar compras ou vigências.';
      const headers = root.querySelectorAll('#funnel-people-table th');
      (organizer ? (filters.produto === 'transmissao' ? ['Conta', 'Donos atuais', 'Contratação acumulada', 'Transmissões no período', 'Referência', 'Fonte'] : ['Conta', 'Donos atuais', 'Contratação', 'Vigência até', 'Situação', 'Fonte']) : ['Pessoa', 'Vínculo', 'Pagamento', 'Vigência desde o pagamento', 'Situação', 'Origem do vínculo']).forEach((label, index) => { headers[index].textContent = label; });
      $('#funnel-base-label').textContent = audience;
      $('#funnel-context').textContent = `${audience} · ${filters.leitura === 'cohort' ? 'Cadastros entre' : 'Base acumulada até'} ${filters.leitura === 'cohort' ? filters.de.split('-').reverse().join('/') + ' e ' : ''}${filters.ate.split('-').reverse().join('/')} · ${organizer ? 'Fontes e limitações em Retenção e origem.' : 'Compras até a data final; vigência comprovada à parte.'}`;
      message(`${truth(data.coverage.payments_mapped) ? (organizer ? (filters.produto === 'transmissao' ? 'Fechamento identificado pela configuração do leaderboard e conta vinculada.' : 'Pagamento identificado pelo crédito de Patrocinado.') : 'Compra identificada por status C atual ou pagamento confirmado. Cobertura histórica parcial.') : 'Contratações deste público/produto ainda não estão mapeadas.'} Consulta: ${data.generated_at}. Veja as regras em Retenção e origem.`);
    } catch (error) {
      if (error.name !== 'AbortError' && requestController === controller) { clearResults(); message(error.message || 'Falha ao consultar o funil.', true); }
    } finally {
      if (requestController === controller) $('#funnel-results').setAttribute('aria-busy', 'false');
    }
  }
  form.addEventListener('submit', event => { event.preventDefault(); load(true); });
  generalForm.addEventListener('submit', event => { event.preventDefault(); loadGeneral(); });
  form.querySelectorAll('select').forEach(field => field.addEventListener('change', () => { if (field.name === 'publico') configureProducts(field.value, form.elements.produto.value); if (field.name === 'publico' || field.name === 'produto') { configureStage(form.elements.publico.value, form.elements.produto.value); $('#funnel-stage').value = 'base'; } load(true); }));
  $('#funnel-stage').addEventListener('change', () => { page = 1; load(false); });
  $('#funnel-search-button').addEventListener('click', () => { page = 1; load(false); });
  $('#funnel-search').addEventListener('keydown', event => { if (event.key === 'Enter') { event.preventDefault(); page = 1; load(false); } });
  $('#funnel-prev').addEventListener('click', () => { if (report && page > 1) { page--; load(false); } });
  $('#funnel-next').addEventListener('click', () => { if (report && page * report.page_size < report.total) { page++; load(false); } });
  uiReady = true;
  if (selectedTab === 'geral') loadGeneral(); else load(true);
})();
