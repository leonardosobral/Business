from pathlib import Path
import json,re
p=Path(__file__).resolve().parent;dest=p/'candidate/evento/parts'
raw=(p/'baseline/evento/parts/fact_review_data.cfm').read_text();reviews=json.loads(re.search(r"deserializeJSON\('(.*)'\)",raw).group(1))
nexts=json.loads((p.parent/'seo-date-next-20261004/source-review.json').read_text())
for x in nexts['events']:
 reviews[str(x['id'])]={'startDate':x['confirmed_date'],'endDate':x['confirmed_date'],'checkedAt':'2026-10-04','sourceUrl':x['source'],'sourceLabel':{37570:'LIVE! RUN',40745:'Running Land',42288:'Brasil Corrida',45413:'Ticket Sports'}[x['id']]}
history={}
for stage in ['seo-date-priority-20261004','seo-date-next-20261004']:
 s=p.parent/stage;b=json.loads((s/'baseline-data.json').read_text());patch=json.loads((s/'changes.json').read_text());published=json.loads((s/'verify.json').read_text());assert published['verified']
 for e in b['events']:
  eid=str(e['id_evento'])
  if eid not in reviews:continue
  review=reviews[eid];groups={}
  for r in b['routes']:
   if str(r['id_evento'])!=eid:continue
   change=patch['routes'].get(str(r['id_evento_percurso']),{});after=change.get('data_percurso',r['data_percurso'])
   if after==r['data_percurso']:continue
   groups.setdefault((r['data_percurso'],after),[]).append(str(r['percurso_evento'])+' '+r['unidade_de_medida'])
  for (before,after),distances in groups.items():
   history.setdefault(eid,[]).append({'recordedAt':'2026-10-04','field':'routeDate','detail':', '.join(distances),'before':before,'after':after,'sourceUrl':review['sourceUrl'],'sourceLabel':review['sourceLabel']})
history['42288'].append({'recordedAt':'2026-10-04','field':'descriptionDate','detail':'','before':'2026-11-15','after':'2026-11-22','sourceUrl':reviews['42288']['sourceUrl'],'sourceLabel':reviews['42288']['sourceLabel']})
assert len(reviews)==8 and len(history)==8 and sum(map(len,history.values()))==9
prefix='<cfprocessingdirective pageencoding="utf-8"/>\n<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>\n'
def datafile(name,var,data,comment):
 text=json.dumps(data,ensure_ascii=False).replace('#','##').replace("'","''")
 (dest/name).write_text(prefix+'<!--- '+comment+' --->\n<cfset VARIABLES.'+var+" = deserializeJSON('"+text+"')/>\n")
datafile('fact_review_data.cfm','eventFactReviews',reviews,'Recibos manuais de conferência de datas. Só cadastrar após comprovação documentada; processamento automático não equivale a revisão.')
datafile('fact_history_data.cfm','eventFactHistory',history,'Histórico curado de valores corrigidos no RoadRunners. Não implica adiamento da prova nem confirmação do cadastro atual. Preservar registros anteriores; não incluir dados de atletas ou operadores.')
(p/'source-receipts.json').write_text(json.dumps({'reviews':reviews,'history':history},ensure_ascii=False,indent=2))
print('8 reviewed events, 9 historical entries derived from published guarded changes')
