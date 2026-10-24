"""Import only a completed, reviewed Semrush UI audit; preserve dated organic data."""
from pathlib import Path
import base64,copy,hashlib,importlib.util,json,re
S=Path(__file__).resolve().parent; B=S.parents[3]
spec=importlib.util.spec_from_file_location('snapshot',B/'_codex/scripts/seo_semrush_snapshot.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
f=S/'source-final.json'
assert f.exists(),'Aguardar o resultado concluído da campanha; não fabricar fonte MCP/UI.'
a=json.loads(f.read_text())
assert a['source']=='Semrush — interface autenticada no Chrome'
assert a['domain']=='roadrunners.run' and a['projectId']==26661911
assert a['status']=='complete' and a['crawled']==a['limit']==5000
assert a['deviceLabel']=='Móvel' and a['javascriptRendered'] is False
assert a['sourceUrl'].startswith('https://pt.semrush.com/siteaudit/campaign/26661911/')
assert 0<=(m.date(a['checkedAt'])-m.date(a['lastFinishedAt'])).total_seconds()<86400
for k in ['errors','warnings','notices','siteHealth','aiHealth']:
 assert type(a[k]) is int and a[k]>=0,k
assert a['siteHealth']<=100 and a['aiHealth']<=100
assert sum(i['count'] for i in a['errorsByType'])==a['errors']
assert sum(i['count'] for i in a['warningsByType'])<=a['warnings']
for k in ['errorsByType','warningsByType']:
 assert all(type(i['count']) is int and i['count']>=0 and isinstance(i['label'],str) for i in a[k])
raw=(S/'baseline/portal/includes/seo_semrush_data.cfm').read_text()
snapshot=json.loads(base64.b64decode(re.search(r'binaryDecode\("([A-Za-z0-9+/=]+)"',raw)[1]))
organic=copy.deepcopy({k:v for k,v in snapshot.items() if k!='audit'});old=snapshot['audit']
# Baseline read in the same campaign before this run; no inferred fixed/new classifications.
previous=json.loads((S/'previous-ui.json').read_text())
assert previous['projectId']==a['projectId'] and previous['crawled']==previous['limit']==5000
assert previous['completedAuditDate']=='2026-10-22' and previous['deviceLabel']==a['deviceLabel']
assert previous['javascriptRendered'] is a['javascriptRendered'] is False
assert previous['status']=='complete'
a={k:v for k,v in a.items() if k!='domain'}
a.update(checkedLabel=m.label(a['checkedAt']),lastFinishedLabel=m.label(a['lastFinishedAt']),previous=previous,previousPanelSnapshot=old)
ui=a.pop('comparisonUI',None)
rows=[]
def comparison_row(label,before,current,fixed=None,new=None,higher=False):
 d=current-before
 return {'label':label,'previous':before,'current':current,'fixedLabel':'—' if fixed is None else str(fixed),'newLabel':'—' if new is None else str(new),'deltaLabel':('+' if d>0 else '')+str(d),'tone':'unknown' if not d else ('pass' if d*(1 if higher else -1)>0 else 'warning')}
for key,label,higher,metric in [('siteHealth','Site Health (%)',True,'g2'),('aiHealth','Estado de pesquisa IA (%)',True,None),('errors','Ocorrências de erro',False,'g4'),('warnings','Advertências',False,'g5'),('notices','Observações',False,'g6')]:
 fixed=new=None
 if ui and metric:
  x=ui['metrics'][metric];assert x['previous']==previous[key] and x['current']==a[key]
  fixed=x['fixed'];new=x['new']
 rows.append(comparison_row(label,previous[key],a[key],fixed,new,higher))
if ui:
 for group in ['errors','warnings']:
  for x in ui[group]:
   if group=='errors' and (x['previous'] or x['current']) or group=='warnings' and x['issueId'] in (109,112,135):
    rows.append(comparison_row(x['label'],x['previous'],x['current'],x['fixed'],x['new']))
a['comparison']={'previousLabel':previous['lastFinishedLabel'],'currentLabel':a['lastFinishedLabel'],'note':'Mesmo limite de 5.000 páginas, rastreador móvel e JavaScript desativado. O conjunto efetivo de URLs pode mudar; corrigidos e novos são as classificações informadas no comparativo Semrush. Não é uma medição de ranking ou indexação.','rows':rows}
snapshot['audit']=a
assert organic=={k:v for k,v in snapshot.items() if k!='audit'}
out=S/'candidate/portal/includes/seo_semrush_data.cfm';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(m.render_cfml(snapshot))
receipt={'projectId':26661911,'source':a['source'],'collectedAt':a['checkedAt'],'finishedAt':a['lastFinishedAt'],'siteHealth':a['siteHealth'],'errors':a['errors'],'warnings':a['warnings'],'notices':a['notices'],'organicCollectedAt':snapshot['collectedAt'],'keywords':len(snapshot['keywords']),'opportunities':len(snapshot['opportunities']),'organicPreserved':True,'sourceSha256':hashlib.sha256(f.read_bytes()).hexdigest()}
(S/'import-receipt.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2))
print(json.dumps(receipt,ensure_ascii=False))
