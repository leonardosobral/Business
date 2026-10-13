const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').resolve(__dirname, '../../administracao/vicky/assets/audit.js'), 'utf8');

// DOMParser/fetch are the unavailable external browser boundary; run the actual UI handler.
function setup({last=false,fail=false}={}) {
  const document = {activeElement:null, importNode:n=>n, createDocumentFragment:()=>({appendChild(){}}), createElement:()=>({})};
  const body={};document.activeElement=body;
  const link={href:'https://business.roadrunners.run/administracao/vicky/?usuario=1&antes=20',attrs:{},setAttribute(k,v){this.attrs[k]=v;},removeAttribute(k){delete this.attrs[k];},focus(){document.activeElement=this;}};
  const next={focus(){document.activeElement=this;}};
  const status={textContent:'',setAttribute(){},focus(){document.activeElement=this;}};
  const scroll={scrollHeight:600,scrollTop:100};
  const turns={dataset:{vpUserId:'1'},querySelector:()=>null,querySelectorAll:()=>[{},{}],prepend(){scroll.scrollHeight=800;}};
  let handler;
  const controls={addEventListener(_,fn){handler=fn;},replaceChildren(){document.activeElement=body;},appendChild(){}};
  const incoming={dataset:{vpUserId:'1'},querySelectorAll:()=>[{dataset:{vpTurn:'21'}}]};
  const parsed={querySelector:s=>s==='[data-vp-turns]'?incoming:{querySelector:()=>last?null:next}};
  const root={querySelector:s=>({'[data-vp-chat-scroll]':scroll,'[data-vp-turns]':turns,'[data-vp-history-controls]':controls,'[data-vp-history-status]':status}[s]||null)};
  document.querySelector=()=>root;
  const fetch=async()=>{if(fail)throw Error('offline');return {ok:true,text:async()=>'<html>older batch</html>'};};
  const DOMParser=class{parseFromString(){return parsed;}};
  vm.runInNewContext(source,{document,URL,fetch,DOMParser,window:{location:{href:link.href,origin:'https://business.roadrunners.run'},fetch,DOMParser}});
  return {document,link,next,status,scroll,click:async overrides=>{
    document.activeElement=link;const event={target:{closest:()=>link},button:0,prevented:false,preventDefault(){this.prevented=true;},...overrides};
    await handler(event);return event;
  }};
}
test('loading an older batch keeps keyboard focus on the replacement control',async()=>{
  const app=setup();await app.click();assert.equal(app.document.activeElement,app.next);assert.equal(app.scroll.scrollTop,800);
});
test('loading the final batch moves focus to its completion status',async()=>{
  const app=setup({last:true});await app.click();assert.equal(app.document.activeElement,app.status);assert.match(app.status.textContent,/1 interação/);
});
test('failed history loading leaves the link usable for retry',async()=>{
  const app=setup({fail:true});await app.click();assert.equal(app.link.attrs['aria-disabled'],undefined);assert.equal(app.document.activeElement,app.link);assert.match(app.status.textContent,/Não foi possível/);
});
test('modified clicks preserve normal open-in-new-tab navigation',async()=>{
  const app=setup();const event=await app.click({ctrlKey:true});assert.equal(event.prevented,false);
});
