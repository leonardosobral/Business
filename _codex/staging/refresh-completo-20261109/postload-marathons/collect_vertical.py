"""Scoped source refresh: only six explicitly authorized vertical cells.

No notebook edits, DDL, publication, product changes or operational mutations.
StudyNotebook executes the analytical SQL with its existing read-only limits.
"""
from pathlib import Path
import base64,hashlib,importlib.util,json,os,sys,time
W=Path(__file__).resolve().parent
BASE=W.parent
spec=importlib.util.spec_from_file_location('vertical_refresh_reader',BASE/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
ALLOWED={424,426,435,437,442,452}
ALL=(423,424,425,426,427,428,429,432,433,434,435,436,437,441,442,444,445,446,449,452,453)
ACTOR=json.loads((BASE/'preflight.json').read_text())['actor']

def query(sql):return reader.query(sql)

def metadata():
    ids=','.join(map(str,ALL))
    result=query("SELECT jsonb_build_object('cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'version',c.version,'hash',md5(c.content),'content',c.content,'section',c.notebook_id,'last_frozen',(SELECT jsonb_build_object('id',r.id,'cell_version',r.cell_version,'started_at',r.started_at,'status',r.status,'frozen',r.frozen,'truncated',r.truncated) FROM estudo.notebook_runs r WHERE r.cell_id=c.id AND r.frozen ORDER BY r.id DESC LIMIT 1)) ORDER BY c.id) FROM estudo.notebook_cells c WHERE c.id IN("+ids+") AND NOT c.archived),'load',(SELECT to_jsonb(a) FROM estudo.fat_perfil_br_2026_20261109_audit a),'products',(SELECT jsonb_agg(jsonb_build_object('code',codigo,'publication',publicacao_id)) FROM estudo.produtos))::text AS payload")
    (W/'metadata-current.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
    (W/'sources').mkdir(exist_ok=True)
    for c in result['cells']:(W/'sources'/f"cell-{c['id']}.sql").write_text(c['content'])
    return result

def collect(cell_id):
    assert cell_id in ALLOWED,'Source not authorized for notebook execution'
    # Reread the exact cell immediately before the execute guard.
    c=query("SELECT jsonb_build_object('id',id,'version',version,'hash',md5(content),'content',content)::text AS payload FROM estudo.notebook_cells WHERE id="+str(cell_id)+" AND NOT archived")
    target=W/'runs'/f'{cell_id}.json';target.parent.mkdir(exist_ok=True)
    if target.exists():
        prior=json.loads(target.read_text())
        if prior.get('run',{}).get('frozen') and prior['run']['cell_version']==c['version'] and prior['source']['hash']==c['hash']:
            print(json.dumps({'cell':cell_id,'reuse':prior['run']['id']}),flush=True);return prior
        raise RuntimeError('Existing attempt requires review: '+str(target))
    cfg=dict(c,actor=ACTOR)
    enc=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
    cf='cfg=deserializeJSON(toString(binaryDecode("'+enc+'","base64")));'
    cf+='current=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=:id AND NOT archived",{id={value=cfg.id,cfsqltype="cf_sql_bigint"}},{datasource="runner_dba",timeout=10});'
    cf+='if(current.recordCount!=1 || current.version[1]!=cfg.version || current.hash[1]!=cfg.hash)throw(message="A célula mudou; releia antes de executar.");'
    cf+='svc=new estudo.includes.StudyNotebook().init();run=svc.execute(cfg.id,cfg.version,cfg.content,cfg.actor);'
    cf+='if(run.status=="ok" && !run.truncated)run=svc.freeze(run.id,"Maratonas — recaptura Jan–Set — 09/11/2026 — célula "&cfg.id,"Mesma amostra/critério da revisão vigente. Nova fonte BI versionada após carga DataGrip; ainda candidato sem publicação. Floripa oficial210 permanece independente dos perfis BI.",cfg.actor);'
    cf+='structDelete(run,"result_json");report={run=run};'
    result=reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
    run=result.get('run',result.get('RUN'))
    record={'source':{k:c[k]for k in ('id','version','hash')},'run':run}
    target.write_text(json.dumps(record,ensure_ascii=False,indent=2))
    if run and run['status']=='ok' and run['frozen']:
        record['data']=query("SELECT jsonb_build_object('id',id,'cell_id',cell_id,'cell_version',cell_version,'started_at',started_at,'frozen',frozen,'status',status,'truncated',truncated,'result',result)::text AS payload FROM estudo.notebook_runs WHERE id="+str(int(run['id'])))
        target.write_text(json.dumps(record,ensure_ascii=False,indent=2))
    print(json.dumps({'cell':cell_id,'run':run['id'],'status':run['status'],'frozen':run['frozen'],'rows':run.get('row_count'),'duration_ms':run.get('duration_ms'),'error':run.get('error_message')}),flush=True)
    return record

if __name__=='__main__':
    print(json.dumps({'owned_process_pid':os.getpid(),'started_at_epoch':time.time(),'mode':sys.argv[1:]}),flush=True)
    if sys.argv[1:] == ['metadata']:
        x=metadata();print(json.dumps({'cells':len(x['cells']),'load_status':x['load']['status'],'load_rows':x['load']['quality'].get('fact')}),flush=True)
    else:
        for cell in map(int,sys.argv[1:]):collect(cell)
