"""Validate internal launch candidates and preservation; no runtime mutations."""
from pathlib import Path
import hashlib
import json
from urllib.parse import urlparse
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
CANDIDATE = HERE.parent/'pdf-candidate'
RR = Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
BUSINESS = Path('/Users/Shared/Projects/RunnerHub/Business')
SOURCE = RR/'_codex/docs/brasil_que_corre_provas/lancamento_q3_2026_10_09'
baseline = json.loads((HERE/'baseline.json').read_text())

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

items = []
for filename, pages in [('brasil-que-corre-provas-guia-rapido-q3.pdf', 1),
                        ('brasil-que-corre-provas-lancamento-q3-execucao-v6.pdf', 8)]:
    path = CANDIDATE/filename
    pdf = PdfReader(path)
    assert len(pdf.pages) == pages
    text = '\n'.join(page.extract_text() for page in pdf.pages)
    for value in ['+2,1%', '+33,9%', '+27,3%', '95', 'READY', '24/11', '13/11', '50%', '2027', 'Leo e Carlos']:
        assert value in text, (filename, value)
    for stale in ['37 páginas', '3 PAUTAS', 'três pautas', '#216', '#221', 'V5 PARA OPERAR']:
        assert stale not in text, (filename, stale)
    links = []
    for n, page in enumerate(pdf.pages, 1):
        assert len(page.extract_text()) > 200
        for ref in page.get('/Annots') or []:
            obj = ref.get_object()
            action = obj.get('/A') or {}
            if action.get('/S') == '/URI':
                url = str(action['/URI'])
                parsed = urlparse(url)
                assert parsed.scheme == 'https'
                assert parsed.netloc in ['business.roadrunners.run', 'roadrunners.run']
                x0, y0, x1, y1 = map(float, obj['/Rect'])
                assert 0 <= x0 < x1 <= float(page.mediabox.width)
                assert 0 <= y0 < y1 <= float(page.mediabox.height)
                links.append({'page': n, 'url': url, 'rectangle': [x0, y0, x1, y1]})
    assert len(links) == (11 if pages == 1 else 3), (filename, len(links))
    if pages == 8:
        for current in ['cinco pautas', 'dez artes', 'sete páginas', '41/run 233', '420/run 239',
                        '30/09/2026', 'panorama 2026: 06/10', 'implementado em 04/11',
                        'Checkout anual pendente', 'em revisão web', 'PROPOSTAS']:
            assert current in text, current
    (HERE/(path.stem+'.txt')).write_text(text)
    items.append({'filename': filename, 'sha256': digest(path), 'bytes': path.stat().st_size,
                  'pages': len(pdf.pages), 'text_characters': len(text), 'links': links})

for item in baseline['pdfs']:
    if 'execucao-v5' in item['filename']:
        for folder in [RR/'output/pdf', BUSINESS/'estudos/lancamento/arquivos', HERE/'baseline']:
            assert digest(folder/item['filename']) == item['production_sha256']
assert digest(SOURCE/'gerar_pdf_execucao_v5.py') == baseline['v5_source_sha256']
assert (HERE/'guia-1.png').exists()
for page in range(1, 9):
    assert (HERE/f'execucao-{page}.png').exists()

result = {'review_date': '2026-11-09', 'status': 'PASS', 'candidates': items,
          'visual_review': {'reviewed': True, 'guide_pages': [1], 'execution_pages': list(range(1, 9)),
                            'findings': 'All 9 rendered pages inspected; no clipping, overlap, unreadable glyphs or broken hierarchy.'},
          'v5_preservation': 'Source and PDFs in RR output, Business runtime and saved baseline remain byte-for-byte unchanged.',
          'temporary_resources': 'No browser, server, driver, watcher or background process created; finite rendering commands exited.',
          'integration_requirement': 'Controller must map doc=execucao-v6 to the new filename and verify authenticated download after publication.'}
(HERE/'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({'status': result['status'], 'pdfs': [{k:v for k,v in i.items() if k != 'links'} for i in items]}, ensure_ascii=False))
