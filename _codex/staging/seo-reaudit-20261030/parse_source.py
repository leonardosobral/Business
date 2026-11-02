from pathlib import Path
from datetime import datetime,timezone
import json,re
S=Path(__file__).resolve().parent;rows=json.loads((S/'comparison-ui.rows.json').read_text());groups={'errors':[],'warnings':[],'notices':[]};metrics={};group=None
num=lambda s: None if s in ('','—') else int(s.replace(',','').replace('.',''))
for r in rows:
 cells=r['cells'];links=r['links']
 if cells[0] in ('Erros','Advertências','Avisos'):
  group={'Erros':'errors','Advertências':'warnings','Avisos':'notices'}[cells[0]];continue
 if len(cells)!=5:continue
 issue=next((x for x in links if '/issue/detail/' in x['href']),None)
 if issue and group:
  groups[group].append({'issueId':int(issue['href'].rsplit('/',1)[1]),'label':issue['text'],'previous':num(cells[1]),'current':num(cells[2]),'fixed':num(cells[3]),'new':num(cells[4])})
 metric=next((x for x in links if re.search(r'/history/id/g[1-6]$',x['href'])),None)
 if metric:metrics[metric['href'].rsplit('/',1)[1]]={'previous':num(cells[1]),'current':num(cells[2]),'fixed':num(cells[3]),'new':num(cells[4])}
for side in ['previous','current']:
 for g,m in [('errors','g4'),('warnings','g5'),('notices','g6')]:assert sum(x[side] for x in groups[g])==metrics[m][side],(side,g)
base={'source':'Semrush — interface autenticada no Chrome','projectId':26661911,'status':'complete','crawled':5000,'limit':5000,'deviceLabel':'Móvel','javascriptRendered':False,'sourceUrl':'https://pt.semrush.com/siteaudit/campaign/26661911/review/overview','finishedPrecision':'minute'}
def audit(side):
 out=base|{k:metrics[m][side] for k,m in [('siteHealth','g2'),('errors','g4'),('warnings','g5'),('notices','g6')]}
 for g in ['errors','warnings','notices']:out[g+'ByType']=[{'issueId':x['issueId'],'label':x['label'],'count':x[side]} for x in groups[g] if x[side]]
 return out
prev=audit('previous')|{'lastFinishedAt':'2026-10-25T02:40:00Z','lastFinishedLabel':'24/10/2026, 23:40 (Brasília)','completedAuditDate':'2026-10-24','aiHealth':80,'aiHealthSource':'Overview current 84% and reported delta +4 points.'}
cur=audit('current')|{'domain':'roadrunners.run','aiHealth':84,'checkedAt':datetime.now(timezone.utc).isoformat(),'lastFinishedAt':'2026-10-29T12:32:00Z','finishedDisplay':'29 out 2026 (09:32)','comparisonUrl':'https://pt.semrush.com/siteaudit/campaign/26661911/review/compare/overall_score','observedDetails':{'source':'Overview, completed crawl settings, full comparison UI and all 34 duplicate-description URLs captured on 30/10; group sums reconciled in both periods.','sameCrawlSettings':True},'comparisonUI':{'metrics':metrics,**groups}}
P=S/'panel';P.mkdir(exist_ok=True);(P/'previous-ui.json').write_text(json.dumps(prev,ensure_ascii=False,indent=2));(P/'source-final.json').write_text(json.dumps(cur,ensure_ascii=False,indent=2));(S/'comparison-ui.parsed.json').write_text(json.dumps({'metrics':metrics,**groups},ensure_ascii=False,indent=2))
print(json.dumps({'current':{k:cur[k] for k in ['siteHealth','aiHealth','errors','warnings','notices']},'previous':{k:prev[k] for k in ['siteHealth','errors','warnings','notices']},'typeCounts':{g:len(v) for g,v in groups.items()}}))
