#!/usr/bin/env python3
"""Local candidate/diff builder for the coordinated Q3 consumer cutover.

Requires explicit new IDs, frozen evidence, and externally captured production
hashes matching the current checkout. Never connects to a server/database.
"""
import argparse
from datetime import datetime
import difflib
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess

HERE=Path(__file__).resolve().parent
BUSINESS=HERE.parents[3]
RR=BUSINESS.parent/'RoadRunners'
BIZ_ASSETS=['pagina.html','estudo.css','dados.js','graficos.js','parcial.js','estudo.js','navegacao.js']
PRESS='brasilquecorreprovas/imprensa/principal/'
REQUIRED_FILES=(
    ['business/estudos/includes/StudyAccess.cfc','business/estudos/leitor/index.cfm','business/estudos/leitor/dados.cfm',
     'business/estudo/includes/StudyEditions.cfc','business/estudo/anual/index.cfm','business/estudo/anual/dados.cfm','business/estudo/anual/_guard.cfm']
    +['business/estudos/leitor/'+x for x in BIZ_ASSETS]
    +['portal/brasilquecorreprovas/web/'+x for x in BIZ_ASSETS]
    +['portal/'+PRESS+x for x in ['index.cfm','dados.cfm','parcial-2026.js','estudo-2026.css']]
    +['portal/brasilquecorreprovas/2026/dados.cfm','portal/brasilquecorreprovas/imprensa/_guard.cfm'])
HOLD_FILES=['atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm',
            'includes/estrutura/header.cfm','includes/backend/backend_profile_settings.cfm',
            'api/profile/teams.cfm','teams/includes/start.cfm']
ID_KEYS=['publication_id','publication_run','public_run','public_revision','paired_run','paired_revision','annual_run','annual_revision']


def sha(data):return hashlib.sha256(data).hexdigest()


def reader_path(rr):return Path(rr)/'_codex/staging/imprensa-estudos-20261019/reader-builder.py'


def path_for(key,business,rr):
    site,relative=key.split('/',1)
    if site not in {'business','portal'} or '..' in Path(relative).parts or Path(relative).is_absolute():raise ValueError('Invalid input path: '+key)
    return (Path(business) if site=='business' else Path(rr))/relative


def positive(value,name):
    if isinstance(value,bool) or not re.fullmatch(r'[1-9][0-9]{0,14}',str(value)):
        raise ValueError('Explicit positive integer required: '+name)
    return int(value)


def exact(text,old,new):
    if text.count(old)!=1:raise ValueError('Canonical source changed; expected exactly once: '+old)
    return text.replace(old,new,1)


def repoint_cfc(text,old_publication,old_public,old_revision,new_publication,new_public,new_revision):
    replacements=[(f'AND a.publicacao_id={old_publication} AND jsonb_extract_path_text',f'AND a.publicacao_id={new_publication} AND jsonb_extract_path_text'),
                  (f'WHERE id={old_public} AND cell_id=420 AND cell_version={old_revision} AND frozen',f'WHERE id={new_public} AND cell_id=420 AND cell_version={new_revision} AND frozen'),
                  (f"'narrativa',jsonb_build_object('celula',420,'execucao',{old_public},'revisao',{old_revision})",f"'narrativa',jsonb_build_object('celula',420,'execucao',{new_public},'revisao',{new_revision})")]
    for old,new in replacements:text=exact(text,old,new)
    return text


