const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// Execute both production controllers; only browser DOM and HTTP are substituted.
function harness({ term = 'Floripa', mode = 'plain', type = 'eventos', filters = {}, respond } = {}) {
    const nodes = new Map(), requests = [], timers = [], documentListeners = {}, sliderCreations = [];
    function node(id, dataset = {}) {
        const listeners = {}, classes = new Set();
        const result = {
            id, dataset, value: '', textContent: '', innerHTML: '', style: {},
            classList: {
                toggle(name, active) { active ? classes.add(name) : classes.delete(name); },
                add(name) { classes.add(name); }, remove(name) { classes.delete(name); }
            },
            addEventListener(name, callback) { (listeners[name] ||= []).push(callback); },
            dispatch(name, event = {}) { (listeners[name] || []).forEach(callback => callback(event)); },
            setAttribute(name, value) { this[name] = value; },
            getAttribute(name) { return this[name]; },
            getElementsByTagName() { return []; },
            insertBefore() {},
            querySelector(selector) {
                if (selector === '[data-busca-total]') {
                    const count = this.innerHTML.match(/data-busca-total="(\d+)"/);
                    return count ? { getAttribute() { return count[1]; } } : null;
                }
                return null;
            },
            querySelectorAll(selector) {
                return selector === '.home-shell-card' ? [...this.innerHTML.matchAll(/class="home-shell-card"/g)] : [];
            }
        };
        nodes.set(id, result);
        return result;
    }
    const form = node('busca-form-main', { buscaSingleField: 'true' });
    const input = node('busca-input-plain');
    const hiddenTerm = node('hidden-term'), hiddenMode = node('hidden-mode'), hiddenType = node('hidden-type');
    hiddenMode.value = mode; hiddenType.value = type;
    form.querySelector = selector => ({
        'input[name="busca"]': hiddenTerm,
        'input[name="busca_mode"]': hiddenMode,
        'input[name="busca_tipo"]': hiddenType
    })[selector] || null;
    const sectionTypes = ['eventos', 'resultados', 'atletas', 'noticias', 'videos'];
    const sections = sectionTypes.map(value => node('busca-' + value + '-section', { buscaSection: value }));
    const tabs = ['todos', ...sectionTypes].map(value => node('tab-' + value, { buscaResultsTab: value }));
    const counts = ['todos', ...sectionTypes].map(value => {
        const badge = node('count-' + value);
        badge.closest = () => nodes.get('tab-' + value);
        return badge;
    });
    ['scroll-container-proximas', 'busca-resultados-results', 'busca-atletas-results', 'busca-noticias-results',
        'busca-videos-results', 'container-proximas', 'busca-empty-state', 'busca-no-results', 'busca-debug-card',
        'busca-feedback-message', 'busca-ai-loading-card', 'busca-results-loading-card',
        'range-distance', 'range-period', 'filter-panel'].forEach(value => node(value));
    const document = {
        getElementById(id) { return nodes.get(id) || null; },
        querySelector(selector) { return selector?.startsWith('#') ? nodes.get(selector.slice(1)) || null : null; },
        querySelectorAll(selector) {
            if (selector === '[data-busca-results-tab]') return tabs;
            if (selector === '[data-busca-section]') return sections;
            const count = selector?.match(/^\[data-busca-count="([^"]+)"\]$/);
            return count ? [counts.find(item => item.id === 'count-' + count[1])] : [];
        },
        addEventListener(name, callback) { (documentListeners[name] ||= []).push(callback); }
    };
    const window = {
        location: new URL('https://roadrunners.run/busca/'), URL, console: { warn() {} },
        setTimeout(callback) { timers.push(callback); return timers.length; },
        clearTimeout() {}, setInterval() { return 1; }, clearInterval() {},
        addEventListener() {}, colorirDistancias() {}, eval() {},
        mdb: { MultiRangeSlider: class { constructor(element, options) { sliderCreations.push({ id: element.id, values: [...options.startValues] }); } dispose() {} } },
        updateURLParameter(url, key, value) {
            const next = new URL(url);
            value === '' ? next.searchParams.delete(key) : next.searchParams.set(key, value);
            return next.href;
        },
        fetch(url) {
            const parsed = new URL(url, window.location.origin);
            requests.push(parsed);
            return Promise.resolve(respond ? respond(parsed) : htmlResponse('found'));
        }
    };
    window.history = { replaceState(unusedState, unusedTitle, url) { window.location = new URL(url); } };
    const context = vm.createContext({ window, document, console });
    ['runnerhub-event-filters.js', 'runnerhub-busca-page.js'].forEach(file => {
        vm.runInContext(fs.readFileSync((file === 'runnerhub-event-filters.js' ? path.resolve(__dirname, 'candidate/assets/js', file) : path.resolve(__dirname, '../../../..','RoadRunners/assets/js',file)), 'utf8'), context);
    });
    const controller = window.RunnerHubEventFilters.init({
        buscaTermo: term, buscaModo: mode, selectors: {
            scrollContainer: '#scroll-container-proximas', rangeDistancia: '#range-distance', rangeTempo: '#range-period', filtroFull: '#filter-panel'
        }, ...filters
    });
    window.RunnerHubBuscaPage.init({
        filtersController: controller,
        selectors: {
            form: '#busca-form-main', buscaPlainInputId: 'busca-input-plain',
            buscaDebugCardId: 'busca-debug-card', buscaFeedbackMessageId: 'busca-feedback-message',
            buscaAiLoadingCardId: 'busca-ai-loading-card', buscaResultsLoadingCardId: 'busca-results-loading-card'
        }
    });
    const event = { preventDefault() {}, stopPropagation() {} };
    return {
        nodes, requests, controller, window, sliderCreations,
        async start() { while (timers.length) timers.shift()(); await settle(); },
        async submit(value, nextMode = hiddenMode.value) {
            input.value = value; hiddenMode.value = nextMode;
            form.dispatch('submit', event); await settle();
        },
        async slider(id, values) {
            nodes.get(id).dispatch('valueChanged.mdb.multiRangeSlider', { values: { rounded: values } });
            while (timers.length) timers.shift()();
            await settle();
        },
        async tab(value) {
            const target = { closest() { return nodes.get('tab-' + value); } };
            (documentListeners.click || []).forEach(callback => callback({ ...event, target }));
            await settle();
        }
    };
}

