"""Renew only authorized derived vertical cells, preserving editorial selections."""
from pathlib import Path
import base64,hashlib,importlib.util,json,re,sys
W=Path(__file__).resolve().parent;BASE=W.parent
sys.path.insert(0,str(BASE));import build_candidate as b
spec=importlib.util.spec_from_file_location('vertical_collector',W/'collect_vertical.py');op=importlib.util.module_from_spec(spec);spec.loader.exec_module(op)
ALLOWED={427,428,429,432,433,445,446,449,453}
DEPS={427:[425],428:[426],429:[427,428],432:[425,426],433:[251],445:[444,427,425],446:[444,445],449:[423,424,251],453:[425,426,427,428,429,436,437,452,251]}
SNAPSHOT=json.loads((W/'metadata-current.json').read_text())
CELLS={c['id']:c for c in SNAPSHOT['cells']}
ORIGINAL=json.loads((BASE/'notebook-before.json').read_text())
ORIGINAL_CELLS={c['id']:c for c in ORIGINAL['cells']}

def runs():
    out={}
    for directory in [BASE/'runs',BASE/'postload/runs',W/'runs']:
        for p in directory.glob('*.json'):
            try:r=b.normalize_runs([json.loads(p.read_text())]);out.update(r)
            except (ValueError,KeyError,json.JSONDecodeError):continue
    return out

def _semantic(value,remap,floripa_bi):
    if isinstance(value,list):return [_semantic(v,remap,floripa_bi)for v in value]
    if isinstance(value,dict):
        result={k:_semantic(v,remap,floripa_bi)for k,v in value.items()}
        for key in ('source_run','adoption_run'):
            if isinstance(result.get(key),int):result[key]=remap.get(result[key],result[key])
        if 'source_runs'in result:result['source_runs']=[remap.get(v,v)for v in result['source_runs']]
        return result
    if isinstance(value,str):
        value=re.sub(r'\b(congelamento|inventário|seleção) (\d+)\b',lambda m:m[1]+' '+str(remap.get(int(m[2]),int(m[2]))),value)
        if floripa_bi is not None:value=value.replace('3.594',f'{floripa_bi:,}'.replace(',','.'))
    return value

