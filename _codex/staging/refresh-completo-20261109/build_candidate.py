#!/usr/bin/env python3
"""Build reviewed notebook SQL from explicit immutable run references.

This module is deliberately offline. It never imports deployment operators,
opens sockets, executes SQL, saves notebook cells or changes publications.

Input map: {"343": {"id": 1234, "cell_version": 2,
                   "started_at": "2026-11-09T12:00:00-03:00",
                   "result_json": "{\"columns\":[...],\"rows\":[...]}"}, ...}.
Result rows are needed only by build_pairs; SQL composition uses run metadata.
"""
from __future__ import annotations
import os
import sys
# The collection stage deliberately has an inspect.py operator. Prime the
# standard-library module before argparse/dataclasses can resolve that sibling.
_saved_search_path=list(sys.path)
try:
    _stage_directory=os.path.dirname(os.path.realpath(__file__))
    sys.path[:]=[entry for entry in sys.path if os.path.realpath(entry or os.curdir)!=_stage_directory]
    import inspect as _stdlib_inspect
finally:
    sys.path[:]=_saved_search_path
import argparse
import copy
from decimal import Decimal
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

HERE=Path(__file__).resolve().parent
BUSINESS=HERE.parents[2]
RR=BUSINESS.parent/'RoadRunners'
sys.path.insert(0,str(HERE))
from build_support.full_projection import build_projection,provenance,source_label

SOURCE_CELLS={
 'geracoes-2023-anual':346,'geracoes-2024-anual':348,'geracoes-2025-anual':349,
 'geracoes-2026-q3':357,'alfa-z-variacoes':380,
 'geral-2026-q3':343,'geral-2025-q3':347,'mensais-provas-q3':350,
 'performance-cna-q3':351,'maratonas-q3':353,'cobertura-q3':355,
 'corte14-2025':356,'corte14-2026-q3':358,'cidades-q3':359,
 'capital-interior-q3':378,'perfil-q3':361,'activites-q3-agregadas':377,
 'mapeamento-q3':363,'cadastro-maratonas-q3':364,
 'precos-resumo-q3':366,'precos-geral-q3':367,'porte-q3':368,
 'edicoes-calendario-2026':384,
}
HISTORICAL_CELLS={346,348,349}
ACTIVITY_CELLS=(365,369,370,371,372,373,374,375,376)
PRESERVED_EVIDENCE=('variacoes_a_z','maratonas_revisao_eventos','maratonas_revisao_situacoes')
DEFAULT_BASELINE_RUN={'id':233,'cell_id':251,'cell_version':39}


def sql_literal(value):
    return "'"+str(value).replace("'","''")+"'"


def dumps(value,**kwargs):
    return json.dumps(value,ensure_ascii=False,default=lambda v:str(v) if isinstance(v,Decimal) else (_ for _ in ()).throw(TypeError(type(v).__name__)),**kwargs)


def load_json(path):
    return json.loads(Path(path).read_text(),parse_float=Decimal)


def normalize_runs(document):
    """Accept cell-keyed maps, lists, RUN receipts, and wrapper {'runs':...}."""
    if isinstance(document,dict) and 'runs' in document:
        document=document['runs']
    if isinstance(document,list):
        entries=[(None,value) for value in document]
    elif isinstance(document,dict):
        entries=document.items()
    else:
        raise ValueError('runs must be a cell-keyed object or a run list')
    result={}
    for key,value in entries:
        if not isinstance(value,dict):
            raise ValueError(f'run {key}: expected object')
        run={str(k).lower():v for k,v in value.get('RUN',value.get('run',value)).items()}
        # Native collector receipts keep metadata in run and aggregate rows in data.
        if isinstance(value.get('data'),dict):
            data={str(k).lower():v for k,v in value['data'].items()}
            if 'result' in data:run['result']=data['result']
            if 'result_json' in data:run['result_json']=data['result_json']
        cell=int(run.get('cell_id',run.get('cellid',key)))
        revision=run.get('cell_version',run.get('cellversion',run.get('version')))
        if revision is None:raise ValueError(f'cell {cell}: cell_version is required')
        run.update(id=int(run['id']),cell_id=cell,cell_version=int(revision))
        if run['id']<=0 or run['cell_version']<=0:raise ValueError('positive run id and revision required')
        for field,bad in [('status',lambda v:v!='ok'),('frozen',lambda v:v not in (True,1)),('truncated',lambda v:v not in (False,0))]:
            if field in run and bad(run[field]):raise ValueError(f'cell {cell}: source {field}={run[field]!r}')
        if 'result_json' in run and 'result' not in run:
            run['result']=json.loads(run['result_json']) if isinstance(run['result_json'],str) else run['result_json']
        elif isinstance(run.get('result'),str):run['result']=json.loads(run['result'])
        if 'rows' in run and 'result' not in run:run['result']={'rows':run['rows']}
        if cell in result:raise ValueError(f'duplicate cell {cell}')
        result[cell]=run
    return result


