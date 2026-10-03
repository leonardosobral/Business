(function(root){
  'use strict';
  function lowerKeys(value){
    if(Array.isArray(value))return value.map(lowerKeys);
    if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[k.toLowerCase(),lowerKeys(v)]));
    return value;
  }
  function eventId(value,required){
    if(!required&&!value)return 0;
    if(!/^[1-9]\d{0,8}$/.test(String(value||'')))throw new Error('Selecione um evento ou treino válido.');
    return Number(value);
  }
  function buildPolicy(data){
    const official=eventId(data.officialEvent,false);
    if(data.source==='open')return {audience:'open',operator:'all',criteria:[],official_event_id:official};
    if(data.source==='advanced'){
      const legacy=lowerKeys(typeof data.legacy==='string'?JSON.parse(data.legacy):data.legacy);
      if(!legacy||!Array.isArray(legacy.criteria)||!legacy.criteria.length)throw new Error('Defina os critérios da regra avançada.');
      return {...legacy,audience:'rules',official_event_id:official};
    }
    const reference=String(data.reference||'').trim();let criterion;
    if(data.source==='event'||data.source==='training')criterion={type:'event_registration',event_ids:[eventId(reference,true)],training_only:data.source==='training'};
    else{
      if(!/^[a-z0-9][a-z0-9._:-]{0,119}$/.test(reference))throw new Error('Selecione um desafio ou circuito válido.');
      if(data.source==='circuit_stages')criterion={type:'circuit_registration',aggregator_tag:reference};
      else if(data.source==='challenge'||data.source==='circuit')criterion={type:'challenge',code:reference,confirmed_only:true};
      else throw new Error('Selecione o público da comunidade.');
    }
    return {audience:'rules',operator:'all',criteria:[criterion],official_event_id:official};
  }
  function matchesCommunity(item,filters){
    return (!filters.mode||item.modo===filters.mode)&&(!filters.status||item.status===filters.status)&&String(item.nome||'').toLocaleLowerCase('pt-BR').includes(String(filters.term||'').toLocaleLowerCase('pt-BR'));
  }
  const api={buildPolicy,matchesCommunity,lowerKeys};
  if(typeof module!=='undefined'&&module.exports)module.exports=api;
  if(!root.document)return;
  const doc=root.document,$=id=>doc.getElementById(id),form=$('communityForm');
  if(!form)return;
  const boot=lowerKeys(JSON.parse($('communityBootstrap').textContent)),initial=boot.policy||{};
  const source=$('communitySource'),reference=$('referenceSelect'),official=$('officialSelect'),auto=$('automaticMembership');
  const kinds={challenge:'challenge',circuit:'circuit',training:'training',event:'event',circuit_stages:'aggregator'};
  const labels={open:'Qualquer usuário, sem pré-requisitos',challenge:'Inscritos em desafio',circuit:'Inscritos em circuito',training:'Inscritos em treino',event:'Inscritos em evento',circuit_stages:'Inscritos nas etapas do circuito',advanced:'Regras combinadas'};
  let initialReference='';
  $('legacyPolicy').value=JSON.stringify(initial,null,2);
  if(initial.audience==='open')source.value='open';
  else if(initial.criteria?.length===1){
    const c=initial.criteria[0];
    if(c.type==='challenge'&&c.confirmed_only===true){source.value=['circuitobrasilgigante','catarinensetrailrun','catarinensecorridaderua'].includes(c.code)?'circuit':'challenge';initialReference=c.code;}
    else if(c.type==='event_registration'&&c.event_ids?.length===1){source.value=c.training_only?'training':'event';initialReference=String(c.event_ids[0]);}
    else if(c.type==='circuit_registration'){source.value='circuit_stages';initialReference=c.aggregator_tag;}
    else source.value='advanced';
  }else source.value='advanced';
  $('officialEnabled').checked=Number(initial.official_event_id)>0;
  const requests=new Map();
  async function loadReferences(kind,select,help,term='',selected=''){
    requests.get(select)?.abort();
    const controller=new AbortController();requests.set(select,controller);
    const timer=setTimeout(()=>controller.abort(),25000);
    help.textContent='Buscando opções…';
    try{
      const query=new URLSearchParams({references:kind,term,selected});
      const response=await fetch('./?'+query,{credentials:'same-origin',cache:'no-store',signal:controller.signal});
      const data=lowerKeys(await response.json());
      if(!response.ok||!data.success)throw new Error(data.message||'Não foi possível carregar as opções.');
      if(requests.get(select)!==controller)return;
      const chosen=selected||select.value,previous=select.selectedOptions[0];
      const options=[new Option('Selecione uma opção','')];
      for(const item of data.items||[])options.push(new Option(item.label+(item.detail?' · '+item.detail:''),String(item.value)));
      if(chosen&&!options.some(o=>o.value===chosen)&&previous?.value===chosen)options.push(new Option(previous.textContent,chosen));
      select.replaceChildren(...options);select.value=chosen;
      help.textContent=data.items?.length?'Selecione a opção desejada. Refine a busca para encontrar outros vínculos.':'Nenhuma opção encontrada. Tente outro nome ou o ID.';
      updatePreview();
    }catch(e){if(e.name!=='AbortError')help.textContent=e.message;else if(requests.get(select)===controller)help.textContent='Busca interrompida. Tente novamente.';}
    finally{clearTimeout(timer);}
  }
  function updatePreview(){
    const isOpen=source.value==='open',isChannel=form.querySelector('[name=group_mode]:checked').value==='channel';
    auto.disabled=isOpen;if(isOpen)auto.checked=false;
    $('previewName').textContent=$('communityName').value.trim()||'Sua comunidade';
    $('previewType').textContent=isChannel?'Canal de publicação':'Grupo de conversa';
    $('previewIcon').className='fa-solid '+(isChannel?'fa-bullhorn':'fa-user-group');
    $('previewAudience').textContent=labels[source.value]+(reference.value&&!['open','advanced'].includes(source.value)?' · '+reference.selectedOptions[0].textContent:'');
    $('previewOfficial').textContent=$('officialEnabled').checked?(official.value?official.selectedOptions[0].textContent:'Selecione o evento'):'Sem vínculo';
    $('previewEntry').textContent=auto.checked?'Inclusão automática dos inscritos elegíveis':'Entrada voluntária / inclusão pelo admin';
    $('automaticHelp').textContent=isOpen?'Uma comunidade aberta não adiciona toda a plataforma. A entrada é voluntária ou por convite do admin.':auto.checked?'Na ativação e sincronização, todos os inscritos elegíveis serão adicionados. Novas inscrições também são verificadas no acesso ao chat.':'A sincronização só revalida os membros existentes; não adiciona todos os inscritos.';
  }
  function sourceChanged(selected=''){
    requests.get(reference)?.abort();reference.replaceChildren(new Option('Selecione uma opção',''));
    $('audienceReference').hidden=['open','advanced'].includes(source.value);
    $('advancedPolicy').hidden=source.value!=='advanced';
    reference.required=!['open','advanced'].includes(source.value);
    if(kinds[source.value])loadReferences(kinds[source.value],reference,$('referenceHelp'),'',selected);
    $('referenceKindLabel').textContent={challenge:'desafio',circuit:'circuito',training:'treino',event:'evento',circuit_stages:'circuito'}[source.value]||'vínculo';
    updatePreview();
  }
  source.addEventListener('change',()=>sourceChanged());
  function officialChanged(selected=''){
    $('officialReference').hidden=!$('officialEnabled').checked;official.required=$('officialEnabled').checked;
    if($('officialEnabled').checked)loadReferences('event',official,$('officialHelp'),'',selected);
    updatePreview();
  }
  $('officialEnabled').addEventListener('change',()=>officialChanged());
  function search(input,callback){let timer;input.addEventListener('input',()=>{clearTimeout(timer);timer=setTimeout(callback,350);});}
  search($('referenceSearch'),()=>loadReferences(kinds[source.value],reference,$('referenceHelp'),$('referenceSearch').value,reference.value));
  search($('officialSearch'),()=>loadReferences('event',official,$('officialHelp'),$('officialSearch').value,official.value));
  form.addEventListener('input',updatePreview);form.addEventListener('change',updatePreview);
  form.addEventListener('submit',event=>{
    try{
      $('communityFormError').hidden=true;
      $('policyJson').value=JSON.stringify(buildPolicy({source:source.value,reference:reference.value,officialEvent:$('officialEnabled').checked?official.value:0,legacy:$('legacyPolicy').value}));
      $('managerAction').value=event.submitter?.dataset.action||(boot.editing?'update':'create');
      if($('managerAction').value!=='preview'&&auto.checked&&!confirm('Confirmar a inclusão automática dos inscritos elegíveis na ativação e nas sincronizações?'))event.preventDefault();
    }catch(e){event.preventDefault();$('communityFormError').textContent=e.message;$('communityFormError').hidden=false;$('communityFormError').scrollIntoView({block:'center'});}
  });
  doc.querySelectorAll('form[data-confirm]').forEach(f=>f.addEventListener('submit',e=>{if(!confirm(f.dataset.confirm))e.preventDefault();}));
  function filter(){let count=0;doc.querySelectorAll('[data-community-row]').forEach(row=>{row.hidden=!matchesCommunity({nome:row.dataset.name,modo:row.dataset.mode,status:row.dataset.status},{term:$('communitySearch').value,mode:$('communityModeFilter').value,status:$('communityStatusFilter').value});if(!row.hidden)count++;});$('communityCount').textContent=count+' comunidades';$('communityEmpty').hidden=count>0;}
  ['communitySearch','communityModeFilter','communityStatusFilter'].forEach(id=>$(id).addEventListener('input',filter));
  sourceChanged(initialReference);officialChanged(String(initial.official_event_id||''));updatePreview();
})(typeof window!=='undefined'?window:globalThis);
