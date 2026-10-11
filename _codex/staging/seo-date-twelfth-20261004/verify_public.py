from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,re,subprocess,sys,html
s=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
events=json.loads((s/'baseline-data.json').read_text())['events'];changes=json.loads((s/'changes.json').read_text())
cases=[{'id':e['id_evento'],'url':'https://roadrunners.run/'+prefix+'/'+e['tag']+'/','lang':lang} for e in events for prefix,lang in [('evento','pt-br'),('en/event','en'),('es/evento','es')]]
if len(sys.argv)>2:
 selected=set(map(int,sys.argv[2].split(',')))
 pairs=[(i,c) for i,c in enumerate(cases) if c['id'] in selected]
else:pairs=list(enumerate(cases))
def metadata(h):
 return {'canonical':re.findall(r'<link[^>]*rel="canonical"[^>]*>',h),'alternates':re.findall(r'<link[^>]*hreflang[^>]*>',h),'jsonld':[json.loads(x) for x in re.findall(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',h,re.I|re.S)]}
def run(pair):
 i,c=pair;cp=subprocess.run(['curl','-sS','--max-time','40','-w','\n%{http_code}',c['url']],capture_output=True,text=True);h,code=cp.stdout.rsplit('\n',1);m=metadata(h);checks={'http200':code=='200','no_cf_error':'Error Occurred While Processing Request' not in h,'canonical_present':len(m['canonical'])==1,'jsonld_present':len(m['jsonld'])>0}
 if mode=='after':
  expected=json.loads((s/f'metadata-before-{i}.json').read_text())
  if str(c['id']) in changes['events']:
   patch=changes['events'][str(c['id'])];before=next(e for e in events if e['id_evento']==c['id'])
   def expected_dates(node):
    if isinstance(node,list):return [expected_dates(v) for v in node]
    if isinstance(node,dict):
     node={k:expected_dates(v) for k,v in node.items()}
     if node.get('@type') in ['Event','SportsEvent']:
      if 'data_inicial' in patch and 'description' in node:
       assert c['id']==37769, 'A new event needs its own reviewed description expectation'
       node['description'],count=re.subn(r'\b21(\s+(?:novembro|november|noviembre))\b',r'22\1',node['description'])
       assert count==1, 'Expected exactly one date phrase in Palmas description'
      for key,field in [('startDate','data_inicial'),('endDate','data_final')]:
       if field in patch and key in node:
        assert node[key].startswith(before[field]),(key,node[key],before[field])
        node[key]=patch[field]+node[key][len(before[field]):]
     return node
    return node
   expected=expected_dates(expected)
  checks['metadata_expected']=m==expected
  rep=json.loads((s/'replacements.json').read_text()).get(str(c['id']))
  if rep:
   key='descricao' if c['lang']=='pt-br' else 'descricao_'+c['lang']
   if key not in rep:key='descricao'
   visible=html.unescape(html.unescape(h))
   for n,(old,new) in enumerate(rep[key]):checks['text_change_'+str(n)]=html.unescape(new) in visible and html.unescape(old) not in visible

  if str(c['id']) in changes['events'] and 'url_regulamento' in changes['events'][str(c['id'])]:checks['regulation_visible']=changes['events'][str(c['id'])]['url_regulamento'] in html.unescape(h)
 else:(s/f'metadata-before-{i}.json').write_text(json.dumps(m,ensure_ascii=False,indent=2))
 return {**c,'http':code,'checks':checks}
with ThreadPoolExecutor(max_workers=3) as pool:rows=list(pool.map(run,pairs))
if len(sys.argv)>2:
 previous=json.loads((s/f'public-{mode}.json').read_text());by_url={x['url']:x for x in previous}
 for row in rows:by_url[row['url']]=row
 rows=[by_url[c['url']] for c in cases]
(s/f'public-{mode}.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False));fails=[x for x in rows if not all(x['checks'].values())];print(json.dumps({'urls':len(rows),'failed':fails}));assert not fails
