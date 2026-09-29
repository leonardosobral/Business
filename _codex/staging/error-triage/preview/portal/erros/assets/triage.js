(function(){
  document.querySelectorAll('[data-triage-export]').forEach(function(form){
    form.addEventListener('submit',function(event){
      var count=Array.from(form.querySelectorAll('[name="ids"]')).filter(function(input){return input.checked;}).length;
      var feedback=form.querySelector('[data-triage-feedback]');
      if(count<1 || count>20){event.preventDefault();feedback.textContent='Selecione entre 1 e 20 problemas para exportar.';}
      else feedback.textContent='';
    });
  });
  document.querySelectorAll('[data-triage-write]').forEach(function(form){
    var sending=false;
    form.addEventListener('submit',function(event){if(sending){event.preventDefault();return;}sending=true;});
    window.addEventListener('pageshow',function(){sending=false;});
  });
}());
