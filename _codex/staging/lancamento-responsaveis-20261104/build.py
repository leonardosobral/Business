from pathlib import Path
W=Path(__file__).resolve().parent

def read(n):return(W/'baseline'/n).read_text()
def out(n,text):
 p=W/'runtime'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
s=read('estudos/includes/StudyAccess.cfc')
needle='''        var completed=0;
        for(var step in steps) {'''
replacement='''        var details=db("SELECT DISTINCT ON (a.detalhes->>'step') a.id,a.detalhes->>'step' AS step,
            coalesce(a.detalhes->>'responsible','') AS responsible,coalesce(a.detalhes->>'notes','') AS notes,
            coalesce(u.name,'Administrador') AS author,
            to_char(a.criado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') AS changed_at
            FROM estudo.auditoria_comercial a JOIN public.tb_usuarios u ON u.id=a.ator_id
            WHERE a.entidade='launch_checklist' AND a.acao='LAUNCH_STEP_DETAILS'
              AND a.entidade_id=(SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3')
              AND a.detalhes->>'release'='2026-q3-20261113'
            ORDER BY a.detalhes->>'step',a.id DESC");
        var knownDetails={};
        for(var j=1;j<=details.recordCount;j++) knownDetails[details.step[j]]={"details_version":toString(details.id[j]),"responsible":details.responsible[j],"notes":details.notes[j],"details_author":details.author[j],"details_changed_at":details.changed_at[j]};
        var completed=0;
        for(var step in steps) {'''
assert s.count(needle)==1;s=s.replace(needle,replacement)
needle='''            structAppend(step,state,true);
            if(step.completed) completed++;'''
replacement='''            structAppend(step,state,true);
            var detailsState=structKeyExists(knownDetails,step.key)?knownDetails[step.key]:{"details_version":"0","responsible":"","notes":"","details_author":"","details_changed_at":""};
            structAppend(step,detailsState,true);
            if(step.completed) completed++;'''
assert s.count(needle)==1;s=s.replace(needle,replacement)
method='''    public struct function adminUpdateLaunchStepDetails(required any actorId,required string stepKey,required string responsible,required string notes,required string expectedVersion) {
        actor(actorId,true);
        limitText(responsible,120);limitText(notes,2000);
        var allowed=false;
        for(var definition in launchStepDefinitions()) if(compare(definition.key,stepKey)==0) allowed=true;
        if(!allowed || !reFind("^(0|[1-9][0-9]{0,17})$",expectedVersion)) throw(type="StudyAccess.Validation",message="Etapa ou versão inválida.");
        var owner=trim(responsible);var observations=trim(notes);
        transaction {
            actor(actorId,true);
            db("SELECT pg_advisory_xact_lock(20261113,hashtext(:step))",{step=p(stepKey)});
            var current=launchChecklistState();var prior={};
            for(var step in current.steps) if(compare(step.key,stepKey)==0) prior=step;
            if(compare(prior.details_version,expectedVersion)!=0) throw(type="StudyAccess.Conflict",message="Outro administrador alterou as informações desta etapa. Seu rascunho foi preservado; confira a versão salva abaixo.");
            if(compare(prior.responsible,owner)!=0 || compare(prior.notes,observations)!=0) {
                var product=one(db("SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3'"));
                audit(actorId,"LAUNCH_STEP_DETAILS","launch_checklist",product.id,
                    {"release":"2026-q3-20261113","step":stepKey,"responsible":owner,"notes":observations,"previous_version":prior.details_version});
            }
            var result=launchChecklistState();
        }
        return result;
    }

'''
needle='    public struct function adminOverview('
assert s.count(needle)==1;s=s.replace(needle,method+needle)
out('estudos/includes/StudyAccess.cfc',s)

s=read('estudos/lancamento/index.cfm').replace('20261104-checklist','20261104-responsaveis')
s=s.replace('As marcações são compartilhadas entre administradores e ficam salvas com autor e data. Valide uma etapa após conferir sua conclusão; desmarque para reabrir.','Defina quem cuida de cada etapa e registre pendências nas observações. Clique em “Salvar informações” para compartilhar com a equipe. A validação continua independente: marque após conferir a conclusão; desmarque para reabrir.')
needle='''<label class="step-validation"><input type="checkbox"'''
fields='''<form class="step-details" data-step-details="#encodeForHTMLAttribute(launchStep.key)#" data-version="#encodeForHTMLAttribute(launchStep.details_version)#">
<label for="responsavel-#encodeForHTMLAttribute(launchStep.key)#">Responsável</label><input id="responsavel-#encodeForHTMLAttribute(launchStep.key)#" name="responsible" type="text" value="#encodeForHTMLAttribute(launchStep.responsible)#" maxlength="120" placeholder="Nome ou equipe" autocomplete="off" disabled>
<label for="observacoes-#encodeForHTMLAttribute(launchStep.key)#">Observações · o que falta</label><textarea id="observacoes-#encodeForHTMLAttribute(launchStep.key)#" name="notes" rows="4" maxlength="2000" placeholder="Pendências, bloqueios e próximos passos" disabled>#encodeForHTML(launchStep.notes)#</textarea>
<button type="submit" data-save-details disabled>Salvar informações</button>
<p class="details-history" data-details-history><cfif len(launchStep.details_author)>Atualizado por #encodeForHTML(launchStep.details_author)# · #encodeForHTML(launchStep.details_changed_at)#<cfelse>Informações ainda não preenchidas.</cfif></p>
<p class="details-feedback" data-details-feedback role="status" aria-live="polite"></p>
<aside class="details-conflict" data-details-conflict hidden><b>Versão salva pela equipe</b><p data-saved-author></p><span>Responsável</span><p data-saved-responsible></p><span>Observações</span><p data-saved-notes></p><div><button type="button" data-use-saved>Usar versão salva</button><button type="button" data-reapply-draft>Salvar meu rascunho</button></div></aside>
</form>
'''
assert s.count(needle)==1;s=s.replace(needle,fields+needle)
out('estudos/lancamento/index.cfm',s)

