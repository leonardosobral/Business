from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import json,re
STAGE=Path(__file__).resolve().parent
rank=STAGE.parent/'seo-ranking-performance-20261004'
before=json.loads((rank/'public-before.json').read_text())[0]
after=json.loads((rank/'public-after.json').read_text())[:2]
for r in after:
 assert r['status']==200 and r['seconds']<2
 assert r['tables']==before['tables']
receipt=json.loads((rank/'candidate-render-passed.json').read_text())
assert receipt['datasource']=='runnerhub' and receipt['rows']==401 and receipt['sql_equivalence']['different_rows']==0
q=STAGE/'candidate/portal/includes/seo_queue_data.cfm';s=q.read_text();assert 'id = "RR-21"' not in s
now=datetime.now(ZoneInfo('America/Sao_Paulo'))
s=re.sub(r'updatedAt = "[^"]+"', 'updatedAt = "'+now.isoformat(timespec='seconds')+'"',s,count=1)
s=re.sub(r'updatedLabel = "[^"]+"', 'updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',s,count=1)
item={
'resolved':'true','id':'RR-21','sites':['roadrunners'],'priority':'p1','priorityLabel':'P1 · Desempenho',
'title':'Acelerar o ranking catarinense de corrida de rua',
'summary':'A pontuação dos inscritos é calculada uma vez por etapa, reduzindo o tempo da página e preservando a classificação.',
'impact':'Remove uma consulta repetida que atrasava a entrega do ranking apontado pelo Semrush como não rastreado.',
'owner':'RoadRunners — Circuito Catarinense',
'rule':'semrush.9; query.repeated-score',
'evidence':'O snapshot Semrush 6ac29b3456eeefef0a3ff73b, de 04/10 às 15:40, aponta corridaderua como não rastreada. Perfil da consulta no datasource runnerhub usado pelo site: 7.150 ms antes e 36 ms depois; 401 linhas iguais em todos os campos, incluindo multiplicidade, sem diferenças reais ou sintéticas. Consumidores Adobe preservaram 135 linhas femininas, 266 masculinas e sete equipes; caso vazio também validado. Um template compilado e revisão independente concluída. Após publicar, página HTTP 200 em 0,30 s e 0,31 s, contra 8,06 s no baseline. Hashes das seis tabelas públicas, incluindo conteúdo e ordem, idênticos; title, canonical e robots preservados. Controle de trail run, busca em inglês e início HTTP 200. Nenhuma atualização de banco, pontuação, autenticação ou proteção Cloudflare. A causa exata da falha de rastreamento do fornecedor não foi provada; redução de latência não comprova indexação.',
'acceptance':'Entrega técnica publicada e verificada em 04/10/2026. Confirmar a baixa da página não rastreada em uma nova auditoria Semrush, sem alterar artificialmente a nota ou os nove erros do snapshot recebido.',
'urls':[{'url':'https://roadrunners.run/circuitocatarinense/corridaderua/','label':'Ranking otimizado'}],
'stateLabel':'Publicado e verificado — Baixa no Semrush depende de nova auditoria'}
def cfstr(v):return '"'+v.replace('"','""').replace('#','##')+'"'
lines=[]
for k,v in item.items():
 if k=='resolved':val=v
 elif k=='sites':val='['+', '.join(map(cfstr,v))+']'
 elif k=='urls':val='['+', '.join('{url = '+cfstr(x['url'])+', label = '+cfstr(x['label'])+'}' for x in v)+']'
 else:val=cfstr(v)
 lines.append('            '+k+' = '+val)
block='        {\n'+',\n'.join(lines)+'\n        },\n'
s=s.replace('    items = [\n','    items = [\n'+block,1)
# RR-20 is the vendor snapshot backlog, keep nine historical errors visible.
rr20=re.search(r'        \{\n            resolved = false, id = "RR-20".*?\n        \},',s,re.S).group(0)
updated=rr20.replace('corridaderua permanece não rastreada','corridaderua foi apontada como não rastreada nesta coleta')
updated=updated.replace('Não houve mudança de datas, cadastros, proteção da Cloudflare ou exclusão de regras da auditoria.', 'Após esta coleta, a consulta do ranking foi otimizada e a página pública caiu de 8,06 s para 0,30–0,31 s, com 401 linhas e tabelas preservadas: entrega registrada em RR-21, ainda sem nova confirmação de rastreamento do Semrush. Não houve mudança de datas, cadastros, proteção da Cloudflare ou exclusão de regras da auditoria.')
updated=updated.replace('Priorizar o acesso ao ranking e a busca lenta;', 'Confirmar o rastreamento do ranking otimizado em RR-21 numa nova auditoria; investigar a busca lenta;')
s=s.replace(rr20,updated,1);q.write_text(s)
v=STAGE/'candidate/portal/conteudo/seo_semrush.cfm';s=v.read_text()
line='  <p class="seo-note">Os nove erros restantes foram detalhados'
idx=s.index(line);end=s.index('</p>',idx)+4
note='\n  <p class="seo-note">Melhoria posterior à auditoria: o ranking catarinense de corrida de rua passou de 8,06 s para 0,30–0,31 s nas verificações públicas, com as tabelas preservadas. Entrega em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-21">RR-21</a>. A baixa do alerta de rastreamento ainda depende de nova auditoria; os números acima continuam sendo os da coleta de 04/10 às 15:40.</p>'
s=s[:end]+note+s[end:];v.write_text(s)
p=STAGE/'verify_panel.py';s=p.read_text().replace("assert '62 ms'", "assert '36 ms'");p.write_text(s)
print(json.dumps({'new_item':'RR-21','queue_total':29,'resolved':22,'pending':7,'semrush_score':76,'vendor_errors_unchanged':9,'public_seconds':[x['seconds'] for x in after]}))
