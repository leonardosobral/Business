const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const scriptPath = '/Users/Shared/Projects/RunnerHub/Business/_codex/staging/seo-shared-assets-20261004/candidate/assets/js/rr-audience-privacy.min.js';

function element(dataset = {}) {
    const listeners = {};
    return {
        dataset, hidden: false, disabled: false, textContent: '', attributes: {},
        addEventListener(type, callback) { (listeners[type] ||= []).push(callback); },
        click() { (listeners.click || []).forEach(callback => callback({ currentTarget: this, preventDefault() {} })); },
        focus() { this.ownerDocument.activeElement = this; },
        setAttribute(name, value) { this.attributes[name] = String(value); },
        getAttribute(name) { return this.attributes[name]; },
        contains(target) { return target === this; }
    };
}

function harness({ gpc = false, optedOut = false, storageBlocked = false, cookiesBlocked = false, hasOpen = true } = {}) {
    const storage = new Map(optedOut ? [['rr-audience-opt-out', 'true']] : []);
    const cookies = new Map(optedOut ? [['rr-audience-opt-out', 'true']] : []);
    const windowListeners = {}, documentListeners = {}, dispatched = [];
    const doc = {
        activeElement: null,
        addEventListener(type, callback) { (documentListeners[type] ||= []).push(callback); },
        querySelector(selector) { return nodes[selector] || null; },
        querySelectorAll(selector) { return selector === '[data-audience-privacy-open]' && nodes[selector] ? [nodes[selector]] : []; }
    };
    Object.defineProperty(doc, 'cookie', {
        get() { if (cookiesBlocked) throw Error('cookies blocked'); return [...cookies].map(([key, value]) => `${key}=${value}`).join('; '); },
        set(value) {
            if (cookiesBlocked) throw Error('cookies blocked');
            const pair = value.split(';', 1)[0]; const split = pair.indexOf('=');
            const key = pair.slice(0, split), cookieValue = pair.slice(split + 1);
            if (/Max-Age=0/i.test(value)) cookies.delete(key); else cookies.set(key, cookieValue);
        }
    });
    const root = element({
        statusAllowed: 'Audience measurement is allowed.',
        statusDenied: 'Audience measurement is off.',
        statusGpc: 'GPC keeps audience measurement off.',
        savedAllowed: 'Preference saved: measurement allowed.',
        savedDenied: 'Preference saved: measurement refused.',
        saveUnavailable: 'Measurement is off on this page, but the browser could not save your choice for future pages.'
    });
    const open = element(), dialog = element(), close = element(), allow = element(), deny = element(), status = element(), feedback = element();
    for (const node of [root, open, dialog, close, allow, deny, status, feedback]) node.ownerDocument = doc;
    dialog.hidden = true;
    dialog.querySelectorAll = () => [close, allow, deny];
    const nodes = {
        '[data-audience-privacy-root]': root,
        '[data-audience-privacy-dialog]': dialog,
        '[data-audience-privacy-close]': close,
        '[data-audience-privacy-allow]': allow,
        '[data-audience-privacy-deny]': deny,
        '[data-audience-privacy-status]': status,
        '[data-audience-privacy-feedback]': feedback
    };
    if (hasOpen) nodes['[data-audience-privacy-open]'] = open;
    let reloads = 0;
    const win = {
        document: doc,
        navigator: { globalPrivacyControl: gpc },
        localStorage: {
            getItem(key) { if (storageBlocked) throw Error('storage blocked'); return storage.get(key) || null; },
            setItem(key, value) { if (storageBlocked) throw Error('storage blocked'); storage.set(key, value); },
            removeItem(key) { if (storageBlocked) throw Error('storage blocked'); storage.delete(key); }
        },
        location: { reload() { reloads++; } },
        addEventListener(type, callback) { (windowListeners[type] ||= []).push(callback); },
        dispatchEvent(event) { dispatched.push(event); (windowListeners[event.type] || []).forEach(callback => callback(event)); }
    };
    class CustomEvent { constructor(type, init = {}) { this.type = type; this.detail = init.detail; } }
    const context = vm.createContext({ window: win, document: doc, navigator: win.navigator, CustomEvent });
    vm.runInContext(fs.existsSync(scriptPath) ? fs.readFileSync(scriptPath, 'utf8') : '', context);
    function keydown(key, shiftKey = false) { (documentListeners.keydown || []).forEach(callback => callback({ key, shiftKey, preventDefault() {} })); }
    function storageEvent(newValue) { (windowListeners.storage || []).forEach(callback => callback({ key: 'rr-audience-opt-out', newValue })); }
    return { win, doc, storage, cookies, dispatched, nodes: { root, open, dialog, close, allow, deny, status, feedback }, keydown, storageEvent, reloads: () => reloads };
}

