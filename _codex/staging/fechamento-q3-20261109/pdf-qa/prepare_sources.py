"""Prepare 09 November internal PDF sources; do not rewrite historical v5."""
from pathlib import Path
import hashlib
import json

RR = Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
BUSINESS = Path('/Users/Shared/Projects/RunnerHub/Business')
BASE = RR / '_codex/docs/brasil_que_corre_provas/lancamento_q3_2026_10_09'
QA = Path(__file__).resolve().parent
if (QA/'baseline.json').exists():
    raise RuntimeError('Baseline already saved; use the versioned generators directly.')
PDFS = ['brasil-que-corre-provas-guia-rapido-q3.pdf',
        'brasil-que-corre-provas-lancamento-q3-execucao-v5.pdf']

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

v5 = BASE / 'gerar_pdf_execucao_v5.py'
guide = BASE / 'gerar_pdf_guia_rapido.py'
(QA/'baseline'/'gerar_pdf_guia_rapido.py').write_bytes(guide.read_bytes())
(QA/'baseline'/'gerar_pdf_execucao_v5.py').write_bytes(v5.read_bytes())
baseline = {'review_date': '2026-11-09', 'pdfs': [], 'v5_source_sha256': digest(v5)}
for name in PDFS:
    baseline['pdfs'].append({
        'filename': name,
        'business_sha256': digest(BUSINESS/'estudos/lancamento/arquivos'/name),
        'rr_sha256': digest(RR/'output/pdf'/name),
        'production_sha256': digest(QA/'baseline'/name),
        'production_verified_by': 'ssh sha256sum 2026-11-09; all three hashes identical',
    })
(QA/'baseline.json').write_text(json.dumps(baseline, ensure_ascii=False, indent=2)+'\n')

def replace_once(text, old, new):
    assert text.count(old) == 1, (old, text.count(old))
    return text.replace(old, new)

g = guide.read_text()
for old, new in [
    ('revisão 04/11/2026', 'revisão 09/11/2026'),
    ('GUIA INTERNO / 04 NOV 2026', 'GUIA INTERNO / 09 NOV 2026'),
    ('6 destaques percentuais.<br/>Hotsite e kit sem cadastro.', '6 cards + 3 comparativos.<br/>Hotsite e kit sem cadastro.'),
    ('37 páginas no Business.<br/>Acesso pessoal por convite/voucher.', 'Capítulos completos no Business.<br/>Acesso pessoal por convite/voucher.'),
    ('Pago em janeiro. Resgate válido:<br/>compra antecipada com 50% de desconto.', 'Em preparação para janeiro de 2027.<br/>Benefício: compra antecipada com -50%.'),
    ('Entrada da campanha e destaques para compartilhar.', '+2,1% mesmas provas; +33,9% calendário.<br/>Resultados registrados: +27,3%.'),
    ('Artes, três pautas, período e fontes.', '5 pautas, 10 artes e PDF público de 7 páginas.'),
    ("entry('Execução v5 / plano atual'", "entry('Execução v6 / plano atual'"),
    ("HUB+'arquivo.cfm?doc=execucao-v5', 298, 230)", "HUB+'arquivo.cfm?doc=execucao-v6', 298, 230)"),
    ("entry('Conselheiros v2', '11 telas. Estratégia e exemplos visuais.',\n      HUB+'arquivo.cfm?doc=conselho-v2', 298, 282)", "entry('Execução v5 / histórico', '8 telas. Versão de 04/11 preservada.',\n      HUB+'arquivo.cfm?doc=execucao-v5', 298, 282)\nentry('Conselheiros v2', '11 telas. Estratégia e exemplos visuais.',\n      HUB+'arquivo.cfm?doc=conselho-v2', 298, 334)"),
    ("HUB+'arquivo.cfm?doc=conselho-v1', 298, 334)", "HUB+'arquivo.cfm?doc=conselho-v1', 298, 386)"),
    ("HUB+'arquivo.cfm?doc=estrategia-inicial', 298, 386)", "HUB+'arquivo.cfm?doc=estrategia-inicial', 298, 438)"),
    ("rect(298, 440, 245, 46, '#E5E5E5', 6)\ntxt('USE O V5 PARA OPERAR', 309, 447, 223, 8.4, 'Medium')\ntxt('Os PDFs anteriores são referência histórica;<br/>o cronograma vigente está aqui e no v5.',\n    309, 462, 223, 8.3, leading=10.5, max_h=22)\n", ''),
    ('Conferir acesso, dados e links.<br/>Liberar a primeira onda.', 'Conferir contrato, dados e links.<br/>Liberar após as conferências.'),
    ('<b>13/11 confirmado.</b> Definir responsáveis, 5-10 leitores de piloto e primeiros criadores.', '<b>13/11 confirmado.</b> Piloto: 10-11/11. Lote: 95 vouchers READY; resgate até 24/11.'),
    ('<b>ABRACEO:</b> negociação contratual; conferência em 12/11. <b>Criadores:</b> kit + cortesia nominal + liberdade editorial.', '<b>ABRACEO:</b> contrato em negociação, prazo 12/11. <b>Criadores:</b> kit + cortesia nominal + liberdade editorial.'),
    ('Benefício de 50% não dá o anual grátis. Preços, CNA e ritmo nacional de 42 km ficam em preparação para o anual.', '50% já implementado em 04/11; checkout anual pendente. Maratonas: apoio separado em revisão web.'),
    ('len(links) == 10', 'len(links) == 11'),
    ("'reviewed': '2026-11-04'", "'reviewed': '2026-11-09'"),
    ("'guia_rapido_pdf_qa-20261104.json'", "'guia_rapido_pdf_qa-20261109.json'"),
]:
    g = replace_once(g, old, new)
