from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, re, shutil, subprocess, tempfile, zipfile

root = next(p for p in [Path('/opt/coldfusion2025/cfusion'), Path('/opt/ColdFusion/cfusion')] if p.exists())
config = (root / 'bin/jvm.config').read_text()
out = {'measured_at_utc': datetime.now(timezone.utc).isoformat(), 'root': str(root), 'config_sha256': hashlib.sha256(config.encode()).hexdigest()}
classpath = re.search(r'^java.class.path=(.*)$', config, re.M)
out['configured_classpath'] = classpath[1] if classpath else None
args = re.search(r'^java.args=(.*)$', config, re.M)
prefixes = ('-Xms', '-Xmx', '-XX:+Use', '--add-opens=', '--add-exports=', '-Duser.timezone=', '-Djava.locale.providers=', '-Dcoldfusion.datasource.blocked.properties=', '-Djdk.lang.Process.allowAmbiguousCommands=')
out['selected_configured_arguments'] = [a for a in args[1].split() if a.startswith(prefixes)] if args else []
out['os_timezone'] = subprocess.run(['timedatectl', 'show', '-p', 'Timezone', '--value'], capture_output=True, text=True).stdout.strip()
legacy = root / 'wwwroot/WEB-INF/cfform/jars'
out['legacy_cfform_jars'] = {'directory_exists': legacy.is_dir(), 'files': sorted(p.name for p in legacy.iterdir()) if legacy.is_dir() else []}
out['updates'] = sorted(p.name for p in (root / 'lib/updates').glob('*.jar'))
pids = []
for p in Path('/proc').iterdir():
    if p.name.isdigit():
        try:
            if (p / 'comm').read_text().strip() == 'java' and str(root.parent).encode() in (p / 'cmdline').read_bytes():
                pids.append(p.name)
        except (FileNotFoundError, ProcessLookupError):
            pass
if len(pids) != 1:
    raise RuntimeError('Expected one matching JVM.')
exe = (Path('/proc') / pids[0] / 'exe').resolve()
work = Path(tempfile.mkdtemp(prefix='cf-jvm-compatibility-', dir='/var/tmp'))
try:
    (work / 'Inspect.java').write_text('import com.sun.tools.attach.VirtualMachine; import sun.tools.attach.HotSpotVirtualMachine; public class Inspect { public static void main(String[] a) throws Exception { VirtualMachine v=VirtualMachine.attach(a[0]); try { ((HotSpotVirtualMachine)v).executeJCmd("VM.system_properties").transferTo(System.out); } finally {v.detach();} } }')
    result = subprocess.run([str(exe), '--add-exports', 'jdk.attach/sun.tools.attach=ALL-UNNAMED', str(work / 'Inspect.java'), pids[0]], capture_output=True, text=True, timeout=25)
    out['runtime_probe_rc'] = result.returncode
    allowed = {'java.version', 'java.runtime.version', 'java.vendor', 'java.home', 'user.timezone', 'java.locale.providers', 'jdk.lang.Process.allowAmbiguousCommands', 'coldfusion.datasource.blocked.properties'}
    out['selected_runtime_properties'] = {key: value for line in result.stdout.splitlines() if '=' in line for key, value in [line.split('=', 1)] if key in allowed}
finally:
    shutil.rmtree(work)
print(json.dumps(out, indent=2))
