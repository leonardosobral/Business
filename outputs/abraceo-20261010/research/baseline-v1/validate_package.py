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
    for i, expected in enumerate([98,96,2,94,94,95,94,91,82,96,33,27,16,4,112], 6):
        assert float(cells[f'B{i}'].find('s:v', ns).text) == expected
    for name in z.namelist():
        if name.startswith('xl/worksheets/') and name.endswith('.xml'):
            assert not ET.fromstring(z.read(name)).findall('.//s:c[@t="e"]', ns)

for filename, expected in [('abraceo_filiados.csv',96),('abraceo_pessoas_juridicas.csv',112)]:
    with (root / filename).open(encoding='utf-8-sig', newline='') as f:
        assert len(list(csv.DictReader(f,delimiter=';'))) == expected
logos = sorted((root / 'logotipos').iterdir())
assert len(logos) == 96
for logo in logos:
    with Image.open(logo) as im:
        im.verify()
files = [root/'abraceo_pre_cadastro.xlsx',root/'abraceo_filiados.csv',root/'abraceo_pessoas_juridicas.csv',*logos]
package = root / 'abraceo_pre_cadastro_completo.zip'
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
    for file in files:
        z.write(file,file.relative_to(root))
with zipfile.ZipFile(package) as z:
    assert len(z.namelist()) == 99
    assert z.testzip() is None
print(json.dumps({'validation':'passed','members':96,'legal_entities':112,'logos':96,'package_files':99,'package_bytes':package.stat().st_size}))
