from pathlib import Path
import importlib.util,json,base64,sys,time,signal
W=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('refresh_inspect',W/'inspect.py')
h=importlib.util.module_from_spec(s);s.loader.exec_module(h)
ROOT=h.ROOT
snapshot=json.loads((W/'notebook-before.json').read_text())
cells={c['id']:c for c in snapshot['cells']}
actor=json.loads((W/'preflight.json').read_text())['actor']
DEST=W/'runs';DEST.mkdir(exist_ok=True)
def collect(cid):
 cell=cells[cid];dest=DEST/f'{cid}.json'
 if dest.exists():
  old=json.loads(dest.read_text())
  if old['run']['frozen'] and old['run']['cell_version']==cell['version']:
   if 'data' not in old:
    old['data']=h.query("SELECT jsonb_build_object('result',result,'id',id,'cell_id',cell_id,'cell_version',cell_version,'started_at',started_at,'frozen',frozen,'status',status)::text AS payload FROM estudo.notebook_runs WHERE id="+str(int(old['run']['id'])))
    dest.write_text(json.dumps(old,ensure_ascii=False,indent=2))
   print(json.dumps({'cell':cid,'already_collected':old['run']['id']}),flush=True);return old
 cfg={'id':cid,'version':cell['version'],'hash':cell['hash'],'sql':cell['content'],'actor':actor,
      'title':f'Atualização Jan–Set — 09/11/2026 — célula {cid}',
      'note':'Renovação completa solicitada em 09/11/2026. Mesmos critérios e corte da revisão vigente; pacote candidato, ainda não publicado. A data de coleta não amplia a janela de eventos.'}
 encoded=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
 cf='cfg=deserializeJSON(toString(binaryDecode("'+encoded+'","base64")));'
 cf+='current=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=:id AND NOT archived",{id={value=cfg.id,cfsqltype="cf_sql_bigint"}},{datasource="runner_dba",timeout=10});'
 cf+='if(current.recordCount!=1 || current.version[1]!=cfg.version || current.hash[1]!=cfg.hash)throw(message="Revisão mudou; não executar sem reler.");'
 cf+='svc=new estudo.includes.StudyNotebook().init();run=svc.execute(cfg.id,cfg.version,cfg.sql,cfg.actor);'
 cf+='if(run.status=="ok" && !run.truncated)run=svc.freeze(run.id,cfg.title,cfg.note,cfg.actor);'
 cf+='structDelete(run,"result_json");report={run=run};'
 result=h.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
 run=result.get('run',result.get('RUN'))
 if not run:raise RuntimeError('Missing execution receipt: '+str(result))
 result={'run':run};dest.write_text(json.dumps(result,ensure_ascii=False,indent=2))
 print(json.dumps({'cell':cid,'run':run['id'],'status':run['status'],'frozen':run['frozen'],'duration_ms':run['duration_ms'],'error':run.get('error_message','')},ensure_ascii=False),flush=True)
 if run['status']!='ok' or not run['frozen']:return result
 data=h.query("SELECT jsonb_build_object('result',result,'id',id,'cell_id',cell_id,'cell_version',cell_version,'started_at',started_at,'frozen',frozen,'status',status)::text AS payload FROM estudo.notebook_runs WHERE id="+str(int(run['id'])))
 result['data']=data;dest.write_text(json.dumps(result,ensure_ascii=False,indent=2))
 return result
if __name__=='__main__':
 for cid in map(int,sys.argv[1:]):collect(cid)
