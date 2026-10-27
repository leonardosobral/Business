(function (root, factory) {
  'use strict';
  var api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root.document) {
    if (root.document.readyState === 'loading') root.document.addEventListener('DOMContentLoaded', api.init);
    else api.init();
  }
}(typeof window !== 'undefined' ? window : {}, function () {
  'use strict';
  var labels = {
    domain: 'domínio', traffic: 'tráfego orgânico', trafficChange: 'variação do tráfego (%)',
    keywords: 'palavras-chave orgânicas', keywordsChange: 'variação de palavras-chave (%)',
    refDomains: 'domínios de referência', refDomainsChange: 'variação de referências (%)',
    authority: 'Authority Score', authorityChange: 'variação do Authority Score (pontos)',
    paidKeywords: 'palavras-chave pagas', paidKeywordsChange: 'variação de palavras-chave pagas (%)',
    paidTraffic: 'tráfego pago', paidTrafficChange: 'variação do tráfego pago (%)'
  };
  function numeric(value) {
    if (value === null || value === undefined || String(value).trim() === '') return null;
    var result = Number(value);
    return Number.isFinite(result) ? result : null;
  }
  function valueOf(row, key) {
    if (key === 'domain') return row.domain;
    var change = /Change$/.test(key), base = key.replace(/Change$/, ''), metric = row.metrics[base];
    return metric ? numeric(metric[change ? 'change' : 'value']) : null;
  }
  function compare(a, b, key, direction) {
    var left = valueOf(a, key), right = valueOf(b, key), sign = direction === 'asc' ? 1 : -1;
    // Missing values remain last in either direction, distinct from measured zero.
    if (left === null && right !== null) return 1;
    if (right === null && left !== null) return -1;
    var delta = left === null ? 0 : (key === 'domain' ? left.localeCompare(right, 'pt-BR') : left - right);
    return delta ? delta * sign : a.domain.localeCompare(b.domain, 'pt-BR');
  }
  function matches(row, state) {
    if (state.search && row.domain.toLowerCase().indexOf(state.search.toLowerCase()) === -1) return false;
    if (state.group === 'own' && !row.own || state.group === 'reference' && row.own) return false;
    var change = valueOf(row, 'trafficChange');
    return state.trend === 'all' || state.trend === 'unknown' && change === null ||
      state.trend === 'up' && change !== null && change > 0 ||
      state.trend === 'down' && change !== null && change < 0 || state.trend === 'flat' && change === 0;
  }
  function readState(params) {
    var key = params.get('dominio_ordem');
    return {
      search: (params.get('dominio_busca') || '').slice(0, 100).trim(),
      group: ['own', 'reference'].indexOf(params.get('dominio_grupo')) >= 0 ? params.get('dominio_grupo') : 'all',
      trend: ['up', 'down', 'flat', 'unknown'].indexOf(params.get('dominio_sinal')) >= 0 ? params.get('dominio_sinal') : 'all',
      key: Object.prototype.hasOwnProperty.call(labels, key) ? key : 'traffic',
      direction: params.get('dominio_direcao') === 'asc' ? 'asc' : 'desc'
    };
  }
  function init() {
    var section = document.querySelector('[data-domains-dashboard]');
    if (!section || section.dataset.initialized === 'true') return;
    section.dataset.initialized = 'true';
    var form = section.querySelector('[data-domain-controls]'), search = section.querySelector('#sd-search'),
      group = section.querySelector('#sd-group'), trend = section.querySelector('#sd-trend'),
      order = section.querySelector('#sd-order'), directionButton = section.querySelector('#sd-direction'),
      status = section.querySelector('#sd-status'), empty = section.querySelector('#sd-empty'),
      body = section.querySelector('tbody'), direction = 'desc';
    var rows = Array.from(body.querySelectorAll('[data-domain-row]')).map(function (el) {
      var metrics = {};
      el.querySelectorAll('[data-metric]').forEach(function (cell) {
        metrics[cell.dataset.metric] = {value: numeric(cell.dataset.value), change: numeric(cell.dataset.change)};
      });
      return {el: el, domain: el.dataset.domain, own: el.dataset.own === 'true', metrics: metrics};
    });
    function restore() {
      var state = readState(new URLSearchParams(window.location.search));
      search.value = state.search; group.value = state.group; trend.value = state.trend;
      order.value = state.key; direction = state.direction;
    }
    function render(writeUrl) {
      var state = {search: search.value.slice(0, 100).trim(), group: group.value, trend: trend.value, key: order.value, direction: direction};
      var visible = 0;
      rows.slice().sort(function (a, b) { return compare(a, b, state.key, state.direction); }).forEach(function (row) {
        row.el.hidden = !matches(row, state);
        if (!row.el.hidden) visible++;
        body.appendChild(row.el);
      });
      empty.hidden = visible !== 0;
      var alpha = state.key === 'domain';
      directionButton.textContent = alpha ? (direction === 'asc' ? 'A → Z' : 'Z → A') : (direction === 'asc' ? 'Menor → maior' : 'Maior → menor');
      status.textContent = visible + ' de ' + rows.length + ' domínios · ordenados por ' + labels[state.key] + ', ' + directionButton.textContent.toLowerCase() + '.';
      section.querySelectorAll('[data-domain-column]').forEach(function (th) {
        var active = th.dataset.domainColumn === state.key.replace(/Change$/, ''), change = /Change$/.test(state.key);
        th.removeAttribute('aria-sort');
        if (active) th.setAttribute('aria-sort', change ? 'other' : (direction === 'asc' ? 'ascending' : 'descending'));
        th.querySelector('span').textContent = active ? (direction === 'asc' ? '↑' : '↓') : '↕';
        th.querySelector('button').setAttribute('aria-label', 'Ordenar por ' + labels[th.dataset.domainColumn] + (active && change ? '; atualmente ordenado pela variação' : ''));
      });
      if (writeUrl) {
        var url = new URL(window.location.href);
        [['dominio_busca', state.search], ['dominio_grupo', state.group === 'all' ? '' : state.group],
          ['dominio_sinal', state.trend === 'all' ? '' : state.trend], ['dominio_ordem', state.key === 'traffic' ? '' : state.key],
          ['dominio_direcao', direction === 'desc' ? '' : direction]].forEach(function (pair) {
          if (pair[1]) url.searchParams.set(pair[0], pair[1]); else url.searchParams.delete(pair[0]);
        });
        try { window.history.replaceState(null, '', url); } catch (_) { /* Sorting remains available if history is restricted. */ }
      }
    }
    restore(); render(false);
    form.addEventListener('submit', function (event) { event.preventDefault(); render(true); });
    search.addEventListener('input', function () { render(true); });
    [group, trend, order].forEach(function (input) { input.addEventListener('change', function () { render(true); }); });
    directionButton.addEventListener('click', function () { direction = direction === 'asc' ? 'desc' : 'asc'; render(true); });
    section.querySelectorAll('[data-domain-sort]').forEach(function (button) {
      button.addEventListener('click', function () {
        var key = button.dataset.domainSort;
        direction = order.value === key ? (direction === 'asc' ? 'desc' : 'asc') : (key === 'domain' ? 'asc' : 'desc');
        order.value = key; render(true);
      });
    });
    form.addEventListener('reset', function (event) {
      event.preventDefault(); search.value = ''; group.value = 'all'; trend.value = 'all'; order.value = 'traffic'; direction = 'desc'; render(true);
    });
    window.addEventListener('popstate', function () { restore(); render(false); });
  }
  return {numeric: numeric, valueOf: valueOf, compare: compare, matches: matches, readState: readState, init: init};
}));
