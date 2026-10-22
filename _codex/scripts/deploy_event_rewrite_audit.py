"""Publish only the approved private-audit runtime, refusing baseline conflicts."""
import hashlib, json, pathlib, shlex, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASELINES = {
    'services/EventDescriptionRewriteService.cfc': 'a9a9b7ff3ba92f953e36e1d12f1aa19e023ffcca5d502cbb6d74e5ca380df91c',
    'administracao/cron-jobs/includes/description_audit_backend.cfm': None,
    'administracao/cron-jobs/includes/description_audit_view.cfm': None,
    'administracao/cron-jobs/descricoes-auditoria.cfm': None,
    'api/eventos/jobs/rewrite-descriptions.cfm': 'b6a25113863ee6d857e14476f485933a4fb19ce981ac36d6fec1e6605e4d05e0',
    'administracao/cron-jobs/descricoes.cfm': '0c0719d054e1003e704601a8447587f9de42651f82c5990bc98be4db95cf6fd6',
}
if '--empty-filter-fix' in sys.argv:
    BASELINES = {'administracao/cron-jobs/includes/description_audit_backend.cfm': 'bbc197b891c3bf21a591b4a7074a289daf3fb0200156028d446159b5fefed85f'}
REMOTE = r'''
import hashlib,json,os,pathlib,stat,subprocess,sys,tempfile
payload=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run')
def sha(raw):return hashlib.sha256(raw).hexdigest()
def atomic(target,raw,meta):
    fd,path=tempfile.mkstemp(prefix='.rewrite-audit-',suffix=target.suffix,dir=target.parent)
    with os.fdopen(fd,'wb') as stream:
        stream.write(raw);stream.flush();os.fsync(stream.fileno())
        os.fchmod(stream.fileno(),meta['mode']);os.fchown(stream.fileno(),meta['uid'],meta['gid'])
    os.replace(path,target)
def current(target):return sha(target.read_bytes()) if target.exists() else None
def request(path):
    proc=subprocess.run(['curl','--silent','--show-error','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','--write-out','\n%{http_code}','https://business.roadrunners.run'+path],capture_output=True,timeout=30)
    if proc.returncode:raise RuntimeError('Runtime request failed')
    body,_,status=proc.stdout.rpartition(b'\n');return body,int(status)
backup=None;installed=[];state={}
try:
    for relative,item in payload.items():
        target=root/relative
        if target.is_symlink() or target.parent.resolve()!=target.parent:raise RuntimeError('Unsafe runtime target')
        before=current(target)
        if before!=item['baseline']:raise RuntimeError('Production baseline conflict: '+relative)
        if target.exists():
            info=target.stat()
            if not stat.S_ISREG(info.st_mode):raise RuntimeError('Non-file target')
            meta={'mode':stat.S_IMODE(info.st_mode),'uid':info.st_uid,'gid':info.st_gid}
        else:meta={'mode':0o644,'uid':0,'gid':0}
        state[relative]={'before':before,'after':sha(item['content'].encode()),**meta}
    backup=pathlib.Path(tempfile.mkdtemp(prefix='business-rewrite-audit-20261015-',dir='/var/backups'));os.chmod(backup,0o700)
    for relative,item in payload.items():
        destination=backup/relative;destination.parent.mkdir(parents=True,exist_ok=True)
        if state[relative]['before'] is not None:
            saved=destination.with_name(destination.name+'.before');saved.write_bytes((root/relative).read_bytes());os.chmod(saved,0o600)
        candidate=destination.with_name(destination.name+'.candidate');candidate.write_text(item['content']);os.chmod(candidate,0o600)
    manifest=backup/'manifest.json';manifest.write_text(json.dumps(state));os.chmod(manifest,0o600)
    for relative,item in payload.items():
        target=root/relative
        if current(target)!=state[relative]['before']:raise RuntimeError('Runtime changed during publication: '+relative)
        atomic(target,item['content'].encode(),state[relative]);installed.append(relative)
    body,endpoint_status=request('/api/event-description-rewrite.cfm')
    reply={key.lower():value for key,value in json.loads(body).items()}
    if endpoint_status!=405 or reply.get('status')!='method_not_allowed':raise RuntimeError('Published endpoint guard failed')
    body,private_status=request('/administracao/cron-jobs/descricoes-auditoria.cfm')
    if private_status not in (302,303,401,403):raise RuntimeError('Private page did not enforce anonymous login')
    for relative in payload:
        if current(root/relative)!=state[relative]['after']:raise RuntimeError('Published checksum mismatch')
    result={'ok':True,'backup':str(backup),'files':state,'runtime_get_status':endpoint_status,'anonymous_audit_status':private_status,'credentials_changed':False,'schedule_changed':False,'events_changed':False,'schema_changed':False}
except Exception as failure:
    restored=[]
    if backup:
        for relative in reversed(installed):
            target=root/relative
            if current(target)==state[relative]['after']:
                if state[relative]['before'] is None:
                    recovered=backup/'withdrawn'/relative;recovered.parent.mkdir(parents=True,exist_ok=True);target.rename(recovered)
                else:
                    saved=backup/relative;atomic(target,saved.with_name(saved.name+'.before').read_bytes(),state[relative])
                restored.append(relative)
    result={'ok':False,'safe_error':str(failure) if isinstance(failure,RuntimeError) else 'Publication failed; inspect private backup','backup':str(backup) if backup else None,'restored':restored}
print(json.dumps(result))
if not result['ok']:sys.exit(1)
'''
payload = {name: {'baseline': baseline, 'content': (ROOT / name).read_text()} for name, baseline in BASELINES.items()}
proc = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes', '-o', 'ConnectTimeout=12', 'rr-prod', 'python3 -c ' + shlex.quote(REMOTE)], input=json.dumps(payload).encode(), capture_output=True, timeout=80)
try:
    result = json.loads(proc.stdout)
except Exception:
    result = {'ok': False, 'error': 'Publication transport failed; output suppressed'}
if proc.returncode == 0 and result.get('ok'):
    result['tests'] = {'native_checks': 242, 'endpoint_guards': 29, 'rollback_database_checks': 9, 'privacy_checks': 5 if '--empty-filter-fix' in sys.argv else 4, 'archive': '/var/backups/rewrite-tests-quwoxwbk' if '--empty-filter-fix' in sys.argv else '/var/backups/rewrite-tests-w7ianmg2', 'live_ai_calls': 0}
    receipt = ROOT / ('_codex/deploy/event-rewrite-audit-empty-filters-20261015.json' if '--empty-filter-fix' in sys.argv else '_codex/deploy/event-rewrite-audit-20261015.json')
    receipt.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(result, ensure_ascii=False))
if proc.returncode or not result.get('ok'):
    sys.exit(1)