test('explicit refusal persists, notifies the tracker and reloads only after the click', () => {
    const h = harness();
    h.storage.set('rr-audience-visitor', 'visitor-id');
    h.storage.set('rr-audience-visitor-created', '1700000000000');
    h.storage.set('rr-audience-session', 'session-id');
    assert.ok(h.win.RoadRunnersAudiencePrivacy);
    assert.equal(h.nodes.status.textContent, 'Audience measurement is allowed.');
    assert.equal(h.reloads(), 0);
    h.nodes.deny.click();
    assert.equal(h.storage.get('rr-audience-opt-out'), 'true');
    assert.equal(h.cookies.get('rr-audience-opt-out'), 'true');
    assert.equal(h.storage.has('rr-audience-visitor'), false);
    assert.equal(h.storage.has('rr-audience-visitor-created'), false);
    assert.equal(h.storage.has('rr-audience-session'), false);
    assert.equal(h.dispatched.at(-1).detail.allowed, false);
    assert.equal(h.reloads(), 1);
});

test('explicit permission clears a prior refusal and reloads after the click', () => {
    const h = harness({ optedOut: true });
    assert.equal(h.nodes.status.textContent, 'Audience measurement is off.');
    h.nodes.allow.click();
    assert.equal(h.storage.has('rr-audience-opt-out'), false);
    assert.equal(h.cookies.has('rr-audience-opt-out'), false);
    assert.equal(h.dispatched.at(-1).detail.allowed, true);
    assert.equal(h.reloads(), 1);
});

test('refusal stays effective without reload when both preference stores are blocked', () => {
    const h = harness({ storageBlocked: true, cookiesBlocked: true });
    h.nodes.deny.click();
    assert.equal(h.win.RoadRunnersAudiencePrivacy.getState(), 'denied');
    assert.equal(h.nodes.status.textContent, 'Audience measurement is off.');
    assert.equal(h.nodes.feedback.textContent, 'Measurement is off on this page, but the browser could not save your choice for future pages.');
    assert.equal(h.dispatched.at(-1).detail.allowed, false);
    assert.equal(h.reloads(), 0);
});

test('GPC prevails over stored preference without triggering an automatic reload', () => {
    const h = harness({ gpc: true });
    h.storage.set('rr-audience-visitor', 'visitor-id');
    h.storage.set('rr-audience-visitor-created', '1700000000000');
    h.storage.set('rr-audience-session', 'session-id');
    h.win.RoadRunnersAudiencePrivacy.refresh();
    assert.equal(h.nodes.status.textContent, 'GPC keeps audience measurement off.');
    assert.equal(h.nodes.allow.disabled, true);
    assert.equal(h.storage.has('rr-audience-visitor'), false);
    assert.equal(h.storage.has('rr-audience-visitor-created'), false);
    assert.equal(h.storage.has('rr-audience-session'), false);
    h.nodes.allow.click();
    assert.equal(h.storage.has('rr-audience-opt-out'), false);
    assert.equal(h.reloads(), 0);
});

test('a refusal from another tab updates status without reloading this page', () => {
    const h = harness();
    h.storage.set('rr-audience-opt-out', 'true');
    h.storageEvent('true');
    assert.equal(h.nodes.status.textContent, 'Audience measurement is off.');
    assert.equal(h.reloads(), 0);
});

test('Escape closes the dialog and returns focus to the control that opened it', () => {
    const h = harness();
    h.nodes.open.focus(); h.nodes.open.click();
    assert.equal(h.nodes.dialog.hidden, false);
    assert.equal(h.doc.activeElement, h.nodes.close);
    h.keydown('Escape');
    assert.equal(h.nodes.dialog.hidden, true);
    assert.equal(h.doc.activeElement, h.nodes.open);
});

test('Tab remains inside the modal while it is open', () => {
    const h = harness();
    h.nodes.open.click();
    h.nodes.deny.focus(); h.keydown('Tab');
    assert.equal(h.doc.activeElement, h.nodes.close);
    h.nodes.close.focus(); h.keydown('Tab', true);
    assert.equal(h.doc.activeElement, h.nodes.deny);
});

test('pages without the user-menu control initialize without errors', () => {
    const h = harness({ hasOpen: false });
    assert.ok(h.win.RoadRunnersAudiencePrivacy);
    assert.equal(h.nodes.dialog.hidden, true);
    assert.equal(h.nodes.status.textContent, 'Audience measurement is allowed.');
});
