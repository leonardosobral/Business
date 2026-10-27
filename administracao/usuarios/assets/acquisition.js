(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else {
    const start = () => api.mount(root.document);
    if (root.document.readyState === 'loading') root.document.addEventListener('DOMContentLoaded', start);
    else start();
  }
})(typeof window === 'object' ? window : globalThis, function () {
  'use strict';
  const periods = [7, 30, 90, 365];
  const number = new Intl.NumberFormat('pt-BR');
  const averageNumber = new Intl.NumberFormat('pt-BR', {maximumFractionDigits: 1});
  const date = (day, year = true) => new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit', month: '2-digit', ...(year ? {year: 'numeric'} : {}), timeZone: 'UTC'
  }).format(new Date(day + 'T12:00:00Z'));
  function select(rows, value) {
    const days = (typeof value === 'number' || typeof value === 'string') && periods.includes(Number(value)) ? Number(value) : 30;
    return rows.slice(-days);
  }
  function summarize(rows) {
    let total = 0, peak = 0, peakDay = '';
    for (const row of rows) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(row.day) || !Number.isSafeInteger(row.count) || row.count < 0) throw new Error('Invalid acquisition series');
      total += row.count;
      if (row.count > peak) { peak = row.count; peakDay = row.day; }
    }
    return {total, average: rows.length ? total / rows.length : 0, peak, peakDay};
  }
  function geometry(rows, width, height) {
    const peak = Math.max(0, ...rows.map(row => row.count));
    const raw = Math.max(1, peak / 4), power = 10 ** Math.floor(Math.log10(raw));
    const step = Math.ceil(raw / power) * power, maximum = step * 4;
    const left = 52, right = Math.max(left + 20, width - 16), top = 18, bottom = height - 34;
    const points = rows.map((row, index) => ({
      x: left + (right - left) * (rows.length > 1 ? index / (rows.length - 1) : 0.5),
      y: bottom - (bottom - top) * row.count / maximum
    }));
    return {left, right, top, bottom, maximum, points, width, height};
  }
  function mount(document) {
    const root = document.querySelector('[data-user-acquisition]');
    if (!root || root.dataset.mounted) return;
    root.dataset.mounted = 'true';
    const plot = root.querySelector('[data-acquisition-plot]');
    const tooltip = root.querySelector('[data-acquisition-tooltip]');
    const announcements = root.querySelector('[data-acquisition-announcement]');
    const svg = root.querySelector('svg');
    const field = name => root.querySelector('[data-acquisition-' + name + ']');
    let all, rows, layout, marker, guide, index = 0, selectedDays = Number(root.dataset.days) || 30;
    function element(name, attributes, text) {
      const node = document.createElementNS('http://www.w3.org/2000/svg', name);
      for (const [key, value] of Object.entries(attributes)) node.setAttribute(key, value);
      if (text !== undefined) node.textContent = text;
      return node;
    }
    function active(next, announce = false) {
      if (!layout || !rows.length) return;
      index = Math.max(0, Math.min(rows.length - 1, next));
      const point = layout.points[index], row = rows[index];
      marker.setAttribute('cx', point.x); marker.setAttribute('cy', point.y); marker.removeAttribute('hidden');
      guide.setAttribute('x1', point.x); guide.setAttribute('x2', point.x); guide.removeAttribute('hidden');
      tooltip.textContent = date(row.day) + ': ' + number.format(row.count) + ' novo(s) usuário(s)';
      tooltip.hidden = false;
      tooltip.style.left = Math.max(0, Math.min(layout.width - tooltip.offsetWidth, point.x - tooltip.offsetWidth / 2)) + 'px';
      if (announce) announcements.textContent = tooltip.textContent;
    }
    function draw() {
      const width = Math.max(260, plot.getBoundingClientRect().width);
      layout = geometry(rows, width, 250);
      svg.setAttribute('viewBox', '0 0 ' + width + ' 250');
      svg.replaceChildren();
      for (let tick = 0; tick <= 4; tick++) {
        const y = layout.bottom - (layout.bottom - layout.top) * tick / 4;
        svg.append(element('line', {x1: layout.left, x2: layout.right, y1: y, y2: y, class: 'acq-grid'}));
        svg.append(element('text', {x: layout.left - 10, y: y + 4, 'text-anchor': 'end', class: 'acq-label'}, number.format(layout.maximum * tick / 4)));
      }
      const line = layout.points.map((point, i) => (i ? 'L' : 'M') + point.x + ',' + point.y).join(' ');
      if (layout.points.length) {
        svg.append(element('path', {d: line + ' L' + layout.points.at(-1).x + ',' + layout.bottom + ' L' + layout.points[0].x + ',' + layout.bottom + ' Z', class: 'acq-area'}));
        svg.append(element('path', {d: line, class: 'acq-line'}));
        if (rows.length <= 30) for (const point of layout.points) svg.append(element('circle', {cx: point.x, cy: point.y, r: 2, class: 'acq-point'}));
      }
      const ticks = Math.max(2, Math.min(7, Math.floor(width / 105)));
      for (let tick = 0; tick < ticks; tick++) {
        const at = Math.round((rows.length - 1) * tick / (ticks - 1));
        svg.append(element('text', {x: layout.points[at].x, y: 241, 'text-anchor': tick === 0 ? 'start' : (tick === ticks - 1 ? 'end' : 'middle'), class: 'acq-label'}, date(rows[at].day, false)));
      }
      guide = element('line', {x1: 0, x2: 0, y1: layout.top, y2: layout.bottom, class: 'acq-guide', hidden: ''});
      marker = element('circle', {r: 5, class: 'acq-marker', hidden: ''});
      svg.append(guide, marker); tooltip.hidden = true;
    }
    function render(days) {
      selectedDays = periods.includes(Number(days)) ? Number(days) : 30;
      rows = select(all, selectedDays); const metrics = summarize(rows);
      field('total').textContent = number.format(metrics.total);
      field('average').textContent = averageNumber.format(metrics.average);
      field('peak').textContent = number.format(metrics.peak);
      field('peak-day').textContent = metrics.peakDay ? date(metrics.peakDay) : 'Sem cadastros';
      field('range').textContent = date(rows[0].day) + ' a ' + date(rows.at(-1).day) + ' · hoje parcial';
      field('empty').hidden = metrics.total !== 0;
      root.dataset.days = String(selectedDays);
      root.querySelectorAll('[data-acquisition-period]').forEach(button => {
        const current = Number(button.dataset.acquisitionPeriod) === selectedDays;
        button.setAttribute('aria-pressed', String(current)); button.classList.toggle('is-selected', current);
      });
      const body = field('table-body'), fragment = document.createDocumentFragment();
      for (const row of rows) {
        const tr = document.createElement('tr'), day = document.createElement('th'), count = document.createElement('td');
        day.scope = 'row'; day.textContent = date(row.day); count.textContent = number.format(row.count);
        tr.append(day, count); fragment.append(tr);
      }
      body.replaceChildren(fragment); index = rows.length - 1; draw();
      const input = document.querySelector('[data-user-list-filters] input[name="aquisicao_dias"]');
      if (input) input.value = String(selectedDays);
      document.querySelectorAll('[data-user-pagination] a').forEach(link => {
        const url = new URL(link.href, document.baseURI); url.searchParams.set('aquisicao_dias', String(selectedDays)); link.href = url.href;
      });
    }
    try {
      all = JSON.parse(root.querySelector('[data-acquisition-data]').textContent);
      if (!Array.isArray(all) || all.length !== 365) throw new Error('Incomplete acquisition series');
      summarize(all); render(selectedDays);
      root.querySelectorAll('[data-acquisition-period]').forEach(button => {
        button.addEventListener('click', event => {
          event.preventDefault(); render(Number(button.dataset.acquisitionPeriod));
          const url = new URL(document.location.href); url.searchParams.set('aquisicao_dias', String(selectedDays));
          try { document.defaultView.history.replaceState(null, '', url); } catch (_) { /* Navigation links remain usable. */ }
        });
        button.addEventListener('keydown', event => {
          if (event.key === ' ') { event.preventDefault(); button.click(); }
        });
      });
      plot.addEventListener('pointermove', event => {
        const box = plot.getBoundingClientRect(), x = (event.clientX - box.left) * layout.width / box.width;
        active(Math.round((x - layout.left) / (layout.right - layout.left) * (rows.length - 1)));
      });
      plot.addEventListener('pointerleave', () => { if (document.activeElement !== plot) { tooltip.hidden = true; marker.setAttribute('hidden', ''); guide.setAttribute('hidden', ''); } });
      plot.addEventListener('focus', () => active(index, true));
      plot.addEventListener('blur', () => { tooltip.hidden = true; marker.setAttribute('hidden', ''); guide.setAttribute('hidden', ''); });
      plot.addEventListener('keydown', event => {
        const next = {ArrowLeft: index - 1, ArrowRight: index + 1, Home: 0, End: rows.length - 1};
        if (Object.hasOwn(next, event.key)) { event.preventDefault(); active(next[event.key], true); }
      });
      if (document.defaultView.ResizeObserver) new document.defaultView.ResizeObserver(draw).observe(plot);
    } catch (_) {
      plot.hidden = true; field('error').hidden = false;
    }
  }
  return {select, summarize, geometry, mount};
});
