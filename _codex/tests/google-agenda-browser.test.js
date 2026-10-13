const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {JSDOM}=require('jsdom');
const base=path.resolve(__dirname,'../../administracao/agenda');
const wait=()=>new Promise(r=>setTimeout(r,15));
async function setup(handler,query='') {
  let html=fs.readFileSync(path.join(base,'index.cfm'),'utf8');
  html=html.slice(html.indexOf('<!doctype html>')).replace(/<cfif[\s\S]*?<\/cfif>/gi,'').replace(/<cfoutput>[\s\S]*?<\/cfoutput>/gi,'test-csrf').replace(/<cf[^>]*>/gi,'').replace(/<script[\s\S]*?<\/script>/g,'');
  const dom=new JSDOM(html,{url:'https://business.roadrunners.run/administracao/agenda/'+query,runScripts:'outside-only'});
  const w=dom.window,calls=[];
  w.HTMLDialogElement.prototype.showModal=function(){this.open=true;};w.HTMLDialogElement.prototype.close=function(){this.open=false;};w.confirm=()=>true;
  w.fetch=async(url,options)=>{const body=Object.fromEntries(new URLSearchParams(options.body));calls.push(body);let data=await handler(body);return {ok:data.success!==false,json:async()=>({success:true,...data})};};
  w.eval(fs.readFileSync(path.join(base,'assets/calendar-model.js'),'utf8'));w.eval(fs.readFileSync(path.join(base,'assets/agenda.js'),'utf8'));await wait();return {w,calls,close:()=>dom.window.close()};
}
const status={connected:true,calendars:[{id:'calendar@example.com',summary:'Operação'}]};
test('disconnected screen prevents event creation',async()=>{
  const app=await setup(()=>({connected:false,calendars:[]}));
  assert.equal(app.w.document.getElementById('agendaNew').disabled,true);assert.match(app.w.document.getElementById('agendaStatus').textContent,/Conecte/);app.close();
});
test('untrusted event title is text, and a user can save a new all-day event with explicit notifications',async()=>{
  const today=new Date().toISOString().slice(0,10);
  const app=await setup(b=>b.action==='status'?status:b.action==='events'?{items:[{id:'e1',summary:'<img src=x onerror=alert(1)>',start:{date:today},end:{date:'2099-01-01'}}]}:{event:{id:'saved'}});
  const d=app.w.document;
  assert.equal(d.querySelector('#agendaEvents img'),null);
  d.getElementById('agendaNew').click();const form=d.getElementById('agendaEventForm');
  form.elements.summary.value='Reunião';form.elements.allDay.checked=true;form.elements.allDay.dispatchEvent(new app.w.Event('change'));
  form.elements.start.value='2026-09-05';form.elements.end.value='2026-09-06';form.elements.send_updates.value='all';
  form.dispatchEvent(new app.w.Event('submit',{cancelable:true}));await wait();
  const saved=app.calls.find(c=>c.action==='save');assert.ok(saved);const event=JSON.parse(saved.event);
  assert.equal(event.allDay,true);assert.equal(event.end,'2026-09-06');assert.equal(saved.send_updates,'all');assert.equal(saved.csrf_token,'test-csrf');app.close();
});
test('Kanban opens the existing linked event instead of creating a duplicate',async()=>{
  const app=await setup(b=>b.action==='status'?status:b.action==='events'?{items:[]}:b.action==='card'?{card:{id:'a'.repeat(24),name:'Cartão'},link:{calendarId:'calendar@example.com',eventId:'linked'}}:{event:{id:'linked',etag:'"v1"',summary:'Existente',start:{date:'2026-09-05'},end:{date:'2026-09-06'}}},'?card_id='+ 'a'.repeat(24));
  assert.equal(app.w.document.getElementById('agendaEventHeading').textContent,'Editar compromisso');assert.equal(app.calls.filter(c=>c.action==='save').length,0);assert.equal(app.calls.find(c=>c.action==='event').event_id,'linked');app.close();
});
test('a server conflict keeps the editor open and shows the error',async()=>{
  const app=await setup(b=>b.action==='status'?status:b.action==='events'?{items:[]}:{success:false,message:'O evento mudou. Reabra-o antes de salvar.'});
  const d=app.w.document;d.getElementById('agendaNew').click();const form=d.getElementById('agendaEventForm');form.elements.summary.value='Teste';form.elements.send_updates.value='none';form.dispatchEvent(new app.w.Event('submit',{cancelable:true}));await wait();
  assert.equal(d.getElementById('agendaEventDialog').open,true);assert.match(d.getElementById('agendaEventError').textContent,/evento mudou/);app.close();
});
const richEvent={id:'rich',etag:'"v1"',summary:'Reunião de operação',location:'Florianópolis',description:'Pauta da semana',start:{dateTime:'2026-10-10T09:00:00-03:00'},end:{dateTime:'2026-10-10T10:30:00-03:00'},organizer:{email:'host@example.com',displayName:'Equipe'},hangoutLink:'https://meet.google.com/abc-defg-hij',htmlLink:'https://calendar.google.com/calendar/event?eid=rich',attendees:[{email:'ana@example.com',displayName:'Ana',responseStatus:'accepted'},{email:'bob@example.com',responseStatus:'declined'}],reminders:{useDefault:false,overrides:[{method:'popup',minutes:30}]}};
async function richSetup(){
  const app=await setup(b=>b.action==='status'?status:b.action==='events'?{items:[richEvent]}:b.action==='event'?{event:richEvent}:{event:{id:'saved'}});
  app.w.document.getElementById('agendaDate').value='2026-10-10';app.w.document.getElementById('agendaDate').dispatchEvent(new app.w.Event('change'));await wait();
  app.w.document.querySelector('.agenda-event').click();await wait();return app;
}
test('editor shows meeting, maps, duration, guest RSVP and accessible keyboard tabs without writes',async()=>{
  const app=await richSetup(),d=app.w.document;
  assert.match(d.querySelector('.agenda-event').textContent,/1h 30min/);
  assert.equal(d.getElementById('agendaMeetingLink').href,richEvent.hangoutLink);
  assert.match(d.getElementById('agendaMapLink').href,/maps.*Florian/);
  const details=d.querySelector('[role=tab][data-panel=details]');details.dispatchEvent(new app.w.KeyboardEvent('keydown',{key:'ArrowRight',bubbles:true}));
  assert.equal(d.querySelector('[data-panel=participants]').getAttribute('aria-selected'),'true');
  assert.equal(d.getElementById('agendaPanelParticipants').hidden,false);
  assert.match(d.getElementById('agendaGuestList').textContent,/Confirmado/);assert.match(d.getElementById('agendaGuestList').textContent,/Recusado/);
  assert.equal(app.calls.filter(c=>c.action==='save').length,0);app.close();
});
test('guest editor adds pasted addresses, deduplicates, edits and removes rows, preserving explicit notification policy',async()=>{
  const app=await richSetup(),d=app.w.document,form=d.getElementById('agendaEventForm');
  d.getElementById('agendaGuestInput').value='ANA@example.com; carol@example.com\ndan@example.com';d.getElementById('agendaAddGuests').click();
  assert.equal(d.querySelectorAll('.agenda-guest').length,4);
  const bob=d.querySelector('[data-email="bob@example.com"]');bob.querySelector('[data-guest-edit]').click();bob.querySelector('input').value='newbob@example.com';bob.querySelector('[data-guest-confirm]').click();
  assert.equal(d.activeElement,d.querySelector('[data-email="newbob@example.com"] [data-guest-edit]'));
  d.querySelector('[data-email="dan@example.com"] [data-guest-remove]').click();
  d.getElementById('agendaGuestInput').value='bad address';d.getElementById('agendaAddGuests').click();assert.match(d.getElementById('agendaGuestError').textContent,/inválido/i);
  d.getElementById('agendaGuestInput').value='';form.elements.send_updates.value='all';form.dispatchEvent(new app.w.Event('submit',{cancelable:true}));await wait();
  const saved=app.calls.find(c=>c.action==='save');assert.deepEqual(JSON.parse(saved.event).attendees,['ana@example.com','newbob@example.com','carol@example.com']);assert.equal(saved.etag,'"v1"');assert.equal(saved.send_updates,'all');app.close();
});
test('unsaved changes survive rejected cancellation and reminder edits are sent only when changed',async()=>{
  const app=await richSetup(),d=app.w.document,form=d.getElementById('agendaEventForm');
  form.elements.location.value='Novo local';form.elements.location.dispatchEvent(new app.w.Event('input',{bubbles:true}));
  app.w.confirm=()=>false;d.querySelector('#agendaEventDialog [data-close]').click();assert.equal(d.getElementById('agendaEventDialog').open,true);
  assert.equal(d.getElementById('agendaReminderList').querySelector('input').value,'30');
  d.getElementById('agendaReminderList').querySelector('input').value='45';d.getElementById('agendaReminderList').querySelector('input').dispatchEvent(new app.w.Event('input',{bubbles:true}));
  app.w.confirm=()=>true;form.elements.send_updates.value='none';form.dispatchEvent(new app.w.Event('submit',{cancelable:true}));await wait();
  const saved=JSON.parse(app.calls.find(c=>c.action==='save').event);assert.deepEqual(saved.reminders,{useDefault:false,overrides:[{method:'popup',minutes:45}]});app.close();
});
test('search finds guests even when their email is absent from the title and description',async()=>{
  const app=await richSetup(),d=app.w.document;app.w.confirm=()=>true;d.querySelector('#agendaEventDialog [data-close]').click();
  d.getElementById('agendaSearch').value='ana@example.com';d.getElementById('agendaSearch').dispatchEvent(new app.w.Event('input'));assert.ok(d.querySelector('.agenda-event'));app.close();
});
test('unsafe meeting and Google links remain hidden, and organizer rows cannot be edited',async()=>{
  const event={...richEvent,location:'http://example.com/venue',hangoutLink:'javascript:alert(1)',htmlLink:'https://user:secret@example.com/',attendees:[{email:'host@example.com',organizer:true,responseStatus:'accepted'}]};
  const app=await setup(b=>b.action==='status'?status:b.action==='events'?{items:[event]}:{event}),d=app.w.document;
  d.getElementById('agendaDate').value='2026-10-10';d.getElementById('agendaDate').dispatchEvent(new app.w.Event('change'));await wait();d.querySelector('.agenda-event').click();await wait();
  assert.equal(d.getElementById('agendaMeetingLink').hasAttribute('href'),false);assert.equal(d.getElementById('agendaGoogleLink').hasAttribute('href'),false);
  assert.equal(d.getElementById('agendaMapLink').hidden,true);
  assert.equal(d.querySelectorAll('[data-guest-edit],[data-guest-remove]').length,0);app.close();
});
test('readonly special events keep viewing actions and tabs usable but prevent mutations',async()=>{
  const event={...richEvent,eventType:'outOfOffice'},app=await setup(b=>b.action==='status'?status:b.action==='events'?{items:[event]}:{event}),d=app.w.document;
  d.getElementById('agendaDate').value='2026-10-10';d.getElementById('agendaDate').dispatchEvent(new app.w.Event('change'));await wait();d.querySelector('.agenda-event').click();await wait();
  assert.equal(d.getElementById('agendaSave').hidden,true);assert.equal(d.getElementById('agendaDelete').hidden,true);assert.equal(d.getElementById('agendaTabParticipants').disabled,false);assert.equal(d.getElementById('agendaCopyMeeting').disabled,false);assert.equal(d.getElementById('agendaEventForm').elements.summary.disabled,true);app.close();
});
test('all-day cards do not repeat the same time label twice',async()=>{
  const event={id:'day',summary:'Dia inteiro',start:{date:'2026-10-10'},end:{date:'2026-10-11'}},app=await setup(b=>b.action==='status'?status:{items:[event]}),d=app.w.document;
  d.getElementById('agendaDate').value='2026-10-10';d.getElementById('agendaDate').dispatchEvent(new app.w.Event('change'));await wait();assert.equal(d.querySelector('.agenda-event-time').textContent,'Dia inteiro');app.close();
});
test('pending guest edits cannot be silently discarded by adding another guest',async()=>{
  const app=await richSetup(),d=app.w.document;
  d.querySelector('[data-email="bob@example.com"] [data-guest-edit]').click();d.querySelector('.agenda-guest input').value='updated@example.com';
  d.getElementById('agendaGuestInput').value='another@example.com';d.getElementById('agendaAddGuests').click();
  assert.equal(d.querySelector('.agenda-guest input')?.value,'updated@example.com');assert.match(d.getElementById('agendaGuestError').textContent,/edição/);app.close();
});
test('missing notification choice prevents writes even though the form has hidden tabs',async()=>{
  const app=await richSetup(),d=app.w.document;d.getElementById('agendaEventForm').dispatchEvent(new app.w.Event('submit',{cancelable:true}));await wait();assert.equal(app.calls.filter(c=>c.action==='save').length,0);app.close();
});
test('unchanged reminders are omitted so a guest/title edit preserves all existing reminders',async()=>{
  const app=await richSetup(),d=app.w.document,form=d.getElementById('agendaEventForm');form.elements.summary.value='Título ajustado';form.elements.send_updates.value='none';form.dispatchEvent(new app.w.Event('submit',{cancelable:true}));await wait();assert.equal(Object.hasOwn(JSON.parse(app.calls.find(c=>c.action==='save').event),'reminders'),false);app.close();
});
