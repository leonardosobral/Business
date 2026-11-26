from pathlib import Path
import http.server,json,os,signal,tempfile,shutil,time
ROOT=Path(__file__).resolve().parents[2];stage=ROOT/'_codex/staging/verified-origins-20261123';work=Path(tempfile.mkdtemp(prefix='business-verified-preview-'))
def stop(signum,frame):raise KeyboardInterrupt()
for sig in [signal.SIGTERM,signal.SIGINT]:signal.signal(sig,stop)
try:
    for source,dest in [(stage/'preview.html',work/'index.html'),(stage/'detail.html',work/'detail.html')]+[(ROOT/p,work/p) for p in ['assets/css/mdb.min.css','assets/css/business-ui.css','portal/verificados/verified.css']]:
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest)
        if dest.suffix=='.html':dest.write_text(dest.read_text().replace('<head>','<head><meta charset="utf-8">',1))
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self,*a,**kw):super().__init__(*a,directory=str(work),**kw)
        def list_directory(self,path):self.send_error(404)
    with http.server.HTTPServer(('127.0.0.1',56484),Handler) as server:
        print(json.dumps({'pid':os.getpid(),'started_at':time.time(),'root':str(work),'port':56484}),flush=True)
        server.serve_forever()
except KeyboardInterrupt:pass
finally:
    shutil.rmtree(work);print(json.dumps({'cleanup':not work.exists()}),flush=True)