def load_runs(path):
    path=Path(path)
    if path.is_dir():
        return normalize_runs([load_json(p) for p in sorted(path.glob('*.json'))])
    return normalize_runs(load_json(path))


def snapshot_cells(snapshot=None):
    snapshot=load_json(HERE/'notebook-before.json') if snapshot is None else snapshot
    return {int(c['id']):c for c in snapshot['cells']}


def conserved_run(cell,snapshot=None):
    c=snapshot_cells(snapshot)[cell];r=c.get('last_frozen')
    if not r:raise ValueError(f'cell {cell}: no conserved frozen source')
    return dict(r,cell_id=cell,cell_version=int(r['cell_version']))


def require_run(runs,cell):
    try:return runs[cell]
    except KeyError as exc:raise ValueError(f'missing frozen source for cell {cell}') from exc


def payload_from(document):
    if isinstance(document,dict) and 'series' in document and 'comparacoes' in document:return document
    if isinstance(document,dict) and 'RUN' in document:return payload_from(document['RUN'])
    if isinstance(document,dict) and 'result_json' in document:
        return payload_from(json.loads(document['result_json']) if isinstance(document['result_json'],str) else document['result_json'])
    if isinstance(document,dict) and 'result' in document:return payload_from(document['result'])
    if isinstance(document,dict) and 'rows' in document:return document['rows'][0]['payload']
    if isinstance(document,dict) and 'payload' in document:return payload_from(document['payload'])
    raise ValueError('baseline must be payload or native notebook result')


def build_themes(runs,baseline,baseline_run=None,snapshot=None):
    """Return SQL for cell414. All analytical series use explicit frozen sources.

    Three pre-2026 age inputs, unused by the 2026 projection, may retain their
    frozen references. All active theme inputs are mandatory and never fall back.
    The baseline's historical evidence is carried with its original dates.
    """
    runs=normalize_runs(runs);baseline=payload_from(baseline)
    if int(baseline['meta']['ano'])!=2026 or int(baseline['meta']['contrato_versao'])!=17:
        raise ValueError('expected current 2026/contract17 baseline')
    source_runs={}
    for name,cell in SOURCE_CELLS.items():
        r=runs.get(cell)
        if r is None and cell in HISTORICAL_CELLS:r=conserved_run(cell,snapshot)
        if r is None:raise ValueError(f'missing {name}: cell {cell}')
        if not r.get('started_at'):raise ValueError(f'cell {cell}: started_at required for truthful provenance')
        source_runs[name]=r
    sql,details=build_projection(source_runs,baseline,baseline_run or DEFAULT_BASELINE_RUN)
    # Stable metadata and series order come from the supplied baseline. The
    # projection may regenerate dynamic category labels rather than retaining
    # obsolete cities, distances or marathon names.
    assert_no_operational_sources(sql)
    return '-- Candidato completo; corte 30/09/2026. Não publica nem libera temas em revisão.\n'+sql


def _tokens(sql):
    """Return SQL comments/literals/code separately; never rewrite numeric data."""
    token=re.compile(r"(--[^\n]*(?:\n|$)|/\*[\s\S]*?\*/|'(?:''|[^'])*'|\"(?:\"\"|[^\"])*\")")
    pos=0
    for m in token.finditer(sql):
        if pos<m.start():yield 'code',sql[pos:m.start()]
        text=m.group(0)
        yield ('literal' if text.startswith("'") else 'other'),text
        pos=m.end()
    if pos<len(sql):yield 'code',sql[pos:]


