import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
const script=readFileSync(new URL('../../ads-network/sdk/v1.js',import.meta.url),'utf8');
function harness({serveStatus='served',broken=false}={}){
 const timers=new Map(),requests=[],observed=[];let timerId=0,observer;
 class Element{
  constructor(tag){this.tagName=tag;this.style={};this.dataset={};this.children=[];this.listeners={};this.isConnected=true;this.complete=!broken;this.naturalWidth=broken?0:300;this.parentElement=null;}
  append(...els){els.forEach(el=>{el.parentElement=this;this.children.push(el);});}
  replaceChildren(...els){this.children=[];this.append(...els);}
  addEventListener(name,fn){this.listeners[name]=fn;}
  getBoundingClientRect(){return {width:300,height:250};}
 }
 const box=new Element('div');box.dataset={rrAdsSite:'test-site',rrAdsSpot:'sidebar'};
 const doc={visibilityState:'visible',readyState:'complete',listeners:{},createElement:t=>new Element(t),querySelectorAll:()=>[box],addEventListener(name,fn){this.listeners[name]=fn;}};
 const ad={status:serveStatus,delivery:'00000000-0000-4000-8000-000000000001',token:'a'.repeat(64),destination:'https://example.test/go',desktop:'https://example.test/d.png',mobile:'https://example.test/m.png',alt:'Test ad',newTab:false,width:300,height:250};
 const win={listeners:{},addEventListener(name,fn){this.listeners[name]=fn;},location:{assign(){}},open(){throw Error('Unexpected popup');}};
 const context={window:win,document:doc,URL,URLSearchParams,AbortController,console,
 setTimeout(fn,ms){const id=++timerId;timers.set(id,{fn,ms});return id;},clearTimeout:id=>timers.delete(id),
 getComputedStyle:()=>({display:'block',visibility:'visible',opacity:'1'}),
 fetch:async(url,options)=>{requests.push({url,options});return {ok:true,json:async()=>url.endsWith('/serve.cfm')?ad:{status:'recorded'}};}};
 context.IntersectionObserver=class {constructor(fn){this.fn=fn;observer=this;}observe(el){observed.push(el);}unobserve(){} };win.IntersectionObserver=context.IntersectionObserver;
 vm.runInNewContext(script,context);
 const flush=async()=>{for(let i=0;i<12;i++)await Promise.resolve();};
 return {box,doc,win,requests,timers,observed,context,flush,enter(ratio=1){observer.fn(observed.map(target=>({target,isIntersecting:ratio>0,intersectionRatio:ratio})));},async tick(){for(const [id,t]of [...timers])if(t.ms===1000){timers.delete(id);await t.fn();}await flush();}};
}
{
 const h=harness();await h.flush();assert.equal(h.box.dataset.rrAdsStatus,'served');assert.equal(h.requests.length,1);
 assert.equal(h.requests[0].options.credentials,'omit');assert.match(h.requests[0].url,/^https:\/\/ads\.roadrunners\.run\//);
 h.enter(.49);await h.tick();assert.equal(h.requests.length,1,'Below half visible must not count');
 h.enter(.8);h.doc.visibilityState='hidden';h.doc.listeners.visibilitychange();await h.tick();assert.equal(h.requests.length,1,'Hidden tab cancels impression');
 h.doc.visibilityState='visible';h.doc.listeners.visibilitychange();await h.tick();assert.equal(h.requests.length,2);assert.match(h.requests[1].url,/viewable/);
 h.enter(1);await h.tick();assert.equal(h.requests.length,2,'One impression per receipt');
 h.win.RoadRunnersAds.scan();vm.runInNewContext(script,h.context);await h.flush();assert.equal(h.requests.length,2,'Duplicate scripts and scans must not serve again');
 const link=h.observed[0];await link.listeners.click({isTrusted:false,type:'click'});assert.equal(h.requests.length,2,'Synthetic click does not debit');
 let prevented=false;await link.listeners.click({isTrusted:true,type:'click',preventDefault(){prevented=true;}});assert.ok(prevented);assert.match(h.requests[2].url,/click/);
 h.win.listeners.pagehide();assert.equal([...h.timers.values()].filter(t=>t.ms===1000).length,0);
}
{
 const h=harness({broken:true});await h.flush();h.enter();await h.tick();assert.equal(h.requests.length,1,'Broken image must not count');
}
{
 const h=harness({serveStatus:'empty'});await h.flush();assert.equal(h.box.dataset.rrAdsStatus,'empty');assert.equal(h.box.children.length,0);assert.equal(h.observed.length,0);
}
console.log('ADS NETWORK SDK TESTS: PASSED (visibility, hidden tab, failed image, idempotent initialization, trusted click, empty inventory)');
