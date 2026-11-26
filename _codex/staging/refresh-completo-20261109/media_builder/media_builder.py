#!/usr/bin/env python3
"""Build a candidate editorial kit from one explicitly supplied public payload.

No DB, network, runtime mutation or import of historical generator contents.
Source references are a separate explicit input because the public JSON correctly
contains no private counts or notebook metadata. Launch date stays 13/11/2026.
"""
import argparse
from datetime import date
from decimal import Decimal, ROUND_HALF_UP
import hashlib
from html import escape
import importlib.util
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
RR = HERE.parents[4] / 'RoadRunners'
FONTS = RR / '_codex/docs/brasil_que_corre_provas/estrategia_comercial_2026_10_09/assets/fonts'
PUBLIC = 'https://roadrunners.run/brasilquecorreprovas/2026/'
EDITORIAL = 'https://business.roadrunners.run/estudos/?interesse=editorial'
LAUNCH = '13/11/2026'
KIT_PATH = Path('portal/brasilquecorreprovas/2026/kit')


def percent(value, signed=False):
    n = Decimal(str(value)).quantize(Decimal('0.1'), rounding=ROUND_HALF_UP)
    if n == 0: n = abs(n)
    return ('+' if signed and n > 0 else '') + format(n, '.1f').replace('.', ',') + '%'


def number(value, name, low=-100, high=1000000):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not low <= value <= high:
        raise ValueError(f'Missing or invalid public number: {name}')
    return value