def _rewrite_json_refs(value,runs,run_ids):
    if isinstance(value,list):return [_rewrite_json_refs(v,runs,run_ids) for v in value]
    if not isinstance(value,dict):return value
    value={k:_rewrite_json_refs(v,runs,run_ids) for k,v in value.items()}
    cell=value.get('celula')
    if cell is not None and str(cell).isdigit() and int(cell) in runs:
        r=runs[int(cell)]
        for field,new in [('revisao',r['cell_version']),('execucao',r['id'])]:
            if field in value:value[field]=new
        if 'coletado_em' in value and r.get('started_at'):value['coletado_em']=r['started_at']
    if value.get('base_inicial_celula')==251 and 251 in runs:
        value['base_inicial_run']=runs[251]['id']
    # Floripa's capture date and official count remain immutable. Only the
    # incorporation date describes when a new assembled package was produced.
    if value.get('celula')==402 and 'incorporado_em' in value and 414 in runs:
        value['incorporado_em']=str(runs[414].get('started_at',value['incorporado_em']))[:10]
    return value


def remap_frozen_references(sql,runs,snapshot=None,extra_old_runs=None):
    """Remap run predicates/IN lists and semantic provenance, never all numbers.

    SQL string literals, prices, counts, thresholds, dates and event IDs are
    protected. JSON provenance objects are rewritten by their explicit cell id.
    Expected SQL patterns are checked by callers before emitting a candidate.
    """
    runs=normalize_runs(runs);cells=snapshot_cells(snapshot)
    old_to_new={int(c['last_frozen']['id']):runs[cell]['id'] for cell,c in cells.items() if cell in runs and c.get('last_frozen')}
    for old,new in (extra_old_runs or {}).items():old_to_new[int(old)]=int(new)
    id_re=re.compile(r'(\b(?:\w+\.)?id\s*=\s*)(\d+)\b',re.I)
    in_re=re.compile(r'(\b(?:\w+\.)?id\s+IN\s*\()(\s*\d+(?:\s*,\s*\d+)*\s*)(\))',re.I)
    # Cell380's VALUES stores immutable notebook run ids in its first column.
    value_re=re.compile(r'(\()(\d+)(\s*,\s*$)')
    version_re=re.compile(r'(\b(?:(\w+)\.)?id\s*=\s*)(\d+)(\s+AND\s+(?:\w+\.)?cell_id\s*=\s*)(\d+)(?:\s+AND\s+(?:\w+\.)?cell_version\s*=\s*\d+)?',re.I)
    by_id={r['id']:r for r in runs.values()}
    output=[]
    for kind,text in _tokens(sql):
        if kind=='code':
            text=id_re.sub(lambda m:m[1]+str(old_to_new.get(int(m[2]),int(m[2]))),text)
            text=in_re.sub(lambda m:m[1]+','.join(str(old_to_new.get(int(v),int(v))) for v in re.findall(r'\d+',m[2]))+m[3],text)
            # Restrict VALUES rewriting to the known first-column source pairs.
            if 'WITH fontes AS' in sql:
                text=value_re.sub(lambda m:m[1]+str(old_to_new.get(int(m[2]),int(m[2])))+m[3],text)
            def revision(m):
                r=by_id.get(int(m[3]));cell=int(m[5])
                if not r or r['cell_id']!=cell:return m.group(0)
                qualifier=(m[2]+'.') if m[2] else ''
                return m[1]+m[3]+m[4]+m[5]+' AND '+qualifier+'cell_version='+str(r['cell_version'])
            text=version_re.sub(revision,text)
        elif kind=='literal':
            value=text[1:-1].replace("''", "'")
            try:
                j=json.loads(value)
            except (ValueError,TypeError):j=None
            if isinstance(j,(dict,list)):
                value=dumps(_rewrite_json_refs(j,runs,old_to_new))
            else:
                def label(m):
                    cell=int(m[1]);r=runs.get(cell)
                    return source_label(r) if r and r.get('started_at') else m.group(0)
                value=re.sub(r'Notebook · célula (\d+) rev\d+ · congelamento \d+ · coleta \d{2}/\d{2}/\d{4}',label,value)
                # Older overlays omit a collection label before the platform name.
                value=re.sub(r'célula (\d+) rev\d+ · congelamento \d+',lambda m:'célula '+m[1]+' rev'+str(runs[int(m[1])]['cell_version'])+' · congelamento '+str(runs[int(m[1])]['id']) if int(m[1]) in runs else m.group(0),value)
                value=re.sub(r'congelamento (\d+)\b',lambda m:'congelamento '+str(old_to_new.get(int(m[1]),int(m[1]))),value)
            text=sql_literal(value)
        output.append(text)
    return ''.join(output)


