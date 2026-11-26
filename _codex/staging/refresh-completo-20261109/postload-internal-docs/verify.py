"""Offline QA and packaging for the isolated internal launch PDFs. No live writes."""
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import difflib
import hashlib
import json
import shutil
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
BUSINESS = HERE.parents[3]
RR = BUSINESS.parent / 'RoadRunners'
PDF = HERE / 'output/pdf'
RUNTIME = HERE / 'runtime/business'
QA = HERE / 'qa'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
baseline = json.loads((HERE / 'baseline-manifest.json').read_text())
facts = json.loads((HERE / 'facts.json').read_text())

assert facts == {'snapshot': 42, 'main_run': 351, 'main_cell': 251,
                 'public_run': 352, 'public_cell': 420, 'cohort_run': 329,
                 'pairs': 615, 'cutoff': '2026-09-30', 'collection': '2026-11-09',
                 'matched': '2,2%', 'calendar': '38,7%', 'volume': '29,3%',
                 'women_before': '52,5%', 'women_after': '53,8%',
                 'short': '61,4%', 'interior': '48,0%'}

router_path = RUNTIME / 'estudos/lancamento/arquivo.cfm'
old_router = (HERE / 'baseline/estudos/lancamento/arquivo.cfm').read_text()
new_router = router_path.read_text()
new_line = "    'execucao-v7':'brasil-que-corre-provas-lancamento-q3-execucao-v7.pdf',\n"
assert new_router.count(new_line) == 1
assert new_router.replace(new_line, '') == old_router
assert old_router.startswith('<cfinclude template="_admin.cfm"/>')
patch = ''.join(difflib.unified_diff(old_router.splitlines(True), new_router.splitlines(True),
                                   fromfile='a/estudos/lancamento/arquivo.cfm',
                                   tofile='b/estudos/lancamento/arquivo.cfm'))
(HERE / 'arquivo-v7.patch').write_text(patch)

common = ['+2,2%', '+38,7%', '+29,3%', '615', '37 páginas', '42/run 351',
          '420/run 352', '95', 'READY', '24/11', '13/11', '12/11',
          '50%', '2027', 'Leo e Carlos']
stale = ['+2,1%', '+33,9%', '+27,3%', '53,9%', '41/run 233',
         '420/run 239', 'panorama 2026: 06/10']
items = []
for filename, pages, expected_links in [
    ('brasil-que-corre-provas-guia-rapido-q3.pdf', 1, 11),
    ('brasil-que-corre-provas-lancamento-q3-execucao-v7.pdf', 8, 3),
]:
    path = PDF / filename
    pdf = PdfReader(path)
    assert len(pdf.pages) == pages
    text = '\n'.join(p.extract_text() for p in pdf.pages)
    normalized = ' '.join(text.split())
    for value in common:
        assert value in normalized, (filename, value)
    for value in stale:
        assert value not in normalized, (filename, value)
    assert '\ufffd' not in text
    links, fonts = [], set()
    for n, page in enumerate(pdf.pages, 1):
        assert len(page.extract_text()) > 200
        width, height = float(page.mediabox.width), float(page.mediabox.height)
        for ref in page.get('/Annots') or []:
            obj = ref.get_object()
            action = obj.get('/A') or {}
            if action.get('/S') != '/URI':
                continue
            url = str(action['/URI'])
            parsed = urlparse(url)
            assert parsed.scheme == 'https'
            assert parsed.netloc in ['business.roadrunners.run', 'roadrunners.run']
            if parsed.path.endswith('/arquivo.cfm'):
                doc = parse_qs(parsed.query)['doc'][0]
                assert "'" + doc + "':" in new_router, doc
            x0, y0, x1, y1 = map(float, obj['/Rect'])
            assert 0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height
            links.append({'page': n, 'url': url})
        for ref in page['/Resources'].get('/Font', {}).values():
            font = ref.get_object()
            descriptor = font.get('/FontDescriptor')
            if descriptor:
                assert '/FontFile2' in descriptor.get_object()
                fonts.add(str(font['/BaseFont']).split('+')[-1])
    assert len(links) == expected_links
    # The existing Libre Franklin TTF variants retain the same internal PS name
    # (LibreFranklin-Thin). Preserve embedded names and source-file hashes rather
    # than inferring the weight from the internal metadata.
    assert {'Poppins-Regular', 'Poppins-SemiBold'} <= fonts, fonts
    assert any(name.startswith('LibreFranklin-') for name in fonts), fonts
    historical_name = filename.replace('execucao-v7.pdf', 'execucao-v6.pdf')
    historical = PdfReader(HERE / 'baseline/estudos/lancamento/arquivos' / historical_name)
    historical_fonts = {str(ref.get_object()['/BaseFont']).split('+')[-1]
                        for page in historical.pages
                        for ref in page['/Resources'].get('/Font', {}).values()
                        if ref.get_object().get('/FontDescriptor')}
    assert fonts == historical_fonts, (fonts, historical_fonts)
    if pages == 8:
        for value in ['52,5% em 2025 - 53,8% em 2026', '61,4%', '48,0%',
                      '387/run 329', '30/09/2026', 'Anual DRAFT',
                      'Rascunho interno (DRAFT)', 'Sem oferta anual ativa',
                      '10-11 NOV', 'cinco pautas', 'dez artes', 'sete páginas',
                      'Checkout anual pendente', 'PROPOSTAS']:
            assert value in normalized, value
        assert [float(pdf.pages[0].mediabox.width), float(pdf.pages[0].mediabox.height)] == [1280, 720]
    else:
        for value in ['Execução v7 / plano atual', 'Execução v6 / histórico',
                      'Execução v5 / histórico', 'ANUAL 2026 - RASCUNHO',
                      '10-11/11', 'coleta 09/11', 'não pessoas únicas']:
            assert value in normalized, value
    (QA / (path.stem + '.txt')).write_text(text)
    target = RUNTIME / 'estudos/lancamento/arquivos' / filename
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)
    assert sha(target) == sha(path)
    items.append({'filename': filename, 'sha256': sha(path), 'bytes': path.stat().st_size,
                  'pages': pages, 'text_characters': len(text),
                  'embedded_fonts': sorted(fonts), 'links': links})

