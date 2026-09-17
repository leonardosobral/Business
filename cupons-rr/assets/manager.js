(() => {
  'use strict';
  const dirtyForms=new Set();
  let submitting=false;
  document.querySelectorAll('[data-cp-form]').forEach(form=>{
    form.addEventListener('input',()=>{dirtyForms.add(form);});
    form.addEventListener('change',()=>{dirtyForms.add(form);});
    form.addEventListener('submit',event=>{
      if(submitting){event.preventDefault();return;}
      if(Array.from(dirtyForms).some(other=>other!==form) && !window.confirm('Há alterações não salvas em outro formulário desta página. Continuar e descartá-las?')){event.preventDefault();return;}
      submitting=true;form.setAttribute('aria-busy','true');
      const feedback=form.querySelector('[data-cp-feedback]');if(feedback) feedback.textContent='Salvando…';
    });
  });
  document.querySelectorAll('[data-cp-confirm]').forEach(form=>form.addEventListener('submit',event=>{
    if(submitting || !window.confirm(form.dataset.cpConfirm+(dirtyForms.size?' Há alterações não salvas que serão descartadas.':''))){event.preventDefault();return;}
    submitting=true;
  }));
  window.addEventListener('beforeunload',event=>{if(dirtyForms.size&&!submitting){event.preventDefault();event.returnValue='';}});
  window.addEventListener('pageshow',()=>{submitting=false;document.querySelectorAll('[aria-busy]').forEach(el=>el.removeAttribute('aria-busy'));});
  document.querySelectorAll('[data-cp-picker]').forEach(picker=>{
    const search=picker.querySelector('[data-cp-search]'),button=picker.querySelector('[data-cp-find]'),select=picker.querySelector('[data-cp-results]'),status=picker.querySelector('[data-cp-search-status]');
    let sequence=0;
    const find=async()=>{
      const request=++sequence;button.disabled=true;status.textContent='Buscando eventos…';
      try{
        const response=await fetch('/cupons-rr/?modo=eventos&busca_evento='+encodeURIComponent(search.value.trim()),{credentials:'same-origin',headers:{Accept:'application/json'}});
        if(!response.ok) throw new Error('search');
        const data=await response.json(),items=data.items||data.ITEMS;
        if(!Array.isArray(items)) throw new Error('search');
        if(request!==sequence)return;
        const previous=select.selectedOptions[0],value=select.value;
        select.replaceChildren(new Option('Selecione o evento',''));
        items.forEach(item=>select.add(new Option(String(item.label??item.LABEL),String(item.id??item.ID))));
        if(value){if(!Array.from(select.options).some(option=>option.value===value))select.add(new Option(previous.textContent,value));select.value=value;}
        status.textContent=items.length?items.length+' evento(s). Se necessário, refine o nome para localizar a edição correta.':'Nenhum evento autorizado encontrado. Tente outro nome.';
      }catch(error){status.textContent='Não foi possível buscar os eventos. Recarregue a sessão ou tente novamente.';}
      finally{if(request===sequence)button.disabled=false;}
    };
    button.addEventListener('click',find);
    search.addEventListener('keydown',event=>{if(event.key==='Enter'){event.preventDefault();find();}});
  });
  document.querySelectorAll('[data-cp-edit-link]').forEach(button=>button.addEventListener('click',()=>{
    const form=document.querySelector('[data-cp-link-form]');if(!form)return;
    if(dirtyForms.has(form) && !window.confirm('Substituir as alterações não salvas neste vínculo?'))return;
    form.closest('details').open=true;
    const select=form.querySelector('[name=id_evento]'),value=button.dataset.event;
    if(!Array.from(select.options).some(option=>option.value===value))select.add(new Option(button.dataset.label,value));
    select.value=value;form.querySelector('[name=inicio]').value=button.dataset.start;form.querySelector('[name=fim]').value=button.dataset.end;form.querySelector('[name=quantidade]').value=button.dataset.quantity;
    form.scrollIntoView({block:'center',behavior:'auto'});form.querySelector('[name=inicio]').focus();
  }));
})();
