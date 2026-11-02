from pathlib import Path
import json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('rehearse','publish','verify','rollback')
b=json.loads((S/'baseline-data.json').read_text());changes=json.loads((S/'changes.json').read_text())['events'];deps=json.loads((S/'dependencies.json').read_text())['dependencies'];ids=','.join(str(e['id_evento']) for e in b['events']);oldids=','.join(str(p['id_evento_percurso']) for p in b['routes'])
def lit(x):
 if x is None:return 'NULL'
 if isinstance(x,bool):return 'true' if x else 'false'
 if isinstance(x,(int,float)):return str(x)
 if isinstance(x,(dict,list)):return lit(json.dumps(x,ensure_ascii=False))+'::jsonb'
 return "'"+x.replace("'","''")+"'"
def clean(r):return {k:v for k,v in r.items() if k!='row_hash'}
deps_expr=(S/'dependencies.sql').read_text().split("SELECT jsonb_build_object('dependencies',",1)[1].split(",'historyMax'",1)[0]
snapshot=f"SELECT jsonb_build_object('events',(SELECT jsonb_agg(to_jsonb(e) ORDER BY id_evento) FROM tb_evento_corridas e WHERE id_evento IN ({ids})),'routes',(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY id_evento_percurso),'[]') FROM tb_evento_corridas_percursos p WHERE id_evento IN ({ids})),'dependencies',{deps_expr})::text payload"
expected={e['id_evento']:clean(e)|changes.get(str(e['id_evento']),{}) for e in b['events']}
body=["DO $fix$ BEGIN PERFORM set_config('lock_timeout','5s',true);",f"PERFORM 1 FROM tb_evento_corridas WHERE id_evento IN ({ids}) ORDER BY id_evento FOR UPDATE;",f"PERFORM 1 FROM tb_evento_corridas_percursos WHERE id_evento IN ({ids}) ORDER BY id_evento_percurso FOR UPDATE;"]
for table,key,rows in [('tb_evento_corridas','id_evento',b['events']),('tb_evento_corridas_percursos','id_evento_percurso',b['routes'])]:
 for r in rows:body.append(f"IF NOT EXISTS(SELECT 1 FROM {table} x WHERE {key}={r[key]} AND md5(to_jsonb(x)::text)={lit(r['row_hash'])}) THEN RAISE EXCEPTION 'Baseline drift {table} {r[key]}'; END IF;")
body.append(f"IF ({deps_expr}) IS DISTINCT FROM {lit(deps)} THEN RAISE EXCEPTION 'Dependent data drift'; END IF;")
body.append('UPDATE tb_evento_corridas_percursos SET percurso_bloqueado=true WHERE id_evento=43657;')
for eid,fields in changes.items():body.append('UPDATE tb_evento_corridas SET '+','.join(k+'='+lit(v) for k,v in fields.items())+f' WHERE id_evento={eid};')
body.append("UPDATE tb_evento_corridas_percursos SET percurso_bloqueado=true WHERE id_evento IN (43657,39395);")
body.append("UPDATE tb_evento_corridas_percursos SET hora_largada=CASE percurso_evento WHEN 5 THEN time '17:00' WHEN 10 THEN time '17:00' WHEN 21 THEN time '06:00' WHEN 42 THEN time '05:00' END WHERE id_evento=39395;")
for eid,e in expected.items():body.append(f"IF (SELECT to_jsonb(x) FROM tb_evento_corridas x WHERE id_evento={eid}) IS DISTINCT FROM {lit(e)} THEN RAISE EXCEPTION 'Unexpected event fields {eid}'; END IF;")
for p in b['routes']:
 want=clean(p)
 if p['id_evento']==43657:want['percurso_bloqueado']=True
 body.append(f"IF (SELECT to_jsonb(x) FROM tb_evento_corridas_percursos x WHERE id_evento_percurso={p['id_evento_percurso']}) IS DISTINCT FROM {lit(want)} THEN RAISE EXCEPTION 'Existing route changed {p['id_evento_percurso']}'; END IF;")