function htmlResponse(label, count = 1, ok = true) {
    return { ok, status: ok ? 200 : 503, url: 'https://roadrunners.run/api/local-fixture.cfm',
        async text() { return '<div data-busca-total="' + count + '"><div class="home-shell-card">' + label + '</div></div>'; } };
}
function aiResponse(filters = {}) {
    return { ok: true, async json() { return {
        ok: true, searchLogId: 17,
        filters: { distancia_inicio: null, distancia_fim: null, estado: '', cidade: '', estados: [],
            periodo_inicio: '', periodo_fim: '', termo_livre: 'Floripa', tipo_termo: 'prova', ...filters },
        meta: { usedAi: true, aiConfigured: true, fallbackReason: '', error: '', debug: {} }, message: 'Interpretada'
    }; } };
}
function deferred() {
    let resolve;
    const promise = new Promise(done => { resolve = done; });
    return { promise, resolve };
}
async function settle() { await new Promise(resolve => setImmediate(resolve)); }

test('GET bootstrap executes a plain term even with no interpreted term', async () => {
    const app = harness({ term: 'Corre RD' }); await app.start();
    assert.equal(app.requests[0].searchParams.get('busca'), 'Corre RD');
    assert.match(app.nodes.get('scroll-container-proximas').innerHTML, /found/);
});

test('empty legacy all-types URL opens the event calendar without an AI request', async () => {
    const app = harness({ term: '', mode: 'ai', type: 'todos' }); await app.start();
    assert.equal(app.requests.length, 1);
    assert.equal(app.requests[0].pathname, '/api/eventos_busca.cfm');
    assert.equal(app.nodes.get('hidden-type').value, 'eventos');
    assert.equal(app.nodes.get('busca-resultados-section').style.display, 'none');
    assert.match(app.nodes.get('scroll-container-proximas').innerHTML, /found/);
    assert.equal(app.nodes.get('busca-empty-state').style.display, 'none');
});

