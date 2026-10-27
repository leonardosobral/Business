'use strict';
document.addEventListener('click', async event => {
  const trigger = event.target.closest('[data-copy-target]');
  if (!trigger) return;
  const input = document.getElementById(trigger.dataset.copyTarget);
  if (!input) return;
  try { await navigator.clipboard.writeText(input.value); trigger.textContent = 'Copiado'; }
  catch { input.focus(); input.select(); trigger.textContent = 'Selecione e copie o link'; }
});
document.addEventListener('submit', event => {
  const form = event.target;
  if (form.dataset.confirm && !window.confirm(form.dataset.confirm)) event.preventDefault();
});
document.querySelectorAll('.teams-tabs').forEach(nav => nav.addEventListener('keydown', event => {
  if (!['ArrowLeft','ArrowRight','Home','End'].includes(event.key)) return;
  const links = [...nav.querySelectorAll('a')]; const at = links.indexOf(document.activeElement);
  if (at < 0) return;
  event.preventDefault();
  const next = event.key === 'Home' ? 0 : event.key === 'End' ? links.length-1 : (at + (event.key === 'ArrowRight' ? 1 : -1) + links.length) % links.length;
  links[next].focus();
}));

document.querySelectorAll('[data-team-qr]').forEach(node => {
  if (typeof qrcode !== 'function') return;
  const qr = qrcode(0, 'M'); qr.addData(node.dataset.teamQr); qr.make();
  const svg = qr.createSvgTag({cellSize: 4, margin: 16, scalable: true});
  node.innerHTML = svg;
  const download = node.closest('figure').querySelector('[data-qr-download]');
  download.href = URL.createObjectURL(new Blob([svg], {type: 'image/svg+xml'}));
});
