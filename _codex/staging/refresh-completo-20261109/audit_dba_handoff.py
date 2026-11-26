"""Verify source archival/checklist and pending load without executing the load."""
from pathlib import Path
import hashlib
import importlib.util
import json

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('handoff_reader',W/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
before=json.loads((W/'dba-source-notebook-before.json').read_text())
source=json.loads((W/'dba-source-notebook-receipt.json').read_text())
proposed=json.loads((W/'dba-central-proposed.json').read_text())
ids=[int(c['id']) for c in source['created']]
sql="""SELECT jsonb_build_object(
 'cells',(SELECT jsonb_agg(jsonb_build_object('id',id,'version',version,'sha256',encode(sha256(convert_to(content,'UTF8')),'hex'),'lang',lang,'type',cell_type)) FROM estudo.notebook_cells WHERE id IN(419,"""+','.join(map(str,ids))+""")),
 'products',(SELECT jsonb_agg(jsonb_build_object('code',codigo,'publication',publicacao_id,'status',status) ORDER BY id) FROM estudo.produtos),
 'public_definition',pg_get_viewdef('estudo.lancamento_publico'::regclass,true),
 'new_fact_visible',to_regclass('estudo.fat_perfil_br_2026_20261109') IS NOT NULL,
 'steps',(SELECT jsonb_agg(to_jsonb(s)) FROM(SELECT DISTINCT ON(detalhes->>'step') id AS version,detalhes->>'step' AS step,detalhes->>'responsible' AS responsible,detalhes->>'notes' AS notes FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' AND detalhes->>'step' IN('organizar','liberacao') ORDER BY detalhes->>'step',id DESC)s),
 'validation_events',(SELECT count(*) FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_VALIDATION' AND detalhes->>'release'='2026-q3-20261113')
 )::text AS payload"""
result=reader.query(sql)
(W/'dba-handoff-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
assert result['products']==before['products']
assert result['public_definition']==before['public_definition']
cells={int(c['id']):c for c in result['cells']}
assert cells[456]['sha256']==source['original_sha256']
assert cells[458]['sha256']==source['adapted_sha256']
assert cells[419]['version']==source['note']['version']==4
for step in result['steps']:
    assert step['responsible']=='Leo e Carlos'
    assert step['notes']==proposed['after'][step['step']]
assert result['validation_events']==0
print(json.dumps({'source_cells':ids,'source_hashes_verified':True,'note_revision':4,'central_saved':True,'published_edition_unchanged':True,'new_fact_visible':result['new_fact_visible'],'load_executed_by_this_task':False},ensure_ascii=False))
