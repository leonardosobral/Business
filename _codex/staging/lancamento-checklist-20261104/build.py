from pathlib import Path
W=Path(__file__).resolve().parent;ROOT=W.parents[2]
def baseline(n):return(W/'baseline'/n).read_text()
def out(n,text):
 p=W/'runtime'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
methods='''
    // Launch validations share the existing immutable commercial audit, independently
    // of notebook queries, grants, voucher campaigns and legal contract acceptance.
    private array function launchStepDefinitions() {
        return [
            {"key":"organizar","date":"09 NOV · SEG","title":"Fechar e organizar","description":"Validar recorte e peças, nomear responsáveis e selecionar leitores e criadores."},
            {"key":"piloto","date":"10–11 NOV · TER–QUA","title":"Pilotar o acesso","description":"Testar login, voucher e leitura com 5–10 leitores. Conferir convites e posts."},
            {"key":"contrato-abraceo","date":"ATÉ 12 NOV · QUI","title":"Aprovar contrato com a ABRACEO","description":"Concluir a revisão e obter a aprovação das partes para o contrato e a comunicação da parceria."},
            {"key":"liberacao","date":"12 NOV · QUI","title":"Conferir e liberar","description":"Resolver bloqueios e conferir links, peças, destinatários, contrato e comunicação antes de divulgar."},
            {"key":"lancamento","date":"13 NOV · SEX","title":"Colocar na rua","description":"Publicar post principal e stories, disponibilizar o kit e realizar a primeira onda de convites autorizados."},
            {"key":"continuidade","date":"14–20 NOV","title":"Dar continuidade","description":"Acompanhar dúvidas, feedback, entrevistas, pautas e reviews que surgirem."},
            {"key":"venda-anual","date":"NOV–DEZ","title":"Preparar a venda","description":"Validar oferta, licença e relacionamento. Testar o checkout antes do recesso."},
            {"key":"edicao-anual","date":"06 / 11 JAN 2027 · PROPOSTA","title":"Antecipado / geral","description":"Confirmar datas e oferta da edição anual. Preço e desconto seguem em validação comercial."}
        ];
    }
    private struct function launchChecklistState() {
        var steps=launchStepDefinitions();
        var latest=db("SELECT DISTINCT ON (a.detalhes->>'step') a.id,a.detalhes->>'step' AS step,
            coalesce((a.detalhes->>'completed')::boolean,false) AS completed,coalesce(u.name,'Administrador') AS author,
            to_char(a.criado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') AS changed_at
            FROM estudo.auditoria_comercial a JOIN public.tb_usuarios u ON u.id=a.ator_id
            WHERE a.entidade='launch_checklist' AND a.acao='LAUNCH_STEP_VALIDATION'
              AND a.entidade_id=(SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3')
              AND a.detalhes->>'release'='2026-q3-20261113'
            ORDER BY a.detalhes->>'step',a.id DESC");
        var known={};
        for(var i=1;i<=latest.recordCount;i++) known[latest.step[i]]={"version":toString(latest.id[i]),"completed":latest.completed[i]?true:false,"author":latest.author[i],"changed_at":latest.changed_at[i]};
        var completed=0;
        for(var step in steps) {
            var state=structKeyExists(known,step.key)?known[step.key]:{"version":"0","completed":false,"author":"","changed_at":""};
            structAppend(step,state,true);
            if(step.completed) completed++;
        }
        return {"release":"2026-q3-20261113","steps":steps,"completed":completed,"total":arrayLen(steps)};
    }
    public struct function adminLaunchChecklist(required any actorId) {
        actor(actorId,true);
        return launchChecklistState();
    }
    public struct function adminValidateLaunchStep(required any actorId,required string stepKey,required boolean completed,required string expectedVersion) {
        actor(actorId,true);
        var allowed=false;
        for(var definition in launchStepDefinitions()) if(compare(definition.key,stepKey)==0) allowed=true;
        if(!allowed || !reFind("^(0|[1-9][0-9]{0,17})$",expectedVersion)) throw(type="StudyAccess.Validation",message="Etapa ou versão inválida.");
        transaction {
            actor(actorId,true);
            db("SELECT pg_advisory_xact_lock(20261113,hashtext(:step))",{step=p(stepKey)});
            var current=launchChecklistState();var prior={};
            for(var step in current.steps) if(compare(step.key,stepKey)==0) prior=step;
            if(compare(prior.version,expectedVersion)!=0) throw(type="StudyAccess.Conflict",message="Outro administrador atualizou esta etapa. Confira o estado atual antes de validar novamente.");
            if(prior.completed!=completed) {
                var product=one(db("SELECT id FROM estudo.produtos WHERE codigo='previa-2026-q3'"));
                audit(actorId,"LAUNCH_STEP_VALIDATION","launch_checklist",product.id,
                    {"release":"2026-q3-20261113","step":stepKey,"completed":completed,"previous_version":prior.version});
            }
            var result=launchChecklistState();
        }
        return result;
    }
'''
s=baseline('estudos/includes/StudyAccess.cfc');needle='    public struct function adminOverview('
assert s.count(needle)==1;s=s.replace(needle,methods+'\n'+needle);out('estudos/includes/StudyAccess.cfc',s)

