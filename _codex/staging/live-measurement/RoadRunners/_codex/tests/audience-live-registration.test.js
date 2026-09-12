const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const trackerPath = path.resolve(__dirname, '../../assets/js/rr-audience.js');

function harness(options = {}) {
    let now = 0;
    const slots = [], requests = [], listeners = {}, timers = new Map();
    const storage = new Map(Object.entries(options.storage || {}));
    let sequence = 0, intersectionObserver;
    const doc = { visibilityState: 'visible', readyState: 'complete', referrer: 'https://example.org/story?private=1', cookie: '',
        documentElement: { clientWidth: 1200, clientHeight: 900 },
        addEventListener(type, callback) { (listeners[type] ||= []).push(callback); },
        querySelectorAll(selector) { return selector === '[data-audience-slot]' ? slots : []; } };
    if (options.cookieThrows) Object.defineProperty(doc, 'cookie', { get() { throw Error('cookies blocked'); } });
    const win = { document: doc, innerWidth: 1200, innerHeight: 900, location: new URL('https://roadrunners.run/busca/?estado=SC&utm_source=newsletter&utm_campaign=run'),
        RoadRunnersAudienceConfig: { endpoint: '/api/analytics/collect.cfm', contextToken: 'signed-context', signature: 'signature', context: { pageViewId: '11111111-1111-4111-8111-111111111111', visitorUf: 'SP', contextUf: 'SC', marketUf: 'SC', contentType: '', contentId: '' } },
        navigator: { globalPrivacyControl: options.gpc || false, sendBeacon(url, body) { requests.push({ url, body: JSON.parse(body) }); return true; } },
        localStorage: {
            getItem(k) { if (options.storageThrows) throw Error('blocked'); return storage.get(k) || null; },
            setItem(k, v) { if (options.storageThrows) throw Error('blocked'); storage.set(k, v); },
            removeItem(k) { if (options.storageThrows) throw Error('blocked'); storage.delete(k); }
        },
        crypto: require('node:crypto').webcrypto, performance: { now: () => now },
        setInterval(callback, delay) { timers.set(++sequence, { callback, delay, at: now + delay, repeat: true }); return sequence; },
        setTimeout(callback, delay) { timers.set(++sequence, { callback, delay, at: now + delay }); return sequence; },
        clearTimeout(id) { timers.delete(id); },
        clearInterval(id) { timers.delete(id); },
        addEventListener: doc.addEventListener,
        getComputedStyle(el) { return { display: el.hidden ? 'none' : typeof el.displayAt === 'function' ? el.displayAt(win.innerWidth) : 'block', visibility: 'visible', opacity: '1' }; },
        matchMedia(query) { return { matches: query === '(max-width: 767.98px)' ? win.innerWidth < 768 : true }; },
        fetch(url, opts) { requests.push({ url, body: JSON.parse(opts.body) }); return Promise.resolve({ ok: true }); }
    };
    if (options.intersectionObserver) win.IntersectionObserver = class {
        constructor(callback) { this.callback = callback; this.observed = new Set(); intersectionObserver = this; }
        observe(el) { this.observed.add(el); }
        unobserve(el) { this.observed.delete(el); }
    };
    function slot(key, state = 'filled', extra = {}) {
        const el = { dataset: { audienceSlot: key, audiencePlacement: 'placement', audienceState: state, audienceRequested: 'true', audienceServed: state === 'filled' ? 'true' : 'false', audienceDelivery: '22222222-2222-4222-8222-222222222222', audienceCampaign: '33333333-3333-4333-8333-333333333333' },
            isConnected: true, hidden: false, images: [], parentElement: null,
            getBoundingClientRect() { return { top: 0, left: 0, right: 300, bottom: 250, width: this.collapsed || this.hidden ? 0 : 300, height: this.collapsed || this.hidden ? 0 : 250 }; },
            querySelectorAll(selector) { return selector === 'img' ? this.images : []; },
            querySelector() { return null; }, ...extra };
        slots.push(el); return el;
    }
    const ctx = vm.createContext({ window: win, document: doc, navigator: win.navigator, URL, URLSearchParams, console, Date: class extends Date { static now() { return 1800000000000 + now; } } });
    function run() { if (fs.existsSync(trackerPath)) vm.runInContext(fs.readFileSync(trackerPath, 'utf8'), ctx); }
    function tick(ms) { const end = now + ms; while (true) { const next = [...timers.entries()].filter(([, t]) => t.at <= end).sort((a, b) => a[1].at - b[1].at)[0]; if (!next) break; now = next[1].at; if (next[1].repeat) next[1].at += next[1].delay; else timers.delete(next[0]); next[1].callback(); } now = end; }
    function event(type, data = {}) { (listeners[type] || []).forEach(fn => fn({ type, ...data })); }
    function events() { win.RoadRunnersAudience?.flush(); return requests.flatMap(r => r.body.events); }
    function intersect(el, ratios) { if (intersectionObserver) intersectionObserver.callback(ratios.map(ratio => ({ target: el, isIntersecting: ratio > 0, intersectionRatio: ratio }))); }
    function evaluate(source, globals = {}) { Object.assign(ctx, globals); return vm.runInContext(source, ctx); }
    return { win, doc, slot, run, tick, event, requests, events, storage, intersect, evaluate };
}


