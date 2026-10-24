from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import html
import re

ROOT = Path(__file__).resolve().parents[3]
STAGE = Path(__file__).resolve().parent
ALLOWED = {'assets/css/mdb.min.css', 'assets/css/style.css', 'assets/css/admin-suite.css',
           'assets/css/admin-dashboard.css', 'assets/css/business-shell.css', 'assets/js/business-shell.js'}

def fixture(kind, baseline=False, nojs=False):
    source = (STAGE / 'baseline/includes/estrutura/header.cfm' if baseline else ROOT / 'includes/estrutura/header.cfm').read_text()
    start = source.find('<link rel=')
    source = source[start if start >= 0 else source.index('<header') :]
    nav = '<nav id="main-navbar" class="navbar fixed-top" style="height:58.59375px;background:#333;color:white">Conta ativa · Todas as contas</nav>'
    if baseline:
        nav += '<p><a href="#">Escolher conta e forma de acesso</a></p>'
    source = re.sub(r'<cfinclude[^>]*sidenav.cfm[^>]*>', '', source)
    source = re.sub(r'<cfinclude[^>]*navbar.cfm[^>]*>', nav, source)
    if nojs:
        source = re.sub(r'<script[^>]*>[\s\S]*?</script>', '', source)
    card = '<header class="admin-suite-header" data-first><h1>Visão geral do Business</h1></header>'
    variants = {
      'home': '<main style="margin-top:-55px"><div class="container"><div class="row g-3"><div class="col-12 business-global-dashboard admin-suite-page">'+card+'</div></div></div></main>',
      'suite': '<main class="admin-suite-main admin-suite-page container-fluid">'+card+'</main>',
      'kanban': '<main class="admin-suite-main"><div class="container-fluid"><div class="admin-suite-page">'+card+'</div></div></main>',
      'legacy': '<main style="margin-top:-80px"><div class="container">'+card+'</div></main>',
      'crm': '<main class="crm-app container-fluid" style="padding-top:24px"><header class="crm-heading" style="margin-top:16px" data-first>CRM interno</header></main>',
      'standalone': '<main style="margin-top:32px"><h1 data-first>Seleção de conta</h1></main>'
    }
    if kind == 'standalone':
        source = '<link rel="stylesheet" href="/assets/css/business-shell.css">'
    css = ''.join('<link rel="stylesheet" href="/'+p+'">' for p in ['assets/css/mdb.min.css','assets/css/style.css','assets/css/admin-suite.css','assets/css/admin-dashboard.css'])
    return '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">'+css+'<style>body{background:#222;color:white}h1{font-size:24px}body.crm-workspace>header>section>.p-5{height:72px!important;padding:0!important}.fixture-controls{margin:50px 20px}main{min-height:400px}</style></head><body class="'+('crm-workspace' if kind == 'crm' else '')+'">'+source+variants[kind]+'<button class="fixture-controls" onclick="document.getElementById(\'main-navbar\').style.height=\'96px\'">Aumentar altura da barra</button></body></html>'

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def do_GET(self):
        url = urlparse(self.path)
        q = parse_qs(url.query)
        if url.path == '/fixture':
            data = fixture(q.get('kind',['home'])[0], 'baseline' in q, 'nojs' in q).encode()
            mime='text/html'
        elif url.path == '/':
            cases=[]
            for width in [1280,390]:
                for kind in ['home','suite','kanban','legacy','crm','standalone']:
                    opts='&baseline=1' if 'baseline' in q else ''
                    cases.append(f'<h2>{kind} · {width}px</h2><iframe title="{kind}-{width}" src="/fixture?kind={kind}{opts}" style="width:{width}px;height:250px;border:1px solid #777"></iframe>')
            measure = '''<script>window.addEventListener('load',()=>{const rows=[...document.querySelectorAll('iframe')].map(frame=>{const d=frame.contentDocument,n=d.querySelector('#main-navbar'),f=d.querySelector('[data-first]'),b=n?n.getBoundingClientRect().bottom:0;return {case:frame.title,navbarBottom:b,contentTop:f.getBoundingClientRect().top,gap:f.getBoundingClientRect().top-b};});document.getElementById('geometry').textContent=JSON.stringify(rows,null,2);});</script>'''
            data=('<!doctype html><html><body style="background:#eee"><pre id="geometry">Medindo…</pre>'+''.join(cases)+measure+'</body></html>').encode()
            mime='text/html'
        elif url.path.lstrip('/') in ALLOWED and (ROOT/url.path.lstrip('/')).exists():
            data=(ROOT/url.path.lstrip('/')).read_bytes()
            mime='text/css' if url.path.endswith('.css') else 'text/javascript'
        else:
            self.send_error(404); return
        self.send_response(200); self.send_header('Content-Type', mime+'; charset=utf-8'); self.send_header('Cache-Control','no-store'); self.end_headers(); self.wfile.write(data)

HTTPServer(('127.0.0.1',8876),Handler).serve_forever()
