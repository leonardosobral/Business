export function initOpportunities({api,escape,date,openProfile,notify}) {
  const $=selector=>document.querySelector(selector);
  const dialog=$('#opportunityDialog');
  const body=$('#opportunityDialogBody');
  const interests={shoes:'Tênis',coaching:'Assessoria',race:'Prova',service:'Serviço',other:'Outro'};
  const stages={new:'Nova',contacting:'Em contato',interested:'Interessado',converted:'Convertida manualmente',closed:'Encerrada'};
  let owners=[];let page=1;let total=0;let current=null;let userContext=null;let request=0;let busy=false;
  const fmt=value=>value?date(value):'Sem prazo';
  const dateInput=value=>{if(!value)return '';const parsed=new Date(value);if(Number.isNaN(parsed.valueOf()))return '';return new Intl.DateTimeFormat('sv-SE',{timeZone:'America/Sao_Paulo',year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',hour12:false}).format(parsed).replace(' ','T');};
  function errorMessage(error){notify(error.message||'Não foi possível concluir a operação.');}
  async function loadOwners(){owners=(await api('opportunities.owners')).items;$('#opportunityOwner').innerHTML='<option value="">Todos</option>'+owners.map(o=>`<option value="${Number(o.id)}">${escape(o.name)}</option>`).join('');}
  async function load(){
    const ticket=++request;
    $('#opportunityList').textContent='Consultando oportunidades…';
    $('#opportunitySummary').textContent='Consultando indicadores…';
    const listResult=api('opportunities.list',{page,owner_id:$('#opportunityOwner').value,stage:$('#opportunityStage').value,due:$('#opportunityDue').value});
    const manualResult=api('opportunities.list',{page:1,stage:'converted'}).then(
      result=>Number.isFinite(Number(result.total))?`${Number(result.total)} convertidas manualmente (todas)`:'Contagem manual indisponível',
      ()=>'Contagem manual indisponível'
    );
    try{
      const result=await listResult;
      if(ticket!==request)return;
      total=Number(result.total);
      const summaryBase=`${total} oportunidades no filtro · `;
      const summarySuffix=' · registro interno; não comprova compras ou receita.';
      $('#opportunitySummary').textContent=summaryBase+'Contagem manual em andamento'+summarySuffix;
      manualResult.then(manualCount=>{if(ticket===request)$('#opportunitySummary').textContent=summaryBase+manualCount+summarySuffix;});
      $('#opportunityList').innerHTML=result.items.length?result.items.map(o=>`<article class="crm-opportunity-row"><div><strong>${escape(o.user_name)}</strong> · ${escape(interests[o.interest]||o.interest)} <span class="crm-tag">${escape(stages[o.stage]||o.stage)}</span><p>${escape(o.next_action||'Sem próxima ação')} · ${escape(fmt(o.due_at))}</p><small>Responsável: ${escape(o.owner_name)} · revisão ${Number(o.revision)}</small></div><div class="crm-opportunity-buttons"><button type="button" data-op-profile="${Number(o.user_id)}">Ver perfil</button><button type="button" data-op-edit="${escape(o.id)}">Abrir</button></div></article>`).join(''):'<p class="crm-empty">Nenhuma oportunidade corresponde aos filtros.</p>';
      $('#opportunityPage').textContent=`Página ${page} de ${Math.max(1,Math.ceil(total/25))}`;
      $('#opportunityPrev').disabled=page<=1;
      $('#opportunityNext').disabled=page*25>=total;
      $('#opportunityList').querySelectorAll('[data-op-edit]').forEach(button=>button.onclick=()=>open(button.dataset.opEdit));
      $('#opportunityList').querySelectorAll('[data-op-profile]').forEach(button=>button.onclick=()=>openProfile(Number(button.dataset.opProfile),button));
    }catch(error){if(ticket===request){$('#opportunityList').textContent='Lista indisponível. Use Atualizar para tentar novamente.';$('#opportunitySummary').textContent='Indicadores indisponíveis.';}errorMessage(error);}
  }
  function form(data={}){
    const selectedUser=userContext?.id||data.user_id;
    const title=userContext?.name||data.user_name||`Usuário ${selectedUser}`;
    const chosenOwner=Number(data.owner_id||owners[0]?.id||0);
    $('#opportunityDialogTitle').textContent=data.id?'Editar oportunidade':'Nova oportunidade';
    body.innerHTML=`<p class="crm-muted">${escape(title)} · registro comercial interno. Salvar não cria contato.</p><div id="opportunityMessage" role="status" aria-live="polite" hidden></div><form id="opportunityForm"><div class="crm-form-grid"><label>Interesse<select name="interest" required>${Object.entries(interests).map(([key,label])=>`<option value="${key}" ${key===data.interest?'selected':''}>${escape(label)}</option>`).join('')}</select></label><label>Responsável<select name="owner_id" required>${owners.map(o=>`<option value="${Number(o.id)}" ${Number(o.id)===chosenOwner?'selected':''}>${escape(o.name)}</option>`).join('')}</select></label><label class="crm-wide">Próxima ação<input name="next_action" maxlength="500" value="${escape(data.next_action||'')}"></label><label>Prazo (Brasília)<input name="due_at" type="datetime-local" value="${escape(dateInput(data.due_at))}"></label>${data.id?'':'<label class="crm-wide">Observação inicial<textarea name="note" maxlength="2000" rows="3"></textarea></label>'}</div><div class="crm-actions"><button type="submit" class="crm-primary">Salvar oportunidade</button></div></form>${data.id?`<section class="crm-opportunity-history"><h3>Etapa e histórico</h3><div class="crm-line"><label>Etapa<select id="opportunityTransition">${Object.entries(stages).map(([key,label])=>`<option value="${key}" ${key===data.stage?'selected':''}>${escape(label)}</option>`).join('')}</select></label><button type="button" id="opportunityMove">Atualizar etapa</button></div><form id="opportunityNote"><label>Nova observação<textarea name="note" maxlength="2000" rows="3" required></textarea></label><button type="submit">Registrar observação</button></form><div class="crm-opportunity-events">${(data.events||[]).map(event=>`<article><small>${escape(date(event.created_at))} · ${escape(event.actor_name)}</small><p>${escape(event.kind==='note'?event.body.note:event.kind==='transition'?`Etapa: ${stages[event.body.stage]||event.body.stage}`:'Dados comerciais atualizados')}</p></article>`).join('')}</div></section>`:''}`;
    $('#opportunityForm').onsubmit=event=>{event.preventDefault();save(selectedUser,data);};
    if(data.id){$('#opportunityMove').onclick=()=>move(data);$('#opportunityNote').onsubmit=event=>{event.preventDefault();note(data);};}
  }
  async function run(action){if(busy)return;busy=true;body.querySelectorAll('button').forEach(b=>b.disabled=true);$('#opportunityMessage').hidden=true;try{await action();await load();}catch(error){const box=$('#opportunityMessage');if(box){box.textContent=error.message||'Operação indisponível.';box.hidden=false;}else errorMessage(error);}finally{busy=false;body.querySelectorAll('button').forEach(b=>b.disabled=false);}}
  async function save(userId,data){
    const f=$('#opportunityForm');if(!f.reportValidity())return;
    const raw=Object.fromEntries(new FormData(f));
    const due=raw.due_at?`${raw.due_at}:00-03:00`:'';
    const requestId=crypto.randomUUID();
    await run(async()=>{const saved=await api('opportunities.save',{user_id:Number(userId),interest:raw.interest,owner_id:Number(raw.owner_id),next_action:raw.next_action,due_at:due,note:raw.note||'',request_id:requestId,...(data.id?{id:data.id,expected_revision:data.revision}:{})});current=await api('opportunities.get',{id:saved.id});userContext=null;form(current);notify('Oportunidade salva; nenhum contato foi enviado.');});
  }
  async function move(data){const stage=$('#opportunityTransition').value;const requestId=crypto.randomUUID();await run(async()=>{await api('opportunities.transition',{id:data.id,expected_revision:data.revision,stage,request_id:requestId});current=await api('opportunities.get',{id:data.id});form(current);notify('Etapa atualizada.');});}
  async function note(data){const noteText=$('#opportunityNote').elements.note.value;const requestId=crypto.randomUUID();await run(async()=>{await api('opportunities.note',{id:data.id,expected_revision:data.revision,note:noteText,request_id:requestId});current=await api('opportunities.get',{id:data.id});form(current);notify('Observação registrada.');});}
  async function open(id){try{if(!owners.length)await loadOwners();current=await api('opportunities.get',{id});userContext=null;form(current);if(!dialog.open)dialog.showModal();}catch(error){errorMessage(error);}}
  async function openForUser(userId,userName){try{if(!owners.length)await loadOwners();current=null;userContext={id:userId,name:userName};form({user_id:userId});if(!dialog.open)dialog.showModal();}catch(error){errorMessage(error);}}
  $('#closeOpportunityDialog').onclick=()=>dialog.close();
  $('#opportunityRefresh').onclick=load;
  for(const selector of ['#opportunityOwner','#opportunityStage','#opportunityDue'])$(selector).onchange=()=>{page=1;load();};
  $('#opportunityPrev').onclick=()=>{if(page>1){page--;load();}};
  $('#opportunityNext').onclick=()=>{if(page*25<total){page++;load();}};
  loadOwners().then(load).catch(errorMessage);
  return {load,open,openForUser};
}
