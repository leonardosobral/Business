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
  const stages = [
    ['base', 'Usuários cadastrados'], ['related', 'Com vínculo ao produto'],
    ['paid', 'Já pagaram'], ['active', 'Pagantes Todo Santo Dia'], ['renewed', 'Pagaram 365 e Todo Santo Dia'],
    ['coupon', 'Inscritos com nosso cupom']
  ];
  let report = null;
  let page = 1;
  let controller;
  let selectedTab = 'journey';
  let appliedFilters;
  const url = new URL(window.location.href);
  const initial = {publico: 'athletes', produto: 'desafio', leitura: 'base', de: `${today.slice(0, 4)}-01-01`, ate: today};
  Object.entries(initial).forEach(([key, fallback]) => {
    const field = form.elements.namedItem(key);
    const supplied = url.searchParams.get(key);
    const allowed = field.tagName === 'SELECT' ? [...field.options].some(option => option.value === supplied) : validDay(supplied || '');
    field.value = allowed ? supplied : fallback;
    if (field.type === 'date') field.max = today;
  });
  const initialStage = url.searchParams.get('etapa');
  if ([...$('#funnel-stage').options].some(option => option.value === initialStage)) $('#funnel-stage').value = initialStage;
  $('#funnel-search').value = (url.searchParams.get('busca') || '').slice(0, 80);
  function setTab(name, focus = false) {
    selectedTab = ['journey', 'people', 'retention'].includes(name) ? name : 'journey';
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
  }
  root.querySelectorAll('[data-tab]').forEach(button => {
    button.addEventListener('click', () => setTab(button.dataset.tab));
    button.addEventListener('keydown', event => {
      const keys = ['ArrowRight', 'ArrowLeft', 'Home', 'End'];
      if (!keys.includes(event.key)) return;
      event.preventDefault();
      const tabs = [...root.querySelectorAll('[data-tab]')];
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
  function clearResults() {
    ['#funnel-shape', '#funnel-groups', '#funnel-people', '#funnel-retention', '#funnel-coverage'].forEach(selector => $(selector).replaceChildren());
    $('#funnel-page-label').textContent = '';
    $('#funnel-prev').disabled = true;
    $('#funnel-next').disabled = true;
    report = null;
  }
  function renderShape(data) {
    const host = $('#funnel-shape');
    host.replaceChildren();
    stages.forEach(([key, label], index) => {
      const value = Number(data.metrics[key]);
      const base = Number(data.metrics.base);
      const independent = key === 'coupon';
      const button = element('button', undefined, `funnel-step${independent ? ' funnel-step-coupon' : ''}`);
      button.type = 'button';
      button.style.setProperty('--left', independent ? '0%' : `${index * 7}%`);
      button.style.setProperty('--right', independent ? '0%' : `${(index + 1) * 7}%`);
      button.style.setProperty('--alpha', String(0.36 + index * 0.12));
      button.setAttribute('aria-label', `${label}: ${count(value)}. Ver pessoas desta etapa.`);
      const band = element('span', undefined, 'funnel-band');
      band.setAttribute('aria-hidden', 'true');
      const text = element('span', undefined, 'funnel-step-text');
      text.append(element('strong', count(value)), element('span', label));
      if (independent) text.append(element('small', 'ROADRUNNERS · TicketSports'));
      const rate = element('span', undefined, 'funnel-step-rate');
      const percentage = value >= 0 && base > 0 ? `${(100 * value / base).toLocaleString('pt-BR', {maximumFractionDigits: 1})}%` : '—';
      rate.append(element('strong', percentage), element('span', 'da base'));
      const previous = index ? Number(data.metrics[stages[index - 1][0]]) : base;
      if (index && !independent && value >= 0 && previous > 0) rate.append(element('small', `${(100 * value / previous).toLocaleString('pt-BR', {maximumFractionDigits: 1})}% da anterior`));
      if (independent && value >= 0) rate.append(element('small', 'Etapa independente'));
      if (value < 0) rate.append(element('small', 'Não mapeado'));
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
    [['registered_only', 'Cadastro sem vínculo conhecido'], ['related_without_term', 'Com vínculo, sem vigência comprovada'], ['term_active', 'Vigência comprovada']].forEach(([key, label]) => {
      const value = Number(data.metrics[key]);
      const group = element('div', undefined, 'funnel-group');
      group.append(element('span', label), element('strong', count(value)));
      const track = element('div', undefined, 'funnel-group-bar');
      const bar = element('span');
      bar.style.width = `${value >= 0 && data.metrics.base > 0 ? Math.min(100, 100 * value / data.metrics.base) : 0}%`;
      track.append(bar);
      group.append(track);
      host.append(group);
    });
    host.append(element('p', 'Sem vigência comprovada também inclui pagamentos sem data utilizável, ex-clientes e pagamentos ainda não identificados.', 'funnel-muted small mb-0'));
    if (truth(data.coverage.coupons_mapped)) host.append(element('p', `${count(Number(data.metrics.coupon_registrations))} inscrições com ROADRUNNERS ligadas a ${count(Number(data.metrics.coupon))} pessoas desta base. Cobertura das provas importadas.`, 'funnel-muted small mb-0'));
  }
  function renderPeople(data) {
    const host = $('#funnel-people');
    host.replaceChildren();
    data.people.forEach(person => {
      const row = element('tr');
      const identity = element('td');
      identity.append(element('span', person.name || 'Sem nome'), element('span', `ID ${person.id}`, 'funnel-person-id'));
      if (person.accounts) identity.append(element('span', person.accounts, 'funnel-person-id'));
      const payment = !truth(data.coverage.payments_mapped) ? 'Não mapeado' : truth(person.renewed) ? '365 + Todo Santo Dia' : truth(person.active) ? 'Todo Santo Dia' : truth(person.paid_365) ? 'Desafio 365' : 'Sem compra anual confirmada';
      const recurrence = !truth(data.coverage.payments_mapped) ? 'Não mapeada' : truth(person.renewed) ? 'Comprou os dois desafios' : truth(person.active) ? 'Comprou Todo Santo Dia' : truth(person.paid_365) ? 'Comprou Desafio 365' : '—';
      const origin = !truth(data.coverage.signup_mapped) || person.origin === 'unknown' ? 'Sem histórico' : person.origin === 'last_recorded_click_7d' ? `Campanha ${person.campaign_id} · clique em até 7 dias` : 'Sem clique registrado';
      const paymentCell = element('td', payment);
      if (truth(person.paid)) paymentCell.append(element('span', person.payment_sources === 'crm' ? 'CRM / auditoria' : person.payment_sources === 'legacy' ? 'Transação do fluxo antigo' : person.payment_sources === 'webhook' ? 'Pedido histórico Pagar.me' : 'Fontes financeiras confirmadas', 'funnel-person-id'));
      const couponCell = element('td', !truth(data.coverage.coupons_mapped) ? 'Não mapeado' : truth(person.coupon) ? `${count(Number(person.coupon_registrations))} inscrição(ões) · ${count(Number(person.coupon_events))} prova(s)` : '—', 'funnel-coupon-cell');
      if (truth(person.coupon)) {
        couponCell.append(element('span', `Última: ${person.coupon_last_event}${person.coupon_last_modality ? ` · ${person.coupon_last_modality}` : ''}`, 'funnel-person-id'));
        couponCell.append(element('span', `${person.coupon_last_day} · ROADRUNNERS · e-mail do participante`, 'funnel-person-id'));
      }
      row.append(identity, element('td', !truth(data.coverage.related_mapped) ? 'Não mapeado' : truth(person.related) ? 'Desafio' : 'Sem vínculo conhecido'), paymentCell, element('td', person.term_end || '—'), element('td', recurrence), couponCell, element('td', origin));
      host.append(row);
    });
    if (!data.people.length) {
      const row = element('tr');
      const cell = element('td', 'Nenhuma pessoa nesta seleção. Etapas não mapeadas não permitem classificar clientes.', 'funnel-muted py-4');
      cell.colSpan = 7;
      row.append(cell);
      host.append(row);
    }
    $('#funnel-page-label').textContent = `${count(Number(data.total))} pessoas · Página ${data.page} de ${Math.max(1, Math.ceil(data.total / data.page_size))}`;
    $('#funnel-prev').disabled = data.page <= 1;
    $('#funnel-next').disabled = data.page * data.page_size >= data.total;
  }
  function renderRetention(data) {
    const host = $('#funnel-retention');
    host.replaceChildren();
    [
      ['term_active', 'Vigência comprovada na data final', 'Compra anual do Todo Santo Dia com data que permite comprovar 12 meses de vigência.'],
      ['continuous', 'Vigentes durante todo o período', 'Vigências anuais confirmadas cobrem o intervalo completo, sem lacunas.'],
      ['renewed_period', 'Compradores dos dois com TSD no período', 'Compraram 365 e Todo Santo Dia, com pagamento datado do Todo Santo Dia no intervalo selecionado.'],
      ['expired_period', 'Encerraram a vigência no período', 'Sem nova vigência confirmada até a data final. Indício de churn na base conhecida.']
    ].forEach(([key, title, note]) => {
      const card = element('div', undefined, 'business-panel funnel-retention-card');
      card.append(element('h2', title), element('strong', count(Number(data.metrics[key]))), element('p', note, 'funnel-muted small mb-0'));
      host.append(card);
    });
    const coverage = $('#funnel-coverage');
    coverage.className = 'funnel-coverage funnel-muted';
    coverage.replaceChildren();
    if (truth(data.coverage.coupons_mapped)) {
      const stats = data.coverage.coupon_stats;
      coverage.append(element('p', `TicketSports / ROADRUNNERS até a data final: ${count(Number(stats.registrations))} inscrições com pedido Pago; ${count(Number(stats.matched))} ligadas à base selecionada; ${count(Number(stats.unmatched))} sem usuário correspondente; ${count(Number(stats.outside_base))} com usuário fora deste recorte; ${count(Number(stats.ambiguous))} com e-mail compartilhado por contas; ${count(Number(stats.conflicting))} com e-mails divergentes; ${count(Number(stats.invalid))} sem e-mail válido.`));
    }
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
      renderRetention(data);
      const audience = filters.publico === 'organizers' ? 'Donos de contas, sem funcionários' : 'Usuários cadastrados';
      $('#funnel-base-label').textContent = audience;
      $('#funnel-context').textContent = `${audience} · ${filters.leitura === 'cohort' ? 'Cadastros entre' : 'Base acumulada; retenção entre'} ${filters.de.split('-').reverse().join('/')} e ${filters.ate.split('-').reverse().join('/')} · Compras até a data final; vigência comprovada à parte.`;
      message(`${truth(data.coverage.payments_mapped) ? 'Pagamentos confirmados na base conhecida. Cobertura histórica parcial.' : 'Pagamentos deste público/produto ainda não estão mapeados.'} Consulta: ${data.generated_at}. Veja as regras em Retenção e origem.`);
    } catch (error) {
      if (error.name !== 'AbortError' && requestController === controller) { clearResults(); message(error.message || 'Falha ao consultar o funil.', true); }
    } finally {
      if (requestController === controller) $('#funnel-results').setAttribute('aria-busy', 'false');
    }
  }
  form.addEventListener('submit', event => { event.preventDefault(); load(true); });
  form.querySelectorAll('select').forEach(field => field.addEventListener('change', () => load(true)));
  $('#funnel-stage').addEventListener('change', () => { page = 1; load(false); });
  $('#funnel-search-button').addEventListener('click', () => { page = 1; load(false); });
  $('#funnel-search').addEventListener('keydown', event => { if (event.key === 'Enter') { event.preventDefault(); page = 1; load(false); } });
  $('#funnel-prev').addEventListener('click', () => { if (report && page > 1) { page--; load(false); } });
  $('#funnel-next').addEventListener('click', () => { if (report && page * report.page_size < report.total) { page++; load(false); } });
  load(true);
})();
