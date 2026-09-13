/* A IA preenche somente o editor; o fluxo existente continua responsável pelo envio. */
(() => {
  'use strict';
  const panel = document.querySelector('[data-helpdesk-ai]');
  if (!panel) return;
  const form = panel.closest('form');
  const editor = form.querySelector('[name="ticket_mensagem"]');
  const button = panel.querySelector('[data-ai-generate]');
  const status = panel.querySelector('[data-ai-status]');
  const sources = panel.querySelector('[data-ai-sources]');
  const pending = panel.querySelector('[data-ai-pending]');
  const preview = panel.querySelector('[data-ai-preview]');
  const undo = panel.querySelector('[data-ai-undo]');
  let previous = null;
  let applied = '';
  let running = false;
  let editVersion = 0;
  editor.addEventListener('input', () => { editVersion++; });
  function announce(text, error = false) {
    status.textContent = text;
    status.classList.toggle('text-danger', error);
  }
  function apply(text) {
    previous = editor.value;
    applied = text;
    editor.value = text;
    editor.dispatchEvent(new Event('input', { bubbles: true }));
    undo.hidden = false;
    pending.hidden = true;
    preview.value = '';
    editor.focus();
    announce('Rascunho inserido. Revise e ajuste a nova mensagem; nada foi enviado.');
  }
  button.addEventListener('click', async () => {
    if (running) return;
    if (!pending.hidden && !window.confirm('Descartar a sugestão pendente e gerar outra? Seu texto no editor será mantido.')) return;
    const initial = editor.value;
    const initialVersion = editVersion;
    running = true;
    button.disabled = true;
    button.textContent = 'Criando rascunho…';
    panel.setAttribute('aria-busy', 'true');
    pending.hidden = true;
    sources.hidden = true;
    announce('Consultando o histórico e a base de conhecimento. Isso pode levar até 90 segundos.');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 95000);
    try {
      const body = new URLSearchParams({
        ticket_id: form.querySelector('[name="ticket_id"]').value,
        csrf_token: panel.dataset.csrf,
        note: panel.querySelector('[data-ai-note]').value.trim()
      });
      const response = await fetch(panel.dataset.endpoint, {
        method: 'POST', credentials: 'same-origin', cache: 'no-store',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'Accept': 'application/json' },
        body, signal: controller.signal
      });
      if (!response.headers.get('content-type')?.includes('application/json')) throw new Error('Sua sessão pode ter expirado. Recarregue a página após guardar seu texto.');
      const result = await response.json();
      if (!response.ok || result.success !== true) throw new Error(result.message || 'Não foi possível gerar o rascunho. Tente novamente.');
      if (typeof result.draft !== 'string' || !result.draft.trim() || result.draft.length > 12000) throw new Error('A IA retornou um rascunho inválido. Tente novamente.');
      const titles = Array.isArray(result.sources) ? result.sources.filter(s => typeof s.title === 'string').map(s => s.title) : [];
      const warnings = Array.isArray(result.warnings) ? result.warnings.filter(w => typeof w === 'string') : [];
      sources.textContent = ['Contexto consultado: ' + titles.join(' · '), ...warnings].join('\n');
      sources.style.whiteSpace = 'pre-line';
      sources.hidden = false;
      // Não sobrescreve texto existente nem alterações feitas durante a consulta.
      if (!initial.trim() && editor.value === initial && editVersion === initialVersion) apply(result.draft.trim());
      else {
        preview.value = result.draft.trim();
        pending.hidden = false;
        announce('Sugestão pronta. Confira abaixo e escolha se deseja substituir o texto no editor. Nada foi enviado.');
      }
    } catch (error) {
      announce(error.name === 'AbortError' ? 'A geração demorou mais que o esperado. Seu texto foi preservado; aguarde alguns instantes antes de tentar novamente.' : (error.message || 'Falha de conexão. Seu texto foi preservado.'), true);
    } finally {
      clearTimeout(timeout);
      running = false;
      button.disabled = false;
      button.textContent = 'Criar resposta com IA';
      panel.removeAttribute('aria-busy');
    }
  });
  panel.querySelector('[data-ai-apply]').addEventListener('click', () => {
    if (preview.value && (!editor.value.trim() || window.confirm('Substituir a nova mensagem pela sugestão da IA? Você poderá recuperar o texto anterior.'))) apply(preview.value);
  });
  panel.querySelector('[data-ai-discard]').addEventListener('click', () => {
    pending.hidden = true;
    preview.value = '';
    sources.hidden = true;
    announce('Sugestão descartada. Seu texto no editor foi mantido.');
  });
  undo.addEventListener('click', () => {
    if (previous === null) return;
    if (editor.value !== applied && !window.confirm('Recuperar o texto anterior? As edições feitas após aplicar a IA serão substituídas.')) return;
    editor.value = previous;
    editor.dispatchEvent(new Event('input', { bubbles: true }));
    previous = null;
    undo.hidden = true;
    sources.hidden = true;
    editor.focus();
    announce('Texto anterior recuperado. Nada foi enviado.');
  });
})();
