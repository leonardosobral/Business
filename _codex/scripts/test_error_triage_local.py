"""Offline CFML behavior tests using the project's cached Lucee runtime."""
from pathlib import Path
import os, shutil, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parents[2]
scratch=Path(tempfile.mkdtemp(prefix='error-triage-',dir='/private/tmp'))
mode=sys.argv[1] if len(sys.argv)>1 else 'normalizer'
pg=Path('/opt/homebrew/opt/postgresql@16/bin');started=False
try:
    shutil.copytree(ROOT/'portal/erros',scratch/'portal/erros')
    (scratch/'_codex/tests').mkdir(parents=True)
    for p in (ROOT/'_codex/tests').glob('error-triage-*.cfm'):shutil.copy2(p,scratch/'_codex/tests'/p.name)
    body='<cfinclude template="_codex/tests/error-triage-normalizer.cfm"/>'
    if mode=='service':
        port=str(55700+os.getpid()%200)
        subprocess.run([str(pg/'initdb'),'-D',str(scratch/'db'),'-U','triage_test','-A','trust','--no-locale','--encoding=UTF8'],check=True,capture_output=True)
        subprocess.run([str(pg/'pg_ctl'),'-D',str(scratch/'db'),'-l',str(scratch/'postgres.log'),'-o',f'-h 127.0.0.1 -p {port} -k {scratch}','-w','start'],check=True,capture_output=True);started=True
        (scratch/'_codex/sql').mkdir()
        shutil.copy2(ROOT/'_codex/sql/2026-09-26_error_triage.sql',scratch/'_codex/sql')
        body='<cfscript>application action="update" datasources={runner_dba={class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:'+port+'/postgres",username="triage_test",password=""}};</cfscript>'+body+'<cfinclude template="_codex/tests/error-triage-service.cfm"/>'
    body='<cfscript>REQUEST.triageSavePreview=true;m=duplicate(getApplicationSettings().mappings);m["/portal"]=getDirectoryFromPath(getCurrentTemplatePath()) & "portal";application action="update" mappings=m sessionmanagement=true;</cfscript>'+body
    (scratch/'run.cfm').write_text(body+'<cfoutput>TRIAGE_PASS #arrayLen(triageTests)#</cfoutput>')
    p=subprocess.run(['/usr/bin/java','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/crm-interno-runtime/commandbox','execute','run.cfm'],cwd=scratch,capture_output=True,text=True,timeout=90)
    print(p.stdout[-6000:]);print(p.stderr[-1000:]);
    if (scratch/'rendered.html').exists():shutil.copy2(scratch/'rendered.html',ROOT/'_codex/staging/error-triage/rendered.html')
    sys.exit(0 if p.returncode==0 and 'TRIAGE_PASS' in p.stdout else 1)
finally:
    if started:subprocess.run([str(pg/'pg_ctl'),'-D',str(scratch/'db'),'-m','fast','-w','stop'],capture_output=True)
    shutil.rmtree(scratch)
