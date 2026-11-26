"""Launch execution brief, v5. Launch confirmed for 13 November 2026; v3 and prior PDFs preserved.

Run with the bundled Python runtime (ReportLab, pypdf).
All numeric examples come from frozen v22 data, not live SQL.
"""
from pathlib import Path
from xml.sax.saxutils import escape
import json
import argparse
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pypdf import PdfReader

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--output-dir', type=Path, default=ROOT / 'output/pdf')
args = parser.parse_args()
OUT = args.output_dir / 'brasil-que-corre-provas-lancamento-q3-execucao-v5.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
FONT = BASE.parent / 'estrategia_comercial_2026_10_09/assets/fonts'
for name, path in [('Body','Poppins-400.ttf'),('Medium','Poppins-600.ttf'),('Bold','Poppins-700.ttf'),
                   ('Title','LibreFranklin-900.ttf'),('Heading','LibreFranklin-700.ttf')]:
    pdfmetrics.registerFont(TTFont(name,str(FONT/path)))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Body',boldItalic='Bold')

W,H=1280,720
INK='#242424'; PAPER='#F4F3EF'; WHITE='#FFFFFF'; YELLOW='#F6BD30'
MUTED='#646464'; SOFT='#CDCDCD'; LINE='#DADADA'; PANEL='#353535'
PURPLE='#7D62BE'; LILAC='#DDD3F2'; TEAL='#266E5B'; MINT='#D8E9E0'
c=canvas.Canvas(str(OUT),pagesize=(W,H),pageCompression=1)
c.setTitle('O Brasil que Corre Provas | Lançar a prévia Jan-Set | v5')
c.setAuthor('Road Runners')
c.setSubject('Execução de novembro: escopo enxuto, convite, criadores e conversão ao anual - plano interno')
checks=[]

def rect(x,y,w,h,fill,r=0,stroke=None):
    c.setFillColor(HexColor(fill));c.setStrokeColor(HexColor(stroke or fill))
    if r: c.roundRect(x,H-y-h,w,h,r,fill=1,stroke=bool(stroke))
    else: c.rect(x,H-y-h,w,h,fill=1,stroke=bool(stroke))

def line(x1,y1,x2,y2,color=LINE,width=1):
    c.setStrokeColor(HexColor(color));c.setLineWidth(width);c.line(x1,H-y1,x2,H-y2)

def txt(s,x,y,w,size=22,font='Body',color=INK,leading=None,max_h=None):
    p=Paragraph(s,ParagraphStyle('p',fontName=font,fontSize=size,leading=leading or size*1.28,
                textColor=HexColor(color),spaceAfter=0))
    _,h=p.wrap(w,H)
    assert y+h<=H-12, (c.getPageNumber(),s,y,h)
    if max_h is not None: assert h<=max_h,(c.getPageNumber(),s,h,max_h)
    p.drawOn(c,x,H-y-h)
    checks.append({'page':c.getPageNumber(),'text':s,'box':[x,y,w,h]})
    return h

def tag(s,x,y,w,fill=YELLOW,color=INK):
    rect(x,y,w,30,fill,15);txt(s,x+14,y+6,w-28,12,'Medium',color,max_h=20)

def arrow(x,y,color=INK):
    line(x,y,x+24,y,color,2.5);line(x+17,y-6,x+24,y,color,2.5);line(x+17,y+6,x+24,y,color,2.5)

def circle(x,y,r,fill):
    c.setFillColor(HexColor(fill));c.circle(x,H-y,r,fill=1,stroke=0)

def header(n,section,dark=False):
    bg=INK if dark else PAPER; fg=WHITE if dark else INK
    rect(0,0,W,H,bg)
    txt('ROAD',56,30,73,19,'Title',fg)
    rect(123,29,4,24,YELLOW);rect(131,29,4,24,YELLOW)
    txt('RUNNERS',144,30,140,19,'Title',fg)
    txt('O BRASIL QUE CORRE PROVAS',298,34,425,13,'Medium',SOFT if dark else MUTED)
    txt('PLANO INTERNO DE EXECUÇÃO',980,34,250,12,'Medium',SOFT if dark else MUTED)
    line(56,674,1224,674,'#505050' if dark else LINE)
    txt(section.upper(),56,687,730,11,'Medium',SOFT if dark else MUTED)
    txt('04 NOV 2026 / V5',995,687,160,11,'Body',SOFT if dark else MUTED)
    txt(f'{n:02d} / 08',1170,686,70,12,'Medium',YELLOW if dark else INK)

