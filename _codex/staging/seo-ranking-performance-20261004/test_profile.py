import json,sys
from pathlib import Path
s=Path(__file__).resolve().parent;mode=sys.argv[1]
p=json.loads((s/(mode+'-profile.json')).read_text());ms=p.get('execution_ms',p.get('EXECUTION_MS'))
assert ms<1500,f'Ranking SQL exceeded 1.5s budget: {ms:.1f}ms'
print(f'Ranking SQL latency passed: {ms:.1f}ms')
