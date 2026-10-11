from pathlib import Path
import json
S=Path(__file__).resolve().parent;n='includes/estrutura/header_tema.cfm'
s=(S/'baseline/rr'/n).read_text();old='listFind("/org/,/timer/,/circuito/", VARIABLES.template)';assert s.count(old)==1
(S/'candidate/rr'/n).write_text(s.replace(old,'listFind("/org/,/timer/,/circuito/,/maratona/", VARIABLES.template)'))
r=json.loads((S/'inspection.json').read_text());tags=[m for m in r['catalog']['marathons'] if m['tag']];print(json.dumps({'runtime_files':1,'marathon_routes_with_tag':len(tags),'theme_branches':sorted(set('logo' if m['theme_id']>1 else 'fallback' for m in tags))}))