test('event calendar preserves its state and month range without calling AI', async () => {
    const app = harness({ term: '', mode: 'ai', filters: {
        buscaEstado: 'SC', periodoMesesSelecionado: [0, 3], rua: true, trail: true, nacional: true
    } }); await app.start();
    assert.equal(app.requests.length, 1);
    assert.equal(app.requests[0].pathname, '/api/eventos_busca.cfm');
    assert.equal(app.requests[0].searchParams.get('estado'), 'SC');
    assert.equal(app.requests[0].searchParams.get('tempo'), '0,3');
    assert.equal(app.window.location.searchParams.get('estado'), 'SC');
    assert.equal(app.nodes.get('busca-debug-card').style.display, 'none');
});

test('removing the calendar state keeps the national view on reload', async () => {
    const app = harness({ term: '', mode: 'plain', filters: { buscaEstado: 'SC' } });
    app.window.location = new URL('https://roadrunners.run/busca/?context_uf=SC&estado=SC');
    await app.start();
    app.controller.syncBuscaFilters({});
    await app.submit('');
    assert.equal(app.window.location.searchParams.get('context_uf'), 'BR');
    assert.equal(app.window.location.searchParams.has('estado'), false);
    assert.equal(app.nodes.get('busca-debug-card').style.display, 'none');
});

test('an explicit twelve-month calendar keeps its absolute cutoff in both event requests', async () => {
    const app = harness({ term: '', mode: 'ai', filters: {
        periodoMesesSelecionado: [0, 12], buscaPeriodoInicio: '2026-09-12', buscaPeriodoFim: '2027-09-07'
    } }); await app.start();
    await app.controller.callAPI();
    assert.equal(app.requests.length, 2);
    for (const request of app.requests) {
        assert.equal(request.pathname, '/api/eventos_busca.cfm');
        assert.equal(request.searchParams.get('periodo_inicio'), '2026-09-12');
        assert.equal(request.searchParams.get('periodo_fim'), '2027-09-07');
    }
});

test('clearing the text returns to the calendar even without additional filters', async () => {
    const app = harness({ mode: 'plain', type: 'todos' }); await app.start();
    app.requests.length = 0;
    await app.submit('');
    assert.equal(app.requests.length, 1);
    assert.equal(app.requests[0].pathname, '/api/eventos_busca.cfm');
    assert.equal(app.requests[0].searchParams.has('busca'), false);
    assert.equal(app.nodes.get('hidden-type').value, 'eventos');
});

test('legacy GET distance autoexecutes without a search term and reaches the endpoint', async () => {
    const app = harness({ term: '', filters: {
        distanciaSelecionada: [5, 5], buscaDistanciaInicio: 5, buscaDistanciaFim: 5, buscaDistanciaAtiva: false
    } });
    await app.start();
    assert.equal(app.requests.length, 1);
    assert.equal(app.requests[0].searchParams.get('distancia_inicio'), '5');
    assert.equal(app.requests[0].searchParams.get('distancia_fim'), '5');
});

test('legacy GET period autoexecutes without a search term and preserves the month range', async () => {
    const app = harness({ term: '', filters: { periodoMesesSelecionado: [0, 2] } }); await app.start();
    assert.equal(app.requests.length, 1);
    assert.equal(app.requests[0].searchParams.get('tempo'), '0,2');
});

test('switching from a direct events search loads athletes instead of showing an unsearched empty section', async () => {
    const app = harness(); await app.start(); await app.tab('atletas');
    assert.match(app.nodes.get('busca-atletas-results').innerHTML, /found/);
    assert.equal(app.nodes.get('busca-atletas-section').style.display, '');
});

