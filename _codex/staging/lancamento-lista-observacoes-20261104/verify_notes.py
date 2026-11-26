from inspect import remote,W
import json,hashlib
expected=json.loads((W/'observacoes-propostas.json').read_text())
sql="""SELECT jsonb_build_object('notes',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT DISTINCT ON(a.detalhes->>'step') a.id,a.detalhes->>'step' AS step,a.detalhes->>'responsible' AS responsible,a.detalhes->>'notes' AS notes,a.ator_id,CAST(a.criado_em AS text) AS saved_at FROM estudo.auditoria_comercial a WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' ORDER BY detalhes->>'step',id DESC)d),'validation_count',(SELECT count(*) FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_VALIDATION'))::text AS payload"""
r=remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':sql})
actual={i['step']:i for i in r['notes']};assert set(actual)==set(expected)
for k,note in expected.items():assert actual[k]['notes']==note,k
before=json.loads((W/'readiness-before.json').read_text());assert r['validation_count']==len(before['validations'])==0
assert all(not v['responsible']for v in actual.values()),'Responsible changed'
(W/'notes-after.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
receipt={'notes':len(actual),'versions':{k:v['id']for k,v in actual.items()},'validation_state_preserved':True,'responsibles_preserved':True,'matched_text':True}
(W/'notes-verify.json').write_text(json.dumps(receipt,indent=2));print(receipt)
