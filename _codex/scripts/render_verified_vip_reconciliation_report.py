"""Render the private review report from the provider audit and committed receipt."""
from pathlib import Path
import datetime,html,json,os
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'_codex/analyses/verified-challenges-20261124'
STAGE=ROOT/'_codex/staging/verified-vip-reconcile-20261124'
receipt=json.loads((STAGE/'first-apply.json').read_text())['result']
assert receipt['APPLIED'] and receipt['CONCILIATED']==42
data=json.loads((OUT/'vip-api-all.json').read_text())
names={r['profile_id']:r['nome'] for r in json.loads((OUT/'audit.json').read_text())['pending']}
terms={r['profile_id']:r['valid_until'] for r in receipt['TERMS']}
labels={53015:'Somente tentativas VIP recusadas',53067:'Pagamento confirmado somente da Básica',53296:'Pedido estornado; upgrade no cadastro requer revisão',53742:'Nenhum pedido TSD localizado pelos vínculos consultados'}
rows=[]
for r in data['results']:
 paid=[o for o in r['orders'] if o['classification']=='confirmed' and set(o['products'])&{'todosantodiavip','todosantodiaupg'}]
 status='Conciliado · selo válido até '+terms[r['profile_id']] if paid else labels[r['profile_id']]
 detail=[]
 for o in paid:
  date=datetime.datetime.fromisoformat(o['paid_at'][0].replace('Z','+00:00')).astimezone(datetime.timezone(datetime.timedelta(hours=-3)))
  detail.append(html.escape(' · '.join([o['products'][0],o['id'],date.strftime('%d/%m/%Y %H:%M')+' (Brasília)','R$ '+format(o['amount']/100,'.2f').replace('.',',')])))
 link='https://business.roadrunners.run/portal/verificados/?filter_status=all&page_id='+str(r['profile_id'])
 rows.append((bool(paid),names[r['profile_id']],'<tr><td>'+html.escape(names[r['profile_id']])+'</td><td>'+html.escape(status)+'</td><td>'+'<br>'.join(detail)+'</td><td><a href="'+link+'">Abrir no Business</a></td></tr>'))
body='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Conciliação VIP concluída — 24/11/2026</title><style>body{font:16px system-ui;background:#f5f5f5;color:#222;margin:0;padding:24px}main{max-width:1250px;margin:auto}h1{font-size:28px}table{border-collapse:collapse;background:white;width:100%}td,th{padding:14px;text-align:left;border-bottom:1px solid #ddd;vertical-align:top}a{color:#805800}p{line-height:1.5}.table{overflow:auto}th{background:#ffe5a0}.notice{padding:18px;background:#fff2cc;border-left:4px solid #f4b120}</style><main><h1>Conciliação VIP concluída</h1><div class="notice"><strong>42 pagamentos conciliados e selos vinculados ao VIP/upgrade, válidos até 31/12/2026.</strong><p>Aplicado em 24/11/2026, após autorização do proprietário e nova confirmação na API. São 38 inscrições VIP e quatro upgrades. Nenhuma cobrança ou estorno foi realizado.</p><a href="https://business.roadrunners.run/portal/verificados/?filter_status=divergent">Revisar os quatro divergentes no Business →</a></div><p>Os quatro casos abaixo ficaram fora da conversão e mantiveram seus selos anteriores. Todos os demais históricos e classificações foram preservados. Total atual: 418 selos ativos, 332 com prazo e 86 permanentes.</p><p>Esta é uma auditoria datada; o estado atual deve ser conferido no Business. As datas dos pedidos são de pagamento na Pagar.me, não de inscrição no cadastro.</p><div class="table"><table><thead><tr><th>Pessoa</th><th>Resultado</th><th>Pedido pago</th><th>Perfil</th></tr></thead><tbody>'''+''.join(x[2] for x in sorted(rows))+'</tbody></table></div></main></html>'
path=OUT/'conciliacao-vip-api.html';path.write_text(body);os.chmod(path,0o600)
print(str(path))
