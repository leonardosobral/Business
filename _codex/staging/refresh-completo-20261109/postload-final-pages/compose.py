"""Compose final central/public shell candidates from current saved baselines.

Local files only. Does not write the canonical runtime, use SQL, or publish.
"""
from pathlib import Path
from html.parser import HTMLParser
import difflib
import hashlib
import json
import re
import subprocess

HERE = Path(__file__).resolve().parent
STAGE = HERE.parent
BUSINESS = HERE.parents[3]
RR = BUSINESS.parent / 'RoadRunners'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
baseline = json.loads((HERE / 'baseline-manifest.json').read_text())

def once(text, before, after):
    assert text.count(before) == 1, (before, text.count(before))
    return text.replace(before, after)

def textarea(text, name):
    pattern = r'(<textarea\b[^>]*\bid="' + re.escape(name) + r'"[^>]*>)(.*?)(</textarea>)'
    matches = list(re.finditer(pattern, text, re.S))
    assert len(matches) == 1, name
    return matches[0]

class Textareas(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.active = None
        self.values = {}
    def handle_starttag(self, tag, attrs):
        if tag == 'textarea':
            self.active = dict(attrs).get('id')
            self.values[self.active] = ''
    def handle_data(self, data):
        if self.active:
            self.values[self.active] += data
    def handle_endtag(self, tag):
        if tag == 'textarea':
            self.active = None

for rel, item in baseline.items():
    assert sha(Path(item['source'])) == item['sha256'], ('Canonical changed since baseline', rel)
    assert sha(HERE / 'baseline' / rel) == item['sha256']

central_rel = 'business/estudos/lancamento/index.cfm'
public_rel = 'portal/brasilquecorreprovas/2026/pagina.html'
fixture_rel = 'portal/brasilquecorreprovas/2026/public-preview.json'
old_central = (HERE / 'baseline' / central_rel).read_text()
old_public = (HERE / 'baseline' / public_rel).read_text()
media_path = STAGE / 'postload-media/candidate/business/estudos/lancamento/index.cfm'
media_central = media_path.read_text()
media_texts = json.loads((STAGE / 'postload-media/candidate/central-texts.json').read_text())
run_path = STAGE / 'postload/runs/420.json'
run = json.loads(run_path.read_text())
assert str(run['run']['id']) == '352' and str(run['run']['cell_id']) == '420'
assert run['run']['cell_version'] == 7 and run['run']['frozen'] and not run['run']['truncated']
assert run['run']['status'] == 'ok' and run['run']['row_count'] == 1
public = run['data']['result']['rows'][0]['payload']
public = json.loads(public) if isinstance(public, str) else public
assert public == json.loads((STAGE / 'postload-media/fonte-publica.json').read_text())
assert set(public) == {'ok', 'release'} and public['ok'] is True
r = public['release']
assert r['coleta'] == '2026-11-09'
assert r['historias']['pareadas']['variacao_percentual'] == 2.2
assert r['historias']['provas']['variacao_percentual'] == 38.7
assert r['historias']['mulheres']['diferenca_pp'] == 1.4

central = old_central
for name in ['copy-release', 'copy-convite']:
    source = textarea(media_central, name)
    target = textarea(central, name)
    assert source.group(1) == target.group(1)
    assert '</textarea' not in source.group(2).lower()
    central = central[:target.start(2)] + source.group(2) + central[target.end(2):]
parser = Textareas()
parser.feed(central)
for name, value in media_texts.items():
    assert parser.values[name] == value, name

for before, after in [
    ('+2,1%', '+2,2%'), ('+33,9%', '+38,7%'),
]:
    # Both remaining occurrences are current scope/kit calls, outside the
    # injected textareas and the explicitly historical PDF cards.
    assert central.count(before) == 2, (before, central.count(before))
    central = central.replace(before, after)
central = once(central, 'Textos atualizados em 04/11/2026 para o lançamento de 13/11.',
               'Textos e coleta de referência atualizados em 09/11/2026 para o lançamento de 13/11.')
central = once(central, 'Os congelamentos e as datas de coleta de cada bloco ficam identificados no notebook.',
               'Coleta de referência dos destaques: 09/11/2026. Notebook: snapshot 42/run 351; narrativa pública 420/run 352. Os congelamentos e as datas de cada bloco ficam identificados no notebook.')
old_v6 = re.search(r'<a href="arquivo\.cfm\?doc=execucao-v6">.*?</a>', central).group()
current_v7 = ('<a href="arquivo.cfm?doc=execucao-v7"><div><span class="tag current">PLANO ATUAL · 8 TELAS</span>'
              '<h3>Execução do lançamento · v7</h3><p>Fonte renovada em 09/11: +2,2% em 615 pares e +38,7% no calendário cadastrado. '
              'Escopo Jan–Set e preparação para 13/11. ABRACEO em negociação contratual.</p></div><b>PDF ↓</b></a>')
historical_v6 = ('<a href="arquivo.cfm?doc=execucao-v6"><div><span class="tag archive">HISTÓRICO · 8 TELAS</span>'
                 '<h3>Execução do lançamento · v6</h3><p>Fechamento editorial anterior de 09/11, preservado. '
                 'Para conteúdo, materiais e próximos passos, use a v7.</p></div><b>PDF ↓</b></a>')
central = once(central, old_v6, current_v7 + '\n' + historical_v6)
assert central.count('use a v6.') == 3
central = central.replace('use a v6.', 'use a v7.')
central = once(central, 'Para o cronograma, vale a v6.', 'Para o cronograma, vale a v7.')

public_html = old_public
public_html = once(public_html, '?v=20261104-edicoes-calendario', '?v=20261109-refresh-q3')
public_html = once(public_html,
    'Comparativo Jan–Set 2025–2026: +2,1% nos concluintes das mesmas provas e +33,9% no calendário cadastrado. Universos distintos, sujeitos à coleta.',
    'Comparativo Jan–Set 2025–2026: +2,2% nos concluintes das mesmas provas e +38,7% no calendário cadastrado. Universos distintos, sujeitos à coleta.')
description = ('Jan–Set 2025–2026: +2,2% nas mesmas provas e +38,7% no calendário cadastrado. '
               'Universos distintos, sujeitos à coleta. Conheça a prévia profissional.')
public_html = once(public_html,
    'O que mudou na corrida de 2025 para 2026? Compare janeiro a setembro e conheça os recortes da prévia profissional do Brasil que Corre Provas.',
    description)
public_html = once(public_html,
    'Mais provas no calendário, alta menor nas mesmas provas. Compare janeiro a setembro de 2025 e 2026 e conheça os destaques do Brasil que Corre Provas.',
    description)
# Keep the hero copy, dynamic charts, script and protected editorial form intact.

candidate = HERE / 'candidate'
outputs = {central_rel: central,
           public_rel: public_html,
           fixture_rel: json.dumps(public, ensure_ascii=False, indent=2) + '\n'}
for rel, content in outputs.items():
    path = candidate / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    old = (HERE / 'baseline' / rel).read_text()
    diff = ''.join(difflib.unified_diff(old.splitlines(True), content.splitlines(True),
                                      fromfile='a/' + rel, tofile='b/' + rel))
    patch = HERE / 'patches' / (rel.replace('/', '__') + '.patch')
    patch.parent.mkdir(exist_ok=True)
    patch.write_text(diff)

# Guard the central's dynamic checklist, owners, forms, CSRF and scripts exactly.
assert central[:central.index('<section id="escopo-q3"')] == old_central[:old_central.index('<section id="escopo-q3"')]
assert central[central.index('<section class="strategy">'):] == old_central[old_central.index('<section class="strategy">'):]
assert central.count('class="tag current"') == 1
assert re.search(r'<a href="arquivo\.cfm\?doc=execucao-v7">.*?class="tag current"', central)
for version in [6, 5, 4, 3]:
    card = re.search(r'<a href="arquivo\.cfm\?doc=execucao-v' + str(version) + r'">.*?</a>', central).group()
    assert 'class="tag archive"' in card and 'HISTÓRICO' in card, version
assert central.count('doc=execucao-v7') == 1
for value in ['+2,1%', '+33,9%', '53,9%', '61,2%', '47,5%', '27,3%', '6 de outubro de 2026']:
    assert value not in central, value
for value in ['snapshot 42/run 351', '420/run 352', '09/11/2026', '37 páginas',
              'Pendente: aprovação do contrato com a ABRACEO.', '13 de novembro de 2026']:
    assert value in central, value
router = STAGE / 'postload-internal-docs/runtime/business/estudos/lancamento/arquivo.cfm'
router_text = router.read_text()
for version in [7, 6, 5]:
    assert "'execucao-v" + str(version) + "':" in router_text
assert public_html[public_html.index('</head>'):] == old_public[old_public.index('</head>'):]
assert 'data-endpoint="public-preview.json"' in public_html
assert '__PRESS_CSRF__' in public_html
assert '<meta name="robots" content="noindex,nofollow">' in public_html
assert '+2,1%' not in public_html and '+33,9%' not in public_html

# Validate the fixture against the existing production JS parser, unchanged.
js = RR / 'brasilquecorreprovas/2026/estudo-publico.js'
node_program = """const fs=require('fs');
const api=require(process.argv[1]);
const payload=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
const r=api.readRelease(payload);
if(r.indicadores.length!==6 || r.coleta!=='09/11/2026')throw Error('Fixture incompatible');
if(r.historias.mulheres.diferenca_pp!==1.4)throw Error('Rounded difference altered');
console.log(JSON.stringify({status:'PASS',indicators:r.indicadores.length,coleta:r.coleta,stories:r.historias}));"""
node = subprocess.run(['node', '-e', node_program, str(js), str(candidate / fixture_rel)],
                      capture_output=True, text=True, check=True)
node_result = json.loads(node.stdout)

for rel, item in baseline.items():
    assert sha(Path(item['source'])) == item['sha256'], ('Canonical changed while composing', rel)

verification = {'status': 'PASS', 'date': '2026-11-09',
    'public_source': {'cell': 420, 'revision': 7, 'run': 352, 'snapshot': 42, 'main_run': 351},
    'public_fixture': 'Exact public payload from the frozen run, without run metadata or private SQL.',
    'fixture_current_js_test': node_result,
    'central': 'Media textareas identical; dynamic checklist/owners/forms/CSRF, strategy, deadlines and scripts preserved. V7 current; v6/v5 historical.',
    'hotsite': 'Only metadata changed: image cache key, image alt, description and OG description. Body/JS/CSRF/endpoint unchanged.',
    'canonical_runtime': 'All three canonical source hashes unchanged after generation.',
    'limits': 'No browser layout, CFML execution, DB queries or deployed HTTP verification. Controller must integrate new kit art, PDF/router and coordinated DB snapshot/view cutover.',
    'resources': 'No browser/server/background process created. Finite Node check exited.'}
(HERE / 'verification.json').write_text(json.dumps(verification, ensure_ascii=False, indent=2) + '\n')
artifacts = []
for rel in outputs:
    path = candidate / rel
    artifacts.append({'candidate': str(path), 'target_project': rel.split('/')[0],
                      'destination': rel.split('/', 1)[1], 'before_sha256': baseline[rel]['sha256'],
                      'after_sha256': sha(path), 'bytes': path.stat().st_size})
manifest = {'scope': 'Three final page/fixture candidates only; local, unpublished.',
    'artifacts': artifacts, 'source_run_sha256': sha(run_path),
    'source_textareas_sha256': sha(media_path),
    'source_texts_json_sha256': sha(STAGE / 'postload-media/candidate/central-texts.json'),
    'dependencies': {'pdf_router': str(router), 'pdf_router_sha256': sha(router),
                     'kit': str(STAGE / 'postload-media/candidate/portal/brasilquecorreprovas/2026/kit'),
                     'dynamic_js_sha256': sha(js),
                     'live_shell_sha256': sha(RR / 'brasilquecorreprovas/2026/index.cfm'),
                     'live_endpoint_sha256': sha(RR / 'brasilquecorreprovas/2026/dados.cfm')},
    'verification_sha256': sha(HERE / 'verification.json')}
(HERE / 'candidate-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
assembler = {'scope': 'Final central/public static pages and public-only local fixture.',
             'files': {rel: {'candidate': 'candidate/' + rel,
                             'candidate_sha256': sha(candidate / rel),
                             'before_sha256': baseline[rel]['sha256']}
                       for rel in outputs},
             'source': {'cell': 420, 'revision': 7, 'run': 352,
                        'snapshot': 42, 'main_run': 351},
             'verification_sha256': sha(HERE / 'verification.json')}
(HERE / 'manifest.json').write_text(json.dumps(assembler, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'status': 'PASS', 'manifest_sha256': sha(HERE / 'manifest.json'),
                  'artifacts': artifacts}, ensure_ascii=False))
