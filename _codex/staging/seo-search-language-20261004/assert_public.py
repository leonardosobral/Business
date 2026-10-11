from pathlib import Path
from urllib.parse import urlsplit
import json,sys
stage=Path(__file__).resolve().parent
r=json.loads((stage/(sys.argv[1]+'.json')).read_text());failures=[]
for x in r:
 if x.get('status')!=200:failures.append('HTTP '+x['url']);continue
 expected=x['url'].split('?')[0]
 if x['canonical']!=[expected]:failures.append('canonical '+x['url'])
 if urlsplit(x['url']).query:
  if x['alternates']:failures.append('Noncanonical search with alternates: '+x['url'])
 else:
  if len(x['alternates'])!=4 or expected not in x['alternates'].values():failures.append('Missing root cluster '+x['url'])
 if 'noindex' in ' '.join(x['robots']):failures.append('Unexpected noindex '+x['url'])
if sys.argv[1]!='before-public':
 before={x['url']:x for x in json.loads((stage/'before-public.json').read_text())}
 for x in r:
  for key in ['title','description','canonical','robots']:
   if x[key]!=before[x['url']][key]:failures.append('Changed '+key+' '+x['url'])
print(json.dumps({'checked':len(r),'failures':len(failures),'details':failures[:3]},ensure_ascii=False))
sys.exit(bool(failures))
