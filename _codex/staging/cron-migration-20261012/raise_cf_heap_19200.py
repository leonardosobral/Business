from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, os, re, subprocess, tempfile, time

os.umask(0o077)
target = Path('/opt/coldfusion2025/cfusion/bin/jvm.config')
original = target.read_bytes()
meta = target.stat()
expected = '90f62b70a87e5e6a68def5f15dd50f95cd590eda0a71dfb9eaefa5d55208ba32'
if hashlib.sha256(original).hexdigest() != expected:
    raise RuntimeError('JVM config changed since capacity review; no changes made.')
if re.findall(rb'-Xm[sx]\S+', original) != [b'-Xms2048m', b'-Xmx8192m']:
    raise RuntimeError('Unexpected heap configuration.')
for name in ['cf-init.sh', 'cf-connectors.sh']:
    if (target.parent / name).exists():
        raise RuntimeError('Startup has additional setup hooks; review required.')

def java_pids():
    result = []
    for proc in Path('/proc').iterdir():
        if proc.name.isdigit():
            try:
                if (proc / 'comm').read_text().strip() == 'java' and b'/opt/coldfusion2025/' in (proc / 'cmdline').read_bytes():
                    result.append(int(proc.name))
            except (FileNotFoundError, ProcessLookupError):
                pass
    return result

before_pids = java_pids()
if len(before_pids) != 1:
    raise RuntimeError('Expected exactly one ColdFusion JVM.')
candidate = original.replace(b'-Xmx8192m', b'-Xmx19200m')
backup = Path(tempfile.mkdtemp(prefix='cf2025-heap-19200-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-', dir='/var/backups'))
(backup / 'jvm.config.before').write_bytes(original)
report = {'backup': str(backup), 'started_at_utc': datetime.now(timezone.utc).isoformat(), 'before_sha256': expected, 'after_sha256': hashlib.sha256(candidate).hexdigest(), 'before_pid': before_pids[0], 'before_heap_mib': {'initial': 2048, 'maximum': 8192}, 'after_heap_mib': {'initial': 2048, 'maximum': 19200}, 'apache_configuration_changed': False}

def save_report():
    (backup / 'result.json').write_text(json.dumps(report, indent=2) + '\n')

def replace_config(content, current_expected):
    if target.read_bytes() != current_expected:
        raise RuntimeError('Concurrent JVM config change; refusing overwrite.')
    fd, name = tempfile.mkstemp(prefix='.jvm-heap-', dir=target.parent)
    try:
        with os.fdopen(fd, 'wb') as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        os.chown(name, meta.st_uid, meta.st_gid)
        os.chmod(name, meta.st_mode & 0o777)
        os.replace(name, target)
    finally:
        if os.path.exists(name):
            os.unlink(name)

def service(action, label):
    with (backup / (label + '.log')).open('w') as output:
        return subprocess.run(['systemctl', action, 'cf2025'], stdout=output, stderr=subprocess.STDOUT, timeout=45).returncode

save_report()
replace_config(candidate, original)
print(json.dumps({'stage': 'config_saved', 'backup': str(backup)}), flush=True)
try:
    report['stop_rc'] = service('stop', 'stop')
    if report['stop_rc'] != 0 or java_pids():
        raise RuntimeError('Original JVM did not stop cleanly; no duplicate start attempted.')
    print(json.dumps({'stage': 'previous_jvm_stopped'}), flush=True)
    report['start_rc'] = service('start', 'start')
    for attempt in range(20):
        if java_pids():
            break
        time.sleep(1)
    report['after_pids'] = java_pids()
    report['service_active'] = subprocess.run(['systemctl', 'is-active', 'cf2025'], capture_output=True, text=True).stdout.strip()
    if report['start_rc'] != 0 or len(report['after_pids']) != 1 or report['service_active'] != 'active':
        raise RuntimeError('New JVM failed startup checks.')
    report['runtime_heap_options'] = [arg.decode() for arg in Path('/proc', str(report['after_pids'][0]), 'cmdline').read_bytes().split(b'\0') if arg.startswith((b'-Xms', b'-Xmx'))]
    if report['runtime_heap_options'] != ['-Xms2048m', '-Xmx19200m']:
        raise RuntimeError('Runtime heap options do not match candidate.')
except Exception as error:
    report['error'] = str(error)
    # Restore the previous configuration only if our candidate is still current.
    replace_config(original, candidate)
    report['config_restored'] = True
    if not java_pids():
        report['rollback_stop_rc'] = service('stop', 'rollback-stop')
        report['rollback_start_rc'] = service('start', 'rollback-start')
    save_report()
    raise
report['finished_at_utc'] = datetime.now(timezone.utc).isoformat()
save_report()
print(json.dumps(report, indent=2), flush=True)