def build_derived(cell,runs,snapshot=None):
    """Return cell380 age deltas or cell377 nine-month activity sum SQL."""
    cell=int(cell);runs=normalize_runs(runs)
    if cell not in (380,377):raise ValueError('supported derived cells: 380,377')
    required=(346,348,352,349,354,357) if cell==380 else ACTIVITY_CELLS
    actual=dict(runs)
    for source in required:
        if source not in actual and source in HISTORICAL_CELLS:actual[source]=conserved_run(source,snapshot)
        require_run(actual,source)
    sql=remap_frozen_references(snapshot_cells(snapshot)[cell]['content'],actual,snapshot)
    assert_no_operational_sources(sql)
    return sql


def build_pairs(runs,matcher_path=None):
    """Return (literal SQL387, full audit JSON) using current matcher semantics."""
    runs=normalize_runs(runs);sources=[require_run(runs,c) for c in (383,384)]
    payloads=[]
    for r in sources:
        rows=(r.get('result') or {}).get('rows')
        if not rows or len(rows)!=1 or 'payload' not in rows[0]:raise ValueError(f"cell {r['cell_id']}: one payload row required")
        payloads.append(rows[0]['payload'])
    matcher_path=Path(matcher_path or RR/'_codex/scripts/brasil_que_corre_edicoes.py')
    spec=importlib.util.spec_from_file_location('frozen_editions_matcher',matcher_path)
    engine=importlib.util.module_from_spec(spec);spec.loader.exec_module(engine)
    combined=copy.deepcopy(payloads[0]);combined['eventos']+=copy.deepcopy(payloads[1]['eventos']);combined['totais']+=copy.deepcopy(payloads[1]['totais'])
    combined['coletado_em']=max(str(p['coletado_em']) for p in payloads)
    result=engine.analyze({'http_status':'200','data':combined})
    result['periodo']='Jan–Set de2025 e2026'
    result['metodologia']='Calendário anual, unicidade por ano/cidade/UF/tipo; vínculo não circuito prioritário; depois nome normalizado, até90dias sazonais, ordinais consecutivos. Contagens de01/01 a30/09. 2026: BI conservada em estudo;2025: base operacional. Crescimento observado mistura captura, composição e evolução real; não identifica causa.'
    def exact(value):
        if isinstance(value,dict):
            for v in value.values():exact(v)
            if 'variacao_pct' in value:
                a=value.get('concluintes_2025',value.get('2025'));b=value.get('concluintes_2026',value.get('2026'))
                if a:value['variacao_pct']=str((Decimal(b)/Decimal(a)-1)*100)
        elif isinstance(value,list):
            for v in value:exact(v)
    exact(result)
    result['fontes']=[provenance(r) for r in sources]
    result['matcher_sha256']=hashlib.sha256(matcher_path.read_bytes()).hexdigest()
    omitted={'pares','pares_sem_resultados_nos_dois_anos','pares_fora_da_janela','chaves_ambiguas','pares_requerem_revisao','nao_pareados_com_resultados'}
    summary={k:v for k,v in result.items() if k not in omitted}
    fields=('id_2025','id_2026','metodo','concluintes_2025','concluintes_2026','percursos_comuns_2025','percursos_comuns_2026')
    summary['pares']=[{k:p[k] for k in fields} for p in result['pares']]
    sql='-- Transformação reproduzível; matcher SHA256='+result['matcher_sha256']+'; fontes='+dumps(result['fontes'])+'\nSELECT '+sql_literal(dumps(summary))+'::jsonb AS payload'
    return sql,result


def build_final(runs,snapshot=None):
    """Return SQL251: cell414 plus official Floripa only in marathon performance."""
    runs=normalize_runs(runs)
    require_run(runs,414);require_run(runs,353)
    rows=(runs[353].get('result') or {}).get('rows')
    if rows:
        top=rows[0]['payload'].get('top10') or []
        if sum(str(v.get('id_evento'))=='34529' for v in top)!=1:
            raise ValueError('Floripa34529 absent/duplicated in new353 top10; reconcile selection before the official overlay')
    if 402 not in runs:runs[402]=conserved_run(402,snapshot)
    # Official capture is independent of the current operational import.
    if runs[402]['id']!=210:raise ValueError('official Floripa run210 must be retained until separately reconciled')
    sql=snapshot_cells(snapshot)[251]['content'].strip().rstrip(';')
    # Old251 restored ALL category labels from214. New414 already preserves the
    # baseline order while updating dynamic categories; keep that result here.
    start=sql.index("'series',(SELECT jsonb_agg((b.value-'ressalva')")
    end=sql.index(",'comparacoes',updated.rows",start)
    sql=sql[:start]+"'series',newseries.rows"+sql[end:]
    sql=remap_frozen_references(sql,runs,snapshot)
    # Deduplicate provenance by cell, retaining the last (newest explicit) entry.
    sql="WITH assembled AS (\n"+sql+"\n) SELECT payload || jsonb_build_object('meta',payload->'meta'||jsonb_build_object('notebook_fontes',(SELECT jsonb_agg(v ORDER BY cell_id) FROM (SELECT DISTINCT ON ((value->>'celula')::bigint) (value->>'celula')::bigint AS cell_id,value AS v FROM jsonb_array_elements(payload->'meta'->'notebook_fontes') WITH ORDINALITY ORDER BY cell_id,ordinality DESC) refs))) AS payload FROM assembled"
    assert_no_operational_sources(sql)
    return '-- Fonte oficial Floripa210 preservada; sem sobreposição em totais nacionais/coorte.\n'+sql