for eid in [43657,39395]:
 body.append(f"IF (SELECT array_agg(percurso_evento ORDER BY percurso_evento) FROM tb_evento_corridas_percursos WHERE id_evento={eid}) IS DISTINCT FROM ARRAY[5,10,21,42]::numeric[] THEN RAISE EXCEPTION 'Distance mismatch'; END IF;")
 body.append(f"IF EXISTS(SELECT 1 FROM tb_evento_corridas_percursos WHERE id_evento={eid} AND (unidade_de_medida<>'km' OR data_percurso<>CASE WHEN {eid}=39395 AND percurso_evento IN (5,10) THEN date '2026-11-21' WHEN {eid}=39395 THEN date '2026-11-22' ELSE date '2026-11-15' END)) THEN RAISE EXCEPTION 'Course dates mismatch'; END IF;")
body.append(f"IF ({deps_expr}) IS DISTINCT FROM {lit(deps)} THEN RAISE EXCEPTION 'Dependent data changed'; END IF; END $fix$;")
forward='\n'.join(body);(S/'candidate.sql').write_text(forward)
# Inverse only accepts the exact state captured after this publication/rehearsal.
inverse=["DO $restore$ BEGIN"]
for eid,e in expected.items():inverse.append(f"IF (SELECT to_jsonb(x) FROM tb_evento_corridas x WHERE id_evento={eid}) IS DISTINCT FROM {lit(e)} THEN RAISE EXCEPTION 'Concurrent event change'; END IF;")
for e in b['events']:
 fields=changes.get(str(e['id_evento']),{})
 if fields:inverse.append('UPDATE tb_evento_corridas SET '+','.join(k+'='+lit(e[k]) for k in fields)+f" WHERE id_evento={e['id_evento']};")
inverse.append(f'DELETE FROM tb_evento_corridas_percursos WHERE id_evento IN (43657,39395) AND id_evento_percurso NOT IN ({oldids});')
for p in b['routes']:
 if p['id_evento']==43657:inverse.append(f"UPDATE tb_evento_corridas_percursos SET percurso_bloqueado={lit(p['percurso_bloqueado'])} WHERE id_evento_percurso={p['id_evento_percurso']};")
inverse.append('END $restore$;');inverse='\n'.join(inverse);(S/'inverse.sql').write_text(inverse)
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def legacy_sql(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-curadoria-circuitos-20261030-data')
def state():return bridge(ROOT,raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);')
if p['mode']=='rehearse':
 stage.mkdir(mode=0o700,exist_ok=False);(stage/'input.json').write_text(json.dumps(p));before=state();(stage/'baseline.json').write_text(json.dumps(before));
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}')
 assert state()==before,'Rehearsal changed database'
 restored=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['inverse'],'restore')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}')
 assert restored==before and state()==before,'Inverse verification failed'
 (stage/'rehearsed.json').write_text(json.dumps(result));(stage/'inverse.sql').write_text(p['inverse']);result={'rehearsed':True,'inverseVerified':True,'events':len(result['events']),'routes':len(result['routes']),'dependencies':len(result['dependencies'])}
elif p['mode']=='publish':
 saved=json.loads((stage/'input.json').read_text());assert saved['forward']==p['forward'] and (stage/'inverse.sql').read_text()==p['inverse'];assert state()==json.loads((stage/'baseline.json').read_text()),'Publication baseline drift'
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);}')
 (stage/'published.json').write_text(json.dumps(result))
elif p['mode']=='rollback':
 assert state()==json.loads((stage/'published.json').read_text()),'Concurrent data changes'
 result=bridge(ROOT,'transaction {'+raw_query(p['inverse'],'restore')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);}')
 assert result==json.loads((stage/'baseline.json').read_text())
else:
 result=state();assert result==json.loads((stage/'published.json').read_text()),'Published state differs'
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'snapshot':snapshot,'forward':forward,'inverse':inverse}),capture_output=True,text=True,timeout=150)
assert cp.returncode==0,cp.stderr[-3000:]
r=json.loads(cp.stdout);(S/('data-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r if mode=='rehearse' else {'mode':mode,'events':len(r['events']),'routes':len(r['routes']),'dependencies':len(r['dependencies'])}))
