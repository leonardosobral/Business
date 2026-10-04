"""Close the privacy item using public proof; record, but do not undo, the cron pause."""
from pathlib import Path
from datetime import datetime,timezone
from zoneinfo import ZoneInfo
import json,re
STAGE=Path(__file__).resolve().parent
proof=json.loads((STAGE/'privacy-verification.json').read_text())
expected='User-agent: Googlebot\nDisallow: /nogooglebot/\nDisallow: /perfil\n\nUser-agent: *\nAllow: /\nDisallow: /perfil\n\nSitemap: https://openresults.run/sitemap.cfm\n'
assert proof['verified_hashes']==2 and proof['unrelated_files_unchanged']==6
assert proof['robots']['status']==200 and proof['robots']['body']==expected
assert len(proof['head_evidence'])==4 and all(p['ok'] for p in proof['head_evidence'])
assert sum(p['noindex'] for p in proof['head_evidence'])==2
snapshot=json.loads((STAGE/'snapshot.json').read_text());evidence=json.loads((STAGE/'evidence.json').read_text())
cron=evidence['cron'];assert cron['active'] is False
assert all(r['stop_reason']=='provider_quota_exhausted' for r in evidence['cron_diagnosis']['runs'])
counts={(r['LANGUAGE'],r['STATUS']):r['TOTAL'] for r in evidence['queue']}
data=(STAGE/'baseline/portal/includes/seo_queue_data.cfm').read_text()
parts=re.split(r'(?m)(?=^            resolved = (?:true|false),\n            id = ")',data)
assert len(parts)==16
def quoted(value):return '"'+str(value).replace('#','##').replace('"','""')+'"'
def update_item(id,field,value):
 matches=[i for i,p in enumerate(parts) if re.search(r'\bid = "'+re.escape(id)+r'"',p)];assert len(matches)==1
 i=matches[0];pattern=r'(\b'+re.escape(field)+r' = )'+(r'(?:true|false)' if isinstance(value,bool) else r'"(?:[^"]|"")*"')
 parts[i],count=re.subn(pattern,lambda m:m[1]+(str(value).lower() if isinstance(value,bool) else quoted(value)),parts[i],count=1);assert count==1
update_item('OR-02','resolved',True)
update_item('OR-02','summary','Páginas individuais /resultados entregam noindex, follow. O cache expirou e o robots público permite sua leitura; /perfil permanece bloqueado.')
update_item('OR-02','evidence','Política aprovada pelo usuário e publicada no lote anterior. Rechecagem pública em 03/10/2026 confirmou HTTP 200 com noindex em /resultados/ e no acesso direto ao template; home e evento continuam sem noindex. O robots público agora coincide com a origem, sem bloqueio de /resultados para Googlebot ou regra geral, e mantém /perfil bloqueado. Dois hashes e seis dependências de runtime foram preservados. Não foi alterada a Cloudflare neste lote. A remoção efetiva do índice exige nova leitura pelos buscadores e não foi comprovada no Search Console.')
update_item('OR-02','acceptance','Concluído no escopo de entrega: noindex nas páginas individuais, robots público atualizado, eventos sem a restrição e dados preservados. A remoção efetiva do índice não foi verificada; pedidos urgentes podem exigir Remoções do Search Console junto à regra permanente. Nomes nas listagens de eventos podem continuar aparecendo.')
update_item('OR-02','stateLabel','Publicado e rechecado em 03/10/2026')
fields=[]
for site in snapshot['sites']:
 check=next(c for c in site['aiChecks'] if c['id']=='event-fields')
 fields.append(f"{site['label']}: {check['pass']+check['warning']+check['error']} eventos avaliados, {check['warning']+check['error']} com lacunas")
