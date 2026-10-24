from pathlib import Path
import base64, hashlib, json, shlex, subprocess

S = Path(__file__).resolve().parent
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']
names = {
    'or': ['includes/menu_apps.cfm', 'includes/seo-web-tools-body-end.cfm', 'includes/header.cfm', 'includes/head.cfm', 'estado/index.cfm', 'robots.txt'],
    'rr': ['includes/estrutura/event_title_date.cfm', 'evento/index.cfm'],
}
remote = '''
from pathlib import Path
import base64, hashlib, json, sys, urllib.request, urllib.error
p = json.load(sys.stdin)
roots = {'or': Path('/var/www/openresults.run'), 'rr': Path('/var/www/roadrunners.com.br')}
r = {'files': {}, 'http': []}
for site, names in p.items():
    r['files'][site] = {}
    for name in names:
        path = roots[site] / name
        b = path.read_bytes()
        r['files'][site][name] = {'sha256': hashlib.sha256(b).hexdigest(), 'content': base64.b64encode(b).decode(), 'mode': path.stat().st_mode & 0o777, 'uid': path.stat().st_uid, 'gid': path.stat().st_gid}
for host, path in [('openresults.run','/'), ('openresults.run','/assets/js/runner-apps-menu-lazy.min.js?v=20261008seo'), ('openresults.run','/estado/RJ/'), ('openresults.run','/estado/rj/')]:
    req = urllib.request.Request('http://127.0.0.1'+path, headers={'Host': host, 'User-Agent':'RunnerHub-SEO/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=45) as response:
            body = response.read(2500000)
            r['http'].append({'host':host,'path':path,'status':response.status,'type':response.headers.get('Content-Type'), 'body':base64.b64encode(body).decode()})
    except urllib.error.HTTPError as e:
        r['http'].append({'host':host,'path':path,'status':e.code,'type':e.headers.get('Content-Type')})
print(json.dumps(r))
'''
cp = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], input=json.dumps(names), capture_output=True, text=True, timeout=210)
if cp.returncode:
    raise RuntimeError(cp.stderr[-2500:])
r = json.loads(cp.stdout)
summary = {}
for site, files in r['files'].items():
    root = Path('/Users/Shared/Projects/RunnerHub') / ('OpenResults' if site == 'or' else 'RoadRunners')
    summary[site] = {}
    for name, value in files.items():
        b = base64.b64decode(value.pop('content'))
        path = S / 'origin' / site / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b)
        summary[site][name] = {'same_local': (root/name).read_bytes() == b, 'sha256': value['sha256']}
for i, item in enumerate(r['http']):
    if 'body' in item:
        (S/f'origin-http-{i}.body').write_bytes(base64.b64decode(item.pop('body')))
(S/'inspection.json').write_text(json.dumps(r, indent=2))
print(json.dumps({'files':summary,'http':r['http']},indent=2))