def validate_inputs(baseline,ids,evidence,business=BUSINESS,rr=RR):
    try:
        captured=datetime.fromisoformat(baseline['captured_at'])
        if captured.tzinfo is None:raise ValueError('Production capture must have a timezone')
        values={key:positive(ids[key],key) for key in ID_KEYS}
        if set(ids)!=set(ID_KEYS):raise ValueError('ID map must have exactly the documented keys')
        db=baseline['database']
        for key in ['product_id','publication_id','publication_run','public_run','public_revision']:
            positive(db[key],'baseline.'+key)
        if db['paired_cell']!=387 or db['public_cell']!=420 or db['annual_cell']!=418:
            raise ValueError('Approved notebook cell contract changed; review manually')
        if db['contract_version']!=17 or evidence['publication']['contract_version']!=18:
            raise ValueError('Only the explicitly reviewed contract transition 17 to 18 is allowed')
        for key,year,cell in [('destination2026',2026,251),('destination2025',2025,249)]:
            destination=db[key]
            if destination['ano']!=year or destination['cell_id']!=cell:
                raise ValueError('Technical destination cell/year changed')
            positive(destination['publicacao_id'],key+'.publication');positive(destination['versao'],key+'.version')
        if db['destination2026']['publicacao_id']!=db['publication_id']:
            raise ValueError('Product and technical destination baseline are not aligned')
        for key in ['publication_id','publication_run','public_run']:
            if values[key]==int(db[key]):raise ValueError('New target still uses old pin: '+key)
        if values['public_revision']<=int(db['public_revision']):raise ValueError('Public narrative needs a new saved revision')
        if db['security_barrier'] is not True or sha(db['view_definition'].encode())!=db['view_sha256']:
            raise ValueError('Public view baseline changed or missing barrier evidence')
        if not re.search(r'p\.publicacao_id\s*=\s*'+str(db['publication_id'])+r'\b',db['view_definition']) or not re.search(r'r\.id\s*=\s*'+str(db['public_run'])+r'\b',db['view_definition']):
            raise ValueError('Public view does not match the expected product/narrative baseline')
        source={}
        for key in REQUIRED_FILES:
            record=baseline['files'][key]
            raw=path_for(key,business,rr).read_bytes()
            digest=sha(raw)
            if record['local_sha256']!=digest or record['production_sha256']!=digest:
                raise ValueError('Production/local baseline divergence: '+key)
            source[key]=raw.decode('utf-8')
        if sha(reader_path(rr).read_bytes())!=baseline['generator_sha256']:
            raise ValueError('Canonical reader generator changed')
        editions=source['business/estudo/includes/StudyEditions.cfc']
        if "c.source_key='bqc-2026-anual-output'" not in editions or 'ORDER BY r.frozen_at DESC,r.id DESC LIMIT 1' not in editions:
            raise ValueError('Annual latest-frozen contract changed')
        if "datasource='runnerhub'" not in source['portal/brasilquecorreprovas/2026/dados.cfm'] or 'SELECT payload FROM estudo.lancamento_publico' not in source['portal/brasilquecorreprovas/2026/dados.cfm']:
            raise ValueError('Public endpoint access contract changed')
        publication=evidence['publication']
        if any(publication[k]!=expected for k,expected in {'id':values['publication_id'],'run':values['publication_run'],'year':2026,'cell':251,'paired_run':values['paired_run'],'paired_revision':values['paired_revision']}.items()):
            raise ValueError('Publication evidence is not linked to requested output and paired source')
        if not re.fullmatch(r'[0-9a-f]{64}',publication['payload_sha256']):raise ValueError('Missing professional payload hash')
        runs={positive(x['id'],'run.id'):x for x in evidence['runs']}
        for run,cell,revision in [(values['public_run'],420,values['public_revision']),(values['paired_run'],387,values['paired_revision']),(values['annual_run'],418,values['annual_revision'])]:
            row=runs[run]
            if row['cell']!=cell or row['revision']!=revision or row['frozen'] is not True or row['status']!='ok' or row['truncated'] is not False or row['row_count']!=1:
                raise ValueError('Incomplete, unfrozen or mismatched target run: '+str(run))
        if not re.fullmatch(r'[0-9a-f]{64}',runs[values['public_run']]['payload_sha256']):raise ValueError('Missing public payload hash')
        if evidence['annual_latest_run']!=values['annual_run']:raise ValueError('Annual latest run does not match requested target')
        return values,db,source
    except (KeyError,TypeError,AttributeError,OSError) as error:
        raise ValueError('Incomplete baseline, IDs or evidence: '+str(error)) from error


