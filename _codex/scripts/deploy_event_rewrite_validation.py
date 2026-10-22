"""Publish only the two approved runtime files, with strict baseline and backup."""
import hashlib,json,pathlib,shlex,subprocess,sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
BASELINES={
    'services/EventDescriptionRewriteService.cfc':'0f1be9c63014d85083cf0bb99e42431fd72706cc49d5b25dccc26f0435b54449',
    'api/eventos/jobs/rewrite-descriptions.cfm':'3da019d6c1da9ef8a8f1d84e51106f3971d4ec63d91acd3bf6586c0d42723412'
}
REMOTE=r'''
import hashlib,json,os,pathlib,stat,subprocess,sys,tempfile
payload=json.load(sys.stdin)
root=pathlib.Path('/var/www/business.roadrunners.run')
def sha(raw):return hashlib.sha256(raw).hexdigest()
def atomic(target,raw,meta):
    fd,path=tempfile.mkstemp(prefix='.rewrite-validation-',suffix=target.suffix,dir=target.parent)
    with os.fdopen(fd,'wb') as stream:
        stream.write(raw);stream.flush();os.fsync(stream.fileno())
        os.fchmod(stream.fileno(),meta['mode']);os.fchown(stream.fileno(),meta['uid'],meta['gid'])
    os.replace(path,target)
backup=None
installed=[]
try:
    # Validate all targets before touching any runtime file.
    state={}
    for relative,item in payload.items():
        target=root/relative
        info=target.lstat()
        if not stat.S_ISREG(info.st_mode) or target.is_symlink():raise RuntimeError('Unsafe runtime target')
        before=target.read_bytes();after=item['content'].encode()
        if sha(before)!=item['baseline']:raise RuntimeError('Production baseline conflict: '+relative)
        state[relative]={'before':sha(before),'after':sha(after),'mode':stat.S_IMODE(info.st_mode),'uid':info.st_uid,'gid':info.st_gid}
    backup=pathlib.Path(tempfile.mkdtemp(prefix='business-rewrite-validation-20261015-',dir='/var/backups'));os.chmod(backup,0o700)
    for relative,item in payload.items():
        name=pathlib.Path(relative).name
        for suffix,raw in [('before',(root/relative).read_bytes()),('candidate',item['content'].encode())]:
            file=backup/(name+'.'+suffix);file.write_bytes(raw);os.chmod(file,0o600)
    (backup/'manifest.json').write_text(json.dumps(state));os.chmod(backup/'manifest.json',0o600)
    for relative,item in payload.items():
        target=root/relative
        if sha(target.read_bytes())!=state[relative]['before']:raise RuntimeError('Production changed during publication')
        atomic(target,item['content'].encode(),state[relative]);installed.append(relative)
    proc=subprocess.run(['curl','--silent','--show-error','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','--write-out','\n%{http_code}','https://business.roadrunners.run/api/event-description-rewrite.cfm'],capture_output=True,timeout=30)
    body,status_code=proc.stdout.rsplit(b'\n',1)
    reply={key.lower():value for key,value in json.loads(body).items()}
    if proc.returncode or status_code!=b'405' or reply.get('status')!='method_not_allowed':raise RuntimeError('Published endpoint verification failed')
    for relative in payload:
        if sha((root/relative).read_bytes())!=state[relative]['after']:raise RuntimeError('Published checksum mismatch')
    result={'ok':True,'backup':str(backup),'files':state,'runtime_get_status':405,'runtime_reply':reply,'credentials_changed':False,'schedule_changed':False,'data_changed':False}
except Exception as failure:
    restored=[]
    if backup:
        for relative in reversed(installed):
            target=root/relative
            if sha(target.read_bytes())==state[relative]['after']:
                atomic(target,(backup/(pathlib.Path(relative).name+'.before')).read_bytes(),state[relative]);restored.append(relative)
    result={'ok':False,'safe_error':str(failure) if isinstance(failure,RuntimeError) else 'Publication failed; inspect private backup','backup':str(backup) if backup else None,'restored':restored}
print(json.dumps(result))
if not result['ok']:sys.exit(1)
'''
payload={path:{'baseline':baseline,'content':(ROOT/path).read_text()} for path,baseline in BASELINES.items()}
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=50)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'Publication transport failed; output suppressed'}
print(json.dumps(result,ensure_ascii=False))
if proc.returncode or not result.get('ok'):sys.exit(1)
