(function (root) {
  'use strict';
  const value = (row, key) => row[key] ?? row[key.toUpperCase()];
  const count = (row, key) => Math.max(0, Number(value(row, key)) || 0);
  const colors = {blue:'#81b8f4', gold:'#efbb55', ink:'#cdd4df', grid:'rgba(170,185,205,.12)'};
  function percentage(numerator, denominator) {
    const n = Number(numerator), d = Number(denominator);
    return Number.isFinite(n) && Number.isFinite(d) && d > 0 ? n / d * 100 : null;
  }
  function options() {
    const axis = {beginAtZero:true, stacked:false, ticks:{color:colors.ink, precision:0}, grid:{color:colors.grid}};
    return {responsive:true, maintainAspectRatio:false, animation:false,
      plugins:{legend:{position:'top',align:'start',labels:{color:colors.ink,boxWidth:12}},tooltip:{mode:'index',intersect:false}},
      scales:{x:{...axis,grid:{display:false}},y:{...axis}}};
  }
  function dailyChart(rows) {
    if (!rows.length) return null;
    // Only observed days: no history is invented before activation or over a gap.
    const type = rows.length >= 8 ? 'line' : 'bar';
    const series = (key,label,color,dash) => ({label,data:rows.map(row=>count(row,key)),
      borderColor:color,backgroundColor:color,borderWidth:2,pointRadius:2,tension:0,fill:false,borderDash:dash});
    return {type,data:{labels:rows.map(row=>String(value(row,'day')).slice(0,10).split('-').slice(1).reverse().join('/')),
      datasets:[series('pageviews','Aberturas de página',colors.blue,[]),series('slot_views','Posições visíveis',colors.gold,[5,3])]},options:options()};
  }
  function regionChart(rows) {
    const sorted = rows.filter(row=>count(row,'slot_views')>0).slice().sort((a,b)=>count(b,'slot_views')-count(a,'slot_views')).slice(0,6);
    if (!sorted.length) return null;
    const chartOptions = options();
    chartOptions.indexAxis='y'; chartOptions.plugins.legend.display=false;
    return {type:'bar',data:{labels:sorted.map(row=>value(row,'audience_uf')==='--'?'Desconhecida':value(row,'audience_uf')),
      datasets:[{label:'Posições visíveis',data:sorted.map(row=>count(row,'slot_views')),backgroundColor:colors.gold,borderColor:colors.gold,borderWidth:1}]},options:chartOptions};
  }
  function mountTabs(page, refreshCharts) {
    const navigation = page.querySelector('[data-audience-tabs]');
    if (!navigation) return;
    const tabs = Array.from(navigation.querySelectorAll('a[href^="#"]'));
    const panels = tabs.map(tab => root.document.getElementById(tab.hash.slice(1)));
    // Validate the complete group before hiding any server-rendered report.
    if (!tabs.length || panels.some(panel => !panel || !page.contains(panel))) return;
    let active = 0;
    function indexForHash(hash) {
      try {
        const target = root.document.getElementById(decodeURIComponent(hash.slice(1)));
        return target ? panels.findIndex(panel => panel === target || panel.contains(target)) : -1;
      } catch (_) { return -1; }
    }
    function activate(index, focus) {
      active = index;
      tabs.forEach((tab, i) => {
        tab.setAttribute('aria-selected', String(i === index));
        tab.tabIndex = i === index ? 0 : -1;
        panels[i].hidden = i !== index;
      });
      if (focus) tabs[index].focus();
      refreshCharts();
    }
    function navigate(index) {
      const hash = '#' + panels[index].id;
      if (root.location.hash !== hash) root.history.pushState(null, '', hash);
      activate(index, true);
    }
    tabs.forEach((tab, index) => {
      tab.id = panels[index].id + '-tab';
      tab.setAttribute('role', 'tab');
      tab.setAttribute('aria-controls', panels[index].id);
      panels[index].setAttribute('role', 'tabpanel');
      panels[index].setAttribute('aria-labelledby', tab.id);
      panels[index].tabIndex = 0;
      tab.addEventListener('click', event => {
        if (event.button !== 0 || event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) return;
        event.preventDefault(); navigate(index);
      });
      tab.addEventListener('keydown', event => {
        const keys = {ArrowRight:(index + 1) % tabs.length, ArrowLeft:(index + tabs.length - 1) % tabs.length, Home:0, End:tabs.length - 1};
        if (!Object.prototype.hasOwnProperty.call(keys, event.key)) return;
        event.preventDefault(); navigate(keys[event.key]);
      });
    });
    navigation.setAttribute('role', 'tablist');
    function restoreHash() {
      const index = indexForHash(root.location.hash);
      activate(index < 0 ? (root.location.hash ? active : 0) : index, false);
      // A legacy section anchor can be inside a previously hidden panel.
      if (index >= 0 && root.location.hash !== '#' + panels[index].id) {
        const target = root.document.getElementById(decodeURIComponent(root.location.hash.slice(1)));
        root.requestAnimationFrame(() => { if (target && !panels[index].hidden) target.scrollIntoView({block:'start'}); });
      }
    }
    root.addEventListener('hashchange', restoreHash);
    root.addEventListener('popstate', restoreHash);
    page.querySelectorAll('form[method="get"]').forEach(form => {
      form.addEventListener('submit', () => {
        const owner = panels.findIndex(panel => panel.contains(form));
        const index = owner < 0 ? active : owner;
        const hash = indexForHash(root.location.hash) === index ? root.location.hash : '#' + panels[index].id;
        form.setAttribute('action', (form.getAttribute('action') || '').split('#')[0] + hash);
      });
    });
    restoreHash();
  }
  function mount() {
    const page = root.document.querySelector('.audience-page');
    if (!page) return;
    const source = root.document.getElementById('audience-chart-data');
    let charts = [];
    try {
      const data = source ? JSON.parse(source.textContent) : {};
      charts = [['audience-daily-chart',dailyChart(data.daily || [])],['audience-region-chart',regionChart(data.regions || [])]].map(([id,model])=>({id,model,attempted:false}));
    } catch (_) { /* Tabs and exact tables do not depend on chart data. */ }
    function refreshCharts() {
      if (!root.mdb || !root.mdb.Chart) return;
      charts.forEach(chart => {
        const {id,model} = chart;
        const canvas = root.document.getElementById(id);
        if (!canvas || !model || chart.attempted) return;
        const panel = canvas.closest('[data-audience-panel]');
        if (panel && panel.hidden) return;
        const frame = canvas.closest('[data-audience-chart]');
        if (!frame) return;
        chart.attempted=true;
        frame.hidden=false;
        try { new root.mdb.Chart(canvas,{type:model.type,data:model.data},{options:model.options}); }
        catch (_) { frame.hidden=true; }
      });
      // MDB's responsive charts listen for size changes after their panel is shown.
      root.requestAnimationFrame(() => root.dispatchEvent(new Event('resize')));
    }
    mountTabs(page, refreshCharts);
    refreshCharts();
  }
  const api = {dailyChart, regionChart, percentage};
  if (typeof module === 'object' && module.exports) module.exports = api;
  else { root.BusinessAudienceDashboard = api;
    if (root.document.readyState === 'loading') root.document.addEventListener('DOMContentLoaded',mount,{once:true});
    else mount();
  }
})(typeof window !== 'undefined' ? window : globalThis);
