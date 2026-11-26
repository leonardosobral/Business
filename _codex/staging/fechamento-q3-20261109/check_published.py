from pathlib import Path
import importlib.util,json,base64,hashlib
W=Path(__file__).resolve().parent
RR=W.parents[2].parent/'RoadRunners'
spec=importlib.util.spec_from_file_location('q3_reader',RR/'_codex/scripts/deploy_estudo_q3.py')
q=importlib.util.module_from_spec(spec);spec.loader.exec_module(q)
checks=[
 {'site':'business','path':'/estudos/leitor/dados.cfm?ano=2026','status':401},
 {'site':'business','path':'/estudos/lancamento/','status':401},
 {'site':'business','path':'/estudos/lancamento/arquivo.cfm?doc=execucao-v6','status':401},
 {'site':'business','path':'/estudos/lancamento/arquivos/brasil-que-corre-provas-lancamento-q3-execucao-v6.pdf','status':403},
 {'site':'portal','path':'/brasilquecorreprovas/2026/','status':200,'kind':'hotsite'},
 {'site':'portal','path':'/brasilquecorreprovas/2026/kit/provas-cadastradas-1920x1080.png?v=20261104-edicoes-calendario','status':200,'kind':'og-image'},
 {'site':'portal','path':'/brasilquecorreprovas/imprensa/principal/dados.cfm?ano=2026','status':200,'kind':'press-payload'},
]
for path in ['/teams/','/teams/meu-team/','/teams/entrar/','/teams/convidar/','/api/profile/teams.cfm']:
 for method in ['GET','POST']:checks.append({'site':'portal','path':path,'method':method,'status':404})
body=r'''
from concurrent.futures import ThreadPoolExecutor
from html.parser import HTMLParser
import re
hosts={'business':'business.roadrunners.run','portal':'roadrunners.run'}
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.meta={}
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='meta':self.meta[a.get('property') or a.get('name')]=a.get('content','')
def check(item):
 host=hosts[item['site']]
 p=subprocess.run(['curl','-sS','--max-time','25','--resolve',host+':443:127.0.0.1','-A','Mozilla/5.0','-X',item.get('method','GET'),'-w','\n%{http_code}','https://'+host+item['path']],capture_output=True,timeout=30)
 assert p.returncode==0,item['path']
 data,status=p.stdout.rsplit(b'\n',1);status=int(status)
 assert status==item['status'],(item['path'],status,data[:200])
 report={'site':item['site'],'path':item['path'],'method':item.get('method','GET'),'status':status}
 if item.get('kind')=='hotsite':
  parser=Meta();parser.feed(data.decode());m=parser.meta
  assert 'Mais provas no calendário, alta menor nas mesmas provas.' in m['og:description']
  assert 'provas-cadastradas-1920x1080.png' in m['og:image']
  assert m['robots']=='noindex,nofollow'
  report['metadata']='current-comparison'
 if item.get('kind')=='og-image':
  assert data[:8]==b'\x89PNG\r\n\x1a\n';report['sha256']=digest(data)
 if item.get('kind')=='press-payload':
  value=json.loads(data);meta=value['meta']['comparativo_pareado']
  assert meta['status']=='disponivel' and meta['execucao']==231 and meta['narrativa']['execucao']==239
  assert meta['coorte']['pares']==608 and len(value['series'])==116
  assert meta['coorte']['concluintes_2025']==1185401 and meta['coorte']['concluintes_2026']==1210676
  assert not any(re.match(r'^(inscricoes_|cna_|performance_42k_)',s['id']) for s in value['series'])
  report.update({'series':len(value['series']),'comparisons':len(value['comparacoes']),'paired_races':608,'source':231,'narrative':239})
 return report
with ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(check,payload['checks']))
for n in ['atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm','includes/estrutura/header.cfm','includes/backend/backend_profile_settings.cfm']:
 source=(Path('/var/www/roadrunners.com.br')/n).read_text()
 assert not re.search(r'/teams/|profile[_-]teams|profile_team_|profileTeams|Road Runners Teams|Meu Team',source,re.I),n
print(json.dumps({'http':results,'teams_templates':'withheld'}))
'''
result=q.remote(body,{'checks':checks})
(W/'http-published.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps({'http_checks':len(result['http']),'teams_404':sum(r['status']==404 for r in result['http']),'private_guards':'preserved','press_payload':'116 series, 608 pairs','public_metadata':'current','teams_templates':result['teams_templates']}))
