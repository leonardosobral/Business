"""Scoped IA/kit publish. Reuses the verified atomic/backup/rollback transport.

Default is read-only preflight. No SQL, secrets, server configuration or Git writes.
"""
import ast
import base64
import hashlib
import json
import pathlib
import shlex
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
baseline = {}
for name in ['geocoding-20261017.json', 'geocoding-fontes-20261017.json', 'geocoding-aceleracao-20261018.json']:
    baseline.update(json.loads((ROOT / '_codex/deploy' / name).read_text())['manifest'])
astra = '--astra' in sys.argv
enrichment = '--enrichment' in sys.argv
quota = '--quota-3000' in sys.argv
if astra or enrichment or quota:
    baseline.update(json.loads((ROOT / '_codex/deploy/geocoding-ia-kit-20261019.json').read_text())['manifest'])
if enrichment or quota:
    baseline.update(json.loads((ROOT / '_codex/deploy/geocoding-astra-20261019.json').read_text())['manifest'])
if quota:
    baseline.update(json.loads((ROOT / '_codex/deploy/geocoding-enrichment-20261019.json').read_text())['manifest'])
receipt_path = ROOT / ('_codex/deploy/geocoding-quota-3000-20261019.json' if quota else ('_codex/deploy/geocoding-enrichment-20261019.json' if enrichment else ('_codex/deploy/geocoding-astra-20261019.json' if astra else '_codex/deploy/geocoding-ia-kit-20261019.json')))
previous = json.loads(receipt_path.read_text()) if receipt_path.exists() else {}
baseline.update(previous.get('manifest', {}))
paths = [
    'services/geocoding/AIClient.cfc', 'services/geocoding/LocationPolicy.cfc',
    'services/geocoding/DocumentReader.cfc', 'services/geocoding/LocationStore.cfc',
    'services/geocoding/LocationWorker.cfc',
    'administracao/geolocalizacao/includes/ai_locations_view.cfm',
    'eventos/includes/localizacoes_confirmadas.cfm',
    'services/geocoding/source_fetcher.py', 'services/geocoding/Policy.cfc', 'services/geocoding/Store.cfc',
    'services/geocoding/config.cfm', 'administracao/geolocalizacao/includes/backend.cfm',
    'administracao/geolocalizacao/includes/view.cfm', 'eventos/form_edicao.cfm',
    'api/eventos/geolocalizar.cfm',
]
if astra:
    paths = ['services/geocoding/AIClient.cfc', 'services/geocoding/LocationWorker.cfc', 'services/geocoding/config.cfm']
if enrichment:
    paths = [
        'services/geocoding/RegionNames.cfc', 'services/geocoding/EnrichmentPolicy.cfc',
        'services/geocoding/EnrichmentStore.cfc', 'services/geocoding/LocationPolicy.cfc',
        'services/geocoding/LocationStore.cfc', 'services/geocoding/LocationWorker.cfc',
        'services/geocoding/AIClient.cfc', 'services/geocoding/Policy.cfc',
        'administracao/geolocalizacao/includes/enrichment_view.cfm',
        'administracao/geolocalizacao/includes/ai_locations_view.cfm',
        'administracao/geolocalizacao/includes/backend.cfm',
        'administracao/geolocalizacao/includes/view.cfm',
        'administracao/geolocalizacao/assets/geocoding.js',
        'administracao/geolocalizacao/index.cfm',
        'eventos/includes/enriquecimento_confirmado.cfm',
        'eventos/includes/localizacoes_confirmadas.cfm',
    ]
if 'eventos/form_edicao.cfm' not in baseline:
    original = subprocess.run(['git', 'show', 'HEAD:eventos/form_edicao.cfm'], cwd=ROOT, capture_output=True, check=True).stdout
    baseline['eventos/form_edicao.cfm'] = {'after': hashlib.sha256(original).hexdigest()}
if quota:
    paths = ['services/geocoding/Store.cfc', 'administracao/geolocalizacao/includes/view.cfm']
payload = {'publish': '--publish' in sys.argv, 'files': [
    {'path': path, 'before': baseline.get(path, {}).get('after'),
     'data': base64.b64encode((ROOT / path).read_bytes()).decode()} for path in paths]}
tree = ast.parse((ROOT / '_codex/scripts/deploy_geocoding_sources.py').read_text())
remote = next(ast.literal_eval(node.value) for node in tree.body if isinstance(node, ast.Assign)
              and any(isinstance(target, ast.Name) and target.id == 'REMOTE' for target in node.targets))
run = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes', '-o', 'ConnectTimeout=12',
                      'rr-prod', 'python3 -c ' + shlex.quote(remote)], input=json.dumps(payload).encode(),
                     capture_output=True, timeout=150)
try:
    result = json.loads(run.stdout)
except Exception:
    result = {'ok': False, 'error': 'Scoped publication transport failed; inspect private transport'}
if result.get('mode') == 'published':
    result['previous_publications'] = previous.get('previous_publications', []) + ([{
        'backup': previous['backup'], 'manifest': previous['manifest']}] if previous else [])
    result['manifest'] = {**previous.get('manifest', {}), **result['manifest']}
    receipt_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({key: result[key] for key in ['ok', 'mode', 'backup', 'checks', 'probes'] if key in result} if '--summary' in sys.argv else result, ensure_ascii=False))
sys.exit(0 if run.returncode == 0 and result.get('ok') else 1)
