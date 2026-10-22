(() => {
  'use strict';
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
