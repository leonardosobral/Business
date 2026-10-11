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
        (9, data['contas'], 'D', 'cnpj_conta'),
        (9, data['contas'], 'E', 'cnpj_pesquisado'),
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
    for i, expected in enumerate([98,96,2,96,96,95,94,91,89,96,44,36,18,2,117], 6):
        assert float(cells[f'B{i}'].find('s:v', ns).text) == expected
    for i, expected in [(22,20),(23,13),(24,55),(27,5),(28,1),(29,36),(30,90),(31,2647),(32,2653),(33,94),(34,833),(35,13),(36,10)]:
        assert float(cells[f'B{i}'].find('s:v', ns).text) == expected
    tree=ET.fromstring(z.read('xl/worksheets/sheet10.xml'))
    ecells={c.attrib['r']:c for c in tree.findall('.//s:c',ns)}
    from datetime import date
    for i,record in enumerate(data['eventos'],6):
        assert int(ecells[f'B{i}'].find('s:v',ns).text)==record['id_evento']
        assert int(ecells[f'D{i}'].find('s:v',ns).text)==(date.fromisoformat(record['data_inicial'])-date(1899,12,30)).days
    for name in z.namelist():
        if name.startswith('xl/worksheets/') and name.endswith('.xml'):
            assert not ET.fromstring(z.read(name)).findall('.//s:c[@t="e"]', ns)

csv_files = [('abraceo_filiados.csv',96),('abraceo_pessoas_juridicas.csv',117),('abraceo_revisao_cnpjs.csv',20),('abraceo_pre_cadastro_rascunhos.csv',36),('abraceo_cruzamento_business.csv',96),('abraceo_contas_existentes.csv',6),('abraceo_fornecedores_existentes.csv',13),('abraceo_eventos_relacionados.csv',2653),('abraceo_eventos_fontes_externas.csv',10),('abraceo_logotipos_manifesto.csv',96)]
for filename, expected in csv_files:
    with (root / filename).open(encoding='utf-8-sig', newline='') as f:
        assert len(list(csv.DictReader(f,delimiter=';'))) == expected
payload = json.loads((root/'abraceo_pre_cadastro_rascunhos.json').read_text())
assert payload['contas_criadas'] is False
drafts = payload['rascunhos']
assert drafts == data['pre_cadastro']
assert len(drafts) == len({r['documento'] for r in drafts}) == len({r['id_filiado'] for r in drafts}) == 36
members = {r['id_filiado']:r for r in data['filiados']}
for draft in drafts:
    member = members[draft['id_filiado']]
    assert member['situacao_cadastral_consultada'] == 'ATIVA'
    assert member['status_pre_cadastro'] == 'APTO PARA RASCUNHO'
    assert draft['documento'] == member['cnpj_pesquisado']
    assert re.fullmatch(r'\d{14}', draft['documento'])
    assert draft['confirmacao_representante'] == 'PENDENTE'
    assert draft['deduplicacao_business'].startswith('NÃO LOCALIZADA EM 11/10/2026')
    assert not member['id_conta_business']
    assert not member['nome_responsavel_login'] and not member['email_responsavel_login']
with (root/'abraceo_pre_cadastro_rascunhos.csv').open(encoding='utf-8-sig',newline='') as f:
    assert list(csv.DictReader(f,delimiter=';')) == drafts
events=data['eventos']
assert len(events)==len({(e['id_filiado'],e['id_evento']) for e in events})==2653
assert len({e['id_evento'] for e in events})==2647
assert len({e['id_filiado'] for e in events})==90
for member in data['cruzamento']:
    mine=[e for e in events if e['id_filiado']==member['id_filiado']]
    assert member['eventos_total']==len(mine)
    assert member['eventos_ja_vinculados']==sum(e['classificacao']=='JÁ VINCULADO À CONTA' for e in mine)
for account in data['contas']:
    if account['correspondencia']=='CNPJ EXATO':
        assert account['cnpj_conta']==account['cnpj_pesquisado']
        assert account['eventos_vinculados']==sum(e['id_filiado']==account['id_filiado'] and e['classificacao']=='JÁ VINCULADO À CONTA' for e in events)
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
    assert len(z.namelist()) == 109
    assert z.testzip() is None
logo_package=root/'abraceo_logotipos.zip'
with zipfile.ZipFile(logo_package,'w',zipfile.ZIP_DEFLATED) as z:
    for f in [*logos,root/'abraceo_logotipos_manifesto.csv']:z.write(f,f.relative_to(root))
with zipfile.ZipFile(logo_package) as z:assert len(z.namelist())==97 and z.testzip() is None
print(json.dumps({'validation':'passed','members':96,'existing_exact_accounts':5,'other_cnpj_account':1,'drafts':36,'pending':55,'distinct_events':2647,'event_relations':2653,'existing_links':94,'logos':96,'package_files':109,'package_bytes':package.stat().st_size}))
