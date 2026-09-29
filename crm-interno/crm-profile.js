export function createProfilePanel({api,escape,date,onOpportunity}) {
  const panel=document.createElement('dialog');
  panel.className='crm-profile-panel';
  panel.setAttribute('aria-labelledby','crmProfileTitle');
  panel.innerHTML=`<div class="crm-profile-head"><div><small>FICHA DO USUÁRIO</small><h2 id="crmProfileTitle">Perfil</h2></div><button type="button" data-close aria-label="Fechar ficha">Fechar</button></div><div data-body role="status" aria-live="polite"></div><section class="crm-profile-opportunities"><div class="crm-profile-section-head"><h3>Oportunidades</h3><button type="button" data-new-opportunity>Nova oportunidade</button></div><div data-opportunities>Consultando…</div></section><section class="crm-profile-timeline"><div class="crm-profile-section-head"><h3>Linha do tempo</h3><small>Registros próprios e contatos deste CRM</small></div><div data-timeline>Carregando histórico…</div><button type="button" data-more hidden>Carregar mais</button></section>`;
  document.querySelector('#crmApp').append(panel);
  const $=selector=>panel.querySelector(selector);
  const channelNames={email:'E-mail',notification:'Notificação',card:'Card no perfil'};
  const reasonNames={marketing_opt_out:'Sem opt-in comercial',channel_opt_out:'Canal cancelado',email_unverified:'E-mail não confirmado ou inválido',email_suppressed:'E-mail bloqueado',account_inactive:'Conta inativa'};
  const sourceNames={agenda_propria:'Agenda própria',resultado_reconhecido:'Resultado reconhecido',acesso_proprio:'Acesso identificado',crm:'CRM'};
  let activeId=null;let nextCursor='';let request=0;let loading=false;let returnFocus=null;

  function close(){request++;if(panel.open)panel.close();}
  $('[data-close]').onclick=close;
  panel.addEventListener('cancel',()=>{request++;});
  panel.addEventListener('close',()=>{activeId=null;returnFocus?.focus();returnFocus=null;});
  $('[data-new-opportunity]').onclick=()=>{if(activeId)onOpportunity?.({userId:activeId,userName:$('#crmProfileTitle').textContent});};

  async function loadOpportunities(userId,current){
    try{
      const data=await api('opportunities.list',{user_id:userId,page:1});
      if(current!==request||activeId!==userId)return;
      $('[data-opportunities]').innerHTML=data.items.length?data.items.slice(0,5).map(item=>`<div class="crm-profile-opportunity"><strong>${escape({shoes:'Tênis',coaching:'Assessoria',race:'Prova',service:'Serviço',other:'Outro'}[item.interest]||item.interest)}</strong><span>${escape(item.next_action||'Sem próxima ação')} · ${escape(item.owner_name)}</span><button type="button" data-open-opportunity="${escape(item.id)}">Abrir</button></div>`).join(''):'<p class="crm-muted">Nenhuma oportunidade registrada.</p>';
      $('[data-opportunities]').querySelectorAll('[data-open-opportunity]').forEach(button=>button.onclick=()=>onOpportunity?.({opportunityId:button.dataset.openOpportunity}));
    }catch(error){if(current===request&&activeId===userId)$('[data-opportunities]').textContent='Oportunidades indisponíveis. Feche e tente novamente.';}
  }

  function renderProfile(data){
    const user=data.user;
    const location=[user.cidade,user.estado].filter(Boolean).join(' / ')||'Localidade não informada';
    const channels=Object.entries(channelNames).map(([key,label])=>{
      const decision=data.channels?.[key];
      return `<span>${escape(label)}: ${escape(decision?.allowed?'Preferência ativa':reasonNames[decision?.reason]||'Indisponível')}</span>`;
    }).join('');
    const registrations=data.registrations||data.agenda||[];
    const results=data.results||[];
    $('[data-body]').innerHTML=`<p class="crm-profile-identity">${escape(user.email)}<br>${escape(location)}</p><div class="crm-profile-flags"><span>${user.optin_usuario?'Opt-in comercial registrado':'Sem opt-in comercial'}</span><span>${user.is_email_verified?'E-mail confirmado':'E-mail não confirmado'}</span></div><div class="crm-profile-channels">${channels}</div><p class="crm-muted">Preferências na consulta. A autorização do contato é conferida novamente antes do envio.</p><section><h3>Acessos identificados</h3><p><strong>${Number(data.access_summary?.days_30||0).toLocaleString('pt-BR')}</strong> dias observados nos últimos 30 · último registro: ${escape(date(data.access_summary?.last_seen))}</p><small class="crm-muted">Cobertura parcial; ausência de registro não indica inatividade.</small></section><div class="crm-profile-two"><section><h3>Agenda e inscrições</h3>${registrations.length?registrations.map(item=>`<p><strong>${escape(item.nome_evento)}</strong><br>${escape(item.tipo_checkin)} · ${escape(date(item.data_final))}</p>`).join(''):'<p class="crm-muted">Sem registros disponíveis.</p>'}<small class="crm-muted">Distância pessoal não confirmada pela agenda.</small></section><section><h3>Resultados reconhecidos</h3>${results.length?results.map(item=>`<p><strong>${escape(item.nome_evento)}</strong><br>${escape(item.percurso)} km · ${escape(date(item.data_final))}</p>`).join(''):'<p class="crm-muted">Sem resultados disponíveis.</p>'}</section></div>`;
    $('#crmProfileTitle').textContent=user.name;
  }

  function renderEvents(items,append){
    const list=$('[data-timeline]');
    if(!append)list.innerHTML='';
    if(!items.length&&!append){list.innerHTML='<p class="crm-muted">Nenhum registro disponível.</p>';return;}
    list.insertAdjacentHTML('beforeend',items.map(item=>`<article class="crm-profile-event"><time>${escape(date(item.at))}</time><strong>${escape(item.label)}</strong><span>${escape(sourceNames[item.source]||item.source)} · ${escape(item.status)}</span></article>`).join(''));
  }

  async function loadTimeline(cursor='',append=false){
    if(loading)return;
    loading=true;const current=request;const id=activeId;$('[data-more]').disabled=true;
    try{
      const data=await api('users.timeline',{id,cursor,limit:25});
      if(current!==request||activeId!==id)return;
      renderEvents(data.items||[],append);
      nextCursor=data.next_cursor||'';
      $('[data-more]').hidden=!nextCursor;
    }catch(error){
      if(current===request&&activeId===id)$('[data-timeline]').insertAdjacentHTML('beforeend','<p class="crm-muted">Histórico indisponível. Tente novamente.</p>');
    }finally{loading=false;$('[data-more]').disabled=false;}
  }

  $('[data-more]').onclick=()=>{if(nextCursor)loadTimeline(nextCursor,true);};

  async function open(userId,origin){
    request++;const current=request;activeId=userId;nextCursor='';loading=false;
    if(!panel.open){returnFocus=origin||document.activeElement;panel.showModal();}
    $('#crmProfileTitle').textContent='Carregando perfil…';
    $('[data-body]').textContent='Consultando dados do usuário…';
    $('[data-timeline]').textContent='Carregando histórico…';
    $('[data-opportunities]').textContent='Consultando oportunidades…';
    $('[data-more]').hidden=true;
    $('[data-close]').focus();
    const [profile,timeline]=await Promise.allSettled([api('users.profile',{id:userId}),api('users.timeline',{id:userId,limit:25})]);
    if(current!==request||activeId!==userId)return;
    if(profile.status==='fulfilled')renderProfile(profile.value);
    else $('[data-body]').textContent='Ficha indisponível. Feche e tente novamente.';
    if(timeline.status==='fulfilled'){
      renderEvents(timeline.value.items||[],false);
      nextCursor=timeline.value.next_cursor||'';
      $('[data-more]').hidden=!nextCursor;
    }else $('[data-timeline]').textContent='Histórico indisponível. Feche e tente novamente.';
    loadOpportunities(userId,current);
  }

  return {open,close};
}
