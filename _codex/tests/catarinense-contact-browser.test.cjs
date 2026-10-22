const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {JSDOM} = require('jsdom');
const {init} = require('../../desafios/assets/catarinense-contact.js');
const modal = fs.readFileSync(path.resolve(__dirname, '../../desafios/includes/catarinense_contact_modal.cfm'), 'utf8');
function setup() {
  const dom = new JSDOM('<!doctype html><body><button id="first">Contato A</button><button id="second">Contato B</button>' + modal + '</body>', {url:'https://business.roadrunners.run/desafios/catarinensetrailrun/'});
  const {document} = dom.window;
  const dialog = document.getElementById('catarinenseContactDialog');
  // jsdom does not implement the native dialog boundary. Keep our event handler,
  // rendering, URL mapping and focus lifecycle real; emulate only native open/close.
  dialog.showModal = () => dialog.setAttribute('open', '');
  dialog.close = () => {dialog.removeAttribute('open'); dialog.dispatchEvent(new dom.window.Event('close'));};
  const first=document.getElementById('first'),second=document.getElementById('second');
  first.dataset.catarinenseContact=JSON.stringify({ID:72,NOME:'Ana <img src=x onerror=alert(1)>',EMAIL:'ana@example.com',TELEFONE_USUARIO:'48999991234',INSTAGRAM:'@ana.atleta',TAG:'ana',CIDADE:'Florianópolis',ESTADO:'SC'});
  second.dataset.catarinenseContact=JSON.stringify({id:73,nome:'Bruno'});
  init(document);
  return {dom,document,dialog,first,second,close:()=>dom.window.close()};
}
test('the discrete button opens the shared dialog with safe text and its own recipient', () => {
  const app=setup();try {
    app.first.click();
    assert.equal(app.dialog.open,true);
    assert.equal(app.dialog.querySelector('[data-contact-name]').textContent,'Ana <img src=x onerror=alert(1)>');
    assert.equal(app.dialog.querySelectorAll('[data-contact-name] img').length,0);
    assert.equal(app.dialog.querySelector('[data-contact-action="chat"]').href,'https://roadrunners.run/mensagens/?destinatario=72');
    assert.equal(app.document.body.classList.contains('catarinense-contact-open'),true);
  } finally {app.close();}
});
test('opening another athlete clears every previous contact and hidden href', () => {
  const app=setup();try {
    app.first.click();app.dialog.close();app.second.click();
    assert.equal(app.dialog.querySelector('[data-contact-name]').textContent,'Bruno');
    for(const field of ['email','phone','whatsapp','instagram']) {
      const value=app.dialog.querySelector('[data-contact-value="'+field+'"]'),action=app.dialog.querySelector('[data-contact-action="'+field+'"]');
      assert.equal(value.textContent,'Não informado');assert.equal(value.hasAttribute('href'),false);
      assert.equal(action.hidden,true);assert.equal(action.hasAttribute('href'),false);
    }
    assert.equal(app.dialog.querySelector('[data-contact-action="profile"]').hidden,true);
    assert.equal(app.dialog.querySelector('[data-contact-action="chat"]').href,'https://roadrunners.run/mensagens/?destinatario=73');
  } finally {app.close();}
});
test('close buttons restore keyboard focus to the athlete contact button', () => {
  const app=setup();try {
    app.first.focus();app.first.click();app.dialog.querySelector('[data-contact-close]').click();
    assert.equal(app.dialog.open,false);assert.equal(app.document.activeElement,app.first);
    assert.equal(app.document.body.classList.contains('catarinense-contact-open'),false);
  } finally {app.close();}
});
test('closing through the native dialog event also restores focus and document scroll', () => {
  const app=setup();try {
    app.first.click();app.dialog.close();
    assert.equal(app.document.activeElement,app.first);
    assert.equal(app.document.body.classList.contains('catarinense-contact-open'),false);
  } finally {app.close();}
});
test('malformed button payload does not open a stale athlete dialog', () => {
  const app=setup();try {
    app.first.click();app.dialog.close();app.second.dataset.catarinenseContact='{invalid';app.second.click();
    assert.equal(app.dialog.open,false);
  } finally {app.close();}
});
test('a broken avatar falls back once without changing athlete identity', () => {
  const app=setup();try {
    app.first.click();const image=app.dialog.querySelector('[data-contact-avatar]');
    image.dispatchEvent(new app.dom.window.Event('error'));
    assert.equal(image.getAttribute('src'),'/assets/user.png');assert.equal(image.onerror,null);
    assert.equal(app.dialog.querySelector('[data-contact-id]').textContent,'ID 72');
  } finally {app.close();}
});
