(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else {
    root.CatarinenseContact = api;
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => api.init(document), {once:true});
    else api.init(document);
  }
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const text = value => typeof value === 'string' || typeof value === 'number' ? String(value).trim() : '';
  function phone(raw, ddi, ddd) {
    raw = text(raw);
    if (!/^[+\d\s().-]+$/.test(raw)) return '';
    let digits = raw.replace(/\D/g, '');
    const international = raw.startsWith('+') || digits.startsWith('00');
    if (digits.startsWith('00')) digits = digits.slice(2);
    const country = text(ddi).replace(/^\+/, '') || '55';
    const area = text(ddd);
    if (!international) {
      if (!/^[1-9]\d{0,2}$/.test(country)) return '';
      if (country === '55') {
        if ((digits.length === 12 || digits.length === 13) && digits.startsWith('55')) { /* Already E.164. */ }
        else if (digits.length === 10 || digits.length === 11) digits = country + digits;
        else if ((digits.length === 8 || digits.length === 9) && /^[1-9]\d$/.test(area)) digits = country + area + digits;
        else return '';
      } else {
        if (digits.length <= 7 && /^\d{1,3}$/.test(area)) digits = area + digits;
        digits = country + digits;
      }
    }
    return /^[1-9]\d{7,14}$/.test(digits) ? digits : '';
  }
  function socialUrl(raw) {
    try {
      const url = new URL(raw);
      return ['https:','http:'].includes(url.protocol) && !url.username && !url.password && !url.port ? url : null;
    } catch { return null; }
  }
  function whatsapp(raw, ddi, ddd) {
    raw = text(raw);
    // RR stores bare profile WhatsApp digits as a complete wa.me recipient,
    // independently of the country/area code of the athlete's telephone.
    if (/^[1-9]\d{7,14}$/.test(raw)) return phone('+' + raw, ddi, ddd);
    if (/^(?:www\.)?wa\.me\//i.test(raw)) raw = 'https://' + raw;
    if (/^https?:/i.test(raw)) {
      const url = socialUrl(raw);
      if (!url) return '';
      if (url.hostname === 'wa.me' && /^\/\d{8,15}\/?$/.test(url.pathname)) return phone('+' + url.pathname.replace(/\//g, ''), ddi, ddd);
      if (['api.whatsapp.com','web.whatsapp.com'].includes(url.hostname) && url.pathname === '/send') return phone('+' + (url.searchParams.get('phone') || ''), ddi, ddd);
      return '';
    }
    return phone(raw, ddi, ddd);
  }
  function instagram(raw) {
    raw = text(raw);
    if (/^(?:www\.)?instagram\.com\//i.test(raw)) raw = 'https://' + raw;
    if (/^https?:/i.test(raw)) {
      const url = socialUrl(raw);
      if (!url || !['instagram.com','www.instagram.com'].includes(url.hostname) || !/^\/[^/]+\/?$/.test(url.pathname)) return '';
      try { raw = decodeURIComponent(url.pathname.replace(/^\/|\/$/g, '')); } catch { return ''; }
    }
    raw = raw.replace(/^@/, '');
    return /^[a-zA-Z0-9_](?:[a-zA-Z0-9._]{0,28}[a-zA-Z0-9_])?$/.test(raw) && !raw.includes('..') ? raw : '';
  }
  function avatar(raw) {
    raw = text(raw);
    if (raw.startsWith('/') && !raw.startsWith('//') && !raw.includes('\\')) return raw;
    const url = socialUrl(raw);
    return url && url.protocol === 'https:' ? url.href : '/assets/user.png';
  }
  function contact(input) {
    const data = {};
    if (input && typeof input === 'object') for (const [key,value] of Object.entries(input)) data[key.toLowerCase()] = text(value);
    const email = /^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/.test(data.email || '') && data.email.length <= 254 ? data.email : '';
    const number = phone(data.telefone_usuario, data.ddi_usuario, data.ddd_usuario);
    const specific = whatsapp(data.whatsapp, data.ddi_usuario, data.ddd_usuario);
    const wa = specific || number;
    const ig = instagram(data.instagram);
    const id = /^[1-9]\d*$/.test(data.id || '') ? data.id : '';
    return {
      name:data.nome || 'Atleta', id, avatar:avatar(data.imagem_usuario),
      location:[data.cidade,data.estado].filter(Boolean).join(' / '), team:data.equipe || '',
      email, phone:number ? '+' + number : '', whatsapp:wa ? '+' + wa : '', instagram:ig ? '@' + ig : '',
      whatsappSource:wa ? (specific ? 'Contato do perfil' : 'Telefone cadastrado') : '',
      links:{email:email ? 'mailto:' + encodeURIComponent(email).replace(/%40/g, '@') : '', phone:number ? 'tel:+' + number : '',
        whatsapp:wa ? 'https://wa.me/' + wa : '', instagram:ig ? 'https://www.instagram.com/' + ig + '/' : '',
        profile:data.tag ? 'https://roadrunners.run/atleta/' + encodeURIComponent(data.tag) + '/' : '',
        chat:id ? 'https://roadrunners.run/mensagens/?destinatario=' + id : ''}
    };
  }
  function init(document) {
    const dialog = document.getElementById('catarinenseContactDialog');
    if (!dialog || dialog.dataset.contactReady) return;
    dialog.dataset.contactReady = '1';
    let opener = null;
    const set = (selector,value) => { const element=dialog.querySelector(selector); element.textContent=value; };
    document.addEventListener('click', event => {
      const button = event.target.closest('[data-catarinense-contact]');
      if (!button) return;
      let value;
      try { value = contact(JSON.parse(button.dataset.catarinenseContact)); } catch { return; }
      opener = button;
      set('[data-contact-name]', value.name);
      set('[data-contact-id]', value.id ? 'ID ' + value.id : '');
      set('[data-contact-location]', value.location || 'Local não informado');
      set('[data-contact-team]', value.team ? 'Assessoria: ' + value.team : 'Assessoria não informada');
      set('[data-contact-whatsapp-source]', value.whatsappSource);
      const image = dialog.querySelector('[data-contact-avatar]');
      image.onerror = () => { image.onerror=null; image.src='/assets/user.png'; };
      image.src = value.avatar;
      for (const field of ['email','phone','whatsapp','instagram']) {
        const element = dialog.querySelector('[data-contact-value="' + field + '"]');
        element.textContent = value[field] || 'Não informado';
        if (value.links[field]) element.href = value.links[field]; else element.removeAttribute('href');
      }
      for (const element of dialog.querySelectorAll('[data-contact-action]')) {
        const href = value.links[element.dataset.contactAction];
        element.hidden = !href;
        if (href) element.href = href; else element.removeAttribute('href');
      }
      if (!dialog.open) dialog.showModal();
      document.body.classList.add('catarinense-contact-open');
    });
    for (const button of dialog.querySelectorAll('[data-contact-close]')) button.addEventListener('click', () => dialog.close());
    dialog.addEventListener('close', () => {
      document.body.classList.remove('catarinense-contact-open');
      if (opener && opener.isConnected) opener.focus();
    });
    dialog.addEventListener('click', event => {
      if (event.target !== dialog) return;
      const rect = dialog.getBoundingClientRect();
      if (event.clientX<rect.left || event.clientX>rect.right || event.clientY<rect.top || event.clientY>rect.bottom) dialog.close();
    });
  }
  return {contact,init};
}));
