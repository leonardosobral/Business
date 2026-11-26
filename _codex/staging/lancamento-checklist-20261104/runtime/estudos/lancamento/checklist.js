(function () {
  'use strict';
  var inputs = Array.from(document.querySelectorAll('[data-launch-step]'));
  var feedback = document.getElementById('launch-feedback');
  if (!inputs.length || !feedback) return;
  function apply(data) {
    data.steps.forEach(function (step) {
      var input = inputs.find(function (candidate) { return candidate.dataset.launchStep === step.key; });
      if (!input) return;
      var card = input.closest('.launch-step');
      input.checked = step.completed;
      input.dataset.version = String(step.version);
      card.classList.toggle('is-complete', step.completed);
      card.querySelector('[data-step-label]').textContent = step.completed ? 'Etapa validada' : 'Validar etapa';
      card.querySelector('[data-step-history]').textContent = step.author
        ? (step.completed ? 'Validado' : 'Reaberto') + ' por ' + step.author + ' · ' + step.changed_at
        : 'Aguardando validação da equipe.';
    });
    document.getElementById('launch-progress-label').textContent = data.completed + ' de ' + data.total + ' etapas validadas';
    document.getElementById('launch-progress').value = data.completed;
    var contract = data.steps.find(function (step) { return step.key === 'contrato-abraceo'; });
    document.getElementById('contract-status').textContent = contract.completed
      ? 'Contrato com a ABRACEO: etapa validada. Confira o alinhamento da comunicação antes da divulgação.'
      : 'Pendente: aprovação do contrato com a ABRACEO. Concluir antes da comunicação conjunta da parceria.';
  }
  inputs.forEach(function (input) {
    input.disabled = false;
    input.addEventListener('change', async function () {
      var previous = !input.checked;
      var refreshed = false;
      inputs.forEach(function (item) { item.disabled = true; });
      feedback.textContent = 'Salvando validação…';
      feedback.classList.remove('is-error');
      try {
        var form = new URLSearchParams({csrf: document.getElementById('launch-csrf').value, step: input.dataset.launchStep, completed: String(input.checked), expectedVersion: input.dataset.version});
        var response = await fetch('checklist.cfm', {method: 'POST', credentials: 'same-origin', headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: form.toString()});
        var result = await response.json();
        if (!response.ok || !result.ok) {
          if (result.data) { apply(result.data); refreshed = true; } else input.checked = previous;
          throw new Error(result.message || 'Não foi possível salvar. Recarregue a página para conferir o estado atual.');
        }
        apply(result.data);
        feedback.textContent = input.checked ? 'Etapa validada e salva para a equipe.' : 'Etapa reaberta e salva para a equipe.';
      } catch (error) {
        if (!refreshed) input.checked = previous;
        feedback.textContent = error.message || 'Não foi possível salvar. Recarregue a página para conferir o estado atual.';
        feedback.classList.add('is-error');
      } finally {
        inputs.forEach(function (item) { item.disabled = false; });
      }
    });
  });
})();
