"""Exercise real Adobe templates in an isolated, localhost-only fixture."""
import base64
import hashlib
from html import unescape
from html.parser import HTMLParser
import json
from pathlib import Path
import shlex
import subprocess
import sys

S = Path(__file__).resolve().parent
ROOT = S.parents[2]
MODE = sys.argv[1]
assert MODE in ('candidate', 'published')
baseline = json.loads((S/'baseline.json').read_text())
files = {n:(ROOT/n).read_text() for n in baseline['names']}
remote = '''from pathlib import Path
import base64,json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run')
work=Path(tempfile.mkdtemp(prefix='seo-domains-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
names=['portal/conteudo/seo.cfm','portal/conteudo/seo_report.cfm','portal/conteudo/seo_ai.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_data.cfm','portal/includes/seo_queue_data.cfm','includes/backend/require_admin.cfm','portal/includes/seo_search_evidence.cfm','portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_domains.cfm','portal/includes/seo_domains_data.cfm']
auth='<cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/>'+'<cfset VARIABLES.businessEffectiveIsAdmin=true/>'
try:
 for name in names:
  dest=work/name;dest.parent.mkdir(parents=True,exist_ok=True)
  if p['mode']=='candidate' and name in p['files']:dest.write_text(p['files'][name])
  else:shutil.copyfile(root/name,dest)
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 cases={'domains':'URL.aba="dominios";','domains-openresults':'URL.aba="dominios";URL.site="openresults";','domains-escaped':'URL.aba="dominios";URL.dominio_busca="<script>alert(1)</script>";','technical':'URL.aba="relatorio";','queue':'URL.aba="fila";','ai':'URL.aba="ia";','semrush':'URL.aba="semrush";','invalid':'URL.aba="bad";'}
 for name,setup in cases.items():
  (work/(name+'.cfm')).write_text('<cfsetting showdebugoutput="false"/><cfset setLocale("Portuguese (Brazilian)")/>'+auth+'<cfscript>'+setup+'</cfscript><cfinclude template="portal/conteudo/seo.cfm"/>')
 for kind,path in [('view','portal/conteudo/seo_domains.cfm'),('data','portal/includes/seo_domains_data.cfm')]:
  for name,prefix in [('anonymous',''),('delegated',auth+'<cfset VARIABLES.businessEffectiveIsAdmin=false/>'),('post',auth)]:
   (work/(name+'-'+kind+'.cfm')).write_text(prefix+'<cfinclude template="'+path+'"/>')
 result={}
 targets=list(cases)+[n+'-'+k for k in ['view','data'] for n in ['anonymous','delegated','post']]+['portal/conteudo/seo_domains','portal/includes/seo_domains_data']
 for name in targets:
  if name.startswith('portal/'):
   q=work/(name+'.cfm');q.write_text(auth+q.read_text())
  cp=subprocess.run(['curl','-sS','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-X','POST' if name.startswith('post-') else 'GET','-D','-','-w','\\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/'+name+'.cfm'],capture_output=True,text=True,timeout=50)
  if cp.returncode:raise RuntimeError('Request failed: '+name)
  full,status=cp.stdout.rsplit('\\n',1);headers,html=full.split('\\n\\n',1)
  result[name]={'status':int(status),'headers':headers,'html':base64.b64encode(html.encode()).decode()}
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
ssh = ['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp = subprocess.run(ssh+['python3 -c '+shlex.quote(remote)], input=json.dumps({'mode':MODE,'files':files}),capture_output=True,text=True,timeout=230)
assert cp.returncode == 0, cp.stderr[-3000:]
result = json.loads(cp.stdout)
html = {n:base64.b64decode(r['html']).decode() for n,r in result.items()}
for name in ['domains','domains-openresults','domains-escaped','technical','queue','ai','semrush','invalid']:
    if result[name]['status'] != 200:
        (S/(MODE+'-failed.html')).write_text(html[name])
        raise AssertionError((name,result[name]['status'],unescape(html[name])[-2500:]))
    assert 'Error Occurred While Processing Request' not in html[name], name

class TableParser(HTMLParser):
    def __init__(self): super().__init__(); self.rows=[]; self.current=None
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if tag=='tr' and 'data-domain-row' in a:
            self.current={'domain':a['data-domain'],'own':a['data-own'],'metrics':{}};self.rows.append(self.current)
        if tag=='td' and 'data-metric' in a and self.current:
            self.current['metrics'][a['data-metric']]={'value':a['data-value'],'change':a['data-change']}

source=json.loads((ROOT/'_codex/analyses/seo_domains/2026-10-25T150300-0300.json').read_text())
(S/(MODE+'-preview.html')).write_text(html['domains'])
parser=TableParser();parser.feed(html['domains'])
assert len(parser.rows)==source['count']==27
assert [r['domain'] for r in parser.rows]==[r['domain'] for r in source['domains']]
for actual,expected in zip(parser.rows,source['domains']):
    assert (actual['own']=='true') == expected['own']
    for key,metric in expected['metrics'].items():
        assert float(actual['metrics'][key]['value'])==metric['value'],(actual['domain'],key)
        assert float(actual['metrics'][key]['change'])==metric['change'],(actual['domain'],key)
assert '17º' in html['domains'] and '22º' in html['domains'] and '3.200' in html['domains'] and '1.300' in html['domains']
assert '25/10/2026 às 15:03 (Brasília)' in unescape(html['domains'])
assert 'data-value="764"' in html['domains']
assert html['domains'].count('class="sd-row-own"')==2
assert 'aria-current="page">Domínios' in unescape(html['domains'])
assert 'data-domains-dashboard' not in html['technical']
assert 'data-domains-dashboard' not in html['semrush']
assert 'data-domains-dashboard' not in html['invalid']
assert html['domains-openresults'].count('data-domain-row')==27
assert '<script>alert(1)</script>' not in html['domains-escaped']
for kind in ['view','data']:
    for prefix in ['anonymous','delegated']:
        case=prefix+'-'+kind
        assert result[case]['status']==403 and 'data-domains-dashboard' not in html[case] and 'binaryDecode' not in html[case]
    case='post-'+kind
    assert result[case]['status']==405 and 'Allow: GET'.lower() in result[case]['headers'].lower()
for name in ['portal/conteudo/seo_domains','portal/includes/seo_domains_data']:
    assert result[name]['status']==403
(S/(MODE+'-preview.html')).write_text(html['domains'])
receipt={'mode':MODE,'scenarios':len(result),'accessChecks':8,'domains':27,'metricCellsVerified':162,'hashes':{n:hashlib.sha256(content.encode()).hexdigest() for n,content in files.items()}}
(S/(MODE+'-verified.json')).write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({k:v for k,v in receipt.items() if k!='hashes'}))
