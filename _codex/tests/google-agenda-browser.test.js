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
