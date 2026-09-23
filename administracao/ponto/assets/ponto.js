(() => {
    'use strict';
    const format = (seconds) => {
        const minutes = Math.floor(Math.max(0, seconds) / 60);
        return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, '0')}min`;
    };
    const timer = document.querySelector('[data-ponto-timer]');
    if (timer?.dataset.running === 'true') {
        const start = performance.now();
        const seconds = Number(timer.dataset.seconds);
        setInterval(() => { timer.textContent = format(seconds + (performance.now() - start) / 1000); }, 1000);
    }
    const editor = document.querySelector('[data-ponto-editor]');
    if (editor) {
        const periods = editor.querySelector('[data-ponto-periods]');
        const renumber = () => {
            const rows = periods.querySelectorAll('[data-ponto-period]');
            editor.querySelector('[data-ponto-count]').value = rows.length;
            rows.forEach((row, index) => {
                row.querySelector('[name^="inicio_"]').name = `inicio_${index + 1}`;
                row.querySelector('[name^="fim_"]').name = `fim_${index + 1}`;
                row.querySelector('[name^="inicio_"]').setAttribute('aria-label', `Início do período ${index + 1}`);
                row.querySelector('[name^="fim_"]').setAttribute('aria-label', `Fim do período ${index + 1}`);
                row.querySelector('[data-ponto-remove]').disabled = rows.length === 1;
            });
            editor.querySelector('[data-ponto-add]').disabled = rows.length >= 50;
        };
        editor.querySelector('[data-ponto-add]').addEventListener('click', () => {
            const row = periods.firstElementChild.cloneNode(true);
            row.querySelectorAll('input').forEach(input => { input.value = ''; });
            periods.append(row);
            renumber();
            row.querySelector('input').focus();
        });
        periods.addEventListener('click', event => {
            if (event.target.closest('[data-ponto-remove]') && periods.children.length > 1) {
                event.target.closest('[data-ponto-period]').remove();
                renumber();
            }
        });
        renumber();
    }
    const trip = document.querySelector('[data-ponto-trip]');
    if (trip) {
        const preview = trip.querySelector('[data-ponto-trip-preview]');
        const update = () => {
            const from = new Date(`${trip.elements.viagem_de.value}T00:00:00Z`);
            const to = new Date(`${trip.elements.viagem_ate.value}T00:00:00Z`);
            const days = Math.round((to - from) / 86400000);
            if (!Number.isFinite(days) || days < 0 || days > 365) {
                preview.textContent = 'Selecione um intervalo de até 366 dias.';
                return;
            }
            let count = 0;
            for (let i = 0; i <= days; i++) {
                const day = new Date(from.getTime() + i * 86400000).getUTCDay();
                if (trip.elements.fins_semana.checked || (day !== 0 && day !== 6)) count++;
            }
            preview.textContent = `${count} dia(s) · ${format(count * Number(trip.elements.horas.value) * 3600)} no total`;
        };
        trip.addEventListener('input', update);
        update();
    }
    document.querySelectorAll('[data-ponto-submit]').forEach(form => {
        form.addEventListener('submit', event => {
            if (form.dataset.busy === 'true') { event.preventDefault(); return; }
            if (form.dataset.pontoConfirm && !window.confirm(form.dataset.pontoConfirm)) {
                event.preventDefault(); return;
            }
            form.dataset.busy = 'true';
            // Keep the clicked button enabled so its action is included in POST.
            form.setAttribute('aria-busy', 'true');
        });
    });
    window.addEventListener('pageshow', event => { if (event.persisted) window.location.reload(); });
})();