update_item('SH-02','evidence','Auditorias datadas no painel: '+'; '.join(fields)+'. Verifica presença de nome, data válida, local e organizador, além de nome/cidade no texto; não comprova exatidão factual. A consulta anterior encontrou organizador nomeado em apenas 1.332 de 34.320 eventos ativos. Não usar cronometrador como organizador nem inferir dados ausentes.')
data=''.join(parts)
t=next(c for c in snapshot['sites'][0]['aiChecks'] if c['id']=='translations')
extra={
 'resolved':False,'id':'RR-11','sites':['roadrunners'],'priority':'p2','priorityLabel':'P2 · Idiomas',
 'title':'Concluir a fila de descrições e traduções',
 'summary':'A entrega de descrições já é medida em amostra. O cron está pausado e suas últimas falhas indicaram créditos da API esgotados.',
 'impact':'Descrições traduzidas ajudam leitores e assistentes a usar o conteúdo no idioma escolhido. O fallback mantém português identificado até haver tradução aprovada.',
 'owner':'Business — cron de descrições; Road Runners — entrega de idiomas',
 'rule':'Conferência complementar de descrições entregues e fila',
 'evidence':f"Conferência pública em 03/10/2026: seis eventos em PT/EN/ES, doze versões alvo — {t['pass']} com idioma esperado e texto diferente, {t['warning']} em português, {t['unknown']} sem descrição marcada suficiente. Isso não valida fidelidade. Consulta somente de leitura: cron15 inativo, intervalo10min, última execução25/09 às21:14 (horário gravado sem fuso). As cinco últimas execuções retornaram HTTP424 com provider_quota_exhausted; saldo atual da API não foi consultado. A fila existente tem {counts[('en','ready')]} EN e {counts[('es','ready')]} ES prontas; {counts[('en','rejected')]} EN e {counts[('es','rejected')]} ES em revisão por rejeição. Há {counts[('pt-BR','ready')]} descrições PT prontas. Não foram consumidos créditos nem removidas rejeições.",
 'acceptance':'Esclarecer a pausa e conferir saldo atual antes de retomar o cron. Preservar a revisão de rejeitados e as proteções de fatos; validar uma execução controlada e o texto entregue contra a fonte. Ampliar a cobertura com amostra explícita, sem inferir fidelidade por tamanho ou idioma anotado.',
 'urls':[{'url':'https://roadrunners.run/en/event/2026-6-rustica-da-assgapa-alusiva-ao-dia-da-forca-aerea/','label':'Descrição com fallback em português'}],
 'stateLabel':'Cron pausado; últimas falhas por créditos da API'}
def cf(value):
 if isinstance(value,bool):return str(value).lower()
 if isinstance(value,str):return quoted(value)
 if isinstance(value,list):return '['+', '.join(cf(v) for v in value)+']'
 if isinstance(value,dict):return '{'+', '.join(k+' = '+cf(v) for k,v in value.items())+'}'
 return str(value)
index=data.rfind('    ]\n};');assert index>0
data=data[:index]+'        ,{\n'+',\n'.join('            '+k+' = '+cf(v) for k,v in extra.items())+'\n        }\n'+data[index:]
runs=[]
for site in snapshot['sites']:
 note=site['coverageNote']+' Descoberta completa dos sitemaps; sem nova reconciliação com o banco. Conferências complementares de traduções, logs e audiência têm datas e escopos próprios na aba SEO para IA.'
 if site['id']=='roadrunners':note+=' A amostra preserva o 404 da notícia retirada e avisos brutos de rotas privadas, canonical na fonte e escapes percentuais. Correções institucionais, da busca e de Maratonas permanecem verificadas.'
 else:note+=' Rodada realizada após a entrega pública do robots atualizado; noindex das páginas individuais foi conferido separadamente.'
 row={'siteId':site['id'],'label':site['label'],'auditLabel':site['auditLabel'],'completionLabel':'Amostra concluída','discoveryComplete':site['discoveryComplete'],'discovered':site['discovered'],'inspected':site['inspected'],'operationalErrors':site['operationalErrors'],'pageErrors':site['pageErrors'],'warnings':site['warnings'],'coverageNote':note}
 runs.append('        {\n'+',\n'.join('            '+k+' = '+cf(v) for k,v in row.items())+'\n        }')
data,n=re.subn(r'    runs = \[[\s\S]*?\n    \],\n    items =',lambda m:'    runs = [\n'+',\n'.join(runs)+'\n    ],\n    items =',data,count=1);assert n==1
now=datetime.now(timezone.utc)
data=re.sub(r'updatedAt = "[^"]*"','updatedAt = '+quoted(now.isoformat()),data,count=1)
data=re.sub(r'updatedLabel = "[^"]*"','updatedLabel = '+quoted(now.astimezone(ZoneInfo('America/Sao_Paulo')).strftime('%d/%m/%Y às %H:%M (Brasília)')),data,count=1)
data=data.replace('_codex/docs/2026-10-03_seo_institucional.md','_codex/docs/2026-10-03_seo_evidencias.md')
(STAGE/'candidate/portal/includes/seo_queue_data.cfm').write_text(data)
assert len(re.findall(r'\bid = "',data))==16 and len(re.findall(r'\bresolved = true',data))==13
print(json.dumps({'items':16,'resolved':13,'pending':3,'OR-02':True,'RR-11':False}))
