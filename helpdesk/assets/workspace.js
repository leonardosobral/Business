(() => {
  'use strict';
  const form = document.querySelector('[data-hd-reply]');
  if (!form) return;
  const editor = form.querySelector('[name="ticket_mensagem"]');
  const feedback = form.querySelector('[data-hd-feedback]');
  const count = form.querySelector('[data-hd-count]');
  const templates = {
    contexto: 'Olá! Para entendermos melhor o que aconteceu, você pode informar em qual etapa encontrou a dificuldade e qual mensagem apareceu? Se enviar uma captura de tela, oculte senhas e outros dados sensíveis.\n\nCom esse contexto, poderemos orientar os próximos passos.',
    andamento: 'Olá! Obrigado por compartilhar os detalhes. Vamos analisar as informações do chamado para orientar você com segurança. Se houver algum contexto adicional que possa ajudar, pode nos enviar por aqui.',
    confirmacao: 'Olá! Você conseguiu realizar o procedimento orientado na nossa conversa? Se a dificuldade continuar, conte em qual etapa ela ocorre e qual mensagem aparece para darmos continuidade ao atendimento.'
  };
  let dirty = editor.value.trim().length > 0;
  let sending = false;
  const update = () => { count.textContent = `${editor.value.length.toLocaleString('pt-BR')} / 12.000`; };
  update();
  form.addEventListener('input', () => { dirty = true; update(); });
  form.addEventListener('change', () => { dirty = true; });
  form.querySelector('[data-hd-insert]').addEventListener('click', () => {
    const text = templates[form.querySelector('[data-hd-template]').value];
    if (!text) { feedback.textContent = 'Escolha uma resposta rápida para inserir.'; return; }
    const next = editor.value.trim() ? `${editor.value}\n\n${text}` : text;
    if (next.length > 12000) { feedback.textContent = 'O texto ultrapassaria 12.000 caracteres. Reduza o rascunho antes de inserir.'; return; }
    editor.value = next;
    editor.dispatchEvent(new Event('input', {bubbles: true}));
    editor.focus();
    feedback.textContent = 'Texto inserido ao final do rascunho. Revise e personalize antes de enviar.';
  });
  form.addEventListener('submit', event => {
    if (sending) { event.preventDefault(); return; }
    const action = event.submitter?.value;
    if (!['responder_ticket','atualizar_ticket'].includes(action)) { event.preventDefault(); return; }
    if (action === 'responder_ticket' && (!editor.value.trim() || editor.value.length > 12000)) {
      event.preventDefault(); feedback.textContent = 'Escreva uma resposta entre 1 e 12.000 caracteres.'; editor.focus(); return;
    }
    if (action === 'atualizar_ticket' && editor.value.trim() && !window.confirm('O texto não será enviado e será descartado ao atualizar somente status e setor. Deseja continuar?')) {
      event.preventDefault(); return;
    }
    sending = true;
    form.setAttribute('aria-busy','true');
    feedback.textContent = action === 'responder_ticket' ? 'Enviando resposta…' : 'Salvando status e setor…';
  });
  window.addEventListener('beforeunload', event => {
    if (dirty && !sending) { event.preventDefault(); event.returnValue = ''; }
  });
  window.addEventListener('pageshow', () => { sending = false; form.removeAttribute('aria-busy'); });
})();
