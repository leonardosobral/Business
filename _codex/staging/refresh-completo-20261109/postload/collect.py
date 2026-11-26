"""Reuse the verified notebook runner with the freshly read post-load revisions."""
from pathlib import Path
import importlib.util
import json
import sys

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('verified_source_collector',W.parent/'collect.py')
collector=importlib.util.module_from_spec(spec);spec.loader.exec_module(collector)
collector.snapshot=json.loads((W/'notebook-current.json').read_text())
collector.cells={int(c['id']):c for c in collector.snapshot['cells']}
collector.DEST=W/'runs';collector.DEST.mkdir(exist_ok=True)
if __name__=='__main__':
    for cell in map(int,sys.argv[1:]):
        receipt=collector.collect(cell)
        run=receipt['run']
        if run['status']!='ok' or not run['frozen']:
            raise SystemExit('Stop: incomplete candidate for cell '+str(cell))
