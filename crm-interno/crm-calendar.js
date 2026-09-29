import {loadAdsTimeline,renderGantt} from './crm-gantt.js?v=3';

export function initPlanning({api,escape,date,notify}) {
  const $=selector=>document.querySelector(selector);
  const form=$('#calendarFilters');
  const labels={email:'E-mail',notification:'Notificação',card:'Card no perfil',draft:'Rascunho',reviewed:'Em revisão',scheduled:'Agendada',running:'Em envio',active:'Ativa',paused:'Pausada',completed:'Concluída',cancelled:'Cancelada',failed:'Falha'};
  const day=value=>new Intl.DateTimeFormat('sv-SE',{timeZone:'America/Sao_Paulo',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(value));
  const displayDay=value=>`${value.slice(8,10)}/${value.slice(5,7)}/${value.slice(0,4)}`;
  const monday=value=>{const d=new Date(`${value}T12:00:00Z`);d.setUTCDate(d.getUTCDate()-(d.getUTCDay()+6)%7);return d.toISOString().slice(0,10);};
  let page=1,total=0,request=0,selected=null,choices=[];
  form.elements.from.value=day(new Date());
  form.elements.to.value=day(new Date(Date.now()+14*86400000));
  function renderCalendar(items){
    if(!items.length){$('#calendarList').innerHTML='<p class="crm-empty">Nenhuma campanha nesta janela.</p>';return;}
    let week='';let stamp='';const html=[];
    for(const item of items){
      const start=day(item.starts_at);const currentWeek=monday(start);
      if(currentWeek!==week){week=currentWeek;html.push(`<h3>Semana de ${displayDay(currentWeek)}</h3>`);}
      if(start!==stamp){stamp=start;html.push(`<h4>${displayDay(start)}</h4>`);}
      html.push(`<article class="crm-calendar-row"><div><strong>${escape(item.name)}</strong><span class="crm-tag">${escape(labels[item.status]||item.status)}</span><p>${escape(labels[item.channel]||item.channel)} · ${escape(date(item.starts_at))} → ${escape(date(item.ends_at))}</p><small>Público ${Number(item.audience_id)} · versão ${Number(item.audience_version)}. ${item.status==='cancelled'?'Cancelada; não há previsão de envio.':item.status==='paused'?'Pausada; não há previsão de envio enquanto pausada.':''}</small></div>${['cancelled','failed','paused'].includes(item.status)?'<span class="crm-muted">Sem pressão ativa</span>':`<button type="button" data-pressure="${Number(item.id)}" data-revision="${Number(item.revision)}">Ver pressão</button>`}</article>`);
    }
    $('#calendarList').innerHTML=html.join('');
    $('#calendarList').querySelectorAll('[data-pressure]').forEach(button=>button.onclick=()=>pressure(Number(button.dataset.pressure),Number(button.dataset.revision)));
  }
  async function loadCalendar(){
    const current=++request;const values=Object.fromEntries(new FormData(form));
    if(!form.reportValidity())return;
    const days=(Date.parse(values.to+'T12:00:00Z')-Date.parse(values.from+'T12:00:00Z'))/86400000;
    if(days<0||days>93){notify('Escolha uma janela de até 93 dias.');return;}
    const activeFilters=Number(Boolean(values.channel))+Number(Boolean(values.status));
    $('#calendarFilterCount').hidden=!activeFilters;
    $('#calendarFilterCount').textContent=activeFilters?String(activeFilters):'';
    $('#calendarAgendaCount').textContent='Consultando…';
    $('#calendarList').textContent='Consultando campanhas…';
    $('#planningGantt').textContent='Consultando linha do tempo…';
    try{
      const result=await api('campaigns.calendar',{...values,page});if(current!==request)return;
      total=Number(result.total);renderCalendar(result.items);
      $('#calendarAgendaCount').textContent=`${total.toLocaleString('pt-BR')} ${total===1?'campanha CRM':'campanhas CRM'}`;
      $('#calendarPage').textContent=`Página ${page} de ${Math.max(1,Math.ceil(total/50))}`;$('#calendarPrev').disabled=page<=1;$('#calendarNext').disabled=page*50>=total;
      const pages=Array.from({length:Math.min(10,Math.ceil(total/50))},(_,index)=>index+1);
      const [crmResult,adsResult]=await Promise.allSettled([Promise.all(pages.map(number=>number===page?result:api('campaigns.calendar',{...values,page:number}))),loadAdsTimeline(values.from,values.to)]);
      if(current!==request)return;
      const warning=[crmResult.status==='rejected'?'Parte das campanhas CRM está indisponível.':'',adsResult.status==='rejected'?'Ads e banners indisponíveis nesta consulta.':''].filter(Boolean).join(' ');
      const crm=crmResult.status==='fulfilled'?crmResult.value.flatMap(part=>part.items):result.items;
      const external=adsResult.status==='fulfilled'?adsResult.value.items:[];
      renderGantt($('#planningGantt'),{from:values.from,to:values.to,crm,external,warning,truncated:total>500||adsResult.status==='fulfilled'&&adsResult.value.truncated},escape);
    }catch(error){if(current===request){$('#calendarAgendaCount').textContent='Indisponível';$('#calendarList').textContent='Calendário indisponível. Tente novamente.';$('#planningGantt').textContent='Linha do tempo indisponível. Tente novamente.';}notify(error.message);}
  }
  async function pressure(id,revision){const target=$('#planningPressure');target.hidden=false;target.textContent='Calculando pressão…';target.scrollIntoView({block:'nearest',behavior:'smooth'});try{const result=await api('campaigns.pressure',{id,revision});const overlaps=result.conflicts||[];const cards=result.card_competition||[];target.innerHTML=`<div class="crm-line"><h3>Pressão da campanha ${id}</h3><button type="button" data-close-pressure>Fechar</button></div><p class="crm-muted">Consulta em ${escape(date(result.as_of))}. ${result.estimated?'Estimativa com critérios atuais; a entrega decide sob trava transacional.':'Fotografias confirmadas quando disponíveis.'}</p>${cards.length?`<p>Cards no mesmo período: ${cards.map(item=>escape(item.name)+' ('+escape(labels[item.status]||item.status)+')').join(', ')}. O limite de sessões de card é independente.</p>`:''}${overlaps.length?`<ul>${overlaps.map(item=>`<li>${escape(item.name)} · ${item.reason==='paused_no_send'?'pausada, sem envio ativo':`${Number(item.users).toLocaleString('pt-BR')} pessoas potencialmente coincidentes`}</li>`).join('')}</ul>`:'<p>Sem campanha coincidente observada nesta consulta.</p>'}${result.truncated?'<p class="crm-muted">Há mais campanhas na janela; refine o período para ver todas.</p>':''}`;target.querySelector('[data-close-pressure]').onclick=()=>{target.hidden=true;};}catch(error){target.textContent='Pressão indisponível. Tente novamente.';notify(error.message);}}
  async function loadChoices(audience){selected=audience;$('#overlapResult').textContent='';$('#overlapChoices').textContent='Consultando públicos…';try{const all=[];for(let page=1;page<=20;page++){const result=await api('audiences.list',{page,include_counts:false});all.push(...result.items);if(result.items.length<25)break;}if(selected?.id!==audience.id)return;choices=all.filter(item=>item.id!==audience.id);$('#overlapChoices').innerHTML=choices.length?choices.map(item=>`<label><input type="checkbox" value="${Number(item.id)}"><span>${escape(item.name)}</span></label>`).join(''):'<p class="crm-muted">Não há outro público para comparar.</p>';}catch(error){if(selected?.id===audience.id)$('#overlapChoices').textContent='Lista de públicos indisponível.';}}
  async function compare(){if(!selected)return;const picked=[...$('#overlapChoices').querySelectorAll('input:checked')].map(input=>Number(input.value));if(!picked.length||picked.length>4){$('#overlapResult').textContent='Selecione de um a quatro outros públicos.';return;}$('#overlapResult').textContent='Comparando públicos…';try{const result=await api('audiences.overlap',{audience_ids:[selected.id,...picked]});const names=Object.fromEntries([selected,...choices].map(item=>[item.id,item.name]));$('#overlapResult').innerHTML=`<p><strong>${Number(result.total_unique).toLocaleString('pt-BR')} pessoas únicas</strong> entre os ${picked.length+1} públicos.</p><div class="crm-table-wrap"><table><thead><tr><th>Públicos</th><th>Interseção</th></tr></thead><tbody>${result.pairs.map(pair=>`<tr><td>${escape(names[pair.left_id]||pair.left_id)} × ${escape(names[pair.right_id]||pair.right_id)}</td><td>${Number(pair.intersection).toLocaleString('pt-BR')}</td></tr>`).join('')}</tbody></table></div><p class="crm-muted">Contagem no horário da consulta; não representa aptidão de envio.</p>`;}catch(error){$('#overlapResult').textContent='Comparação indisponível. Tente novamente.';notify(error.message);}}
  form.onsubmit=event=>{event.preventDefault();page=1;loadCalendar();};
  $('#calendarPrev').onclick=()=>{if(page>1){page--;loadCalendar();}};
  $('#calendarNext').onclick=()=>{if(page*50<total){page++;loadCalendar();}};
  $('#overlapCompare').onclick=compare;
  loadCalendar();
  return {loadCalendar,loadChoices,compare};
}
