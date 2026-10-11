"""Import a reviewed UI audit without changing the dated organic MCP data."""
from pathlib import Path
import base64, copy, importlib.util, json, re

P=Path(__file__).resolve().parent
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business')
spec=importlib.util.spec_from_file_location('snapshot',ROOT/'_codex/scripts/seo_semrush_snapshot.py')
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
source=json.loads(Path('/private/tmp/seo-semrush-20261006-source.json').read_text())
assert source['domain']=='roadrunners.run' and source['projectId']==26661911
assert source['source']=='Semrush — interface autenticada no Chrome'
assert source['status']=='complete' and source['crawled']==source['limit']==5000
assert sum(x['count'] for x in source['errorsByType'])==source['errors']
assert sum(x['count'] for x in source['warningsByType'])==source['warnings']
assert sum(x['count'] for x in source['noticesByType'])==source['notices']
for name in ['errors','warnings','notices','siteHealth','aiHealth']:
    assert type(source[name]) is int and source[name]>=0
assert 0<=source['siteHealth']<=100 and 0<=source['aiHealth']<=100
assert source['deviceLabel']=='Móvel' and source['javascriptRendered'] is False
assert 0 <= (mod.date(source['checkedAt'])-mod.date(source['lastFinishedAt'])).total_seconds() < 86400
body=(P/'baseline/business/portal/includes/seo_semrush_data.cfm').read_text()
snapshot=json.loads(base64.b64decode(re.search(r'binaryDecode\("([A-Za-z0-9+/=]+)"',body)[1]))
organic=copy.deepcopy({k:v for k,v in snapshot.items() if k!='audit'})
old=snapshot['audit']
assert old['errors']==126 and old['crawled']==5000 and old['siteHealth']==69
audit={k:v for k,v in source.items() if k not in ['domain','status']}
audit.update(status='complete',checkedLabel=mod.label(source['checkedAt']),lastFinishedLabel=mod.label(source['lastFinishedAt']),previous=old)
audit['comparison']={
 'previousLabel':old['lastFinishedLabel'], 'currentLabel':audit['lastFinishedLabel'],
 'note':'As duas rodadas têm limite de 5.000 páginas, rastreador móvel e JavaScript sem renderização. O conjunto de URLs mudou, incluindo novas páginas da loja; a comparação de ocorrências não é uma medição de ranking ou indexação.',
 'rows':[]
}
comparisons=[('Site Health (%)',69,75,None,None,True),('Estado de pesquisa IA (%)',81,78,None,None,True),('Erros',126,27,112,13,False),('Advertências',37581,45495,12782,20696,False),('Observações',3455,2328,2066,939,False),('Páginas com títulos duplicados',62,6,62,6,False),('Páginas com conteúdo duplicado',8,0,8,0,False),('Links internos quebrados',35,12,24,1,False),('Páginas com HTTP 4xx',14,2,12,0,False),('Páginas com descrições duplicadas',4,6,4,6,False),('Página não rastreada',1,0,1,0,False),('Conflito hreflang',1,1,0,0,False),('Página lenta',1,0,1,0,False),('Redirecionamentos temporários',26249,27850,8147,9748,False),('Recursos sem minificação',6394,11995,2612,8213,False)]
for title,previous,current,fixed,new,higher_is_better in comparisons:
    if fixed is not None:assert previous-fixed+new==current
    delta=current-previous
    tone='pass' if delta*(1 if higher_is_better else -1)>0 else 'warning' if delta else 'unknown'
    audit['comparison']['rows'].append(dict(label=title,previous=previous,current=current,fixedLabel='—' if fixed is None else str(fixed),newLabel='—' if new is None else str(new),deltaLabel=('+' if delta>0 else '')+str(delta),tone=tone))
snapshot['audit']=audit
assert organic=={k:v for k,v in snapshot.items() if k!='audit'}
dest=P/'candidate/business/portal/includes/seo_semrush_data.cfm'
dest.write_text(mod.render_cfml(snapshot))
(P/'import-receipt.json').write_text(json.dumps({'projectId':source['projectId'],'source':source['source'],'collectedAt':source['checkedAt'],'finishedAt':source['lastFinishedAt'],'organicCollectedAt':snapshot['collectedAt'],'keywords':len(snapshot['keywords']),'opportunities':len(snapshot['opportunities']),'errorsBefore':old['errors'],'errors':audit['errors'],'warnings':audit['warnings'],'notices':audit['notices']},ensure_ascii=False,indent=2))
print(json.dumps({'auditImported':audit['status'],'errors':audit['errors'],'organicPreserved':True}))
