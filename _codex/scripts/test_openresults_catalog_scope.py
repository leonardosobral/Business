from pathlib import Path
import json,subprocess,shlex,re
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/openresults-catalog-recovery-20261004'
files={}
for mode in ['baseline','candidate']:
 s=(STAGE/mode/'includes/backend.cfm').read_text()
 stubs={
 'qEventosBase':'''<cfset qEventosBase=queryNew("id_evento,cidade,tipo_corrida,cupom,pais,estado","integer,varchar,varchar,varchar,varchar,varchar",[{id_evento=1,cidade='Fixture',tipo_corrida='rua',cupom='',pais='BR',estado='RJ'}])/><cfset qEventosResult={executionTime=0,cached=true}/>''',
 'qPowerUps':'<cfset qPowerUps=queryNew("id_powerup")/>',
 'qBadges':'<cfset qBadges=queryNew("badge")/>',
 'qStatsAll':'<cfset qStatsAll=queryNew("percurso,sexo,rp,rp_pace,avg_pace,avg_tempo,concluintes,eventos")/>'}
 for name,stub in stubs.items():
  s,n=re.subn(r'<cfquery\s+name="'+name+r'"[^>]*>.*?</cfquery>',lambda m:stub,s,count=1,flags=re.S|re.I);assert n==1,(name,n)
 files[mode+'.cfm']=s
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/opt/ColdFusion/cfusion/wwwroot')").replace("dir=root/'_codex'","dir=root").replace('https://business.roadrunners.run/_codex/','http://127.0.0.1:8500/')
source=source.replace('result=json.loads(p.stdout)',"\n  try:result=json.loads(p.stdout)\n  except Exception:raise RuntimeError('TEST RESPONSE: '+__import__('re').sub('<[^>]+>', ' ', p.stdout)[:3500]+p.stderr)")
remote=r'''
payload=json.load(sys.stdin)
with tempfile.TemporaryDirectory(prefix='or-catalog-test-',dir='/var/tmp') as tmp:
 p=Path(tmp);os.chmod(p,0o755)
 for name,s in payload.items():(p/name).write_text(s)
 body='''+'"""'+'''
 report={checks=[]};URL={badges='',rua=true,trail=true,cupom=false,nacional=true,internacional=true,tag='rj'};
 for(mode in ['baseline','candidate']) {
  for(route in ['/resultados/','/evento/','/busca/','/404/','/','/estado/']) {
   for(key in ['qEventosBase','qEventos','qEventosResult','qStatsAll','qStatsCards','qStatsCharts'])structDelete(VARIABLES,key);
   VARIABLES.template=route;
   testTemplate='TEMPDIR/' & mode & '.cfm';include testTemplate;
   observed=structKeyExists(VARIABLES,'qEventosBase');expected=listFind('/,/estado/',route)>0;
   arrayAppend(report.checks,{mode=mode,route=route,catalogLoaded=observed,expected=expected,passed=observed==expected});
  }
 }
 '''+'"""'+'''.replace('TEMPDIR',os.path.relpath(p,Path('/opt/ColdFusion/cfusion/wwwroot/fixture')))
 result=bridge(Path('/opt/ColdFusion/cfusion/wwwroot'),body)
 checks=result['CHECKS'];assert sum(not r['PASSED'] for r in checks if r['MODE']=='baseline')==4,checks
 assert all(r['PASSED'] for r in checks if r['MODE']=='candidate'),checks
 print(json.dumps(result))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source+remote)],input=json.dumps(files),capture_output=True,text=True,timeout=110)
print(p.stdout);print(p.stderr[-3500:]);(STAGE/'test-scope.json').write_text(p.stdout);raise SystemExit(p.returncode)
