"""Normalize saved Semrush UI CSV exports; no provider calls or live corrections."""
import argparse
import csv
import hashlib
import json
import math
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlsplit

SITES = {
    'roadrunners': dict(domain='roadrunners.run', label='Road Runners', projectId=26661911,
                       auditDate='2026-11-04', siteHealth=72, aiHealth=76, device='Móvel'),
    'openresults': dict(domain='openresults.run', label='Open Results', projectId=31744040,
                       auditDate='2026-11-03', siteHealth=76, aiHealth=79, device='Computador'),
}
TRANSLATIONS = {
    1:'Erros HTTP 5xx', 2:'Erros HTTP 4xx', 3:'Título ausente', 4:'Bloqueadas para rastreamento',
    6:'Títulos duplicados', 7:'Conteúdo duplicado', 8:'Links internos quebrados', 9:'Páginas não rastreadas',
    12:'Links externos quebrados', 13:'Imagens internas quebradas', 14:'Imagens externas quebradas',
    15:'Descrições duplicadas', 24:'Conflitos de hreflang', 101:'Título curto', 102:'Título longo',
    103:'H1 ausente', 104:'Múltiplos H1', 109:'Redirecionamentos temporários', 110:'Imagens sem ALT',
    111:'Carregamento lento', 112:'Baixa proporção texto/HTML', 113:'Parâmetros em excesso',
    117:'Poucas palavras', 123:'Nofollow em links internos', 133:'JS e CSS em excesso',
    135:'JS e CSS sem minificação', 204:'Idioma incompatível com hreflang', 205:'Sem HSTS',
    212:'Mais de três cliques de profundidade', 213:'Apenas um link interno de entrada',
    214:'Redirecionamentos permanentes', 216:'Links sem texto âncora',
    217:'Texto âncora não descritivo', 218:'Recursos externos com HTTP 403',
    222:'Baixo uso de HTML semântico', 223:'Conteúdo não otimizado',
}
DETAIL_IDS = {
    'duplicate_meta_description':15, 'duplicate_title_tag':6, 'duplicate_content':7,
    'slow_loading_speed':111, 'http_4xx_client_errors':2, 'broken_internal_links':8,
    'we_couldn`t_crawl_the_page':9, 'unminified_javascript_and_css_files':135,
}


def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        reader=csv.DictReader(f)
        assert reader.fieldnames and len(set(reader.fieldnames))==len(reader.fieldnames), path.name
        rows=list(reader)
        assert all(None not in r and all(v is not None for v in r.values()) for r in rows), path.name
        return reader.fieldnames, rows


def integer(value):
    assert str(value).isdigit(), repr(value)
    return int(value)


def safe_url(url):
    try:
        parsed=urlsplit(url)
        return bool(parsed.scheme in ('http','https') and parsed.hostname and not parsed.username and not parsed.password
                    and not any(ord(c)<33 or c=='\\' for c in url))
    except ValueError:
        return False


def write_json(path, value):
    path.write_text(json.dumps(value,ensure_ascii=False,separators=(',',':')))
    path.chmod(0o600)


