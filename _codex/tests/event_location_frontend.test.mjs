import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import test from 'node:test';
const source=readFileSync(new URL('../../eventos/assets/event-location.js',import.meta.url),'utf8');
test('country changes enable exactly the appropriate location fields and retain values',()=>{
 const listeners={};const country={value:'PT',addEventListener:(name,handler)=>{listeners[name]=handler;}};
 const brazil={hidden:false,disabled:false};const foreign={hidden:false,disabled:false};const lookup={hidden:false};const mode={value:''};
 const root={querySelector:selector=>({'[data-event-country]':country,'[data-event-br-fields]':brazil,'[data-event-foreign-fields]':foreign,'[data-event-location-mode]':mode})[selector]};
 runInNewContext(source,{document:{querySelector:()=>root,querySelectorAll:()=>[lookup]}});
 assert.equal(brazil.disabled,true);assert.equal(foreign.disabled,false);assert.equal(mode.value,'foreign');assert.equal(lookup.hidden,true);
 country.value='BR';listeners.change();assert.equal(brazil.disabled,false);assert.equal(foreign.disabled,true);assert.equal(mode.value,'br');assert.equal(lookup.hidden,false);
 country.value='PT';listeners.change();assert.equal(brazil.disabled,true);assert.equal(foreign.disabled,false);assert.equal(mode.value,'foreign');
});
