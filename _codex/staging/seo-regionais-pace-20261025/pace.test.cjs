const {test}=require('node:test'),assert=require('node:assert/strict'),path=require('node:path');
const root=process.env.PACE_SOURCE_ROOT||path.join(__dirname,'candidate');
for(const file of ['runnerhub-pace.js','runnerhub-pace.min.js']){
 const p=require(path.join(root,'assets/js',file));
 test(file+' — known running calculations',()=>{
  assert.equal(p.duration(p.calculate('pace',5,1800).pace,true),'6:00');
  assert.equal(p.duration(p.calculate('time',10,null,330).time),'00:55:00');
  assert.equal(p.calculate('distance',null,2700,360).distance,7.5);
  assert.equal(p.duration(p.calculate('time',21.0975,null,300).time),'01:45:29');
  assert.equal(p.duration(p.calculate('time',42.195,null,300).time),'03:30:59');
 });
 test(file+' — decimal and duration validation',()=>{
  assert.equal(p.decimal('21,0975'),21.0975);assert.equal(p.decimal('42.195'),42.195);
  for(const x of ['-2','1,000.2','1e2','','abc','Infinity','5km'])assert.ok(Number.isNaN(p.decimal(x)),x);
  assert.equal(p.clock('1','05','09',false),3909);
  for(const args of [[0,60,0,false],[0,5,60,true],[1,5,0,true],[0,-1,0,true],[0,'',0,false]])assert.ok(Number.isNaN(p.clock(...args)));
  assert.equal(p.duration(3599.5),'01:00:00');assert.equal(p.duration(359.5,true),'6:00');assert.equal(p.duration(90000),'25:00:00');
 });
 test(file+' — rejects invalid, zero and extreme calculations',()=>{
  for(const args of [['pace',0,1800],['pace',5,0],['time',NaN,null,300],['distance',null,Infinity,300],['time',1001,null,300],['bad',5,1800,300],['time',5,null,0]])assert.throws(()=>p.calculate(...args));
 });
 test(file+' — splits preserve exact finish without duplicate finish',()=>{
  for(const d of [0.5,5,7.5,21.0975,42.195,1000]){
   const r=p.calculate('time',d,null,333.3333),s=p.splits(r);assert.ok(s.rows.length<=101);
   assert.deepEqual(s.rows.at(-1),{distance:d,time:r.time});assert.equal(new Set(s.rows.map(x=>x.distance)).size,s.rows.length);
   s.rows.slice(0,-1).forEach(x=>assert.equal(x.time,x.distance*r.pace));
  }
 });
 test(file+' — calendar preserves selected state and actual catalog categories',()=>{
  for(const [d,low,high] of [[5,5,5],[10,10,10],[21.0975,21,21],[42.195,42,42],[7.5,7,8]]){
   const c=p.calendar(p.calculate('time',d,null,300),'pr'),u=new URL(c.href,'https://roadrunners.run');
   assert.equal(u.pathname,'/busca/');assert.equal(u.searchParams.get('estado'),'PR');assert.equal(u.searchParams.get('context_uf'),'PR');assert.equal(u.searchParams.get('distancia_inicio'),String(low));assert.equal(u.searchParams.get('distancia_fim'),String(high));assert.equal(u.searchParams.get('busca_mode'),'plain');assert.equal(u.searchParams.has('pace'),false);
  }
  const national=new URL(p.calendar(p.calculate('time',5,null,300),'XX').href,'https://roadrunners.run');assert.equal(national.searchParams.has('estado'),false);assert.equal(national.searchParams.get('context_uf'),'BR');
 });
}
