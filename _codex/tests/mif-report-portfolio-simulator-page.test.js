const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const test = require('node:test');

const reportRoot = path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
);
const pagePath = path.join(reportRoot, 'portfolio', 'simulador.cfm');
const portfolio = require(path.join(reportRoot, 'assets', 'portfolio.js'));
const report = require(path.join(reportRoot, 'assets', 'report.js'));
const page = fs.readFileSync(pagePath, 'utf8');

function simulatorFixture() {
  return {
    thresholds: {
      maximum_selected_channels: 10,
      publishable_cell_minimum_registrations: 5,
      exposure_classification_minimum_registrations: 10,
      exposure_high_event_share_pct: '40.00',
      exposure_medium_event_share_pct: '20.00',
      exposure_partner_concentration_pct: '60.00',
    },
    selectable_channels: [
      { slug: 'baixo', channel_name: 'Canal Baixo', gross_value: '100.00' },
      { slug: 'alto', channel_name: 'Canal Alto', gross_value: '300.00' },
      { slug: 'medio', channel_name: 'Canal Médio', gross_value: '200.00' },
    ],
    coverage_cube: [
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Canal Alto', paid_registrations: 12 },
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Canal Médio', paid_registrations: 8 },
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Canal Baixo', paid_registrations: 6 },
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Canais comerciais não orgânicos', paid_registrations: 26 },
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Todos os canais', paid_registrations: 40 },
    ],
  };
}

class FakeElement {
  constructor(tagName = 'div') {
    this.tagName = tagName.toUpperCase();
    this._children = [];
    this.dataset = {};
    this.listeners = {};
    this.hidden = false;
    this.disabled = false;
    this.checked = false;
    this.value = '';
    this.textContent = '';
    this.innerHTML = '';
  }

  get children() {
    const collection = { length: this._children.length };
    this._children.forEach((child, index) => { collection[index] = child; });
    collection[Symbol.iterator] = this._children[Symbol.iterator].bind(this._children);
    return collection;
  }

  appendChild(child) {
    this._children.push(child);
    return child;
  }

  replaceChildren(...children) {
    this._children = children;
  }

  addEventListener(type, listener) {
    (this.listeners[type] ||= []).push(listener);
  }

  dispatch(type) {
    const event = { preventDefault() { this.defaultPrevented = true; } };
    for (const listener of this.listeners[type] || []) listener(event);
    return event;
  }

  querySelectorAll(selector) {
    const descendants = [];
    const visit = (element) => {
      for (const child of element._children) {
        descendants.push(child);
        visit(child);
      }
    };
    visit(this);
    if (selector === 'input[name="canal"]') {
      return descendants.filter((element) => element.tagName === 'INPUT' && element.name === 'canal');
    }
    return [];
  }
}

function simulatorScript() {
  const scripts = [...page.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)]
    .map((match) => match[1]);
  const script = scripts.find((candidate) => /configureMifPortfolioSimulator/.test(candidate));
  assert.ok(script, 'simulator bootstrap script must exist');
  return script;
}

function runSimulator(search) {
  const elements = Object.fromEntries([
    'mif-report-data',
    'portfolio-simulator-form',
    'portfolio-channel-search',
    'portfolio-channel-list',
    'portfolio-selection-count',
    'portfolio-simulator-error',
    'mif-portfolio-simulation',
  ].map((id) => [id, new FakeElement()]));
  elements['mif-report-data'].textContent = JSON.stringify(simulatorFixture());
  const replaced = [];
  const window = {
    location: {
      href: `https://business.example/relatorios/maratona-floripa-2026/portfolio/simulador.cfm${search}`,
      search,
    },
    history: { replaceState(_state, _title, url) { replaced.push(url); } },
  };
  const document = {
    createElement(tagName) { return new FakeElement(tagName); },
    getElementById(id) { return elements[id]; },
  };
  vm.runInNewContext(simulatorScript(), {
    document,
    window,
    URLSearchParams,
    MifPortfolio: portfolio,
    MifReport: report,
  });
  return { elements, replaced };
}

