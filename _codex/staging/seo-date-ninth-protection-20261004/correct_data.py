from pathlib import Path
import json,shlex,subprocess,sys
P=Path(__file__).resolve().parent;ROOT=P.parents[2];mode=sys.argv[1]
assert mode in ['rehearse','validate_rollback','publish','verify','reconcile','rollback','test_drift']
before=json.loads((P/'baseline-data.json').read_text());patch=json.loads((P/'changes.json').read_text())
ids=','.join(str(e['id_evento']) for e in before['events'])
tables=list(json.loads((P/'dependencies.json').read_text())['dependencies'])
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
def literal(v):
 if v is None:return 'NULL'
 if isinstance(v,(dict,list)):return "'"+json.dumps(v,ensure_ascii=False).replace("'","''")+"'::jsonb"
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,(int,float)):return str(v)
 return "'"+v.replace("'","''")+"'"
def objectsql(v):return literal(v)
dep_sql="jsonb_build_object("+','.join(literal(t)+",(SELECT jsonb_build_object('count',count(*),'hash',md5(string_agg(md5(to_jsonb(d)::text),'' ORDER BY md5(to_jsonb(d)::text)))) FROM "+t+" d WHERE id_evento IN ("+','.join(literal(str(e['id_evento'])) for e in before['events'])+"))" for t in tables)+")"
snapshot="SELECT jsonb_build_object('events',(SELECT jsonb_agg(jsonb_build_object('id_evento',id_evento,'row_hash',md5(to_jsonb(e)::text)) ORDER BY id_evento) FROM tb_evento_corridas e WHERE id_evento IN ("+ids+")),'routes',(SELECT jsonb_agg(jsonb_build_object('id_evento_percurso',id_evento_percurso,'row_hash',md5(to_jsonb(p)::text)) ORDER BY id_evento_percurso) FROM tb_evento_corridas_percursos p WHERE id_evento IN (39558,41364,42544,42847,44114,44134,44550,44804,45121,45208,45377,45484,46297,47432,48133)),'dependencies',"+dep_sql+")::text payload"
def sql_for(reverse=False,after=None):
 ev={int(k):v.copy() for k,v in patch['events'].items()};rt={int(k):v.copy() for k,v in patch['routes'].items()}
 if reverse:
  for e in before['events']:
   if e['id_evento'] in ev:ev[e['id_evento']]={k:e[k] for k in ev[e['id_evento']]}
  for r in before['routes']:
   if r['id_evento_percurso'] in rt:rt[r['id_evento_percurso']]={k:r[k] for k in rt[r['id_evento_percurso']]}
 assert not patch['events'], 'This batch changes route dates only'
 guards=after if reverse else before
 out=["DO $seo$ DECLARE old_events jsonb;old_routes jsonb;deps jsonb;expected jsonb; BEGIN PERFORM set_config('lock_timeout','5s',true);",
 f"PERFORM 1 FROM tb_evento_corridas WHERE id_evento IN ({ids}) ORDER BY id_evento FOR UPDATE;",
 "PERFORM 1 FROM tb_evento_corridas_percursos WHERE id_evento IN (39558,41364,42544,42847,44114,44134,44550,44804,45121,45208,45377,45484,46297,47432,48133) ORDER BY id_evento_percurso FOR UPDATE;",
 "IF (SELECT count(*) FROM tb_evento_corridas_percursos WHERE id_evento IN (39558,41364,42544,42847,44114,44134,44550,44804,45121,45208,45377,45484,46297,47432,48133))<>31 THEN RAISE EXCEPTION 'Routes changed'; END IF;",
 f"SELECT jsonb_agg(to_jsonb(e) ORDER BY id_evento) INTO old_events FROM tb_evento_corridas e WHERE id_evento IN ({ids});",
 "SELECT jsonb_agg(to_jsonb(p) ORDER BY id_evento_percurso) INTO old_routes FROM tb_evento_corridas_percursos p WHERE id_evento IN (39558,41364,42544,42847,44114,44134,44550,44804,45121,45208,45377,45484,46297,47432,48133);",
 "SELECT "+dep_sql+" INTO deps;"]
 for table,key,rows in [('tb_evento_corridas','id_evento',guards['events']),('tb_evento_corridas_percursos','id_evento_percurso',guards['routes'])]:
  for r in rows:out.append(f"IF NOT EXISTS(SELECT 1 FROM {table} z WHERE {key}={r[key]} AND md5(to_jsonb(z)::text)='{r['row_hash']}') THEN RAISE EXCEPTION 'Baseline drift'; END IF;")
 for eid,fields in ev.items():out.append('UPDATE tb_evento_corridas SET '+','.join(k+'='+literal(v) for k,v in fields.items())+f' WHERE id_evento={eid};')
 for rid,fields in rt.items():out.append('UPDATE tb_evento_corridas_percursos SET '+','.join(k+'='+literal(v) for k,v in fields.items())+f' WHERE id_evento_percurso={rid};')
 for e in before['events']:
  eid=e['id_evento'];fields=ev.get(eid,{})
  out.append(f"SELECT x || {objectsql(fields)} INTO expected FROM jsonb_array_elements(old_events) x WHERE (x->>'id_evento')::int={eid}; IF (SELECT to_jsonb(e) FROM tb_evento_corridas e WHERE id_evento={eid}) IS DISTINCT FROM expected THEN RAISE EXCEPTION 'Unexpected event fields'; END IF;")
 for r in before['routes']:
  rid=r['id_evento_percurso'];fields=rt.get(rid,{})
  out.append(f"SELECT x || {objectsql(fields)} INTO expected FROM jsonb_array_elements(old_routes) x WHERE (x->>'id_evento_percurso')::int={rid}; IF (SELECT to_jsonb(p) FROM tb_evento_corridas_percursos p WHERE id_evento_percurso={rid}) IS DISTINCT FROM expected THEN RAISE EXCEPTION 'Unexpected route fields'; END IF;")
 out.extend(["IF (SELECT count(*) FROM tb_evento_corridas_percursos WHERE id_evento IN (39558,41364,42544,42847,44114,44134,44550,44804,45121,45208,45377,45484,46297,47432,48133))<>31 THEN RAISE EXCEPTION 'Route IDs recreated'; END IF;", "IF (SELECT "+dep_sql+") IS DISTINCT FROM deps THEN RAISE EXCEPTION 'Dependencies changed'; END IF; END $seo$"])
 return '\n'.join(out)
