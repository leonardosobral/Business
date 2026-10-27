const {test}=require('node:test'),assert=require('node:assert/strict'),path=require('node:path'),fs=require('node:fs'),vm=require('node:vm');
const root=process.env.RR_REGION_SOURCE_ROOT||path.join(__dirname,'candidate');
for(const filename of ['runnerhub-regional-period.js','runnerhub-regional-period.min.js']){
 const p=require(path.join(root,'assets/js',filename));
 test(filename+' preset preserves live filters and resets pagination/legacy dates',()=>{
  const href=p.preset('https://roadrunners.run/estado/pr/curitiba/?pagina=3&cupom=true&distancia=10%2C21&tempo=0%2C3&trail=false','/estado/pr/curitiba/?periodo_inicio=2026-11-01&periodo_fim=2026-11-30');
  const u=new URL(href,'https://roadrunners.run');assert.equal(u.pathname,'/estado/pr/curitiba/');
  for(const [key,value]of Object.entries({cupom:'true',distancia:'10,21',trail:'false',periodo_inicio:'2026-11-01',periodo_fim:'2026-11-30'}))assert.equal(u.searchParams.get(key),value);
  assert.equal(u.searchParams.has('pagina'),false);assert.equal(u.searchParams.has('tempo'),false);
 });
 test(filename+' preset removes stale filters after user clears them',()=>{
  const u=new URL(p.preset('https://roadrunners.run/estado/pr/','/estado/pr/?cupom=true&badges=pcd&periodo_inicio=2026-11-01&periodo_fim=2026-11-30'),'https://roadrunners.run');assert.equal(u.searchParams.has('cupom'),false);assert.equal(u.searchParams.has('badges'),false);
 });
}
for(const filename of ['runnerhub-estado-cidades.js','runnerhub-estado-cidades.min.js']){
 const ctx={window:{},URL,console};vm.runInNewContext(fs.readFileSync(path.join(root,'assets/js',filename),'utf8'),ctx);const c=ctx.window.RunnerHubEstadoCities;
 test(filename+' city retains exact dates and drops pagination',()=>{
  const u=new URL(c.buildUrl('https://roadrunners.run/estado/pr/?pagina=3&periodo_inicio=2026-11-01&periodo_fim=2026-11-30&cupom=true','PR','curitiba'),'https://roadrunners.run');assert.equal(u.searchParams.get('periodo_inicio'),'2026-11-01');assert.equal(u.searchParams.get('periodo_fim'),'2026-11-30');assert.equal(u.searchParams.get('cupom'),'true');assert.equal(u.searchParams.has('pagina'),false);
 });
 test(filename+' city rejects stale counts from another period',()=>{
  const f={distancia:'1,42',tempo:'0,12',rua:true,trail:true,nacional:true,internacional:false,cupom:false,badges:'',periodo_inicio:'2026-11-01',periodo_fim:'2026-11-30'};
  assert.ok(c.acceptsFilters('https://roadrunners.run/estado/pr/?periodo_inicio=2026-11-01&periodo_fim=2026-11-30',f));assert.equal(c.acceptsFilters('https://roadrunners.run/estado/pr/?periodo_inicio=2026-12-01&periodo_fim=2026-12-31',f),false);
 });
}