def source(s,dark=False):
    txt(s,56,643,1168,11.5,'Body',SOFT if dark else MUTED,max_h=28)

def end(): c.showPage()

# 1. Confirmed launch date; this document does not send the campaign.
header(1,'O lançamento que fazemos agora',True)
tag('JAN-SET 2026 / ESTREIA EM 13 DE NOVEMBRO',56,91,411)
txt('O trimestre fechou.<br/>Vamos colocar os<br/>dados em circulação.',56,149,790,57,'Title',WHITE,64,max_h=204)
txt('A prévia lança o que já está revisado.<br/>Os temas que exigem mais trabalho ficam para o anual.',59,370,835,22,color=SOFT,leading=32)
rect(941,149,283,275,YELLOW,14)
txt('DATA CONFIRMADA',965,174,230,13,'Medium')
txt('13',956,214,245,105,'Title')
txt('NOVEMBRO',965,337,231,26,'Heading')
txt('Piloto em 10-11/11.<br/>Parceria em negociação.',965,379,234,15,leading=22)
for i,(title,body,color) in enumerate([
    ('PÚBLICO','Percentuais + pautas<br/>para compartilhar.',YELLOW),
    ('CONVIDADOS','Leitura profissional<br/>no Business.',MINT),
    ('JANEIRO','Edição anual paga.<br/>Oferta ainda em validação.',LILAC)]):
    x=56+i*397;rect(x,497,374,115,PANEL,10)
    txt(title,x+20,513,334,14,'Medium',color)
    txt(body,x+20,548,334,20,color=WHITE,leading=27)
source('Plano atualizado em 04/11/2026. Lançamento confirmado para 13/11. A prévia cobre provas de 01/01 a 30/09; o anual cobre 2026 inteiro.',True)
end()

# 2. Three clear products instead of an unfinished giant report.
header(2,'Escopo que protege o timing')
tag('ENTREGA EDITORIAL, NÃO LISTA DE PENDÊNCIAS',56,91,435,INK,WHITE)
txt('O leitor recebe uma edição fechada.',56,143,1168,43,'Title')
txt('A prévia profissional é completa dentro do recorte lançado agora.',56,205,1168,21,color=MUTED)
cols=[(56,YELLOW,'PANORAMA PÚBLICO','Poucos dados.<br/>Muito contexto.','Seis percentuais no hotsite. Kit com três pautas, artes e fontes. Compartilhamento sem cadastro.'),
      (453,MINT,'PRÉVIA PROFISSIONAL','Mais profundidade.<br/>Acesso nominal.','Perfil, idades, gerações, distâncias, geografia, calendário, porte e maratonas revisadas. Fontes e critérios.'),
      (850,LILAC,'TEMAS PARA O ANUAL','Mostrar o horizonte.<br/>Sem números frágeis.','Preços de inscrição, faixas de desempenho (CNA) e ritmo nacional de 42 km: temas em preparação.')]
for x,color,kicker,title,body in cols:
    rect(x,265,374,319,color,12)
    txt(kicker,x+22,287,330,13,'Medium')
    txt(title,x+22,333,329,25,'Heading',leading=33,max_h=76)
    txt(body,x+22,430,328,19,leading=28,max_h=125)
txt('Novas normalizações seguem em paralelo. A prévia não precisa esperá-las.',56,606,1168,21,'Heading')
source('Ritmo de 5/10/21 km: participações elegíveis, inclusive PCD, sem ranking. Maratonas: top 10 revisado. Escopo e fontes registrados no notebook.')
end()

# 3. Reuse reviewed facts; no unnecessary new analyses for the campaign.
header(3,'Conteúdo pronto para abrir a conversa')
tag('3 PAUTAS / 3 PEÇAS / FONTES VISÍVEIS',56,91,367,INK,WHITE)
txt('Começar com dados que rendem conversa.',56,143,1168,40,'Title')
txt('Instagram descobre a pauta. YouTube pode aprofundar na semana seguinte.',56,204,1168,21,color=MUTED)
for i,(value,title,desc,color) in enumerate([
    ('53,9%','Elas seguem maioria','Participações femininas nas provas elegíveis.',YELLOW),
    ('61,2%','A força das distâncias curtas','Participações de rua em percursos positivos inferiores a 6 km.',MINT),
    ('47,5%','Além das capitais','Participações em provas de rua fora das capitais.',LILAC)]):
    x=56+i*397;rect(x,265,374,315,color,12)
    txt(value,x+20,289,334,64,'Title',leading=77)
    txt(title,x+24,390,326,24,'Heading',leading=30,max_h=65)
    txt(desc,x+24,471,326,18,leading=27,max_h=95)