guide.write_text(g)

e = v5.read_text()
for old, new in [
    ('Launch execution brief, v5.', 'Launch execution brief, v6.'),
    ('v3 and prior PDFs preserved.', 'v5 and prior PDFs preserved.'),
    ('All numeric examples come from frozen v22 data, not live SQL.', 'Uses frozen professional publication 41/run 233 and public projection 239; no live SQL.'),
    ('lancamento-q3-execucao-v5.pdf', 'lancamento-q3-execucao-v6.pdf'),
    ('Lançar a prévia Jan-Set | v5', 'Lançar a prévia Jan-Set | v6'),
    ("txt('04 NOV 2026 / V5'", "txt('09 NOV 2026 / V6'"),
    ('Plano atualizado em 04/11/2026.', 'Plano atualizado em 09/11/2026.'),
    ('Seis percentuais no hotsite. Kit com três pautas, artes e fontes. Compartilhamento sem cadastro.', 'Seis cards e três comparativos no hotsite. Kit: cinco pautas, dez artes e PDF de sete páginas. Fontes abertas.'),
    ('Perfil, idades, gerações, distâncias, geografia, calendário, porte e maratonas revisadas. Fontes e critérios.', 'Capítulos completos de perfil, idades, gerações, distâncias, geografia, calendário e porte. Fontes e critérios.'),
    ('Preços de inscrição, faixas de desempenho (CNA) e ritmo nacional de 42 km: temas em preparação.', 'Preços, kits e lotes, faixas de desempenho (CNA), ritmo nacional de 42 km e Q4: temas em preparação.'),
    ('Ritmo de 5/10/21 km: participações elegíveis, inclusive PCD, sem ranking. Maratonas: top 10 revisado. Escopo e fontes registrados no notebook.', 'Profissional: publicação 41/run 233; corte 30/09/2026. Maratonas: apoio editorial separado, em revisão web; sem promessa de novo PDF.'),
    ('Só o resgate válido ativa o benefício. Pedido de convite e aviso anual não concedem desconto automaticamente. Sem cartão na prévia.', 'Prévia por convite/voucher, sem venda. Resgate válido ativa o benefício de 50%, já implementado em 04/11. Checkout anual pendente.'),
    ("txt('Benefício aos associados'", "txt('Lote preparado'"),
    ('Convite individual + leitura profissional + suporte no primeiro acesso. O cadastro aproxima o organizador do Business.', '95 vouchers READY, com resgate até 24/11. Convite individual, leitura profissional e suporte no primeiro acesso.'),
    ('Nomear donos. Escolher 5-10 leitores e os primeiros criadores.', 'Organizar cinco pautas. Nomear donos e selecionar leitores e criadores.'),
    ('Corrigir bloqueios reais. Confirmar peças, links e destinatários.', 'Conferir contrato, peças, links e destinatários. Liberar após as conferências.'),
    ('Segunda pauta, suporte, reviews e um caso de uso contado pelo leitor.', 'Pautas de apoio, suporte, entrevistas e reviews que surgirem.'),
    ('Estreia confirmada em 13/11. Conferir o contrato ABRACEO em 12/11. Acessos e materiais prontos para a estreia.', 'Estreia em 13/11. Contrato ABRACEO até 12/11. Piloto e liberação dependem da conferência da equipe.'),
    ("('JANEIRO','Apresentar a oferta','Anual pago. Benefício de compra antecipada com 50% para resgates válidos.'", "('JAN 2027','Apresentar a oferta','Anual separado, em preparação. Resgates válidos já têm benefício de 50%; checkout pendente.'"),
    ('PROPOSTA DO ANUAL / A VALIDAR', 'PROPOSTAS / ANUAL 2026 EM JANEIRO DE 2027'),
    ('ESTRUTURA PRONTA. ORGANIZAR A PRIMEIRA ONDA.', 'PRÓXIMAS AÇÕES / ESTREIA EM 13 DE NOVEMBRO'),
    ("('03','Prazo do convite','Aprovar resgate e leitura antes de emitir cada lote nominal.')", "('03','Lote e contrato','Conferir 95 vouchers READY, resgate até 24/11. Concluir negociação ABRACEO até 12/11.')"),
    ("'execucao-layout-v5.json'", "'execucao-layout-v6.json'"),
]:
    e = replace_once(e, old, new)

