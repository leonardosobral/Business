"""Refresh the curated queue using the same immutable audit as the scorecard."""
from pathlib import Path
import json,re,sys
from datetime import datetime,timezone
STAGE=Path(__file__).resolve().parent
snapshot=json.loads((STAGE/'snapshot.json').read_text())
data=(STAGE/'baseline/portal/includes/seo_queue_data.cfm').read_text()
def quoted(value):return '"'+str(value).replace('#','##').replace('"','""')+'"'
def update_item(id,field,value):
 global data
 pattern=r'(id = "'+re.escape(id)+r'"[\s\S]*?\b'+re.escape(field)+r' = )"(?:[^"]|"")*"'
 data,count=re.subn(pattern,lambda m:m[1]+quoted(value),data,count=1)
 if count!=1:raise RuntimeError('Missing queue field '+id+'/'+field)
runs=[]
for site in snapshot['sites']:
 note=site['coverageNote']+' Descoberta completa dos sitemaps; sem nova reconciliação com o banco. O histórico informa mudança de amostra quando necessário.'
 if site['id']=='roadrunners':note+=' O 404 observado pertence à notícia retirada editorialmente, ausente do sitemap. A rechecagem também inclui três rotas privadas com login intencional, dois canonicals para fonte externa e um aviso por diferença de caixa nos escapes %0D/%0d. Os achados brutos e a nota técnica permanecem preservados.'
 runs.append('        {\n'+',\n'.join('            '+key+' = '+(quoted(value) if isinstance(value,str) else str(value).lower() if isinstance(value,bool) else str(value)) for key,value in {
  'siteId':site['id'],'label':site['label'],'auditLabel':site['auditLabel'],'completionLabel':'Amostra concluída','discoveryComplete':site['discoveryComplete'],'discovered':site['discovered'],'inspected':site['inspected'],'operationalErrors':site['operationalErrors'],'pageErrors':site['pageErrors'],'warnings':site['warnings'],'coverageNote':note}.items())+'\n        }')
