#!/usr/bin/env python3
"""Read-only post-load production/local consumer capture via the existing SSH bridge.

No database DML/DDL or runtime publication. The loopback-only temporary CF bridge
uses its existing finally cleanup and a unique task prefix checked after capture.
"""
import base64
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import re
import uuid

HERE=Path(__file__).resolve().parent
STAGE=HERE.parent
BUSINESS=HERE.parents[3]
RR=BUSINESS.parent/'RoadRunners'


def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);return mod


SQL="""SELECT jsonb_build_object(
 'captured_at',clock_timestamp(),'database_user',current_user,
 'products',(SELECT jsonb_agg(jsonb_build_object('id',p.id,'code',p.codigo,'status',p.status,
   'publication',p.publicacao_id,'run',w.run_id,'published_at',w.publicado_em,
   'payload_sha256',encode(sha256(convert_to(w.payload::text,'UTF8')),'hex')) ORDER BY p.id)
   FROM estudo.produtos p LEFT JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id),
 'destinations',(SELECT jsonb_agg(to_jsonb(d) ORDER BY ano) FROM estudo.web_destinos d),
 'view',(SELECT jsonb_build_object('definition',pg_get_viewdef(c.oid,true),
   'sha256',encode(sha256(convert_to(pg_get_viewdef(c.oid,true),'UTF8')),'hex'),
   'owner',pg_get_userbyid(c.relowner),'options',c.reloptions,
   'security_barrier',coalesce(c.reloptions,'{}') @> ARRAY['security_barrier=true'])
   FROM pg_class c WHERE c.oid='estudo.lancamento_publico'::regclass),
 'source_runs',(SELECT jsonb_agg(jsonb_build_object('id',r.id,'cell',r.cell_id,'revision',r.cell_version,
   'status',r.status,'frozen',r.frozen,'truncated',r.truncated,'row_count',r.row_count,
   'frozen_at',r.frozen_at,'payload_sha256',encode(sha256(convert_to((r.result->'rows'->0->'payload')::text,'UTF8')),'hex')) ORDER BY r.id)
   FROM estudo.notebook_runs r WHERE r.cell_id IN(387,418,420) AND r.frozen),
 'annual_latest_run',(SELECT r.id FROM estudo.notebook_runs r JOIN estudo.notebook_cells c ON c.id=r.cell_id
   WHERE c.source_key='bqc-2026-anual-output' AND NOT c.archived AND r.frozen AND r.status='ok'
   AND NOT r.truncated AND r.row_count=1 AND r.result->'columns'='["payload"]'::jsonb
   AND jsonb_array_length(r.result->'rows')=1 ORDER BY r.frozen_at DESC,r.id DESC LIMIT 1),
 'privileges',jsonb_build_object(
   'product_update',has_table_privilege(current_user,'estudo.produtos','UPDATE'),
   'publication_insert',has_table_privilege(current_user,'estudo.web_publicacoes','INSERT'),
   'publish_function',has_function_privilege(current_user,'estudo.publicar_web(integer,bigint,bigint,bigint,text)','EXECUTE'),
   'preview_function',has_function_privilege(current_user,'estudo.web_payload_conferido(integer,bigint)','EXECUTE'),
   'schema_create',has_schema_privilege(current_user,'estudo','CREATE'))
)::text AS payload"""

REMOTE=r'''
roots={'business':Path('/var/www/business.roadrunners.run'),'portal':Path('/var/www/roadrunners.com.br')}
result={'files':{}}
for key in payload['files']:
 site,relative=key.split('/',1);p=roots[site]/relative
 raw=p.read_bytes()
 result['files'][key]={'sha256':digest(raw),'bytes':len(raw),'content_base64':base64.b64encode(raw).decode()}
result['database']=bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')
for key,record in result['files'].items():
 site,relative=key.split('/',1)
 if digest((roots[site]/relative).read_bytes())!=record['sha256']:raise RuntimeError('Production changed during capture: '+key)
result['temporary_directories_left']=[str(p) for p in (ROOT/'_codex').glob(payload['bridge_prefix']+'*')]
if result['temporary_directories_left']:raise RuntimeError('Owned temporary bridge cleanup incomplete')
print(json.dumps(result))
'''


def main():
    cutover=load('consumer_cutover_capture',STAGE/'consumer-cutover/consumer_cutover.py')
    remote=load('postload_read_operator',RR/'_codex/scripts/deploy_estudo_q3.py')
    prefix='postload-consumers-read-'+uuid.uuid4().hex+'-'
    remote.HELPERS=remote.HELPERS.replace("prefix='error-triage-op-'","prefix='"+prefix+"'")
    local={key:cutover.path_for(key,BUSINESS,RR).read_bytes() for key in cutover.REQUIRED_FILES}
    result=remote.remote(REMOTE,{'files':cutover.REQUIRED_FILES,'sql':SQL,'bridge_prefix':prefix})
    mismatch=[];files={}
    for key,record in result['files'].items():
        raw=base64.b64decode(record.pop('content_base64'))
        if cutover.sha(raw)!=record['sha256']:raise RuntimeError('Transport checksum mismatch: '+key)
        for kind,data in [('production',raw),('local',local[key])]:
            dest=HERE/'snapshots'/kind/key;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
        current=cutover.path_for(key,BUSINESS,RR).read_bytes()
        if current!=local[key]:raise RuntimeError('Checkout changed during capture: '+key)
        files[key]={'local_sha256':cutover.sha(local[key]),'production_sha256':record['sha256']}
        if files[key]['local_sha256']!=record['sha256']:mismatch.append(key)
    db=result['database'];view=db['view'];definition=view['definition']
    product=next(p for p in db['products'] if p['code']=='previa-2026-q3')
    match=re.search(r'r\.id\s*=\s*([1-9][0-9]*)\b',definition)
    if not match:raise RuntimeError('Public view run pin not recognized')
    public_run=int(match[1]);public=next(r for r in db['source_runs'] if r['id']==public_run)
    baseline={'captured_at':datetime.now(timezone.utc).isoformat(),'files':files,
              'generator_sha256':cutover.sha(cutover.reader_path(RR).read_bytes()),
              'database':{'product_id':product['id'],'publication_id':product['publication'],
                          'publication_run':product['run'],'public_run':public_run,'public_revision':public['revision'],
                          'paired_cell':387,'public_cell':420,'annual_cell':418,
                          'view_definition':definition,'view_sha256':view['sha256'],'security_barrier':view['security_barrier']}}
    if cutover.sha(definition.encode())!=view['sha256']:raise RuntimeError('DB/local definition hash mismatch')
    (HERE/'baseline.json').write_text(json.dumps(baseline,ensure_ascii=False,indent=2)+'\n')
    (HERE/'database-snapshot.json').write_text(json.dumps(db,ensure_ascii=False,indent=2)+'\n')
    report={'captured_at':baseline['captured_at'],'files':len(files),'divergent_files':mismatch,
            'current_product':product,'public_run':public_run,'public_revision':public['revision'],
            'annual_latest_run':db['annual_latest_run'],'view_owner':view['owner'],
            'security_barrier':view['security_barrier'],'privileges':db['privileges'],
            'owned_bridge_prefix':prefix,'temporary_directories_left':result['temporary_directories_left'],
            'ready_for_ids':not mismatch,'database_mutations':False,'runtime_publication':False}
    (HERE/'capture-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
