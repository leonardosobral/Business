import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
const tasks=[];let checks=0, prevented=false;
const form={listeners:[],addEventListener(name,fn){this.listeners.push(fn);}};
const makePicker=kind=>{
 const input={value:'',listeners:{},validity:'',setCustomValidity(v){this.validity=v;},reportValidity(){},addEventListener(n,f){this.listeners[n]=f;},closest(){return form;}};
 const id={value:''},options={options:[],replaceChildren(...rows){this.options=rows;}},status={textContent:''};
 const map={'[data-picker-input]':input,'[data-picker-id]':id,'[data-picker-options]':options,'[data-picker-status]':status};
 return {dataset:{namePicker:kind},querySelector:s=>map[s],input,id,options,status};
};
const page=makePicker('page'),user=makePicker('user');
vm.runInNewContext(fs.readFileSync(new URL('../../../portal/canais/assets/manager.js',import.meta.url),'utf8'),{
 document:{querySelectorAll:()=>[page,user],querySelector:()=>null,createElement:()=>({value:'',dataset:{}})},Map,Array,Number,String,URLSearchParams,AbortController,
 setTimeout:fn=>{tasks.push(fn);return tasks.length;},clearTimeout:()=>{},fetch:async url=>{
  assert.match(url,/lookup=page/);assert.match(url,/q=RunTV/);checks+=2;
  return {ok:true,headers:{get:()=> 'application/json'},json:async()=>({items:[{id:37,label:'RunTV · /canal/runtv/',owner_id:50,owner_label:'Autor · autor@example.test'}]})};
 }
});
page.input.value='RunTV';page.input.listeners.input();await tasks.shift()();
assert.equal(page.options.options.length,1);checks++;
page.input.value=page.options.options[0].value;page.input.listeners.input();
assert.equal(page.id.value,'37');assert.equal(user.id.value,'50');assert.equal(user.input.value,'Autor · autor@example.test');checks+=3;
page.input.value='Outro nome';page.input.listeners.input();assert.equal(page.id.value,'');checks++;
for(const listener of form.listeners)listener({preventDefault(){prevented=true;}});
assert.equal(prevented,true);assert.match(page.input.validity,/Escolha um resultado/);checks+=2;
page.input.value='';page.input.listeners.input();assert.equal(page.options.options.length,0);assert.equal(page.id.value,'');checks+=2;
console.log('YOUTUBE_PICKERS_PASSED '+checks);
