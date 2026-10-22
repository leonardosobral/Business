"""Bounded native regression report; no provider calls in the all suite."""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
run = subprocess.run([sys.executable, str(ROOT / '_codex/scripts/test_geocoding_native.py'), 'all'],
                     capture_output=True, text=True, timeout=600)
results = []
for line in run.stdout.splitlines():
    try:
        result = json.loads(line)
    except ValueError:
        continue
    results.append(result)
report = {'ok': run.returncode == 0 and len(results) == 31 and all(item.get('ok') for item in results),
          'suite_count': len(results), 'suites': results, 'python_reader': None}
reader = subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', '_codex/tests/geocoding',
                         '-p', 'test_source_fetcher.py'], cwd=ROOT, capture_output=True, text=True, timeout=30)
report['python_reader'] = {'ok': reader.returncode == 0, 'result': reader.stderr[-2000:]}
report['ok'] = report['ok'] and reader.returncode == 0
(ROOT / '_codex/deploy/geocoding-ia-kit-tests-20261019.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'ok': report['ok'], 'suite_count': len(results), 'suites': [
    {'ok': item['ok'], 'archive': item.get('archive'), 'passes': item.get('output', '').count('PASS '),
     'failure': item.get('output', '')[-2500:] if not item.get('ok') else ''} for item in results],
    'python_reader': report['python_reader']}, ensure_ascii=False))
sys.exit(0 if report['ok'] else 1)
