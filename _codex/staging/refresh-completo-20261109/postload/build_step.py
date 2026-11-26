"""Build a single next notebook cell using the merged immutable run receipts."""
from pathlib import Path
import importlib.util
import json
import sys

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('study_candidate_builder',W.parent/'build_candidate.py')
b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)

def runs():
    combined=b.load_runs(W.parent/'runs')
    combined.update(b.load_runs(W/'runs'))
    return combined

if __name__=='__main__':
    cell=int(sys.argv[1]);r=runs()
    if cell in (380,377):sql=b.build_derived(cell,r)
    elif cell==387:
        sql,pairs=b.build_pairs(r)
        (W/'pairs-full.json').write_text(b.dumps(pairs,indent=2))
    elif cell==414:
        baseline=json.loads((W.parent/'baseline-2026-payload.json').read_text())
        sql=b.build_themes(r,baseline)
    elif cell==251:
        sql=b.build_final(r)
        provenance_file=W/'build_provenance.py'
        if provenance_file.exists():
            ps=importlib.util.spec_from_file_location('postload_provenance',provenance_file)
            p=importlib.util.module_from_spec(ps);ps.loader.exec_module(p)
            source={
                'audit':json.loads((W.parent/'postload-audit/metadata.json').read_text())['audit'],
                'verification':json.loads((W.parent/'postload-audit/verification.json').read_text()),
            }
            sql=p.annotate_final(sql,r,source)
    elif cell==420:sql=b.build_public(r)
    elif cell==418:sql=b.build_annual(r)
    else:raise ValueError(cell)
    dest=W/'sql'/f'cell-{cell}.sql'
    assert not dest.exists(),'Inspect existing candidate before replacing it'
    dest.write_text(sql.rstrip()+'\n')
    (W/'merged-run-refs.json').write_text(json.dumps({str(c):{k:v[k] for k in ('id','cell_version','started_at') if k in v} for c,v in r.items()},ensure_ascii=False,indent=2))
    print(json.dumps({'cell':cell,'sql':str(dest),'sources':len(r),'published':False},ensure_ascii=False))