test('network failure interpreting AI preserves the typed term through plain search', async () => {
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm'
        ? Promise.reject(new Error('offline')) : htmlResponse('found') });
    await app.start();
    const results = app.requests.find(url => url.pathname === '/api/eventos_busca.cfm');
    assert.equal(results.searchParams.get('busca'), 'Floripa');
    assert.equal(results.searchParams.get('busca_mode'), 'plain');
});

test('unsuccessful AI response also falls back to searching the typed term', async () => {
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm'
        ? { ok: false, status: 503, async json() { return { ok: false }; } } : htmlResponse('found') });
    await app.start();
    const results = app.requests.find(url => url.pathname === '/api/eventos_busca.cfm');
    assert.equal(results.searchParams.get('busca'), 'Floripa');
    assert.equal(results.searchParams.get('busca_mode'), 'plain');
});

test('a new plain query removes filters inferred for the previous AI query', async () => {
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm'
        ? aiResponse({ cidade: 'Florianópolis', estado: 'SC', distancia_inicio: 21, distancia_fim: 21 }) : htmlResponse('found') });
    await app.start(); await app.submit('São Silvestre', 'plain');
    const results = app.requests.at(-1);
    assert.equal(results.searchParams.get('busca'), 'São Silvestre');
    assert.equal(results.searchParams.get('cidade'), null);
    assert.equal(results.searchParams.get('estado'), null);
    assert.equal(results.searchParams.get('distancia_inicio'), null);
});

test('plain search retains an explicit location supplied in GET', async () => {
    const app = harness({ filters: { buscaEstado: 'SC' } }); await app.start();
    assert.equal(app.requests[0].searchParams.get('estado'), 'SC');
});

test('leaving AI restores the location selected before the interpretation', async () => {
    const app = harness({ mode: 'ai', filters: { buscaEstado: 'SP' },
        respond: url => url.pathname === '/api/search.cfm' ? aiResponse({ estado: 'SC' }) : htmlResponse('found') });
    await app.start(); await app.submit('São Silvestre', 'plain');
    assert.equal(app.requests.at(-1).searchParams.get('estado'), 'SP');
});

test('switching among sections already loaded in Todos reuses their results', async () => {
    const app = harness({ type: 'todos' }); await app.start(); await app.tab('atletas'); await app.tab('eventos');
    assert.equal(app.requests.length, 5);
    assert.match(app.nodes.get('busca-atletas-results').innerHTML, /found/);
    assert.match(app.nodes.get('scroll-container-proximas').innerHTML, /found/);
});

test('an older HTML response cannot replace a newer search result', async () => {
    const first = deferred();
    const app = harness({ respond: url => url.searchParams.get('busca') === 'Floripa' ? first.promise : htmlResponse('São Silvestre') });
    await app.start(); await app.submit('São Silvestre');
    first.resolve(htmlResponse('Floripa')); await settle();
    assert.match(app.nodes.get('scroll-container-proximas').innerHTML, /São Silvestre/);
    assert.doesNotMatch(app.nodes.get('scroll-container-proximas').innerHTML, /Floripa/);
});

test('an older AI response cannot change filters or launch results for the newer query', async () => {
    const first = deferred();
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm' ? first.promise : htmlResponse('São Silvestre') });
    await app.start(); await app.submit('São Silvestre', 'plain');
    first.resolve(aiResponse({ cidade: 'Florianópolis', estado: 'SC' })); await settle();
    assert.equal(app.controller.getState().buscaCidade, '');
    assert.equal(app.requests.filter(url => url.pathname === '/api/eventos_busca.cfm').length, 1);
});

test('one failed section does not erase the counts of sections that did load', async () => {
    const app = harness({ type: 'todos', respond: url => htmlResponse('found', 1, url.pathname !== '/api/resultados_busca.cfm') });
    await app.start();
    assert.equal(app.nodes.get('count-eventos').textContent, '1');
    assert.equal(app.nodes.get('count-atletas').textContent, '1');
});

