from http.server import HTTPServer,BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlsplit
import mimetypes
stage=Path(__file__).resolve().parent
class Preview(BaseHTTPRequestHandler):
 def do_GET(self):
  name=urlsplit(self.path).path
  if name=='/':target=stage/'tests/candidate-render.html'
  elif name.startswith('/assets/'):
   target=(stage/'candidate'/name.lstrip('/')).resolve()
   if not target.is_relative_to(stage/'candidate'):self.send_error(404);return
  else:target=None
  if target and target.is_file():
   data=target.read_bytes();self.send_response(200);self.send_header('Content-Type',mimetypes.guess_type(str(target))[0] or 'text/html');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
  else:
   self.send_response(302);self.send_header('Location','https://openresults.run'+self.path);self.end_headers()
 def log_message(self,*args):pass
server=HTTPServer(('127.0.0.1',0),Preview)
print(server.server_port,flush=True);server.serve_forever()
