from pathlib import Path
import hashlib,json,os
b=Path('/var/backups/strava-timezone-20261012-g18a8z2g')
p=Path('/var/www/roadrunners.com.br/api/integrations/strava/batch-refresh.cfm');s=p.stat()
meta={'uid':s.st_uid,'gid':s.st_gid,'mode':oct(s.st_mode&0o777),'runtime_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'backup_directory_mode':oct(b.stat().st_mode&0o777),'backup_data_mode':oct((b/'activity-dates-before.json').stat().st_mode&0o777),'backup_data_sha256':hashlib.sha256((b/'activity-dates-before.json').read_bytes()).hexdigest(),'temporary_probes_remaining':len(list(Path('/var/www/business.roadrunners.run/_codex').glob('strava-date-ops-*')))}
(b/'runtime-metadata.json').write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta,indent=2))
