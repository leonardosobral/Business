from pathlib import Path
import importlib.util,json
W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('release',W.parents[4]/'RoadRunners/_codex/scripts/deploy_estudo_q3.py')
# Use the same approved remote transport as the scoped deployment.
ROOT=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
spec=importlib.util.spec_from_file_location('release',ROOT/'_codex/scripts/deploy_estudo_q3.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
body=r'''
def request(host,path,method='GET'):
 p=subprocess.run(['curl','-sS','--max-time','20','--resolve',host+':443:127.0.0.1','-X',method,'-w','\n%{http_code}','https://'+host+path],capture_output=True,text=True,timeout=25)
 if p.returncode:raise RuntimeError(p.stderr)
 value,code=p.stdout.rsplit('\n',1);return int(code),value
out={'teams':[]}
for path in ['/teams/','/teams/meu-team/','/teams/entrar/','/teams/convidar/','/api/profile/teams.cfm']:
 for method in ['GET','POST']:
  code,_=request('roadrunners.run',path,method);assert code==404,(method,path,code);out['teams'].append({'method':method,'path':path,'status':code})
code,text=request('roadrunners.run','/brasilquecorreprovas/2026/dados.cfm');assert code==200;data=json.loads(text)
assert set(data)=={'ok','release'} and data['ok'];r=data['release'];assert len(r['indicadores'])==6
assert r['periodo_fim']=='2026-09-30' and r['periodo_inicio']=='2026-01-01'
assert r['historias']['pareadas']['variacao_percentual']==2.2 and r['historias']['provas']['variacao_percentual']==38.7
out['public']={'status':code,'bytes':len(text.encode()),'six_indicators':6,'paired':2.2,'calendar':38.7,'volume':r['historias']['resultados']['variacao_percentual']}
code,text=request('roadrunners.run','/brasilquecorreprovas/imprensa/principal/dados.cfm?ano=2026');assert code==200;d=json.loads(text);assert d['meta']['contrato_versao']==18
assert d['meta']['comparativo_pareado']['execucao']==329 and d['meta']['comparativo_pareado']['coorte']['pares']==615
out['press_principal']={'status':code,'contract':18,'paired_source':329,'series':len(d['series'])}
code,_=request('roadrunners.run','/brasilquecorreprovas/imprensa/principal/dados.cfm?ano=2025');assert code==200;out['press_2025_status']=code
code,text=request('roadrunners.run','/brasilquecorreprovas/2026/kit/release-imprensa-2026.txt');assert code==200 and '+38,7%' in text and '+2,2%' in text;out['release']=code
code,text=request('roadrunners.run','/brasilquecorreprovas/2026/');assert code==200 and '+38,7%' in text and 'noindex' in text;out['landing']=code
code,_=request('business.roadrunners.run','/estudos/leitor/dados.cfm?ano=2026');assert code==401;out['professional_anonymous']=code
code,_=request('business.roadrunners.run','/estudos/lancamento/arquivo.cfm?doc=execucao-v7');assert code in [302,401,403];out['internal_pdf_anonymous']=code
print(json.dumps(out))
'''
r=m.remote(body,{});(W/'http-verification.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False))