function registration(id = '304', href = 'https://www.liverun.com.br/etapa/live-run-test/?private=secret', extra = {}) {
    return { tagName: 'A', dataset: { audienceLiveRegistration: id }, href,
        getAttribute(name) { return name === 'href' ? this.href : null; },
        closest(selector) { return selector === '[data-audience-live-registration]' ? this : null; }, ...extra };
}
function click(h, target, extra = {}) { h.event('click', { target, button: 0, ...extra }); }
const outbound = h => h.events().filter(event => event.kind === 'outbound_click');

test('LIVE registration emits one stable event across nested icons, repeated clicks and replacement modal content', () => {
    const h = harness(); h.run();
    const target = registration();
    click(h, { closest: selector => target.closest(selector) });
    click(h, target); click(h, registration());
    assert.deepEqual(outbound(h).map(({ kind, key, contentType, contentId }) => ({ kind, key, contentType, contentId })), [
        { kind: 'outbound_click', key: 'outbound_click:live_registration:304', contentType: 'event', contentId: '304' }
    ]);
    const payload = h.requests.find(request => request.body.events.some(event => event.kind === 'outbound_click')).body;
    assert.equal(payload.source, 'newsletter'); assert.equal(payload.campaign, 'run');
    assert.equal(payload.contextToken, 'signed-context');
    assert.equal(JSON.stringify(payload).includes('private=secret'), false);
    assert.equal(outbound(h)[0].campaignId, undefined); assert.equal(outbound(h)[0].activeMs, undefined);
});

test('keyboard activation, modified click and middle click collect without cancelling navigation', () => {
    for (const activation of [{type:'click', button:0, detail:0}, {type:'click', button:0, ctrlKey:true}, {type:'auxclick', button:1}]) {
        const h = harness(); h.run(); let prevented = false;
        h.event(activation.type, { target: registration(), ...activation, preventDefault() { prevented = true; } });
        assert.equal(outbound(h).length, 1); assert.equal(prevented, false);
    }
});

test('window.open registration buttons and exact LIVE checkout hosts share the event identity', () => {
    const h = harness(); h.run();
    click(h, registration('305', '', {tagName:'BUTTON', dataset:{audienceLiveRegistration:'305', audienceRegistrationUrl:'https://www.appliveexperience.com.br/evento/test/'}}));
    click(h, registration('306', 'https://appliveexperience.com.br/evento/test/'));
    click(h, registration('307', 'https://liverun.com.br/etapa/test/'));
    assert.deepEqual(outbound(h).map(e => e.contentId), ['305','306','307']);
});

test('unmarked links, wrong hosts, non-HTTPS, credentials, ports and invalid event IDs never become LIVE registrations', () => {
    const h = harness(); h.run();
    for (const href of ['https://liverun.com.br.evil.test/a','https://evil.test/?next=https://liverun.com.br/',
        'https://sub.liverun.com.br/a','https://user@liverun.com.br/a','https://liverun.com.br:8443/a','http://liverun.com.br/a','javascript:alert(1)','/evento/test/']) click(h, registration('304', href));
    for (const id of ['', '0','-1','0304','1.5','304:other','user@example.com','12345678901']) click(h, registration(id));
    click(h, { closest() { return null; } });
    assert.equal(outbound(h).length, 0);
});

test('disabled/cancelled activation and right/middle button actions on a button are ignored', () => {
    const h = harness(); h.run();
    click(h, registration(), {defaultPrevented:true}); click(h, registration('304','https://liverun.com.br/',{disabled:true}));
    h.event('auxclick',{target:registration(),button:2});
    h.event('auxclick',{target:registration('304','',{tagName:'BUTTON',dataset:{audienceLiveRegistration:'304',audienceRegistrationUrl:'https://liverun.com.br/'}}),button:1});
    assert.equal(outbound(h).length,0);
});

test('GPC, initial opt-out, storage failure and later refusal preserve controls and never send refused clicks', () => {
    for (const options of [{gpc:true},{storage:{'rr-audience-opt-out':'1'}}]) {
        const h=harness(options); h.run(); click(h,registration()); assert.equal(h.requests.length,0);
    }
    const h=harness({storageThrows:true}); h.run(); click(h,registration()); assert.equal(outbound(h).length,1);
    h.event('rr-audience-preference',{detail:{allowed:false}}); click(h,registration('305')); assert.equal(outbound(h).length,1);
});

test('transport failure does not escape the registration click handler', () => {
    const h=harness(); h.win.navigator.sendBeacon=()=>{throw Error('offline');}; h.win.fetch=()=>{throw Error('offline');}; h.run();
    assert.doesNotThrow(()=>click(h,registration()));
});
