(() => {
  'use strict';
  const period = document.getElementById('ou-period');
  if (!period) return;
  const update = () => document.querySelectorAll('.ou-custom').forEach(field => {
    field.hidden = period.value !== 'custom';
  });
  period.addEventListener('change', update);
  update();
})();
