from pathlib import Path
import base64,json,shlex,subprocess
helper=Path(__file__).with_name('runnerhub-telemetry-acl').read_bytes()
script=r'''
from pathlib import Path
import base64,ctypes,hashlib,json,os,pwd,shutil,subprocess,tempfile
b=Path('/var/backups/external-storage-20261013/telemetry');b.mkdir(mode=0o700)
cfg=Path('/etc/logrotate.d/apache2');before=cfg.read_bytes()
helper=base64.b64decode(PAYLOAD)
dst=Path('/usr/local/sbin/runnerhub-telemetry-acl');assert not dst.exists()
assert before.count(b'\tpostrotate\n')==1
lib=ctypes.CDLL('libacl.so.1',use_errno=True)
lib.acl_get_file.argtypes=[ctypes.c_char_p,ctypes.c_int];lib.acl_get_file.restype=ctypes.c_void_p
lib.acl_to_text.argtypes=[ctypes.c_void_p,ctypes.c_void_p];lib.acl_to_text.restype=ctypes.c_void_p
lib.acl_free.argtypes=[ctypes.c_void_p]
def get_acl(p):
 a=lib.acl_get_file(os.fsencode(p),0x8000);assert a
 t=lib.acl_to_text(a,None);assert t
 try:return ctypes.string_at(t).decode()
 finally:lib.acl_free(t);lib.acl_free(a)
paths=['/var/log/apache2','/var/log/apache2/api.roadrunners.run-telemetry.log']
baseline={p:get_acl(p) for p in paths}
assert baseline[paths[0]].strip()=='user::rwx\ngroup::r-x\nother::---',baseline[paths[0]]
assert baseline[paths[1]].strip()=='user::rw-\ngroup::r--\nother::---',baseline[paths[1]]
(b/'acl-before.json').write_text(json.dumps(baseline,indent=2));(b/'apache2.before').write_bytes(before)
candidate=before.replace(b'\tpostrotate\n',b'\tpostrotate\n\t\t/usr/local/sbin/runnerhub-telemetry-acl\n')
(b/'apache2.candidate').write_bytes(candidate)
check=subprocess.run(['logrotate','--debug',str(b/'apache2.candidate')],capture_output=True,text=True)
(b/'logrotate-candidate-check.txt').write_text(check.stderr)
assert check.returncode==0
scope={'__name__':'acl_test'};exec(compile(helper,'telemetry-helper','exec'),scope)
uid=pwd.getpwnam('coldfusion').pw_uid
fixture=Path(tempfile.mkdtemp(prefix='telemetry-acl-test-',dir='/tmp'));os.chmod(fixture,0o755)
try:
 d=fixture/'logs';d.mkdir(mode=0o750)
 log=d/'telemetry.log';log.write_text('synthetic');os.chmod(log,0o640)
 other=d/'other.log';other.write_text('private');os.chmod(other,0o640)
 def probe(expected):
  code="import os; from pathlib import Path; p="+repr(str(log))+"; other="+repr(str(other))+"; assert os.access(p,os.R_OK)=="+repr(expected)+"; assert not os.access(p,os.W_OK); assert not os.access(other,os.R_OK)"
  subprocess.run(['runuser','-u','coldfusion','--','python3','-c',code],check=True)
 probe(False)
 scope['apply_acl'](str(d),f'user::rwx,user:{uid}:--x,group::r-x,mask::r-x,other::---')
 scope['apply_acl'](str(log),f'user::rw-,user:{uid}:r--,group::r--,mask::r--,other::---');probe(True)
 log.rename(d/'telemetry.log.1');log.write_text('new synthetic');os.chmod(log,0o640);probe(False)
 scope['apply_acl'](str(log),f'user::rw-,user:{uid}:r--,group::r--,mask::r--,other::---');probe(True)
finally:shutil.rmtree(fixture)
assert cfg.read_bytes()==before
dst.write_bytes(helper);os.chmod(dst,0o755)
tmp=cfg.with_name('.apache2.telemetry-new');tmp.write_bytes(candidate);os.chmod(tmp,0o644);tmp.replace(cfg)
subprocess.run([str(dst)],check=True)
verify=subprocess.run(['logrotate','--debug','/etc/logrotate.conf'],capture_output=True,text=True)
(b/'logrotate-full-check.txt').write_text(verify.stderr);assert verify.returncode==0
code="import os; p='/var/log/apache2/api.roadrunners.run-telemetry.log'; assert os.access(p,os.R_OK); assert not os.access(p,os.W_OK); open(p,'rb').read(1); assert not os.access('/var/log/apache2/error.log',os.R_OK); print('telemetry_only_read_ok')"
read_check=subprocess.check_output(['runuser','-u','coldfusion','--','python3','-c',code],text=True).strip()
report={'backup':str(b),'helper':str(dst),'logrotate_check':True,'simulated_rotation_check':True,'runtime_read_check':read_check,'after_acl':{p:get_acl(p) for p in paths}}
(b/'result.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
'''.replace('PAYLOAD',repr(base64.b64encode(helper).decode()))
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(script)],capture_output=True,text=True,timeout=55)
if r.returncode:raise RuntimeError(r.stderr)
Path(__file__).with_name('telemetry-result.json').write_text(r.stdout)
print(r.stdout)
