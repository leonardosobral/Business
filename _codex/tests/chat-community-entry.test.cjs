const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const runtime=process.env.RR_CHAT_RUNTIME || require('node:path').resolve(__dirname,'../../../RoadRunners/assets/js/runnerhub-chat.js');
async function enter(action,folder){
  const calls=[]; let click; let thread;
  const list={replaceWith(){}};
  const empty={querySelector(){return null;},querySelectorAll(){return [];},setAttribute(){},removeAttribute(){},replaceWith(next){thread=next;}};
  thread={...empty,dataset:{threadKind:'group',groupId:'42',folder,currentUrl:'/mensagens/'+folder+'/'}};
  const shell={dataset:{threadKind:'group',groupId:'42',folder,channelListPath:'/mensagens/canais/',groupListPath:'/mensagens/grupos/'},closest(){return null;},classList:{add(){},remove(){},toggle(){}},querySelector(selector){return selector==='[data-chat-thread]' ? thread : selector==='.rr-chat-contact-list' ? list : null;},querySelectorAll(){return [];},addEventListener(type,callback){if(type==='click')click=callback;}};
  const document={querySelector(selector){return selector==='[data-chat-shell]'?shell:null;},addEventListener(){},dispatchEvent(){}};
  const window={matchMedia(){return {matches:true};},addEventListener(){},setTimeout(){return 1;},clearTimeout(){}};
  const location={pathname:'/mensagens/'+folder+'/',search:'',href:'https://roadrunners.run/mensagens/'+folder+'/'};
  const fetch=async(url,options={})=>{calls.push({url:String(url),options});return {ok:true,json:async()=>({}),text:async()=>''};};
  const context={window,document,location,history:{state:{},replaceState(){}},fetch,URL,AbortController,CustomEvent:class{},DOMParser:class{parseFromString(){return {querySelector(selector){return selector==='[data-chat-thread]'?thread:list;}};}},setInterval(){},alert(message){throw new Error(message);}};
  vm.runInNewContext(fs.readFileSync(runtime,'utf8'),context);
  const button={dataset:{chatAction:action},isConnected:true};
  await click({button:0,preventDefault(){},target:{closest(selector){return selector==='[data-chat-action]'?button:null;}}});
  return calls.filter(call=>!call.options.method && !call.options.headers?.['X-RR-Chat-Partial']).map(call=>call.url);
}
test('joining a group refreshes the group list, not channels',async()=>{assert.deepEqual(await enter('join','groups'),['/mensagens/grupos/']);});
test('subscribing to a channel refreshes channels',async()=>{assert.deepEqual(await enter('subscribe','channels'),['/mensagens/canais/']);});
