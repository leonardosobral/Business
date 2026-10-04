"""Update curated items only from a matching immutable audit and public proof."""
from pathlib import Path
from datetime import datetime,timezone
from zoneinfo import ZoneInfo
import json,re,sys
STAGE=Path(__file__).resolve().parent
snapshot=json.loads((STAGE/'snapshot.json').read_text())
rr=next(s for s in snapshot['sites'] if s['id']=='roadrunners')
expected={'https://roadrunners.run'+p for p in ['/sobre/','/en/about/','/es/sobre/','/ajuda/','/en/help/','/es/ayuda/','/privacidade/','/en/privacy/','/es/privacidad/']}
preview='--preview' in sys.argv
verified=False
if not preview:
 try:public=json.loads((STAGE/'public-verification.json').read_text());audit=json.loads((STAGE/'audit-verification.json').read_text())
 except FileNotFoundError as e:raise RuntimeError('Institutional verification evidence missing') from e
 rows=[p for p in public.get('pages',[]) if p.get('kind')=='institutional']
 if not public.get('ok') or len(rows)!=9 or {p.get('url') for p in rows}!=expected or any(p.get('ok') is not True for p in rows):raise RuntimeError('Institutional public verification must confirm nine destinations')
 if audit.get('runId')!=rr['runId'] or audit.get('auditAt')!=rr['auditAt'] or len(audit.get('institutional',[]))!=9 or {p.get('url') for p in audit['institutional']}!=expected or any(p.get('status')!='pass' for p in audit['institutional']):raise RuntimeError('Institutional audit must confirm all nine destinations in this run')
 if datetime.fromisoformat(rr['auditAt'].replace('Z','+00:00'))<=datetime.fromisoformat(public['checked_at_utc'].replace('Z','+00:00')):raise RuntimeError('Require an audit after public verification')
 # Policy evidence and all six delivered versions must be available before claiming technical news completion.
 policy=json.loads((STAGE/'editorial-policy-verification.json').read_text())
 news=[p for p in public['pages'] if p.get('kind')=='external_news']
 if len(policy.get('records',[]))!=2 or len(news)!=6 or any(p.get('ok') is not True for p in news):raise RuntimeError('News policy/public evidence missing')
 marathon=json.loads((STAGE/'marathons/public-verification.json').read_text())
 if marathon.get('url')!='https://roadrunners.run/maratonas/' or marathon.get('ok') is not True or marathon.get('h1_count')!=1 or audit.get('marathons')!={'url':'https://roadrunners.run/maratonas/','status':'pass','h1_count':1}:raise RuntimeError('Marathons public/audit evidence missing')
 if datetime.fromisoformat(rr['auditAt'].replace('Z','+00:00'))<=datetime.fromisoformat(marathon['checked_at_utc'].replace('Z','+00:00')):raise RuntimeError('Require an audit after marathon public verification')
 verified=True
data=(STAGE/'baseline/Business/portal/includes/seo_queue_data.cfm').read_text()
def quoted(value):return '"'+str(value).replace('#','##').replace('"','""')+'"'
parts=re.split(r'(?m)(?=^            resolved = (?:true|false),\n            id = ")',data)
if len(parts)!=15:raise RuntimeError('Expected fourteen separately bounded queue items')
def update_item(id,field,value):
 matches=[i for i,p in enumerate(parts) if re.search(r'\bid = "'+re.escape(id)+r'"',p)]
 if len(matches)!=1:raise RuntimeError('Missing/duplicate queue item '+id)
 i=matches[0];pattern=r'(\b'+re.escape(field)+r' = )'+(r'(?:true|false)' if isinstance(value,bool) else r'"(?:[^"]|"")*"')
 parts[i],count=re.subn(pattern,lambda m:m[1]+(str(value).lower() if isinstance(value,bool) else quoted(value)),parts[i],count=1)
 if count!=1:raise RuntimeError('Missing queue field '+id+'/'+field)
update_item('RR-09','resolved',verified)
update_item('RR-09','evidence','Sobre, Ajuda e Privacidade identificam a rota também em PT. Testes CFML RED → GREEN cobrem nove destinos, preservando o conteúdo institucional. '+('Publicação conferida em nove URLs públicas: HTTP 200 direto, canonical próprio, PT/EN/ES e x-default; a auditoria posterior confirma reciprocidade aprovada em todas.' if verified else 'Candidato preparado; a conclusão exige verificação pública e auditoria posterior.'))
update_item('RR-09','stateLabel','Corrigido e rechecado em 03/10/2026' if verified else 'Correção preparada; publicação pendente')
update_item('RR-08','summary','Links de idioma ajustados à regra editorial de canonical na fonte. O cadastro do canal ainda tem campos editoriais divergentes.')
update_item('RR-08','evidence','A API pública confirma original_url Corrida no Ar e publication_mode=licensed_full para as duas notícias; authorized_republication=false e license_expires_at=null também estão cadastrados. A regra de canonical na fonte foi preservada. O head omite hreflang quando esse canonical difere do próprio, mantendo a navegação de idiomas e o noindex existente de external_only. '+('As seis versões públicas foram verificadas; doze páginas de controle, incluindo as três versões da notícia própria, preservam seus alternates.' if verified else 'Verificação pública das seis versões ainda pendente.'))
update_item('RR-08','acceptance','A coerência técnica dos alternates foi corrigida. Conferir com o responsável editorial o modo de publicação, a autorização cadastrada e a política de canonical/idiomas; só depois alterar a atribuição à fonte. A API não comprova licença de reprodução.')
update_item('RR-08','stateLabel','Alternates corrigidos; cadastro editorial pendente' if verified else 'Ajuste técnico preparado; cadastro editorial pendente')
update_item('RR-08','resolved',False)
facts=[]
for site in snapshot['sites']:
 check=next(c for c in site['aiChecks'] if c['id']=='event-fields')
 facts.append(f"{site['label']}: {check['pass']+check['warning']+check['error']} páginas avaliadas para campos de eventos, {check['warning']+check['error']} com lacunas que pedem revisão")
