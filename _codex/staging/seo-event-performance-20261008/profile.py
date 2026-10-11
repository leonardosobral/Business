from pathlib import Path
import base64, hashlib, json, re, shlex, subprocess, sys

S = Path(__file__).resolve().parent
B = S.parents[2]
R = B.parent / 'RoadRunners'
NAME = 'includes/backend/backend_evento.cfm'
mode = sys.argv[1] if len(sys.argv)>1 else 'before'
assert mode in ['before','candidate']
helpers = (B / '_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0]
helpers = helpers.replace('ROOT=Path(__file__).resolve().parents[2]', "ROOT=Path('/var/www/business.roadrunners.run')")
remote = helpers + '''
import re
rr=Path('/var/www/roadrunners.com.br');name='includes/backend/backend_evento.cfm'
p=json.load(sys.stdin);src=p.get('source') or (rr/name).read_text();query=re.search(r'<cfquery name="qEventoEdicoes"[^>]*>(.*?)</cfquery>',src,re.S).group(1)
query=re.sub(r'<cfqueryparam[^>]*value="#VARIABLES.eventRecordAssetsBaseUrl#"[^>]*/>',"'https://roadrunners.run/assets/paginas/'",query)
query=re.sub(r'<cfqueryparam[^>]*value="#qEvento.id_agrega_evento#"[^>]*/>',"(SELECT id_agrega_evento FROM tb_evento_corridas WHERE tag='2026-101-corrida-internacional-de-sao-silvestre' LIMIT 1)",query)
assert '<cf' not in query
body='transaction {'+raw_query("SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='20s'",'qLimits')+raw_query('EXPLAIN (ANALYZE, FORMAT JSON) '+query,'qPlan')+'}plan=deserializeJSON(qPlan["QUERY PLAN"][1]);report={execution_ms=plan[1]["Execution Time"],rows=plan[1].Plan["Actual Rows"],nodes=[]};function walk(n){var x={};for(k in ["Node Type","Relation Name","Actual Loops","Actual Rows","Actual Total Time","Subplan Name"]){if(structKeyExists(n,k))x[k]=n[k];}arrayAppend(report.nodes,x);if(structKeyExists(n,"Plans")){for(c in n.Plans)walk(c);}}walk(plan[1].Plan);'
reports=[bridge(ROOT,body),bridge(ROOT,body)]
watch=['Application.cfc','evento/index.cfm','includes/estrutura/event_title_date.cfm','includes/evento_edicoes.cfm']
print(json.dumps({'source':base64.b64encode(src.encode()).decode(),'profiles':reports,'watch':{n:digest((rr/n).read_bytes()) for n in watch if (rr/n).exists()}}))
'''
ssh = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']
cp = subprocess.run(ssh + ['python3 -c ' + shlex.quote(remote)], input=json.dumps({'source':(S/'candidate/rr'/NAME).read_text() if mode=='candidate' else None}), capture_output=True, text=True, timeout=210)
if cp.returncode:
    raise RuntimeError(cp.stderr[-2500:])
r = json.loads(cp.stdout)
src = base64.b64decode(r.pop('source'))
if mode=='before':
    for group in ['baseline', 'candidate']:
        target = S / group / 'rr' / NAME
        target.parent.mkdir(parents=True, exist_ok=True)
        assert not target.exists() or target.read_bytes() == src
        target.write_bytes(src)
r['sha256'] = hashlib.sha256(src).hexdigest()
r['local_matches'] = (R / NAME).read_bytes() == src
(S / ('profile-'+mode+'.json')).write_text(json.dumps(r, indent=2))
print(json.dumps({'mode':mode,'profiles':[{'execution_ms':x['EXECUTION_MS'],'rows':x['ROWS'],'profile_lookup_loops':sum(n['Actual Loops'] for n in x['NODES'] if n.get('Relation Name') in ['tb_usuarios','tb_paginas'])} for x in r['profiles']],'local_matches':r['local_matches']}))
