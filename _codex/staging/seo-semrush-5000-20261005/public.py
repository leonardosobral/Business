from pathlib import Path
from urllib.parse import quote
from html.parser import HTMLParser
import json,shlex,subprocess,sys
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
events=json.loads((P/'inspection.json').read_text())['events'];ids=[28082,28088,43965,41252,47423,48153,48167]
cases=[{'path':'/evento/'+quote(e['tag'],safe='')+'/','kind':'event','id':e['id_evento']} for e in events if e['id_evento'] in ids]
cases += [{'path':'/evento/'+x+'/','kind':'case'} for x in ['2025-live-run-xp-brasilia-i-2025','2025-live-run-xp-brasilia-ii-2025','2026-endorfina-run-santo-andre-ii']]
cases += [{'path':x,'kind':'parent'} for x in ['/estado/pr/palmeira/','/estado/pb/lastro/','/estado/sp/ubatuba/','/estado/sp/campinas/','/timer/branca-esportes-saude-e-lazer/','/timer/corpo-e-saude/','/timer/geracao-saude/','/timer/grupo-de-corrida-espaco-saude/','/timer/zero-meia-um-saude-e-esporte/']]
remote='''import json,subprocess,sys
p=json.load(sys.stdin);result=[]
for x in p:
 cp=subprocess.run(['curl','-sS','--max-time','30','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code}','-D','-','https://roadrunners.run'+x['path']],capture_output=True,text=True,timeout=35)
 body,_,status=cp.stdout.rpartition('\\n');result.append(dict(x,status=status,response=body,returncode=cp.returncode))
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(cases),text=True,capture_output=True,timeout=300)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
rows=json.loads(cp.stdout);(P/('public-'+mode+'.json')).write_text(json.dumps(rows,indent=2,ensure_ascii=False))
print(json.dumps([{k:v for k,v in x.items() if k!='response'} for x in rows],ensure_ascii=False))
if mode=='after':
 for x in rows:
  assert x['returncode']==0
  assert x['status']==('301' if x['kind']=='case' else '200'),(x['path'],x['status'],x['response'][:700])
  assert 'Error Occurred While Processing Request' not in x['response']
