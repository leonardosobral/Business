/* RoadRunners Ads SDK v1. Public identifiers only; no cookies or local storage. */
(function () {
  'use strict';
  if (window.RoadRunnersAds) { window.RoadRunnersAds.scan(); return; }
  const base = 'https://ads.roadrunners.run';
  const tracked = new Set();
  const claimed = new WeakSet();
  const https = value => { try { const u = new URL(value); return u.protocol === 'https:' && !u.username && !u.password; } catch (_) { return false; } };
  async function post(path, values) {
    const control = new AbortController();
    const timeout = setTimeout(() => control.abort(), path === 'serve' ? 8000 : 2500);
    try {
      const response = await fetch(base + '/v1/' + path + '.cfm', {
        method: 'POST', body: new URLSearchParams(values), credentials: 'omit',
        mode: 'cors', cache: 'no-store', keepalive: path !== 'serve', signal: control.signal
      });
      if (!response.ok) throw new Error('Ads unavailable');
      return await response.json();
    } finally { clearTimeout(timeout); }
  }
  function visible(state) {
    if (document.visibilityState !== 'visible' || !state.box.isConnected || state.ratio < 0.5 || !state.img.complete || !state.img.naturalWidth) return false;
    const rect = state.box.getBoundingClientRect();
    if (!rect.width || !rect.height) return false;
    for (let n = state.box; n; n = n.parentElement) {
      const css = getComputedStyle(n);
      if (css.display === 'none' || css.visibility === 'hidden' || css.visibility === 'collapse' || Number(css.opacity) === 0) return false;
    }
    return true;
  }
  function cancel(state) { clearTimeout(state.timer); state.timer = 0; }
  function check(state) {
    if (!visible(state)) { cancel(state); return; }
    if (state.viewed || state.timer || state.sending || state.attempts >= 3) return;
    state.timer = setTimeout(async () => {
      state.timer = 0;
      if (!visible(state)) return;
      state.attempts++;
      state.sending = post('viewable', state.receipt);
      try {
        const result = await state.sending;
        state.viewed = ['recorded', 'already_recorded'].includes(result.status);
        if (state.viewed) { observer.unobserve(state.box); tracked.delete(state); }
      } catch (_) { /* Retry the same receipt, never mint a second impression. */ }
      finally { state.sending = null; if (!state.viewed) check(state); }
    }, 1000);
  }
  const states = new WeakMap();
  const observer = 'IntersectionObserver' in window ? new IntersectionObserver(entries => {
    entries.forEach(entry => { const state = states.get(entry.target); if (state) { state.ratio = entry.isIntersecting ? entry.intersectionRatio : 0; check(state); } });
  }, { threshold: [0, 0.5, 1] }) : null;
  async function load(box) {
    if (claimed.has(box)) return;
    claimed.add(box);
    box.dataset.rrAdsStatus = 'loading';
    try {
      const ad = await post('serve', { site: box.dataset.rrAdsSite || '', spot: box.dataset.rrAdsSpot || '' });
      if (ad.status !== 'served') { box.dataset.rrAdsStatus = 'empty'; return; }
      if (!https(ad.destination) || !https(ad.desktop) || !https(ad.mobile)) throw new Error('Invalid creative');
      const frame = document.createElement('div');
      frame.style.cssText = 'display:block;width:100%;max-width:' + Math.max(50, Math.min(2400, Number(ad.width) || 300)) + 'px;margin:0 auto;';
      const label = document.createElement('div'); label.textContent = 'Publicidade'; label.style.cssText = 'font:11px/1.5 sans-serif;color:inherit;opacity:.7;';
      const link = document.createElement('a'); link.href = ad.destination; link.rel = 'sponsored noopener noreferrer';
      link.style.cssText = 'display:block;'; if (ad.newTab) link.target = '_blank';
      const picture = document.createElement('picture');
      const source = document.createElement('source'); source.media = '(max-width: 767px)'; source.srcset = ad.mobile;
      const img = document.createElement('img'); img.src = ad.desktop; img.alt = ad.alt || 'Publicidade';
      img.width = Number(ad.width) || 300; img.height = Number(ad.height) || 250;
      img.style.cssText = 'display:block;width:100%;height:auto;object-fit:contain;'; img.referrerPolicy = 'no-referrer';
      picture.append(source, img); link.append(picture); frame.append(label, link); box.replaceChildren(frame);
      const state = { box: link, img, ratio: 0, viewed: false, timer: 0, sending: null, attempts: 0, receipt: { delivery: ad.delivery, token: ad.token } };
      states.set(link, state); tracked.add(state);
      if (observer) observer.observe(link);
      img.addEventListener('load', () => check(state));
      img.addEventListener('error', () => { cancel(state); box.dataset.rrAdsStatus = 'error'; });
      async function click(event) {
        if (!event.isTrusted || (event.type === 'auxclick' && event.button !== 1)) return;
        event.preventDefault();
        const newTab = ad.newTab || event.ctrlKey || event.metaKey || event.shiftKey || event.button === 1;
        const target = newTab ? window.open('about:blank', '_blank') : null;
        if (target) target.opener = null;
        try {
          // Wait for an in-flight genuine view receipt; a quick click is not an impression.
          if (state.sending) await state.sending.catch(() => {});
          await post('click', state.receipt);
        } catch (_) { /* A tracking failure must not prevent visiting the advertiser. */ }
        finally { if (target) target.location.replace(ad.destination); else if (!newTab) window.location.assign(ad.destination); }
      }
      link.addEventListener('click', click); link.addEventListener('auxclick', click);
      box.dataset.rrAdsStatus = 'served';
    } catch (_) { box.dataset.rrAdsStatus = 'error'; }
  }
  function scan() { document.querySelectorAll('[data-rr-ads-site][data-rr-ads-spot]').forEach(load); }
  document.addEventListener('visibilitychange', () => tracked.forEach(s => { cancel(s); check(s); }));
  window.addEventListener('pagehide', () => tracked.forEach(cancel));
  window.RoadRunnersAds = { scan };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', scan, { once: true }); else scan();
}());