s=baseline('estudos/lancamento/index.cfm')
s=s.replace('<cfinclude template="_admin.cfm"/>','<cfinclude template="_admin.cfm"/>\n<cfset launchChecklist=studyService.adminLaunchChecklist(studyActor)/>',1)
s=s.replace('lancamento.css?v=20261010-textos','lancamento.css?v=20261104-checklist')
a=s.index('<section class="intro">');b=s.index('<section id="no-ar">',a)
s=s[:a]+'''<section class="intro launch-intro"><div><p class="eyebrow">CENTRAL DA EQUIPE · 2026</p><h1>Lançamento da prévia Jan–Set.</h1><p><b>Sexta-feira, 13 de novembro de 2026.</b> Acompanhe e valide as etapas abaixo.</p></div><a class="button" href="arquivo.cfm?doc=resumo">Resumo de 1 página ↓</a></section>
<nav class="jump" aria-label="Nesta página"><a href="#cronograma">Cronograma e validação</a><a href="#no-ar">O que está no ar</a><a href="#textos">Textos para divulgação</a><a href="#pdfs">PDFs</a><a href="#decisoes">Próximos passos</a></nav>
'''+s[b:]
a=s.index('<section id="cronograma">');b=s.index('<section id="decisoes"',a);s=s[:a]+s[b:]
checklist='''<section id="cronograma" aria-labelledby="cronograma-title"><div class="section-title"><span>01</span><h2 id="cronograma-title">Cronograma e validação</h2></div>
<p class="note">As marcações são compartilhadas entre administradores e ficam salvas com autor e data. Valide uma etapa após conferir sua conclusão; desmarque para reabrir.</p>
<div class="launch-progress"><div><strong id="launch-progress-label"><cfoutput>#launchChecklist.completed# de #launchChecklist.total# etapas validadas</cfoutput></strong><span>Preparação: 9–12/11 · Divulgação: 13/11 · Acompanhamento: 14–20/11</span></div><progress id="launch-progress" value="<cfoutput>#launchChecklist.completed#</cfoutput>" max="<cfoutput>#launchChecklist.total#</cfoutput>" aria-labelledby="launch-progress-label"></progress></div>
<p class="contract-note" id="contract-status"><cfif launchChecklist.steps[3].completed>Contrato com a ABRACEO: etapa validada. Confira o alinhamento da comunicação antes da divulgação.<cfelse><b>Pendente: aprovação do contrato com a ABRACEO.</b> Concluir antes da comunicação conjunta da parceria.</cfif></p>
<input type="hidden" id="launch-csrf" value="<cfoutput>#encodeForHTMLAttribute(SESSION.businessStudyCsrf)#</cfoutput>">
<p id="launch-feedback" class="checklist-feedback" role="status" aria-live="polite"></p><noscript><p>Ative o JavaScript para registrar a validação das etapas.</p></noscript>
<div class="timeline launch-checklist"><cfoutput><cfloop array="#launchChecklist.steps#" index="launchStep">
<article id="etapa-#encodeForHTMLAttribute(launchStep.key)#" class="launch-step<cfif launchStep.key EQ 'lancamento'> launch</cfif><cfif launchStep.key EQ 'contrato-abraceo'> contract</cfif><cfif launchStep.completed> is-complete</cfif>">
<time>#encodeForHTML(launchStep.date)#</time><h3>#encodeForHTML(launchStep.title)#</h3><p>#encodeForHTML(launchStep.description)#</p>
<label class="step-validation"><input type="checkbox" data-launch-step="#encodeForHTMLAttribute(launchStep.key)#" data-version="#encodeForHTMLAttribute(launchStep.version)#" aria-label="Validar: #encodeForHTMLAttribute(launchStep.title)#"<cfif launchStep.completed> checked</cfif> disabled><span data-step-label><cfif launchStep.completed>Etapa validada<cfelse>Validar etapa</cfif></span></label>
<p class="step-history" data-step-history><cfif len(launchStep.author)><cfif launchStep.completed>Validado<cfelse>Reaberto</cfif> por #encodeForHTML(launchStep.author)# · #encodeForHTML(launchStep.changed_at)#<cfelse>Aguardando validação da equipe.</cfif></p>
</article></cfloop></cfoutput></div>
<p class="note">Horários de Brasília. A marcação registra a conferência da equipe; não assina o contrato nem envia divulgação. Datas de janeiro e preços seguem como propostas. Prazo de resgate dos vouchers ABRACEO: 24/11.</p></section>
'''
a=s.index('<section id="no-ar">');s=s[:a]+checklist+s[a:]
s=s.replace('<span>01</span><h2>Pronto para usar','<span>02</span><h2>Pronto para usar').replace('<span>02</span><h2>Textos para divulgação','<span>03</span><h2>Textos para divulgação').replace('<span>03</span><h2>Os PDFs','<span>04</span><h2>Os PDFs').replace('<span>04</span><h2>A estratégia','<span>05</span><h2>A estratégia')
s=s.replace('</main><script>','</main><script src="checklist.js?v=20261104-checklist" defer></script><script>',1)
out('estudos/lancamento/index.cfm',s)

