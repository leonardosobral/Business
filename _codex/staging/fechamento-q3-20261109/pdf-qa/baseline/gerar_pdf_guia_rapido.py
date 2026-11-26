"""One-page launch index; URLs point to the protected Business launch hub.

Run with the bundled Python runtime. Existing strategy PDFs are preserved.
"""
from pathlib import Path
import json
import argparse
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pypdf import PdfReader

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
FONT = BASE.parent / 'estrategia_comercial_2026_10_09/assets/fonts'
parser = argparse.ArgumentParser()
parser.add_argument('--output-dir', type=Path, default=ROOT / 'output/pdf')
args = parser.parse_args()
OUT = args.output_dir / 'brasil-que-corre-provas-guia-rapido-q3.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
for name, file in [('Body', 'Poppins-400.ttf'), ('Medium', 'Poppins-600.ttf'),
                   ('Bold', 'Poppins-700.ttf'), ('Title', 'LibreFranklin-900.ttf'),
                   ('Heading', 'LibreFranklin-700.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(FONT / file)))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='Bold', italic='Body', boldItalic='Bold')

W, H = landscape(A4)
INK, PAPER, WHITE, YELLOW = '#242424', '#F4F3EF', '#FFFFFF', '#F6BD30'
MUTED, LINE = '#646464', '#D6D6D6'
HUB = 'https://business.roadrunners.run/estudos/lancamento/'
c = canvas.Canvas(str(OUT), pagesize=(W, H), pageCompression=1)
c.setTitle('Brasil que Corre Provas | Guia rápido do lançamento Jan-Set 2026')
c.setAuthor('Road Runners')
c.setSubject('Índice de materiais, acessos e cronograma interno - revisão 04/11/2026')
checks, links = [], []

def rect(x, y, w, h, fill, radius=0, stroke=None):
    c.setFillColor(HexColor(fill)); c.setStrokeColor(HexColor(stroke or fill))
    if radius:
        c.roundRect(x, H-y-h, w, h, radius, fill=1, stroke=bool(stroke))
    else:
        c.rect(x, H-y-h, w, h, fill=1, stroke=bool(stroke))

def line(x, y, w, color=LINE):
    c.setStrokeColor(HexColor(color)); c.setLineWidth(.6)
    c.line(x, H-y, x+w, H-y)

def txt(s, x, y, w, size=10, font='Body', color=INK, leading=None, max_h=None):
    p = Paragraph(s, ParagraphStyle('p', fontName=font, fontSize=size,
                  leading=leading or size*1.3, textColor=HexColor(color), spaceAfter=0))
    _, h = p.wrap(w, H)
    assert y+h <= H-10, (s, y, h)
    if max_h is not None:
        assert h <= max_h, (s, h, max_h)
    p.drawOn(c, x, H-y-h)
    checks.append({'text': s, 'box': [x, y, w, h]})
    return h

def link(url, x, y, w, h):
    c.linkURL(url, (x, H-y-h, x+w, H-y), relative=0, thickness=0)
    links.append({'url': url, 'box': [x, y, w, h]})

def entry(title, desc, url, x, y, w=245, h=45):
    txt(title, x, y, w-18, 11, 'Heading', max_h=15)
    txt('>', x+w-12, y, 12, 11, 'Heading')
    txt(desc, x, y+18, w, 9.2, color=MUTED, leading=12, max_h=25)
    link(url, x-2, y-3, w+4, h)

rect(0, 0, W, H, PAPER)
rect(0, 0, W, 96, INK)
txt('ROAD RUNNERS / BRASIL QUE CORRE PROVAS', 28, 15, 560, 9.5, 'Medium', YELLOW)
txt('GUIA INTERNO / 04 NOV 2026', 629, 15, 188, 8.5, 'Medium', '#CCCCCC')
txt('O lançamento, em um lugar só.', 28, 36, 781, 27, 'Title', WHITE, 32)
txt('Prévia de janeiro a setembro de 2026. Materiais clicáveis + calendário de execução.',
    29, 74, 780, 10.2, color='#DDDDDD', max_h=15)

cards = [
    (28, 245, 'PÚBLICO', '6 destaques percentuais.<br/>Hotsite e kit sem cadastro.'),
    (298, 245, 'PROFISSIONAL', '37 páginas no Business.<br/>Acesso pessoal por convite/voucher.'),
    (568, 245, 'ANUAL 2026', 'Pago em janeiro. Resgate válido:<br/>compra antecipada com 50% de desconto.'),
]
for x, w, title, body in cards:
    rect(x, 109, w, 70, WHITE, 7)
    rect(x, 109, 4, 70, YELLOW, 1)
    txt(title, x+14, 119, w-28, 9, 'Medium')
    txt(body, x+14, 137, w-25, 9.5, leading=13, max_h=28)

cols = [28, 298, 568]
for x, name in zip(cols, ['ACESSOS PUBLICADOS', 'PDFs E MATERIAIS', 'CRONOGRAMA DE TRABALHO']):
    txt(name, x, 197, 245, 10.1, 'Medium')
    line(x, 217, 245)

for args in [
    ('Hotsite público', 'Entrada da campanha e destaques para compartilhar.',
     'https://roadrunners.run/brasilquecorreprovas/2026/', 28, 230),
    ('Biblioteca / prévia profissional', 'Login, voucher, pedido de acesso e leitura.',
     'https://business.roadrunners.run/estudos/', 28, 282),
    ('Kit para criadores e imprensa', 'Artes, três pautas, período e fontes.',
     'https://roadrunners.run/brasilquecorreprovas/2026/kit/', 28, 334),
    ('Gestão de convites', 'Admin: pedidos, vouchers, acessos e interesse anual.',
     'https://business.roadrunners.run/estudos/#gestao', 28, 386),
    ('Notebook do estudo', 'Admin / DBA: queries e resultados congelados.',
     'https://business.roadrunners.run/estudo/', 28, 438),
]: entry(*args)

entry('Execução v5 / plano atual', '8 telas. Estreia confirmada em 13/11/2026.',
      HUB+'arquivo.cfm?doc=execucao-v5', 298, 230)
entry('Conselheiros v2', '11 telas. Estratégia e exemplos visuais.',
      HUB+'arquivo.cfm?doc=conselho-v2', 298, 282)
entry('Conselheiros v1 / histórico', '6 telas. Primeira proposta visual preservada.',
      HUB+'arquivo.cfm?doc=conselho-v1', 298, 334)
entry('Estratégia inicial / histórico', '10 páginas. Fundamentação em texto.',
      HUB+'arquivo.cfm?doc=estrategia-inicial', 298, 386)
rect(298, 440, 245, 46, '#E5E5E5', 6)
txt('USE O V5 PARA OPERAR', 309, 447, 223, 8.4, 'Medium')
txt('Os PDFs anteriores são referência histórica;<br/>o cronograma vigente está aqui e no v5.',
    309, 462, 223, 8.3, leading=10.5, max_h=22)

events = [
    ('09/11', 'Fechar e organizar. Nomear donos<br/>e escolher piloto/criadores.'),
    ('10-11/11', 'Piloto com 5-10 leitores.<br/>Login, voucher, leitura e peças.'),
    ('12/11', 'Conferir acesso, dados e links.<br/>Liberar a primeira onda.'),
    ('13/11', '<b>Lançamento confirmado.</b><br/>Posts, kit e primeira onda de convites.'),
    ('14-20/11', 'Repercussão, suporte, entrevistas<br/>e reviews que surgirem.'),
    ('NOV-DEZ', 'Relacionamento; fechar oferta<br/>e testar checkout do anual.'),
    ('JAN 2027', '<b>Propostas:</b> 06/01 antecipado;<br/>11/01 venda geral. Ainda a confirmar.'),
]
for i, (date, body) in enumerate(events):
    y = 229+i*37
    if date == '13/11': rect(560, y-4, 261, 36, YELLOW, 5)
    txt(date, 568, y+2, 75, 8.7 if len(date)>8 else 9.4, 'Heading', max_h=14)
    txt(body, 647, y, 171, 8.5, leading=11.3, max_h=24)

line(28, 501, 785)
txt('<b>13/11 confirmado.</b> Definir responsáveis, 5-10 leitores de piloto e primeiros criadores.',
    28, 511, 785, 9.6, max_h=15)
txt('<b>ABRACEO:</b> negociação contratual; conferência em 12/11. <b>Criadores:</b> kit + cortesia nominal + liberdade editorial.',
    28, 530, 785, 9.1, max_h=15)
txt('Benefício de 50% não dá o anual grátis. Preços, CNA e ritmo nacional de 42 km ficam em preparação para o anual.',
    28, 548, 785, 8.4, color=MUTED, max_h=13)
txt('CENTRAL DA EQUIPE', 28, 571, 125, 8, 'Medium')
txt('business.roadrunners.run/estudos/lancamento/', 157, 570, 435, 8.8, 'Medium')
link(HUB, 27, 568, 563, 16)
txt('Acesso admin aos PDFs / 1 página', 640, 571, 179, 7.9, color=MUTED)
c.save()

reader = PdfReader(str(OUT))
assert len(reader.pages) == 1
annotations = reader.pages[0].get('/Annots') or []
actual_urls = [a.get_object()['/A']['/URI'] for a in annotations if a.get_object().get('/A', {}).get('/S') == '/URI']
assert len(actual_urls) == len(links) == 10
assert set(actual_urls) == set(item['url'] for item in links)
assert '13/11' in reader.pages[0].extract_text()
assert '14/10' not in reader.pages[0].extract_text()
qa = {'pdf': str(OUT), 'pages': len(reader.pages), 'size': list(landscape(A4)),
      'links': links, 'text_boxes': checks, 'reviewed': '2026-11-04'}
(OUT.parent / 'guia_rapido_pdf_qa-20261104.json').write_text(json.dumps(qa, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({'pdf': str(OUT), 'pages': 1, 'links': len(links)}, ensure_ascii=False))
