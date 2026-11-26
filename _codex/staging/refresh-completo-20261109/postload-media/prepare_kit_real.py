#!/usr/bin/env python3
"""Local run352 kit candidate. No DB, runtime write, publication or PDF-Maratonas."""
from pathlib import Path
import hashlib
import importlib.util
import json
import re

HERE=Path(__file__).resolve().parent
STAGE=HERE.parent
BUSINESS=HERE.parents[3]


def digest(data):return hashlib.sha256(data).hexdigest()


def main():
    source_path=STAGE/'postload/runs/420.json'
    frozen=json.loads(source_path.read_text())
    result=frozen['data']['result']
    if isinstance(result,str):result=json.loads(result)
    payload=result['rows'][0]['payload']
    if isinstance(payload,str):payload=json.loads(payload)
    run=frozen['data']
    assert int(run['id'])==352 and int(run['cell_id'])==420 and int(run['cell_version'])==7
    assert run['status']=='ok' and bool(run['frozen'])
    r=payload['release'];h=r['historias']
    assert [h[k]['variacao_percentual'] for k in ['pareadas','provas','resultados']]==[2.2,38.7,29.3]
    assert [h['mulheres'][k]for k in ['anterior','atual']]==[52.5,53.8]
    assert [x['valor']for x in r['indicadores']]==[53.8,46.1,61.4,48.0,43.2,48.1]
    assert r['coleta']=='2026-11-09'
    provenance={'public_cell':420,'public_run':352,'publication_id':42,'publication_run':351,'status':'reviewed'}
    (HERE/'fonte-publica.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n')
    (HERE/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n')
    central_path=BUSINESS/'estudos/lancamento/index.cfm';central=central_path.read_bytes()
    (HERE/'central-baseline.cfm').write_bytes(central)
    spec=importlib.util.spec_from_file_location('real_source_media_builder',STAGE/'media_builder/media_builder.py')
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    manifest=builder.generate(payload,provenance,HERE/'candidate',central.decode('utf-8'))
    assert central_path.read_bytes()==central,'Current central changed during local generation'
    candidate=(HERE/'candidate/business/estudos/lancamento/index.cfm').read_bytes()
    def outside_textareas(raw):
        for key in [b'copy-release',b'copy-convite']:
            pattern=rb'(<textarea\b[^>]*\bid=["\']'+key+rb'["\'][^>]*>).*?(</textarea>)'
            raw,n=re.subn(pattern,lambda m:m[1]+m[2],raw,flags=re.S)
            assert n==1,key
        return raw
    assert outside_textareas(central)==outside_textareas(candidate),'Bytes outside two textareas changed'
    from pypdf import PdfReader
    from PIL import Image
    kit=HERE/'candidate/portal/brasilquecorreprovas/2026/kit'
    files=sorted(p.name for p in kit.iterdir()if p.is_file())
    assert len(files)==17 and len(list(kit.glob('*.png')))==12
    pdf=PdfReader(kit/'panorama-publico-jan-set-2026.pdf');assert len(pdf.pages)==7
    text='\n'.join(page.extract_text()for page in pdf.pages)
    text+='\n'.join(p.read_text()for p in kit.iterdir()if p.suffix in ['.html','.txt'])
    for expected in ['+2,2%','+38,7%','+29,3%','52,5%','53,8%','61,4%','48,0%','09/11/2026','congelamento 352','publicação 42','congelamento 351','13/11/2026']:
        assert expected in text,expected
    for stale in ['+2,1%','+33,9%','+27,3%','53,9%','61,2%','47,5%','06/10/2026','congelamento 239','publicação 41','congelamento 233']:
        assert stale not in text,stale
    for path in kit.glob('*.png'):
        with Image.open(path)as im:
            assert im.size==((1080,1350)if'1080x1350'in path.name else(1920,1080))
    report={'source_cell':420,'source_revision':7,'source_run':352,'professional_publication':42,'professional_run':351,
            'status':'reviewed, not published','source_snapshot_sha256':digest(source_path.read_bytes()),
            'public_files':files,'public_file_count':len(files),'pdf_pages':7,'artworks':10,'legacy_aliases':2,
            'central_original_sha256':digest(central),'central_candidate_sha256':digest(candidate),
            'outside_textareas_sha256':digest(outside_textareas(central)),'outside_textareas_differences':0,
            'runtime_untouched':True,'database_access':False,'published':False,
            'note':'Only the two central textareas were replaced. Other central rates/card copy are intentionally untouched and need controller review separately.',
            'manifest':str((HERE/'candidate/qa/manifest.json').resolve())}
    (HERE/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
