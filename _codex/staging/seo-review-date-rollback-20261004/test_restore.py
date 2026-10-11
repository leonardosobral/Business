from pathlib import Path
import json,sys,hashlib
s=Path(__file__).resolve().parent;mode=sys.argv[1];f=json.loads((s/'expected-source.json').read_text())
old=json.loads((s.parent/'seo-date-eleventh-20261004/baseline-data.json').read_text());live=json.loads((s/('baseline-data.json' if mode=='before' else 'after-data.json')).read_text())
original={r['id_evento_percurso']:r for r in old['routes'] if r['id_evento'] in f['restore_ids']};start=json.loads((s/'baseline-data.json').read_text());initial={r['id_evento_percurso']:r for r in start['routes']};tests={}
for r in live['routes']:
 target=original.get(r['id_evento_percurso'],initial[r['id_evento_percurso']]);tests['route_'+str(r['id_evento_percurso'])]=all(r[k]==target[k] for k in ['data_percurso','percurso_bloqueado'])
q2=next(e for e in live['events'] if e['id_evento']==39867)
for k,v in f['q2'].items():tests['q2_'+k]=q2[k]==v
if mode=='after':
 for lang in ['en','es']:
  m=q2['descricao_traducoes_meta'][lang];tests['translation_'+lang]=m['source_hash']==hashlib.md5(q2['descricao'].encode()).hexdigest() and m['description_hash']==hashlib.md5(q2['descricao_'+lang].encode()).hexdigest()
passed=all(tests.values());(s/('red.json' if mode=='before' else 'green.json')).write_text(json.dumps({'passed':passed,'tests':tests},indent=2));print(json.dumps({'mode':mode,'checks':len(tests),'passed':passed}));assert passed
