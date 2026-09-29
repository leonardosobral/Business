import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const source = await readFile(new URL('../../crm-interno/crm-opportunities.js', import.meta.url), 'utf8');
const { initOpportunities } = await import(`data:text/javascript,${encodeURIComponent(source)}`);

function fixture({ metricFails = false, metricPending = false } = {}) {
  const nodes = new Map();
  const element = selector => {
    if (!nodes.has(selector)) nodes.set(selector, {
      value: '', textContent: '', innerHTML: '', disabled: false,
      querySelectorAll: () => [],
    });
    return nodes.get(selector);
  };
  globalThis.document = { querySelector: element };
  const calls = [];
  const api = async (action, input = {}) => {
    calls.push({ action, input });
    if (action === 'opportunities.owners') return { items: [] };
    if (action === 'opportunities.list') {
      if (input.stage === 'converted') {
        if (metricFails) throw new Error('summary unavailable');
        if (metricPending) return new Promise(() => {});
        return { items: [], total: 3 };
      }
      return { items: [], total: 8 };
    }
    throw new Error(`unexpected action ${action}`);
  };
  initOpportunities({ api, escape: value => value, date: value => value, openProfile: () => {}, notify: () => {} });
  return { element, calls };
}

async function settled() {
  await new Promise(resolve => setTimeout(resolve, 20));
}

test('manual conversions have a distinct count, not revenue', async () => {
  const { element, calls } = fixture();
  await settled();
  assert.match(element('#opportunitySummary').textContent, /8 oportunidades no filtro/);
  assert.match(element('#opportunitySummary').textContent, /3 convertidas manualmente/);
  assert.match(element('#opportunitySummary').textContent, /não comprova compras ou receita/);
  assert.deepEqual(calls.filter(call => call.action === 'opportunities.list').map(call => call.input.stage), ['', 'converted']);
});

test('an unavailable manual count is not shown as zero or allowed to hide the list', async () => {
  const { element } = fixture({ metricFails: true });
  await settled();
  assert.match(element('#opportunitySummary').textContent, /Contagem manual indisponível/);
  assert.doesNotMatch(element('#opportunitySummary').textContent, /0 convertidas/);
  assert.match(element('#opportunityList').innerHTML, /Nenhuma oportunidade corresponde aos filtros/);
});

test('a pending manual count does not delay the opportunity list', async () => {
  const { element } = fixture({ metricPending: true });
  await settled();
  assert.match(element('#opportunitySummary').textContent, /8 oportunidades no filtro/);
  assert.match(element('#opportunitySummary').textContent, /Contagem manual em andamento/);
  assert.match(element('#opportunityList').innerHTML, /Nenhuma oportunidade corresponde aos filtros/);
});
