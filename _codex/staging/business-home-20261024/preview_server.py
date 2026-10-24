from http.server import BaseHTTPRequestHandler,HTTPServer
from pathlib import Path
from urllib.parse import urlsplit
import html
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business')
STAGE=ROOT/'_codex/staging/business-home-20261024'
ALLOWED={'/assets/css/mdb.min.css','/assets/css/admin-suite.css','/assets/css/admin-dashboard.css','/assets/js/business-home-dashboard.js'}
class H(BaseHTTPRequestHandler):
 def do_GET(self):
  path=urlsplit(self.path).path
  if path in ALLOWED:
   raw=(ROOT/path[1:]).read_bytes();mime='text/css' if path.endswith('.css') else 'application/javascript'
  elif path in ['/desktop','/mobile','/']:
   view=(STAGE/'render/pending.html').read_text()
   head='<link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/admin-suite.css"><link rel="stylesheet" href="/assets/css/admin-dashboard.css">'
   page='<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'+head+'</head><body data-mdb-theme="dark" style="margin:0;background:#212121;padding:20px"><div class="container"><div class="row"><div class="col-12 business-global-dashboard admin-suite-page" data-business-home><header class="admin-suite-header"><div class="admin-suite-heading"><div class="admin-suite-heading-copy"><div class="admin-suite-kicker">Operação RunnerHub · Admin global</div><h1 class="admin-suite-title">Visão geral do Business</h1><p class="admin-suite-subtitle">O que está acontecendo e o que precisa da sua atenção.</p></div></div></header>'+view+'</div></div></div><script src="/assets/js/business-home-dashboard.js"></script></body></html>'
   width=390 if path=='/mobile' else 1280
   raw=('<!doctype html><html><head><title>Business real view fixture</title></head><body style="margin:0;background:#212121"><iframe title="Home Business" style="border:0;width:'+str(width)+'px;height:1800px" srcdoc="'+html.escape(page,quote=True)+'"></iframe></body></html>').encode();mime='text/html; charset=utf-8'
  else:self.send_error(404);return
  self.send_response(200);self.send_header('Content-Type',mime);self.end_headers();self.wfile.write(raw)
 def log_message(self,*args):pass
HTTPServer(('127.0.0.1',8875),H).serve_forever()