start = e.index('# 3. Reuse reviewed facts; no unnecessary new analyses for the campaign.')
finish = e.index('# 4. Show how the free preview supports a commercial relationship.')
e = e[:start] + '''# 3. Five current public pitches; the joint comparison uses different populations.
header(3,'Conteúdo pronto para abrir a conversa')
tag('5 PAUTAS / 10 ARTES / PDF PÚBLICO DE 7 PÁGINAS',56,91,478,INK,WHITE)
txt('Cinco pautas. Uma base com contexto.',56,143,1168,40,'Title')
txt('Abertura: calendário mais cheio, alta menor nas edições das mesmas provas.',56,204,1168,21,color=MUTED)
for x,color,label in [(56,MINT,'CALENDÁRIO E MESMAS PROVAS'),(453,LILAC,'PARTICIPAÇÃO FEMININA'),(850,YELLOW,'RESULTADOS REGISTRADOS')]:
    rect(x,251,374,282,color,12)
    txt(label,x+21,272,331,12,'Medium')
txt('+2,1%',77,302,330,45,'Title',leading=53)
txt('concluintes nas mesmas provas',79,357,328,15,'Medium')
txt('+33,9%',77,389,330,45,'Title',leading=53)
txt('provas no calendário cadastrado',79,446,328,15,'Medium')
txt('Universos diferentes; sujeitos à coleta.',79,491,328,13,leading=18,max_h=36)
txt('53,9%',474,302,331,58,'Title',leading=70)
txt('Elas seguem<br/>maioria',477,391,327,25,'Heading',leading=31,max_h=65)
txt('Participações elegíveis,<br/>não pessoas únicas.',477,475,327,16,leading=23,max_h=48)
txt('+27,3%',871,302,331,58,'Title',leading=70)
txt('Mais registros.<br/>Mais perguntas.',874,391,327,25,'Heading',leading=31,max_h=65)
txt('Captura e importações<br/>afetam a comparação.',874,475,327,16,leading=23,max_h=48)
for x,w,color,value,title,body in [
    (56,569,LILAC,'61,2%','A força dos percursos curtos','Participações de rua em percursos positivos abaixo de 6 km.'),
    (647,577,MINT,'47,5%','A corrida além das capitais','Local da prova, não residência do atleta.')]:
    rect(x,552,w,75,color,9)
    txt(value,x+17,569,154,32,'Title',leading=40)
    txt(title,x+183,565,w-201,18,'Heading',max_h=25)
    txt(body,x+183,593,w-201,11.5,leading=15,max_h=30)
source('Jan-Set 2025/2026. Público: célula 420/run 239; origem 41/run 233. Coleta por bloco; panorama 2026: 06/10. Não isola crescimento do mercado.')
c.linkURL('https://roadrunners.run/brasilquecorreprovas/2026/kit/',(56,H-627,1224,H-251),relative=0,thickness=0)
end()

''' + e[finish:]
(BASE/'gerar_pdf_execucao_v6.py').write_text(e)
assert digest(v5) == baseline['v5_source_sha256']
print(json.dumps({'guide_source': str(guide), 'v6_source': str(BASE/'gerar_pdf_execucao_v6.py'), 'baseline': str(QA/'baseline.json')}, ensure_ascii=False))