test('simulator authenticates before reading only its compact simulator payload', () => {
  const reads = [...page.matchAll(/mifReadDataset\(\s*["']([^"']+)["']\s*\)/gi)]
    .map((match) => match[1]);

  assert.match(page, /\.\.\/includes\/auth\.cfm/i);
  assert.match(page, /\.\.\/includes\/data\.cfm/i);
  assert.ok(
    page.search(/\.\.\/includes\/auth\.cfm/i) < page.search(/mifReadDataset\s*\(/i),
    'authentication must precede private data access',
  );
  assert.deepEqual(reads, ['portfolio/simulator.json']);
  assert.doesNotMatch(page, /summary\.json|explorer\.json|channels\/[a-z0-9-]+\.json/i);
  assert.match(page, /type=["']application\/json["']/i);
  assert.match(page, /replace\([^\n]+["']<\/["'][^\n]+["']<\\\/["']/i);
});

test('simulator preserves repeated channel parameters through the authenticated return path', () => {
  const returnPath = page.search(/mifReportRequestedReturnPath/i);
  const auth = page.search(/\.\.\/includes\/auth\.cfm/i);

  assert.ok(returnPath >= 0 && returnPath < auth, 'return path must be prepared before authentication');
  assert.match(page, /CGI\.QUERY_STRING/i);
  assert.match(page, /simulador\.cfm/i);
});

test('simulator header exposes general analysis, dossiers, portfolio and PDF actions', () => {
  assert.match(page, /class=["']report-brand["']/i);
  assert.match(page, /src=["']\/lib\/images\/runpro\.svg["']/i);
  assert.match(page, /href=["']\.\.\/["'][^>]*>← Análise geral</i);
  assert.match(page, /href=["']\.\.\/canais\/["'][^>]*>Dossiês</i);
  assert.match(page, /href=["']\.\/["'][^>]*>Portfólio</i);
  assert.match(page, /window\.print\s*\(/i);
  assert.match(page, /portfolio\.css\?v=20260902-2/i);
  assert.match(page, /portfolio\.js\?v=20260902-4/i);
  assert.doesNotMatch(page, />Explorador</i);
});

test('simulator restores repeated channels, sorts choices by gross value and replaces a deterministic URL', () => {
  const { elements, replaced } = runSimulator('?canal=baixo&canal=alto');
  const choices = Array.from(elements['portfolio-channel-list'].children);
  const slugs = choices.map((choice) => choice.querySelectorAll('input[name="canal"]')[0].value);

  assert.deepEqual(slugs, ['alto', 'medio', 'baixo']);
  assert.match(elements['mif-portfolio-simulation'].innerHTML, /CANAL BAIXO, CANAL ALTO/);
  assert.equal(elements['portfolio-selection-count'].textContent, '2 de 10 canais selecionados');
  assert.equal(
    replaced.at(-1),
    'https://business.example/relatorios/maratona-floripa-2026/portfolio/simulador.cfm?canal=alto&canal=baixo',
  );
});

test('simulator search filters rendered choices without submitting the form', () => {
  const { elements } = runSimulator('?canal=alto');
  const search = elements['portfolio-channel-search'];
  search.value = 'medio';
  search.dispatch('input');

  assert.deepEqual(
    Array.from(elements['portfolio-channel-list'].children).map((choice) => choice.hidden),
    [true, false, true],
  );
  const submitted = elements['portfolio-simulator-form'].dispatch('submit');
  assert.equal(submitted.defaultPrevented, true);
});

test('simulator leaves an invalid shared slug visible instead of silently rewriting it', () => {
  const { elements, replaced } = runSimulator('?canal=desconhecido');

  assert.equal(elements['portfolio-simulator-error'].hidden, false);
  assert.match(elements['portfolio-simulator-error'].textContent, /Canal desconhecido: desconhecido/i);
  assert.equal(elements['mif-portfolio-simulation'].innerHTML, '');
  assert.deepEqual(replaced, []);
});
