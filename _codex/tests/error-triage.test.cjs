const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
function fixture(count){
 const nodes=Array.from({length:count},()=>({checked:true,disabled:false}));const listeners={};const feedback={textContent:''};let submitted=false;
 const form={querySelectorAll:()=>nodes,querySelector:()=>feedback,addEventListener:(k,fn)=>listeners[k]=fn,setAttribute(){}};
 vm.runInNewContext(fs.readFileSync('portal/erros/assets/triage.js','utf8'),{document:{querySelectorAll:selector=>selector==='[data-triage-export]'?[form]:[]},window:{addEventListener(){}},});
 return {submit(){const e={preventDefault(){this.prevented=true;}};listeners.submit(e);submitted=!e.prevented;return submitted;},feedback,nodes};
}
test('export rejects empty selection and more than 20 without losing selection',()=>{for(const count of [0,21]){const f=fixture(count);assert.equal(f.submit(),false);assert.ok(f.feedback.textContent.length);assert.equal(f.nodes.filter(n=>n.checked).length,count);}});
test('valid export stays usable for a second download',()=>{const f=fixture(2);assert.equal(f.submit(),true);assert.equal(f.submit(),true);});
test('write forms prevent duplicate submission without dropping the action',()=>{
 const listeners={},pages={},button={disabled:false};
 const form={dataset:{},addEventListener:(k,fn)=>listeners[k]=fn,querySelectorAll:()=>[button]};
 vm.runInNewContext(fs.readFileSync('portal/erros/assets/triage.js','utf8'),{document:{querySelectorAll:selector=>selector==='[data-triage-write]'?[form]:[]},window:{addEventListener:(k,fn)=>pages[k]=fn}});
 const event=()=>({preventDefault(){this.prevented=true;}});let a=event();listeners.submit(a);assert.notEqual(a.prevented,true);assert.equal(button.disabled,false);let b=event();listeners.submit(b);assert.equal(b.prevented,true);pages.pageshow();let c=event();listeners.submit(c);assert.notEqual(c.prevented,true);
});
test('treatment requires fields for each status without changing the entered publication time',()=>{
 const listeners={},status={value:'published',addEventListener:(k,fn)=>listeners[k]=fn};
 const fields={evidence:{},published_at:{value:'2026-09-28T14:00:00'},reason:{}};
 const markers={evidence:{},published_at:{},reason:{}},summary={textContent:''};
 const form={querySelector(selector){if(selector==='[name="status"]')return status;if(selector==='[data-triage-required-summary]')return summary;let match=selector.match(/^\[name="(.+)"\]$/);return match?fields[match[1]]:markers[selector.match(/^\[data-triage-required="(.+)"\]$/)[1]];}};
 vm.runInNewContext(fs.readFileSync('portal/erros/assets/triage.js','utf8'),{document:{querySelectorAll:s=>s==='[data-triage-treatment]'?[form]:[]},window:{addEventListener(){}}});
 assert.equal(fields.evidence.required,true);assert.equal(fields.published_at.required,true);assert.equal(fields.reason.required,false);
 status.value='verified';listeners.change();assert.equal(fields.evidence.required,true);assert.equal(fields.published_at.required,false);
 for(const value of ['ignored','reopened']){status.value=value;listeners.change();assert.equal(fields.reason.required,true);assert.equal(fields.evidence.required,false);assert.equal(markers.reason.hidden,false);}
 status.value='new';listeners.change();assert.equal(fields.reason.required,false);assert.equal(markers.reason.hidden,true);assert.equal(fields.published_at.value,'2026-09-28T14:00:00');
});
