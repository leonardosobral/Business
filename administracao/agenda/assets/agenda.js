(function () {
  'use strict';
  const root=document.getElementById('googleAgenda'); if(!root) return;
  const M=window.AgendaModel, $=id=>document.getElementById(id);
  const eventForm=$('agendaEventForm'), settingsForm=$('agendaSettingsForm');
  const field=name=>eventForm.elements.namedItem(name);
  let connected=false, events=[], editing=null, card=null, requestId='', generation=0, busy=false;
  const cardId=new URLSearchParams(location.search).get('card_id');
  function node(tag,text,className) { const n=document.createElement(tag); if(text!=null)n.textContent=text;if(className)n.className=className;return n; }
  function status(text,error=false) { $('agendaStatus').textContent=text;$('agendaStatus').className=error?'text-danger':'text-muted'; }
  async function api(action,data={}) {
    const response=await fetch('/administracao/agenda/api.cfm',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({action,csrf_token:root.dataset.csrf,...data})});
    let result;try { result=await response.json(); } catch {throw new Error('A sessão expirou ou o servidor não respondeu. Recarregue a página.');}
    if(!response.ok || !result.success)throw new Error(result.message||'Não foi possível concluir a operação.');return result;
  }
  function protect(fn,errorTarget) {return async function(event){if(event)event.preventDefault();if(busy)return;busy=true;const buttons=[...root.querySelectorAll('button')];const previous=buttons.map(b=>b.disabled);buttons.forEach(b=>b.disabled=true);try{await fn(event);}catch(e){if(errorTarget)$(errorTarget).textContent=e.message;else status(e.message,true);}finally{busy=false;buttons.forEach((b,i)=>b.disabled=previous[i]);$('agendaSettings').disabled=!connected;$('agendaNew').disabled=!connected||!$('agendaCalendar').value;}};}
  function formatDay(value){return new Intl.DateTimeFormat('pt-BR',{timeZone:'UTC',weekday:'short',day:'2-digit',month:'short'}).format(new Date(value+'T12:00:00Z'));}
  function safeLink(anchor,value){try{const u=new URL(value);if(u.protocol!=='https:')throw new Error();anchor.href=u.href;anchor.hidden=false;}catch{anchor.removeAttribute('href');anchor.hidden=true;}}
  async function loadStatus() {
    const data=await api('status');connected=data.connected;$('agendaConnect').textContent=connected?'Reconectar Google':'Conectar Google';$('agendaSettings').disabled=!connected;
    const select=$('agendaCalendar'),old=select.value;select.replaceChildren();
    data.calendars.forEach(c=>{const o=node('option',c.summary);o.value=c.id;select.appendChild(o);});if([...select.options].some(o=>o.value===old))select.value=old;
    select.disabled=!connected||!data.calendars.length;$('agendaNew').disabled=select.disabled;
    status(!connected?'Conecte a conta Google para visualizar os compromissos.':!data.calendars.length?'Conta conectada. Abra Configurar agendas e selecione pelo menos uma agenda.':'Conta conectada.');
    if(connected&&select.value)await loadEvents();else {$('agendaEvents').replaceChildren(node('p','Sua agenda aparecerá aqui após a conexão e seleção.','agenda-empty'));}
  }
  async function loadEvents(){
    if(!connected||!$('agendaCalendar').value)return;
    const date=$('agendaDate').value;if(!date)return;const seq=++generation;
    events=[];$('agendaEvents').replaceChildren(node('p','Carregando compromissos…','agenda-empty'));
    $('agendaEvents').setAttribute('aria-busy','true');status('Carregando compromissos…');
    try {const period=M.range(date,$('agendaView').value);const result=await api('events',{calendar_id:$('agendaCalendar').value,...period});if(seq!==generation)return;events=result.items||[];render();status(events.length+' compromissos no período.');}
    catch(e){if(seq===generation){events=[];$('agendaEvents').replaceChildren();status(e.message,true);}}
    finally{if(seq===generation)$('agendaEvents').setAttribute('aria-busy','false');}
  }
  function render(){
    const period=M.range($('agendaDate').value,$('agendaView').value),list=$('agendaView').value==='list';
    $('agendaPeriod').textContent=formatDay(period.from)+' — '+formatDay(M.add(period.until,-1));
    const container=$('agendaEvents');container.replaceChildren();container.className=list?'agenda-list':'agenda-grid';
    const search=$('agendaSearch').value.toLocaleLowerCase('pt-BR');const filtered=events.filter(e=>[e.summary,e.description,e.location].join(' ').toLocaleLowerCase('pt-BR').includes(search));
    let total=0;
    for(let day=period.from;day<period.until;day=M.add(day,1)){
      const matches=filtered.filter(e=>M.onDay(e,day));if(list&&!matches.length)continue;
      const section=node('section',null,list?'agenda-list-day':'agenda-day'+(day===M.local(new Date()).slice(0,10)?' is-today':''));section.appendChild(node('h3',formatDay(day),'agenda-day-heading'));
      matches.forEach(e=>{const time=e.start.date?'Dia inteiro':M.local(e.start.dateTime).slice(11);const button=node('button',time+' · '+(e.summary||'(Sem título)')+(e.recurringEventId?' ↻':''),'agenda-event');button.type='button';button.addEventListener('click',protect(()=>openEvent(e.id)));section.appendChild(button);total++;});container.appendChild(section);
    }
    if(list&&!total)container.appendChild(node('p','Nenhum compromisso encontrado neste período.','agenda-empty'));
  }
  function dateType(){const allDay=field('allDay').checked;for(const name of ['start','end']){const value=field(name).value;field(name).type=allDay?'date':'datetime-local';field(name).value=value?(allDay?value.slice(0,10):value.length===10?value+'T09:00':value):'';}$('agendaEndLabel').textContent=allDay?'Data final (exclusiva)':'Término';}
  function fill(event){
    editing=event||null;eventForm.reset();$('agendaEventError').textContent='';requestId=crypto.randomUUID();
    $('agendaEventHeading').textContent=event?'Editar compromisso':'Novo compromisso';
    field('summary').value=event?.summary||card?.name||'';field('description').value=event?.description||card?.description||'';field('location').value=event?.location||'';
    field('allDay').checked=!!event?.start?.date;dateType();
    const start=event?(event.start.date||M.local(event.start.dateTime)):(card?.due?M.local(card.due):$('agendaDate').value+'T09:00');
    field('start').value=start;field('end').value=event?(event.end.date||M.local(event.end.dateTime)):(start.slice(0,10)+'T'+(start.slice(11,13)==='23'?'23:59':String(Number(start.slice(11,13))+1).padStart(2,'0')+start.slice(13)));
    field('attendees').value=(event?.attendees||[]).map(a=>a.email).join(', ');
    $('agendaRepeatFields').hidden=!!event;$('agendaDelete').hidden=!event;$('agendaEditSeries').hidden=!event?.recurringEventId;
    $('agendaRecurrenceNotice').textContent=event?.recurringEventId?'Você está editando somente esta ocorrência.':event?.recurrence?'Você está editando a série inteira. A regra de repetição será preservada.':'';
    $('agendaCardNotice').textContent=card&&!event?'Vincular ao cartão: '+card.name:'';
    safeLink($('agendaGoogleLink'),event?.htmlLink||'');
    $('agendaEventDialog').showModal();field('summary').focus();
  }
  async function openEvent(id,scope='occurrence'){const r=await api('event',{calendar_id:$('agendaCalendar').value,event_id:id,scope});fill(r.event);}
  async function openCard(){if(!cardId||!connected)return;const r=await api('card',{card_id:cardId});card=r.card;if(r.link.calendarId)$('agendaCalendar').value=r.link.calendarId;if(r.link.eventId){await loadEvents();await openEvent(r.link.eventId);}else if($('agendaCalendar').value)fill(null);else status('Selecione uma agenda em Configurar agendas para agendar o cartão.');}
  $('agendaConnect').onclick=protect(async()=>{const r=await api('connect');location.assign(r.url);});
  $('agendaSettings').onclick=protect(async()=>{const r=await api('calendars');$('agendaChoices').replaceChildren();$('agendaSettingsError').textContent='';(r.items||[]).forEach(c=>{const label=node('label');const input=node('input');input.type='checkbox';input.value=c.id;input.checked=c.selected;label.append(input,node('span',c.summary));$('agendaChoices').append(label);});if(!r.items.length)$('agendaChoices').append(node('p','Nenhuma agenda própria encontrada.'));$('agendaSettingsDialog').showModal();});
  settingsForm.onsubmit=protect(async()=>{await api('select_calendars',{ids:JSON.stringify([...$('agendaChoices').querySelectorAll('input:checked')].map(e=>e.value))});$('agendaSettingsDialog').close();await loadStatus();await openCard();},'agendaSettingsError');
  $('agendaDisconnect').onclick=protect(async()=>{if(!confirm('Desconectar a conta Google para todos os administradores do Business? Os eventos serão mantidos no Google.'))return;const r=await api('disconnect');$('agendaSettingsDialog').close();await loadStatus();status(r.message);},'agendaSettingsError');
  $('agendaNew').onclick=()=>{card=null;fill(null);};
  eventForm.onsubmit=protect(async()=>{
    if(!eventForm.reportValidity())return;
    if(editing?.recurrence&&!confirm('Salvar as alterações na série inteira?'))return;
    const event={summary:field('summary').value,description:field('description').value,location:field('location').value,allDay:field('allDay').checked,start:field('start').value,end:field('end').value,attendees:field('attendees').value.split(/[,;\n]/).map(s=>s.trim()).filter(Boolean),repeat:field('repeat').value,count:Number(field('count').value)};
    await api('save',{calendar_id:$('agendaCalendar').value,event_id:editing?.id||'',etag:editing?.etag||'',card_id:!editing&&card?card.id:'',request_id:requestId,send_updates:field('send_updates').value,event:JSON.stringify(event)});
    $('agendaEventDialog').close();card=null;await loadEvents();
  },'agendaEventError');
  $('agendaDelete').onclick=protect(async()=>{if(!editing)return;if(!field('send_updates').reportValidity())return;if(!confirm(editing.recurrence?'Excluir toda a série de compromissos?':editing.recurringEventId?'Excluir somente esta ocorrência?':'Excluir este compromisso do Google?'))return;await api('delete',{calendar_id:$('agendaCalendar').value,event_id:editing.id,etag:editing.etag,send_updates:field('send_updates').value});$('agendaEventDialog').close();await loadEvents();},'agendaEventError');
  $('agendaEditSeries').onclick=protect(async()=>{if(!confirm('Abrir a série inteira? As alterações não salvas serão descartadas.'))return;await openEvent(editing.id,'series');},'agendaEventError');
  field('allDay').onchange=dateType;
  root.querySelectorAll('[data-close]').forEach(b=>b.onclick=()=>b.closest('dialog').close());
  $('agendaDate').value=M.local(new Date()).slice(0,10);
  for(const id of ['agendaCalendar','agendaView','agendaDate'])$(id).onchange=loadEvents;
  $('agendaSearch').oninput=()=>{if($('agendaDate').value)render();};$('agendaRefresh').onclick=loadEvents;
  $('agendaPrevious').onclick=()=>{$('agendaDate').value=M.move($('agendaDate').value,$('agendaView').value,-1);loadEvents();};
  $('agendaNext').onclick=()=>{$('agendaDate').value=M.move($('agendaDate').value,$('agendaView').value,1);loadEvents();};
  $('agendaToday').onclick=()=>{$('agendaDate').value=M.local(new Date()).slice(0,10);loadEvents();};
  loadStatus().then(openCard).catch(e=>status(e.message,true));
}());
