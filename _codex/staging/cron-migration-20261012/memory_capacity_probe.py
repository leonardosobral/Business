from pathlib import Path
from datetime import datetime, timezone
import collections, hashlib, json, re, subprocess

out = {'measured_at_utc': datetime.now(timezone.utc).isoformat()}
out['memory_kib'] = {k: int(v) for k, v in re.findall(r'^(MemTotal|MemAvailable|SwapTotal|SwapFree|Slab|SReclaimable|KernelStack|PageTables):\s+(\d+)', Path('/proc/meminfo').read_text(), re.M)}
out['load'] = Path('/proc/loadavg').read_text().strip()
out['cpu_count'] = subprocess.check_output(['nproc'], text=True).strip()
groups = collections.defaultdict(lambda: {'rss_kib': 0, 'pss_kib': 0, 'processes': 0})
out['java'] = []
for proc in Path('/proc').iterdir():
    if not proc.name.isdigit():
        continue
    try:
        name = (proc / 'comm').read_text().strip()
        status = (proc / 'status').read_text()
        rss = re.search(r'^VmRSS:\s+(\d+)', status, re.M)
        if not rss:
            continue
        rollup = (proc / 'smaps_rollup').read_text()
        pss = re.search(r'^Pss:\s+(\d+)', rollup, re.M)
        group = groups[name]
        group['rss_kib'] += int(rss[1])
        group['pss_kib'] += int(pss[1]) if pss else 0
        group['processes'] += 1
        if name == 'java':
            args = (proc / 'cmdline').read_bytes().decode().split('\0')
            out['java'].append({'pid': int(proc.name), 'heap_options': [a for a in args if a.startswith(('-Xms', '-Xmx', '-Xss', '-XX:MaxMetaspaceSize', '-XX:MaxDirectMemorySize'))], 'threads': re.search(r'^Threads:\s+(\d+)', status, re.M)[1], 'cgroup': (proc / 'cgroup').read_text().strip()})
    except (FileNotFoundError, ProcessLookupError, PermissionError):
        continue
out['process_memory'] = dict(sorted(groups.items(), key=lambda item: item[1]['pss_kib'], reverse=True)[:15])
for path in ['/opt/coldfusion2025/cfusion/bin/jvm.config', '/opt/ColdFusion/cfusion/bin/jvm.config']:
    p = Path(path)
    if p.exists():
        raw = p.read_bytes()
        out['jvm_config'] = {'path': path, 'sha256': hashlib.sha256(raw).hexdigest(), 'heap_options': re.findall(r'-Xm[sx]\S+', raw.decode())}
out['cf_service_limits'] = subprocess.run(['systemctl', 'show', 'cf2025', '--property=MemoryMax,MemoryHigh,EffectiveMemoryMax,TasksMax,ActiveState,MainPID'], capture_output=True, text=True).stdout.splitlines()
r = subprocess.run(['curl', '-sS', '--max-time', '5', 'http://127.0.0.1/server-status?auto'], capture_output=True, text=True)
out['apache'] = [l for l in r.stdout.splitlines() if l.startswith(('BusyWorkers:', 'IdleWorkers:'))]
r = subprocess.run(['ss', '-lnt'], capture_output=True, text=True)
out['queues'] = [l for l in r.stdout.splitlines() if any(re.search(r':'+p+r'\s', l) for p in ['443','80','8124'])]
print(json.dumps(out, indent=2))
