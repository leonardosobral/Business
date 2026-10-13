(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.AgendaModel = api;
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const zone = 'America/Sao_Paulo';
  function day(date) { return date.toISOString().slice(0, 10); }
  function add(value, days) { const date = new Date(value + 'T12:00:00Z'); date.setUTCDate(date.getUTCDate() + days); return day(date); }
  function local(instant) {
    const parts = Object.fromEntries(new Intl.DateTimeFormat('en-CA', { timeZone: zone, year:'numeric', month:'2-digit', day:'2-digit', hour:'2-digit', minute:'2-digit', hourCycle:'h23' }).formatToParts(new Date(instant)).map(p => [p.type,p.value]));
    return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}`;
  }
  function range(value, view) {
    const date = new Date(value + 'T12:00:00Z');
    if (view === 'week') { const from = add(value, -((date.getUTCDay() + 6) % 7)); return { from, until:add(from,7) }; }
    const from = value.slice(0,7) + '-01';
    const until = day(new Date(Date.UTC(date.getUTCFullYear(),date.getUTCMonth()+1,1,12)));
    if (view === 'list') return {from,until};
    const first = new Date(from+'T12:00:00Z');
    const gridStart = add(from,-((first.getUTCDay()+6)%7));
    const last = new Date(until+'T12:00:00Z');
    return {from:gridStart,until:add(until,(7-((last.getUTCDay()+6)%7))%7)};
  }
  function daysFor(event) {
    if (!event.start || !event.end || event.status === 'cancelled') return null;
    if (event.start.date) return {from:event.start.date,until:event.end.date};
    return {from:local(event.start.dateTime).slice(0,10),until:add(local(new Date(new Date(event.end.dateTime).getTime()-1)).slice(0,10),1)};
  }
  function onDay(event, value) { const span=daysFor(event); return !!span && value>=span.from && value<span.until; }
  function move(value, view, direction) {
    if (view==='week') return add(value,7*direction);
    const d=new Date(value+'T12:00:00Z'); return day(new Date(Date.UTC(d.getUTCFullYear(),d.getUTCMonth()+direction,1,12)));
  }
  function https(value) {
    try {const u=new URL(value);return u.protocol==='https:'&&!u.username&&!u.password?u.href:'';} catch {return '';}
  }
  function meeting(event) {
    for(const entry of event.conferenceData?.entryPoints||[]) {
      if(entry.entryPointType==='video'&&https(entry.uri))return https(entry.uri);
    }
    if(https(event.hangoutLink))return https(event.hangoutLink);
    const place=https(event.location);
    return place&&new URL(place).hostname==='meet.google.com'?place:'';
  }
  function parseGuests(value) {
    const emails=[];
    for(const raw of value.split(/[,;\n\r]+/).map(s=>s.trim()).filter(Boolean)) {
      const email=(raw.match(/^[^<>]*<([^<>]+)>$/)?.[1]||raw).trim().toLowerCase();
      if(email.length>254||!/^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/.test(email))throw new Error('E-mail inválido: '+raw);
      if(!emails.includes(email))emails.push(email);
    }
    if(emails.length>100)throw new Error('Informe até 100 participantes.');
    return emails;
  }
  function responses(guests=[]) {
    const result={total:0,accepted:0,tentative:0,declined:0,needsAction:0};
    guests.filter(g=>!g.organizer).forEach(g=>{result.total++;result[['accepted','tentative','declined'].includes(g.responseStatus)?g.responseStatus:'needsAction']++;});
    return result;
  }
  function duration(event) {
    if(!event.start||!event.end)return '';
    if(event.start.date){const days=Math.round((new Date(event.end.date)-new Date(event.start.date))/86400000);return days>1?days+' dias':'Dia inteiro';}
    const minutes=Math.round((new Date(event.end.dateTime)-new Date(event.start.dateTime))/60000);
    if(!Number.isFinite(minutes)||minutes<0)return '';
    return [minutes>=60?Math.floor(minutes/60)+'h':'',minutes%60||!minutes?(minutes%60)+'min':''].filter(Boolean).join(' ');
  }
  function matches(event,search) {
    return [event.summary,event.description,event.location,event.organizer?.email,event.organizer?.displayName,...(event.attendees||[]).flatMap(g=>[g.email,g.displayName])].join(' ').toLocaleLowerCase('pt-BR').includes(search.toLocaleLowerCase('pt-BR'));
  }
  return {zone,add,local,range,onDay,move,https,meeting,parseGuests,responses,duration,matches};
}));
