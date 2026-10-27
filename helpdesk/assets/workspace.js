(() => {
  'use strict';
  const form = document.querySelector('[data-hd-reply]');
  if (!form) return;
  const editor = form.querySelector('[name="ticket_mensagem"]');
  const feedback = form.querySelector('[data-hd-feedback]');
  const count = form.querySelector('[data-hd-count]');
  const isNote = () => form.querySelector('[name="message_kind"]:checked')?.value === 'nota';
  const mode = () => {
    const note = isNote();
    form.classList.toggle('is-note', note);
    form.querySelectorAll('[data-hd-public-panel]').forEach(panel => {
      panel.hidden = note;
      if (panel.tagName === 'BUTTON') panel.disabled = note;
      panel.querySelectorAll('button,select').forEach(control => { control.disabled = note; });
    });
    const saveNote = form.querySelector('[data-hd-note-button]');
    saveNote.hidden = !note; saveNote.disabled = !note;
    form.querySelector('[data-hd-editor-title]').textContent = note ? 'Nota interna da equipe' : 'Responder ao usuário';
    form.querySelector('[data-hd-visibility]').textContent = note ? 'Somente equipe · Não notifica o usuário' : 'Mensagem pública · Visível ao usuário';
  };
  mode();
  let dirty = editor.value.trim().length > 0;
  let sending = false;
  const update = () => { count.textContent = `${editor.value.length.toLocaleString('pt-BR')} / 12.000`; };
  update();
  form.addEventListener('input', () => { dirty = true; update(); });
  form.addEventListener('change', () => { dirty = true; mode(); });
  form.querySelector('[data-hd-insert]').addEventListener('click', () => {
    const text = form.querySelector('[data-hd-template]').selectedOptions[0]?.dataset.text;
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
    if (!['responder_ticket','atualizar_ticket','nota_ticket'].includes(action)) { event.preventDefault(); return; }
    if (isNote() && action !== 'nota_ticket') { event.preventDefault(); feedback.textContent = 'Use Salvar nota interna para manter esta mensagem privada.'; return; }
    if (['responder_ticket','nota_ticket'].includes(action) && (!editor.value.trim() || editor.value.length > 12000)) {
      event.preventDefault(); feedback.textContent = 'Escreva uma resposta entre 1 e 12.000 caracteres.'; editor.focus(); return;
    }
    if (action === 'atualizar_ticket' && editor.value.trim() && !window.confirm('O texto não será enviado e será descartado ao atualizar somente status e setor. Deseja continuar?')) {
      event.preventDefault(); return;
    }
    sending = true;
    form.setAttribute('aria-busy','true');
    feedback.textContent = action === 'nota_ticket' ? 'Salvando nota interna…' : (action === 'responder_ticket' ? 'Enviando resposta…' : 'Salvando status e setor…');
  });
  window.addEventListener('beforeunload', event => {
    if (dirty && !sending) { event.preventDefault(); event.returnValue = ''; }
  });
  window.addEventListener('pageshow', () => { sending = false; form.removeAttribute('aria-busy'); });
})();
