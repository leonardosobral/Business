const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const modulePath = path.resolve(__dirname, '../../desafios/assets/catarinense-contact.js');
const implementation = fs.existsSync(modulePath) ? require(modulePath) : {};
function contact(data) {
  assert.equal(typeof implementation.contact, 'function', 'The athlete contact modal must provide its contact model');
  return implementation.contact(data);
}

// Breaks caught: incorrect recipient, duplicate country/area code, unsafe links,
// empty data presented as an actionable contact, and CF uppercase JSON keys.
test('contact actions use the athlete ID and profile, not the row or ranking position', () => {
  const value = contact({id:31521, nome:'Daniel Porto Camilo', tag:'daniel porto', cidade:'Criciúma', estado:'SC', equipe:'Equipe A'});
  assert.equal(value.name, 'Daniel Porto Camilo');
  assert.equal(value.location, 'Criciúma / SC');
  assert.equal(value.team, 'Equipe A');
  assert.equal(value.links.chat, 'https://roadrunners.run/mensagens/?destinatario=31521');
  assert.equal(value.links.profile, 'https://roadrunners.run/atleta/daniel%20porto/');
});
test('Brazilian local, national and international phone formats yield the same contact', () => {
  for (const raw of ['99999-1234', '(48) 99999-1234', '+55 (48) 99999-1234', '5548999991234', '005548999991234']) {
    const value = contact({ddi_usuario:'55',ddd_usuario:'48',telefone_usuario:raw});
    assert.equal(value.links.phone, 'tel:+5548999991234', raw);
    assert.equal(value.links.whatsapp, 'https://wa.me/5548999991234', raw);
  }
});
test('a national number beginning with area code 55 still receives its country code', () => {
  assert.equal(contact({telefone_usuario:'55999991234'}).links.phone, 'tel:+5555999991234');
});
test('international contact does not silently receive Brazilian country or area code', () => {
  assert.equal(contact({ddi_usuario:'1',telefone_usuario:'2025550123'}).links.phone, 'tel:+12025550123');
  assert.equal(contact({ddi_usuario:'351',telefone_usuario:'912345678'}).links.phone, 'tel:+351912345678');
});
test('a specific WhatsApp number takes precedence without changing the telephone', () => {
  const value = contact({ddd_usuario:'48',telefone_usuario:'999991234',whatsapp:'https://wa.me/5548988884321?text=Oi'});
  assert.equal(value.links.whatsapp, 'https://wa.me/5548988884321');
  assert.equal(value.links.phone, 'tel:+5548999991234');
});
test('WhatsApp send links and local saved numbers normalize to an unambiguous HTTPS link', () => {
  assert.equal(contact({whatsapp:'https://api.whatsapp.com/send?phone=5548999991234'}).links.whatsapp, 'https://wa.me/5548999991234');
  assert.equal(contact({whatsapp:'(48) 99999-1234'}).links.whatsapp, 'https://wa.me/5548999991234');
});
test('numeric profile WhatsApp preserves its existing international recipient independently of telephone DDI', () => {
  for (const data of [
    {ddi_usuario:'351',whatsapp:'351912345678'},
    {ddi_usuario:'1',whatsapp:'12025550123'},
    {ddi_usuario:'55',whatsapp:'351912345678'},
    {ddi_usuario:'55',whatsapp:'12025550123'}
  ]) assert.equal(contact(data).links.whatsapp, 'https://wa.me/' + data.whatsapp);
});
test('Instagram handles and profile links produce a canonical profile URL', () => {
  for (const raw of ['@atleta.sc','atleta.sc','https://www.instagram.com/atleta.sc/?igsh=abc','instagram.com/atleta.sc/']) {
    assert.equal(contact({instagram:raw}).links.instagram, 'https://www.instagram.com/atleta.sc/', raw);
  }
});
test('external or executable social links never become contact actions', () => {
  for (const raw of ['javascript:alert(1)', 'https://instagram.com.evil.test/user', 'https://evil.test/atleta', 'https://user:pass@instagram.com/atleta', 'https://www.instagram.com/p/post/']) {
    assert.equal(contact({instagram:raw}).links.instagram, '', raw);
  }
  assert.equal(contact({whatsapp:'https://wa.me.evil.test/5548999991234'}).links.whatsapp, '');
});
test('invalid and absent contact data have no actionable links', () => {
  const value = contact({id:0,email:'user@example.com\r\nBcc:other@example.com',telefone_usuario:'ramal 123',tag:'',imagem_usuario:'javascript:alert(1)'});
  assert.equal(value.links.email, '');
  assert.equal(value.links.phone, '');
  assert.equal(value.links.whatsapp, '');
  assert.equal(value.links.profile, '');
  assert.equal(value.links.chat, '');
  assert.equal(value.avatar, '/assets/user.png');
});
test('email actions encode special characters and expose only a mailto address', () => {
  const value = contact({email:'athlete+team@example.com'});
  assert.equal(value.email, 'athlete+team@example.com');
  assert.equal(value.links.email, 'mailto:athlete%2Bteam@example.com');
});
test('Adobe ColdFusion uppercase keys remain compatible with the contact model', () => {
  const value = contact({ID:72,NOME:'Atleta',EMAIL:'athlete@example.com',TELEFONE_USUARIO:'48999991234',INSTAGRAM:'@atleta'});
  assert.equal(value.links.chat, 'https://roadrunners.run/mensagens/?destinatario=72');
  assert.equal(value.links.email, 'mailto:athlete@example.com');
  assert.equal(value.links.instagram, 'https://www.instagram.com/atleta/');
});
