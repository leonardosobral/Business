"""Offline provenance wrapper for Q3 cells414/251; never executes or saves SQL.

annotate_final(sql, runs, source_audit) accepts native collector receipts and:
  source_audit={'audit': metadata['audit'], 'verification': verification_json}.
The 18 postload controls must pass. Required runs353/413 must be complete frozen
sources captured after the load. The caller owns collection/publication guards.
"""
from __future__ import annotations
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import sys

_STAGE=Path(__file__).resolve().parent.parent
if str(_STAGE) not in sys.path:sys.path.insert(0,str(_STAGE))
from build_candidate import _tokens,assert_no_operational_sources,normalize_runs,sql_literal

_FACT='estudo.fat_perfil_br_2026_20261109'

def _json(value):
    return json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(',',':'))

def _time(value):
    stamp=datetime.fromisoformat(str(value))
    if stamp.tzinfo is None:raise ValueError('provenance timestamps require a timezone')
    return stamp

def _provenance(run):
    return dict(celula=run['cell_id'],revisao=run['cell_version'],execucao=run['id'],coletado_em=run['started_at'])

def _annotation(runs,source_audit):
    runs=normalize_runs(runs)
    audit=source_audit.get('audit')
    verification=source_audit.get('verification',{})
    checks=verification.get('checks',{})
    if not isinstance(audit,dict) or audit.get('status')!='activated':raise ValueError('activated load audit required')
    if verification.get('status')!='verified_active' or len(checks)!=18 or not all(v is True for v in checks.values()):
        raise ValueError('all 18 postload validations must pass')
    for key in ('loaded_at','snapshot_id','source_script_sha256','quality','activated_views'):
        if key not in audit:raise ValueError('load audit missing '+key)
    if not re.fullmatch('[0-9a-f]{64}',audit['source_script_sha256']):raise ValueError('invalid source script hash')
    if verification.get('snapshot_id')!=audit['snapshot_id'] or _time(verification.get('loaded_at',''))!=_time(audit['loaded_at']):
        raise ValueError('verification does not belong to this loaded snapshot')
    if verification.get('fact_rows')!=audit['quality'].get('fact') or audit['quality'].get('eligible')!=audit['quality'].get('fact'):
        raise ValueError('verified source counts do not match the load receipt')
    for cell in (353,413):
        if cell not in runs:raise ValueError('missing current frozen source '+str(cell))
        if _time(runs[cell].get('started_at',''))<_time(audit['loaded_at']):raise ValueError('source predates BI load: '+str(cell))
    if 402 in runs and (runs[402]['id']!=210 or runs[402]['cell_version']!=1):
        raise ValueError('official capture402/210 must remain preserved')
    portal=_provenance(runs[353]);auditor=_provenance(runs[413])
    bi=dict(schema='estudo',tabela='fat_perfil_br_2026_20261109',relacao=_FACT,
            loaded_at=audit['loaded_at'],snapshot_id=audit['snapshot_id'],
            status=audit['status'],activated_at=audit.get('activated_at'),
            sha256_rotina=audit['source_script_sha256'],
            hash_auditoria=hashlib.sha256(_json(audit).encode()).hexdigest(),
            hashes_funcoes=audit.get('function_contract',{}),hashes_adaptadores=audit['activated_views'],
            auditoria=auditor,validacoes=dict(quantidade=18,verificado_em=verification.get('verified_at'),controles=checks))
    highlights=dict(portal,fonte_celula=353,fonte_revisao=portal['revisao'],fonte_execucao=portal['execucao'])
    origin=('BI 2026: '+_FACT+'; carga '+audit['loaded_at']+'; snapshot '+audit['snapshot_id']+
            '. Adaptadores estudo preservam dimensões ausentes. Auditoria célula 413 rev'+str(auditor['revisao'])+
            ' / congelamento '+str(auditor['execucao'])+'. Complementos operacionais por id_resultado; fontes congeladas e datas próprias por tema. '
            'Corte 30/09/2026; fonte oficial Floripa402/210, PDF2025 e evidências históricas preservados.')
    profile={}
    if 361 in runs:
        profile['regra_peso']=('Peso: intervalo de20 a300 kg, inclusivo, confirmado pelo responsável. '
            'Informações atuais das contas elegíveis, renovadas no congelamento '+str(runs[361]['id'])+
            '; valores fora do intervalo excluídos. Alternativas e bases permanecem no notebook.')
    mapping={'diagnosticos_historicos':{
        'referencia_publicacao':41,'referencia_execucao':233,
        'nota':'Fórmula antiga do Stats e sobreposição azul/vermelho são evidência herdada, preservada para auditoria; não foram recalculadas pela fonte atual de mapeamento.'}}
    return dict(bi=bi,auditor=auditor,portal=portal,highlights=highlights,refs=[portal,auditor],origin=origin,profile=profile,mapping=mapping),runs

