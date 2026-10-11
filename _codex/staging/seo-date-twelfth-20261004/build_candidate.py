from pathlib import Path
import json,hashlib
p=Path(__file__).resolve().parent;b=json.loads((p/'baseline-data.json').read_text())
facts={43140:('2026-11-08',[5],'RealTiming: 08.NOV.2026; CHÃ PRETA - AL; Categorias 5KM; no linked conflicting regulation'),43541:('2026-11-08',[6,3,2],'Trichip current page and updated regulation: Domingo 08/11/2026; kit 07/11; 6km,3km,2km'),45366:('2026-11-20',[21,5,10],'Official LIVE2026 Fortaleza source: 20/11; 21KM,5KM,10KM; program 5:15 and5:30; no competing date in current page'),43854:('2026-11-28',[5],'Oxys current page and current linked regulation: race28November2026 at20h; 5km. Old September refund cutoff is not a race-date statement.'),43166:('2026-11-29',[5,10,3],'Kmais header NOVA DATA29November and current regulation ALTERAÇÃO DA DATA; all existing inscriptions valid;5km,10km,3km'),41908:('2026-12-06',[5],'Central current BlackRun page6December2026;5km;no conflicting regulation offered')}
links={43541:'https://www.trichip.com.br/painel/upload/doc/inscricao/doc-23-0d90d40c45b2fcde0689e6a73400dda6.pdf',43854:'https://www.oxyscrono.com.br/painel/upload/doc/inscricao/doc-017-24082026082940-7b1aeb59bfb3361ebb4d7ccc9d19ccc3.pdf',43166:'https://firebasestorage.googleapis.com/v0/b/kmais-app.appspot.com/o/pdfs%2F1788793065455_Regulameto%20FFSMS%20Corridas%202026.pdf?alt=media&token=b2ad35cc-770d-4c91-98cf-bd9ce8dfde67'}
c={'events':{str(k):{'url_regulamento':v} for k,v in links.items()},'routes':{}};reviews=[]
for e in b['events']:
 eid=e['id_evento'];date,distances,excerpt=facts[eid];assert e['data_inicial']==e['data_final']==date
 rows=[r for r in b['routes'] if r['id_evento']==eid]
 for r in rows:
  assert r['percurso_evento'] in distances and r['unidade_de_medida']=='km' and r['data_percurso']!=date
  c['routes'][str(r['id_evento_percurso'])]={'data_percurso':date,'percurso_bloqueado':True}
 review={'id':eid,'date':date,'distances_km':distances,'source':e['url_hotsite'] or e['url_inscricao'],'excerpt':excerpt,'checked_date':'2026-10-04','method':'visible official DOM; current regulation when provided','route_ids':[r['id_evento_percurso'] for r in rows]}
 if eid in links:
  f={43541:'apaex-current.pdf',43854:'anabolica-current.pdf',43166:'ffsms-current.pdf'}[eid];review['current_regulation']=links[eid];review['regulation_sha256']=hashlib.sha256((p/f).read_bytes()).hexdigest();assert e['url_regulamento']!=links[eid]
 reviews.append(review)
assert len(c['routes'])==12 and len(c['events'])==3
(p/'changes.json').write_text(json.dumps(c,ensure_ascii=False,indent=2));(p/'source-review.json').write_text(json.dumps({'selected':reviews,'excluded':[{'id':40891,'reason':'Current October25 header conflicts with current linked regulation August16.'},{'id':47272,'reason':'Current November22 header conflicts with current linked regulation September27.'},{'id':43831,'reason':'Header/kit dates November15 but currently linked DOCX raceSeptember20.'},{'id':43860,'reason':'HeaderDecember20 but retified linked DOCX raceNovember15.'},{'id':42042,'reason':'Official program says20–21November; exact course-day allocation remains unconfirmed, especiallyOpenTrail.'}]},ensure_ascii=False,indent=2))
print(json.dumps({'events':6,'routes':12,'regulation_links':3}))