def build(raw, output):
    output.mkdir(parents=True,exist_ok=True,mode=0o700)
    manifest=dict(schemaVersion=1, collectedAt=datetime.now(timezone.utc).isoformat(),
                  source='Semrush · exportações CSV da interface autenticada', sites={}, files={})
    for key, meta in SITES.items():
        domain=meta['domain']; prefix=domain+'_'; suffix='_20261104.csv'
        summary_path=raw/(prefix+'issues'+suffix)
        _, summary=read_csv(summary_path)
        assert len(summary)==101 and set(summary[0])=={'Issue Id','Issue Type','Issue','Failed checks','Total checks','Changed from last audit'}
        issues=[]; by_name={}
        for r in summary:
            iid=integer(r['Issue Id']); assert r['Issue Type'] in ('ERROR','WARNING','NOTICE')
            issue=dict(id=iid,name=r['Issue'],label=TRANSLATIONS.get(iid,r['Issue']),
                       severity=r['Issue Type'].lower(),count=integer(r['Failed checks']),checks=integer(r['Total checks']),
                       providerDelta=int(r['Changed from last audit']))
            assert iid not in {i['id'] for i in issues}
            issues.append(issue);by_name[r['Issue']]=issue
        fields, mega=read_csv(raw/(prefix+'mega_export'+suffix))
        assert fields[0]=='Page URL' and set(fields[1:])==set(by_name), 'Unknown issue columns'
        assert len(mega)==20000 and len({r['Page URL'] for r in mega})==20000, 'Incomplete or duplicate crawl inventory'
        page_path=raw/(prefix+'pages'+suffix)
        metadata={}; metadata_fields=[]
        if page_path.exists():
            metadata_fields, page_rows=read_csv(page_path)
            metadata={r['Page URL']:{k:v for k,v in r.items() if k!='Page URL'} for r in page_rows}
            assert len(page_rows)==20000 and len(metadata)==20000
            assert set(metadata)=={r['Page URL'] for r in mega}, 'Page inventories differ'
        page_rows=[]; affected=Counter(); severity_counts=Counter()
        for r in mega:
            url=r['Page URL']; findings={}; errors=0; warnings=0; notices=0
            for name in fields[1:]:
                n=integer(r[name])
                if n:
                    issue=by_name[name];iid=issue['id'];findings[str(iid)]=n;affected[iid]+=1
                    if issue['severity']=='error':errors+=n
                    elif issue['severity']=='warning':warnings+=n
                    else:notices+=n
            page_rows.append(dict(url=url,linkAllowed=safe_url(url),findings=findings,errors=errors,warnings=warnings,notices=notices,metadata=metadata.get(url,{})))
            for severity,n in [('error',errors),('warning',warnings),('notice',notices)]:
                if n:severity_counts[severity]+=1
        page_rows.sort(key=lambda r:(-bool(r['errors']),-r['errors'],-r['warnings'],r['url']))
        for i in issues:i['affectedPages']=affected[i['id']]
        files=[];organic=None
        for path in sorted(raw.glob(domain+'*.csv')):
            if path.name.startswith(prefix) and path.name.endswith(suffix):kind=path.name[len(prefix):-len(suffix)]
            elif path.name.startswith(domain+'-organic.Positions-br-20261103-'):kind='organic_positions'
            else:raise ValueError('Unexpected source file: '+path.name)
            columns, rows=read_csv(path)
            fid=key+'-'+kind.replace('`','').replace(' ','_')
            assert fid not in manifest['files']
            entry=dict(id=fid,site=key,name=path.name,kind=kind,rows=len(rows),columns=columns,
                       bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
            if kind in DETAIL_IDS:entry['issueId']=DETAIL_IDS[kind]
            manifest['files'][fid]=entry;files.append(fid)
            if kind=='organic_positions':
                assert organic is None and set(['Keyword','Position','Previous position','Search Volume','URL','Timestamp'])<=set(columns)
                for r in rows:
                    for name in ['Position','Previous position','Search Volume','Keyword Difficulty','Traffic']:
                        if r[name]=='':continue
                        number=float(r[name]);assert math.isfinite(number) and number>=0
                    r['linkAllowed']=safe_url(r['URL'])
                rows.sort(key=lambda r:(r['Search Volume']=='',-float(r['Search Volume']) if r['Search Volume'] else 0,float(r['Position']) if r['Position'] else 101,r['Keyword'].casefold(),r['URL']))
                organic=dict(rows=len(rows),uniqueKeywords=len({r['Keyword'].casefold() for r in rows}),fileId=fid,
                             database='br',device='desktop',snapshotDate='2026-11-03')
                write_json(output/(key+'-keywords.json'),dict(schemaVersion=1,site=key,rows=rows))
        order={'error':0,'warning':1,'notice':2}
        issues.sort(key=lambda i:(order[i['severity']],-i['count'],i['id']))
        totals={s:sum(i['count'] for i in issues if i['severity']==s) for s in order}
        site=dict(meta,pages=20000,limit=20000,javascriptRendered=False,precision='day',issues=issues,
                  totals=totals,affectedPages=dict(severity_counts),metadataAvailable=bool(metadata),
                  metadataColumns=metadata_fields,files=files,sourceUrl=f'https://pt.semrush.com/siteaudit/campaign/{meta["projectId"]}/review/overview',
                  pagesFile=key+'-pages.json')
        site['organic']=organic
        site['detailLimitations']=[{'issueId':204,'reason':'A interface deste relatório não ofereceu exportação CSV; as URLs e os indicadores constam no inventário geral.'}] if key=='roadrunners' else []
        write_json(output/site['pagesFile'],dict(schemaVersion=1,site=key,rows=page_rows))
        manifest['sites'][key]=site
    write_json(output/'manifest.json',manifest)
    return {k:dict(pages=v['pages'],siteHealth=v['siteHealth'],totals=v['totals'],files=len(v['files']),metadata=v['metadataAvailable']) for k,v in manifest['sites'].items()}


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--raw',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    args=p.parse_args();print(json.dumps(build(args.raw,args.output),ensure_ascii=False,indent=2))
