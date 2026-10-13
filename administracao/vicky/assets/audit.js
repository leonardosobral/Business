(function () {
  'use strict';
  var root = document.querySelector('[data-vp-audit]');
  if (!root) return;
  var scroll = root.querySelector('[data-vp-chat-scroll]');
  var turns = root.querySelector('[data-vp-turns]');
  var controls = root.querySelector('[data-vp-history-controls]');
  var status = root.querySelector('[data-vp-history-status]');
  if (!scroll || !turns || !controls) return;
  var highlighted = turns.querySelector('.is-highlighted');
  if (highlighted) scroll.scrollTop = highlighted.offsetTop - scroll.offsetTop;
  else scroll.scrollTop = scroll.scrollHeight;
  var loading = false;
  controls.addEventListener('click', async function (event) {
    var link = event.target.closest('[data-vp-older]');
    if (!link || !window.fetch || !window.DOMParser) return;
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || (typeof event.button === 'number' && event.button !== 0)) return;
    event.preventDefault();
    if (loading) return;
    loading = true;
    link.setAttribute('aria-disabled', 'true');
    link.setAttribute('aria-busy', 'true');
    status.textContent = 'Carregando interações anteriores…';
    try {
      var url = new URL(link.href, window.location.href);
      if (url.origin !== window.location.origin) throw new Error('invalid origin');
      var response = await fetch(url.href, {credentials: 'same-origin', cache: 'no-store'});
      if (!response.ok) throw new Error('HTTP ' + response.status);
      var parsed = new DOMParser().parseFromString(await response.text(), 'text/html');
      var incoming = parsed.querySelector('[data-vp-turns]');
      var nextControls = parsed.querySelector('[data-vp-history-controls]');
      if (!incoming || !nextControls || incoming.dataset.vpUserId !== turns.dataset.vpUserId) throw new Error('session or user changed');
      var previousHeight = scroll.scrollHeight;
      var previousTop = scroll.scrollTop;
      var added = 0;
      var fragment = document.createDocumentFragment();
      incoming.querySelectorAll('[data-vp-turn]').forEach(function (turn) {
        if (turns.querySelector('[data-vp-turn="' + turn.dataset.vpTurn + '"]')) return;
        fragment.appendChild(document.importNode(turn, true));
        added++;
      });
      if (!added) throw new Error('no older content');
      turns.prepend(fragment);
      controls.replaceChildren();
      var next = nextControls.querySelector('[data-vp-older]');
      var focusTarget = status;
      if (next) {
        focusTarget = document.importNode(next, true);
        controls.appendChild(focusTarget);
      }
      else {
        var start = document.createElement('p');
        start.className = 'vp-audit-start';
        start.textContent = 'Início do histórico disponível neste recorte';
        controls.appendChild(start);
      }
      status.textContent = added + ' interação(ões) anteriores carregadas.';
      scroll.scrollTop = previousTop + scroll.scrollHeight - previousHeight;
      if (focusTarget === status) status.setAttribute('tabindex', '-1');
      focusTarget.focus({preventScroll: true});
      var footer = root.querySelector('.vp-audit-chat-foot');
      if (footer) footer.firstChild.textContent = turns.querySelectorAll('[data-vp-turn]').length + ' interações carregadas · até 20 por carregamento ';
    } catch (error) {
      status.textContent = 'Não foi possível carregar. Tente novamente ou abra o link em outra aba.';
      link.removeAttribute('aria-disabled');
      link.removeAttribute('aria-busy');
    } finally {
      loading = false;
    }
  });
})();
