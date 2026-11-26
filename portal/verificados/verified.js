(() => {
    'use strict';
    const bulk = document.getElementById('verified-bulk-form');
    const checkboxes = [...document.querySelectorAll('.verified-row-select:not(:disabled)')];
    const selectAll = document.getElementById('verified-select-all');
    const submit = document.getElementById('verified-bulk-submit');
    const counter = document.getElementById('verified-selected-count');
    const jump = document.getElementById('verified-bulk-jump');
    const updateSelection = () => {
        const selected = checkboxes.filter(input => input.checked).length;
        if (counter) counter.textContent = `${selected} selecionado${selected === 1 ? '' : 's'}`;
        if (submit) submit.disabled = selected === 0;
        if (jump) { jump.hidden = selected === 0; jump.textContent = `Classificar ${selected} selecionado${selected === 1 ? '' : 's'} ↑`; }
        if (selectAll) {
            selectAll.disabled = checkboxes.length === 0;
            selectAll.checked = selected > 0 && selected === checkboxes.length;
            selectAll.indeterminate = selected > 0 && selected < checkboxes.length;
        }
        checkboxes.forEach(input => input.closest('tr').classList.toggle('is-selected', input.checked));
    };
    checkboxes.forEach(input => input.addEventListener('change', updateSelection));
    if (selectAll) selectAll.addEventListener('change', () => {
        checkboxes.forEach(input => { input.checked = selectAll.checked; });
        updateSelection();
    });
    document.querySelectorAll('[data-quick-form]').forEach(form => {
        const category = form.querySelector('[data-quick-category]');
        const note = form.querySelector('[data-quick-note]');
        const optional = form.querySelector('[data-note-optional]');
        const updateReason = () => {
            note.required = category.value === 'outro';
            note.placeholder = note.required ? 'Descreva o motivo da concessão' : 'Vínculo ou observação (opcional)';
            if (optional) optional.textContent = note.required ? '(obrigatório para Outro motivo)' : '(opcional)';
        };
        category.addEventListener('change', updateReason);
        updateReason();
        form.addEventListener('submit', event => {
            if (form === bulk && !checkboxes.some(input => input.checked)) {
                event.preventDefault();
                counter.textContent = 'Selecione pelo menos uma pessoa.';
                return;
            }
            // Keep the submitted values intact; suppress a second submit until navigation completes.
            if (form.dataset.saving) { event.preventDefault(); return; }
            form.dataset.saving = 'true';
            form.querySelectorAll('button[type="submit"]').forEach(button => {
                button.disabled = true;
                button.textContent = 'Salvando…';
            });
        });
    });
    window.addEventListener('pageshow', event => { if (event.persisted) window.location.reload(); });
    updateSelection();
})();