data,count=re.subn(r'    runs = \[[\s\S]*?\n    \],\n    items =',lambda m:'    runs = [\n'+',\n'.join(runs)+'\n    ],\n    items =',data,count=1);assert count==1
now=datetime.now(timezone.utc);label=now.astimezone(__import__('zoneinfo').ZoneInfo('America/Sao_Paulo')).strftime('%d/%m/%Y às %H:%M (Brasília)')
data=re.sub(r'updatedAt = "[^"]*"','updatedAt = '+quoted(now.isoformat().replace('+00:00','Z')),data,count=1)
data=re.sub(r'updatedLabel = "[^"]*"','updatedLabel = '+quoted(label),data,count=1)
data=data.replace('em cache HIT com TTL de uma hora. A conclusão aguarda limpeza ou expiração desse cache.','em cache HIT. O cabeçalho anuncia max-age=3600, mas a versão antiga continuou com Age superior a 3600; isso não confirma o TTL efetivo da borda. A conclusão aguarda limpeza ou expiração efetiva desse cache.')
data=data.replace('última auditoria em _codex/docs/2026-09-29_seo_auditoria.md','última auditoria em _codex/docs/2026-10-03_seo_idiomas.md')
update_item('RR-01','acceptance','Concluído nos quatro casos: HTTP 200, evento e canonical corretos nos três idiomas, sem mudar tags ou o cadastro. Teste com Apache real confere caracteres especiais e preserva caminhos sensíveis. A auditoria de 03/10 rechecou Operário com HTTP 200; seu aviso de canonical compara %0D com %0d, equivalentes, e foi mantido como evidência da regra legada.')
update_item('OR-02','summary','As páginas individuais /resultados recebem noindex, follow. O robots correto está na origem, mas a Cloudflare ainda entrega a versão antiga com bloqueio; /perfil permanece bloqueado.')
update_item('RR-05','stateLabel','Retirada editorial confirmada; ausência no sitemap verificada')
update_item('RR-03','evidence','A correção de barras permanece validada. A nova auditoria de 03/10 incluiu a notícia de Gleison em PT/EN/ES, com canonical próprio e conjuntos hreflang recíprocos. Duas outras notícias continuam declarando a fonte Corrida no Ar como canonical externo; a intenção editorial foi separada no item RR-08, sem atribuir esse comportamento ao defeito de barras corrigido.')
update_item('SH-01','evidence','Conferência focal de 13 páginas e nova auditoria de 100 páginas por site em 03/10: busca Road Runners e home Open Results entregam H1. O slogan compartilhado é parágrafo nas páginas internas. As três URLs privadas de desafios, fora do sitemap e rechecadas intencionalmente, chegam ao login sem H1 e continuam gerando avisos brutos; não desfazem a correção dos templates públicos. Desktop, celular, compilação e teste CFML da estrutura foram verificados no lote anterior.')
update_item('SH-02','evidence','Auditoria de 03/10: 42 páginas de eventos Road Runners, com 41 casos que pedem revisão dos campos; 99 eventos Open Results, com 96 casos que pedem revisão. A checagem cobre nome, data válida, local e organizador, além de nome/cidade no texto, sem comprovar exatidão factual. O cadastro compartilhado consultado no lote anterior tem 34.320 eventos ativos, dos quais 1.332 possuem organizador nomeado nesse papel. Não usar cronometrador como organizador nem inferir dados ausentes.')
extra='''        ,{
            resolved = SEARCH_RESOLVED,
            id = "RR-07",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Idiomas",
            title = "Completar hreflang da busca em português",
            summary = "A busca precisa identificar a rota search para emitir os links de idioma também em português.",
            impact = "Permite que PT, EN e ES declarem o mesmo conjunto de alternates e os links de retorno.",
            owner = "RoadRunners — metadados da busca",
            rule = "hreflang-reciprocity",
            evidence = "A auditoria inicial de 03/10 encontrou quatro alternates em EN/ES e nenhum em PT. Uma linha no template identifica a rota, sem alterar filtros ou o bootstrap. Teste CFML falhou antes e passou nos três idiomas após a correção. A rechecagem pública e o snapshot após publicação registram o resultado real.",
            acceptance = "HTTP 200, canonical próprio, os três idiomas e x-default em todas as versões; termos e filtro de estado preservados. O teste de reciprocidade não comprova tradução do conteúdo.",
            urls = [{url = "https://roadrunners.run/busca/", label = "Busca em português"}, {url = "https://roadrunners.run/en/search/", label = "Busca em inglês"}, {url = "https://roadrunners.run/es/busqueda/", label = "Busca em espanhol"}],
            stateLabel = "SEARCH_STATE"
        },{
            resolved = false,
            id = "RR-08",
            sites = ["roadrunners"],
            priority = "review",
            priorityLabel = "Revisão editorial",
            title = "Conferir canonical externo nas notícias traduzidas",
            summary = "Duas notícias apontam para a fonte Corrida no Ar enquanto declaram versões próprias de idioma.",
            impact = "A atribuição à fonte pode ser intencional; decidir como as versões traduzidas devem participar da indexação antes de mudar o canonical.",
            owner = "RoadRunners — política editorial e atribuição à fonte",
            rule = "canonical.mismatch; hreflang-reciprocity",
            evidence = "Amostra de 03/10: os artigos sobre Nike e sobre trocas de camiseta no pódio declaram canonical externo e alternates próprios. O novo check aponta atenção para esse conjunto. A intenção editorial e os termos de reprodução não foram confirmados; os metadados foram preservados.",
            acceptance = "Conferir política e fonte, escolher canonical e alternates coerentes com essa intenção e validar as versões entregues. Não substituir canonical externo automaticamente.",
            urls = [{url = "https://roadrunners.run/noticias/o-que-aconteceu-com-a-nike-no-mundo-da-corrida-e-na-bolsa/", label = "Notícia sobre Nike"}, {url = "https://roadrunners.run/noticias/por-que-ele-trocou-de-camiseta-tantas-vezes-no-podio/", label = "Notícia sobre pódio"}],
            stateLabel = "Intenção editorial pendente de conferência"
        },{
            resolved = false,
            id = "RR-09",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Idiomas",
            title = "Completar hreflang das páginas institucionais em português",
            summary = "Sobre, Ajuda e Privacidade em PT ainda não declaram os links de idioma anunciados pelas versões EN/ES.",
            impact = "A falta de retorno interrompe a reciprocidade dos conjuntos de idioma dessas páginas.",
            owner = "RoadRunners — metadados das páginas institucionais",
            rule = "hreflang-reciprocity",
            evidence = "Na auditoria final de 03/10, as páginas PT entregaram HTML utilizável sem alternates; as versões EN/ES inspecionadas declaram essas URLs em seus conjuntos. Seis páginas EN/ES pedem atenção por falta de retorno em PT. A correção da busca foi revalidada separadamente e não resolve essas outras rotas.",
            acceptance = "Identificar a rota no template ou corrigir a identificação compartilhada, preservar o conteúdo institucional e verificar canonical e alternates PT/EN/ES em HTML público.",
            urls = [{url = "https://roadrunners.run/sobre/", label = "Sobre em português"}, {url = "https://roadrunners.run/ajuda/", label = "Ajuda em português"}, {url = "https://roadrunners.run/privacidade/", label = "Privacidade em português"}],
            stateLabel = "Reciprocidade incompleta; correção pendente"
        }
'''
verified=(STAGE/'search-public-verification.json').exists()
if verified:
 report=json.loads((STAGE/'search-public-verification.json').read_text());assert report['ok'] and len(report['pages'])==3
 assert 'roadrunners' in [s['id'] for s in snapshot['sites']]
 if datetime.fromisoformat(next(s for s in snapshot['sites'] if s['id']=='roadrunners')['auditAt'].replace('Z','+00:00'))<=datetime.fromisoformat(report['checked_at_utc'].replace('Z','+00:00')):raise RuntimeError('Require an audit after public verification')
 audit_file=STAGE/'search-audit-verification.json'
 if not audit_file.exists():raise RuntimeError('Search audit evidence missing')
 audit=json.loads(audit_file.read_text());rr=next(s for s in snapshot['sites'] if s['id']=='roadrunners')
 expected_urls={'https://roadrunners.run/busca/','https://roadrunners.run/en/search/','https://roadrunners.run/es/busqueda/'}
 if audit.get('runId')!=rr['runId'] or audit.get('auditAt')!=rr['auditAt'] or len(audit.get('pages',[]))!=3 or {p.get('url') for p in audit['pages']}!=expected_urls or any(p.get('status')!='pass' for p in audit['pages']):raise RuntimeError('Search audit must confirm all three searches in this run')
elif '--preview' not in sys.argv:raise RuntimeError('Search publication not verified')
extra=extra.replace('SEARCH_RESOLVED',str(verified).lower()).replace('SEARCH_STATE','Corrigido e rechecado em 03/10/2026' if verified else 'Correção preparada; publicação pendente')
pos=data.rfind('    ]');assert pos>0;data=data[:pos]+extra+data[pos:]
candidate=STAGE/'candidate/portal/includes/seo_queue_data.cfm';candidate.parent.mkdir(parents=True,exist_ok=True);candidate.write_text(data)
print(json.dumps({'runs':len(runs),'items':14,'search_verified':verified,'output':str(candidate)}))
