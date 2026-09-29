const lower=data=>Array.isArray(data)?data.map(lower):data&&typeof data==='object'?Object.fromEntries(Object.entries(data).map(([key,value])=>[key.toLowerCase(),lower(value)])):data;
const ordinal=value=>Date.parse(`${value}T12:00:00Z`)/86400000;
const localDay=value=>new Intl.DateTimeFormat('sv-SE',{timeZone:'America/Sao_Paulo',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(value));
const shortDay=value=>`${value.slice(8,10)}/${value.slice(5,7)}`;

export async function loadAdsTimeline(from,to){
 const response=await fetch('/crm-interno/timeline.cfm',{method:'POST',credentials:'same-origin',body:new URLSearchParams({csrf:document.querySelector('#crmApp').dataset.csrf,from,to})});
 const result=lower(await response.json());
 if(!response.ok||!result.success)throw new Error('Ads e banners indisponíveis nesta consulta.');
 return result.data;
}

export function renderGantt(container,{from,to,crm=[],external=[],warning='',truncated=false},escape){
 const days=ordinal(to)-ordinal(from)+1;
 const statusLabels={draft:'Rascunho',reviewed:'Em revisão',scheduled:'Agendada',running:'Em envio',active:'Ativa',paused:'Pausada',completed:'Concluída',cancelled:'Cancelada',failed:'Falha',ended:'Finalizada'};
 const sourceLabels={program:'Contínua',crm:'CRM',ads:'Ads',banner:'Banner'};
 const program={id:'todosantodia',name:'Todo Santo Dia',kind:'program',status:'active',starts_day:from,ends_day:to,ongoing:true};
 const own=crm.map(item=>({id:item.id,name:item.name,kind:'crm',status:item.status,starts_day:localDay(item.starts_at),ends_day:localDay(item.ends_at),channel:item.channel}));
 const grouped=[['Acompanhamento contínuo',[program]],['Campanhas CRM',own],['Ads',external.filter(item=>item.kind==='ads')],['Banners',external.filter(item=>item.kind==='banner')]];
 const ticks=[];const step=days<=21?3:7;
 for(let offset=0;offset<days;offset+=step){const value=new Date((ordinal(from)+offset)*86400000).toISOString().slice(0,10);ticks.push(`<span class="crm-gantt-tick" style="left:${(offset/days*100).toFixed(3)}%">${shortDay(value)}</span>`);}
 const row=item=>{
  const start=Math.max(ordinal(from),ordinal(item.starts_day));
  const end=Math.min(ordinal(to),ordinal(item.ends_day));
  if(end<start)return '';
  const left=((start-ordinal(from))/days*100).toFixed(3);
  const width=((end-start+1)/days*100).toFixed(3);
  const inactive=['draft','paused','cancelled','failed','ended','completed'].includes(String(item.status).toLowerCase());
  const period=item.ongoing?'Acompanhamento contínuo; início comercial não verificado':`${shortDay(item.starts_day)} a ${shortDay(item.ends_day)}`;
  const label=`${item.name} · ${sourceLabels[item.kind]} · ${statusLabels[String(item.status).toLowerCase()]||item.status} · ${period}`;
  return `<div class="crm-gantt-row"><div class="crm-gantt-label" title="${escape(label)}"><strong>${escape(item.name)}</strong></div><div class="crm-gantt-track"><span class="crm-gantt-bar crm-gantt-${item.kind}${inactive?' is-inactive':''}" style="left:${left}%;width:${width}%" role="img" aria-label="${escape(label)}" title="${escape(label)}"></span></div></div>`;
 };
 container.innerHTML=`<div class="crm-line"><div><h3>Gantt das campanhas</h3><p class="crm-muted">${shortDay(from)} a ${shortDay(to)} · Brasília</p></div><span class="crm-muted">${grouped.reduce((sum,[,items])=>sum+items.length,0).toLocaleString('pt-BR')} linhas</span></div>${warning?`<p class="crm-gantt-warning">${escape(warning)}</p>`:''}${truncated?'<p class="crm-gantt-warning">Há mais campanhas do que o limite exibido. Reduza o período para ver todas.</p>':''}<div class="crm-gantt-scroll" tabindex="0" aria-label="Deslocar linha do tempo"><div class="crm-gantt-board"><div class="crm-gantt-ruler"><div class="crm-gantt-label">Campanha / origem</div><div class="crm-gantt-axis">${ticks.join('')}</div></div>${grouped.map(([title,items])=>`<div class="crm-gantt-group">${escape(title)} · ${items.length}</div>${items.length?items.map(row).join(''):'<div class="crm-gantt-empty">Nenhuma nesta janela.</div>'}`).join('')}</div></div><p class="crm-muted crm-gantt-note">Todo Santo Dia: acompanhamento contínuo, sem data de início comercial verificada.</p>`;
}
