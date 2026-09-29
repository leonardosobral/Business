(function(){
  document.querySelectorAll('[data-error-tabs]').forEach(function(group){
    var owned=function(selector){return Array.from(group.querySelectorAll(selector)).filter(function(node){return node.closest('[data-error-tabs]')===group;});};
    var tabs=owned('[data-error-tab]'),panels=owned('[data-error-panel]');
    if(!tabs.length)return;
    function activate(key,focus,updateHash){
      var chosen=tabs.find(function(tab){return tab.dataset.errorTab===key;}) || tabs[0];
      key=chosen.dataset.errorTab;
      tabs.forEach(function(tab){var active=tab===chosen;tab.setAttribute('aria-selected',String(active));tab.tabIndex=active?0:-1;});
      panels.forEach(function(panel){panel.hidden=panel.dataset.errorPanel.split(' ').indexOf(key)===-1;});
      owned('[data-error-tab-value]').forEach(function(input){input.value=key;});
      if(focus)chosen.focus();
      if(updateHash && group.dataset.tabHash)window.history.replaceState(null,'','#'+key);
    }
    tabs.forEach(function(tab,index){
      tab.addEventListener('click',function(){activate(tab.dataset.errorTab,false,true);});
      tab.addEventListener('keydown',function(event){
        var next;
        if(event.key==='ArrowRight')next=(index+1)%tabs.length;
        else if(event.key==='ArrowLeft')next=(index+tabs.length-1)%tabs.length;
        else if(event.key==='Home')next=0;
        else if(event.key==='End')next=tabs.length-1;
        else return;
        event.preventDefault();activate(tabs[next].dataset.errorTab,true,true);
      });
    });
    var initial=group.dataset.tabDefault;
    if(group.dataset.tabHash){
      var fromHash=window.location.hash.slice(1);
      if(tabs.some(function(tab){return tab.dataset.errorTab===fromHash;}))initial=fromHash;
      window.addEventListener('hashchange',function(){activate(window.location.hash.slice(1),false,false);});
    }
    activate(initial,false,false);
  });
  document.querySelectorAll('[data-triage-export]').forEach(function(form){
    form.addEventListener('submit',function(event){
      var count=Array.from(form.querySelectorAll('[name="ids"]')).filter(function(input){return input.checked;}).length;
      var feedback=form.querySelector('[data-triage-feedback]');
      if(count<1 || count>20){event.preventDefault();feedback.textContent='Selecione entre 1 e 20 problemas para exportar.';}
      else feedback.textContent='';
    });
  });
  document.querySelectorAll('[data-triage-treatment]').forEach(function(form){
    var status=form.querySelector('[name="status"]');
    function updateRequired(){
      var value=status.value.toLowerCase();
      var required={evidence:value==='published'||value==='verified',published_at:value==='published',reason:value==='ignored'||value==='reopened'};
      Object.keys(required).forEach(function(name){
        var input=form.querySelector('[name="'+name+'"]');
        input.required=required[name];
        form.querySelector('[data-triage-required="'+name+'"]').hidden=!required[name];
      });
      var extra=value==='published'?' Também preencha a evidência e confira o horário efetivo da publicação.':value==='verified'?' Também preencha a evidência. A publicação deve ter sido registrada antes.':required.reason?' Também informe o motivo da alteração.':'';
      form.querySelector('[data-triage-required-summary]').textContent='Obrigatórios: título, status e categoria.'+extra+' Os demais campos são opcionais.';
    }
    status.addEventListener('change',updateRequired);updateRequired();
  });
  document.querySelectorAll('[data-triage-write]').forEach(function(form){
    var sending=false;
    form.addEventListener('submit',function(event){if(sending){event.preventDefault();return;}sending=true;});
    window.addEventListener('pageshow',function(){sending=false;});
  });
}());
