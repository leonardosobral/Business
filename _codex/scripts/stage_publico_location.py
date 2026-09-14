"""Read-only production capture and exact, scope-limited release artifact builder."""
from pathlib import Path
import base64, hashlib, json, re, shlex, subprocess, sys

root = Path(__file__).resolve().parents[2]
stage = Path(sys.argv[1]).resolve()
assert stage.is_dir() and not list(stage.iterdir()), 'Use an empty private staging directory'
targets = {
    ('RoadRunners','services/LocationResolver.cfc'): '09bba9d0f16adf1dd90c2b6cc5e97ee65391b75be45ea30011af7040b9472b9d',
    ('RoadRunners','Application.cfc'): '2e81c368a8251ff13882104be30b2b66f02f9aaecbea2bf5af077540c774bf48',
    ('Business','portal/audiencia/queries/event_interest.sql'): '4382b640eff5eb12f054bb2a1765deaa9410e6047fc8137ad5f16664066aff55',
    ('Business','portal/includes/event_interest_backend.cfm'): '2fc6aaec72f8e99a12fff3497e043c4fae3cee9af995b269da6c4c348743b3d2',
    ('Business','portal/eventos-analytics/home.cfm'): '6e9b6aec915c71122a8277a71a619a0fc16c93cc3a4c253aa3452b143bf4755d',
    ('RoadRunners','services/AudienceMeasurementService.cfc'): 'ece8218e02d5886540b2a1963ae0b343cf521bff7386c53aaefc7955a60ad476',
}
remote_roots = {'RoadRunners':'/var/www/roadrunners.com.br','Business':'/var/www/business.roadrunners.run'}
paths = {site+'/'+name:remote_roots[site]+'/'+name for site,name in targets}
code = 'from pathlib import Path; import base64,json; print(json.dumps({k:base64.b64encode(Path(v).read_bytes()).decode() for k,v in '+repr(paths)+'.items()}))'
ssh = ['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
payload = json.loads(subprocess.check_output(ssh+['python3 -c '+shlex.quote(code)],timeout=60))
for (site,name),expected in targets.items():
    content = base64.b64decode(payload[site+'/'+name])
    assert hashlib.sha256(content).hexdigest()==expected, 'Production changed: '+site+'/'+name
    before = stage/'baseline'/site/name
    before.parent.mkdir(parents=True,exist_ok=True)
    before.write_bytes(content)
    local = (root.parent/site/name).read_bytes()
    if name=='services/LocationResolver.cfc':
        # Keep pre-existing production/local negative-cache differences out of this release.
        method = re.search(rb'    <!--- Global request hydration:[\s\S]*?</cffunction>\n\n',local)
        assert method and b'name="resolveAvailable"' in method[0]
        anchor = b'    <cffunction name="getEstadoNome"'
        assert content.count(anchor)==1 and b'name="resolveAvailable"' not in content
        candidate = content.replace(anchor,method[0]+anchor)
        assert candidate.replace(method[0],b'',1)==content
    else:
        candidate = local
    if name=='services/AudienceMeasurementService.cfc':
        assert candidate==content, 'The test dependency must match production unchanged'
    dest = stage/'candidate'/site/name
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_bytes(candidate)
    print(site+'/'+name, expected, hashlib.sha256(candidate).hexdigest())
