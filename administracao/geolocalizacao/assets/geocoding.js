(() => {
  'use strict';
  document.querySelector('[data-geo-review-heading]')?.focus({ preventScroll: true });
  const editor = document.getElementById('geo-edited-value');
  document.querySelectorAll('[data-geo-edit-copy]').forEach(button => button.addEventListener('click', () => {
    if (!editor) return;
    const source = document.querySelector(button.dataset.geoEditCopy === 'current' ? '[data-geo-current-value]' : '[data-geo-source-value]');
    if (source) { editor.value = source.textContent.trim(); editor.dispatchEvent(new Event('input', { bubbles: true })); editor.focus(); }
  }));
  document.querySelectorAll('[data-geo-guided-form]').forEach(form => form.addEventListener('submit', event => {
    if (form.dataset.submitting === 'true') { event.preventDefault(); return; }
    form.dataset.submitting = 'true';
    form.setAttribute('aria-busy', 'true');
    const status = form.querySelector('[data-geo-guided-status]');
    if (status) { status.classList.remove('d-none'); status.textContent = event.submitter?.value === 'skip_review' ? 'Abrindo o próximo evento sem alterar o cadastro…' : 'Salvando decisão e abrindo a próxima pendência…'; }
    // Do not disable the submitter: its name/value is part of the POST contract.
  }));
  const master = document.querySelector('[data-geo-select-all]');
  const items = [...document.querySelectorAll('[data-geo-select]')];
  const count = document.querySelector('[data-geo-count]');
  const update = () => {
    const selected = items.filter(item => item.checked).length;
    if (count) count.textContent = `${selected} selecionado(s)`;
    if (master) master.checked = items.length > 0 && selected === items.length;
  };
  if (master) master.addEventListener('change', () => { items.forEach(item => { item.checked = master.checked; }); update(); });
  items.forEach(item => item.addEventListener('change', update));
  document.querySelectorAll('[data-geo-confirm]').forEach(form => form.addEventListener('submit', event => {
    if (!window.confirm(form.dataset.geoConfirm)) event.preventDefault();
  }));
  document.querySelectorAll('[data-geo-panels]').forEach(group => {
    const tabs = [...group.querySelectorAll('[data-geo-tab]')];
    const activate = (tab, focus = false) => {
      tabs.forEach(item => {
        const selected = item === tab;
        item.setAttribute('aria-selected', String(selected));
        item.tabIndex = selected ? 0 : -1;
        item.classList.toggle('active', selected);
        const panel = document.getElementById(item.dataset.geoTab);
        if (panel) panel.hidden = !selected;
      });
      if (focus) tab.focus();
    };
    tabs.forEach((tab, index) => {
      tab.addEventListener('click', () => activate(tab));
      tab.addEventListener('keydown', event => {
        let next;
        if (event.key === 'ArrowRight') next = tabs[(index + 1) % tabs.length];
        if (event.key === 'ArrowLeft') next = tabs[(index + tabs.length - 1) % tabs.length];
        if (event.key === 'Home') next = tabs[0];
        if (event.key === 'End') next = tabs[tabs.length - 1];
        if (next) { event.preventDefault(); activate(next, true); }
      });
    });
    if (location.hash === '#geo-panel-fields') activate(tabs.find(tab => tab.dataset.geoTab === 'geo-panel-fields'));
  });
  update();
})();
