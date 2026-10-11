import json,sys
from pathlib import Path
from urllib.parse import urlsplit
p=Path(__file__).resolve().parent
r=json.loads((p/(sys.argv[1]+'.json')).read_text());issues=json.loads((p/'issues.json').read_text());by={x['url']:x for x in r}; failures=[]
for x in r:
 if x.get('status')!=200:failures.append('HTTP: '+x['url']);continue
 if '?page=' in x['url'] and not all(urlsplit(a).query==urlsplit(x['url']).query for a in x['alternates'].values()):failures.append('hreflang page mismatch: '+x['url'])
for issue,key in [('6','title'),('15','description')]:
 values=[str(by[x['source_url']][key]) for x in issues[issue]['data']['data']]
 if len(set(values))!=len(values):failures.append('Duplicate '+key+': '+str(len(values)-len(set(values))))
sitemap=by['https://roadrunners.run/sitemaps/news-recent.xml'].get('locs',[])
for x in issues['18']['data']['data']:
 if x['target_url'] in sitemap:failures.append('Noncanonical sitemap URL: '+x['target_url'])
print(json.dumps({'pages_checked':len(r),'failures':failures},ensure_ascii=False,indent=2))
sys.exit(bool(failures))