def database_sql(db,ids,evidence):
    r={x['id']:x for x in evidence['runs']}
    annual=ids['annual_run'];pid=ids['publication_id'];public=ids['public_run']
    checks=[]
    for run,cell,rev in [(public,420,ids['public_revision']),(ids['paired_run'],387,ids['paired_revision']),(annual,418,ids['annual_revision'])]:
        extra=" AND encode(sha256(convert_to((result->'rows'->0->'payload')::text,'UTF8')),'hex')='"+r[public]['payload_sha256']+"'" if run==public else ''
        checks.append(f"IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id={run} AND cell_id={cell} AND cell_version={rev} AND frozen AND status='ok' AND NOT truncated AND row_count=1{extra}) THEN RAISE EXCEPTION 'Target run {run} changed'; END IF;")
    dest=db['destination2026'];prior25=db['destination2025']
    guard25=f"ano=2025 AND cell_id=249 AND publicacao_id={prior25['publicacao_id']} AND versao={prior25['versao']}"
    return f"""-- DBA review artifact only. This helper never executes this transaction.
-- Private unreferenced publication exists; all active pointers remain old until this transaction.
-- Deploy and verify the compatible runtime before executing in DataGrip.
BEGIN;
SET LOCAL lock_timeout='5s';
DO $consumer_cutover$
DECLARE touched integer;
BEGIN
 PERFORM ano FROM estudo.web_destinos WHERE ano IN(2025,2026) ORDER BY ano FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE {guard25}) THEN RAISE EXCEPTION '2025 destination changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND cell_id=251 AND publicacao_id={dest['publicacao_id']} AND versao={dest['versao']}) THEN RAISE EXCEPTION '2026 technical destination changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_publicacoes WHERE id={db['publication_id']} AND run_id={db['publication_run']} AND payload->'meta'->>'contrato_versao'='17') THEN RAISE EXCEPTION 'Previous contract/publication changed'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.web_destinos WHERE publicacao_id={pid}) OR EXISTS(SELECT 1 FROM estudo.produtos WHERE publicacao_id={pid}) THEN RAISE EXCEPTION 'Candidate publication already referenced'; END IF;
 IF encode(sha256(convert_to(pg_get_viewdef('estudo.lancamento_publico'::regclass,true),'UTF8')),'hex')<>'{db['view_sha256']}' THEN RAISE EXCEPTION 'Public view changed; recapture baseline'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_class WHERE oid='estudo.lancamento_publico'::regclass AND coalesce(reloptions,'{{}}') @> ARRAY['security_barrier=true']) THEN RAISE EXCEPTION 'Public view barrier changed'; END IF;
 PERFORM id FROM estudo.produtos WHERE id={db['product_id']} AND codigo='previa-2026-q3' AND status='ACTIVE' AND publicacao_id={db['publication_id']} FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Product pointer changed'; END IF;
 {' '.join(checks)}
 IF NOT EXISTS(SELECT 1 FROM estudo.web_publicacoes p JOIN estudo.notebook_runs r ON r.id=p.run_id WHERE p.id={pid} AND p.ano=2026 AND p.run_id={ids['publication_run']} AND r.cell_id=251 AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1 AND encode(sha256(convert_to(p.payload::text,'UTF8')),'hex')='{evidence['publication']['payload_sha256']}' AND p.payload=r.result->'rows'->0->'payload' AND p.payload=estudo.web_payload_conferido(2026,{ids['publication_run']}) AND p.payload->'meta'->>'contrato_versao'='18' AND p.payload->'meta'->>'corte'='2026-09-30' AND p.payload->'meta'->>'periodo_inicio'='2026-01-01' AND EXISTS(SELECT 1 FROM jsonb_array_elements(p.payload->'meta'->'notebook_fontes') f WHERE f->>'celula'='387' AND f->>'execucao'='{ids['paired_run']}' AND f->>'revisao'='{ids['paired_revision']}')) THEN RAISE EXCEPTION 'Professional publication/source link changed'; END IF;
 IF NOT EXISTS(
   SELECT 1 FROM estudo.web_publicacoes p
   JOIN estudo.notebook_runs paired ON paired.id={ids['paired_run']}
   JOIN estudo.notebook_runs public_run ON public_run.id={public}
   CROSS JOIN LATERAL (SELECT paired.result->'rows'->0->'payload' AS summary, public_run.result->'rows'->0->'payload' AS document) raw
   CROSS JOIN LATERAL (SELECT raw.document->'release' AS release) n
   WHERE p.id={pid} AND raw.document->'ok'='true'::jsonb
     AND raw.document - ARRAY['ok','release']='{{}}'::jsonb
     AND n.release - ARRAY['title','periodo_inicio','periodo_fim','coleta','indicadores','historias']='{{}}'::jsonb
     AND n.release->>'periodo_inicio'='2026-01-01' AND n.release->>'periodo_fim'='2026-09-30'
     AND n.release->>'coleta' ~ '^20[0-9]{{2}}-[0-9]{{2}}-[0-9]{{2}}$'
     AND jsonb_array_length(n.release->'indicadores')=6
     AND (SELECT count(DISTINCT i->>'id') FROM jsonb_array_elements(n.release->'indicadores') i)=6
     AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(n.release->'indicadores') i
       WHERE i->>'id' NOT IN('femininas','millennials','distancias_curtas','interior','terceiro_trimestre','concentracao_porte')
         OR i - ARRAY['id','valor','label','descricao','universo','comparativo']<>'{{}}'::jsonb
         OR (i->'comparativo') - ARRAY['anterior','nota']<>'{{}}'::jsonb)
     AND (n.release->'historias') - ARRAY['pareadas','provas','resultados','mulheres']='{{}}'::jsonb
     AND (n.release->'historias'->'mulheres') - ARRAY['anterior','atual','diferenca_pp']='{{}}'::jsonb
     AND NOT EXISTS(SELECT 1 FROM jsonb_each(n.release->'historias') h WHERE h.key<>'mulheres' AND h.value - 'variacao_percentual'<>'{{}}'::jsonb)
     AND raw.summary->>'periodo'='Jan–Set de2025 e2026'
     AND (raw.summary#>>'{{coorte_pareada,pares}}')::bigint>0
     AND (raw.summary#>>'{{coorte_pareada,concluintes_2025}}')::bigint>0
     AND (raw.summary#>>'{{coorte_pareada,concluintes_2026}}')::bigint>=0
     AND round((raw.summary#>>'{{coorte_pareada,variacao_pct}}')::numeric,1)=(n.release#>>'{{historias,pareadas,variacao_percentual}}')::numeric
     AND round((p.payload#>>'{{comparativo,provas,meses_completos,variacao_cadastradas}}')::numeric,1)=(n.release#>>'{{historias,provas,variacao_percentual}}')::numeric
 ) THEN RAISE EXCEPTION 'Comparative rates or public release contract changed'; END IF;
 IF (SELECT r.id FROM estudo.notebook_runs r JOIN estudo.notebook_cells c ON c.id=r.cell_id WHERE c.source_key='bqc-2026-anual-output' AND NOT c.archived AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1 AND r.result->'columns'='["payload"]'::jsonb AND jsonb_array_length(r.result->'rows')=1 ORDER BY r.frozen_at DESC,r.id DESC LIMIT 1) IS DISTINCT FROM {annual} THEN RAISE EXCEPTION 'Annual latest-frozen changed'; END IF;
 UPDATE estudo.web_destinos SET publicacao_id={pid},versao=versao+1 WHERE ano=2026 AND cell_id=251 AND publicacao_id={dest['publicacao_id']} AND versao={dest['versao']};
 GET DIAGNOSTICS touched=ROW_COUNT;
 IF touched<>1 THEN RAISE EXCEPTION 'Technical destination cutover did not update exactly one row'; END IF;
 UPDATE estudo.produtos SET publicacao_id={pid} WHERE id={db['product_id']} AND codigo='previa-2026-q3' AND status='ACTIVE' AND publicacao_id={db['publication_id']};
 GET DIAGNOSTICS touched=ROW_COUNT;
 IF touched<>1 THEN RAISE EXCEPTION 'Product cutover did not update exactly one row'; END IF;
END;$consumer_cutover$;
CREATE OR REPLACE VIEW estudo.lancamento_publico WITH (security_barrier=true) AS
SELECT r.result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs r
JOIN estudo.produtos p ON p.codigo='previa-2026-q3' AND p.status='ACTIVE' AND p.publicacao_id={pid}
WHERE r.id={public} AND r.cell_id=420 AND r.cell_version={ids['public_revision']} AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1;
DO $consumer_postcheck$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE {guard25}) THEN RAISE EXCEPTION '2025 destination changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND cell_id=251 AND publicacao_id={pid} AND versao={dest['versao']+1}) THEN RAISE EXCEPTION 'Technical destination final mismatch'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.produtos WHERE id={db['product_id']} AND publicacao_id={pid} AND status='ACTIVE') THEN RAISE EXCEPTION 'Product final mismatch'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.lancamento_publico WHERE encode(sha256(convert_to(payload::text,'UTF8')),'hex')='{r[public]['payload_sha256']}') THEN RAISE EXCEPTION 'Public view final mismatch'; END IF;
END;$consumer_postcheck$;
SELECT payload FROM estudo.lancamento_publico;
COMMIT;
"""