test('a manual distance range stays intact when only one end differs from the previous AI range', async () => {
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm'
        ? aiResponse({ distancia_inicio: 5, distancia_fim: 10 }) : htmlResponse('found') });
    await app.start(); await app.slider('range-distance', [5, 21]); await app.submit('Corre RD', 'plain');
    const results = app.requests.at(-1);
    assert.equal(results.searchParams.get('distancia_inicio'), '5');
    assert.equal(results.searchParams.get('distancia_fim'), '21');
});

test('a manual period stays intact when only one end differs from the previous AI period', async () => {
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm'
        ? aiResponse({ periodo_inicio: monthDate(1), periodo_fim: monthDate(2) }) : htmlResponse('found') });
    await app.start(); await app.slider('range-period', [1, 4]); await app.submit('Corre RD', 'plain');
    const results = app.requests.at(-1);
    assert.equal(results.searchParams.get('periodo_inicio'), monthDate(1));
    assert.equal(results.searchParams.get('periodo_fim'), monthDate(4));
});

function monthDate(offset) {
    const today = new Date(), date = new Date(today.getFullYear(), today.getMonth() + offset, today.getDate());
    return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');
}

test('an AI minimum distance keeps the maximum open in page URL, aggregate search and filter refresh', async () => {
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm'
        ? aiResponse({ distancia_inicio: 30, distancia_fim: null }) : htmlResponse('found') });
    await app.start();
    assert.equal(app.requests.at(-1).searchParams.get('distancia_inicio'), '30');
    assert.equal(app.requests.at(-1).searchParams.get('distancia_fim'), null);
    assert.equal(app.window.location.searchParams.get('distancia_fim'), null);
    await app.controller.callAPI();
    assert.equal(app.requests.at(-1).searchParams.get('distancia_inicio'), '30');
    assert.equal(app.requests.at(-1).searchParams.get('distancia_fim'), null);
});

test('an AI maximum distance keeps the minimum open in page URL, aggregate search and filter refresh', async () => {
    const app = harness({ mode: 'ai', respond: url => url.pathname === '/api/search.cfm'
        ? aiResponse({ distancia_inicio: null, distancia_fim: 10 }) : htmlResponse('found') });
    await app.start();
    assert.equal(app.requests.at(-1).searchParams.get('distancia_inicio'), null);
    assert.equal(app.requests.at(-1).searchParams.get('distancia_fim'), '10');
    assert.equal(app.window.location.searchParams.get('distancia_inicio'), null);
    await app.controller.callAPI();
    assert.equal(app.requests.at(-1).searchParams.get('distancia_inicio'), null);
    assert.equal(app.requests.at(-1).searchParams.get('distancia_fim'), '10');
});

test('a GET minimum distance remains open even though the visual slider ends at 42', async () => {
    const app = harness({ term: '', filters: {
        distanciaSelecionada: [30, 42], buscaDistanciaInicio: 30, buscaDistanciaFim: null, buscaDistanciaAtiva: true
    } });
    await app.start();
    assert.equal(app.requests.at(-1).searchParams.get('distancia_inicio'), '30');
    assert.equal(app.requests.at(-1).searchParams.get('distancia_fim'), null);
    await app.controller.callAPI();
    assert.equal(app.requests.at(-1).searchParams.get('distancia_fim'), null);
});

for (const visiblePeriod of [false, true]) {
 test('visible distance is reinitialized when opening filters; period visible=' + visiblePeriod, async () => {
  const app = harness(); await app.start();
  app.nodes.get('range-distance').offsetWidth = 500;
  app.nodes.get('range-period').offsetWidth = visiblePeriod ? 500 : 0;
  const before = app.sliderCreations.length;
  app.nodes.get('filter-panel').dispatch('shown.bs.collapse');
  assert.deepEqual(app.sliderCreations.slice(before).map(x => x.id), visiblePeriod ? ['range-distance','range-period'] : ['range-distance']);
  assert.deepEqual(app.sliderCreations[before].values, [1,42]);
  await app.start();
  await app.slider('range-distance', [5,10]);
  assert.equal(app.requests.at(-1).searchParams.get('distancia_inicio'), '5');
  assert.equal(app.requests.at(-1).searchParams.get('distancia_fim'), '10');
 });
}
