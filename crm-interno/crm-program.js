export function initProgram({api,escape,date,openProfile,notify}){
 const root=document.querySelector('#crmProgram');
 const $=selector=>root.querySelector(selector);
 const number=value=>Number(value||0).toLocaleString('pt-BR');
 const productName={todosantodia:'Básica',todosantodiavip:'VIP',todosantodiaupg:'Upgrade'};
 const state={source:'registrants',page:1,total:0,purchasePage:1,purchaseTotal:0,purchaseLoaded:false,lastRefresh:null};
 const localDay=value=>new Intl.DateTimeFormat('sv-SE',{timeZone:'America/Sao_Paulo',year:'numeric',month:'2-digit',day:'2-digit'}).format(value);
 const form=$('[data-program-filters]');
 if(!form.elements.from.value){form.elements.to.value=localDay(new Date());form.elements.from.value=localDay(new Date(Date.now()-89*86400000));}

 function segments(items){
  return items?.length?`<ul class="crm-program-segments">${items.slice(0,12).map(item=>`<li><span>${escape(item.label)}</span><strong>${number(item.people)}</strong></li>`).join('')}</ul>`:'<p class="crm-muted">Não informado</p>';
 }
 function render(data){
  $('[data-program-status]').textContent=data.status==='active_tracking'?'Ativa · acompanhamento':'Indisponível';
  $('[data-program-registrants]').textContent=number(data.totals.registrants);
  $('[data-program-registrants-asof]').textContent=`Retrato em ${date(data.coverage.registrants_as_of)}`;
  $('[data-program-signups]').textContent=number(data.totals.signup_starts);
  $('[data-program-signups-from]').textContent=data.coverage.signups_from?date(data.coverage.signups_from):'fonte indisponível';
  const finance=data.coverage.finance||{status:'unavailable'};
  const financeReady=finance.status==='partial'||finance.status==='available';
  const history=finance.historical||{};
  const historyText=history.windows?`${number(history.complete_windows)} de ${number(history.windows)} janelas históricas concluídas (${String(history.from_day).slice(0,10)} a ${String(history.through_day).slice(0,10)}); ${number(history.pending)} pedidos sem pagamento confirmado ou ambíguos`:'histórico anterior ainda não coberto nem auditado';
  $('[data-program-orders]').textContent=financeReady?number(data.totals.paid_orders):'—';
  $('[data-program-finance]').textContent=financeReady?'Pedidos confirmados por GET autenticado · cobertura parcial':'Compras ainda não conciliadas';
  $('[data-program-coverage]').textContent=`Base cadastrada: retrato atual, não histórico. Inícios: eventos novos desde ${data.coverage.signups_from?date(data.coverage.signups_from):'fonte indisponível'}. Lançamento do produto: ${data.coverage.launch_date_status==='unverified'?'não verificado':'documentado'}. Compras: ${financeReady?`vínculos novos desde ${date(finance.linked_from)}; ${historyText}`:'fonte indisponível'}.`;
  const financeDetails=$('[data-program-finance-details]');
  financeDetails.hidden=!financeReady;
  if(financeReady){
   const amounts=(data.finance?.amount_by_currency||[]).map(row=>`${escape(row.currency)} ${new Intl.NumberFormat('pt-BR',{style:'currency',currency:row.currency}).format(Number(row.net_amount_minor||0)/100)}`).join(' · ');
   financeDetails.innerHTML=`<div><small>Compradores identificados</small><strong>${number(data.totals.identified_buyers)}</strong></div><div><small>Anuidades vigentes</small><strong>${number(data.totals.active_terms)}</strong></div><div><small>Renovações</small><strong>${number(data.totals.renewals)}</strong></div><div><small>Upgrades</small><strong>${number(data.totals.upgrades)}</strong></div><div><small>Estornos totais</small><strong>${number(data.totals.refunded_orders)}</strong></div><div><small>Valor líquido verificado</small><strong class="crm-program-amount">${amounts||'—'}</strong></div><p class="crm-muted">Valor bruto de pedidos, após estornos totais confirmados; não é lucro nem valor de repasse. Números limitados à cobertura exibida acima.</p>`;
  }
  $('[data-program-series]').innerHTML=data.series?.length?`<div class="crm-table-wrap"><table><thead><tr><th>Período</th><th>Inícios</th></tr></thead><tbody>${data.series.map(item=>`<tr><td>${escape(String(item.period_start).slice(0,10))}</td><td>${number(item.signup_starts)}</td></tr>`).join('')}</tbody></table></div>`:'<p class="crm-muted">Nenhum início observado neste período. A coleta tem início próprio e não reconstrói cadastros antigos.</p>';
  const financialSeries=data.finance?.series||[];
  $('[data-program-financial-series]').innerHTML=financeReady?`<h4>Compras por período e produto</h4>${financialSeries.length?`<div class="crm-table-wrap"><table><thead><tr><th>Período</th><th>Produto</th><th>Pagos</th><th>Estornos</th></tr></thead><tbody>${financialSeries.map(item=>`<tr><td>${escape(String(item.period_start).slice(0,10))}</td><td>${escape(productName[item.product_code]||item.product_code)}</td><td>${number(item.paid_orders)}</td><td>${number(item.refunded_orders)}</td></tr>`).join('')}</tbody></table></div>`:'<p class="crm-muted">Nenhuma compra comprovada neste período. Confira a cobertura acima.</p>'}`:'';
  const profile=data.profile?.registrants||{};
  $('[data-program-profile]').innerHTML=`<div class="crm-program-profile-grid"><div><h4>Estado</h4>${segments(profile.states)}</div><div><h4>Cidade</h4>${segments(profile.cities)}</div><div><h4>Idade</h4>${segments(profile.ages)}</div></div><p class="crm-muted">Perfil atual das contas cadastradas; não descreve o perfil histórico no dia da inscrição.</p>`;
  const buyers=data.profile?.buyers||{};
  const buyerSegments=buyers.demographics||{};
  const buyersAllTime=(buyerSegments.states||[]).reduce((total,item)=>total+Number(item.people||0),0);
  $('[data-program-buyer-profile]').innerHTML=financeReady&&buyers.status==='available'?`<h4>Compradores identificados</h4>${buyersAllTime?`<div class="crm-program-profile-grid"><div><h4>Estado</h4>${segments(buyerSegments.states)}</div><div><h4>Cidade</h4>${segments(buyerSegments.cities)}</div><div><h4>Idade</h4>${segments(buyerSegments.ages)}</div><div><h4>Vigência atual</h4>${segments(buyers.tiers)}</div></div><p class="crm-muted">Perfil atual acumulado, somente de pedidos ligados ao checkout autenticado; o número acima considera o período selecionado.</p>`:'<p class="crm-muted">Nenhum comprador com vínculo seguro foi conciliado ainda.</p>'}`:'';
  const linked=data.linked_campaigns||[];
  $('[data-program-link-status]').textContent=linked.length?`Campanhas vinculadas para análise: ${linked.map(item=>item.name).join(', ')}.`:'Nenhuma campanha promocional vinculada.';
  document.querySelector('[data-program-entry-summary]').textContent=`${data.status==='active_tracking'?'Ativa':'Indisponível'} · base atual ${number(data.totals.registrants)} · inícios no período ${number(data.totals.signup_starts)} · ${financeReady?`compras comprovadas no período ${number(data.totals.paid_orders)}`:'compras ainda não conciliadas'}.`;
  state.lastRefresh=new Date();
 }
 async function loadReport(){
  if(!form.reportValidity())return;
  const input=Object.fromEntries(new FormData(form));
  try{render(await api('programs.report',input));if($('[data-program-purchases]').open)await loadPurchases(1);}
  catch(error){$('[data-program-status]').textContent=`Indisponível${state.lastRefresh?` · última consulta ${date(state.lastRefresh)}`:''}`;throw error;}
 }
 async function loadUsers(page=1){
  const source=$('[data-program-user-source]').value;
  const data=await api('programs.users',{source,page});
  state.source=source;state.page=page;state.total=Number(data.total||0);
  $('[data-program-user-rows]').innerHTML=data.items?.length?data.items.map(item=>`<tr><td>${escape(item.name)}<small>${escape(item.email)}</small></td><td>${escape([item.cidade,item.estado].filter(Boolean).join(' / ')||'Não informado')}</td><td><button type="button" class="crm-link" data-program-profile="${Number(item.id)}">Ver perfil</button></td></tr>`).join(''):'<tr><td colspan="3">Nenhuma pessoa encontrada nesta fonte.</td></tr>';
  $('[data-program-page]').textContent=`${state.total?`Página ${page} de ${Math.ceil(state.total/25)}`:'0 pessoas'}`;
  $('[data-program-prev]').disabled=page<=1;
  $('[data-program-next]').disabled=page*25>=state.total;
  root.querySelectorAll('[data-program-profile]').forEach(button=>button.onclick=()=>openProfile(Number(button.dataset.programProfile),button));
 }
 async function loadPurchases(page=1){
  const input=Object.fromEntries(new FormData(form));
  const data=await api('programs.purchases',{from:input.from,to:input.to,page});
  state.purchasePage=page;state.purchaseTotal=Number(data.total||0);state.purchaseLoaded=true;
  const statuses={confirmed:'Pago',refunded:'Estornado',pending:'Pendente'};
  $('[data-program-purchase-rows]').innerHTML=data.items?.length?data.items.map(item=>{
   const person=Number(item.user_id)>0?`<button type="button" class="crm-link" data-program-purchase-profile="${Number(item.user_id)}">${escape(item.user_name||`Usuário ${item.user_id}`)}</button>`:'Sem vínculo';
   const origin=Number(item.user_id)>0?(item.attribution_method==='last_recorded_click_7d'?'Clique registrado':item.attribution_method==='none'?'Orgânico':'Ainda não apurado'):'Sem vínculo';
   return `<tr><td>${escape(item.order_key)}</td><td>${escape(productName[item.product_code]||item.product_code||'Não informado')}</td><td>${escape(statuses[item.classification]||'Pendente')}</td><td>${item.paid_at?date(item.paid_at):'—'}</td><td>${person}</td><td>${item.classification==='confirmed'&&item.term_end?date(item.term_end):'—'}</td><td>${origin}</td></tr>`;
  }).join(''):'<tr><td colspan="7">Nenhum pedido desta fonte no período selecionado.</td></tr>';
  $('[data-program-purchase-page]').textContent=`${state.purchaseTotal?`Página ${page} de ${Math.ceil(state.purchaseTotal/25)}`:'0 pedidos'}`;
  $('[data-program-purchase-prev]').disabled=page<=1;
  $('[data-program-purchase-next]').disabled=page*25>=state.purchaseTotal;
  root.querySelectorAll('[data-program-purchase-profile]').forEach(button=>button.onclick=()=>openProfile(Number(button.dataset.programPurchaseProfile),button));
 }
 form.onsubmit=event=>{event.preventDefault();loadReport().catch(error=>notify(error.message));};
 $('[data-program-close]').onclick=()=>root.close();
 $('[data-program-users]').onclick=()=>loadUsers(1).catch(error=>notify(error.message));
 $('[data-program-user-source]').onchange=()=>loadUsers(1).catch(error=>notify(error.message));
 $('[data-program-prev]').onclick=()=>loadUsers(state.page-1).catch(error=>notify(error.message));
 $('[data-program-next]').onclick=()=>loadUsers(state.page+1).catch(error=>notify(error.message));
 $('[data-program-purchases]').ontoggle=event=>{if(event.target.open&&!state.purchaseLoaded)loadPurchases(1).catch(error=>notify(error.message));};
 $('[data-program-purchase-prev]').onclick=()=>loadPurchases(state.purchasePage-1).catch(error=>notify(error.message));
 $('[data-program-purchase-next]').onclick=()=>loadPurchases(state.purchasePage+1).catch(error=>notify(error.message));
 $('[data-program-link-open]').onclick=async()=>{
  try{
   const options=[];
   for(let page=1;page<=20;page++){const list=await api('campaigns.list',{page});options.push(...list.items);if(list.items.length<25)break;}
   const select=$('[data-program-link-select]');
   select.innerHTML=options.map(item=>`<option value="${Number(item.id)}" data-revision="${Number(item.revision)}">${escape(item.name)}</option>`).join('');
   $('[data-program-link-form]').hidden=!options.length;
   $('[data-program-link-status]').textContent=options.length?'Selecione a campanha e confirme o vínculo de análise.':'Nenhuma campanha existente para vincular.';
  }catch(error){notify(error.message);}
 };
 $('[data-program-link-form]').onsubmit=async event=>{
  event.preventDefault();
  const selected=$('[data-program-link-select]').selectedOptions[0];
  if(!selected)return;
  try{
   const result=await api('programs.link',{campaign_id:Number(selected.value),expected_revision:Number(selected.dataset.revision)});
   $('[data-program-link-status]').textContent=`Campanha ${result.campaign_id} vinculada ao Todo Santo Dia para análise. Nenhum envio foi ativado.`;
   $('[data-program-link-form]').hidden=true;
  }catch(error){notify(error.message);}
 };
 return {open:async()=>{if(!root.open)root.showModal();$('[data-program-message]').hidden=true;root.scrollTop=0;await loadReport();await loadUsers(1);}};
}
