from pathlib import Path
import json,re
S=Path(__file__).resolve().parent
ids='48501,48554,48918,49606';rel=json.loads((S/'relations.json').read_text())['foreignKeys'];rel=[r for r in rel if r['table'] not in ['tb_agregadores_eventos','tb_evento_corridas_percursos']]
fields=[]
for r in rel:
 t,c=r['table'],r['column'];assert re.fullmatch(r'[a-z_][a-z0-9_]*(\.[a-z_][a-z0-9_]*)?',t) and re.fullmatch(r'[a-z_][a-z0-9_]*',c)
 fields += ["'"+t+'.'+c+"'",f"(SELECT jsonb_build_object('count',count(*),'hash',md5(coalesce(string_agg(md5(to_jsonb(z)::text),'' ORDER BY md5(to_jsonb(z)::text)),'')),'source_adc',count(*) FILTER(WHERE {c}=48501),'source_outubro',count(*) FILTER(WHERE {c}=48554)) FROM {t} z WHERE {c} IN ({ids}))"]
dep='jsonb_build_object('+','.join(fields)+')';(S/'dependency-expression.sql').write_text(dep)
snapshot=f"SELECT jsonb_build_object('events',(SELECT jsonb_agg(to_jsonb(e) ORDER BY id_evento) FROM tb_evento_corridas e WHERE id_evento IN ({ids})),'routes',(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY id_evento_percurso),'[]') FROM tb_evento_corridas_percursos p WHERE id_evento IN ({ids})),'memberships',(SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY id_evento,agregador_tag),'[]') FROM tb_agregadores_eventos g WHERE id_evento IN ({ids})),'dependencies',{dep})::text payload"
(S/'before.sql').write_text(snapshot);print(json.dumps({'events':4,'dependentGroups':len(rel)}))
