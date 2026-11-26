"""Disposable PostgreSQL cluster, with ownership and cleanup verified."""
from pathlib import Path
import json,os,signal,subprocess,tempfile,shutil
ROOT=Path(__file__).resolve().parents[2]
BIN=Path(subprocess.check_output(['pg_config','--bindir'],text=True).strip())
work=Path(tempfile.mkdtemp(prefix='business-verified-pg-'));data=work/'data';sock=work/'socket';sock.mkdir();started=False;pid=None

def stop_on_signal(signum,frame):raise KeyboardInterrupt()
for sig in (signal.SIGINT,signal.SIGTERM):signal.signal(sig,stop_on_signal)
try:
    subprocess.run([str(BIN/'initdb'),'-D',str(data),'-A','trust','--no-locale','-E','UTF8'],check=True,capture_output=True)
    subprocess.run([str(BIN/'pg_ctl'),'-D',str(data),'-l',str(work/'server.log'),'-o',"-k "+str(sock)+" -p 56483 -h ''",'-w','start'],check=True,capture_output=True)
    started=True;pid=int((data/'postmaster.pid').read_text().splitlines()[0]);(work/'ownership.json').write_text(json.dumps({'pid':pid,'data':str(data),'socket':str(sock)}))
    run=subprocess.run([str(BIN/'psql'),'-h',str(sock),'-p','56483','-d','postgres','-v','ON_ERROR_STOP=1','-f',str(ROOT/'_codex/tests/verified-origins/quick-batch.sql')],text=True,capture_output=True,timeout=45)
    if run.returncode:raise RuntimeError(run.stderr)
    result={'ok':'VERIFIED_QUICK_BATCH_PASSED' in run.stdout,'checks':['initial migration','idempotence','admin authorization','permanent-only','category validation','reason validation','concurrent revision','append-only history','no entitlement mutation','restricted grants','batch rollback on conflict','batch success']}
finally:
    if started:
        subprocess.run([str(BIN/'pg_ctl'),'-D',str(data),'-m','fast','-w','stop'],check=True,capture_output=True,timeout=30)
        if (data/'postmaster.pid').exists():raise RuntimeError('Temporary PostgreSQL still owns PID file: '+str(work))
    shutil.rmtree(work)
result['temporary_cluster_removed']=not work.exists()
(ROOT/'_codex/staging/verified-quick-20261124/sql-tests.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
