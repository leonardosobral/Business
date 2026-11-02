const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {JSDOM}=require('/private/tmp/rr-seo-mobile-20261030-tools/node_modules/jsdom');
const library='https://api.mapbox.com/mapbox-gl-js/v3.25.0/mapbox-gl.js';
const route='/assets/js/event-route-mapbox.min.js?v=20261008seo',location='/assets/js/event-location-mapbox.min.js?v=20261008seo';
function fixture(file,options={}){
 const root=(type)=>`<section data-event-${type}-component><div data-event-${type}-map-shell hidden></div><p data-event-${type}-loading>Loading</p><p data-event-${type}-${type==='route'?'unavailable':'error'} hidden>Unavailable</p><div data-event-${type}-toolbar hidden></div>${type==='route'?'<button data-event-route-index="0" aria-selected="true">5 km</button><button data-event-route-index="1" aria-selected="false"><span>10 km</span></button>':''}</section>`;
 const dom=new JSDOM('<!doctype html><html><head></head><body>'+root('route')+root('location')+'</body></html>',{url:'https://roadrunners.run/evento/test/',runScripts:'outside-only'}),w=dom.window,d=w.document,observers=[],requested=[],timers=[];
 Object.defineProperty(d,'readyState',{value:options.readyState||'complete',configurable:true});
 const script=d.createElement('script');script.setAttribute('data-mapbox-src',options.library||library);script.setAttribute('data-route-src',options.route||route);script.setAttribute('data-location-src',location);d.body.append(script);Object.defineProperty(d,'currentScript',{value:script});
 if(!options.noObserver)w.IntersectionObserver=class{constructor(cb,config){if(options.brokenObserver)throw Error('unsupported');this.cb=cb;this.config=config;this.disconnected=false;observers.push(this);}observe(e){this.root=e;}disconnect(){this.disconnected=true;}};
 if(options.alreadyLoaded)w.mapboxgl={};
 w.setTimeout=(fn)=>{timers.push(fn);return timers.length;};w.clearTimeout=(id)=>{timers[id-1]=null;};
 const append=d.head.appendChild.bind(d.head);d.head.appendChild=e=>{requested.push(e);return append(e);};
 const source=fs.readFileSync(path.join(__dirname,'candidate/assets/js',file),'utf8');w.eval(source);
 return {w,d,dom,observers,requested,timers,source,root:type=>d.querySelector(`[data-event-${type}-component]`),intersect(type,visible=true){const o=observers.find(x=>x.root===this.root(type));o.cb([{target:o.root,isIntersecting:visible}]);},async flush(){for(let i=0;i<8;i++)await Promise.resolve();},complete(node,failed=false){if(failed)node.onerror();else{if(node.src===library)w.mapboxgl={};if(node.src.includes('event-route-mapbox.min.js')){this.root('route').querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{this.root('route').querySelectorAll('button').forEach(a=>a.setAttribute('aria-selected',String(a===b)));}));}node.onload();}}};
}
for(const file of ['event-maps-lazy.js','event-maps-lazy.min.js']){
 test(file+' defers offscreen maps and shares one library between independent sections',async t=>{
  const f=fixture(file);t.after(()=>f.dom.window.close());assert.equal(f.requested.length,0);assert.equal(f.observers.length,2);assert.equal(f.root('route').querySelector('[data-event-route-map-shell]').hidden,false);
  f.intersect('route',false);await f.flush();assert.equal(f.requested.length,0);
  f.intersect('route');await f.flush();assert.equal(f.requested.length,1);assert.equal(f.requested[0].src,library);assert.equal(f.observers[0].disconnected,true);
  f.complete(f.requested[0]);await f.flush();assert.equal(f.requested.length,2);assert.ok(f.requested[1].src.endsWith(route));f.complete(f.requested[1]);await f.flush();assert.equal(f.root('route').getAttribute('data-event-map-load'),'loaded');assert.equal(f.root('location').getAttribute('data-event-map-load'),'waiting');
  f.intersect('location');await f.flush();assert.equal(f.requested.length,3);assert.ok(f.requested[2].src.endsWith(location));f.complete(f.requested[2]);await f.flush();assert.equal(f.root('location').getAttribute('data-event-map-load'),'loaded');f.intersect('route');assert.equal(f.requested.length,3);
 });
 test(file+' preserves the last route selected while downloads are pending',async t=>{
  const f=fixture(file);t.after(()=>f.dom.window.close());const tab=f.root('route').querySelectorAll('button')[1];tab.querySelector('span').click();await f.flush();assert.equal(f.requested.length,1);f.complete(f.requested[0]);await f.flush();f.complete(f.requested[1]);await f.flush();assert.equal(tab.getAttribute('aria-selected'),'true');assert.equal(f.root('route').querySelector('button').getAttribute('aria-selected'),'false');
 });
 test(file+' keyboard focus loads a section and duplicate focus never duplicates a request',async t=>{
  const f=fixture(file);t.after(()=>f.dom.window.close());f.root('route').querySelector('button').focus();f.root('route').dispatchEvent(new f.w.Event('focusin',{bubbles:true}));await f.flush();assert.equal(f.requested.length,1);assert.equal(f.root('route').getAttribute('data-event-map-load'),'loading');
 });
 test(file+' older browsers and a failed observer retain the original widgets',async t=>{
  for(const opt of [{noObserver:true},{brokenObserver:true}]){const f=fixture(file,opt);t.after(()=>f.dom.window.close());await f.flush();assert.equal(f.requested.length,1);f.complete(f.requested[0]);await f.flush();assert.equal(f.requested.length,3);assert.equal(new Set(f.requested.map(x=>x.src)).size,3);}
 });
 test(file+' library failure still loads native widget fallbacks; module failure shows the existing error',async t=>{
  const f=fixture(file);t.after(()=>f.dom.window.close());f.intersect('location');await f.flush();f.complete(f.requested[0],true);await f.flush();assert.ok(f.requested[1].src.endsWith(location));f.complete(f.requested[1],true);await f.flush();assert.equal(f.root('location').getAttribute('data-event-map-load'),'error');assert.equal(f.root('location').querySelector('[data-event-location-error]').hidden,false);assert.equal(f.root('location').querySelector('[data-event-location-loading]').hidden,true);
 });
 test(file+' timeout falls back and untrusted remote scripts are never requested',async t=>{
  const f=fixture(file,{library:'https://example.invalid/mapbox.js',route:'https://example.invalid/event-route-mapbox.min.js'});t.after(()=>f.dom.window.close());f.intersect('route');await f.flush();assert.equal(f.requested.length,0);assert.equal(f.root('route').getAttribute('data-event-map-load'),'error');assert.equal(f.root('route').querySelector('[data-event-route-unavailable]').hidden,false);
  const g=fixture(file);t.after(()=>g.dom.window.close());g.intersect('location');await g.flush();g.timers[0]();await g.flush();assert.equal(g.requested.length,2);assert.ok(g.requested[1].src.endsWith(location));
 });
 test(file+' honors DOM readiness, an existing library, and duplicate bootstrap protection',async t=>{
  const f=fixture(file,{readyState:'loading',alreadyLoaded:true});t.after(()=>f.dom.window.close());assert.equal(f.observers.length,0);f.d.dispatchEvent(new f.w.Event('DOMContentLoaded'));await f.flush();assert.equal(f.observers.length,2);f.w.eval(f.source);assert.equal(f.observers.length,2);f.intersect('route');await f.flush();assert.equal(f.requested.length,1);assert.ok(f.requested[0].src.endsWith(route));
 });
}
