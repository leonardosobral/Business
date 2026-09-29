"""Run CRM behavior tests against an isolated local PostgreSQL/CFML runtime."""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess

root = Path(__file__).resolve().parents[2]
rr = root.parent / 'RoadRunners'
runtime = Path('/private/tmp/crm-interno-runtime')
psql = ['/opt/homebrew/opt/postgresql@16/bin/psql', '-X', '-v', 'ON_ERROR_STOP=1',
        '-h', '127.0.0.1', '-p', '55447', '-U', 'crm_test', '-d', 'crm_test']

def run(command, **kwargs):
    subprocess.run(command, check=True, **kwargs)

identity = subprocess.check_output(psql + ['-Atc', 'select current_database()'], text=True).strip()
if identity != 'crm_test':
    raise SystemExit('Refusing a non-test database')
for relative in ['_codex/tests/crm-interno/fixtures.sql',
                 '_codex/sql/migrations/2026-09-24_crm_interno.sql',
                 '_codex/sql/migrations/2026-09-24_crm_interno.sql',
                 '_codex/sql/migrations/2026-09-24_crm_opportunities.sql',
                 '_codex/sql/migrations/2026-09-24_crm_opportunities.sql',
                 '_codex/sql/migrations/2026-09-24_crm_audience_history.sql',
                 '_codex/sql/migrations/2026-09-24_crm_audience_history.sql',
                 '_codex/sql/migrations/2026-09-25_crm_checkout_identity.sql',
                 '_codex/sql/migrations/2026-09-25_crm_checkout_identity.sql',
                 '_codex/sql/migrations/2026-09-25_crm_conversion_ledger.sql',
                 '_codex/sql/migrations/2026-09-25_crm_conversion_ledger.sql',
                 '_codex/sql/migrations/2026-09-25_crm_challenge_signup.sql',
                 '_codex/sql/migrations/2026-09-25_crm_challenge_signup.sql',
                 '_codex/sql/migrations/2026-09-25_crm_tsd_program.sql',
                 '_codex/sql/migrations/2026-09-25_crm_tsd_program.sql',
                 '_codex/tests/crm-interno/schema.sql']:
    run(psql + ['-f', str(rr / relative)], stdout=subprocess.DEVNULL)
program_sql = rr / '_codex/sql/migrations/2026-09-25_crm_tsd_program.sql'
program_checksum = hashlib.sha256(program_sql.read_bytes()).hexdigest()
run(psql + ['-c', "INSERT INTO crm_interno.schema_migrations(version,checksum) VALUES('2026-09-25_crm_tsd_program','" + program_checksum + "') ON CONFLICT(version) DO UPDATE SET checksum=excluded.checksum"], stdout=subprocess.DEVNULL)
marker = subprocess.check_output(psql + ['-Atc', "SELECT checksum FROM crm_interno.schema_migrations WHERE version='2026-09-25_crm_tsd_program'"], text=True).strip()
if marker != program_checksum:
    raise SystemExit('Todo Santo Dia migration checksum marker differs')
for checkout in ['transacao_pix.cfm', 'transacao_cc.cfm']:
    source = (rr / 'carteira/parts' / checkout).read_text()
    reserve = source.find('reserve(Usuario.id, FORM.produto_codigo)')
    post = source.find('<cfhttp url="https://api.pagar.me/core/v5/orders"')
    bind = source.find('.bind(VARIABLES.crmOrderIdentity.code,')
    if not (0 <= reserve < post < bind):
        raise SystemExit(f'{checkout}: authenticated SKU must be reserved before Pagar.me POST and bound after response')
app = runtime / 'app'
app.mkdir(exist_ok=True)
if (rr / 'services/crm').exists():
    shutil.copytree(rr / 'services/crm', app / 'services/crm', dirs_exist_ok=True)
for name in ['CrmJobSecurity.cfc', 'CrmClient.cfc', 'CrmCommerceService.cfc']:
    shutil.copy2(root / 'services' / name, app / 'services' / name)
shutil.copy2(rr / '_codex/tests/crm-interno/run.cfm', app / 'run.cfm')
env = dict(os.environ, RUNNERHUB_OFFLINE_CFML_TESTS='1')
run(['/usr/bin/java', '-cp', '/Users/Shared/Projects/ColdFusion Certification/box',
     'cliloader.LoaderCLIMain', f'-CommandBox_home={runtime}/commandbox',
     'execute', 'run.cfm'], cwd=app, env=env)
