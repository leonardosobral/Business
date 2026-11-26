"""Evidence-backed deltas and editorial review queue; no database connection."""
from pathlib import Path
import csv,json,sys
W=Path(__file__).resolve().parent;sys.path.insert(0,str(W));import derive
old=json.loads((W/'baseline/data.json').read_text());runs=derive.runs()
def rows(c):return runs[c]['result']['rows']
def payload(c):
 v=rows(c)[0]['payload'];return json.loads(v)if isinstance(v,str)else v
report={'published':False,'cutoff':'2026-09-30','load':derive.SNAPSHOT['load'],'sources':{str(c):{'run':r['id'],'revision':r['cell_version'],'started_at':r.get('started_at')}for c,r in runs.items()if c in derive.CELLS},'years':{},'issues':[],'lineage_correction':'Intermediate derived freezes using historical2025 references were superseded; retained in attempt-history. Final SQL uses original→new source mapping, checked by regression tests.'}
queue=[]
for y,inv,sel,detail,age in [('2025',425,427,436,441),('2026',426,428,437,442)]:
 prev={r['id_evento']:r for r in old['years'][y]['inventory']};current={r['id_evento']:r for r in rows(inv)}
 selection=rows(sel);sel_ids={r['id_evento']for r in selection if r.get('decisao','selecionada')=='selecionada'}
 old_sel={r['id_evento']for r in old['years'][y]['races']};assert sel_ids==old_sel
 new=[current[i]for i in sorted(set(current)-set(prev))];missing=[prev[i]for i in sorted(set(prev)-set(current))]
 keys=['participacoes','feminino','masculino','sub3','sub4','id_agrega_evento','ranking','tipo_corrida','data_final','modalidades']
 changed=[{'id_evento':i,'name':current[i]['nome_evento'],'changes':{k:{'before':prev[i].get(k),'after':current[i].get(k)}for k in keys if prev[i].get(k)!=current[i].get(k)}}for i in sorted(set(prev)&set(current))if any(prev[i].get(k)!=current[i].get(k)for k in keys)]
 for r in new:queue.append({'year':y,'id_evento':r['id_evento'],'name':r['nome_evento'],'date':r['data_final'],'eligible':r['participacoes'],'ranking':r['ranking'],'reason':'New inventory candidate outside preserved editorial whitelist; identity/distance/modalities/source require review','approved':False})
 for r in selection:
  if r.get('decisao','selecionada')!='selecionada'and current[r['id_evento']]['participacoes']>0:
   queue.append({'year':y,'id_evento':r['id_evento'],'name':r['nome_evento'],'date':r['data_final'],'eligible':current[r['id_evento']]['participacoes'],'ranking':current[r['id_evento']]['ranking'],'reason':'Explicit prior exclusion preserved: '+r['decisao'],'approved':False})
 p=payload(detail);a=payload(age);profile_total=sum(r['total']for r in a['provas']);raw_total=sum(r['total']for r in p['provas'])
 editorial=raw_total
 if y=='2026':editorial=raw_total-next(r['total']for r in p['provas']if r['id_evento']==34529)+3592
 report['years'][y]={'inventory_before':len(prev),'inventory_after':len(current),'new_candidates':new,'missing_candidates':missing,'changed_existing_candidates':changed,'curation_preserved':True,'selected_events':len(sel_ids),'editorial_before':old['notes'][y]['official_total'],'editorial_after':editorial,'profile_before':old['notes'][y]['profile_total'],'profile_after':profile_total,'age_missing_before':old['age_audit'][y]['totals']['sem_informacao'],'age_missing_after':sum(r['sem_informacao']for r in a['provas'])}
 if missing:report['issues'].append({'year':y,'kind':'missing_inventory_candidates','ids':[r['id_evento']for r in missing]})
report['adoption_before']=old['brasil_gigante']['adoption'];report['adoption_after']=payload(452)
report['paired_2025_2026']=payload(429)['coorte'];report['paired_2024_2025']=payload(446)['coorte']
report['editorial_queue']=queue
(W/'delta-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
with (W/'editorial-review-queue.csv').open('w',encoding='utf-8-sig',newline='')as f:
 out=csv.DictWriter(f,fieldnames=list(queue[0]),delimiter=';');out.writeheader();out.writerows(queue)
print(json.dumps({'years':{y:{k:v for k,v in section.items()if k in ['inventory_before','inventory_after','selected_events','editorial_before','editorial_after','profile_before','profile_after','age_missing_before','age_missing_after']}for y,section in report['years'].items()},'review_queue':len(queue),'issues':report['issues']},ensure_ascii=False,indent=2))
