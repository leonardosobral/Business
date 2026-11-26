"""Verify candidate runs, preserved publications, and saved operational notes."""
from pathlib import Path
import hashlib
import importlib.util
import json

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('final_refresh_reader',W/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
before=json.loads((W/'notebook-before.json').read_text())
proposed=json.loads((W/'progress-proposed.json').read_text())
run_ids=sorted([int(json.loads(p.read_text())['run']['id']) for p in (W/'runs').glob('*.json')]+[299])
sql="""SELECT jsonb_build_object(
 'cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'version',c.version,'hash',md5(c.content),'content',CASE WHEN c.id IN(419,454) THEN c.content ELSE NULL END) ORDER BY c.id) FROM estudo.notebook_cells c JOIN estudo.notebooks n ON n.notebook_id=c.notebook_id WHERE n.caderno_id=6 AND NOT c.archived),
 'products',(SELECT jsonb_agg(jsonb_build_object('id',p.id,'code',p.codigo,'publication',p.publicacao_id,'run',w.run_id,'status',p.status)) FROM estudo.produtos p LEFT JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id),
 'destinations',(SELECT jsonb_agg(to_jsonb(d)) FROM estudo.web_destinos d),
 'public_definition',pg_get_viewdef('estudo.lancamento_publico'::regclass,true),
 'runs',(SELECT jsonb_agg(jsonb_build_object('id',id,'cell_id',cell_id,'cell_version',cell_version,'status',status,'frozen',frozen,'truncated',truncated,'sql_hash',sql_sha256) ORDER BY id) FROM estudo.notebook_runs WHERE id IN("""+','.join(map(str,run_ids))+""")),
 'steps',(SELECT jsonb_agg(to_jsonb(s)) FROM(SELECT DISTINCT ON(detalhes->>'step') id AS version,detalhes->>'step' AS step,detalhes->>'responsible' AS responsible,detalhes->>'notes' AS notes FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' ORDER BY detalhes->>'step',id DESC)s),
 'validation_events',(SELECT count(*) FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_VALIDATION' AND detalhes->>'release'='2026-q3-20261113')
 )::text AS payload"""
after=reader.query(sql)
(W/'audit-final.json').write_text(json.dumps(after,ensure_ascii=False,indent=2))
assert sorted(after['products'],key=lambda x:x['id'])==sorted(before['products'],key=lambda x:x['id'])
assert sorted(after['destinations'],key=lambda x:x['ano'])==sorted(before['destinations'],key=lambda x:x['ano'])
assert after['public_definition']==before['public_definition']
old_cells={int(c['id']):c for c in before['cells']};new_cells={int(c['id']):c for c in after['cells']}
assert set(new_cells)-set(old_cells)=={454}
changes=[]
for cid,c in old_cells.items():
    now=new_cells[cid]
    if cid==377:
        assert now['version']==c['version']+1
        assert now['hash']==hashlib.md5((W/'candidate-sql/cell-377.sql').read_bytes()).hexdigest()
        changes.append(cid)
    elif cid==419:
        assert now['version']==c['version']+1 and now['content']==proposed['content']
        changes.append(cid)
    else:
        assert now['version']==c['version'] and now['hash']==c['hash'],('Concurrent change: re-read before proceeding',cid)
assert new_cells[454]['content']==(W/'candidate-sql/freshness-audit.sql').read_text()
assert len(after['runs'])==33
assert all(r['status']=='ok' and r['frozen'] and not r['truncated'] for r in after['runs'])
for c in proposed['steps']:
    step=next(s for s in after['steps'] if s['step']==c['step'])
    assert step['responsible']==c['responsible'] and step['notes']==c['notes']
before_progress=json.loads((W/'progress-before.json').read_text())
assert after['validation_events']==before_progress['validation_events']==0
print(json.dumps({'candidate_runs':33,'frozen_complete':True,'publication_unchanged':True,'changed_existing_cells':changes,'new_audit_cell':454,'central_notes_verified':['organizar','liberacao'],'stages_validated':0},ensure_ascii=False))
