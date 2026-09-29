"""Real CFML + isolated PostgreSQL fixtures; never connects to production."""
from pathlib import Path
import os, re, shutil, subprocess, sys, tempfile

ROOT = Path(__file__).resolve().parents[2]
work = Path(tempfile.mkdtemp(prefix='notification-audience-', dir='/private/tmp'))
pg = Path('/opt/homebrew/opt/postgresql@16/bin')
started = False
try:
    shutil.copytree(ROOT/'notificacoes', work/'notificacoes')
    tests = work/'_codex/tests'
    tests.mkdir(parents=True)
    shutil.copy2(ROOT/'_codex/tests/notification-audience.cfm', tests)
    backend = (ROOT/'notificacoes/includes/backend.cfm').read_text()
    dashboard = (ROOT/'includes/estrutura/home_admin_dashboard.cfm').read_text()
    home_query = re.search(r'<cfquery name="qBusinessAdminHomeNotificationStats">.*?</cfquery>', dashboard, re.S).group()
    (tests/'home_stats.cfm').write_text(home_query)
    for name, sql in [('bulk_deactivate','UPDATE'), ('bulk_delete','DELETE FROM')]:
        fragment = re.search(r'<cfquery>\s*'+sql+r' tb_notifica ntf.*?</cfquery>', backend, re.S).group()
        (work/'notificacoes/includes'/f'{name}.cfm').write_text(fragment)
        (tests/f'{name}.cfm').write_text(f'<cfinclude template="../../notificacoes/includes/{name}.cfm"/>')
    port = str(55900 + os.getpid()%200)
    subprocess.run([str(pg/'initdb'),'-D',str(work/'db'),'-U','notification_test','-A','trust','--no-locale','--encoding=UTF8'],check=True,capture_output=True)
    subprocess.run([str(pg/'pg_ctl'),'-D',str(work/'db'),'-l',str(work/'postgres.log'),'-o',f'-h 127.0.0.1 -p {port} -k {work}','-w','start'],check=True,capture_output=True)
    started = True
    (work/'run.cfm').write_text('<cfscript>application action="update" datasource="runner_dba" datasources={runner_dba={class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:'+port+'/postgres",username="notification_test",password=""}};</cfscript><cfinclude template="_codex/tests/notification-audience.cfm"/>')
    result = subprocess.run(['/usr/bin/java','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/crm-interno-runtime/commandbox','execute','run.cfm'],cwd=work,capture_output=True,text=True,timeout=120)
    print(result.stdout[-7000:]); print(result.stderr[-1500:])
    sys.exit(0 if result.returncode == 0 and 'NOTIFICATION_AUDIENCE_PASS' in result.stdout else 1)
finally:
    if started:
        subprocess.run([str(pg/'pg_ctl'),'-D',str(work/'db'),'-m','fast','-w','stop'],capture_output=True)
    shutil.rmtree(work)