forward=sql_for();(P/'candidate.sql').write_text(forward)
reverse=sql_for(True,json.loads((P/'rehearse.json').read_text())) if mode in ['validate_rollback','rollback'] else ''
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-date-ninth-protection-20261004');mode=p['mode']
def state():return bridge(ROOT,raw_query(p['snapshot'],'state')+'report=deserializeJSON(state.payload[1]);')
def snapshot_guard(expected):
 value=json.dumps(expected,ensure_ascii=False).replace("'","''")
 return "DO $seo_guard$ BEGIN IF ("+p['snapshot']+")::jsonb IS DISTINCT FROM '"+value+"'::jsonb THEN RAISE EXCEPTION 'Publication snapshot drift'; END IF; END $seo_guard$"

if mode=='rehearse':
 stage.mkdir(mode=0o700,exist_ok=False)
 (stage/'inputs.json').write_text(json.dumps(p,ensure_ascii=False,indent=2))
 baseline=state();(stage/'baseline.json').write_text(json.dumps(baseline,indent=2))
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'mutation')+raw_query(p['snapshot'],'state')+'report=deserializeJSON(state.payload[1]);transaction action="rollback";}')
 if state()!=baseline:raise RuntimeError('Rehearsal rollback failed')
 (stage/'expected.json').write_text(json.dumps(result,indent=2))
elif mode=='validate_rollback':
 if json.loads((stage/'inputs.json').read_text())['forward']!=p['forward']:raise RuntimeError('Candidate changed')
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'mutation')+raw_query(p['reverse'],'restoration')+raw_query(p['snapshot'],'state')+'report=deserializeJSON(state.payload[1]);transaction action="rollback";}')
 if result!=json.loads((stage/'baseline.json').read_text()) or state()!=result:raise RuntimeError('Inverse verification failed')
 (stage/'inverse.sql').write_text(p['reverse']);(stage/'inverse-verified.json').write_text(json.dumps(result,indent=2))
elif mode=='test_drift':
 expected=json.loads((stage/'expected.json').read_text());expected['events'][0]['row_hash']='00000000000000000000000000000000'
 try:
  bridge(ROOT,'transaction {'+raw_query(p['forward'],'mutation')+raw_query(snapshot_guard(expected),'guard')+'report={unexpected=true};}')
 except RuntimeError as exc:
  if 'Publication snapshot drift' not in str(exc):raise
 else:raise RuntimeError('Drift was not rejected')
 result=state()
 if result!=json.loads((stage/'baseline.json').read_text()):raise RuntimeError('Drift test did not roll back')
 (stage/'drift-verified.json').write_text(json.dumps({'rejected_before_commit':True,'baseline_restored':True}))
elif mode=='publish':
 if json.loads((stage/'inputs.json').read_text())['forward']!=p['forward'] or not (stage/'inverse-verified.json').exists() or not (stage/'drift-verified.json').exists():raise RuntimeError('Unverified candidate')
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'mutation')+raw_query(snapshot_guard(json.loads((stage/'expected.json').read_text())),'guard')+raw_query(p['snapshot'],'state')+'report=deserializeJSON(state.payload[1]);}')
 if result!=json.loads((stage/'expected.json').read_text()):raise RuntimeError('Committed state differs; use reconcile')
 (stage/'published.json').write_text(json.dumps(result,indent=2))
elif mode in ['verify','reconcile']:
 result=state()
 if result==json.loads((stage/'expected.json').read_text()):
  (stage/'published.json').write_text(json.dumps(result,indent=2));result['verified']=True
 elif mode=='reconcile' and result==json.loads((stage/'baseline.json').read_text()):result['state']='baseline'
 else:raise RuntimeError('State matches neither expected nor baseline')
else:
 if (stage/'inverse.sql').read_text()!=p['reverse']:raise RuntimeError('Inverse changed')
 result=bridge(ROOT,'transaction {'+raw_query(p['reverse'],'restoration')+raw_query(p['snapshot'],'state')+'report=deserializeJSON(state.payload[1]);}')
 if result!=json.loads((stage/'baseline.json').read_text()):raise RuntimeError('Restoration mismatch')
print(json.dumps(result))
'''
payload={'mode':mode,'forward':forward,'reverse':reverse,'snapshot':snapshot,'baseline':before,'changes':patch}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=150)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout);(P/(mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps({'mode':mode,'events':len(r['events']),'routes':len(r['routes']),'dependent_tables':len(r['dependencies']),'verified':r.get('verified')}))
