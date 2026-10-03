const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const runtime=process.env.RR_MEMBERS_RUNTIME||path.resolve(__dirname,'../../../RoadRunners');
const pager=require(process.env.RR_MEMBERS_PAGER||path.join(runtime,'assets/js/runnerhub-chat-members-pager.js'));
const row=id=>({id_usuario:id,nome:'Member <'+id+'>',papel:'member',status:'active',tag:'member'+id});
function harness(fetchPage,mode='chat'){
  const listeners={},requests=[];let gid=42,observer,focused='';
  const opener={isConnected:true,focus:()=>focused='opener'},first={offsetParent:{},focus:()=>focused='first'},last={offsetParent:{},focus:()=>focused='last'};
  const list={dataset:{memberMode:mode,profilePathTemplate:'/atleta/{tag}/',labelEmpty:'Empty',labelLoading:'Loading',labelLoaded:'{count} members',labelOther:'e outros {count} membros',labelMore:'More',labelRetry:'Retry',labelPromote:'Promote',labelRemove:'Remove'},innerHTML:'',isConnected:true,setAttribute(){},insertAdjacentHTML(_,html){this.innerHTML+=html;}};
  const status={textContent:''},button={hidden:false,disabled:false,textContent:''},footer={hidden:false,querySelector:q=>q==='[data-group-members-status]'?status:button,classList:{toggle(){}}};
  const dialog={scrollHeight:1000,clientHeight:300,scrollTop:0};
  const memberModal={hidden:true,querySelectorAll:()=>[first,last],querySelector:q=>({'[data-group-members]':list,'[data-group-members-scroll]':dialog,'[data-group-members-footer]':footer}[q]||first)};
  const shell={dataset:{},querySelector:()=>({dataset:{groupId:gid}})};
  const doc={activeElement:opener,body:{classList:{add(){},remove(){}}},querySelector:q=>q==='[data-chat-shell]'?shell:(q==='[data-group-modal="members"]'?memberModal:null),querySelectorAll:q=>q==='[data-group-modal]'?[memberModal]:[],addEventListener:(name,fn)=>(listeners[name]??=[]).push(fn),createElement:()=>{let text='';return {set textContent(v){text=v;},get innerHTML(){return text.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');}};}};
  const context={document:doc,window:{RRGroupMemberPager:pager,setTimeout,clearTimeout},AbortController,CustomEvent:function(){},alert(){},location:{},fetch:async(url,options)=>{requests.push({url,options});return {ok:true,json:()=>fetchPage(url,options,requests.length)};},IntersectionObserver:class {constructor(fn,options){observer={fn,options,disconnected:false};}observe(target){observer.target=target;}disconnect(){observer.disconnected=true;}}};
  vm.runInNewContext(fs.readFileSync(path.join(runtime,'assets/js/runnerhub-chat-groups.js'),'utf8'),context);
  async function click(selector,dataset={}){const target={dataset,closest:q=>q===selector?target:null};await Promise.all((listeners.click||[]).map(fn=>fn({target,preventDefault(){}})));await new Promise(setImmediate);}
  return {requests,list,status,button,dialog,memberModal,click,observer:()=>observer,setGroup:id=>gid=id,focus:()=>focused,key:(key,shiftKey=false)=>{doc.activeElement=shiftKey?first:last;listeners.keydown.forEach(fn=>fn({key,shiftKey,preventDefault(){}}));},scroll:async()=>{observer.fn([{isIntersecting:true}]);await new Promise(setImmediate);}};
}
test('real modal uses bounded requests, appends on intersection and keeps profile links and safe names',async()=>{
  const h=harness((url,_,n)=>({success:true,can_manage:'false',items:[row(n)],has_more:n===1,next_cursor:n===1?'next':''}));
  await h.click('[data-group-modal-open]',{groupModalOpen:'members'});
  assert.match(h.requests[0].url,/limit=30/);assert.equal(h.requests.length,1);
  assert.equal(h.observer().options.root,h.dialog);assert.match(h.list.innerHTML,/Member &lt;1&gt;/);assert.match(h.list.innerHTML,/\/atleta\/member1\//);assert.doesNotMatch(h.list.innerHTML,/data-group-member-action/);
  await h.scroll();assert.match(h.requests[1].url,/cursor=next/);assert.match(h.list.innerHTML,/Member &lt;1&gt;/);assert.match(h.list.innerHTML,/Member &lt;2&gt;/);assert.equal(h.button.hidden,true);
  await h.scroll();assert.equal(h.requests.length,2);
});
test('keyboard focus stays in the members dialog and returns to its opener on close',async()=>{
  const h=harness(()=>({success:true,items:[row(1)],has_more:false,next_cursor:''}));
  await h.click('[data-group-modal-open]',{groupModalOpen:'members'});
  h.key('Tab');assert.equal(h.focus(),'first');h.key('Tab',true);assert.equal(h.focus(),'last');
  h.key('Escape');assert.equal(h.memberModal.hidden,true);assert.equal(h.focus(),'opener');
});
test('scroll errors do not loop and the retry control recovers without removing earlier members',async()=>{
  const h=harness((_,__,n)=>{if(n===2)throw new Error('offline');return {success:true,items:[row(n)],has_more:n===1,next_cursor:n===1?'next':''};});
  await h.click('[data-group-modal-open]',{groupModalOpen:'members'});await h.scroll();assert.match(h.status.textContent,/offline/);assert.equal(h.button.textContent,'Retry');
  await h.scroll();assert.equal(h.requests.length,2);
  await h.click('[data-group-members-more]');assert.equal(h.requests.length,3);assert.match(h.list.innerHTML,/member1/);assert.match(h.list.innerHTML,/member3/);
  await h.click('[data-group-modal-close]');assert.equal(h.memberModal.hidden,true);assert.equal(h.observer().disconnected,true);
});
test('channel footer uses the server total of nonfollowed members rather than the number of loaded friends',async()=>{
  const h=harness((_,__,n)=>({success:true,can_manage:false,items:Array.from({length:n===1?30:15},(_,i)=>row(i+(n===1?1:31))),has_more:n===1,next_cursor:n===1?'next':'',other_members:55}),'channel');
  await h.click('[data-group-modal-open]',{groupModalOpen:'members'});
  assert.equal(h.status.textContent,'e outros 55 membros');
  await h.scroll();assert.equal(h.status.textContent,'e outros 55 membros');
  assert.equal((h.list.innerHTML.match(/class="rr-group-member"/g)||[]).length,45);
});
test('empty channel still displays the aggregate other count and the private empty message',async()=>{
  const h=harness(()=>({success:true,items:[],has_more:false,next_cursor:'',other_members:65}),'channel');
  await h.click('[data-group-modal-open]',{groupModalOpen:'members'});
  assert.equal(h.status.textContent,'e outros 65 membros');assert.match(h.list.innerHTML,/Empty/);
});
test('group footer keeps the loaded count and ignores channel aggregate metadata',async()=>{
  const h=harness(()=>({success:true,items:[row(1),row(2)],has_more:false,next_cursor:'',other_members:65}));
  await h.click('[data-group-modal-open]',{groupModalOpen:'members'});assert.equal(h.status.textContent,'2 members');
});
