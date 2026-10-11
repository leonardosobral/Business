from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import json,re
stage=Path(__file__).resolve().parent
source=json.loads(Path('/Users/Shared/RunnerHubReports/seo/semrush/roadrunners/20261004-reaudit-500/evidence.json').read_text())
s=stage/'candidate';p=s/'portal/includes/seo_queue_data.cfm';t=p.read_text()
now=datetime.fromisoformat(source['audit']['collected_at'].replace('Z','+00:00')).astimezone(ZoneInfo('America/Sao_Paulo'))
t=re.sub(r'updatedAt = "[^"]+"','updatedAt = "'+now.isoformat(timespec='seconds')+'"',t,count=1)
t=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',t,count=1)
def item(id,fields):
 global t
 start=t.index('id = "'+id+'"');end=t.index('\n        }',start);block=t[start:end]
 for field,value in fields.items():
  assert '"' not in value
  block,n=re.subn(r'\b'+field+r' = "[^"]*"',lambda _:field+' = "'+value+'"',block,count=1);assert n==1,(id,field)
 t=t[:start]+block+t[end:]
def append_evidence(id,extra):
 start=t.index('id = "'+id+'"');v=re.search(r'evidence = "([^"]*)"',t[start:]).group(1)
 item(id,{'evidence':v+' '+extra})
append_evidence('RR-17','Reauditoria Semrush concluída em 04/10 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b, 500 páginas: descrições duplicadas 27 para 0, problemas de sitemap 4 para 0 e títulos duplicados 27 para 2. Os dois títulos restantes são das URLs 2026 e 2027 da Corrida do Turismo ABAVSE, fora das listagens editoriais corrigidas; seguem no RR-20. Mesmos limites e configurações observáveis, sem prova de que todas as URLs amostradas são idênticas. Não comprova indexação.')
item('RR-17',{'acceptance':'Entrega técnica validada e baixa dos grupos editoriais confirmada na amostra Semrush de 04/10 às 15:40. Os dois títulos restantes de eventos estão separados no RR-20; a confirmação vale para esta coleta de 500 páginas.', 'stateLabel':'Reauditoria confirmada em 04/10 às 15:40 — pendências de eventos no RR-20'})
append_evidence('RR-18','Reauditoria Semrush concluída em 04/10 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b: grupo de conflitos hreflang passou de 42 para 0 na amostra de 500 páginas, reunindo o efeito dos lotes RR-17 e RR-18. Não comprova correção em URLs fora da amostra nem indexação.')
item('RR-18',{'acceptance':'Entrega pública validada e nenhum conflito hreflang apontado na nova amostra Semrush de 500 páginas. Manter validação dos alternates e canonicals ao ampliar a cobertura.', 'stateLabel':'Reauditoria confirmada em 04/10 às 15:40 — hreflang sem ocorrências na amostra'})
append_evidence('RR-19','Reauditoria Semrush concluída em 04/10 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b: imagens quebradas passaram de 1 para 0. A página de corrida de rua ainda aparece como não rastreada; a validação pública da imagem nela não foi substituída por uma confirmação de rastreamento do fornecedor.')
item('RR-19',{'stateLabel':'Semrush: zero imagens quebradas na amostra de 04/10 às 15:40'})
item('RR-20',{
 'title':'Resolver os nove erros restantes da reauditoria Semrush',
 'summary':'A coleta de 500 páginas ainda aponta dois títulos iguais de eventos, um ranking não rastreado, uma busca lenta e cinco ocorrências ligadas à proteção de e-mail.',
 'rule':'semrush.2; semrush.6; semrush.8; semrush.9; semrush.111',
 'evidence':'Reauditoria concluída em 04/10/2026 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b. Erros: 114 para 9. Detalhes completos: dois títulos duplicados nas URLs 2026 e 2027 da 4ª Corrida do Turismo ABAVSE; corridaderua permanece não rastreada; o alerta de lentidão agora aponta a busca em inglês com filtro de 5 km, não o evento Lupo da coleta anterior. Um 404 e quatro links continuam ligados a /cdn-cgi/l/email-protection. O grupo de conteúdo duplicado passou de quatro para zero, porém teve somente oito verificações contra 1.272 antes: desaparecimento na amostra não prova correção global e não houve alteração de conteúdo dos vídeos. Não houve mudança de datas, cadastros, proteção da Cloudflare ou exclusão de regras da auditoria.',
 'acceptance':'Priorizar o acesso ao ranking e a busca lenta; conferir as fontes e a identidade das duas URLs ABAVSE antes de corrigir título, data ou redirecionamento; validar os links protegidos em navegador. Depois tratar os maiores grupos de avisos. Manter a cobertura explícita e não usar redução de erros como confirmação de indexação.',
 'stateLabel':'Reauditoria recebida — 9 erros em análise; 6.356 avisos e 126 observações'
})
for old in [' Baixa no Semrush depende de nova auditoria.',' Nova auditoria Semrush ainda não executada.',' Contadores Semrush permanecem os da coleta anterior: não houve reauditoria nem confirmação de indexação.']:
 t=t.replace(old,'')
p.write_text(t)
p=s/'portal/conteudo/seo_semrush.cfm';t=p.read_text();start=t.index('  <p class="seo-note">Correções editoriais');end=t.index('  <nav class="sr-nav"',start)
t=t[:start]+'''  <p class="seo-note"><strong>Comparação das auditorias de 04/10/2026, 14:39 e 15:40:</strong> Site Health Semrush de 68 para 76 (+8 pontos); erros de 114 para 9 (−92,1%); avisos de 6.293 para 6.356; observações de 60 para 126. Ambas rastrearam 500 páginas, com os mesmos limites e configurações observáveis. A composição das URLs e o número de verificações variam; esta comparação não comprova indexação no Google.</p>
  <p class="seo-note">Na nova amostra, hreflang passou de 42 para 0, descrições duplicadas de 27 para 0, problemas de sitemap de 4 para 0 e imagens quebradas de 1 para 0. Evidências: <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-17">RR-17 — editorial</a>, <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-18">RR-18 — buscas</a> e <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-19">RR-19 — imagens</a>.</p>
  <p class="seo-note">Os nove erros restantes foram detalhados no <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-20">RR-20</a>: dois títulos iguais de eventos, uma página não rastreada, uma busca lenta e cinco ocorrências da proteção de e-mail. A maior parte dos avisos concentra-se em recursos sem minificação (2.809) e redirecionamentos temporários (2.786); são ocorrências, não páginas únicas nem correções independentes.</p>
'''+t[end:];p.write_text(t)
p=stage/'verify_panel.py';t=p.read_text().replace("assert 'Correções editoriais publicadas e verificadas' in h","assert 'Comparação das auditorias' in h\nassert 'Site Health Semrush de 68 para 76' in h\nassert 'erros de 114 para 9' in h\nassert '2.809' in h and '2.786' in h\nassert 'uma nova auditoria ainda precisa confirmar' not in h\nassert 'os totais do fornecedor ainda são os da auditoria anterior' not in h")
t=t.replace("assert '114 ocorrências de erro' in h and '6.293 avisos' in h and '60 observações' in h", "assert '9 ocorrências de erro' in h and '6.356 avisos' in h and '126 observações' in h\nassert '114 ocorrências de erro' not in h\nassert 'Resolver os nove erros restantes' in __import__('html').unescape(rendered['queue'])")
t=t.replace("assert '04/10/2026, 14:39 (Brasília)' in", "assert '04/10/2026, 15:40 (Brasília)' in")
p.write_text(t)
print('Updated audit notes, four queue items and render assertions')
