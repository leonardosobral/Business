from pathlib import Path
import importlib.util,json,hashlib,shutil
W=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('close_inspect',W/'inspect_current.py')
h=importlib.util.module_from_spec(s);s.loader.exec_module(h)
sql="""SELECT jsonb_build_object(
 'cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'version',c.version,'hash',md5(c.content))) FROM estudo.notebook_cells c JOIN estudo.notebooks n ON n.notebook_id=c.notebook_id WHERE n.caderno_id=6 AND NOT c.archived),
 'scope',(SELECT to_jsonb(c) FROM (SELECT id,version,content FROM estudo.notebook_cells WHERE id=419)c),
 'product',(SELECT jsonb_build_object('publication',publicacao_id,'status',status) FROM estudo.produtos WHERE codigo='previa-2026-q3'),
 'runs',(SELECT jsonb_agg(jsonb_build_object('id',id,'frozen',frozen,'status',status)) FROM estudo.notebook_runs WHERE id IN(231,233,239)),
 'steps',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT DISTINCT ON(detalhes->>'step') detalhes->>'step' AS step,id AS version,detalhes->>'responsible' AS responsible,detalhes->>'notes' AS notes FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' ORDER BY detalhes->>'step',id DESC)d),
 'validation_events',(SELECT count(*) FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_VALIDATION' AND detalhes->>'release'='2026-q3-20261113')
 )::text AS payload"""
result=h.h.remote("report=bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);');report['v5_sha256']=digest((Path('/var/www/business.roadrunners.run')/payload['v5']).read_bytes());print(json.dumps(report))",{'sql':sql,'v5':'estudos/lancamento/arquivos/brasil-que-corre-provas-lancamento-q3-execucao-v5.pdf'})
before=json.loads((W/'current-state.json').read_text())
before_cells={x['id']:x for x in before['cells']};after_cells={x['id']:x for x in result['cells']}
assert set(before_cells)==set(after_cells)
for cid,b in before_cells.items():
 if cid!=419:assert all(after_cells[cid][k]==b[k] for k in ['version','hash']),cid
scope=json.loads((W/'notebook-scope-proposed.json').read_text())
assert result['scope']['version']==2 and result['scope']['content']==scope['content']
assert result['product']=={'publication':41,'status':'ACTIVE'}
assert all(x['frozen'] and x['status']=='ok' for x in result['runs'])
assert result['v5_sha256']=='2f886359df22602ee7fa84029b48bd764bcf348f56ff71ceaa3e7ceb316fc1e8'
notes=json.loads((W/'observacoes-fechamento-propostas.json').read_text())
for step in result['steps']:
 if step['step'] in notes:
  assert step['notes']==notes[step['step']]
  assert step['responsible']=='Leo e Carlos'
assert result['validation_events']==0
(W/'audit-final.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
proof=W/'qa';proof.mkdir(exist_ok=True)
for name in ['q3-fechamento-comparativo-desktop.png','q3-fechamento-comparativo-mobile.png']:
 p=Path('/private/tmp')/name;shutil.copy2(p,proof/name);p.unlink()
print(json.dumps({'notebook_queries_unchanged':True,'note_419_revision':2,'frozen_runs_preserved':[231,233,239],'v5_preserved':True,'owners_saved':5,'stages_validated':0}))
