from pathlib import Path
import json,subprocess,shlex,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('rehearse','publish','verify','rollback')
b=json.loads((S/'before.json').read_text());d=json.loads((S/'decisions.json').read_text());patch=d['eventChanges'];snapshot=(S/'before.sql').read_text();dep=(S/'dependency-expression.sql').read_text();ids=','.join(str(e['id_evento']) for e in b['events']);oldids=','.join(str(p['id_evento_percurso']) for p in b['routes'])
def lit(x):
 if x is None:return 'NULL'
 if isinstance(x,bool):return 'true' if x else 'false'
 if isinstance(x,(int,float)):return str(x)
 if isinstance(x,(dict,list)):return lit(json.dumps(x,ensure_ascii=False))+'::jsonb'
 return "'"+x.replace("'","''")+"'"
expected={e['id_evento']:e|patch.get(str(e['id_evento']),{}) for e in b['events']}
wantMembers=sorted(b['memberships']+[{'id_evento':x['id_evento'],'agregador_tag':x['agregador_tag'],'percursos':None} for x in d['addMemberships']],key=lambda x:(x['id_evento'],x['agregador_tag']))
memberExpr=f"(SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY id_evento,agregador_tag),'[]') FROM tb_agregadores_eventos g WHERE id_evento IN ({ids}))"
body=["DO $fix$ BEGIN PERFORM set_config('lock_timeout','5s',true);",f"PERFORM 1 FROM tb_evento_corridas WHERE id_evento IN ({ids}) ORDER BY id_evento FOR UPDATE;",f"PERFORM 1 FROM tb_evento_corridas_percursos WHERE id_evento IN ({ids}) ORDER BY id_evento_percurso FOR UPDATE;"]
for e in b['events']:body.append(f"IF (SELECT to_jsonb(e) FROM tb_evento_corridas e WHERE id_evento={e['id_evento']}) IS DISTINCT FROM {lit(e)} THEN RAISE EXCEPTION 'Event baseline drift {e['id_evento']}'; END IF;")
body += [f"IF ({memberExpr}) IS DISTINCT FROM {lit(b['memberships'])} THEN RAISE EXCEPTION 'Membership baseline drift'; END IF;",f"IF ({dep}) IS DISTINCT FROM {lit(b['dependencies'])} THEN RAISE EXCEPTION 'Dependency drift'; END IF;",f"IF (SELECT jsonb_agg(to_jsonb(p) ORDER BY id_evento_percurso) FROM tb_evento_corridas_percursos p WHERE id_evento IN ({ids})) IS DISTINCT FROM {lit(b['routes'])} THEN RAISE EXCEPTION 'Route drift'; END IF;"]
body.append('UPDATE tb_evento_corridas_percursos SET percurso_bloqueado=true WHERE id_evento=48557;')
for eid,fields in patch.items():body.append('UPDATE tb_evento_corridas SET '+','.join(k+'='+lit(v) for k,v in fields.items())+f' WHERE id_evento={eid};')
body.append('UPDATE tb_evento_corridas_percursos SET percurso_bloqueado=true WHERE id_evento=48557;')
body.append('INSERT INTO tb_agregadores_eventos(agregador_tag,id_evento) VALUES '+','.join('('+lit(x['agregador_tag'])+','+str(x['id_evento'])+')' for x in d['addMemberships'])+';')
for eid,e in expected.items():body.append(f"IF (SELECT to_jsonb(e) FROM tb_evento_corridas e WHERE id_evento={eid}) IS DISTINCT FROM {lit(e)} THEN RAISE EXCEPTION 'Unexpected event fields {eid}'; END IF;")
for p in b['routes']:
 want=dict(p)
 if p['id_evento']==48557:want['percurso_bloqueado']=True
 body.append(f"IF (SELECT to_jsonb(p) FROM tb_evento_corridas_percursos p WHERE id_evento_percurso={p['id_evento_percurso']}) IS DISTINCT FROM {lit(want)} THEN RAISE EXCEPTION 'Existing route changed'; END IF;")
body += ["IF (SELECT array_agg(percurso_evento ORDER BY percurso_evento) FROM tb_evento_corridas_percursos WHERE id_evento=48557) IS DISTINCT FROM ARRAY[5,10,15]::numeric[] THEN RAISE EXCEPTION 'Distance mismatch'; END IF;", "IF EXISTS(SELECT 1 FROM tb_evento_corridas_percursos WHERE id_evento=48557 AND (data_percurso<>date '2026-11-22' OR unidade_de_medida<>'km' OR NOT percurso_bloqueado)) THEN RAISE EXCEPTION 'Course facts mismatch'; END IF;",f"IF (SELECT count(*) FROM tb_evento_corridas_percursos WHERE id_evento IN ({ids}))<>{len(b['routes'])+1} THEN RAISE EXCEPTION 'Unexpected route count'; END IF;",f"IF ({memberExpr}) IS DISTINCT FROM {lit(wantMembers)} THEN RAISE EXCEPTION 'Membership mismatch'; END IF;",f"IF ({dep}) IS DISTINCT FROM {lit(b['dependencies'])} THEN RAISE EXCEPTION 'Dependent rows changed'; END IF; END $fix$;"]
forward='\n'.join(body);(S/'candidate.sql').write_text(forward)
reverse=['DO $undo$ BEGIN']
for e in b['events']:
 fields=patch.get(str(e['id_evento']),{})
 if fields:reverse.append('UPDATE tb_evento_corridas SET '+','.join(k+'='+lit(e[k]) for k in fields)+f" WHERE id_evento={e['id_evento']};")
reverse.append(f'DELETE FROM tb_evento_corridas_percursos WHERE id_evento=48557 AND id_evento_percurso NOT IN ({oldids});')
for p in b['routes']:
 if p['id_evento']==48557:reverse.append(f"UPDATE tb_evento_corridas_percursos SET percurso_bloqueado={lit(p['percurso_bloqueado'])} WHERE id_evento_percurso={p['id_evento_percurso']};")
for x in d['addMemberships']:reverse.append(f"DELETE FROM tb_agregadores_eventos WHERE id_evento={x['id_evento']} AND agregador_tag={lit(x['agregador_tag'])};")
reverse.append('END $undo$;');reverse='\n'.join(reverse);(S/'inverse.sql').write_text(reverse)
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def legacy_sql(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-circuitos-vinculos-20261030')
def state():return bridge(ROOT,raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);')
if p['mode']=='rehearse':
 stage.mkdir(mode=0o700,exist_ok=False);before=state();(stage/'baseline.json').write_text(json.dumps(before));(stage/'input.json').write_text(json.dumps(p))
 result=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}');assert state()==before,'Rehearsal failed to restore baseline'
 restored=bridge(ROOT,'transaction {'+raw_query(p['forward'],'fix')+raw_query(p['inverse'],'undo')+raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);transaction action="rollback";}');assert restored==before and state()==before,'Inverse verification failed'
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
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'forward':forward,'inverse':reverse,'snapshot':snapshot}),capture_output=True,text=True,timeout=150);assert r.returncode==0,r.stderr[-2600:];result=json.loads(r.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(result,indent=2,ensure_ascii=False));print(json.dumps(result if mode=='rehearse' else {'mode':mode,'events':len(result['events']),'routes':len(result['routes']),'memberships':len(result['memberships']),'dependencies':len(result['dependencies'])}))