def prepare(cell):
    assert cell in ALLOWED
    r=runs()
    for source in DEPS[cell]:b.require_run(r,source)
    publication_path=W/'principal-publication.json'
    publication=json.loads(publication_path.read_text())if publication_path.exists()else None
    if publication and 251 in r:assert int(publication['run'])==r[251]['id'],'Principal publication/source mismatch'
    pubid=int(publication['publication_id'])if publication else None
    # Validate exact selection presence before deriving/finalizing a whitelist.
    if cell==427:
        ids={int(i)for i,decision in re.findall(r"\((\d+),'((?:''|[^'])*)'\)",CELLS[427]['content'])}
        available={int(v['id_evento'])for v in r[425]['result']['rows']}
        assert len(ids)==50 and ids<=available,'Missing curated2025 candidate; do not turn absence into zero'
    if cell==428:
        ids={int(v)for v in max(re.findall(r'\bIN\s*\(([\d,\s]+)\)',CELLS[428]['content']),key=len).split(',')}
        available={int(v['id_evento'])for v in r[426]['result']['rows']}
        assert len(ids)==39 and ids<=available,'Missing curated2026 candidate'
        for q in (435,437,442):
            fixed={int(v)for v in max(re.findall(r'\bIN\s*\(([\d,\s]+)\)',CELLS[q]['content']),key=len).split(',')}
            assert fixed==ids,f'Fixed selection differs in{q}'
    extra={233:r[251]['id']} if 251 in r else {}
    remap={int(c['last_frozen']['id']):r[cid]['id']for cid,c in ORIGINAL_CELLS.items()if cid in r and c.get('last_frozen')}
    remap.update(extra)
    sql=b.remap_frozen_references(CELLS[cell]['content'],r,ORIGINAL,extra_old_runs=remap)
    if cell==433:
        new=r[251]
        sql="""-- Principal2025 mantém congelamento205 histórico. Principal2026 é candidato novo, ainda sem afirmar publicação comercial.
WITH p AS (
 SELECT id,result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs
 WHERE id IN(205,"""+str(new['id'])+""") AND frozen AND status='ok' AND NOT truncated AND row_count=1
)
SELECT CASE WHEN id=205 THEN 37 ELSE """+str(pubid if pubid is not None else 'NULL::integer')+""" END AS publicacao,
 (payload->'meta'->>'ano')::integer AS ano,
 jsonb_build_object('meta',payload->'meta'||jsonb_build_object('principal_source_run',id,'principal_state',CASE WHEN id=205 THEN 'historico2025' ELSE 'candidato2026' END),
 'series',(SELECT jsonb_agg(s) FROM jsonb_array_elements(payload->'series')s WHERE s->>'id' LIKE 'maratonas_%' OR s->>'id' LIKE 'performance_42k_%' OR s->>'id' LIKE 'cna_42k%'),
 'comparacoes',(SELECT jsonb_agg(c) FROM jsonb_array_elements(payload->'comparacoes')c WHERE c->>'serie' LIKE 'maratonas_%' OR c->>'serie' LIKE 'performance_42k_%' OR c->>'serie' LIKE 'cna_42k%')) AS payload FROM p ORDER BY ano"""
    else:
        # Historical context CASE outputs contain source ids, not result counts.
        pieces=[]
        for kind,text in b._tokens(sql):
            if kind=='code':
                text=re.sub(r'\b(THEN|ELSE)\s+(\d+)\b',lambda m:m[1]+' '+str(remap.get(int(m[2]),int(m[2]))),text)
            elif kind=='literal':
                value=text[1:-1].replace("''", "'")
                try:j=json.loads(value)
                except ValueError:j=None
                if isinstance(j,(dict,list)):
                    floripa_bi=next((v['participacoes']for v in r.get(426,{}).get('result',{}).get('rows',[])if v['id_evento']==34529),None)
                    text=b.sql_literal(json.dumps(_semantic(j,remap,floripa_bi),ensure_ascii=False))
            pieces.append(text)
        sql=''.join(pieces)
        sql=re.sub(r"('(source_run|adoption_run)',\s*)(\d+)\b",lambda m:m[1]+str(remap.get(int(m[3]),int(m[3]))),sql)
    if cell==453:
        def context_meta(m):
            value=json.loads(m[1].replace("''", "'"))
            value['principal_context_run']=r[251]['id']
            value['principal_context_publication']=pubid
            value['source_runs'].append(r[251]['id']);value['source_cells'].append(251)
            return "'meta',"+b.sql_literal(json.dumps(value,ensure_ascii=False))+"::jsonb"
        sql,count=re.subn(r"'meta','((?:''|[^'])*)'::jsonb",context_meta,sql,count=1);assert count==1
        sql,count=re.subn(r'(FROM estudo.notebook_runs WHERE id IN\()([\d,]+)(\))',lambda m:m[1]+m[2]+','+str(r[251]['id'])+m[3],sql,count=1);assert count==1
    if cell==449:
        sql=sql.replace("'publication_ids',jsonb_build_array(37,41)","'publication_ids',jsonb_build_array(37,"+str(pubid if pubid is not None else 'NULL')+"),'principal2025_state','historico205','principal2026_run',"+str(r[251]['id']))
    # Preserve old documentary text but precede it with unambiguous current inputs.
    refs=[{'cell':source,'revision':r[source]['cell_version'],'run':r[source]['id'],'started_at':r[source].get('started_at')}for source in DEPS[cell]]
    sql='-- Renovação candidata09/11; curadoria/capturas externas preservadas; entradas='+json.dumps(refs,ensure_ascii=False)+'\n'+sql
    path=W/'sql'/f'cell-{cell}.sql';path.parent.mkdir(exist_ok=True);path.write_text(sql+'\n')
    return path

