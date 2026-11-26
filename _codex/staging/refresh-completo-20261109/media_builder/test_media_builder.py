"""Regression tests for source-driven editorial assets; no production/DB access."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
OLD = HERE.parents[4] / 'RoadRunners/_codex/docs/brasil_que_corre_provas/kit_lancamento_2026_11_13/fonte-publica.json'


def module():
    path = HERE / 'media_builder.py'
    if not path.is_file():
        raise AssertionError('The source-driven media builder does not exist yet')
    spec = importlib.util.spec_from_file_location('media_builder', path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def fixture():
    return json.loads(OLD.read_text())


def changed():
    data = fixture()
    r = data['release']
    r['coleta'] = '2026-11-09'
    r['historias']['pareadas']['variacao_percentual'] = -4.8
    r['historias']['provas']['variacao_percentual'] = 18.6
    r['historias']['resultados']['variacao_percentual'] = -12.7
    r['historias']['mulheres'].update(anterior=44.4, atual=46.8, diferenca_pp=2.4)
    for row in r['indicadores']:
        if row['id'] in {'femininas', 'distancias_curtas', 'interior'}:
            row['valor'] = {'femininas': 46.8, 'distancias_curtas': 62.3, 'interior': 48.6}[row['id']]
    return data


PROVENANCE = {'public_cell': 420, 'public_run': 9001, 'publication_id': 9002,
              'publication_run': 9003, 'status': 'candidate'}


class SourceDrivenKit(unittest.TestCase):
    def test_all_five_pitches_follow_changed_source(self):
        m = module().build_model(changed(), PROVENANCE)
        self.assertEqual(len(m['pitches']), 5)
        text = json.dumps(m, ensure_ascii=False)
        for current in ['-4,8%', '+18,6%', '-12,7%', '44,4%', '46,8%', '62,3%', '48,6%', '09/11/2026']:
            self.assertIn(current, text)
        for stale in ['+2,1%', '+33,9%', '+27,3%', '52,5%', '53,9%', '61,2%', '47,5%', '06/10/2026', 'congelamento 239', 'publicação 41']:
            self.assertNotIn(stale, text)
        self.assertIn('congelamento 9001', text)
        self.assertIn('publicação 9002', text)
        self.assertIn('candidato', text.lower())

    def test_missing_or_inconsistent_source_is_rejected(self):
        b = module()
        for mutation in ['missing', 'null', 'invalid_date', 'compact_date', 'gender_mismatch', 'nan']:
            with self.subTest(mutation=mutation):
                p = changed()
                if mutation == 'missing': del p['release']['historias']['pareadas']
                if mutation == 'null': p['release']['historias']['provas']['variacao_percentual'] = None
                if mutation == 'invalid_date': p['release']['coleta'] = '2026-02-30'
                if mutation == 'compact_date': p['release']['coleta'] = '20261109'
                if mutation == 'gender_mismatch': p['release']['historias']['mulheres']['atual'] = 22.2
                if mutation == 'nan': p['release']['historias']['resultados']['variacao_percentual'] = float('nan')
                with self.assertRaises(ValueError): b.build_model(p, PROVENANCE)

    def test_invalid_provenance_cannot_label_the_source_as_reviewed(self):
        b = module()
        for provenance in [{}, {**PROVENANCE, 'public_run': 0},
                           {**PROVENANCE, 'status': 'fresh'}, {**PROVENANCE, 'publication_id': True}]:
            with self.subTest(provenance=provenance):
                with self.assertRaises(ValueError): b.build_model(changed(), provenance)

    def test_old_input_uses_the_same_source_driven_interface(self):
        m = module().build_model(fixture(), {'public_cell':420, 'public_run':239,
                                            'publication_id':41, 'publication_run':233})
        self.assertEqual([p['number'] for p in m['pitches']], ['+2,1%', '53,9%', '+27,3%', '61,2%', '47,5%'])
        self.assertEqual(m['status'], 'candidate')

    def test_candidate_html_and_central_patch_use_only_new_values(self):
        b = module()
        m = b.build_model(changed(), PROVENANCE)
        source = '<header>Preserve owner checklist 09Nov</header><textarea id="copy-release">OLD</textarea><textarea id="copy-convite">OLD</textarea><footer>OWNER CONTENT</footer>'
        text = b.central_texts(m)
        patched = b.patch_central(source, text)
        self.assertTrue(patched.startswith('<header>Preserve owner checklist 09Nov</header>'))
        self.assertTrue(patched.endswith('<footer>OWNER CONTENT</footer>'))
        self.assertIn('-4,8%', patched)
        self.assertNotIn('OLD', patched)
        with self.assertRaises(ValueError): b.patch_central('<textarea id="copy-release"></textarea>', text)
        html = b.kit_html(m, 'fixture-version')
        for pitch in m['pitches']:
            self.assertIn(pitch['slug'] + '-1080x1350.png?v=fixture-version', html)
        self.assertIn('46,8%', html)
        self.assertNotIn('53,9%', html)

    def test_changed_fixture_generates_complete_candidate_and_no_old_numbers(self):
        from pypdf import PdfReader
        from PIL import Image
        b = module()
        with tempfile.TemporaryDirectory(prefix='rr-kit-dynamic-test-') as temp:
            dest = Path(temp) / 'candidate'
            result = b.generate(changed(), PROVENANCE, dest)
            kit = dest / 'portal/brasilquecorreprovas/2026/kit'
            self.assertEqual(result['pdf_pages'], 7)
            self.assertEqual(len(list(kit.glob('*.png'))), 12)
            pdf = PdfReader(kit / 'panorama-publico-jan-set-2026.pdf')
            for index in [4, 5]:
                page_text = pdf.pages[index].extract_text()
                self.assertIn('Jan-Set 2026 | Coleta', page_text)
                self.assertNotIn('Jan-Set 2025/2026', page_text)
            text = '\n'.join(page.extract_text() for page in pdf.pages)
            text += '\n'.join(path.read_text() for path in kit.iterdir() if path.suffix in {'.txt', '.html'})
            for current in ['-4,8%', '+18,6%', '-12,7%', '44,4%', '46,8%', '62,3%', '48,6%', '09/11/2026']:
                self.assertIn(current, text)
            for stale in ['+2,1%', '+33,9%', '+27,3%', '52,5%', '53,9%', '61,2%', '47,5%', '06/10/2026', 'congelamento 239', 'publicação 41']:
                self.assertNotIn(stale, text)
            for path in kit.glob('*.png'):
                with Image.open(path) as im:
                    self.assertEqual(im.size, (1080, 1350) if '1080x1350' in path.name else (1920, 1080))
            self.assertTrue((dest / 'central-texts.json').is_file())
            self.assertTrue((dest / 'qa/manifest.json').is_file())


if __name__ == '__main__': unittest.main()
