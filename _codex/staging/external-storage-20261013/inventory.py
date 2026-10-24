"""Read-only external-path inventory. Output paths/references, never full config lines."""
from pathlib import Path
import collections,json,os,re

roots=[Path('/var/www')]
skip={'.git','node_modules','vendor','_codex','backup','backups','.cache','assets','images','fonts','css','ckeditor','ckeditor5','bootstrap'}
extensions={'.cfm','.cfc','.json','.xml','.conf','.ini','.properties','.sh','.py','.js','.yml','.yaml','.env'}
paths=collections.defaultdict(list)
temp=collections.defaultdict(list)
symlinks=[]
pattern=re.compile(r'''(?<![A-Za-z0-9:/])/(?:var|opt|tmp|srv|mnt|home|data|etc|root|usr)/[A-Za-z0-9_./${}#@%+ -]+''')
for root in roots:
 for parent,dirs,files in os.walk(root,followlinks=False):
  dirs[:]=[d for d in dirs if d not in skip and not d.startswith('.codex')]
  for name in dirs+files:
   f=Path(parent)/name
   if f.is_symlink():
    dest=str(f.resolve())
    if not dest.startswith('/var/www/'):
     symlinks.append({'link':str(f),'target':dest,'exists':f.exists()})
  for name in files:
   f=Path(parent)/name
   if f.suffix.lower() not in extensions and name not in {'.env','.htaccess'}:continue
   if f.is_symlink():continue
   try:
    if f.stat().st_size>2_000_000:continue
    text=f.read_text(errors='replace')
   except OSError:continue
   for num,line in enumerate(text.splitlines(),1):
    ref=str(f)+':'+str(num)
    for m in pattern.finditer(line):
     p=m.group().strip()
     if not p.startswith('/var/www/'):
      paths[p].append(ref)
    if re.search(r'getTempDirectory\s*\(',line,re.I):
     temp[str(f).split('/')[3]].append(ref)
env_paths=[]
for proc in Path('/proc').glob('[0-9]*'):
 try:
  cmd=(proc/'cmdline').read_bytes()
  if b'cfusion' not in cmd or b'java' not in cmd:continue
  for e in (proc/'environ').read_bytes().split(b'\0'):
   key,sep,value=e.partition(b'=')
   v=value.decode(errors='replace')
   if sep and v.startswith(('/var/','/opt/','/tmp/','/srv/','/mnt/','/data/')) and not v.startswith('/var/www/'):
    env_paths.append({'name':key.decode(),'path':v,'exists':Path(v).exists()})
 except (OSError,ValueError):pass
out={'paths':[{'path':p,'exists':Path(p).exists(),'refs':refs[:6],'reference_count':len(refs)} for p,refs in sorted(paths.items())], 'temp_usage':{site:{'count':len(refs),'refs':refs[:8]} for site,refs in temp.items()},'external_symlinks':symlinks,'runtime_environment_paths':env_paths}
print(json.dumps(out,indent=2))
