"""Save one explicit derived query with an optimistic lock, then run/freeze it.

No publication, product pointer, view, DDL or operational fact table is changed.
An existing receipt is a hard stop; recovery must inspect its run before retrying.
"""
from pathlib import Path
import base64
import importlib.util
import json
import sys

W = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('refresh_operator_reader', W / 'inspect.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)

def save_collect(cell_id, sql_path):
    snapshot = json.loads((W / 'notebook-before.json').read_text())
    cell = next(c for c in snapshot['cells'] if int(c['id']) == cell_id)
    target = W / 'runs' / f'{cell_id}.json'
    assert not target.exists(), 'Receipt already exists; inspect before recovery'
    cfg = dict(id=cell_id, version=cell['version'], hash=cell['hash'],
               content=Path(sql_path).read_text(), actor=json.loads((W / 'preflight.json').read_text())['actor'])
    encoded = base64.b64encode(json.dumps(cfg, ensure_ascii=False).encode()).decode()
    cf = 'cfg=deserializeJSON(toString(binaryDecode("' + encoded + '","base64")));'
    cf += 'preflightGuard=new estudo.includes.SqlReadGuard();preflightGuard.validate(cfg.content);'
    cf += 'current=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=:id AND NOT archived",{id={value=cfg.id,cfsqltype="cf_sql_bigint"}},{datasource="runner_dba",timeout=10});'
    cf += 'if(current.recordCount!=1 || current.version[1]!=cfg.version || current.hash[1]!=cfg.hash)throw(message="A célula mudou. Reler e comparar antes de salvar.");'
    cf += 'svc=new estudo.includes.StudyNotebook().init();saved=svc.saveCell(cfg.id,cfg.version,"code","sql",cfg.content,cfg.actor);'
    cf += 'run=svc.execute(saved.id,saved.version,saved.content,cfg.actor);'
    cf += 'if(run.status=="ok" && !run.truncated)run=svc.freeze(run.id,"Atualização Jan–Set — 09/11/2026 — célula "&cfg.id,"Candidato da renovação completa. Referências mensais atualizadas, critérios preservados. A publicação vigente não foi alterada.",cfg.actor);'
    cf += 'structDelete(saved,"content");structDelete(run,"result_json");report={"saved":saved,"run":run};'
    report = reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))", {'cf':cf})
    target.write_text(json.dumps(report, ensure_ascii=False, indent=2))
    run = report['run']
    if run['status'] != 'ok' or not run['frozen']:
        raise RuntimeError('Execution failed; receipt preserved: ' + str(target))
    report['data'] = reader.query("SELECT jsonb_build_object('result',result,'id',id,'cell_id',cell_id,'cell_version',cell_version,'started_at',started_at,'frozen',frozen,'status',status)::text AS payload FROM estudo.notebook_runs WHERE id=" + str(int(run['id'])))
    target.write_text(json.dumps(report, ensure_ascii=False, indent=2))
    print(json.dumps({'cell':cell_id, 'revision':run['cell_version'], 'run':run['id'], 'frozen':run['frozen'], 'published':False}))

if __name__ == '__main__':
    save_collect(int(sys.argv[1]), Path(sys.argv[2]))
