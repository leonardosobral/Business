const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {resolve} = require('node:path');
const vm = require('node:vm');
const source = readFileSync(resolve(__dirname,'../../assets/js/audience-dashboard.js'),'utf8');

// Small DOM boundary for the real navigation script; rendering is covered by CFML tests.
function fixture(hash = '#regioes') {
  const ids = new Map();
  class Element {
    constructor(id = '', parent = null, attrs = {}) { this.id=id; this.parent=parent; this.attrs=attrs; this.events={}; this.hidden=false; if(id) ids.set(id,this); }
    setAttribute(key,value) { this.attrs[key]=value; }
    getAttribute(key) { return this.attrs[key] ?? null; }
    addEventListener(key,fn) { (this.events[key] ||= []).push(fn); }
    dispatch(key,extra={}) { for(const fn of this.events[key] || []) fn({button:0,preventDefault(){},...extra}); }
    contains(child) { for(let item=child;item;item=item.parent) if(item===this) return true; return false; }
    focus() { doc.activeElement=this; }
    scrollIntoView() { this.scrolled=true; }
  }
  const page = new Element('page');
  const names = ['overview','regions','capacity','positions','content','acquisition','coverage'];
  const panels = names.map(name=>new Element('audience-'+name,page));
  const tabs = panels.map(panel=>{const link=new Element();link.hash='#'+panel.id;return link;});
  const navigation = new Element(); navigation.querySelectorAll=()=>tabs;
  const regionSection = new Element('regioes',panels[1]);
  const formats = ['all','ads','banners','other'].map(name=>new Element('regioes-'+name,regionSection,{'data-region-format':name}));
  const choices = formats.map(format=>{const link=new Element('',regionSection,{'data-region-choice':format.attrs['data-region-format']});link.hash='#'+format.id;return link;});
  const regionNavigation = new Element('',regionSection); regionNavigation.querySelectorAll=()=>choices;
  const legacyLive = new Element('jornada-live',panels[5]);
  const globalForm = new Element('',page);
  const liveForm = new Element('',legacyLive);
  page.querySelector = selector=>selector==='[data-audience-tabs]' ? navigation : selector==='[data-region-filters]' ? regionNavigation : null;
  page.querySelectorAll = selector=>selector==='form[method="get"]' ? [globalForm,liveForm] : [];
  const doc = {readyState:'complete',querySelector:()=>page,getElementById:id=>ids.get(id) || null,activeElement:null};
  const listeners = {};
  const win = {document:doc,location:{hash},history:{pushState(_,__,next){win.location.hash=next;}},requestAnimationFrame:fn=>fn(),
    addEventListener(key,fn){(listeners[key] ||= []).push(fn);}};
  vm.runInNewContext(source,{window:win});
  return {panels,tabs,formats,choices,globalForm,liveForm,doc,win,legacyLive,
    restore(next,key='popstate'){win.location.hash=next;for(const fn of listeners[key] || []) fn();}};
}
test('legacy regional anchor reveals Regiões and defaults to Ads while keeping one format visible',()=>{
  const ui=fixture();
  assert.equal(ui.panels[1].hidden,false);
  assert.equal(ui.panels.filter(panel=>!panel.hidden).length,1);
  assert.deepEqual(ui.formats.filter(panel=>!panel.hidden).map(panel=>panel.id),['regioes-ads']);
  assert.equal(ui.choices[1].getAttribute('aria-current'),'true');
});
test('format links, deep links and history restore the correct table and preserve GET filter context',()=>{
  const ui=fixture('#regioes-banners');
  assert.deepEqual(ui.formats.filter(panel=>!panel.hidden).map(panel=>panel.id),['regioes-banners']);
  ui.choices[0].dispatch('click');
  assert.equal(ui.win.location.hash,'#regioes-all');
  assert.deepEqual(ui.formats.filter(panel=>!panel.hidden).map(panel=>panel.id),['regioes-all']);
  ui.restore('#regioes-banners');
  assert.deepEqual(ui.formats.filter(panel=>!panel.hidden).map(panel=>panel.id),['regioes-banners']);
  ui.globalForm.dispatch('submit');
  assert.equal(ui.globalForm.getAttribute('action'),'#regioes-banners');
});
test('existing LIVE links, keyboard navigation and history remain functional with the seventh tab',()=>{
  const ui=fixture('#jornada-live');
  assert.equal(ui.panels[5].hidden,false);
  assert.equal(ui.legacyLive.scrolled,true);
  ui.tabs[5].dispatch('keydown',{key:'ArrowRight'});
  assert.equal(ui.panels[6].hidden,false);
  assert.equal(ui.doc.activeElement,ui.tabs[6]);
  ui.tabs[6].dispatch('keydown',{key:'ArrowRight'});
  assert.equal(ui.panels[0].hidden,false);
  ui.restore('#jornada-live','hashchange');
  assert.equal(ui.panels[5].hidden,false);
  ui.liveForm.dispatch('submit');
  assert.equal(ui.liveForm.getAttribute('action'),'#jornada-live');
  ui.restore('');
  assert.equal(ui.panels[0].hidden,false);
});
