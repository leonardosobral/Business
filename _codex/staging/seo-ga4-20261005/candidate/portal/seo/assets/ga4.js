(function () {
  'use strict';
  function change(current, previous) { return previous > 0 ? ((current - previous) / previous) * 100 : null; }
  function reportRows(report) {
    return (report.rows || []).map(row => {
      const out = {};
      (report.dimensionHeaders || []).forEach((h, i) => { out[h.name] = row.dimensionValues?.[i]?.value || ''; });
      (report.metricHeaders || []).forEach((h, i) => { out[h.name] = Number(row.metricValues?.[i]?.value || 0); });
      return out;
    });
  }
  function summary(report) {
    const rows = reportRows(report);
    return { atual: rows.find(r => r.dateRange === 'atual') || {}, anterior: rows.find(r => r.dateRange === 'anterior') || {} };
  }
  function formatDate(value) { const raw = value.replaceAll('-', ''); return /^\d{8}$/.test(raw) ? `${raw.slice(6)}/${raw.slice(4, 6)}/${raw.slice(0, 4)}` : value; }
  if (typeof module !== 'undefined' && module.exports) module.exports = {change, reportRows, summary, formatDate};
  if (typeof document === 'undefined') return;
  const app = document.getElementById('ga4-app'); if (!app) return;
  const el = id => document.getElementById('ga4-' + id);
  const fmt = n => Number(n).toLocaleString('pt-BR', {maximumFractionDigits: 0});
  let busy = false;
  async function api(action, values = {}) {
    const response = await fetch('/portal/seo/ga4_api.cfm', {method: 'POST', credentials: 'same-origin', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: new URLSearchParams({action, csrf_token: app.dataset.csrf, ...values})});
    let data; try { data = await response.json(); } catch { throw new Error('Sessão expirada ou resposta indisponível. Recarregue a página.'); }
    if (!response.ok || !data.success) throw new Error(data.message || 'Não foi possível consultar o Analytics.');
    return data.data;
  }
  async function run(fn) {
    if (busy) return; busy = true; app.setAttribute('aria-busy', 'true');
    app.querySelectorAll('button, select').forEach(e => { e.disabled = true; });
    try { await fn(); } catch (e) { el('status').textContent = e.message; }
    finally { busy = false; app.removeAttribute('aria-busy'); app.querySelectorAll('button, select').forEach(e => { e.disabled = false; }); }
  }
  async function connect() {
    el('status').textContent = 'Abrindo autorização do Google…';
    const data = await api('connect'); const url = new URL(data.url);
    if (url.origin !== 'https://accounts.google.com') throw new Error('Endereço de autorização inválido.');
    location.assign(url.href);
  }
  function table(target, rows, columns) {
    const host = el(target); host.replaceChildren();
    if (!rows.length) { const p = document.createElement('p'); p.textContent = 'Nenhum dado retornado pelo Google neste recorte.'; host.append(p); return; }
    const t = document.createElement('table'), head = t.createTHead().insertRow();
    columns.forEach(c => { const th = document.createElement('th'); th.scope = 'col'; th.textContent = c[1]; head.append(th); });
    const body = t.createTBody(); rows.forEach(row => { const tr = body.insertRow(); columns.forEach(c => { const td = tr.insertCell(); const v = row[c[0]]; td.textContent = c[2] ? c[2](v) : String(v ?? ''); }); }); host.append(t);
  }
  function tab() {
    const name = ['evolucao', 'canais', 'paginas', 'ia'].includes(location.hash.slice(1)) ? location.hash.slice(1) : 'evolucao';
    document.querySelectorAll('[data-ga4-tab]').forEach(a => { const active = a.dataset.ga4Tab === name; if (active) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current'); el(a.dataset.ga4Tab).hidden = !active; });
  }
  function render(data) {
    const [totals, daily, channels, pages, ai] = data.reports, sums = summary(totals);
    const fields = [['activeUsers','Usuários ativos'],['sessions','Sessões'],['screenPageViews','Visualizações'],['engagementRate','Taxa de engajamento']];
    el('metrics').replaceChildren();
    fields.forEach(([key, label]) => {
      const box = document.createElement('div'), dt = document.createElement('dt'), dd = document.createElement('dd'), small = document.createElement('small');
      const current = sums.atual[key] || 0, previous = sums.anterior[key] || 0, delta = change(current, previous);
      dt.textContent = label; dd.textContent = key === 'engagementRate' ? `${(current * 100).toFixed(1).replace('.', ',')}%` : fmt(current);
      small.textContent = key === 'engagementRate' ? `${((current-previous)*100).toFixed(1).replace('.', ',')} p.p. vs. anterior` : delta === null ? 'Sem base anterior para calcular variação' : `${delta > 0 ? '+' : ''}${delta.toFixed(1).replace('.', ',')}% vs. anterior`;
      box.append(dt, dd, small); el('metrics').append(box);
    });
    const [now, before] = data.periods;
    el('period').textContent = `${data.property.name} · ${formatDate(now.startDate)} a ${formatDate(now.endDate)} vs. ${formatDate(before.startDate)} a ${formatDate(before.endDate)} · Fuso: ${data.property.timezone} · Consultado: ${new Date(data.updated).toLocaleString('pt-BR', {timeZone:'America/Sao_Paulo'})} (Brasília).`;
    const warnings = new Set();
    for (const report of data.reports) {
      const m = report.metadata || {};
      if (m.subjectToThresholding) warnings.add('O Google aplicou ou pode aplicar limites de privacidade.');
      if (m.dataLossFromOtherRow) warnings.add('Há dados agrupados em “outros” por limite de cardinalidade.');
      if (m.samplingMetadatas?.length) warnings.add('O Google informou amostragem neste relatório.');
    }
    el('warnings').hidden = warnings.size === 0; el('warnings').textContent = [...warnings].join(' ');
    const metrics = [['sessions','Sessões',fmt],['activeUsers','Usuários ativos',fmt],['screenPageViews','Visualizações',fmt]];
    table('daily', reportRows(daily), [['date','Data',formatDate], ...metrics]);
    table('channels', reportRows(channels), [['sessionDefaultChannelGroup','Canal'], ...metrics]);
    table('pages', reportRows(pages), [['landingPage','Página'], ...metrics]);
    table('ai', reportRows(ai), [['sessionSource','Origem'], ['sessionMedium','Meio'], ...metrics]);
    el('result').hidden = false; tab();
  }
  async function load() {
    el('result').hidden = true; el('status').textContent = 'Consultando audiência no Google…';
    const property = el('property').value, days = el('days').value;
    const data = await api('report', {property, days}); render(data);
    const url = new URL(location.href); url.searchParams.set('propriedade', property); url.searchParams.set('dias', days); history.replaceState(null, '', url);
    el('status').textContent = 'Dados carregados. Consultas repetidas reutilizam o resultado por até 15 minutos.';
  }
  el('connect').addEventListener('click', () => run(connect)); el('reconnect').addEventListener('click', () => run(connect));
  el('filters').addEventListener('submit', e => { e.preventDefault(); run(load); });
  ['property', 'days'].forEach(name => el(name).addEventListener('change', () => { el('result').hidden = true; el('status').textContent = 'Clique em Carregar dados para aplicar os filtros.'; }));
  window.addEventListener('hashchange', tab);
  run(async () => {
    const status = await api('status');
    if (!status.authorized) { el('status').textContent = 'Falta autorizar a leitura do Analytics.'; el('connect-panel').hidden = false; return; }
    el('status').textContent = 'Carregando propriedades disponíveis…';
    el('connect-panel').hidden = false; // Reauthorization stays reachable if listing fails.
    const data = await api('properties'); el('property').replaceChildren();
    data.properties.forEach(p => { const o = document.createElement('option'); o.value = p.id; o.textContent = `${p.name} (${p.id})`; el('property').append(o); });
    if (!data.properties.length) { el('status').textContent = 'A conta não retornou propriedades GA4. Confira o acesso no Google Analytics.'; return; }
    el('connect-panel').hidden = true; el('filters').hidden = false;
    const url = new URL(location.href), requested = url.searchParams.get('propriedade');
    const choice = data.properties.find(p => p.id === requested) || data.properties.find(p => /road\s*runners/i.test(p.name));
    if (choice) el('property').value = choice.id;
    if (['7','28','90'].includes(url.searchParams.get('dias'))) el('days').value = url.searchParams.get('dias');
    el('status').textContent = 'Selecione a propriedade do Road Runners e carregue os dados.';
    if (choice) await load();
  });
})();