txt('São participações observadas, não pessoas únicas nem um censo do mercado.',56,605,1168,20,'Medium')
source('Jan-Set/2026; coleta 06/10. Publicação 41, versão 22, congelamento 233. Kit: recortes #216 e #221, cada indicador com seu universo.')
c.linkURL('https://roadrunners.run/brasilquecorreprovas/2026/kit/',(56,H-627,1224,H-265),relative=0,thickness=0)
end()

# 4. Show how the free preview supports a commercial relationship.
header(4,'Da descoberta ao relacionamento',True)
tag('O BUSINESS É O PONTO DE ENCONTRO',56,91,391)
txt('Primeiro, provar utilidade.<br/>Depois, vender o anual.',56,142,1168,44,'Title',WHITE,leading=52)
journeys=[(286,'PÚBLICO',LILAC,[('Post ou vídeo','Descobre a pesquisa'),('Panorama','Conhece os destaques'),('Interesse','Pede acesso ou aviso'),('Janeiro','Oferta do anual')]),
          (456,'CONVIDADO',MINT,[('Convite nominal','Profissional ou criador'),('Conta Business','Login + resgate'),('Leitura','Usa e dá feedback'),('Benefício','Compra antecipada -50%')])]
for y,label,color,steps in journeys:
    txt(label,56,y-23,1150,13,'Medium',SOFT)
    for i,(title,body) in enumerate(steps):
        x=56+299*i;rect(x,y+5,271,116,color,10)
        txt(title,x+18,y+25,241,22,'Heading')
        txt(body,x+18,y+69,241,15,leading=23,max_h=50)
        if i<3:arrow(x+276,y+61,YELLOW)
txt('50% é desconto na compra. A cortesia não inclui o anual gratuitamente.',56,609,1168,20,'Medium',WHITE)
source('Só o resgate válido ativa o benefício. Pedido de convite e aviso anual não concedem desconto automaticamente. Sem cartão na prévia.',True)
end()

# 5. Partnership optional, creators independent; campaigns not sent by this document.
header(5,'Distribuição que não trava a estreia')
tag('DUAS FRENTES EM PARALELO',56,91,298,INK,WHITE)
txt('ABRACEO amplia. Criadores repercutem.',56,143,1168,40,'Title')
rect(56,221,569,365,WHITE,12)
txt('ABRACEO',81,246,518,30,'Heading')
tag('EM NEGOCIAÇÃO',82,295,203,LILAC,PURPLE)
txt('Benefício aos associados',82,352,518,24,'Heading')
txt('Convite individual + leitura profissional + suporte no primeiro acesso. O cadastro aproxima o organizador do Business.',82,394,513,19,leading=28,max_h=115)
rect(78,524,525,40,YELLOW,6)
txt('Conferir contrato e comunicação até 12/11.',92,534,501,16,'Medium')
rect(647,221,577,365,INK,12)
txt('CRIADORES',672,246,527,30,'Heading',WHITE)
tag('SELEÇÃO INICIAL: 5-8 NOMES',673,295,288,YELLOW)
txt('Pauta boa + liberdade editorial',673,352,527,23,'Heading',WHITE)
txt('Kit público, fontes, acesso nominal aos convidados e canal de dúvidas. Shorts agora; reviews e entrevistas depois.',673,394,521,19,color=SOFT,leading=28,max_h=115)
txt('Cortesia não exige post nem avaliação positiva.',673,536,523,16,'Medium',YELLOW)
txt('Começar por afinidade e credibilidade. Seguidores são apenas parte do contexto.',56,608,1168,20,'Medium')
source('Nenhum contato ou envio é executado por este plano. Uso da marca da associação depende de acordo. Conteúdo contratado é outra negociação.')
end()

# 6. Rapid, concrete schedule with limited human gates.
header(6,'O caminho curto até a estreia')
tag('9 A 13 DE NOVEMBRO / DATA CONFIRMADA',56,91,358,INK,WHITE)
txt('Cinco dias para colocar a prévia na rua.',56,143,1168,41,'Title')
items=[('09 NOV','Fechar e organizar','Nomear donos. Escolher 5-10 leitores e os primeiros criadores.'),
       ('10-11 NOV','Pilotar acesso','Login, voucher, leitura. Confirmar a experiência com os leitores do piloto.'),
       ('12 NOV','Conferir e liberar','Corrigir bloqueios reais. Confirmar peças, links e destinatários.'),
       ('13 NOV','Lançamento','Post principal + stories + kit. Primeira onda de convites autorizados.')]
