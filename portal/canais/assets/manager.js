(() => {
  'use strict';
  const pickers = new Map();
  document.querySelectorAll('[data-name-picker]').forEach(root => {
    const kind = root.dataset.namePicker;
    const input = root.querySelector('[data-picker-input]');
    const hidden = root.querySelector('[data-picker-id]');
    const options = root.querySelector('[data-picker-options]');
    const status = root.querySelector('[data-picker-status]');
    let selected = input.value, timer, controller, generation = 0;
    const set = (id, label) => { hidden.value = String(id || ''); input.value = label || ''; selected = input.value; input.setCustomValidity(''); status.textContent = id ? 'Selecionado.' : 'Digite pelo menos dois caracteres e escolha um resultado.'; };
    pickers.set(kind, {set, hidden});
    input.addEventListener('input', () => {
      clearTimeout(timer); if (controller) controller.abort(); generation++;
      input.setCustomValidity('');
      const option = Array.from(options.options).find(option => option.value === input.value);
      if (option) {
        set(option.dataset.id, option.value);
        const user = pickers.get('user');
        if (kind === 'page' && user && !user.hidden.value && Number(option.dataset.ownerId) > 0) user.set(option.dataset.ownerId, option.dataset.ownerLabel);
        return;
      }
      if (input.value !== selected) hidden.value = '';
      if (input.value.trim().length < 2) { options.replaceChildren(); status.textContent = 'Digite pelo menos dois caracteres.'; return; }
      const requestGeneration = generation;
      timer = setTimeout(async () => {
        controller = new AbortController(); status.textContent = 'Buscando…';
        try {
          const response = await fetch('/portal/canais/?' + new URLSearchParams({lookup: kind, q: input.value.trim()}), {signal: controller.signal, credentials: 'same-origin', headers: {Accept: 'application/json'}});
          if (!response.ok || !response.headers.get('content-type')?.includes('application/json')) throw new Error('lookup');
          const data = await response.json(); if (requestGeneration !== generation) return;
          const items = Array.isArray(data.items) ? data.items : [];
          options.replaceChildren(...items.map(item => { const option = document.createElement('option'); option.value = item.label; option.dataset.id = item.id; option.dataset.ownerId = item.owner_id || ''; option.dataset.ownerLabel = item.owner_label || ''; return option; }));
          status.textContent = items.length ? 'Escolha um dos resultados sugeridos.' : 'Nenhum resultado. Tente outro nome.';
        } catch (error) { if (error.name !== 'AbortError' && requestGeneration === generation) status.textContent = 'Não foi possível buscar. Tente novamente ou recarregue a página.'; }
      }, 280);
    });
    input.closest('form').addEventListener('submit', event => { if (input.value.trim() && !hidden.value) { event.preventDefault(); input.setCustomValidity('Escolha um resultado da busca ou deixe o vínculo vazio.'); input.reportValidity(); } });
  });
  const kind = document.querySelector('[data-source-kind]'), source = document.querySelector('[data-source-input]');
  if (kind && source) kind.addEventListener('change', () => { source.placeholder = kind.value === 'playlist' ? 'https://www.youtube.com/playlist?list=…' : 'https://www.youtube.com/@nomedocanal'; });
})();
