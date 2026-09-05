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
  return {zone,add,local,range,onDay,move};
}));
