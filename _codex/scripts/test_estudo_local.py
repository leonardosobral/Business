"""CFML contracts against a disposable database; no production connections."""
from pathlib import Path
import importlib.util, shutil, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parents[2]
scratch=Path(tempfile.mkdtemp(prefix='estudo-cf-',dir='/private/tmp'))
db=None
try:
 if (ROOT/'estudo').exists():shutil.copytree(ROOT/'estudo',scratch/'estudo')
 else:(scratch/'estudo').mkdir()
 (scratch/'_codex/tests').mkdir(parents=True)
 for p in (ROOT/'_codex/tests').glob('estudo_*.cfm'):shutil.copy2(p,scratch/'_codex/tests'/p.name)
 body='<cfscript>m=duplicate(getApplicationSettings().mappings);m["/estudo"]=getDirectoryFromPath(getCurrentTemplatePath())&"estudo";application action="update" mappings=m;</cfscript>'
 if 'service' in sys.argv:
  spec=importlib.util.spec_from_file_location('fixture',ROOT/'_codex/tests/estudo_notebook_db_test.py')
  mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
  db=mod.NotebookDatabase;db.setUpClass()
  body+='<cfscript>application action="update" datasources={runner_dba={class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:'+db.port+'/postgres",username="runner_dba",password=""}};</cfscript>'
 body+='<cfinclude template="_codex/tests/estudo_guard.cfm"/>'
 if db:body+='<cfinclude template="_codex/tests/estudo_service.cfm"/>'
 (scratch/'run.cfm').write_text('<cftry>'+body+'<cfoutput>ESTUDO_PASS</cfoutput><cfcatch><cfdump var="#cfcatch#" format="text"/><cfrethrow/></cfcatch></cftry>')
 p=subprocess.run(['/usr/bin/java','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/crm-interno-runtime/commandbox','execute','run.cfm'],cwd=scratch,capture_output=True,text=True,timeout=120)
 print(p.stdout[-9000:]);print(p.stderr[-1000:])
 sys.exit(0 if p.returncode==0 and 'ESTUDO_PASS' in p.stdout else 1)
finally:
 if db:db.cleanup()
 shutil.rmtree(scratch)
