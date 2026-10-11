/* Coordinate optional invitations. Privacy choices and user-triggered dialogs stay independent. */
(function (window, document) {
  'use strict';
  if (window.RREntryPrompts) return;
  var startedAt = Date.now(), engaged = false, timer = 0, queue = [], running = false;
  var sessionKey = 'rr.entry.optionalPrompt.v1';
  var shown = false;
  try { shown = window.sessionStorage.getItem(sessionKey) === '1'; } catch (_) {}
  function blocked() {
    var focused = document.activeElement;
    return document.hidden || document.body.classList.contains('rr-mobile-onboarding-open')
      || !!document.querySelector('.modal.show, .modal-backdrop, .offcanvas.show, .dropdown-menu.show, .rr-pwa-sheet, [data-audience-privacy-dialog]:not([hidden]), #rrCookieNotice:not([hidden]), #rrPwaUpdateToast, #rrPwaPushPrompt, #rrPwaInstallPrompt')
      || !!(focused && focused.matches('input, textarea, select, [contenteditable="true"]'));
  }
  function schedule() {
    if (timer || shown || !queue.length) return;
    timer = window.setTimeout(run, 1000);
  }
  async function run() {
    timer = 0;
    if (shown || running) return;
    if (!engaged || document.hidden) return;
    if (Date.now() - startedAt < 20000 || blocked()) { schedule(); return; }
    queue.sort(function (a, b) { return b.priority - a.priority; });
    var item = queue.shift();
    if (!item) return;
    running = true;
    try {
      if (await item.show() !== false) {
        shown = true;
        try { window.sessionStorage.setItem(sessionKey, '1'); } catch (_) {}
      }
    } catch (_) {}
    running = false;
    schedule();
  }
  function engage(event) {
    if (event.isTrusted === false) return;
    engaged = true;
    schedule();
  }
  ['pointerdown', 'keydown', 'scroll'].forEach(function (name) { window.addEventListener(name, engage, {passive: true}); });
  document.addEventListener('visibilitychange', schedule);
  window.RREntryPrompts = {
    blocked: blocked,
    enqueue: function (id, show, priority) {
      if (shown || queue.some(function (item) { return item.id === id; })) return;
      queue.push({id: id, show: show, priority: priority || 0});
      schedule();
    }
  };
}(window, document));