def save(cell):
    path=prepare(cell);content=path.read_text();target=W/'runs'/f'{cell}.json'
    prior=json.loads(target.read_text()) if target.exists() else None
    if prior and prior.get('sql_sha256')==hashlib.sha256(content.encode()).hexdigest():
        assert prior['run']['frozen'],'Existing non-frozen attempt requires review'
        print(json.dumps({'cell':cell,'reuse':prior['run']['id']}),flush=True);return
    live=op.query("SELECT jsonb_build_object('id',id,'version',version,'hash',md5(content),'content',content)::text AS payload FROM estudo.notebook_cells WHERE id="+str(cell)+" AND NOT archived")
    if prior:
        assert live['version']==prior['run']['cell_version'],'Cell version changed outside this chain'
        assert hashlib.sha256(live['content'].encode()).hexdigest()==prior['sql_sha256'],'Cell content changed outside this chain'
        archive=W/'attempt-history';archive.mkdir(exist_ok=True)
        (archive/f"cell-{cell}-run-{prior['run']['id']}.json").write_text(json.dumps(prior,ensure_ascii=False,indent=2))
    else:
        expected=CELLS[cell]
        assert live['version']==expected['version'] and live['hash']==expected['hash'],'Cell changed after metadata capture; stop before saving'
    cfg=dict(live,content=content,actor=op.ACTOR)
    enc=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
    cf='cfg=deserializeJSON(toString(binaryDecode("'+enc+'","base64")));'
    cf+='current=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=:id AND NOT archived",{id={value=cfg.id,cfsqltype="cf_sql_bigint"}},{datasource="runner_dba",timeout=10});'
    cf+='if(current.recordCount!=1 || current.version[1]!=cfg.version || current.hash[1]!=cfg.hash)throw(message="Célula mudou; reler antes de salvar.");'
    cf+='svc=new estudo.includes.StudyNotebook().init();saved=svc.saveCell(cfg.id,cfg.version,"code","sql",cfg.content,cfg.actor);run=svc.execute(saved.id,saved.version,saved.content,cfg.actor);'
    cf+='if(run.status=="ok" && !run.truncated)run=svc.freeze(run.id,"Maratonas — derivação renovada — 09/11/2026 — célula "&cfg.id,"Referências novas e curadoria literal preservada. Não publica HTML/produtos. Capturas externas mantêm suas datas. Principal2025 histórico205; demais temas com fontes próprias.",cfg.actor);structDelete(run,"result_json");report={run=run};'
    result=op.reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
    run=result.get('run',result.get('RUN'))
    rec={'source_before':live,'sql_sha256':hashlib.sha256(content.encode()).hexdigest(),'run':run}
    target.write_text(json.dumps(rec,ensure_ascii=False,indent=2))
    if run['status']=='ok' and run['frozen']:
        rec['data']=op.query("SELECT jsonb_build_object('id',id,'cell_id',cell_id,'cell_version',cell_version,'started_at',started_at,'status',status,'frozen',frozen,'truncated',truncated,'result',result)::text AS payload FROM estudo.notebook_runs WHERE id="+str(int(run['id'])))
        target.write_text(json.dumps(rec,ensure_ascii=False,indent=2))
    print(json.dumps({'cell':cell,'revision':run['cell_version'],'run':run['id'],'frozen':run['frozen'],'status':run['status'],'rows':run.get('row_count'),'error':run.get('error_message')}),flush=True)
    if not run['frozen']:raise RuntimeError('Derived query not frozen; stop chain')

if __name__=='__main__':
    for cell in map(int,sys.argv[2:]):
        if sys.argv[1]=='prepare':print(prepare(cell),flush=True)
        elif sys.argv[1]=='save':save(cell)
        else:raise ValueError('prepare|save required')
