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
  function mount() {
    const source = root.document.getElementById('audience-chart-data');
    if (!source || !root.mdb || !root.mdb.Chart) return; // Exact tables remain usable without JS.
    try {
      const data = JSON.parse(source.textContent);
      [['audience-daily-chart',dailyChart(data.daily)],['audience-region-chart',regionChart(data.regions)]].forEach(([id,model])=>{
        const canvas = root.document.getElementById(id);
        if (!canvas || !model) return;
        const frame = canvas.closest('[data-audience-chart]');
        frame.hidden=false;
        try { new root.mdb.Chart(canvas,{type:model.type,data:model.data},{options:model.options}); }
        catch (_) { frame.hidden=true; }
      });
    } catch (_) { /* Failure must not hide metrics, filters or data tables. */ }
  }
  const api = {dailyChart, regionChart, percentage};
  if (typeof module === 'object' && module.exports) module.exports = api;
  else { root.BusinessAudienceDashboard = api;
    if (root.document.readyState === 'loading') root.document.addEventListener('DOMContentLoaded',mount,{once:true});
    else mount();
  }
})(typeof window !== 'undefined' ? window : globalThis);
