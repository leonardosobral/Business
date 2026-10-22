"""Install the user-provided Geoapify key privately; never print secret material."""
import hashlib, json, pathlib, re, shlex, subprocess, sys

source = pathlib.Path(sys.argv[1])
raw = source.read_text().strip()
if not re.fullmatch(r'[A-Za-z0-9_-]{16,128}', raw):
    raise SystemExit('O arquivo não contém uma chave Geoapify válida; conteúdo omitido.')
if not (raw.startswith('8ddb7521') and raw.endswith('f370')):
    raise SystemExit('A identificação da chave não corresponde à chave conferida no navegador; nenhuma alteração.')
REMOTE = r'''
import hashlib,json,os,pathlib,re,stat,sys,tempfile
payload=json.load(sys.stdin);key=payload['key']
target=pathlib.Path('/var/www/business.roadrunners.run/config/business.local.cfm')
def sha(raw):return hashlib.sha256(raw).hexdigest()
if target.is_symlink():raise SystemExit('Unsafe private configuration target')
before=target.read_bytes();info=target.stat();text=before.decode('utf-8-sig')
if re.search(r'geoapifyApiKey',text,re.I):
 if key not in text:raise SystemExit('Existing Geoapify configuration differs; no changes')
 print(json.dumps({'ok':True,'already_configured':True,'fingerprint':sha(key.encode()),'key_printed':False}));sys.exit(0)
candidate=before+b'\n<cfscript>businessLocalConfig.geoapifyApiKey="'+key.encode()+b'";</cfscript>\n'
backup=pathlib.Path(tempfile.mkdtemp(prefix='business-geo-key-20261017-',dir='/var/backups'));os.chmod(backup,0o700)
saved=backup/'business.local.cfm.before';saved.write_bytes(before);os.chmod(saved,0o600)
if target.read_bytes()!=before:raise SystemExit('Private configuration changed concurrently; no publication')
fd,tmp=tempfile.mkstemp(prefix='.geo-key-',suffix='.cfm',dir=target.parent)
with os.fdopen(fd,'wb') as stream:
 stream.write(candidate);stream.flush();os.fsync(stream.fileno());os.fchmod(stream.fileno(),stat.S_IMODE(info.st_mode));os.fchown(stream.fileno(),info.st_uid,info.st_gid)
os.replace(tmp,target)
if target.read_bytes()!=candidate:raise SystemExit('Private key publication verification failed')
print(json.dumps({'ok':True,'backup':str(backup),'before':sha(before),'after':sha(candidate),'fingerprint':sha(key.encode()),'key_printed':False,'other_integrations_changed':False,'restart_required':False}))
'''
proc = subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'key':raw}).encode(),capture_output=True,timeout=30)
try:
    result=json.loads(proc.stdout)
except Exception:
    result={'ok':False,'error':'Configuração privada não confirmada; conteúdo da saída omitido.'}
if result.get('ok'):
    receipt=pathlib.Path(__file__).resolve().parents[2]/'_codex/deploy/geocoding-key-20261017.json'
    receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if proc.returncode or not result.get('ok'):sys.exit(1)