def build_model(payload, provenance):
    try:
        r = payload['release']
        if payload.get('ok') is not True or r['periodo_inicio'] != '2026-01-01' or r['periodo_fim'] != '2026-09-30':
            raise ValueError('Expected the approved Jan-Sep public projection')
        if not isinstance(r['coleta'], str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', r['coleta']):
            raise ValueError('Collection date must use YYYY-MM-DD')
        collection = date.fromisoformat(r['coleta']).strftime('%d/%m/%Y')
        indicators = r['indicadores']
        required = {'femininas', 'millennials', 'distancias_curtas', 'interior', 'terceiro_trimestre', 'concentracao_porte'}
        if not isinstance(indicators, list) or len(indicators) != 6 or {i['id'] for i in indicators} != required:
            raise ValueError('Expected the six approved public indicators, without duplicates')
        rows = {i['id']: i for i in indicators}
        for key, row in rows.items(): number(row['valor'], key, 0, 100)
        h = r['historias']
        raw = {key: number(h[key]['variacao_percentual'], key) for key in ['pareadas', 'provas', 'resultados']}
        raw.update(women_previous=number(h['mulheres']['anterior'], 'women_previous', 0, 100),
                   women_current=number(h['mulheres']['atual'], 'women_current', 0, 100),
                   distance=rows['distancias_curtas']['valor'], interior=rows['interior']['valor'])
        if abs(raw['women_current'] - rows['femininas']['valor']) > 1e-8:
            raise ValueError('Female story and indicator disagree')
        refs = {}
        for key in ['public_cell', 'public_run', 'publication_id', 'publication_run']:
            value = provenance[key]
            if isinstance(value, bool) or not re.fullmatch(r'[1-9][0-9]{0,17}', str(value)):
                raise ValueError(f'Invalid source reference: {key}')
            refs[key] = str(value)
        status = provenance.get('status', 'candidate')
        if status not in {'candidate', 'reviewed'}: raise ValueError('Source status must be candidate or reviewed')
    except (KeyError, TypeError) as error:
        raise ValueError(f'Incomplete public source or provenance: {error}') from error
    v = {key: percent(value, key in {'pareadas', 'provas', 'resultados'}) for key, value in raw.items()}
    source = f"Célula {refs['public_cell']} / congelamento {refs['public_run']}"
    origin = f"Origem: publicação {refs['publication_id']} / congelamento {refs['publication_run']}"
    pending = 'Material candidato; renovação e publicação ainda não confirmadas.' if status == 'candidate' else 'Fonte fornecida e revisada para esta versão.'
    common = 'Janeiro a setembro de 2025 e 2026. Participações, não pessoas únicas. A captura dos resultados pode variar.'
    pitches = [
        dict(slug='provas-cadastradas', kind='comparison', accent='#B6DDCB',
             title='Calendário e mesmas provas: duas leituras.',
             question='Como comparar calendário e participação com contexto?',
             number=v['pareadas'], secondary=v['provas'],
             detail='concluintes nas edições pareadas', secondary_detail='provas no calendário cadastrado',
             note='Recortes diferentes, sujeitos à coleta. Cadastros incluem inativos e cancelados e não comprovam realização.',
             caption=f"Nas edições pareadas, a variação dos concluintes foi de {v['pareadas']}. No calendário cadastrado, foi de {v['provas']}. {common}",
             angle='Compare o calendário conhecido com as edições pareadas. Ouça organizadores sobre continuidade e distribuição de público; os números não isolam crescimento real do mercado.'),
        dict(slug='participacao-feminina', kind='pair', accent='#D8C8F2',
             title='Participação feminina em dois períodos.',
             question='Como esse retrato aparece na sua comunidade?',
             number=v['women_current'], previous=v['women_previous'],
             detail='das participações elegíveis em 2026 são femininas.',
             note='Base: todas as participações elegíveis. Uma pessoa pode concluir várias provas; os dados não explicam causas.',
             caption=f"A participação feminina foi de {v['women_previous']} em 2025 e {v['women_current']} em 2026. {common}",
             angle='Ouça corredoras e organizadores e investigue diferenças por distância e região, sem atribuir causas apenas aos percentuais.'),
        dict(slug='resultados-comparativo', kind='single', accent='#F6BD30',
             title='O que mudou nos resultados registrados?',
             question='Mudança nas provas ou na cobertura da coleta?',
             number=v['resultados'], detail='de variação nos resultados registrados: Jan-Set 2026 versus Jan-Set 2025.',
             note='Variação na base pode refletir captura e importações. Não mede, sozinha, crescimento real do mercado.',
             caption=f"A variação dos resultados registrados foi de {v['resultados']}. {common}",
             angle='Diferencie provas cadastradas, provas com resultados coletados e participações elegíveis. Apure como a cobertura mudou entre os períodos.'),
        dict(slug='distancias-curtas', kind='bar', accent='#D8C8F2',
             title='Percursos curtos na base observada.',
             question='O que as provas curtas representam na sua comunidade?',
             number=v['distance'], value=raw['distance'],
             detail='das participações de rua com distância elegível estão em percursos abaixo de 6 km.',
             note='Percursos positivos cadastrados abaixo de 6 km. Não é uma pesquisa de preferência.',
             caption=f"{v['distance']} das participações de rua com distância elegível estão em percursos positivos inferiores a 6 km. Janeiro a setembro de 2026.",
             angle='Investigue os percursos disponíveis e a experiência de quem participa, distinguindo a oferta observada de preferência declarada.'),
        dict(slug='fora-das-capitais', kind='bar', accent='#B6DDCB',
             title='A corrida além das capitais.',
             question='Quais cidades merecem entrar na conversa?',
             number=v['interior'], value=raw['interior'],
             detail='das participações no recorte de rua ocorreram fora das capitais.',
             note='Localização da prova, não residência do atleta. Registros sem classificação permanecem no denominador.',
             caption=f"{v['interior']} das participações do recorte de rua ocorreram fora das capitais. Janeiro a setembro de 2026; considera o local da prova.",
             angle='Mostre a realidade das provas locais, preservando a distinção entre localização do evento e residência de seus participantes.')]
    for p in pitches:
        p['source'] = source
        p['alt'] = p['caption'] + ' ' + p['note']
    return dict(values=v, raw=raw, collection=collection, collection_iso=r['coleta'], source=source,
                origin=origin, status=status, status_label=pending, pitches=pitches, provenance=refs,
                launch=LAUNCH, methodology=common)


def central_texts(m):
    v = m['values']
    release = f"""Calendário cadastrado: {v['provas']}; nas mesmas provas: {v['pareadas']}

Em 13 de novembro de 2026, o Road Runners apresenta a prévia de O Brasil que Corre Provas. Na comparação de janeiro a setembro de 2025 e 2026, a variação foi de {v['provas']} no calendário cadastrado e {v['pareadas']} nos concluintes das edições pareadas com resultados nos dois anos.

São recortes distintos. O calendário inclui cadastros inativos ou cancelados e não comprova realização. A coorte acompanha apenas as edições pareadas; não representa todas as provas brasileiras. Diferenças na captura dos resultados afetam as duas leituras, que não isolam crescimento real do mercado nem explicam causas.

Nos mesmos nove meses, os resultados registrados variaram {v['resultados']}. As mulheres representaram {v['women_previous']} das participações elegíveis em 2025 e {v['women_current']} em 2026. No recorte de rua de 2026, {v['distance']} das participações com distância elegível ocorreram em percursos positivos abaixo de 6 km; {v['interior']} das participações do recorte de rua ocorreram fora das capitais, considerando o local da prova.

A leitura profissional de janeiro a setembro reúne 37 páginas, com gráficos, tabelas, exportações agregadas e fontes. Jornalistas e criadores podem solicitar acesso editorial. A edição anual de 2026 segue como produto separado, em preparação.

Sobre os dados
São participações, não pessoas únicas: um corredor pode concluir várias provas. Cada indicador tem critérios próprios. A coleta de referência fornecida para os destaques é de {m['collection']}. A base observada não constitui um censo de todas as provas brasileiras.
{m['source']} | {m['origin']}.
{m['status_label']}

Prévia pública: {PUBLIC}
Kit com artes, legendas e fontes: {PUBLIC}kit/
Solicitação de acesso editorial: {EDITORIAL}
"""
    invite = f"""Oi, [nome]! A prévia do Brasil que Corre Provas compara janeiro a setembro de 2025 e 2026: {v['provas']} no calendário cadastrado e {v['pareadas']} nos concluintes das edições pareadas. São universos distintos, sujeitos à cobertura da coleta.

O lançamento editorial está marcado para 13/11/2026. O kit reúne artes para Instagram e YouTube, legendas, fontes e contexto:
{PUBLIC}kit/

Para conhecer a leitura profissional de 37 páginas e solicitar acesso editorial:
{EDITORIAL}

O acesso é uma cortesia editorial, sem obrigação de publicar ou avaliar positivamente. Sua análise é livre. Os números não isolam crescimento real do mercado.
Coleta de referência fornecida: {m['collection']}. {m['status_label']}
"""
    return {'copy-release': release, 'copy-convite': invite}


def patch_central(source, texts):
    result = source
    for key in ['copy-release', 'copy-convite']:
        pattern = r'(<textarea\b[^>]*\bid=[\"\']' + key + r'[\"\'][^>]*>).*?(</textarea>)'
        result, count = re.subn(pattern, lambda match: match[1] + escape(texts[key], quote=False) + match[2], result, flags=re.S)
        if count != 1: raise ValueError(f'Expected exactly one central textarea {key}; found {count}')
    return result


def kit_html(m, version):
    e = escape
    cards = []
    for p in m['pitches']:
        slug = p['slug']
        cards.append(f'''<article class="card" id="pauta-{slug}"><img src="{slug}-1080x1350.png?v={e(version)}" alt="{e(p['alt'])}" width="1080" height="1350" loading="lazy"><div><h2>{e(p['title'])}</h2><p>{e(p['caption'])}</p><p><strong>Contexto:</strong> {e(p['note'])}</p><p><strong>Para apurar:</strong> {e(p['angle'])}</p><p><a href="{slug}-1080x1350.png?v={e(version)}" download>Instagram · PNG</a> · <a href="{slug}-1920x1080.png?v={e(version)}" download>YouTube / apresentações · PNG</a></p></div></article>''')
    v = m['values']
    headline = f"Calendário {v['provas']}; mesmas provas {v['pareadas']}"
    return f'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>Kit editorial · Brasil que Corre Provas 2026</title><meta name="description" content="{e(headline)}. Cinco pautas e contexto para o lançamento de 13/11/2026."><meta property="og:title" content="{e(headline)}"><meta property="og:image" content="{PUBLIC}kit/provas-cadastradas-1920x1080.png?v={e(version)}"><link rel="canonical" href="{PUBLIC}kit/"><style>
@font-face{{font-family:LibreFranklin;src:url('../../web/assets/libre-franklin-latin.woff2') format('woff2');font-weight:100 900;font-display:swap}}@font-face{{font-family:Poppins;src:url('../../web/assets/poppins-400-latin.woff2') format('woff2');font-weight:400;font-display:swap}}@font-face{{font-family:Poppins;src:url('../../web/assets/poppins-600-latin.woff2') format('woff2');font-weight:600;font-display:swap}}
*{{box-sizing:border-box}}body{{margin:0;background:#242424;color:#fff;font:17px/1.6 Poppins,Arial,sans-serif}}main{{max-width:1200px;margin:auto;padding:32px 24px}}a{{color:#f6bd30}}h1{{font:900 clamp(2rem,5vw,4rem)/1.12 LibreFranklin,Arial,sans-serif;max-width:950px}}h2{{font-family:LibreFranklin,Arial,sans-serif;line-height:1.25}}.lead{{font-size:1.3rem}}.tabs{{display:flex;gap:12px;flex-wrap:wrap;padding:20px 0}}.tabs a,.button{{display:inline-block;border:1px solid #777;border-radius:6px;padding:9px 14px}}.card{{display:grid;grid-template-columns:minmax(200px,35%) 1fr;gap:28px;background:#393939;border-radius:12px;padding:24px;margin:28px 0}}img{{width:100%;height:auto}}.note{{color:#cfcfcf}}:focus-visible{{outline:3px solid #f6bd30;outline-offset:4px}}@media(max-width:650px){{.card{{grid-template-columns:1fr}}main{{padding:20px 16px}}}}
</style></head><body><main><a href="../">← Prévia pública</a><p>O BRASIL QUE CORRE PROVAS · LANÇAMENTO EM 13/11/2026</p><h1>Calendário e mesmas provas: duas leituras.</h1><p class="lead">{e(headline)}. Janeiro a setembro de 2025 e 2026, com universos diferentes.</p><p class="note">{e(m['status_label'])}</p><nav aria-label="Conteúdos do kit" class="tabs"><a href="#pautas">Cinco pautas</a><a href="#downloads">Downloads</a><a href="#fontes">Fontes e critérios</a></nav><section id="downloads"><h2>Materiais para baixar</h2><p>Dez artes em dois formatos, PDF de sete páginas, legendas, release e convite curto.</p>''' + ''.join(f'<a class="button" href="{name}?v={e(version)}" download>{label}</a> ' for name, label in [('panorama-publico-jan-set-2026.pdf', 'PDF · sete páginas'), ('legendas-e-fontes.txt', 'Legendas e fontes'), ('release-imprensa-2026.txt', 'Release'), ('convite-criadores.txt', 'Convite curto')]) + f'''</section><section id="pautas"><h2>Cinco pautas para explorar</h2>{''.join(cards)}</section><section id="fontes"><h2>Fontes e critérios</h2><p>{e(m['source'])}. {e(m['origin'])}. Coleta de referência fornecida: {e(m['collection'])}.</p><p>{e(m['methodology'])} Não é um censo nacional. Cadastros incluem inativos e cancelados e não certificam realização. Os percentuais não isolam crescimento real do mercado.</p><p><a href="{EDITORIAL}">Solicitar acesso editorial</a></p></section></main></body></html>'''


def graphics():
    spec = importlib.util.spec_from_file_location('kit_graphics', HERE / 'graphics.py')
    g = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(g)
    return g.Graphics(FONTS)


def footer(g, c, m, note, W, H, period):
    x = 64 if W == 1080 else 90
    g.rect(c, x, H-230, W-2*x, 2, '#626262', H)
    g.txt(c, note, x, H-212, W-2*x, 20 if W == 1080 else 23, H, color='#CFCFCF', leading=29, max_h=92)
    g.txt(c, period + ' | Coleta fornecida: ' + m['collection'], x, H-105, W-2*x, 18, H, color='#CFCFCF')
    g.txt(c, m['source'] + ' | ' + m['origin'], x, H-76, W-2*x, 14 if W == 1080 else 18, H, color='#CFCFCF', max_h=30)
    g.txt(c, 'roadrunners.run/brasilquecorreprovas/2026/', x, H-42, W-2*x, 18, H, color='#F6BD30')
    c.linkURL(PUBLIC, (x, 15, W-x, 60), relative=0)


def draw_pitch(g, c, m, p, portrait=False):
    W, H = (1080, 1350) if portrait else (1920, 1080)
    x = 64 if portrait else 90
    g.rect(c, 0, 0, W, H, '#242424', H)
    g.logo(c, H, x, 48)
    g.txt(c, 'BRASIL QUE CORRE PROVAS / LANÇAMENTO 13/11/2026', x, 125, W-2*x, 22, H, color=p['accent'])
    g.txt(c, p['title'], x, 208 if portrait else 220, 950 if portrait else 1730, 60 if portrait else 66, H, font='Title', leading=73 if portrait else 80, max_h=230 if portrait else 175)
    if p['kind'] == 'comparison':
        for i, (value, label, color) in enumerate([(p['number'], p['detail'], '#B6DDCB'), (p['secondary'], p['secondary_detail'], '#D8C8F2')]):
            bx, by, bw, bh = (64, 450+i*262, 952, 234) if portrait else (90+i*900, 435, 840, 335)
            g.rect(c, bx, by, bw, bh, color, H, 18)
            g.txt(c, value, bx+25, by+12, bw-50, 108 if portrait else 125, H, color='#242424', font='Title', leading=140, max_h=145)
            g.txt(c, label, bx+28, by+150 if portrait else by+182, bw-55, 31, H, color='#242424', font='Medium', leading=39, max_h=82)
    elif p['kind'] == 'pair':
        for i, (year, value) in enumerate([('JAN-SET 2025', p['previous']), ('JAN-SET 2026', p['number'])]):
            bx, by, bw = (69, 450+i*225, 940) if portrait else (100+i*900, 445, 800)
            g.txt(c, year, bx, by, bw, 23, H, color='#CFCFCF')
            g.txt(c, value, bx-8, by+36, bw, 130 if portrait else 145, H, color=p['accent'], font='Title', leading=165, max_h=175)
        g.txt(c, 'Participações femininas na base observada.', 69 if portrait else 100, 925 if portrait else 695, W-2*x, 28, H, max_h=78)
    else:
        bx, by, bw = (56, 480, 960) if portrait else (1030, 400, 795)
        g.txt(c, p['number'], bx, by, bw, 165 if portrait else 155, H, color=p['accent'], font='Title', leading=185, max_h=200)
        g.txt(c, p['detail'], 69 if portrait else 100, 720 if portrait else 470, 923 if portrait else 790, 36, H, leading=48, max_h=155 if portrait else 195)
        if p['kind'] == 'bar':
            bx, by, bw = (69, 920, 942) if portrait else (1040, 700, 755)
            g.rect(c, bx, by, bw, 20, '#393939', H, 10)
            g.rect(c, bx, by, bw*p['value']/100, 20, p['accent'], H, 10)
    g.txt(c, p['question'], 69 if portrait else 92, 1000 if portrait else 790, W-2*x, 28, H, font='Medium', leading=36, max_h=83 if portrait else 72)
    footer(g, c, m, p['note'], W, H, 'Jan-Set 2026' if p['kind'] == 'bar' else 'Jan-Set 2025/2026')


def draw_pitches(g, c, m):
    H = 1080
    g.rect(c, 0, 0, 1920, H, '#242424', H)
    g.logo(c, H, 90, 55)
    g.txt(c, 'DO DADO À PAUTA / LANÇAMENTO EM 13/11/2026', 90, 158, 1740, 24, H, color='#F6BD30')
    g.txt(c, 'Uma pergunta. Três jeitos de contar.', 90, 219, 1740, 66, H, font='Title', leading=80)
    v = m['values']
    items = [('REELS / CARROSSEL', 'Duas medidas, duas populações.', f"Compare {v['pareadas']} nas edições pareadas e {v['provas']} no calendário. Explique os universos e preserve as ressalvas."),
             ('YOUTUBE / REVIEW', 'O que a coleta permite observar?', f"Contextualize a variação de {v['resultados']} nos resultados registrados. Mais ou menos registros não isolam crescimento real do mercado."),
             ('IMPRENSA / MATÉRIA', 'Do indicador à apuração local.', f"Parta dos recortes e investigue a realidade local. Participação feminina: {v['women_previous']} em 2025 e {v['women_current']} em 2026.")]
    for i, (tag, title, body) in enumerate(items):
        x = 90+i*589
        g.rect(c, x, 369, 550, 465, '#393939', H, 18)
        g.txt(c, tag, x+28, 397, 490, 22, H, color='#F6BD30')
        g.txt(c, title, x+28, 459, 490, 33, H, font='Title', leading=42, max_h=145)
        g.txt(c, body, x+28, 623, 490, 25, H, color='#CFCFCF', leading=34, max_h=190)
    g.txt(c, 'Artes, release, convite curto e fontes:', 90, 890, 1740, 28, H)
    g.txt(c, PUBLIC+'kit/', 90, 940, 1740, 28, H, color='#F6BD30')
    c.linkURL(PUBLIC+'kit/', (90, 80, 1780, 150), relative=0)
    g.txt(c, m['status_label'], 90, 1002, 1740, 21, H, color='#CFCFCF')


def draw_method(g, c, m):
    H = 1080
    g.rect(c, 0, 0, 1920, H, '#242424', H)
    g.logo(c, H, 90, 55)
    g.txt(c, 'ANTES DE COMPARTILHAR', 90, 170, 1740, 25, H, color='#F6BD30')
    g.txt(c, 'O contexto faz parte do dado.', 90, 244, 1740, 72, H, font='Title', leading=90)
    items = [('01', 'Participações', 'Uma pessoa pode concluir várias provas. Participações e conclusões registradas não são pessoas únicas nem um censo nacional.'),
             ('02', 'Períodos iguais', 'Janeiro a setembro de 2025 e 2026. Edições pareadas e calendário cadastrado representam populações distintas.'),
             ('03', 'Coleta e cadastro', 'A captura pode variar entre anos e temas. Cadastros incluem inativos e cancelados. Os indicadores não isolam crescimento real do mercado.')]
    for i, (num, title, body) in enumerate(items):
        x = 90+i*589
        g.rect(c, x, 428, 550, 365, '#393939', H, 18)
        g.txt(c, num, x+30, 451, 490, 42, H, color='#F6BD30', font='Title')
        g.txt(c, title, x+30, 520, 490, 33, H, font='Bold', max_h=90)
        g.txt(c, body, x+30, 594, 484, 25, H, color='#CFCFCF', leading=35, max_h=175)
    g.txt(c, 'Coleta de referência fornecida: ' + m['collection'] + '. Lançamento: ' + LAUNCH, 90, 840, 1740, 27, H)
    g.txt(c, m['status_label'], 90, 890, 1740, 23, H, color='#CFCFCF')
    g.txt(c, PUBLIC, 90, 944, 1740, 28, H, color='#F6BD30')
    g.txt(c, m['source'] + ' | ' + m['origin'], 90, 1005, 1740, 20, H, color='#CFCFCF')


def generate(payload, provenance, destination, central_source=None):
    from reportlab.pdfgen import canvas
    from pypdf import PdfReader
    from PIL import Image
    m = build_model(payload, provenance)
    destination = Path(destination).resolve()
    if destination == RR.resolve() or destination in [RR.resolve() / 'brasilquecorreprovas', RR.resolve() / 'brasilquecorreprovas/2026/kit']:
        raise ValueError('Destination must be an isolated candidate directory')
    kit = destination / KIT_PATH
    qa = destination / 'qa'
    kit.mkdir(parents=True, exist_ok=True)
    qa.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps({'payload': payload, 'provenance': provenance}, ensure_ascii=False, sort_keys=True, allow_nan=False)
    version = 'source-' + hashlib.sha256(serialized.encode()).hexdigest()[:14]
    g = graphics()
    pdf = kit / 'panorama-publico-jan-set-2026.pdf'
    c = canvas.Canvas(str(pdf), pagesize=(1920, 1080), pageCompression=1, invariant=1)
    c.setTitle('Brasil que Corre Provas 2026 | Kit editorial 13/11')
    c.setAuthor('Road Runners')
    c.setSubject(m['source'] + ' | ' + m['origin'])
    for p in m['pitches'][:3]: draw_pitch(g, c, m, p); c.showPage()
    draw_pitches(g, c, m); c.showPage()
    for p in m['pitches'][3:]: draw_pitch(g, c, m, p); c.showPage()
    draw_method(g, c, m); c.showPage(); c.save()
    reader = PdfReader(pdf)
    if len(reader.pages) != 7: raise ValueError('Expected seven kit pages')
    pdftext = '\n'.join(page.extract_text() for page in reader.pages)
    for value in m['values'].values():
        if value not in pdftext: raise ValueError('Generated PDF omitted source value: ' + value)
    with tempfile.TemporaryDirectory(prefix='rr-kit-refresh-media-') as tmp:
        tmp = Path(tmp)
        subprocess.run(['pdftoppm', '-r', '72', '-png', str(pdf), str(tmp/'page')], check=True, capture_output=True, timeout=90)
        for i, p in enumerate(m['pitches']):
            page = i+1 if i < 3 else i+2
            with Image.open(tmp/f'page-{page}.png') as im:
                if im.size != (1920, 1080): raise ValueError('Unexpected PDF raster size')
                im.save(kit/f"{p['slug']}-1920x1080.png", optimize=True)
            portrait = tmp/f"{p['slug']}.pdf"
            c = canvas.Canvas(str(portrait), pagesize=(1080, 1350), invariant=1)
            draw_pitch(g, c, m, p, True); c.showPage(); c.save()
            subprocess.run(['pdftoppm', '-r', '72', '-png', '-singlefile', str(portrait), str(tmp/p['slug'])], check=True, capture_output=True, timeout=30)
            with Image.open(tmp/f"{p['slug']}.png") as im:
                if im.size != (1080, 1350): raise ValueError('Unexpected portrait raster size')
                im.save(kit/f"{p['slug']}-1080x1350.png", optimize=True)
        for n in range(1, 8):
            with Image.open(tmp/f'page-{n}.png') as im:
                im.resize((1280, 720)).save(qa/f'pdf-{n}.png')
        contact = Image.new('RGB', (960, 1160), '#eeeeee')
        for n in range(1, 8):
            with Image.open(tmp/f'page-{n}.png') as im:
                im.thumbnail((470, 265)); contact.paste(im, (((n-1) % 2)*480, ((n-1)//2)*290))
        contact.save(qa/'pdf-contact.png')
    for size in ['1080x1350', '1920x1080']:
        shutil.copyfile(kit/f'provas-cadastradas-{size}.png', kit/f'fevereiro-comparativo-{size}.png')
    texts = central_texts(m)
    (kit/'index.html').write_text(kit_html(m, version), encoding='utf-8')
    (kit/'release-imprensa-2026.txt').write_text(texts['copy-release'], encoding='utf-8')
    (kit/'convite-criadores.txt').write_text(texts['copy-convite'], encoding='utf-8')
    captions = ['O BRASIL QUE CORRE PROVAS 2026 | KIT EDITORIAL', m['status_label'], 'Lançamento: '+LAUNCH]
    for p in m['pitches']:
        captions += ['', p['title'], 'LEGENDA', p['caption'], 'CONTEXTO', p['note'], 'PAUTA', p['angle'], 'TEXTO ALTERNATIVO', p['alt']]
    captions += ['', m['source'], m['origin'], 'Coleta de referência fornecida: '+m['collection'], PUBLIC]
    (kit/'legendas-e-fontes.txt').write_text('\n'.join(captions)+'\n', encoding='utf-8')
    (destination/'central-texts.json').write_text(json.dumps(texts, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    if central_source is not None:
        central = destination/'business/estudos/lancamento/index.cfm'
        central.parent.mkdir(parents=True, exist_ok=True)
        central.write_text(patch_central(central_source, texts), encoding='utf-8')
    manifest = {'status': m['status'], 'source_sha256': hashlib.sha256(serialized.encode()).hexdigest(),
                'provenance': m['provenance'], 'collection': m['collection_iso'], 'version': version,
                'pdf_pages': 7, 'artworks': 10, 'legacy_aliases': 2,
                'files': {str(p.relative_to(destination)): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in sorted(kit.iterdir()) if p.is_file()}}
    (qa/'model.json').write_text(json.dumps(m, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (qa/'layout.json').write_text(json.dumps(g.layout, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (qa/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True, type=Path, help='Explicit fonte-publica.json with the public projection')
    parser.add_argument('--provenance', required=True, type=Path, help='Source IDs and candidate/reviewed status JSON')
    parser.add_argument('--output-dir', required=True, type=Path, help='Isolated candidate root; creates portal/.../kit below it')
    parser.add_argument('--central-source', type=Path, help='Optional CURRENT central file; replace only its two textareas in candidate')
    args = parser.parse_args()
    result = generate(json.loads(args.source.read_text()), json.loads(args.provenance.read_text()),
                      args.output_dir, args.central_source.read_text() if args.central_source else None)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__': main()
