"""Scoped Racezone cache recovery; all runtime source bytes remain unchanged."""
from pathlib import Path
import json
import shlex
import subprocess
import sys

HERE = Path(__file__).resolve().parent
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']

REMOTE = r'''
from pathlib import Path
import csv, hashlib, html, json, os, re, secrets, shutil, signal, subprocess, sys, tempfile, time
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

mode = sys.argv[1]
root = Path('/var/www/runnerhub.run')
cache = Path('/opt/coldfusion2025/cfusion/wwwroot/WEB-INF/cfclasses')
cfroot = Path('/opt/coldfusion2025/cfusion/wwwroot')
source_names = ['api/racezone/index.cfm', 'api/racezone/parse.cfm',
                'api/racezone/resolve_url.cfm', 'includes/seo-web-tools-head.cfm']
expected = {'api/racezone/index.cfm': '9ecd2f699542a1f35b38ce332cbf79843e9570be4d26e5861c3640dccc826dc4',
            'api/racezone/parse.cfm': 'a76787780747d3b614b76c7f8158e5f1ca8b2297f1d49c75c8fa6ff784223df5',
            'api/racezone/resolve_url.cfm': '8a2e315966fd6da1af2200ad154afb5cbe2fa96744f06769413f33255b5a2bc7'}
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
def stop(signum, frame):
    raise SystemExit(128 + signum)
signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

def bridge(body, timeout=40):
    """Isolated, token-protected loopback probe; never exposes an external URL."""
    work = Path(tempfile.mkdtemp(prefix='racezone-recovery-36657-', dir=cfroot))
    os.chmod(work, 0o755)
    token = secrets.token_hex(32)
    try:
        (work/'Application.cfc').write_text('component {this.name="' + work.name + '";'
          'this.datasource="runner_dba";this.sessionManagement=false;'
          'boolean function onRequestStart(string target){'
          'if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||'
          'compare(form.key ?: "","' + token + '")!=0){cfheader(statuscode=404);abort;}return true;}}')
        (work/'run.cfm').write_text('<cfsetting requesttimeout="' + str(timeout) + '" showdebugoutput="false"/>'
          '<cfcontent type="application/json" reset="true"/><cftry><cfscript>'
          + body + ';writeOutput(serializeJSON(report));</cfscript><cfcatch>'
          '<cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.type,message=cfcatch.message,detail=cfcatch.detail})#</cfoutput>'
          '</cfcatch></cftry>')
        for p in work.iterdir(): os.chmod(p, 0o644)
        response = subprocess.run(['curl', '-sS', '--max-time', str(timeout + 3),
          '-X', 'POST', '--data-urlencode', 'key=' + token,
          'http://127.0.0.1:8500/' + work.name + '/run.cfm'],
          capture_output=True, text=True, timeout=timeout+5)
        if response.returncode:
            raise RuntimeError('Probe transport failed: ' + response.stderr[-500:])
        try: result=json.loads(response.stdout)
        except Exception: raise RuntimeError('Non-JSON probe response: ' + re.sub('<[^>]+>', ' ', response.stdout)[:500])
        if any(k.lower()=='error' for k in result): raise RuntimeError(json.dumps(result))
        return result
    finally:
        shutil.rmtree(work)
        if work.exists(): raise RuntimeError('Temporary probe cleanup failed: ' + str(work))

def source_guard():
    for name, digest in expected.items():
        assert sha(root/name) == digest, 'Production source changed: ' + name

def rows_fn():
    return 'function rows(q){var a=[];for(var r in q)arrayAppend(a,r);return a;}'

source_guard()
stage=Path('/var/backups/runnerhub-racezone-cache-20261109-5f8132d5bd')
if mode == 'inspect':
    body=rows_fn()+"""report={event=rows(queryExecute("SELECT id_evento,nome_evento,tag,data_final,url_resultado,url_wiclax FROM tb_evento_corridas WHERE id_evento=36657",{},{timeout=10})),
      tables=rows(queryExecute("SELECT table_name,column_name,data_type FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('tb_resultados','tb_resultados_temp','tb_resultados_resumo','tb_resultados_processa','tb_resultados_processa_logs','tb_evento_corridas_percursos') ORDER BY table_name,ordinal_position",{},{timeout=10})),
      procedures=rows(queryExecute("SELECT p.proname,pg_get_functiondef(p.oid) AS definition FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname IN ('gera_resultados','atualiza_classific_f1_v2','atualiza_resultados_resumo_2025')",{},{timeout=10})),
      active=rows(queryExecute("SELECT state,wait_event_type,wait_event,count(*) AS n FROM pg_stat_activity WHERE pid<>pg_backend_pid() AND (query ILIKE '%36657%' OR query ILIKE '%racezone%') GROUP BY state,wait_event_type,wait_event",{},{timeout=10})),
      };
    """
    result=bridge(body)
    stage=Path('/var/backups')/('runnerhub-racezone-cache-20261109-'+secrets.token_hex(5))
    stage.mkdir(mode=0o700)
    (stage/'inspection.json').write_text(json.dumps(result,indent=2))
    os.chmod(stage/'inspection.json',0o600)
    metadata={}
    for name in source_names:
        p=root/name; dest=stage/'source'/name
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
        st=p.stat();metadata[name]={'sha256':sha(p),'mtime_ns':st.st_mtime_ns,'atime_ns':st.st_atime_ns,'mode':st.st_mode,'uid':st.st_uid,'gid':st.st_gid}
    (stage/'cache-before').mkdir()
    for p in cache.glob('cfparse2ecfm2083463583*.class'):
        shutil.copy2(p,stage/'cache-before'/p.name)
    (stage/'source-manifest.json').write_text(json.dumps(metadata,indent=2))
    result_l={k.lower():v for k,v in result.items()}
    procs=[]
    for p in result_l['procedures']:
        p={k.lower():v for k,v in p.items()}
        procs.append({'name':p['proname'],'mutations':re.findall(r'(?im)^\s*(?:insert\s+into|update|delete\s+from|call)\s+([a-z_0-9.]+)',p['definition'])})
    xml=ET.parse('/opt/coldfusion2025/cfusion/lib/neo-runtime.xml')
    settings={v.get('name'):ET.tostring(v,encoding='unicode') for v in xml.iter('var') if any(x in v.get('name','').lower() for x in ('trusted','classfile','templatecache'))}
    print(json.dumps({'backup':str(stage),'event':result_l['event'],'active':result_l['active'],'cache_settings':settings,'tables':[{k.lower():v for k,v in x.items()} for x in result_l['tables']],'procedures':procs,'source_hashes':{k:v['sha256'] for k,v in metadata.items()}}))
elif mode == 'snapshot':
    assert stage.is_dir() and not (stage/'database-before.json').exists()
    conditions={
      'tb_evento_corridas':'id_evento=36657',
      'tb_evento_corridas_percursos':'id_evento=36657',
      'tb_resultados':'id_evento=36657',
      'tb_resultados_temp':"id_evento='36657'",
      'tb_resultados_resumo':'id_evento=36657 OR tipo_corrida IS NULL',
      'tb_resultados_resumo_2025':'id_evento=36657',
      'tb_resultados_processa':"id_evento=36657 OR cod_evento='36657'",
      'tb_resultados_processa_logs':"id_evento=36657 OR cod_evento='36657'"}
    pieces=[]
    for table,condition in conditions.items():
        pieces.extend(["'"+table+"'", "coalesce((SELECT jsonb_agg(to_jsonb(t)) FROM "+table+" t WHERE "+condition+"),'[]'::jsonb)"])
    sql='SELECT jsonb_build_object('+','.join(pieces)+')::text AS payload'
    body='q=queryExecute('+json.dumps(sql)+',{},{timeout=25});report={payload=q.payload[1]};'
    result=bridge(body)
    payload=next(v for k,v in result.items() if k.lower()=='payload')
    data=json.loads(payload)
    assert set(data)==set(conditions)
    dest=stage/'database-before.json';dest.write_text(payload);os.chmod(dest,0o600)
    receipt={'backup':str(dest),'sha256':sha(dest),'rows':{k:len(v) for k,v in data.items()},'conditions':conditions}
    (stage/'database-manifest.json').write_text(json.dumps(receipt,indent=2))
    print(json.dumps(receipt))
elif mode == 'rebuild':
    assert (stage/'database-before.json').is_file(), 'Missing database backup'
    assert not (stage/'rebuild.json').exists(), 'Recovery was already attempted'
    manifest=json.loads((stage/'source-manifest.json').read_text())
    assert all(sha(root/k)==v['sha256'] for k,v in manifest.items())
    xml=ET.parse('/opt/coldfusion2025/cfusion/lib/neo-runtime.xml')
    trusted=[v for v in xml.iter('var') if v.get('name')=='trustedCacheEnabled']
    assert len(trusted)==1 and trusted[0].find('boolean').get('value')=='false', 'Trusted cache enabled; scoped admin invalidation required'
    bad=cache/'cfparse2ecfm2083463583$funcRACEZONEAWARDMODALITY.class'
    assert bad.is_file() and bad.stat().st_size==0
    assert (stage/'cache-before'/bad.name).is_file()
    # Discard only the proven empty generated file. The unchanged published CFML
    # source is invalidated by mtime, allowing ColdFusion's normal recompilation.
    bad.unlink()
    src=root/'api/racezone/parse.cfm'
    previous=src.stat()
    os.utime(src,ns=(previous.st_atime_ns,time.time_ns()))
    assert sha(src)==expected['api/racezone/parse.cfm']
    receipt={'removed_empty_class':bad.name,'source_content_preserved':True,'source_mtime_ns':src.stat().st_mtime_ns}
    (stage/'rebuild.json').write_text(json.dumps(receipt,indent=2))
    print(json.dumps(receipt))
elif mode == 'preflight':
    dest=stage/'event-form.html'
    response=subprocess.run(['curl','-sS','--max-time','40','--resolve','runnerhub.run:443:127.0.0.1',
      '-o',str(dest),'-w','%{http_code} %{time_total}','https://runnerhub.run/api/racezone/?id_evento=36657&auto=false'],capture_output=True,text=True,timeout=45)
    assert response.returncode==0, response.stderr
    assert response.stdout.startswith('200 '),response.stdout
    match=re.search(r'name="url_wiclax"\s+value="([^"]+)"',dest.read_text())
    assert match, 'Resolved source URL not found'
    url=html.unescape(match.group(1))
    assert re.fullmatch(r'https://resultados[.]racetag[.]com[.]br/mycrono/data/[^/]+/event[.]json',url),url
    docs={}
    for filename in ('event.json','results.json'):
        target=stage/filename
        r=subprocess.run(['curl','-sS','--max-time','35','-A','RunnerHub/1.0','-H','Accept: application/json',
          '-o',str(target),'-w','%{http_code} %{time_total}',url.replace('event.json',filename)],capture_output=True,text=True,timeout=40)
        assert r.returncode==0 and r.stdout.startswith('200 '),r.stderr+r.stdout
        os.chmod(target,0o600)
        docs[filename]=json.loads(target.read_text(encoding='utf-8-sig'))
    event=docs['event.json'];athletes=docs['results.json']
    assert isinstance(athletes,list) and isinstance(event.get('routes'),list)
    route_counts=[]
    for route in event['routes']:
        if 'd' not in route:continue
        selected=[a for a in athletes if str(a.get('r'))==str(route['i']) and str(a.get('s','')).strip().upper() not in ('DSQ','DNF')]
        route_counts.append({'name':route.get('n'),'distance_m':route.get('d'),'expected_import':len(selected)})
    receipt={'source_url':url,'name':event.get('name'),'source_athletes':len(athletes),'routes':route_counts,
      'expected_import':sum(x['expected_import'] for x in route_counts),'form_http':response.stdout}
    (stage/'preflight.json').write_text(json.dumps(receipt,indent=2))
    print(json.dumps(receipt))
elif mode == 'smoke':
    assert (stage/'rebuild.json').exists()
    log=Path('/opt/coldfusion2025/cfusion/logs/application.log')
    before=log.stat().st_size
    target=stage/'smoke.html'
    r=subprocess.run(['curl','-sS','--max-time','35','--resolve','runnerhub.run:443:127.0.0.1',
      '-o',str(target),'-w','%{http_code} %{time_total}',
      'https://runnerhub.run/api/racezone/parse.cfm'],capture_output=True,text=True,timeout=40)
    text=target.read_text(errors='replace') if target.exists() else ''
    classes=[{'name':p.name,'size':p.stat().st_size,'java_class':p.read_bytes()[:4]==bytes.fromhex('cafebabe')}
      for p in cache.glob('cfparse2ecfm2083463583*.class')]
    with log.open('rb') as f:f.seek(before);new=f.read().decode(errors='replace')
    receipt={'http':r.stdout,'returncode':r.returncode,'transport_error':r.stderr,
      'resolved_to_empty_input_message':'Não foi possível localizar o JSON da RaceZone' in text,
      'classes':classes,'new_importer_errors':[line[:500] for line in new.splitlines() if 'racezone/parse.cfm' in line],
      'source_hashes':{name:sha(root/name) for name in source_names}}
    (stage/'smoke.json').write_text(json.dumps(receipt,indent=2))
    print(json.dumps(receipt))
elif mode == 'import':
    smoke=json.loads((stage/'smoke.json').read_text())
    assert smoke['http'].startswith('200 ') and smoke['resolved_to_empty_input_message'] and not smoke['new_importer_errors']
    assert not (stage/'import-start.json').exists(), 'Import already dispatched; inspect outcome instead of repeating'
    prior=bridge("report={final_count=queryExecute('SELECT count(*) AS n FROM tb_resultados WHERE id_evento=36657',{},{timeout=5}).n[1],temp_count=queryExecute(\"SELECT count(*) AS n FROM tb_resultados_temp WHERE id_evento='36657'\",{},{timeout=5}).n[1]};")
    assert all(int(v)==0 for v in prior.values()), 'Event data changed since backup'
    preflight=json.loads((stage/'preflight.json').read_text())
    log=Path('/opt/coldfusion2025/cfusion/logs/application.log')
    before=log.stat().st_size
    started=datetime.now(timezone.utc).isoformat()
    start={'event_id':36657,'started_utc':started,'application_log_offset':before,'source_url':preflight['source_url']}
    (stage/'import-start.json').write_text(json.dumps(start,indent=2))
    argv=['curl','-sS','--max-time','590','--resolve','runnerhub.run:443:127.0.0.1',
      '-X','POST','--data-urlencode','id_evento=36657','--data-urlencode','url_wiclax='+preflight['source_url'],
      '-o',str(stage/'import-response.html'),'-w','%{http_code} %{time_total}',
      'https://runnerhub.run/api/racezone/parse.cfm']
    p=subprocess.Popen(argv,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    start['curl_pid']=p.pid
    start['curl_proc_stat']=Path('/proc/'+str(p.pid)+'/stat').read_text()
    (stage/'import-start.json').write_text(json.dumps(start,indent=2))
    try:
        out,err=p.communicate(timeout=600)
    except BaseException:
        p.terminate()
        try:p.communicate(timeout=5)
        except subprocess.TimeoutExpired:p.kill();p.communicate()
        raise
    finally:
        if p.poll() is not None:
            start['curl_exited']=True;start['curl_returncode']=p.returncode
            (stage/'import-start.json').write_text(json.dumps(start,indent=2))
    response=(stage/'import-response.html').read_text(errors='replace')
    os.chmod(stage/'import-response.html',0o600)
    with log.open('rb') as f:f.seek(before);new=f.read().decode(errors='replace')
    receipt={'event_id':36657,'http':out,'returncode':p.returncode,'transport_error':err,
      'step7_completed':'Passo 7: Resultados gerados e GAP geral atualizado em produção.' in response,
      'displayed_counts':re.findall(r'Registros (?:na importação|finais):\s*(\d+)',re.sub('<[^>]*>','',response)),
      'new_importer_errors':[line[:700] for line in new.splitlines() if 'racezone/parse.cfm' in line],
      'source_hashes':{name:sha(root/name) for name in source_names},'curl_exited':p.poll() is not None}
    (stage/'import.json').write_text(json.dumps(receipt,indent=2))
    print(json.dumps(receipt))
elif mode == 'verify':
    body=rows_fn()+"""report={
      event=rows(queryExecute("SELECT id_evento,nome_evento,tag,url_wiclax FROM tb_evento_corridas WHERE id_evento=36657",{},{timeout=10})),
      final=rows(queryExecute("SELECT modalidade,sexo,count(*) AS total,count(*) FILTER(WHERE concluinte AND status_final=0) AS finishers,count(*) FILTER(WHERE classificacao_sexo IS NOT NULL) AS sex_ranked,count(*) FILTER(WHERE classificacao_categoria IS NOT NULL) AS category_ranked FROM tb_resultados WHERE id_evento=36657 GROUP BY modalidade,sexo ORDER BY modalidade,sexo",{},{timeout=10})),
      counts=rows(queryExecute("SELECT (SELECT count(*) FROM tb_resultados WHERE id_evento=36657) AS final_count,(SELECT count(*) FROM tb_resultados_temp WHERE id_evento='36657') AS temp_count,(SELECT count(*) FROM tb_resultados_resumo WHERE id_evento=36657) AS summary_count,(SELECT count(*) FROM tb_resultados_resumo_2025 WHERE id_evento=36657) AS summary_2025_count",{},{timeout=10})),
      processing=rows(queryExecute("SELECT cod_evento,id_evento,data_processamento_inicial,data_processamento_final,chave_processamento,erro_execucao FROM tb_resultados_processa WHERE id_evento=36657 ORDER BY data_processamento_inicial DESC LIMIT 5",{},{timeout=10})),
      processing_errors=rows(queryExecute("SELECT erro_execucao,count(*) AS total FROM tb_resultados_processa_logs WHERE id_evento=36657 OR cod_evento='36657' GROUP BY erro_execucao",{},{timeout=10})),
      active=rows(queryExecute("SELECT state,wait_event_type,wait_event,count(*) AS n FROM pg_stat_activity WHERE pid<>pg_backend_pid() AND state<>'idle' AND query ILIKE '%36657%' GROUP BY state,wait_event_type,wait_event",{},{timeout=10})),
      results=rows(queryExecute("SELECT num_peito,modalidade,percurso,sexo,classificacao_sexo,classificacao_categoria,classificacao_total,tempo_total,status_final FROM tb_resultados WHERE id_evento=36657 ORDER BY id_resultado",{},{timeout=10}))};
    """
    result=bridge(body)
    dest=stage/('verification-'+str(time.time_ns())+'.json')
    dest.write_text(json.dumps(result,indent=2));os.chmod(dest,0o600)
    r={k.lower():v for k,v in result.items()}
    r.pop('results')
    manifest=json.loads((stage/'source-manifest.json').read_text())
    r['source_content_preserved']=all(sha(root/k)==v['sha256'] for k,v in manifest.items())
    cls=cache/'cfparse2ecfm2083463583$funcRACEZONEAWARDMODALITY.class'
    r['rebuilt_class']={'bytes':cls.stat().st_size,'valid_header':cls.read_bytes()[:4]==bytes.fromhex('cafebabe')}
    r['temporary_probe_directories']=[p.name for p in cfroot.glob('racezone-recovery-36657-*') if p.is_dir()]
    r['backup']=str(stage)
    print(json.dumps(r))
elif mode == 'final-check':
    latest=max(stage.glob('verification-*.json'),key=lambda p:p.stat().st_mtime_ns)
    data={k.lower():v for k,v in json.loads(latest.read_text()).items()}
    final=[{k.lower():v for k,v in row.items()} for row in data['results']]
    athletes=json.loads((stage/'results.json').read_text(encoding='utf-8-sig'))
    event=json.loads((stage/'event.json').read_text(encoding='utf-8-sig'))
    expected_rows=[]
    for route in event['routes']:
        if 'd' not in route:continue
        for a in athletes:
            if str(a.get('r'))==str(route['i']) and str(a.get('s','')).strip().upper() not in ('DSQ','DNF'):
                expected_rows.append((int(a['n']),round(float(route['d'])/1000)))
    actual_rows=[(int(a['num_peito']),round(float(a['percurso']))) for a in final]
    from collections import Counter
    missing=Counter(expected_rows)-Counter(actual_rows)
    extra=Counter(actual_rows)-Counter(expected_rows)
    public_url='https://openresults.run/evento/2026-feira-night-run-analise-2026/'
    checks=[]
    for label,args in [('origin',['--resolve','openresults.run:443:127.0.0.1']),('public',[])]:
        dest=stage/('public-'+label+'.html')
        r=subprocess.run(['curl','-sS','--max-time','40',*args,'-o',str(dest),'-w','%{http_code} %{time_total}',public_url],capture_output=True,text=True,timeout=45)
        text=dest.read_text(errors='replace') if dest.exists() else ''
        if dest.exists():os.chmod(dest,0o600)
        checks.append({'path':label,'http':r.stdout,'returncode':r.returncode,'has_event_name':'FEIRA NIGHT RUN' in text.upper(),
          'has_results':bool(re.search(r'1[.,]612|1612|1[.,]944|1944',re.sub('<[^>]*>',' ',text))),
          'has_error':bool(re.search(r'Bad Gateway|Internal Server Error|Error Occurred While Processing Request',text))})
    manifest=json.loads((stage/'source-manifest.json').read_text())
    # Correlate only request metadata; omit client addresses and user agents.
    requests=[]
    with Path('/var/log/apache2/access.log').open(errors='replace') as f:
        for line in f:
            if '[09/Nov/2026:14:18:' in line and 'POST /api/racezone/parse.cfm' in line:
                match=re.search(r'\[([^]]+)\] "([^\"]+)" (\d+) (\d+) "([^\"]+)"',line)
                if match:requests.append({'time_utc':match.group(1),'request':match.group(2),'http':match.group(3),'referer':match.group(5)})
    receipt={'event_id':36657,'source_athletes':len(athletes),'expected_import':len(expected_rows),'final_count':len(final),
      'missing_from_source':sum(missing.values()),'unexpected_final_rows':sum(extra.values()),'public_checks':checks,
      'processing_requests':requests,'source_content_preserved':all(sha(root/k)==v['sha256'] for k,v in manifest.items()),
      'temporary_probes_remaining':[p.name for p in cfroot.glob('racezone-recovery-36657-*') if p.is_dir()],
      'backup':str(stage),'public_url':public_url}
    (stage/'final-receipt.json').write_text(json.dumps(receipt,indent=2))
    print(json.dumps(receipt))
else:
    raise RuntimeError('Unknown mode')
'''

mode=sys.argv[1]
r=subprocess.run(SSH+['python3 -c '+shlex.quote(REMOTE)+' '+shlex.quote(mode)],
                 capture_output=True,text=True,timeout=650 if mode=='import' else 100)
if r.returncode:
    print(r.stderr[-4500:])
    raise SystemExit(r.returncode)
result=json.loads(r.stdout)
(HERE/(mode+'.json')).write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
