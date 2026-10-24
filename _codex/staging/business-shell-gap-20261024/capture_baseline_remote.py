"""Read-only metadata/content snapshot. Run over SSH; stdout is private JSON."""
from pathlib import Path
import base64
import datetime
import hashlib
import json
import pwd
import stat

ROOT = Path('/var/www/business.roadrunners.run')
NAMES = [
    'includes/estrutura/header.cfm',
    'includes/estrutura/navbar.cfm',
    'assets/css/business-shell.css',
    'assets/js/business-shell.js',
]
WATCH = [
    'assets/css/style.css', 'assets/css/admin-suite.css',
    'includes/estrutura/account_context_modal.cfm', 'template.cfm',
    'includes/estrutura/head.cfm', 'includes/estrutura/sidenav.cfm',
    'assets/css/admin-dashboard.css',
]

out = {
    'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'root': str(ROOT), 'files': {}, 'watch': {}, 'compiler': [],
}
for name in NAMES + WATCH:
    target = ROOT / name
    row = {'exists': target.exists(), 'symlink': target.is_symlink()}
    if target.is_file():
        data = target.read_bytes()
        metadata = target.stat()
        row.update(sha256=hashlib.sha256(data).hexdigest(), bytes=len(data),
                   mode=stat.S_IMODE(metadata.st_mode), uid=metadata.st_uid,
                   gid=metadata.st_gid)
        if name in NAMES:
            row['content_base64'] = base64.b64encode(data).decode()
    out['files' if name in NAMES else 'watch'][name] = row
for executable in Path('/opt').glob('*/cfusion/bin/cfcompile.sh'):
    seed = executable.parent.parent / 'lib/seed.properties'
    out['compiler'].append({
        'executable': str(executable),
        'user': pwd.getpwuid(seed.stat().st_uid).pw_name,
    })
print(json.dumps(out))
