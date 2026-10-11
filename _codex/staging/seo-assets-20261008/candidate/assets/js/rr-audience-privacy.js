/* First-party audience preference controls. Independent from login and Ads cookies. */
(function (window, document) {
    'use strict';
    if (window.RoadRunnersAudiencePrivacy) return;
    var root = document.querySelector('[data-audience-privacy-root]');
    if (!root) return;
    var openButtons = Array.prototype.slice.call(document.querySelectorAll('[data-audience-privacy-open]'));
    var dialog = document.querySelector('[data-audience-privacy-dialog]');
    var closeButton = document.querySelector('[data-audience-privacy-close]');
    var allowButton = document.querySelector('[data-audience-privacy-allow]');
    var denyButton = document.querySelector('[data-audience-privacy-deny]');
    var status = document.querySelector('[data-audience-privacy-status]');
    var feedback = document.querySelector('[data-audience-privacy-feedback]');
    var returnFocus = null;
    var transientDenied = false;

    function storageGet() { try { return window.localStorage.getItem('rr-audience-opt-out') || ''; } catch (_) { return ''; } }
    function cookieDenied() { try { return /(?:^|;\s*)rr-audience-opt-out=(?:1|true|yes)(?:;|$)/i.test(document.cookie || ''); } catch (_) { return false; } }
    function storedDenied() { return /^(1|true|yes)$/i.test(storageGet()) || cookieDenied(); }
    function denied() { return transientDenied || storedDenied(); }
    function gpc() { return window.navigator.globalPrivacyControl === true; }
    function state() { return gpc() ? 'gpc' : denied() ? 'denied' : 'allowed'; }
    function clearIdentifiers() {
        try {
            window.localStorage.removeItem('rr-audience-visitor');
            window.localStorage.removeItem('rr-audience-visitor-created');
            window.localStorage.removeItem('rr-audience-session');
        } catch (_) {}
    }
    function update() {
        var current = state();
        if (current !== 'allowed') clearIdentifiers();
        status.textContent = current === 'gpc' ? root.dataset.statusGpc : current === 'denied' ? root.dataset.statusDenied : root.dataset.statusAllowed;
        allowButton.disabled = current === 'gpc';
        allowButton.setAttribute('aria-pressed', current === 'allowed' ? 'true' : 'false');
        denyButton.setAttribute('aria-pressed', current === 'denied' || current === 'gpc' ? 'true' : 'false');
        root.dataset.audiencePrivacyState = current;
        return current;
    }
    function setExpanded(value) {
        openButtons.forEach(function (button) { button.setAttribute('aria-expanded', value); });
    }
    function open(event) {
        returnFocus = event && event.currentTarget ? event.currentTarget : document.activeElement || openButtons[0] || null;
        dialog.hidden = false;
        dialog.setAttribute('aria-hidden', 'false');
        setExpanded('true');
        root.dataset.audiencePrivacyOpen = 'true';
        update();
        closeButton.focus();
    }
    function close() {
        if (dialog.hidden) return;
        dialog.hidden = true;
        dialog.setAttribute('aria-hidden', 'true');
        setExpanded('false');
        delete root.dataset.audiencePrivacyOpen;
        if (returnFocus && typeof returnFocus.focus === 'function') returnFocus.focus();
    }
    function persist(allowed) {
        if (allowed && gpc()) return false;
        transientDenied = !allowed;
        try {
            if (allowed) window.localStorage.removeItem('rr-audience-opt-out');
            else window.localStorage.setItem('rr-audience-opt-out', 'true');
        } catch (_) {}
        try {
            // Host-only on purpose: this control must not alter auth or Ads cookies on sibling hosts.
            document.cookie = allowed
                ? 'rr-audience-opt-out=; Max-Age=0; Path=/; SameSite=Lax; Secure'
                : 'rr-audience-opt-out=true; Max-Age=31536000; Path=/; SameSite=Lax; Secure';
        } catch (_) {}
        var consistent = allowed ? !storedDenied() : storedDenied();
        feedback.textContent = consistent ? (allowed ? root.dataset.savedAllowed : root.dataset.savedDenied) : root.dataset.saveUnavailable;
        window.dispatchEvent(new CustomEvent('rr-audience-preference', { detail: { allowed: allowed } }));
        update();
        if (consistent) window.location.reload();
        return consistent;
    }

    openButtons.forEach(function (button) { button.addEventListener('click', open); });
    closeButton.addEventListener('click', close);
    allowButton.addEventListener('click', function () { persist(true); });
    denyButton.addEventListener('click', function () { persist(false); });
    dialog.addEventListener('click', function (event) { if (event.target === dialog) close(); });
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape' && !dialog.hidden) { event.preventDefault(); close(); }
        if (event.key === 'Tab' && !dialog.hidden) {
            var focusable = Array.prototype.slice.call(dialog.querySelectorAll('button:not([disabled]), a[href]'));
            if (!focusable.length) return;
            var first = focusable[0], last = focusable[focusable.length - 1];
            if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
            else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
        }
    });
    window.addEventListener('storage', function (event) {
        if (event && event.key === 'rr-audience-opt-out') update();
    });

    window.RoadRunnersAudiencePrivacy = { getState: state, open: open, close: close, setAllowed: persist, refresh: update };
    update();
}(window, document));
