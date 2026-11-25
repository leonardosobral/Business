(function () {
  'use strict';
  var inputs = Array.from(document.querySelectorAll('[data-launch-step]'));
  var forms = Array.from(document.querySelectorAll('[data-step-details]'));
  var feedback = document.getElementById('launch-feedback');
  var conflicts = new WeakMap();
  var busy = false;
  if (!inputs.length || !feedback) return;

  function updateSummary(form, step) {
    var row = form.closest('.launch-step');
    row.querySelector('[data-responsible-summary]').textContent = step.responsible.trim() || 'A definir';
    var first = step.notes.split(/\r?\n/).find(function (line) { return line.trim(); }) || 'Observações ainda não preenchidas.';
    row.querySelector('[data-notes-preview]').textContent = first.length > 260 ? first.slice(0, 257) + '…' : first;
  }
  function resizeNotes(form) {
    if (!form.closest('.step-editor').open) return;
    var field = form.elements.notes;
    field.style.height = 'auto';
    field.style.height = Math.min(560, Math.max(230, field.scrollHeight + 2)) + 'px';
  }
  function fillDetails(form, step) {
    form.elements.responsible.value = step.responsible;
    form.elements.notes.value = step.notes;
    form.dataset.version = String(step.details_version);
    form.dataset.dirty = 'false';
    form.closest('.launch-step').querySelector('[data-draft-badge]').hidden = true;
    updateSummary(form, step);
    resizeNotes(form);
    form.querySelector('[data-details-history]').textContent = step.details_author
      ? 'Atualizado por ' + step.details_author + ' · ' + step.details_changed_at
      : 'Informações ainda não preenchidas.';
    form.querySelector('[data-details-conflict]').hidden = true;
    conflicts.delete(form);
  }
  function apply(data, savedForm) {
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
        : 'Aguardando validação.';
      var form = card.querySelector('[data-step-details]');
      if (form) updateSummary(form, step);
      if (form && (form === savedForm || form.dataset.dirty !== 'true')) fillDetails(form, step);
    });
    document.getElementById('launch-progress-label').textContent = data.completed + ' de ' + data.total + ' etapas validadas';
    document.getElementById('launch-progress').value = data.completed;
    var contract = data.steps.find(function (step) { return step.key === 'contrato-abraceo'; });
    document.getElementById('contract-status').textContent = contract.completed
      ? 'Contrato com a ABRACEO: etapa validada. Confira o alinhamento da comunicação antes da divulgação.'
      : 'Pendente: aprovação do contrato com a ABRACEO. Concluir antes da comunicação conjunta da parceria.';
  }
  function setBusy(value, activeForm) {
    busy = value;
    inputs.forEach(function (input) { input.disabled = value; });
    forms.forEach(function (form) {
      form.querySelectorAll('button').forEach(function (button) { button.disabled = value; });
    });
    if (activeForm) activeForm.querySelectorAll('input,textarea').forEach(function (field) { field.disabled = value; });
  }
  async function send(values) {
    values.csrf = document.getElementById('launch-csrf').value;
    var response = await fetch('checklist.cfm', {method: 'POST', credentials: 'same-origin', headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: new URLSearchParams(values).toString()});
    var result = await response.json();
    return {ok: response.ok && result.ok, data: result.data, message: result.message};
  }
  function showConflict(form, step) {
    conflicts.set(form, step);
    var box = form.querySelector('[data-details-conflict]');
    box.querySelector('[data-saved-author]').textContent = 'Atualizado por ' + step.details_author + ' · ' + step.details_changed_at;
    box.querySelector('[data-saved-responsible]').textContent = step.responsible || 'Não definido';
    box.querySelector('[data-saved-notes]').textContent = step.notes || 'Sem observações';
    box.hidden = false;
  }

  inputs.forEach(function (input) {
    input.disabled = false;
    input.addEventListener('change', async function () {
      var previous = !input.checked;
      var refreshed = false;
      setBusy(true);
      feedback.textContent = 'Salvando validação…';
      feedback.classList.remove('is-error');
      try {
        var result = await send({operation: 'validate', step: input.dataset.launchStep, completed: String(input.checked), expectedVersion: input.dataset.version});
        if (!result.ok) {
          if (result.data) { apply(result.data); refreshed = true; }
          throw new Error(result.message || 'Não foi possível salvar. Recarregue a página para conferir o estado atual.');
        }
        apply(result.data);
        feedback.textContent = input.checked ? 'Etapa validada e salva para a equipe.' : 'Etapa reaberta e salva para a equipe.';
      } catch (error) {
        if (!refreshed) input.checked = previous;
        feedback.textContent = error.message || 'Não foi possível salvar. Tente novamente.';
        feedback.classList.add('is-error');
      } finally { setBusy(false); }
    });
  });
  forms.forEach(function (form) {
    form.querySelectorAll('input,textarea,button').forEach(function (field) { field.disabled = false; });
    var status = form.querySelector('[data-details-feedback]');
    var editor = form.closest('.step-editor');
    var row = form.closest('.launch-step');
    var toggle = row.querySelector('[data-toggle-step]');
    function syncExpanded() {
      var label = editor.open ? 'Recolher' : 'Expandir';
      toggle.setAttribute('aria-expanded', String(editor.open));
      toggle.setAttribute('aria-label', label + ' etapa: ' + row.querySelector('h3').textContent);
      toggle.querySelector('[data-toggle-label]').textContent = label;
      resizeNotes(form);
    }
    toggle.disabled = false;
    toggle.addEventListener('click', function () { editor.open = !editor.open; syncExpanded(); });
    editor.addEventListener('toggle', syncExpanded);
    syncExpanded();
    form.addEventListener('input', function () {
      form.dataset.dirty = 'true';
      form.closest('.launch-step').querySelector('[data-draft-badge]').hidden = false;
      resizeNotes(form);
      status.textContent = 'Alterações não salvas.';
      status.classList.remove('is-error');
    });
    form.addEventListener('submit', async function (event) {
      event.preventDefault();
      if (busy) return;
      var values = {operation: 'details', step: form.dataset.stepDetails, responsible: form.elements.responsible.value, notes: form.elements.notes.value, expectedVersion: form.dataset.version};
      setBusy(true, form);
      status.textContent = 'Salvando informações…';
      status.classList.remove('is-error');
      try {
        var result = await send(values);
        if (!result.ok) {
          if (result.data) {
            apply(result.data);
            var latest = result.data.steps.find(function (step) { return step.key === form.dataset.stepDetails; });
            if (latest) showConflict(form, latest);
          }
          throw new Error(result.message || 'Não foi possível salvar. Seu rascunho foi mantido.');
        }
        apply(result.data, form);
        status.textContent = 'Informações salvas para a equipe.';
      } catch (error) {
        status.textContent = error.message || 'Não foi possível salvar. Seu rascunho foi mantido.';
        status.classList.add('is-error');
      } finally { setBusy(false, form); }
    });
    form.querySelector('[data-use-saved]').addEventListener('click', function () {
      var step = conflicts.get(form);
      if (!step) return;
      fillDetails(form, step);
      status.textContent = 'Versão salva carregada.';
      status.classList.remove('is-error');
    });
    form.querySelector('[data-reapply-draft]').addEventListener('click', function () {
      var step = conflicts.get(form);
      if (!step || busy) return;
      form.dataset.version = String(step.details_version);
      form.querySelector('[data-details-conflict]').hidden = true;
      form.requestSubmit();
    });
  });
  function openLinkedStep() {
    var row = document.getElementById(location.hash.slice(1));
    if (row && row.matches('.launch-step')) row.querySelector('.step-editor').open = true;
  }
  window.addEventListener('hashchange', openLinkedStep);
  openLinkedStep();
})();
