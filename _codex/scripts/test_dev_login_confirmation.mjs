import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const home=fs.readFileSync(new URL('../../administracao/usuarios/home.cfm',import.meta.url),'utf8');
const script=home.match(/<script>([\s\S]*?)<\/script>/)[1];
let checks=0;
for(const accept of [false,true]) {
  let callback;let prevented=false;let confirmed={value:'0'};
  const form={
    getAttribute:()=> 'Entrar no DEV como o usuário escolhido?',
    hasAttribute:name=>name==='data-dev-login',
    elements:{namedItem:()=>confirmed},
    addEventListener:(name,fn)=>{if(name==='submit')callback=fn;}
  };
  vm.runInNewContext(script,{
    document:{addEventListener:(name,fn)=>fn(),querySelectorAll:()=>[form]},
    window:{confirm:()=>accept}
  });
  callback({preventDefault:()=>{prevented=true;}});
  assert.equal(prevented,!accept,'Cancel must prevent opening the other account');checks++;
  assert.equal(confirmed.value,accept?'1':'0','Only accepted confirmation can mark the submitted request');checks++;
}
console.log(`DEV_CONFIRMATION_PASSED:${checks}`);
