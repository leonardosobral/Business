"""Read immutable prior executions; never executes analytical source SQL."""
from pathlib import Path
import importlib.util
import json

W = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('refresh_reader', W / 'inspect.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
snapshot = json.loads((W / 'notebook-before.json').read_text())
cells = {int(c['id']): c for c in snapshot['cells']}
requested = set(int(p.stem) for p in (W / 'runs').glob('*.json'))
requested.update((251, 249, 420, 377, 387))
ids = sorted({int(cells[c]['last_frozen']['id']) for c in requested})
sql = """SELECT jsonb_build_object('runs',(
 SELECT jsonb_agg(jsonb_build_object('id',id,'cell_id',cell_id,
 'cell_version',cell_version,'started_at',started_at,'frozen',frozen,
 'status',status,'truncated',truncated,'result',result) ORDER BY id)
 FROM estudo.notebook_runs WHERE id IN (""" + ','.join(map(str, ids)) + ") AND frozen))::text AS payload"
document = reader.query(sql)
assert len(document['runs']) == len(ids), 'Missing baseline execution'
out = W / 'baseline-runs'
out.mkdir(exist_ok=True)
for run in document['runs']:
    (out / f"{run['cell_id']}.json").write_text(json.dumps(run, ensure_ascii=False, indent=2))
    if int(run['cell_id']) == 251:
        payload = run['result']['rows'][0]['payload']
        (W / 'baseline-2026-payload.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2))
print(json.dumps({'baseline_count':len(ids),'output':str(out)}, ensure_ascii=False))