update_item('SH-02','evidence','Auditorias datadas no painel: '+ '; '.join(facts)+'. A checagem cobre nome, data válida, local e organizador, além de nome/cidade no texto; não comprova exatidão factual. A consulta anterior encontrou organizador nomeado em apenas 1.332 de 34.320 eventos ativos do cadastro compartilhado. Não usar cronometrador como organizador nem inferir dados ausentes.')
data=''.join(parts)
extra='''        ,{
            resolved = MARATHON_RESOLVED,
            id = "RR-10",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Estrutura",
            title = "Identificar o título principal de Maratonas",
            summary = "O título visível Maratonas do Brasil passou de h3 para h1, preservando a aparência existente.",
            impact = "A página pública passa a identificar o seu título principal depois da correção do slogan compartilhado.",
            owner = "RoadRunners — página de Maratonas",
            rule = "h1.missing",
            evidence = "A auditoria ampliada encontrou HTTP 200 e nenhum H1 em /maratonas/. Teste RED → GREEN verifica o título; a alteração é somente h1 class=h3 e seu fechamento. MARATHON_EVIDENCE",
            acceptance = "HTTP 200 direto, canonical próprio e um H1 no HTML público, preservando texto, consultas, filtros, autenticação e aparência.",
            urls = [{url = "https://roadrunners.run/maratonas/", label = "Maratonas do Brasil"}],
            stateLabel = "MARATHON_STATE"
        }
'''
extra=extra.replace('MARATHON_RESOLVED',str(verified).lower()).replace('MARATHON_EVIDENCE','Publicado e rechecado no HTML público; a auditoria posterior do mesmo snapshot confirma um H1.' if verified else 'Verificação pública e auditoria posterior ainda pendentes.').replace('MARATHON_STATE','Corrigido e rechecado em 03/10/2026' if verified else 'Correção preparada; publicação pendente')
index=data.rfind('    ]\n};');assert index>0;data=data[:index]+extra+data[index:]
runs=[]
for site in snapshot['sites']:
 note=site['coverageNote']+' Descoberta completa dos sitemaps; sem nova reconciliação com o banco. O histórico informa mudança de amostra quando necessário.'
 if site['id']=='roadrunners':
  note+=' O 404 é de notícia retirada editorialmente, ausente do sitemap. A amostra inclui rotas privadas com login intencional, notícias com canonical na fonte e diferenças na caixa de escapes percentuais; os avisos técnicos brutos continuam visíveis. Sobre, Ajuda e Privacidade e as duas notícias têm cobertura estratégica nos três idiomas.'
  note+=' Maratonas tem seu H1 corrigido e rechecado.' if verified else ' Maratonas: correção preparada; verificação pendente.'
 fields={'siteId':site['id'],'label':site['label'],'auditLabel':site['auditLabel'],'completionLabel':'Amostra concluída','discoveryComplete':site['discoveryComplete'],'discovered':site['discovered'],'inspected':site['inspected'],'operationalErrors':site['operationalErrors'],'pageErrors':site['pageErrors'],'warnings':site['warnings'],'coverageNote':note}
 runs.append('        {\n'+',\n'.join('            '+k+' = '+(quoted(v) if isinstance(v,str) else str(v).lower() if isinstance(v,bool) else str(v)) for k,v in fields.items())+'\n        }')
data,count=re.subn(r'    runs = \[[\s\S]*?\n    \],\n    items =',lambda m:'    runs = [\n'+',\n'.join(runs)+'\n    ],\n    items =',data,count=1);assert count==1
now=datetime.now(timezone.utc)
data=re.sub(r'updatedAt = "[^"]*"','updatedAt = '+quoted(now.isoformat().replace('+00:00','Z')),data,count=1)
data=re.sub(r'updatedLabel = "[^"]*"','updatedLabel = '+quoted(now.astimezone(ZoneInfo('America/Sao_Paulo')).strftime('%d/%m/%Y às %H:%M (Brasília)')),data,count=1)
data=data.replace('_codex/docs/2026-10-03_seo_idiomas.md','_codex/docs/2026-10-03_seo_institucional.md')
target=STAGE/'candidate/portal/includes/seo_queue_data.cfm';target.parent.mkdir(parents=True,exist_ok=True);target.write_text(data)
print(json.dumps({'institutional_verified':verified,'items':len(re.findall(r'\bid = "',data)),'resolved':len(re.findall(r'\bresolved = true',data))}))
