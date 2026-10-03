const test=require('node:test');
const assert=require('node:assert/strict');
const path=require('node:path');
const runtime=process.env.RR_MEMBERS_PAGER || path.resolve(__dirname,'../../../RoadRunners/assets/js/runnerhub-chat-members-pager.js');
let createPager;try{createPager=require(runtime).createPager;}catch(_){}
function pager(options){assert.equal(typeof createPager,'function','progressive members controller is missing');return createPager(options);}
const item=id=>({id_usuario:id,nome:'Athlete '+id,papel:'member',status:'active'});
function page(ids,more=false,cursor=''){return {success:true,items:ids.map(item),has_more:more,next_cursor:cursor,can_manage:false};}
test('opening fetches only one bounded page, later pages append without replacing earlier members',async()=>{
  const calls=[],rendered=[];
  const p=pager({fetchPage:async request=>{calls.push(request);return calls.length===1?page([1,2],true,'page2'):page([3]);},onPage:items=>rendered.push(...items)});
  await p.start(42);assert.equal(calls.length,1);assert.equal(calls[0].limit,30);
  assert.deepEqual(rendered.map(x=>x.id_usuario),[1,2]);
  await p.loadMore();assert.equal(calls[1].cursor,'page2');assert.deepEqual(rendered.map(x=>x.id_usuario),[1,2,3]);
  await p.loadMore();assert.equal(calls.length,2,'the final page cannot trigger endless requests');
});
test('overlapping scroll events cannot fetch the same page twice',async()=>{
  let resolve,requests=0;
  const p=pager({fetchPage:()=>{requests++;return new Promise(r=>resolve=r);}});
  const pending=p.start(42);await p.loadMore();await p.loadMore();assert.equal(requests,1);
  resolve(page([1]));await pending;assert.equal(p.snapshot().loaded,1);
});
test('closing ignores a late response and cancels transport',async()=>{
  let resolve,request;const rendered=[];
  const p=pager({fetchPage:q=>{request=q;return new Promise(r=>resolve=r);},onPage:rows=>rendered.push(...rows)});
  const pending=p.start(42);p.close();assert.equal(request.signal.aborted,true);
  resolve(page([1]));await pending;assert.equal(rendered.length,0);
});
test('switching groups cannot append the previous group response to the new modal',async()=>{
  const resolvers=[],rendered=[];
  const p=pager({fetchPage:q=>new Promise(r=>resolvers.push({q,r})),onReset:()=>rendered.splice(0),onPage:rows=>rendered.push(...rows)});
  const first=p.start(42),second=p.start(43);
  resolvers[1].r(page([2]));await second;resolvers[0].r(page([1]));await first;
  assert.deepEqual(rendered.map(x=>x.id_usuario),[2]);assert.equal(p.snapshot().groupId,43);
});
test('a failed next page preserves members and can be retried at the same cursor',async()=>{
  const rendered=[],calls=[];let failures=1;
  const p=pager({fetchPage:async q=>{calls.push(q);if(!q.cursor)return page([1],true,'next');if(failures--)throw new Error('Network offline');return page([2]);},onPage:rows=>rendered.push(...rows)});
  await p.start(42);await p.loadMore();assert.equal(p.snapshot().error,'Network offline');assert.deepEqual(rendered.map(x=>x.id_usuario),[1]);
  await p.loadMore();assert.equal(calls[2].cursor,'next');assert.deepEqual(rendered.map(x=>x.id_usuario),[1,2]);
});
test('duplicate members from concurrent roster changes are never shown twice',async()=>{
  let n=0;const rendered=[];
  const p=pager({fetchPage:async()=>++n===1?page([1,2],true,'next'):page([2,3]),onPage:rows=>rendered.push(...rows)});
  await p.start(42);await p.loadMore();assert.deepEqual(rendered.map(x=>x.id_usuario),[1,2,3]);
});
test('a nonadvancing cursor reports an error instead of an infinite download loop',async()=>{
  let n=0;const p=pager({fetchPage:async()=>++n===1?page([1],true,'same'):page([2],true,'same')});
  await p.start(42);await p.loadMore();assert.ok(p.snapshot().error);assert.equal(p.snapshot().loaded,1);
});
test('empty community terminates without additional requests',async()=>{
  let n=0;const p=pager({fetchPage:async()=>{n++;return page([]);}});
  await p.start(42);await p.loadMore();assert.equal(n,1);assert.equal(p.snapshot().loaded,0);assert.equal(p.snapshot().hasMore,false);
});
