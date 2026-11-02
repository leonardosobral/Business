from pathlib import Path
import json,subprocess,shlex,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('rehearse','publish','verify','rollback')
b=json.loads((S/'before.json').read_text());d=json.loads((S/'decisions.json').read_text());patch=d['eventChanges'];snapshot=(S/'before.sql').read_text();dep=(S/'dependency-expression.sql').read_text();ids=','.join(str(e['id_evento']) for e in b['events'])
def lit(x):
 if x is None:return 'NULL'
 if isinstance(x,bool):return 'true' if x else 'false'
 if isinstance(x,(int,float)):return str(x)
 if isinstance(x,(dict,list)):return lit(json.dumps(x,ensure_ascii=False))+'::jsonb'
 return "'"+x.replace("'","''")+"'"
expected={e['id_evento']:e|patch.get(str(e['id_evento']),{}) for e in b['events']}
routeExpr=f"(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY id_evento_percurso),'[]') FROM tb_evento_corridas_percursos p WHERE id_evento IN ({ids}))"
memberExpr=f"(SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY id_evento,agregador_tag),'[]') FROM tb_agregadores_eventos g WHERE id_evento IN ({ids}))"
def guards(events):
 out=[]
 for eid,e in events.items():out.append(f"IF (SELECT to_jsonb(e) FROM tb_evento_corridas e WHERE id_evento={eid}) IS DISTINCT FROM {lit(e)} THEN RAISE EXCEPTION 'Event drift {eid}'; END IF;")
 for expr,want,name in [(routeExpr,b['routes'],'Courses'),(memberExpr,b['memberships'],'Memberships'),(dep,b['dependencies'],'Dependencies')]:out.append(f"IF ({expr}) IS DISTINCT FROM {lit(want)} THEN RAISE EXCEPTION '{name} changed'; END IF;")
 return out
prefix=["DO $fix$ BEGIN PERFORM set_config('lock_timeout','5s',true);",f"PERFORM 1 FROM tb_evento_corridas WHERE id_evento IN ({ids}) ORDER BY id_evento FOR UPDATE;"]
updates=['UPDATE tb_evento_corridas SET '+','.join(k+'='+lit(v) for k,v in fields.items())+f' WHERE id_evento={eid};' for eid,fields in patch.items()]
old={e['id_evento']:e for e in b['events']}
forward='\n'.join(prefix+guards(old)+updates+guards(expected)+['END $fix$;'])
reverseUpdates=['UPDATE tb_evento_corridas SET '+','.join(k+'='+lit(old[int(eid)][k]) for k in fields)+f' WHERE id_evento={eid};' for eid,fields in patch.items()]
reverse='\n'.join(prefix+guards(expected)+reverseUpdates+guards(old)+['END $fix$;'])
(S/'candidate.sql').write_text(forward);(S/'inverse.sql').write_text(reverse)
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def legacy_sql(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-duplicidades-20261030-data')
def state():return bridge(ROOT,raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);')
if p['mode']=='rehearse':
 stage.mkdir(mode=0o700,exist_ok=False);before=state();(stage/'baseline.json').write_text(json.dumps(before));(stage/'input.json').write_text(json.dumps(p))
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}');assert state()==before,'Rehearsal baseline not restored'
 restored=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['inverse'],'undo')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}');assert restored==before and state()==before,'Inverse failed'
 (stage/'rehearsed.json').write_text(json.dumps(result));(stage/'inverse.sql').write_text(p['inverse']);result={'rehearsed':True,'inverseVerified':True,'events':len(result['events']),'routes':len(result['routes']),'memberships':len(result['memberships']),'dependencies':len(result['dependencies'])}
elif p['mode']=='publish':
 saved=json.loads((stage/'input.json').read_text());assert saved['forward']==p['forward'] and (stage/'inverse.sql').read_text()==p['inverse'];assert state()==json.loads((stage/'baseline.json').read_text()),'Publication drift'
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);}');(stage/'published.json').write_text(json.dumps(result))
elif p['mode']=='rollback':
 assert state()==json.loads((stage/'published.json').read_text()),'Concurrent changes';result=bridge(ROOT,'transaction {'+raw_query(p['inverse'],'undo')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);}');assert result==json.loads((stage/'baseline.json').read_text())
else:
 result=state();assert result==json.loads((stage/'published.json').read_text()),'Published state differs'
print(json.dumps(result))
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'forward':forward,'inverse':reverse,'snapshot':snapshot}),capture_output=True,text=True,timeout=150);assert r.returncode==0,r.stderr[-2600:];result=json.loads(r.stdout);(S/('data-'+mode+'.json')).write_text(json.dumps(result,indent=2,ensure_ascii=False));print(json.dumps(result if mode=='rehearse' else {'mode':mode,'events':len(result['events']),'routes':len(result['routes']),'memberships':len(result['memberships']),'dependencies':len(result['dependencies'])}))
