"""Private, read-only review of the frozen 107-profile challenge audit."""
from collections import defaultdict
from html import escape
from pathlib import Path
from urllib.parse import quote
import json
import os

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / '_codex/analyses/verified-challenges-20261124'
audit = json.loads((STAGE / 'audit.json').read_text())
notes = json.loads((STAGE / 'notes.json').read_text())['notes']
labels = {
 'todosantodiavip': 'Todo Santo Dia · VIP',
 'todosantodiaupg': 'Todo Santo Dia · Upgrade para VIP',
 'todosantodia': 'Todo Santo Dia · Básica',
 'inscricao365vip': 'Desafio 365 · VIP',
 'inscricao365': 'Desafio 365 · Inscrição',
 'inscricao366': 'Desafio 366 · Inscrição',
 'desafiofoco': 'Desafio Foco',
 'circuitobrasilgigante': 'Circuito Brasil Gigante',
 'catarinensecorridaderua': 'Catarinense de Corrida de Rua',
 'catarinensetrailrun': 'Catarinense de Trail Run',
 '/desafiosupra/inscricao/': 'Desafio Supra 2024'
}
status_labels = {'C':'Confirmada no cadastro (C)', 'I':'Sem confirmação (I)', 'E':'Status E · revisar', 'sem_cbat':'Sem CBAt · revisar'}
by_profile = defaultdict(list)
legacy = defaultdict(list)
lead_ids = {x['profile_id'] for x in audit['leads']}
note_groups = defaultdict(list)
for row in audit['registrations']: by_profile[row['profile_id']].append(row)
for row in audit['legacy_cna']: legacy[row['profile_id']].append(row)
for row in notes:
    item = (row['source'], row['produto'], row['note'])
    if item not in note_groups[row['profile_id']]: note_groups[row['profile_id']].append(item)

def h(value): return escape(str(value or ''), quote=True)

rows = []
counts = {'profiles':len(audit['pending']), 'registered':0, 'confirmed':0, 'nonconfirmed':0, 'none':0, 'vip_confirmed':0}
for profile in audit['pending']:
    pid = profile['profile_id']; registrations = by_profile[pid]
    confirmed = any(x['status']=='C' for x in registrations)
    vip = any(x['status']=='C' and x['produto'] in ('todosantodiavip','todosantodiaupg') for x in registrations)
    flags = ['registered' if registrations else 'none', 'confirmed' if confirmed else 'nonconfirmed']
    counts['registered'] += bool(registrations); counts['confirmed'] += confirmed
    counts['nonconfirmed'] += bool(registrations) and not confirmed; counts['none'] += not registrations; counts['vip_confirmed'] += vip
    if vip: flags.append('vip')
    if note_groups[pid]: flags.append('notes')
    entries = []
    for item in registrations:
        state = item['status']; product = labels.get(item['produto'], item['product_name'])
        order = 'Referência de pedido cadastrada' if item['order_ref'] else 'Sem referência de pedido'
        entries.append(f'<li><strong>{h(product)}</strong> <span class="badge {"confirmed" if state=="C" else "pending"}">{h(status_labels.get(state, state))}</span><small>{h(item["registered_at"])} · {order}</small><small>Cadastro: {h(item["desafio"])} / {h(item["produto"])}</small></li>')
    other = []
    for item in legacy[pid]:
        other.append(h(labels.get(item['produto'], item['produto'])) + ' · ' + h(status_labels.get(item['status'],item['status'])))
    other_html = '<details><summary>Também no legado CNA</summary><ul>' + ''.join('<li>'+x+'</li>' for x in other) + '</ul></details>' if other else ''
    if pid in lead_ids: other_html += '<p class="muted">Há registro de lead histórico; não comprova inscrição ou pagamento.</p>'
    # Summaries retain the operational meaning without exposing opaque document tokens.
    summaries = []
    for source, product, note in note_groups[pid]:
        if note.startswith('desaprovacao_documental:'): note = 'Registro de desaprovação documental no circuito.'
        elif note.startswith('vinculo_resultado_oficial:'): note = 'Registro de vínculo de resultado oficial no circuito.'
        elif note.startswith('mandala_numero:'): note = 'Número de mandala registrado: ' + note.split(':',1)[1]
        elif note == 'mandala_entregue': note = 'Entrega de mandala registrada.'
        elif note.startswith('cancelado_'): note = 'Observação de cancelamento vinculada a pedido.'
        elif note.startswith('estorno parcial'): note = 'Observação de estorno parcial e upgrade vinculada a pedido.'
        summaries.append(f'<li>{h(note)} <small>{h(source)} · {h(product)}</small></li>')
    note_html = '<details><summary>Observações para conferir</summary><ul>' + ''.join(summaries) + '</ul></details>' if summaries else ''
    if pid == 28882: note_html += '<p class="highlight">Atleta de elite: classificação autorizada pelo proprietário; execução vinculada ao SQL complementar.</p>'
    profile_url = 'https://roadrunners.run/atleta/' + quote(profile['tag'],safe='') + '/'
    admin_url = f'https://business.roadrunners.run/portal/verificados/?page_id={pid}'
    rows.append(f'<article class="person" data-flags="{" ".join(flags)}"><header><h2>{h(profile["nome"])}</h2><span class="muted">Perfil {pid}</span></header><ul class="registrations">{"".join(entries) if entries else "<li>Sem registro nas tabelas de desafios consultadas.</li>"}</ul>{other_html}{note_html}<footer><a href="{h(admin_url)}" target="_blank" rel="noopener">Revisar motivo no Business ↗</a><a href="{h(profile_url)}" target="_blank" rel="noopener">Perfil público ↗</a></footer></article>')