def build_public(runs,snapshot=None):
    runs=normalize_runs(runs)
    for cell in (251,347,354,421,383,368,387):require_run(runs,cell)
    sql=remap_frozen_references(snapshot_cells(snapshot)[420]['content'],runs,snapshot)
    sql=sql.replace('Coletas: 2025 em 13/10; 2026 em 06/10.','Coletas próprias por tema; referência2025 '+str(runs[421]['started_at'])[:10]+'; referência2026 '+str(require_run(runs,378)['started_at'])[:10]+'.')
    assert_no_operational_sources(sql)
    return '-- Candidato de narrativa Jan–Set; congelar não altera a view nem a publicação liberada.\n'+sql


def build_annual(runs,snapshot=None):
    runs=normalize_runs(runs);require_run(runs,251)
    sql=remap_frozen_references(snapshot_cells(snapshot)[418]['content'],runs,snapshot)
    assert_no_operational_sources(sql)
    return sql


def assert_no_operational_sources(sql):
    without_literals=''.join(t if k=='code' else ' ' for k,t in _tokens(sql))
    tables=re.findall(r'\b(?:FROM|JOIN)\s+((?:public|estudo)\.\w+)',without_literals,re.I)
    disallowed=sorted({t for t in tables if t.lower()!='estudo.notebook_runs'})
    if disallowed:raise ValueError('projection must read only frozen runs: '+','.join(disallowed))


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runs',type=Path,required=True)
    parser.add_argument('--baseline',type=Path)
    parser.add_argument('--baseline-run',type=int,default=233)
    parser.add_argument('--baseline-version',type=int,default=39)
    parser.add_argument('--snapshot',type=Path,default=HERE/'notebook-before.json')
    parser.add_argument('--output-dir',type=Path,required=True)
    parser.add_argument('--steps',nargs='+',choices=['380','377','387','414','251','420','418'],default=['414'])
    args=parser.parse_args(argv)
    runs=load_runs(args.runs);snapshot=load_json(args.snapshot)
    args.output_dir.mkdir(parents=True,exist_ok=True)
    outputs={}
    for step in args.steps:
        if step in ('380','377'):sql=build_derived(int(step),runs,snapshot)
        elif step=='387':
            sql,pairs=build_pairs(runs);(args.output_dir/'pairs-full.json').write_text(dumps(pairs,indent=2))
        elif step=='414':
            if args.baseline is None:parser.error('--baseline required for414')
            sql=build_themes(runs,load_json(args.baseline),{'id':args.baseline_run,'cell_id':251,'cell_version':args.baseline_version},snapshot)
        elif step=='251':sql=build_final(runs,snapshot)
        elif step=='420':sql=build_public(runs,snapshot)
        else:sql=build_annual(runs,snapshot)
        target=args.output_dir/f'cell-{step}.sql';target.write_text(sql+'\n')
        outputs[step]={'path':str(target),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
    manifest={'offline_only':True,'contract_version':17,'cutoff':'2026-09-30','outputs':outputs,'sources':{str(c):{k:r[k] for k in ('id','cell_version','started_at') if k in r} for c,r in runs.items()},'preserved_evidence':list(PRESERVED_EVIDENCE),'annual_review_topics':['precos','cna','ritmo42','cadastro_maratonas'],'publication_changed':False,'bi_reload':'not_verified_by_generator','validation_scope':'offline SQL composition; no database execution or numerical SQL validation'}
    (args.output_dir/'build-manifest.json').write_text(dumps(manifest,indent=2))
    print(dumps({'outputs':outputs,'publication_changed':False},indent=2))

if __name__=='__main__':main()
