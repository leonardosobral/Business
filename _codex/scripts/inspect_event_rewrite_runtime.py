"""Read-only verification of published validation; no credentials or provider calls."""
import json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
REMOTE=r'''
import json,os,pathlib,re,secrets,subprocess,sys,tempfile
payload=json.load(sys.stdin)
stage=pathlib.Path(tempfile.mkdtemp(prefix='rewrite_inspect_',dir='/var/www/business.roadrunners.run/_codex'));os.chmod(stage,0o755)
archive=pathlib.Path(tempfile.mkdtemp(prefix='rewrite-runtime-inspect-',dir='/var/backups'));os.chmod(archive,0o700)
nonce=secrets.token_hex(24)
def norm(value):
    if isinstance(value,dict):return {key.lower():norm(item) for key,item in value.items()}
    if isinstance(value,list):return [norm(item) for item in value]
    return value
try:
    (stage/'.htaccess').write_text('Require local\n')
    (stage/'run.cfm').write_text(payload['probe'].replace('@@NONCE@@',nonce),encoding='utf-8-sig')
    for item in stage.iterdir():os.chmod(item,0o644)
    proc=subprocess.run(['curl','--silent','--show-error','--max-time','35','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Rewrite-Inspect: '+nonce,'https://business.roadrunners.run/_codex/'+stage.name+'/run.cfm'],capture_output=True,timeout=40)
    try:result=norm(json.loads(proc.stdout))
    except Exception:result={'ok':False,'error':'Runtime did not return safe JSON'}
    (archive/'evidence.json').write_text(json.dumps(result));os.chmod(archive/'evidence.json',0o600)
    summary={key:value for key,value in result.items() if key!='events'}
    summary['events']=[]
    for event in result.get('events',[]):
        clean={key:value for key,value in event.items() if key not in ['original','normalized','published']}
        text=event.get('normalized','')
        clean['normalized_length']=len(text)
        if event['id'] in [48090,48091]:
            clean['source_excerpt']=text[:1600]
            clean['published_excerpt']=event.get('published','')[:1000]
            clean['source_numbers']=re.findall(r'[0-9]+(?:[.,][0-9]+)*',text)
            clean['source_urls']=re.findall(r'https?://[^\s<>]+',text)
        summary['events'].append(clean)
finally:
    stage.rename(archive/'diagnostic')
    summary['archive']=str(archive)
    summary['diagnostic_archived']=not stage.exists()
print(json.dumps(summary))
'''
payload={'probe':(ROOT/'_codex/tests/event-description-rewrite/runtime-inspect.cfm').read_text()}
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=55)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'Read-only inspection failed','exit_code':proc.returncode,'diagnostic':proc.stderr.decode(errors='replace')[-700:]}
print(json.dumps(result,ensure_ascii=False))
if proc.returncode or not result.get('ok'):sys.exit(1)
