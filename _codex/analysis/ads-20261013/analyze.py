from pathlib import Path
import json
P=Path(__file__).parent
raw=json.loads((P/'warehouse.json').read_text()); res={k:[{f.lower():v for f,v in r.items()} for r in q.get('rows',q.get('ROWS',[]))] for k,q in raw['results'].items()}
# Google Ads: valores da tabela Campanhas, lidos no navegador, fuso Brasília.
ads={'before':{'A':[34.62,63,653],'D':[26.65,48,489],'E':[26.91,61,502],'LIVE':[135.73,1458,23957],'C':[18.39,180,2625]},'after':{'A':[20.33,101,433],'D':[22.20,80,486],'E':[21.76,122,573],'LIVE':[100.46,956,13737],'C':[0,0,0]},'today':{'A':[3.91,37,94],'D':[2.70,14,88],'E':[4.89,32,195],'LIVE':[24.22,214,3283],'C':[0,0,0]}}
names={'A':'rr_teste_a_corridas_sc_202610','D':'rr_teste_d_corridas_maringa_202610','E':'rr_teste_e_corridas_interior_sp_202610','LIVE':'live_cupom_2026_retomada','C':'rr_teste_c_display_corridas_sc_202610'}
rows=[]
for period,groups in ads.items():
 for short,(cost,clicks,impressions) in groups.items():
  q=next((r for r in res[period+'_live_journey'] if r['row_type']=='campaign' and r['campaign']==names[short]),{})
  r={'period':period,'campaign':short,'cost_brl':cost,'clicks':clicks,'impressions':impressions,**{k:q.get(k,0) for k in ['sessions','pageviews','qualified_sessions','outbound_sessions']}}
  r['cost_qualified']=round(cost/r['qualified_sessions'],4) if r['qualified_sessions'] else None;r['cpc']=round(cost/clicks,4) if clicks else None
  rows.append(r)
assert round(sum(ads['after'][c][0] for c in ['A','D','E']),2)==64.29
assert sum(ads['after'][c][1] for c in ['A','D','E'])==303
(P/'analysis.json').write_text(json.dumps({'ads':ads,'metrics':rows,'google_conversion':{'period':'2026-10-01 a 2026-10-13','name':'RR | Saída para inscrição LIVE!','status':'Ativa','secondary':True,'all_conversions':20,'value':0}},ensure_ascii=False,indent=2))
for r in rows: print(json.dumps(r))
for c in ['A','D','E']:
 a=next(r for r in rows if r['period']=='before' and r['campaign']==c);b=next(r for r in rows if r['period']=='after' and r['campaign']==c)
 print(c,'cost_qualified_change',round(100*(b['cost_qualified']/a['cost_qualified']-1),1),'spent_total',round(sum(ads[p][c][0] for p in ads),2))
nb={'nbformat':4,'nbformat_minor':5,'metadata':{'kernelspec':{'display_name':'Python 3','language':'python','name':'python3'}},'cells':[{'cell_type':'markdown','metadata':{},'source':['# Reanálise Ads — 13/10/2026\nComparação descritiva de 2–8/10 com 9–12/10; hoje parcial separado. Não é experimento causal.\nFontes: tabela Google Ads e consultas readonly do Business em warehouse.json. Cliques de anúncios, sessões próprias, saídas LIVE! e inscrições são medidas distintas.']},{'cell_type':'code','metadata':{},'execution_count':None,'outputs':[],'source':['import json\nfrom pathlib import Path\nd = json.loads(Path("analysis.json").read_text())\nfor row in d["metrics"]:\n    print(row)']},{'cell_type':'code','metadata':{},'execution_count':None,'outputs':[],'source':['data=json.loads(Path("warehouse.json").read_text())\n# SQL exato e resultados preservados, sem dados de identificação pessoal.\nlist(data["queries"])']}]}
(P/'review.ipynb').write_text(json.dumps(nb,ensure_ascii=False,indent=2))
items=[]
for period in ['before','after','today']:
 periodlabel={'before':'2 a 8 de outubro de 2026','after':'9 a 12 de outubro de 2026','today':'13 de outubro de 2026, parcial'}[period]
 metrics=[r for r in rows if r['period']==period]
 queries=[{'id':'google-'+period,'source':{'label':'Google Ads — campanhas','links':[{'label':'Google Ads','url':'https://ads.google.com/aw/campaigns'}],'filters':['Fuso horário: Brasília','Campanhas da conta RunnerHub','Inclui campanhas pausadas com histórico']},'reportingPeriod':periodlabel,'columns':['campaign','cost_brl','clicks','impressions'],'rows':metrics}]
 for name in ['live_journey','advertiser_acquisition']:
  key=period+'_'+name
  chosen=[r for r in res[key] if r.get('source')=='google' and (name!='live_journey' or r.get('row_type')=='campaign')]
  columns=['campaign','sessions','pageviews','qualified_sessions','outbound_sessions'] if name=='live_journey' else ['campaign','advertiser_name','view_sessions','viewed_deliveries','clicked_deliveries']
  queries.append({'id':key.replace('_','-'),'source':{'label':'Business — '+name,'links':[{'label':'Audiência','url':'https://business.roadrunners.run/portal/audiencia/'}],'sql':raw['queries'][key],'caveats':['Sessões qualificadas: pelo menos 30 segundos ativos ou duas páginas distintas. Cliques e sessões não são inscrições.'] if name=='live_journey' else ['Exposição de 50% da peça por 1 segundo; cliques válidos deduplicados por entrega. Banners sem delivery_id e visitas sem campanha UTM não entram. Não somar sessões entre anunciantes como pessoas únicas.']},'reportingPeriod':periodlabel,'columns':columns,'rows':chosen,'preview':{'kind':'aggregate','note':'Agregados filtrados para Google e campanhas relevantes.'}})
 items.append({'id':period+'-performance','title':periodlabel,'queries':queries})
items.append({'id':'google-live-conversion','title':'Conversão de saída LIVE! ativa','queries':[{'id':'google-conversions','source':{'label':'Google Ads — todas as conversões','links':[{'label':'Conversões','url':'https://ads.google.com/aw/conversions/all'}],'caveats':['Conversão secundária: aparece em Todas as conv.; não é compra confirmada. Período distinto da tabela principal.']},'reportingPeriod':'1 a 13 de outubro de 2026','columns':['name','status','secondary','all_conversions','value'],'rows':[{'name':'RR | Saída para inscrição LIVE!','status':'Ativa','secondary':True,'all_conversions':20,'value':0}]}]})
(P/'sources.json').write_text(json.dumps({'schemaVersion':1,'items':items},ensure_ascii=False,indent=2))
