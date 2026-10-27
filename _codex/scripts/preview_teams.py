import base64,json,pathlib,shlex,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2];archive=json.loads((ROOT/'_codex/teams/http-http.json').read_text())['archive']
if not archive.startswith('/var/backups/rr-teams-http-'):raise SystemExit('Unexpected preview archive')
code="import base64,json,pathlib;p=pathlib.Path("+repr(archive)+");print(json.dumps({n:base64.b64encode((p/n).read_bytes()).decode() for n in ['preview-cadastro.html','preview-divulgacao.html','preview-rr.html']}))"
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(code)],capture_output=True,timeout=20)
run.check_returncode();payload=json.loads(run.stdout);dest=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-final-preview-'))
for name,encoded in payload.items():(dest/name).write_bytes(base64.b64decode(encoded))
for p in (ROOT/'_codex/teams/release/business/teams/assets').glob('*'):
 if p.is_file():
  out=dest/'teams/assets'/p.name;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(p.read_bytes())
out=dest/'assets/css/business-ui.css';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes((ROOT/'assets/css/business-ui.css').read_bytes())
(dest/'mobile.html').write_text('<!doctype html><meta charset="utf-8"><title>Teams · Mobile</title><style>body{margin:0;background:#ddd}iframe{width:390px;height:900px;border:0;display:block;margin:12px auto}</style><iframe title="Teams em 390px" src="preview-cadastro.html"></iframe>')
print(json.dumps({'preview':str(dest)}));(ROOT/'_codex/teams/final-preview.json').write_text(json.dumps({'path':str(dest)},indent=2))
