from pathlib import Path
import json,re,shlex,subprocess
stage=Path(__file__).resolve().parent
src=stage/'candidate'
backend=Path('/Users/Shared/Projects/RunnerHub/RoadRunners/includes/backend/backend.cfm').read_text()
base=re.search(r'<cfquery name="qEventosBase"[\s\S]*?</cfquery>',backend).group()
page=(src/'estado/index.cfm').read_text()
start=page.index('            <div class="estado-page-hero-header">')
end=page.index('        <!--- LISTAGEM DE EVENTOS --->',start)
hero=page[start:end].rsplit('</div>',1)[0]
count=(src/'includes/backend/backend_estado_cidades.cfm').read_text()
sa=page.index('                   <div class="home-side-block p-3 estado-city-list-card"')
sb=page.index('               <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"',sa)
sidebar=page[sa:sb]
fixture='''<cfsetting showdebugoutput="false"/><cfscript>
VARIABLES.template="/estado/";
URL={tag="BA",cidade="",tempo="0,12",distancia="1,42",badges="",rua=true,trail=true,nacional=true,internacional=false,cupom=false};
REQUEST.t=function(key){return "Selecione um estado";};
function getEstadoNome(uf){if(uf=="BA")return "Bahia";if(uf=="SC")return "Santa Catarina";return uf;}
VARIABLES.estadoHeroStateOptions="BA,SC";
VARIABLES.estadoHeroUfSelecionada="BA";VARIABLES.estadoHeroTituloUf="BA";
VARIABLES.estadoHeroStatePrepositions={"BA"="na","SC"="em"};
VARIABLES.estadoRootPath="/estado/ba/";VARIABLES.estadoFilterSuffix="";
</cfscript>'''+base+count+'<cfsavecontent variable="cityHeroHtml">'+hero+'</cfsavecontent><cfscript>report={"html"=cityHeroHtml,"initial"=VARIABLES.estadoCitiesData};URL.tempo="0,1";</cfscript>'+count+'<cfscript>report["filtered"]=VARIABLES.estadoCitiesData;URL.tempo="30,31";</cfscript>'+count+'<cfsavecontent variable="citySidebarZero">'+sidebar+'</cfsavecontent><cfscript>if(!find("data-estado-city-sidebar",citySidebarZero))throw(message="Empty calendar must retain sidebar for later filter updates");report["empty_sidebar_preserved"]=true;report["empty_sidebar_html"]=citySidebarZero;writeOutput(serializeJSON(report));</cfscript>'
helpers=(Path('/Users/Shared/Projects/RunnerHub/Business/_codex/scripts/deploy_estudo.py')).read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace("(work/'run.cfm').write_text", "(work/'fixture.cfm').write_text(payload['fixture'])\n  (work/'run.cfm').write_text")
remote=helpers+'''\npayload=json.load(sys.stdin)
r=bridge(Path('/var/www/business.roadrunners.run'),'savecontent variable="fixtureOutput" { include "fixture.cfm"; } report=deserializeJSON(fixtureOutput);')
print(json.dumps(r))'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'fixture':fixture}),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
def lowercase_keys(v):
 if isinstance(v,dict):return {k.lower():lowercase_keys(val) for k,val in v.items()}
 if isinstance(v,list):return [lowercase_keys(val) for val in v]
 return v
r=lowercase_keys(r)
(stage/'preview-data.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
css=(src/'assets/css/runnerhub-estado-cidades.css').read_text()
js=(src/'assets/js/runnerhub-estado-cidades.js').read_text()
html='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Verificação do filtro de cidades</title><style>body{font-family:Arial,sans-serif;color:#333;background:#f5f5f5;margin:0}.container{max-width:1200px;margin:40px auto;padding:16px}.estado-page-hero-header{display:flex;align-items:center;justify-content:space-between;gap:12px}.page-section-hero-title{font-size:26px;display:flex;gap:8px;align-items:center;min-width:0}.page-section-hero-icon{width:26px;height:26px}.home-hero-chip-select{border:1px solid #ddd;background:#fff;padding:12px;border-radius:24px;font-size:14px;max-width:100%}.home-hero-chip-select-wrap{display:flex}button{padding:12px;border:1px solid #ddd;border-radius:8px;margin-top:32px;background:#fff}@media(max-width:767px){.estado-page-hero-header{flex-direction:column;align-items:stretch}}</style><style>'''+css+'</style><body><div class="container">'+r['html']+r['empty_sidebar_html']+'<button id="test-period">Verificar contagens: próximos 30 dias</button><p id="test-period-result"></p></div><script>'+js+'</script><script>window.RunnerHubEstadoCities.init(document,"BA","");const nextCounts='+json.dumps(r['filtered'],ensure_ascii=False)+';const oldCounts='+json.dumps(r['initial'],ensure_ascii=False)+''';document.querySelector('#test-period').addEventListener('click',function(){history.replaceState(null,'','?tempo=0%2C1');window.RunnerHubEstadoCities.update(nextCounts);window.RunnerHubEstadoCities.update(oldCounts);document.querySelector('#test-period-result').textContent='Período atualizado: '+nextCounts.total+' provas';});</script></body></html>'''
(stage/'preview.html').write_text(html)
print(json.dumps({'cities':len(r['initial']['cities']),'events_default':r['initial']['total'],'events_30_days':r['filtered']['total']},ensure_ascii=False))
