(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  let selection = null, admin = false;
  const normalize = value => Array.isArray(value) ? value.map(normalize) : value && typeof value === 'object'
    ? Object.fromEntries(Object.entries(value).map(([k,v]) => [k.toLowerCase(), normalize(v)])) : value;
  function status(message, error=false) { $('status').textContent=message; $('status').classList.toggle('error',error); $('status').classList.toggle('visible',Boolean(message)); }
  async function api(operation, fields={}) {
    const response=await fetch('api.cfm',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({operation,csrf:$('csrf').value,...fields})});
    let result;try { result=normalize(await response.json()); } catch { throw new Error('A sessão não está disponível. Recarregue a página.'); }
    if(!response.ok || !result.ok) throw new Error(result.message || 'Não foi possível concluir.');
    return result.data;
  }
  async function submit(form, operation) {
    const button=form.querySelector('button[type="submit"],button:not([type])');
    button.disabled=true;form.setAttribute('aria-busy','true');status('Conferindo…');
    try { await operation(); } catch(error) { status(error.message,true); } finally { button.disabled=false;form.removeAttribute('aria-busy'); }
  }
  function showTab() {
    const management=location.hash==='#gestao' && admin;
    $('gestao').hidden=!management;$('acesso').hidden=management;
    document.querySelectorAll('.main-tabs a').forEach(a => a.setAttribute('aria-current',a.hash===(management?'#gestao':'#acesso')?'page':'false'));
    const representative=location.hash==='#representante' && Boolean(selection);
    $('company-details').hidden=representative;$('representative-panel').hidden=!representative;
    document.querySelectorAll('.company-tabs a').forEach(a => a.setAttribute('aria-current',a.hash===(representative?'#representante':'#empresa')?'page':'false'));
  }
  function showCompany(data) {
    const c=data.company;
    $('company-name').textContent=c.nome_empresa;$('company-document').textContent=`CNPJ ${c.cnpj}`;
    $('company-logo').hidden=!c.logo;
    if(c.logo){$('company-logo').src=c.logo;$('company-logo').alt=`Logotipo de ${c.nome_empresa}`;}
    $('company-data').replaceChildren();
    for(const [key,label] of Object.entries({razao_social:'Razão social',nome_fantasia:'Nome fantasia',email_publico:'E-mail da empresa',telefone_publico:'Telefone da empresa',site:'Site',endereco:'Endereço',bairro:'Bairro',cidade:'Cidade',uf:'UF',cep:'CEP'})) {
      if(!c[key])continue;
      const term=document.createElement('dt'),detail=document.createElement('dd');term.textContent=label;detail.textContent=c[key];$('company-data').append(term,detail);
    }
    $('representative-identity').textContent=`${data.representative.name} · ${data.representative.email}`;
    $('company-panel').hidden=false;$('lookup-panel').hidden=true;$('success-panel').hidden=true;
    $('confirm').reset();$('representative-company').textContent=c.nome_empresa;location.hash='#empresa';showTab();$('company-name').setAttribute('tabindex','-1');$('company-name').focus();
  }
  $('lookup').addEventListener('change',event => {
    if(event.target.name!=='mode')return;
    const voucher=event.target.value==='VOUCHER',input=$('lookup').elements.value;
    $('value-label').firstChild.textContent=voucher?'Código do voucher':'CNPJ da empresa';
    input.value='';input.placeholder=voucher?'BQ26-…':'00.000.000/0000-00';input.inputMode=voucher?'text':'numeric';input.focus();
  });
  $('lookup').addEventListener('submit',event => {
    event.preventDefault();const form=event.currentTarget;
    submit(form,async()=>{const fields={mode:form.elements.mode.value,value:form.elements.value.value.trim()};const data=await api('lookup',fields);selection=fields;showCompany(data);status('Pré-cadastro encontrado. Confira a empresa e confirme o representante.');});
  });
  $('change-company').addEventListener('click',()=>{selection=null;$('company-panel').hidden=true;$('lookup-panel').hidden=false;$('confirm').reset();$('lookup').elements.value.focus();status('');});
  $('confirm').addEventListener('submit',event=>{
    event.preventDefault();const form=event.currentTarget;if(!selection)return;
    submit(form,async()=>{const data=await api('confirm',{...selection,role:form.elements.role.value,corrections:form.elements.corrections.value,declared:form.elements.declared.checked?'true':'false'});$('company-panel').hidden=true;$('lookup-panel').hidden=true;$('success-panel').hidden=false;$('success-message').textContent=`Representante registrado para ${data.company}. A leitura está disponível na sua conta pessoal.`;selection=null;$('lookup').reset();status('Prévia liberada.');$('success-panel').querySelector('a').focus();});
  });
  $('issue').addEventListener('submit',event=>{
    event.preventDefault();const form=event.currentTarget;$('issued').hidden=true;$('issued-code').textContent='';
    submit(form,async()=>{const fields=Object.fromEntries(new FormData(form));const data=await api('issue',fields);$('issued-code').textContent=data.code_once;$('issued-recipient').textContent=`Destinatário: ${fields.email} · Resgate até ${fields.expiresOn}`;$('issued').hidden=false;status('Voucher gerado. Copie o código antes de sair desta página.');});
  });
  $('copy-voucher').addEventListener('click',async()=>{try{await navigator.clipboard.writeText($('issued-code').textContent);status('Voucher copiado.');}catch{status('Selecione o código e copie manualmente.',true);}});
  window.addEventListener('hashchange',()=>{showTab();if(selection && location.hash==='#representante')$('representative-title').focus();});
  api('overview').then(data=>{
    admin=Boolean(data.user.is_admin);$('identity').textContent=`${data.user.name} · ${data.user.email}`;$('admin-tab').hidden=!admin;
    for(const c of data.companies){const o=document.createElement('option');o.value=c.cnpj;o.textContent=`${c.name} · ${c.cnpj}`;$('company-options').append(o);}
    if(!data.representatives.length)$('representatives').textContent='Nenhum representante declarado por este fluxo ainda.';
    for(const r of data.representatives){const row=document.createElement('article');row.className='rep-row';for(const text of [`${r.company} · ${r.name}`,`${r.email} · ${r.role} · ${r.method} · ${r.status}`,r.corrections?`Correções informadas: ${r.corrections}`:'']){if(!text)continue;const p=document.createElement('p');p.textContent=text;row.append(p);}$('representatives').append(row);}
    showTab();
  }).catch(error=>status(error.message,true));
})();