api='''<cfinclude template="../_context.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try {
    if(CGI.request_method!='POST') {cfheader(statuscode=405);cfheader(name='Allow',value='POST');writeOutput('{"ok":false,"message":"Use POST."}');abort;}
    if(!studyActor) {cfheader(statuscode=401);writeOutput('{"ok":false,"message":"Entre com sua conta de administrador."}');abort;}
    if(structCount(URL)>0 || (structKeyExists(CGI,'path_info') && len(CGI.path_info))) {cfheader(statuscode=400);writeOutput('{"ok":false,"message":"Requisição inválida."}');abort;}
    if(!structKeyExists(FORM,'csrf') || !isSimpleValue(FORM.csrf) || compare(FORM.csrf,SESSION.businessStudyCsrf)!=0) {cfheader(statuscode=403);writeOutput('{"ok":false,"message":"Recarregue a página para continuar."}');abort;}
    for(field in ['step','completed','expectedVersion']) if(!structKeyExists(FORM,field) || !isSimpleValue(FORM[field])) throw(type='StudyAccess.Validation',message='Informe a etapa e o estado esperado.');
    if(!listFind('true,false',FORM.completed)) throw(type='StudyAccess.Validation',message='Estado inválido.');
    result=studyService.adminValidateLaunchStep(studyActor,toString(FORM.step),FORM.completed=='true',toString(FORM.expectedVersion));
    writeOutput(serializeJSON({'ok':true,'data':result}));
} catch(any err) {
    status=500;message='Não foi possível salvar. Tente novamente.';kind=listLast(err.type,'.');
    if(kind=='Validation') status=400;
    else if(kind=='Conflict') status=409;
    else if(kind=='Access' || kind=='Forbidden') status=403;
    else if(kind=='Missing') status=404;
    if(status!=500) message=err.message;
    response={'ok':false,'message':message};
    if(status==409) response['data']=studyService.adminLaunchChecklist(studyActor);
    cfheader(statuscode=status);writeOutput(serializeJSON(response));
}
</cfscript>
'''
out('estudos/lancamento/checklist.cfm',api)
js='''(function () {
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
      inputs.forEach(function (item) { item.disabled = true; });
      feedback.textContent = 'Salvando validação…';
      feedback.classList.remove('is-error');
      try {
        var form = new URLSearchParams({csrf: document.getElementById('launch-csrf').value, step: input.dataset.launchStep, completed: String(input.checked), expectedVersion: input.dataset.version});
        var response = await fetch('checklist.cfm', {method: 'POST', credentials: 'same-origin', headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: form.toString()});
        var result = await response.json();
        if (!response.ok || !result.ok) {
          if (result.data) apply(result.data); else input.checked = previous;
          throw new Error(result.message || 'Não foi possível salvar. Recarregue a página para conferir o estado atual.');
        }
        apply(result.data);
        feedback.textContent = input.checked ? 'Etapa validada e salva para a equipe.' : 'Etapa reaberta e salva para a equipe.';
      } catch (error) {
        input.checked = previous;
        feedback.textContent = error.message || 'Não foi possível salvar. Recarregue a página para conferir o estado atual.';
        feedback.classList.add('is-error');
      } finally {
        inputs.forEach(function (item) { item.disabled = false; });
      }
    });
  });
})();
'''
# On a stale response keep the refreshed server state, rather than restoring the old checkbox.
js=js.replace("var previous = !input.checked;","var previous = !input.checked;\n      var refreshed = false;").replace("if (result.data) apply(result.data); else input.checked = previous;","if (result.data) { apply(result.data); refreshed = true; } else input.checked = previous;").replace("      } catch (error) {\n        input.checked = previous;","      } catch (error) {\n        if (!refreshed) input.checked = previous;")
out('estudos/lancamento/checklist.js',js)
css='''
/* Shared administrator launch checklist. */
.launch-intro{padding:26px 0 16px;gap:20px}.launch-intro h1{font-size:clamp(27px,3vw,40px);margin:10px 0 14px}.launch-intro p{margin-bottom:0}.launch-intro .eyebrow{font-size:11px}.launch-intro .button{font-size:14px}
.launch-progress{display:flex;align-items:center;justify-content:space-between;gap:24px;padding:18px 22px;background:white;border:1px solid var(--line);border-radius:12px}.launch-progress strong{display:block;font-size:19px}.launch-progress span{display:block;font-size:13px;color:var(--muted);margin-top:4px}.launch-progress progress{width:220px;min-width:160px;height:13px;accent-color:#655099}.contract-note{margin:16px 0 0;padding:15px 20px;background:#e6ddf2;border-left:4px solid #8064ad;border-radius:7px;font-size:15px}.checklist-feedback{min-height:25px;margin:10px 0 0;font-size:14px;color:#315c4b}.checklist-feedback.is-error{color:#9d342d}.launch-checklist{margin-top:9px}.launch-step{display:flex;flex-direction:column}.launch-step>p:first-of-type{font-size:15px;line-height:1.65}.launch-step.contract{border-color:#a48dbe;background:#f7f2fc}.launch-step.is-complete{box-shadow:inset 0 4px #398263}.step-validation{display:flex;align-items:center;gap:10px;margin:22px 0 10px;padding-top:17px;border-top:1px solid #0002;font-weight:600;font-size:15px;cursor:pointer}.step-validation input{width:23px;height:23px;flex-shrink:0;accent-color:#286747;cursor:pointer}.step-validation input:focus-visible{outline:3px solid #7058b5;outline-offset:4px}.step-validation input:disabled{cursor:wait}.launch-checklist .step-history{font-size:12px;line-height:1.6;color:#525252;margin:0;min-height:39px;overflow-wrap:anywhere}.launch-checklist .step-validation{margin-top:auto}.launch-checklist .launch .step-history{color:#40380f}.launch-checklist h3{font-size:23px}.launch-checklist time{line-height:1.5}
@media(max-width:1050px){.launch-checklist{grid-template-columns:repeat(2,minmax(0,1fr))}.launch-intro{align-items:flex-start}}@media(max-width:650px){.launch-progress{display:block}.launch-progress progress{margin-top:16px;width:100%}.launch-intro .button{margin-top:16px}.launch-checklist{grid-template-columns:1fr}.launch-checklist article{padding:23px}.launch-checklist .step-history{min-height:0}.launch-checklist .step-validation{margin-top:22px}.launch-progress strong{font-size:18px}}
'''
out('estudos/lancamento/lancamento.css',baseline('estudos/lancamento/lancamento.css')+css)
print('Built 5 Business files: shared checklist, audit-backed validation, chronology first.')