def build(baseline,ids,evidence,output,business=BUSINESS,rr=RR):
    ids,db,source=validate_inputs(baseline,ids,evidence,business,rr)
    business=Path(business).resolve();rr=Path(rr).resolve();output=Path(output).resolve()
    if output==business or output==rr or output.is_relative_to(business/'estudos') or output.is_relative_to(business/'estudo') or output.is_relative_to(rr/'brasilquecorreprovas'):
        raise ValueError('Output must be an isolated staging directory')
    if output.exists():raise ValueError('Output already exists; use a fresh candidate directory')
    before=source['business/estudos/includes/StudyAccess.cfc']
    cfc=repoint_cfc(before,db['publication_id'],db['public_run'],db['public_revision'],ids['publication_id'],ids['public_run'],ids['public_revision'])
    # An inverse transform proves no metric, authorization or unrelated byte changed.
    if repoint_cfc(cfc,ids['publication_id'],ids['public_run'],ids['public_revision'],db['publication_id'],db['public_run'],db['public_revision'])!=before:
        raise ValueError('Unexpected CFC change outside source pins')
    partial=exact(source['business/estudos/leitor/parcial.js'],f"meta.narrativa?.execucao!=={db['public_run']}",f"meta.narrativa?.execucao!=={ids['public_run']}")
    version=f"consumer-{ids['publication_id']}-{ids['public_run']}"
    index,count=re.subn(r'\?v=q3-20261109-comparativo', '?v='+version,source['business/estudos/leitor/index.cfm'])
    if count!=1:raise ValueError('Business cache-version contract changed')
    annual,count=re.subn(r'\?v=edicoes-20261010-1', '?v='+version,source['business/estudo/anual/index.cfm'])
    if count!=1:raise ValueError('Annual cache-version contract changed')
    candidates={'business/estudos/includes/StudyAccess.cfc':cfc,'business/estudos/leitor/parcial.js':partial,
                'business/estudos/leitor/index.cfm':index,'business/estudo/anual/index.cfm':annual}
    spec=importlib.util.spec_from_file_location('canonical_press_reader',reader_path(rr))
    reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
    reader.ROOT=rr;reader.BUSINESS=business
    def read_validated(path):
        path=Path(path).resolve()
        key=('business/'+str(path.relative_to(business))) if path.is_relative_to(business) else ('portal/'+str(path.relative_to(rr)))
        if key not in source:raise ValueError('Generator requested a source outside validated baseline: '+key)
        text=candidates.get(key,source[key]);reader.SOURCES[key]=sha(text.encode());return text
    reader.source=read_validated
    html25=reader.principal_html(2025);html26=reader.principal_html(2026)
    projection=reader.extract_projection(read_validated(business/'estudos/includes/StudyAccess.cfc'))
    old_projection=reader.extract_projection(before)
    if repoint_cfc(cfc,ids['publication_id'],ids['public_run'],ids['public_revision'],db['publication_id'],db['public_run'],db['public_revision'])!=before:raise ValueError('Projection metric drift')
    old_index=source['portal/'+PRESS+'index.cfm']
    start25=old_index.index('<cfif VARIABLES.pressYear EQ \'2025\'>')
    wrapper=old_index[old_index.index('<cfprocessingdirective'):start25]
    # Keep redirects and edition/access guards byte-identical; rebuild only the two HTML branches.
    index_content=wrapper+"<cfif VARIABLES.pressYear EQ '2025'>"+html25+'<cfelse>'+html26+'</cfif>\n'
    css=read_validated(business/'estudos/leitor/estudo.css')
    css=re.sub(r"url\((\s*[\"']?)assets/",lambda m:'url('+m[1]+reader.RR_ASSETS+'assets/',css)
    pjs=reader.partial_script()
    stamp='<!--- Generated by reader-builder.py. Canonical sources SHA-256: '+json.dumps(reader.SOURCES,ensure_ascii=False,sort_keys=True,separators=(',',':'))+' --->\n'
    candidates.update({'portal/'+PRESS+'index.cfm':stamp+index_content,
                       'portal/'+PRESS+'dados.cfm':stamp+reader.principal_data(projection),
                       'portal/'+PRESS+'parcial-2026.js':'// Generated from Business/estudos/leitor/parcial.js; rebuild via reader-builder.py.\n'+pjs,
                       'portal/'+PRESS+'estudo-2026.css':'/* Generated from Business/estudos/leitor/estudo.css; rebuild via reader-builder.py. */\n'+css})
    node=shutil.which('node')
    if node is None:raise ValueError('Node is required for syntax and RR Teams hold verification')
    check=rr/'_codex/scripts/check_rr_teams_release_hold.mjs'
    subprocess.run([node,str(check),'--root',str(rr)],capture_output=True,text=True,check=True,timeout=60)
    output.mkdir(parents=True)
    diffs=[]
    for key,content in candidates.items():
        dest=output/'candidate'/key;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(content,encoding='utf-8')
        original=source[key]
        diffs.extend(difflib.unified_diff(original.splitlines(True),content.splitlines(True),fromfile='a/'+key,tofile='b/'+key))
        if dest.suffix=='.js':subprocess.run([node,'--check',str(dest)],capture_output=True,text=True,check=True,timeout=30)
    verification=output/'candidate/portal'
    for relative in HOLD_FILES:
        p=verification/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes((rr/relative).read_bytes())
    (verification/'.rsync-filter').write_bytes((rr/'.rsync-filter').read_bytes())
    subprocess.run([node,str(check),'--root',str(verification)],capture_output=True,text=True,check=True,timeout=60)
    report={'ids':ids,'previous':{k:db[k] for k in ['product_id','publication_id','publication_run','public_run','public_revision']},
            'runtime_files':{key:{'before_sha256':sha(source[key].encode()),'candidate_sha256':sha(content.encode())} for key,content in candidates.items()},
            'generator_sha256':baseline['generator_sha256'],'source_hashes':reader.SOURCES,
            'projection_before_sha256':sha(old_projection.encode()),'projection_candidate_sha256':sha(projection.encode()),
            'changes':'Source IDs and presentation cache versions only; metrics and auth untouched.',
            'validation_only_files':['portal/'+p for p in HOLD_FILES]+['portal/.rsync-filter'],
            'transfer_allowlist':'Only runtime_files; validation templates are never routine transfer targets. RR transfers must use the root .rsync-filter (-F).',
            'teams_hold':{'checkout':True,'candidate':True},
            'annual':{'mode':'latest-frozen, unchanged','target_run':ids['annual_run'],'source_cell':418,'product_activation':False},
            'technical_destination':{'before':db['destination2026'],'after':{**db['destination2026'],'publicacao_id':ids['publication_id'],'versao':db['destination2026']['versao']+1},'2025_preserved':db['destination2025']},
            'contract_transition':{'before':17,'after':18},
            'database_execution':False,'production_verification':'Pending live recapture, DBA transaction, compile and HTTP checks.'}
    (output/'manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    (output/'runtime.patch').write_text(''.join(diffs))
    (output/'database-cutover-DBA.sql').write_text(database_sql(db,ids,evidence))
    (output/'database-baseline.json').write_text(json.dumps(db,ensure_ascii=False,indent=2)+'\n')
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--describe',action='store_true',help='Print required baseline file keys and explicit ID fields, without writing')
    parser.add_argument('--baseline',type=Path)
    parser.add_argument('--ids',type=Path)
    parser.add_argument('--evidence',type=Path)
    parser.add_argument('--output-dir',type=Path)
    args=parser.parse_args()
    if args.describe:
        print(json.dumps({'files':REQUIRED_FILES,'id_keys':ID_KEYS,'canonical_generator':str(reader_path(RR))},indent=2));return
    if any(x is None for x in [args.baseline,args.ids,args.evidence,args.output_dir]):parser.error('--baseline, --ids, --evidence and --output-dir are required')
    report=build(json.loads(args.baseline.read_text()),json.loads(args.ids.read_text()),json.loads(args.evidence.read_text()),args.output_dir)
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