assert len(PdfReader(HERE / 'baseline/estudos/lancamento/arquivos/brasil-que-corre-provas-lancamento-q3-execucao-v6.pdf').pages) == 8
guide_boxes = json.loads((PDF / 'guia_rapido_pdf_qa-20261109.json').read_text())['text_boxes']
execution_boxes = json.loads((PDF / 'execucao-layout-v7.json').read_text())
for boxes, width, height in [(guide_boxes, 841.8897637795277, 595.2755905511812),
                             (execution_boxes, 1280, 720)]:
    for item in boxes:
        x, y, w, h = item['box']
        assert min(x, y, w, h) >= 0
        assert x + w <= width + 0.01 and y + h <= height + 0.01

assert (QA / 'guia.png').exists()
for page in range(1, 9):
    assert (QA / f'execucao-{page}.png').exists()
for rel, expected in baseline['runtime'].items():
    assert sha(BUSINESS / rel) == expected, ('Actual runtime changed', rel)
    assert sha(HERE / 'baseline' / rel) == expected
source = RR / '_codex/docs/brasil_que_corre_provas/lancamento_q3_2026_10_09'
for name, expected in baseline['generators'].items():
    assert sha(source / name) == expected, ('Historical generator changed', name)

verification = {
    'status': 'PASS', 'review_date': '2026-11-09', 'facts': facts, 'pdfs': items,
    'visual_review': {'reviewed': True, 'guide_pages': [1], 'execution_pages': list(range(1, 9)),
                      'findings': 'All 9 rendered pages inspected; legible, no clipping or text overlap.'},
    'router_check': 'Only one additive v7 route; admin guard and v6/v5 mappings byte-for-byte preserved.',
    'preservation_check': 'Runtime index/router/guide/v6/v5 and historical source generators unchanged.',
    'scope': 'Internal guide and execution only; no Maratonas PDF, DB operations, publication or Git.',
    'integration_limits': 'Central index remains unchanged and still points to v6; controller coordinates its v7 link. Authenticated download and deployed headers remain to be verified after coordinated publication.',
    'resources': 'No browser/server/driver/watcher/background process created; finite rendering commands exited.',
}
(HERE / 'verification.json').write_text(json.dumps(verification, ensure_ascii=False, indent=2) + '\n')
artifacts = []
for path in sorted(RUNTIME.rglob('*')):
    if path.is_file():
        destination = str(path.relative_to(RUNTIME))
        artifacts.append({'candidate': str(path.relative_to(HERE)), 'destination': destination,
                          'sha256': sha(path), 'bytes': path.stat().st_size,
                          'baseline_sha256': baseline['runtime'].get(destination)})
assert len(artifacts) == 3
manifest = {'scope': 'Isolated internal documents candidate; not published', 'facts': facts,
            'artifacts': artifacts, 'baseline': baseline,
            'sources': {str(p.relative_to(HERE.parent)): sha(p) for p in
                        [HERE.parent / f'postload/runs/{cell}.json' for cell in [251, 420, 387]]},
            'generators': {p.name: sha(p) for p in sorted((HERE / 'generators').glob('*.py'))},
            'verification_sha256': sha(HERE / 'verification.json'),
            'patch_sha256': sha(HERE / 'arquivo-v7.patch')}
(HERE / 'candidate-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'status': 'PASS', 'artifacts': artifacts,
                  'manifest_sha256': sha(HERE / 'candidate-manifest.json')}, ensure_ascii=False))
