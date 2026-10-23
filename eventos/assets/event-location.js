(() => {
  'use strict';
  const root = document.querySelector('[data-event-location]');
  if (!root) return;
  const country = root.querySelector('[data-event-country]');
  const brazil = root.querySelector('[data-event-br-fields]');
  const foreign = root.querySelector('[data-event-foreign-fields]');
  const mode = root.querySelector('[data-event-location-mode]');
  const update = () => {
    const isBrazil = country.value === 'BR';
    brazil.hidden = !isBrazil; brazil.disabled = !isBrazil;
    foreign.hidden = isBrazil; foreign.disabled = isBrazil;
    mode.value = isBrazil ? 'br' : 'foreign';
    document.querySelectorAll('[data-event-br-lookup]').forEach(element => { element.hidden = !isBrazil; });
  };
  country.addEventListener('change', update);
  update();
})();
