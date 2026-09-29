from pathlib import Path
import subprocess,shlex,json
root=Path(__file__).resolve().parents[2]
source=(root/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
body='service=new portal.erros.includes.ErrorTriage().init();started=getTickCount();images=service.missingImages({site="RR",sort="frequency"});report={paths=images.total,occurrences=images.occurrences,elapsed_ms=getTickCount()-started,top=[]};for(row in images.items){if(arrayLen(report.top)<8)arrayAppend(report.top,{path=row.path,occurrences=row.occurrences,log_id=row.sample_id});}'
source+='\nresult=bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')\nprint(json.dumps(result,default=str))\nprint(json.dumps({"handler_published_utc":__import__("datetime").datetime.fromtimestamp(Path("/var/backups/roadrunners-error-handler-20260926-v2/published.json").stat().st_mtime,__import__("datetime").timezone.utc).isoformat()}))'
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],capture_output=True,text=True,timeout=110)
print(p.stdout);print(p.stderr[-1000:] if p.returncode else '');(root/'_codex/staging/error-triage-admin-evidence/production-export.json').write_text(p.stdout);raise SystemExit(p.returncode)
