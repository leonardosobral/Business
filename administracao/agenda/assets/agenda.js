(function () {
  'use strict';
  const root=document.getElementById('googleAgenda'); if(!root)return;
  const M=window.AgendaModel, $=id=>document.getElementById(id);
  const eventForm=$('agendaEventForm'), settingsForm=$('agendaSettingsForm'), dialog=$('agendaEventDialog');
  const field=name=>eventForm.elements.namedItem(name);
  const labels={accepted:'Confirmado',declined:'Recusado',tentative:'Talvez',needsAction:'Aguardando resposta'};
  const cardId=new URLSearchParams(location.search).get('card_id');
  let connected=false,events=[],editing=null,card=null,requestId='',generation=0,busy=false,guests=[],baseline='',remindersChanged=false;
  function node(tag,text,className){const n=document.createElement(tag);if(text!=null)n.textContent=text;if(className)n.className=className;return n;}
  function status(text,error=false){$('agendaStatus').textContent=text;$('agendaStatus').className=error?'text-danger':'agenda-muted';}
  function notice(id,text){$(id).textContent=text;$(id).hidden=!text;}
  function safeLink(anchor,value){const url=M.https(value);anchor.hidden=!url;if(url)anchor.href=url;else anchor.removeAttribute('href');}
  function editable(){return !editing||(!editing.locked&&(!editing.eventType||editing.eventType==='default'));}
  function syncControls(){
    $('agendaSettings').disabled=busy||!connected;$('agendaNew').disabled=busy||!connected||!$('agendaCalendar').value;$('agendaConnect').disabled=busy;
    dialog.querySelectorAll('input,textarea,select,button:not([data-close]):not([role=tab])').forEach(e=>e.disabled=busy||!editable());
    $('agendaEditSeries').disabled=busy;$('agendaCopyMeeting').disabled=busy;
    $('agendaAddReminder').disabled=busy||!editable()||$('agendaReminderList').children.length>=5;
    settingsForm.querySelectorAll('button').forEach(e=>e.disabled=busy);
    field('count').disabled=busy||!!editing||field('repeat').value==='none';
  }
  async function api(action,data={}){
    const response=await fetch('/administracao/agenda/api.cfm',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({action,csrf_token:root.dataset.csrf,...data})});
    let result;try{result=await response.json();}catch{throw new Error('A sessão expirou ou o servidor não respondeu. Recarregue a página.');}
    if(!response.ok||!result.success)throw new Error(result.message||'Não foi possível concluir a operação.');return result;
  }
  function protect(fn,errorTarget){return async function(event){
    if(event)event.preventDefault();if(busy)return;busy=true;syncControls();
    try{await fn(event);}catch(e){if(errorTarget)$(errorTarget).textContent=e.message;else status(e.message,true);}
    finally{busy=false;syncControls();}
  };}
  function formatDay(value){return new Intl.DateTimeFormat('pt-BR',{timeZone:'UTC',weekday:'short',day:'2-digit',month:'short'}).format(new Date(value+'T12:00:00Z'));}
  function stamp(value){if(!value||!Number.isFinite(new Date(value).getTime()))return 'Não informado';return new Intl.DateTimeFormat('pt-BR',{timeZone:M.zone,dateStyle:'short',timeStyle:'short'}).format(new Date(value));}
  async function loadStatus(){
    const data=await api('status');connected=data.connected;$('agendaConnect').textContent=connected?'Reconectar Google':'Conectar Google';
    const select=$('agendaCalendar'),old=select.value;select.replaceChildren();
    data.calendars.forEach(c=>{const o=node('option',c.summary);o.value=c.id;select.appendChild(o);});if([...select.options].some(o=>o.value===old))select.value=old;
    select.disabled=!connected||!data.calendars.length;syncControls();
    status(!connected?'Conecte a conta Google para visualizar os compromissos.':!data.calendars.length?'Conta conectada. Abra Configurar agendas e selecione pelo menos uma agenda.':'Conta conectada.');
    if(connected&&select.value)await loadEvents();else $('agendaEvents').replaceChildren(node('p','Sua agenda aparecerá aqui após a conexão e seleção.','agenda-empty'));
  }
  async function loadEvents(){
    if(!connected||!$('agendaCalendar').value||!$('agendaDate').value)return;
    const seq=++generation;events=[];$('agendaEvents').replaceChildren(node('p','Carregando compromissos…','agenda-empty'));
    $('agendaEvents').setAttribute('aria-busy','true');status('Carregando compromissos…');
    try{const period=M.range($('agendaDate').value,$('agendaView').value),result=await api('events',{calendar_id:$('agendaCalendar').value,...period});if(seq!==generation)return;events=result.items||[];render();status(events.length+' compromissos no período.');}
    catch(e){if(seq===generation){events=[];$('agendaEvents').replaceChildren();status(e.message,true);}}
    finally{if(seq===generation)$('agendaEvents').setAttribute('aria-busy','false');}
  }
  function eventButton(event){
    const button=node('button',null,'agenda-event');button.type='button';
    const time=event.start.date?'Dia inteiro':M.local(event.start.dateTime).slice(11);
    const duration=M.duration(event);
    button.append(node('span',duration&&duration!==time?time+' · '+duration:time,'agenda-event-time'),node('strong',event.summary||'(Sem título)','agenda-event-title'));
    if(event.location)button.append(node('span','⌖ '+event.location,'agenda-event-location'));
    const meta=node('span',null,'agenda-event-badges'),responses=M.responses(event.attendees);
    if(M.meeting(event))meta.append(node('span','Reunião on-line','agenda-chip is-online'));
    if(responses.total)meta.append(node('span',responses.accepted+'/'+responses.total+' confirmados','agenda-chip'));
    if(event.recurringEventId)meta.append(node('span','↻ Recorrente','agenda-chip'));
    button.append(meta);button.addEventListener('click',protect(()=>openEvent(event.id)));return button;
  }
  function render(){
    const period=M.range($('agendaDate').value,$('agendaView').value),list=$('agendaView').value==='list';
    $('agendaPeriod').textContent=formatDay(period.from)+' — '+formatDay(M.add(period.until,-1));
    const container=$('agendaEvents');container.replaceChildren();container.className=list?'agenda-list':'agenda-grid';
    const filtered=events.filter(e=>M.matches(e,$('agendaSearch').value));let total=0;
    for(let day=period.from;day<period.until;day=M.add(day,1)){
      const matches=filtered.filter(e=>M.onDay(e,day));if(list&&!matches.length)continue;
      const section=node('section',null,list?'agenda-list-day':'agenda-day'+(day===M.local(new Date()).slice(0,10)?' is-today':''));
      section.append(node('h3',formatDay(day),'agenda-day-heading'));matches.forEach(e=>{section.append(eventButton(e));total++;});container.append(section);
    }
    if(list&&!total)container.append(node('p','Nenhum compromisso encontrado neste período.','agenda-empty'));
  }
  function selectTab(panel,focus=false){
    dialog.querySelectorAll('[role=tab]').forEach(tab=>{const selected=tab.dataset.panel===panel;tab.setAttribute('aria-selected',String(selected));tab.tabIndex=selected?0:-1;$(tab.getAttribute('aria-controls')).hidden=!selected;if(selected&&focus)tab.focus();});
    dialog.querySelector('.agenda-dialog-body').scrollTop=0;
  }
  dialog.querySelectorAll('[role=tab]').forEach(tab=>{
    tab.onclick=()=>selectTab(tab.dataset.panel);
    tab.onkeydown=e=>{const tabs=[...dialog.querySelectorAll('[role=tab]')],index=tabs.indexOf(tab);let next;
      if(e.key==='ArrowRight')next=(index+1)%tabs.length;if(e.key==='ArrowLeft')next=(index+tabs.length-1)%tabs.length;
      if(e.key==='Home')next=0;if(e.key==='End')next=tabs.length-1;
      if(next!==undefined){e.preventDefault();selectTab(tabs[next].dataset.panel,true);}
    };
  });
  function dateType(){const allDay=field('allDay').checked;for(const name of ['start','end']){const value=field(name).value;field(name).type=allDay?'date':'datetime-local';field(name).value=value?(allDay?value.slice(0,10):value.length===10?value+'T09:00':value):'';}$('agendaEndLabel').textContent=allDay?'Data final (exclusiva)':'Término';$('agendaDateHint').hidden=!allDay;}
  function mapLink(){const place=field('location').value.trim();safeLink($('agendaMapLink'),place&&!/^https?:\/\//i.test(place)?'https://www.google.com/maps/search/?api=1&query='+encodeURIComponent(place):'');}
  function guestStatus(g){return Object.hasOwn(labels,g.responseStatus)?g.responseStatus:'needsAction';}
  function guestSummary(){
    const counts=M.responses(guests);$('agendaGuestCount').textContent=counts.total;
    const summary=$('agendaGuestSummary');summary.replaceChildren();
    for(const [key,label] of Object.entries(labels))summary.append(node('span',counts[key]+' · '+label,'agenda-rsvp is-'+key));
  }
  function guestButton(text,attribute,callback){const b=node('button',text,'agenda-icon-button');b.type='button';b.setAttribute(attribute,'');b.onclick=()=>{if(!busy&&editable())callback();};return b;}
  function renderGuests(){
    const list=$('agendaGuestList');list.replaceChildren();guestSummary();
    if(!guests.length)list.append(node('p','Nenhum convidado adicionado.','agenda-empty'));
    guests.forEach((g,index)=>{
      const row=node('div',null,'agenda-guest');row.dataset.email=g.email;
      const avatar=node('span',(g.displayName||g.email||'?').slice(0,2).toUpperCase(),'agenda-guest-avatar');avatar.setAttribute('aria-hidden','true');
      const copy=node('div',null,'agenda-guest-copy');copy.append(node('strong',g.displayName||g.email));if(g.displayName)copy.append(node('span',g.email,'agenda-muted'));
      const badge=node('span',g.organizer?'Organizador':labels[guestStatus(g)],'agenda-rsvp is-'+guestStatus(g));row.append(avatar,copy,badge);
      if(g.comment)copy.append(node('span',g.comment,'agenda-guest-comment'));
      if(!g.organizer){const actions=node('div',null,'agenda-guest-actions');actions.append(guestButton('Editar','data-guest-edit',()=>editGuest(row,index)),guestButton('Remover','data-guest-remove',()=>{if(pendingGuestEdit())return;guests.splice(index,1);renderGuests();focusGuest(index);changed();}));row.append(actions);}
      list.append(row);
    });syncControls();
  }
  function focusGuest(index){const rows=$('agendaGuestList').querySelectorAll('.agenda-guest');(rows[index]?.querySelector('[data-guest-edit]')||$('agendaGuestInput')).focus();}
  function editGuest(row,index){
    if(dialog.querySelector('[data-guest-confirm]')){$('agendaGuestError').textContent='Conclua a edição do e-mail anterior antes de editar outro.';return;}
    const original=guests[index],copy=row.querySelector('.agenda-guest-copy');copy.replaceChildren();
    const input=node('input');input.type='email';input.value=original.email;input.maxLength=254;input.required=true;input.className='form-control form-control-sm';input.setAttribute('aria-label','E-mail do participante');copy.append(input);
    const actions=row.querySelector('.agenda-guest-actions');actions.replaceChildren();
    const apply=()=>{try{const emails=M.parseGuests(input.value);if(emails.length!==1)throw new Error('Informe um e-mail válido.');if(guests.some((g,i)=>i!==index&&g.email.toLowerCase()===emails[0]))throw new Error('Este participante já foi adicionado.');if(emails[0]!==original.email.toLowerCase())guests[index]={email:emails[0],responseStatus:'needsAction'};$('agendaGuestError').textContent='';renderGuests();focusGuest(index);changed();}catch(e){$('agendaGuestError').textContent=e.message;input.focus();}};
    actions.append(guestButton('Aplicar','data-guest-confirm',apply),guestButton('Cancelar','data-guest-cancel',()=>{renderGuests();focusGuest(index);changed();}));
    input.onkeydown=e=>{if(e.key==='Enter'){e.preventDefault();apply();}};input.focus();
  }
  function pendingGuestEdit(){if(!dialog.querySelector('[data-guest-confirm]'))return false;$('agendaGuestError').textContent='Aplique ou cancele a edição do e-mail antes de alterar outros participantes.';selectTab('participants');return true;}
  function addGuests(){
    if(pendingGuestEdit())return false;
    try{const emails=M.parseGuests($('agendaGuestInput').value),newEmails=emails.filter(email=>!guests.some(g=>g.email.toLowerCase()===email));
      if(guests.length+newEmails.length>100)throw new Error('Informe até 100 participantes, incluindo o organizador.');
      newEmails.forEach(email=>guests.push({...editing?.attendees?.find(g=>g.email.toLowerCase()===email),email,responseStatus:editing?.attendees?.find(g=>g.email.toLowerCase()===email)?.responseStatus||'needsAction'}));$('agendaGuestInput').value='';$('agendaGuestError').textContent='';renderGuests();changed();return true;
    }catch(e){selectTab('participants');$('agendaGuestError').textContent=e.message;return false;}
  }
  function addReminder(value={method:'popup',minutes:30}){
    if($('agendaReminderList').children.length>=5)return;
    const row=node('div',null,'agenda-reminder'),method=node('select'),minutes=node('input'),remove=node('button','Remover','agenda-icon-button');
    method.className='form-select form-select-sm';method.setAttribute('aria-label','Tipo de lembrete');
    for(const [key,label] of [['popup','Notificação'],['email','E-mail']]){const o=node('option',label);o.value=key;method.append(o);}method.value=value.method;
    minutes.type='number';minutes.min=0;minutes.max=40320;minutes.step=1;minutes.required=true;minutes.value=value.minutes;minutes.className='form-control form-control-sm';minutes.setAttribute('aria-label','Minutos antes do início');
    remove.type='button';remove.onclick=()=>{if(busy||!editable())return;row.remove();remindersChanged=true;syncControls();changed();};row.append(method,minutes,node('span','min antes'),remove);$('agendaReminderList').append(row);syncControls();
  }
  function reminderPayload(){return {useDefault:$('agendaReminderMode').value==='default',...($('agendaReminderMode').value==='default'?{}:{overrides:$('agendaReminderMode').value==='none'?[]:[...$('agendaReminderList').children].map(row=>({method:row.querySelector('select').value,minutes:Number(row.querySelector('input').value)}))})};}
  function snapshot(){return JSON.stringify({fields:['summary','description','location','allDay','start','end','repeat','count','send_updates'].map(name=>field(name).type==='checkbox'?field(name).checked:field(name).value),guests:guests.map(g=>g.email),pending:$('agendaGuestInput').value,edit:dialog.querySelector('.agenda-guest input')?.value,reminders:reminderPayload()});}
  function dirty(){return !!baseline&&snapshot()!==baseline;}
  function changed(){if(baseline)$('agendaDirtyStatus').textContent=dirty()?'Alterações não salvas':'';}
  function closeEvent(){if(busy)return;if(dirty()&&!confirm('Descartar as alterações não salvas deste compromisso?'))return;dialog.close();baseline='';card=null;}
  function fill(event){
    baseline='';editing=event||null;guests=(event?.attendees||[]).map(g=>({...g}));eventForm.reset();$('agendaEventError').textContent='';$('agendaGuestError').textContent='';$('agendaCopyStatus').textContent='';$('agendaDirtyStatus').textContent='';requestId=crypto.randomUUID();remindersChanged=false;
    $('agendaEventHeading').textContent=event?(editable()?'Editar compromisso':'Consultar compromisso'):'Novo compromisso';
    $('agendaEventMeta').textContent=event?[M.duration(event),event.status==='tentative'?'A confirmar':'Confirmado',$('agendaCalendar').selectedOptions[0]?.textContent].filter(Boolean).join(' · '):'Preencha os dados e escolha como notificar os convidados.';
    field('summary').value=event?.summary||card?.name||'';field('description').value=event?.description||card?.description||'';field('location').value=event?.location||'';
    field('allDay').checked=!!event?.start?.date;dateType();
    const start=event?(event.start.date||M.local(event.start.dateTime)):(card?.due?M.local(card.due):$('agendaDate').value+'T09:00');
    field('start').value=start;field('end').value=event?(event.end.date||M.local(event.end.dateTime)):(start.slice(0,10)+'T'+(start.slice(11,13)==='23'?'23:59':String(Number(start.slice(11,13))+1).padStart(2,'0')+start.slice(13)));
    $('agendaRepeatFields').hidden=!!event;$('agendaDelete').hidden=!event||!editable();$('agendaSave').hidden=!editable();$('agendaEditSeries').hidden=!event?.recurringEventId;
    notice('agendaRecurrenceNotice',!editable()?'Este evento especial ou bloqueado só pode ser alterado no Google.':event?.recurringEventId?'Você está editando somente esta ocorrência.':event?.recurrence?'Você está editando a série inteira. A regra de repetição será preservada.':'');
    notice('agendaCardNotice',card&&!event?'Vincular ao cartão: '+card.name:'');safeLink($('agendaGoogleLink'),event?.htmlLink||'');mapLink();
    const meeting=M.meeting(event||{});safeLink($('agendaMeetingLink'),meeting);$('agendaCopyMeeting').hidden=!meeting;
    $('agendaMeetingInfo').textContent=meeting?meeting:'Sem link de reunião. Adicione a videoconferência pelo Google Calendar; o link aparecerá aqui ao reabrir o compromisso.';
    $('agendaOrganizer').replaceChildren();for(const [label,value] of [['Organizador',event?.organizer?.displayName?event.organizer.displayName+' · '+(event.organizer.email||''):event?.organizer?.email||'Conta da agenda selecionada'],['Criado em',stamp(event?.created)],['Atualizado em',stamp(event?.updated)]]){if(!event&&label!=='Organizador')continue;$('agendaOrganizer').append(node('dt',label),node('dd',value));}
    const reminders=event?.reminders,mode=!reminders||reminders.useDefault?'default':reminders.overrides?.length?'custom':'none';$('agendaReminderMode').value=mode;$('agendaReminderCustom').hidden=mode!=='custom';$('agendaReminderList').replaceChildren();(reminders?.overrides||[]).forEach(addReminder);
    renderGuests();selectTab('details');baseline=snapshot();if(!dialog.open)dialog.showModal();field('summary').focus();
  }
  async function openEvent(id,scope='occurrence'){const r=await api('event',{calendar_id:$('agendaCalendar').value,event_id:id,scope});fill(r.event);}
  async function openCard(){if(!cardId||!connected)return;const r=await api('card',{card_id:cardId});card=r.card;if(r.link.calendarId)$('agendaCalendar').value=r.link.calendarId;if(r.link.eventId){await loadEvents();await openEvent(r.link.eventId);}else if($('agendaCalendar').value)fill(null);else status('Selecione uma agenda em Configurar agendas para agendar o cartão.');}
  function validate(){
    if(dialog.querySelector('[data-guest-confirm]')){selectTab('participants');$('agendaEventError').textContent='Aplique ou cancele a edição do e-mail antes de salvar.';return false;}
    $('agendaReminderList').querySelectorAll('input,select').forEach(e=>e.disabled=$('agendaReminderMode').value!=='custom');
    if(eventForm.checkValidity())return true;
    const invalid=eventForm.querySelector(':invalid'),panel=invalid?.closest('[role=tabpanel]');if(panel)selectTab(panel.id==='agendaPanelParticipants'?'participants':panel.id==='agendaPanelOptions'?'options':'details');
    invalid?.reportValidity();invalid?.focus();return false;
  }
  $('agendaConnect').onclick=protect(async()=>{const r=await api('connect');location.assign(r.url);});
  $('agendaSettings').onclick=protect(async()=>{const r=await api('calendars');$('agendaChoices').replaceChildren();$('agendaSettingsError').textContent='';(r.items||[]).forEach(c=>{const label=node('label'),input=node('input');input.type='checkbox';input.value=c.id;input.checked=c.selected;label.append(input,node('span',c.summary));$('agendaChoices').append(label);});if(!r.items.length)$('agendaChoices').append(node('p','Nenhuma agenda própria encontrada.'));$('agendaSettingsDialog').showModal();});
  settingsForm.onsubmit=protect(async()=>{await api('select_calendars',{ids:JSON.stringify([...$('agendaChoices').querySelectorAll('input:checked')].map(e=>e.value))});$('agendaSettingsDialog').close();await loadStatus();await openCard();},'agendaSettingsError');
  $('agendaDisconnect').onclick=protect(async()=>{if(!confirm('Desconectar a conta Google para todos os administradores do Business? Os eventos serão mantidos no Google.'))return;const r=await api('disconnect');$('agendaSettingsDialog').close();await loadStatus();status(r.message);},'agendaSettingsError');
  $('agendaNew').onclick=()=>{card=null;fill(null);};
  // Validate before busy: disabled controls bypass native validity checks.
  eventForm.onsubmit=e=>{e.preventDefault();if(busy||!editable())return;$('agendaEventError').textContent='';if($('agendaGuestInput').value.trim()&&!addGuests())return;if(!validate())return;
    protect(async()=>{
      if(editing?.recurrence&&!confirm('Salvar as alterações na série inteira?'))return;
      const event={summary:field('summary').value,description:field('description').value,location:field('location').value,allDay:field('allDay').checked,start:field('start').value,end:field('end').value,attendees:guests.map(g=>g.email),repeat:field('repeat').value,count:Number(field('count').value)};
      if(remindersChanged||!editing)event.reminders=reminderPayload();
      await api('save',{calendar_id:$('agendaCalendar').value,event_id:editing?.id||'',etag:editing?.etag||'',card_id:!editing&&card?card.id:'',request_id:requestId,send_updates:field('send_updates').value,event:JSON.stringify(event)});
      baseline='';dialog.close();card=null;await loadEvents();
    },'agendaEventError')();
  };
  $('agendaDelete').onclick=e=>{e.preventDefault();if(busy||!editing||!editable()||!field('send_updates').reportValidity())return;protect(async()=>{if(!confirm(editing.recurrence?'Excluir toda a série de compromissos?':editing.recurringEventId?'Excluir somente esta ocorrência?':'Excluir este compromisso do Google?'))return;await api('delete',{calendar_id:$('agendaCalendar').value,event_id:editing.id,etag:editing.etag,send_updates:field('send_updates').value});baseline='';dialog.close();await loadEvents();},'agendaEventError')();};
  $('agendaEditSeries').onclick=protect(async()=>{if(!confirm('Abrir a série inteira? As alterações não salvas serão descartadas.'))return;await openEvent(editing.id,'series');},'agendaEventError');
  $('agendaAddGuests').onclick=()=>{if(!busy&&editable())addGuests();};
  $('agendaReminderMode').onchange=()=>{const custom=$('agendaReminderMode').value==='custom';$('agendaReminderCustom').hidden=!custom;if(custom&&!$('agendaReminderList').children.length)addReminder();remindersChanged=true;syncControls();changed();};
  $('agendaAddReminder').onclick=()=>{if(busy||!editable())return;addReminder();remindersChanged=true;changed();};
  $('agendaReminderList').addEventListener('input',()=>{remindersChanged=true;changed();});$('agendaReminderList').addEventListener('change',()=>{remindersChanged=true;changed();});
  $('agendaCopyMeeting').onclick=async()=>{try{await navigator.clipboard.writeText($('agendaMeetingLink').href);$('agendaCopyStatus').textContent='Link copiado.';}catch{$('agendaCopyStatus').textContent='Não foi possível copiar automaticamente. Copie o endereço exibido acima.';}};
  field('allDay').onchange=()=>{dateType();changed();};field('repeat').onchange=()=>{syncControls();changed();};field('location').oninput=()=>{mapLink();changed();};
  eventForm.addEventListener('input',changed);eventForm.addEventListener('change',changed);
  root.querySelectorAll('[data-close]').forEach(b=>b.onclick=()=>{if(b.closest('dialog')===dialog)closeEvent();else if(!busy)b.closest('dialog').close();});
  dialog.addEventListener('cancel',e=>{e.preventDefault();closeEvent();});
  window.addEventListener('beforeunload',e=>{if(dialog.open&&dirty()){e.preventDefault();e.returnValue='';}});
  $('agendaDate').value=M.local(new Date()).slice(0,10);
  for(const id of ['agendaCalendar','agendaView','agendaDate'])$(id).onchange=loadEvents;
  $('agendaSearch').oninput=()=>{if($('agendaDate').value)render();};$('agendaRefresh').onclick=loadEvents;
  $('agendaPrevious').onclick=()=>{$('agendaDate').value=M.move($('agendaDate').value,$('agendaView').value,-1);loadEvents();};
  $('agendaNext').onclick=()=>{$('agendaDate').value=M.move($('agendaDate').value,$('agendaView').value,1);loadEvents();};
  $('agendaToday').onclick=()=>{$('agendaDate').value=M.local(new Date()).slice(0,10);loadEvents();};
  loadStatus().then(openCard).catch(e=>status(e.message,true));
}());