def _refresh_current_literals(sql,portal):
    """Only current plain provenance strings change; JSON literals stay opaque.

    Structured JSON literals include independently dated historical evidence.
    SQL code, comments, identifiers, numbers, numeric strings and402/210 are never
    rewritten here. Numeric boundaries prevent changing a run2180 into3090.
    """
    out=[]
    for kind,text in _tokens(sql):
        if kind!='literal':out.append(text);continue
        value=text[1:-1].replace("''", "'")
        try:json.loads(value)
        except (ValueError,TypeError):
            value=re.sub(r'(?<!\w)((?:célula\s+)?353\s+rev)\d+(?!\d)',lambda m:m[1]+str(portal['revisao']),value,flags=re.I)
            value=re.sub(r'(?<!\w)(congel(?:amento)?\s*)218(?!\w)',lambda m:m[1]+str(portal['execucao']),value,flags=re.I)
            text=sql_literal(value)
        out.append(text)
    return ''.join(out)

def annotate_final(sql,runs,source_audit):
    """Return one read-only SELECT; update provenance without metric projection.

    Never applies to418 automatically. The input analytical SELECT is retained;
    only plain labels353/218 and the meta provenance fields below can change.
    """
    assert_no_operational_sources(sql)
    annotation,runs=_annotation(runs,source_audit)
    source=_refresh_current_literals(sql.strip().rstrip(';'),annotation['portal'])
    reference_tests=' OR '.join('(id='+str(runs[cell]['id'])+' AND cell_id='+str(cell)+' AND cell_version='+str(runs[cell]['cell_version'])+')' for cell in (353,413))
    statement="""WITH provenance_source AS MATERIALIZED (
SOURCE
), provenance_annotation AS (SELECT CONFIG::jsonb AS p), provenance_guard AS (
 SELECT id FROM estudo.notebook_runs WHERE (REFERENCE_TESTS)
 AND frozen AND status='ok' AND NOT truncated AND row_count=1
)
SELECT s.payload || jsonb_build_object('meta',s.payload->'meta'||jsonb_build_object(
 'origem',a.p->'origin',
 'bi_fonte_versionada',a.p->'bi',
 'auditoria_bi',a.p->'auditor',
 'perfil',coalesce(s.payload#>'{meta,perfil}','{}'::jsonb)||(a.p->'profile'),
 'mapeamento',coalesce(s.payload#>'{meta,mapeamento}','{}'::jsonb)||(a.p->'mapping'),
 'maratonas',coalesce(s.payload#>'{meta,maratonas}','{}'::jsonb)||(a.p->'portal'),
 'maratonas_destaques',coalesce(s.payload#>'{meta,maratonas_destaques}','{}'::jsonb)||(a.p->'highlights')||jsonb_build_object('derivado_em',transaction_timestamp()),
 'notebook_fontes',coalesce((SELECT jsonb_agg(ref.value ORDER BY ref.ordinality)
   FROM jsonb_array_elements(CASE WHEN jsonb_typeof(s.payload#>'{meta,notebook_fontes}')='array'
     THEN s.payload#>'{meta,notebook_fontes}' ELSE '[]'::jsonb END) WITH ORDINALITY ref
   WHERE coalesce(ref.value->>'celula','') NOT IN('353','413')),'[]'::jsonb)||(a.p->'refs')
)) AS payload FROM provenance_source s CROSS JOIN provenance_annotation a
WHERE (SELECT count(*) FROM provenance_guard)=2"""
    # Replace individual markers rather than formatting SQL braces/JSON paths.
    statement=statement.replace('REFERENCE_TESTS',reference_tests,1).replace('CONFIG',sql_literal(_json(annotation)),1)
    statement=statement.replace('\nSOURCE\n','\n'+source+'\n',1)
    assert_no_operational_sources(statement)
    return '-- Proveniência da carga09/11; métricas e capturas oficiais preservadas.\n'+statement
