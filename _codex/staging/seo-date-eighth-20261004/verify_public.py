from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,re,subprocess,sys,html
s=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
events=json.loads((s/'baseline-data.json').read_text())['events'];changes=json.loads((s/'changes.json').read_text())
cases=[{'id':e['id_evento'],'url':'https://roadrunners.run/'+prefix+'/'+e['tag']+'/','lang':lang} for e in events for prefix,lang in [('evento','pt-br'),('en/event','en'),('es/evento','es')]]
def metadata(h):
 return {'canonical':re.findall(r'<link[^>]*rel="canonical"[^>]*>',h),'alternates':re.findall(r'<link[^>]*hreflang[^>]*>',h),'jsonld':[json.loads(x) for x in re.findall(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',h,re.I|re.S)]}
def run(pair):
 i,c=pair;cp=subprocess.run(['curl','-sS','--max-time','40','-w','\n%{http_code}',c['url']],capture_output=True,text=True);h,code=cp.stdout.rsplit('\n',1);(s/f'public-{mode}-{i}.html').write_text(h);m=metadata(h);checks={'http200':code=='200','no_cf_error':'Error Occurred While Processing Request' not in h,'canonical_present':len(m['canonical'])==1,'jsonld_present':len(m['jsonld'])>0}
 if mode=='after':
  expected=json.loads((s/f'metadata-before-{i}.json').read_text())
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
with ThreadPoolExecutor(max_workers=3) as pool:rows=list(pool.map(run,enumerate(cases)))
(s/f'public-{mode}.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False));fails=[x for x in rows if not all(x['checks'].values())];print(json.dumps({'urls':len(rows),'failed':fails}));assert not fails
