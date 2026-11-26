"""Save reviewed derived SQL using the current post-load revisions."""
from pathlib import Path
import importlib.util
import shutil
import sys

W=Path(__file__).resolve().parent
# The original baseline remains immutable for reference remapping in the builder.
if not (W/'notebook-before.json').exists():
    shutil.copy2(W/'notebook-current.json',W/'notebook-before.json')
spec=importlib.util.spec_from_file_location('verified_derived_operator',W.parent/'save_collect.py')
operator=importlib.util.module_from_spec(spec);spec.loader.exec_module(operator)
operator.W=W
if not (W/'preflight.json').exists():shutil.copy2(W.parent/'preflight.json',W/'preflight.json')
if __name__=='__main__':operator.save_collect(int(sys.argv[1]),Path(sys.argv[2]))
