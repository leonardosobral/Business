import csv
import json
import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET
from PIL import Image

root = Path(__file__).resolve().parent.parent
data = json.loads((root / 'research/prepared.json').read_text())
ns = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
with zipfile.ZipFile(root / 'abraceo_pre_cadastro.xlsx') as z:
    assert z.testzip() is None
    for number, rows, column, key in [
        (2, data['filiados'], 'D', 'cnpj_pesquisado'),
        (3, data['juridicas'], 'C', 'cnpj'),
        (6, data['revisoes'], 'C', 'cnpj_anterior'),
        (6, data['revisoes'], 'D', 'cnpj_revisado'),
        (7, data['pre_cadastro'], 'C', 'documento'),
    ]:
        tree = ET.fromstring(z.read(f'xl/worksheets/sheet{number}.xml'))
        cells = {c.attrib['r']: c for c in tree.findall('.//s:c', ns)}
        for i, record in enumerate(rows, 6):
            expected = record.get(key)
            if not expected:
                continue
            cell = cells[f'{column}{i}']
            assert cell.attrib['t'] == 'str'
            actual = cell.find('s:v', ns).text
            assert not actual.startswith("'")
            assert re.sub(r'\D', '', actual) == expected
    tree = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    cells = {c.attrib['r']: c for c in tree.findall('.//s:c', ns)}
    for i, expected in enumerate([98,96,2,96,96,95,94,91,89,96,44,40,18,2,117], 6):
        assert float(cells[f'B{i}'].find('s:v', ns).text) == expected
    for i, expected in [(22,20),(23,13),(24,56)]:
        assert float(cells[f'B{i}'].find('s:v', ns).text) == expected
    for name in z.namelist():
        if name.startswith('xl/worksheets/') and name.endswith('.xml'):
            assert not ET.fromstring(z.read(name)).findall('.//s:c[@t="e"]', ns)

csv_files = [('abraceo_filiados.csv',96),('abraceo_pessoas_juridicas.csv',117),('abraceo_revisao_cnpjs.csv',20),('abraceo_pre_cadastro_rascunhos.csv',40)]
for filename, expected in csv_files:
    with (root / filename).open(encoding='utf-8-sig', newline='') as f:
        assert len(list(csv.DictReader(f,delimiter=';'))) == expected
payload = json.loads((root/'abraceo_pre_cadastro_rascunhos.json').read_text())
assert payload['contas_criadas'] is False
drafts = payload['rascunhos']
assert drafts == data['pre_cadastro']
assert len(drafts) == len({r['documento'] for r in drafts}) == len({r['id_filiado'] for r in drafts}) == 40
members = {r['id_filiado']:r for r in data['filiados']}
for draft in drafts:
    member = members[draft['id_filiado']]
    assert member['situacao_cadastral_consultada'] == 'ATIVA'
    assert member['status_pre_cadastro'] == 'APTO PARA RASCUNHO'
    assert draft['documento'] == member['cnpj_pesquisado']
    assert re.fullmatch(r'\d{14}', draft['documento'])
    assert draft['confirmacao_representante'] == draft['deduplicacao_business'] == 'PENDENTE'
    assert not member['nome_responsavel_login'] and not member['email_responsavel_login']
with (root/'abraceo_pre_cadastro_rascunhos.csv').open(encoding='utf-8-sig',newline='') as f:
    assert list(csv.DictReader(f,delimiter=';')) == drafts
logos = sorted((root / 'logotipos').iterdir())
assert len(logos) == 96
for logo in logos:
    with Image.open(logo) as im:
        im.verify()
files = [root/'abraceo_pre_cadastro.xlsx',*[root/name for name,_ in csv_files],root/'abraceo_pre_cadastro_rascunhos.json',root/'LEIA-ME.txt',*logos]
package = root / 'abraceo_pre_cadastro_completo.zip'
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
    for file in files:
        z.write(file,file.relative_to(root))
with zipfile.ZipFile(package) as z:
    assert len(z.namelist()) == 103
    assert z.testzip() is None
print(json.dumps({'validation':'passed','members':96,'legal_records':117,'priority_reviews':20,'drafts':40,'pending':56,'logos':96,'package_files':103,'package_bytes':package.stat().st_size}))
