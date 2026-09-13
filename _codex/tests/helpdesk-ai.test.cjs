const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('helpdesk/assets/ai-draft.js', 'utf8');

function fixture({text = '', payload = {success: true, draft: 'Resposta sugerida', sources: [{title: 'Guia'}], warnings: []}, ok = true, deferred = false} = {}) {
  const elements = {};
  function element(key) {
    return elements[key] ||= {value: '', hidden: true, disabled: false, textContent: '', style: {}, dataset: {}, handlers: {},
      classList: {toggle() {}}, addEventListener(name, fn) {this.handlers[name] = fn;},
      dispatchEvent(event) {this.handlers[event.type]?.(event);}, focus() {}, setAttribute() {}, removeAttribute() {}};
  }
  const panel = element('panel');
  panel.dataset = {csrf: 'csrf-test', endpoint: '/helpdesk/ai-draft.cfm'};
  panel.querySelector = element;
  const form = {querySelector: element};
  panel.closest = () => form;
  element('[name="ticket_mensagem"]').value = text;
  element('[name="ticket_id"]').value = '89';
  let calls = []; let resolve; let confirms = true;
  const response = {ok, headers: {get: () => 'application/json'}, json: async () => payload};
  const fetch = async (url, options) => { calls.push({url, options}); return deferred ? new Promise(r => {resolve = () => r(response);}) : response; };
  vm.runInNewContext(source, {document: {querySelector: () => panel}, window: {confirm: () => confirms}, fetch,
    URLSearchParams, AbortController, Event, setTimeout: () => 1, clearTimeout() {}});
  return {elements, calls, edit(value) {element('[name="ticket_mensagem"]').value = value; element('[name="ticket_mensagem"]').dispatchEvent(new Event('input'));},
    click(key) {return element(`[data-ai-${key}]`).handlers.click();}, resolve() {resolve();}, confirm(value) {confirms = value;},
    editor: element('[name="ticket_mensagem"]'), status: element('[data-ai-status]')};
}

test('editor vazio recebe rascunho, sem ação de envio', async () => {
  const f = fixture(); await f.click('generate');
  assert.equal(f.editor.value, 'Resposta sugerida');
  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0].options.body.get('helpdesk_action'), null);
  assert.equal(f.calls[0].options.body.get('csrf_token'), 'csrf-test');
  assert.equal(f.calls[0].options.body.get('ticket_id'), '89');
  assert.equal(f.elements['[data-ai-generate]'].disabled, false);
  await f.click('undo'); assert.equal(f.editor.value, '');
});
test('texto existente exige aplicação explícita e pode ser recuperado', async () => {
  const f = fixture({text: 'Texto humano'}); await f.click('generate');
  assert.equal(f.editor.value, 'Texto humano'); assert.equal(f.elements['[data-ai-pending]'].hidden, false);
  f.confirm(false); await f.click('apply'); assert.equal(f.editor.value, 'Texto humano');
  f.confirm(true); await f.click('apply'); assert.equal(f.editor.value, 'Resposta sugerida');
  await f.click('undo'); assert.equal(f.editor.value, 'Texto humano');
});
test('edição durante a consulta é preservada; clique duplicado não faz outra chamada', async () => {
  const f = fixture({deferred: true}); const pending = f.click('generate');
  await f.click('generate'); assert.equal(f.calls.length, 1);
  f.edit('Comecei a responder'); f.resolve(); await pending;
  assert.equal(f.editor.value, 'Comecei a responder'); assert.equal(f.elements['[data-ai-pending]'].hidden, false);
});
test('falha do servidor mantém o texto e reabilita geração', async () => {
  const f = fixture({text: 'Meu texto', ok: false, payload: {success: false, message: 'Base indisponível'}}); await f.click('generate');
  assert.equal(f.editor.value, 'Meu texto'); assert.equal(f.status.textContent, 'Base indisponível');
  assert.equal(f.elements['[data-ai-generate]'].disabled, false);
});
test('resposta vazia ou inválida não substitui o editor', async () => {
  const f = fixture({text: 'Meu texto', payload: {success: true, draft: ''}}); await f.click('generate');
  assert.equal(f.editor.value, 'Meu texto'); assert.match(f.status.textContent, /inválido/);
});
test('texto da IA e nomes das fontes são texto simples, não HTML', async () => {
  const f = fixture({payload: {success: true, draft: '<script>alert(1)</script>', sources: [{title: '<img onerror=alert(1)>'}], warnings: ['Sem fonte relevante']}});
  await f.click('generate'); assert.equal(f.editor.value, '<script>alert(1)</script>');
  assert.match(f.elements['[data-ai-sources]'].textContent, /<img/);
  assert.equal(f.elements['[data-ai-sources]'].innerHTML, undefined);
});
test('alteração após aplicar IA exige confirmação antes de desfazer', async () => {
  const f = fixture(); await f.click('generate'); f.edit('Ajustei a resposta'); f.confirm(false);
  await f.click('undo'); assert.equal(f.editor.value, 'Ajustei a resposta');
});
test('endpoint separado não inclui backend de mutações e valida admin/CSRF/método', () => {
  const endpoint = fs.readFileSync('helpdesk/ai-draft.cfm', 'utf8');
  assert.match(endpoint, /CGI.REQUEST_METHOD!="POST"/);
  assert.match(endpoint, /SELECT is_admin FROM tb_usuarios/);
  assert.match(endpoint, /REQUEST.businessIdentity.id/);
  assert.match(endpoint, /SESSION.helpdeskAICsrf/);
  assert.doesNotMatch(endpoint, /backend\.cfm|responder_ticket|INSERT INTO|UPDATE tb_helpdesk|helpdeskNotify/i);
  const service = fs.readFileSync('helpdesk/includes/HelpdeskAI.cfc', 'utf8');
  assert.match(service, /status='active'/); assert.match(service, /store=false/);
  assert.doesNotMatch(service, /INSERT INTO|UPDATE tb_helpdesk|DELETE FROM|helpdeskNotify/i);
});