for i,(date,title,body) in enumerate(items):
    x=56+299*i;rect(x,239,271,302,YELLOW if i==3 else WHITE,12)
    txt(date,x+19,261,234,25,'Heading')
    txt(title,x+19,320,233,22,'Heading',leading=28,max_h=63)
    txt(body,x+19,404,233,18,leading=27,max_h=112)
rect(56,563,1168,64,INK,9)
txt('14-20 NOV',78,582,192,17,'Medium',YELLOW)
txt('Segunda pauta, suporte, reviews e um caso de uso contado pelo leitor.',279,582,918,19,'Medium',WHITE)
source('Estreia confirmada em 13/11. Conferir o contrato ABRACEO em 12/11. Acessos e materiais prontos para a estreia.')
end()

# 7. Extend usefulness and preserve January's pending status.
header(7,'Converter a prévia em intenção de compra')
tag('NOVEMBRO ABRE A RELAÇÃO. JANEIRO VENDE.',56,91,426,INK,WHITE)
txt('Não deixar o interesse esfriar.',56,143,1168,43,'Title')
for i,(month,title,body,color) in enumerate([
    ('14-20 NOV','Ouvir quem leu','Qual decisão o dado ajudaria a tomar? Separar dificuldade de acesso de falta de interesse.',YELLOW),
    ('NOV-DEZ','Dar razão para voltar','Pautas úteis, dúvidas respondidas e entrevistas. Definir oferta e testar checkout antes do recesso.',MINT),
    ('JANEIRO','Apresentar a oferta','Anual pago. Benefício de compra antecipada com 50% para resgates válidos.',LILAC)]):
    x=56+397*i;rect(x,239,374,289,color,12)
    txt(month,x+22,261,330,14,'Medium')
    txt(title,x+22,310,329,25,'Heading',leading=31,max_h=66)
    txt(body,x+22,390,328,19,leading=28,max_h=125)
rect(56,552,1168,78,WHITE,9)
txt('PROPOSTA DO ANUAL / A VALIDAR',78,566,1090,12,'Medium',MUTED)
txt('R$ 497   |   R$ 248,50 com benefício   |   06/01 antecipado   |   11/01 geral',78,592,1113,21,'Heading')
source('Preços, licença, datas e prazo do desconto não são oferta ativa. Curadoria de novembro não espera o checkout anual. Ads e eventos são opcionais.')
end()

# 8. Conclude with operational handoff, not a new strategy project.
header(8,'O que precisa de decisão para estrear',True)
tag('ESTRUTURA PRONTA. ORGANIZAR A PRIMEIRA ONDA.',56,91,478)
txt('Agora é escolher pessoas<br/>e operar o lançamento.',56,141,1168,45,'Title',WHITE,leading=54)
for i,(n,title,body) in enumerate([
    ('01','Donos e suporte','Nomear responsáveis e canal de suporte. Estreia em 13/11 confirmada.'),
    ('02','Piloto e contatos','Escolher 5-10 leitores, primeiros criadores e autorizar os contatos.'),
    ('03','Prazo do convite','Aprovar resgate e leitura antes de emitir cada lote nominal.')]):
    x=56+397*i;rect(x,286,374,230,PANEL,12)
    txt(n,x+22,307,47,24,'Heading',YELLOW)
    txt(title,x+82,309,270,22,'Heading',WHITE)
    txt(body,x+23,373,327,20,color=SOFT,leading=30,max_h=123)
rect(56,541,1168,80,YELLOW,10)
txt('NÃO ESPERAR',79,556,1080,12,'Medium')
txt('Normalizações novas, reviews prontos ou decisão de preço anual.',79,582,1118,20,'Heading')
source('Hotsite: roadrunners.run/brasilquecorreprovas/2026/ | Biblioteca: business.roadrunners.run/estudos/ | Plano e rascunhos ficam com a equipe.',True)
c.linkURL('https://roadrunners.run/brasilquecorreprovas/2026/',(56,H-669,630,H-640),relative=0,thickness=0)
c.linkURL('https://business.roadrunners.run/estudos/',(635,H-669,1224,H-640),relative=0,thickness=0)
end()

c.save()
reader=PdfReader(str(OUT))
assert len(reader.pages)==8
for p in reader.pages: assert len(p.extract_text())>200
(OUT.parent/'execucao-layout-v5.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2))
print(OUT)
print(f'8 pages / {OUT.stat().st_size:,} bytes / {len(checks)} text blocks')