summary_rows = []
for label, code in [('Todo Santo Dia · VIP','todosantodiavip'),('Todo Santo Dia · Upgrade','todosantodiaupg'),('Todo Santo Dia · Básica','todosantodia'),('Desafio 365 · VIP','inscricao365vip'),('Desafio 365 · Inscrição','inscricao365'),('Desafio 366','inscricao366'),('Brasil Gigante','circuitobrasilgigante')]:
    items = [r for r in audit['registrations'] if r['produto']==code]
    summary_rows.append(f'<tr><td>{h(label)}</td><td>{len(items)}</td><td>{sum(r["status"]=="C" for r in items)}</td></tr>')

document = '''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Revisão dos vínculos em desafios</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f5f5;color:#222;font:16px/1.5 system-ui,sans-serif}main{max-width:1100px;margin:0 auto;padding:32px 20px}h1{font-size:32px;line-height:1.2;margin:10px 0}h2{font-size:20px;margin:0}p{margin:8px 0 16px}a{color:#765000}.eyebrow{font-size:12px;font-weight:800;letter-spacing:.1em}.intro,.person,.summary{background:white;border:1px solid #ddd;border-radius:14px;padding:22px;margin-bottom:18px}.intro{border-top:5px solid #f4b120}.stats{display:flex;gap:24px;flex-wrap:wrap;margin:24px 0}.stats strong{font-size:30px;display:block}.muted,small{color:#666;font-size:13px}small{display:block}.toolbar{position:sticky;top:0;background:#f5f5f5;padding:12px 0;display:flex;gap:10px;flex-wrap:wrap;z-index:1}input,select{font:inherit;border:1px solid #aaa;border-radius:8px;padding:10px;background:#fff}input{flex:1;min-width:180px}.person header{display:flex;justify-content:space-between;gap:12px}.person li{margin:10px 0}.registrations{padding-left:20px}.badge{display:inline-block;border-radius:5px;padding:2px 7px;background:#eee;font-size:12px;margin-left:6px}.confirmed{background:#e3f0e5;color:#24582c}.pending{background:#fff1cf;color:#6b4e0c}footer{display:flex;gap:20px;margin-top:18px;font-size:14px}details{margin:12px 0}summary{cursor:pointer;font-weight:600}.highlight{border-left:3px solid #f4b120;padding-left:10px;font-size:14px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{text-align:left;border-bottom:1px solid #ddd;padding:9px}th{background:#f6f6f6}[hidden]{display:none!important}@media(max-width:600px){main{padding:18px 12px}.person,.intro,.summary{padding:16px}.person header,footer{display:block}footer a{display:block;margin:10px 0}h1{font-size:27px}.toolbar>*{width:100%}}
</style></head><body><main><section class="intro"><div class="eyebrow">BUSINESS · REVISÃO DE SELOS · 24/11/2026</div><h1>Vínculos dos 107 perfis em desafios</h1><p>Retrato da fila “A classificar” antes da classificação autorizada de Guilherme Neto. Uma pessoa pode aparecer em vários desafios.</p><div class="stats"><div><strong>107</strong>perfis analisados</div><div><strong>105</strong>com inscrição cadastrada</div><div><strong>73</strong>com ao menos uma confirmada</div><div><strong>2</strong>sem registro encontrado</div></div><p><b>“Confirmada” é o status C da inscrição.</b> Não comprova pagamento nem que o desafio foi o motivo original do selo. Nenhum outro motivo ou prazo foi alterado por esta análise.</p><p class="muted">Consultadas: desafios, desafio_cna, tb_desafios_rr, tb_desafios_rr_provas, desafio_leads e GoRunners via vínculo de conta. O legado CNA sobrepõe 43 pessoas; não deve ser somado ao total. Catálogos de desafios/produtos usados para os nomes. Dados locais privados, sem envio a terceiros.</p></section><section class="summary"><h2>Principais vínculos</h2><table><thead><tr><th>Desafio / produto</th><th>Perfis cadastrados</th><th>Status C</th></tr></thead><tbody>SUMMARY_ROWS</tbody></table><p class="muted">46 pessoas têm VIP ou upgrade do Todo Santo Dia com status C: 37 sem referência de pedido e 9 com referência. Este cruzamento não confirmou pagamentos para elas. Há também registros de Foco, Supra e circuitos catarinenses sem status C.</p></section><div class="toolbar"><input type="search" id="search" placeholder="Buscar nome, desafio ou produto" aria-label="Buscar na relação"><select id="filter" aria-label="Filtrar vínculo"><option value="all">Todos os 107</option><option value="vip">VIP / upgrade TSD com status C</option><option value="confirmed">Alguma inscrição confirmada</option><option value="only_pending">Só inscrições sem confirmação</option><option value="none">Sem vínculo encontrado</option><option value="notes">Com observações para revisar</option></select></div><p id="count" role="status">107 perfis exibidos</p><div id="people">PEOPLE</div><p class="muted">Ausência nessas tabelas não exclui vínculo em outra fonte. A conta técnica de ID zero foi excluída dos cruzamentos de identidade.</p></main><script>
const search=document.getElementById('search'),filter=document.getElementById('filter'),people=[...document.querySelectorAll('.person')];const norm=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();function update(){let visible=0;for(const row of people){const flags=row.dataset.flags.split(' '),wanted=filter.value;const included=wanted==='all'||(wanted==='only_pending'?flags.includes('registered')&&flags.includes('nonconfirmed'):flags.includes(wanted));row.hidden=!(included&&norm(row.textContent).includes(norm(search.value.trim())));if(!row.hidden)visible++;}document.getElementById('count').textContent=visible+' perfis exibidos';}search.addEventListener('input',update);filter.addEventListener('change',update);
</script></body></html>'''
assert counts == {'profiles':107,'registered':105,'confirmed':73,'nonconfirmed':32,'none':2,'vip_confirmed':46}, counts
document = document.replace('SUMMARY_ROWS',''.join(summary_rows)).replace('PEOPLE',''.join(rows))
target = STAGE / 'revisao-desafios.html'; target.write_text(document); os.chmod(target,0o600)
(STAGE / 'summary.json').write_text(json.dumps(counts,indent=2))
print(json.dumps({'report':str(target),'counts':counts}))
