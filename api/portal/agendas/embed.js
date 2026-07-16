(function () {
  'use strict';

  var script = document.currentScript;
  if (!script) return;

  var agendaKey = (script.getAttribute('data-agenda') || '').trim();
  var view = (script.getAttribute('data-view') || 'futuros').toLowerCase();
  var targetId = (script.getAttribute('data-target') || '').trim();
  var title = (script.getAttribute('data-title') || 'Agenda de eventos Road Runners').trim();
  var sourceUrl = new URL(script.src, window.location.href);
  var apiOrigin = sourceUrl.origin;
  var target = targetId ? document.getElementById(targetId) : null;

  if (!agendaKey) {
    console.error('[Road Runners Agenda] Informe data-agenda no script de incorporacao.');
    return;
  }

  if (view !== 'futuros' && view !== 'resultados') view = 'futuros';

  if (!target) {
    target = document.createElement('div');
    script.parentNode.insertBefore(target, script);
  }

  var embedId = 'rr-agenda-' + Math.random().toString(36).slice(2, 12);
  var frame = document.createElement('iframe');
  frame.src = apiOrigin + '/api/portal/agendas/render.cfm?agenda=' + encodeURIComponent(agendaKey) + '&visao=' + encodeURIComponent(view) + '&embed_id=' + encodeURIComponent(embedId);
  frame.title = title;
  frame.loading = 'lazy';
  frame.referrerPolicy = 'strict-origin-when-cross-origin';
  frame.sandbox = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
  frame.setAttribute('scrolling', 'no');
  frame.setAttribute('allowtransparency', 'true');
  frame.style.setProperty('background', 'transparent', 'important');
  frame.style.setProperty('box-sizing', 'border-box', 'important');
  frame.style.setProperty('display', 'block', 'important');
  frame.style.setProperty('width', '100%', 'important');
  frame.style.setProperty('min-width', '0', 'important');
  frame.style.setProperty('max-width', '680px', 'important');
  frame.style.setProperty('height', '240px', 'important');
  frame.style.setProperty('border', '0', 'important');
  frame.style.setProperty('margin', '0 auto', 'important');
  frame.style.setProperty('overflow', 'hidden', 'important');

  target.setAttribute('data-rr-agenda-ready', 'true');
  target.style.setProperty('background', 'transparent', 'important');
  target.style.setProperty('box-sizing', 'border-box', 'important');
  target.style.setProperty('display', 'block', 'important');
  target.style.setProperty('width', '100%', 'important');
  target.style.setProperty('min-width', '0', 'important');
  target.style.setProperty('max-width', '680px', 'important');
  target.style.setProperty('margin', '0 auto', 'important');
  target.style.setProperty('overflow', 'hidden', 'important');
  target.replaceChildren(frame);

  window.addEventListener('message', function (event) {
    if (event.origin !== apiOrigin || event.source !== frame.contentWindow) return;
    if (!event.data || event.data.type !== 'rr-agenda:resize' || event.data.embedId !== embedId) return;
    var height = Math.max(120, Math.min(12000, Number(event.data.height) || 240));
    frame.style.setProperty('height', Math.ceil(height) + 'px', 'important');
  });
})();