s=read('estudos/lancamento/checklist.cfm')
a=s.index("    for(field in ['step','completed','expectedVersion'])");b=s.index("    writeOutput(serializeJSON({'ok':true",a)
s=s[:a]+'''    param name='FORM.operation' default='validate';
    if(!isSimpleValue(FORM.operation) || !listFind('validate,details',FORM.operation)) throw(type='StudyAccess.Validation',message='Operação inválida.');
    requiredFields=FORM.operation=='details'?['step','responsible','notes','expectedVersion']:['step','completed','expectedVersion'];
    for(field in requiredFields) if(!structKeyExists(FORM,field) || !isSimpleValue(FORM[field])) throw(type='StudyAccess.Validation',message='Informe os dados da etapa.');
    if(FORM.operation=='details') result=studyService.adminUpdateLaunchStepDetails(studyActor,toString(FORM.step),toString(FORM.responsible),toString(FORM.notes),toString(FORM.expectedVersion));
    else {
        if(!listFind('true,false',FORM.completed)) throw(type='StudyAccess.Validation',message='Estado inválido.');
        result=studyService.adminValidateLaunchStep(studyActor,toString(FORM.step),FORM.completed=='true',toString(FORM.expectedVersion));
    }
'''+s[b:]
out('estudos/lancamento/checklist.cfm',s)

js='''(function () {
  'use strict';
  var inputs = Array.from(document.querySelectorAll('[data-launch-step]'));
  var forms = Array.from(document.querySelectorAll('[data-step-details]'));
  var feedback = document.getElementById('launch-feedback');
  var conflicts = new WeakMap();
  var busy = false;
  if (!inputs.length || !feedback) return;

  function fillDetails(form, step) {
    form.elements.responsible.value = step.responsible;
    form.elements.notes.value = step.notes;
    form.dataset.version = String(step.details_version);
    form.dataset.dirty = 'false';
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
        : 'Aguardando validação da equipe.';
      var form = card.querySelector('[data-step-details]');
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
    form.addEventListener('input', function () {
      form.dataset.dirty = 'true';
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
})();
'''
out('estudos/lancamento/checklist.js',js)
css='''
/* Owner and pending work are saved independently from step validation. */
.step-details{margin-top:20px;padding-top:18px;border-top:1px solid #0002}.step-details>label{display:block;font-size:14px;font-weight:600;line-height:1.5;margin-bottom:7px}.step-details>label:not(:first-child){margin-top:16px}.step-details>input,.step-details>textarea{display:block;width:100%;max-width:100%;min-width:0;padding:10px 11px;border:1px solid #c9c7c1;border-radius:7px;background:white;color:var(--ink);font:15px/1.6 Poppins,sans-serif}.step-details>textarea{resize:vertical;min-height:122px}.step-details>input:focus-visible,.step-details>textarea:focus-visible,.step-details button:focus-visible{outline:3px solid #7058b5;outline-offset:2px}.step-details>button,.details-conflict button{padding:10px 12px;border:1px solid #54504a;border-radius:7px;background:var(--ink);color:white;font:600 13px/1.5 Poppins,sans-serif;cursor:pointer;white-space:normal}.step-details>button{margin:13px 0 10px;width:100%}.step-details button:disabled{opacity:.6;cursor:wait}.launch-checklist .details-history{font-size:12px;line-height:1.6;color:#525252;margin:0;overflow-wrap:anywhere}.launch-checklist .details-feedback{font-size:12px;line-height:1.6;color:#315c4b;min-height:20px;margin:7px 0 15px}.launch-checklist .details-feedback.is-error{color:#9d342d}.details-conflict{border:1px solid #a68068;border-radius:8px;padding:12px;margin:12px 0;background:#fff8f1;font-size:12px;line-height:1.6;overflow-wrap:anywhere}.details-conflict span{font-weight:600}.launch-checklist .details-conflict p{font-size:12px;white-space:pre-wrap;margin:6px 0 12px}.details-conflict>div{display:flex;flex-wrap:wrap;gap:8px}.details-conflict button{font-size:12px;padding:8px}.details-conflict button:first-child{background:white;color:var(--ink)}.launch-checklist .step-validation{margin-top:2px}.launch-checklist .launch .step-details>button{background:#242424}.launch-checklist .launch .details-history{color:#40380f}
'''
out('estudos/lancamento/lancamento.css',read('estudos/lancamento/lancamento.css')+css+'\n@media(max-width:650px){.step-details>input,.step-details>textarea{font-size:16px}}\n')
print('Built owner/notes fields, independent audit revisions, explicit save, preserved drafts on conflict.')
