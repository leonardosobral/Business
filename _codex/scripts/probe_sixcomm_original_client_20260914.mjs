import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
const source = readFileSync('/Users/geraldoprotta/IdeaProjects/News/config/content.local.cfm', 'utf8');
const values = {};
for (const [target, key] of [['clientId','googleOAuthClientId'],['clientSecret','googleOAuthClientSecret']]) {
  const matches = [...source.matchAll(new RegExp('^\\s*' + key + '\\s*=\\s*"([^"\\r\\n]+)"\\s*,?\\s*$', 'gm'))];
  if (matches.length !== 1) throw Error('Missing or ambiguous original client; values withheld.');
  values[target] = matches[0][1];
}
const result = spawnSync('ssh', ['-o','BatchMode=yes','rr-prod',
  'python3 /var/backups/content-sixcomm-oauth.0d8rxvcj/run_diagnostic.py candidate'], {
  input: JSON.stringify(values), encoding: 'utf8', maxBuffer: 1024*1024,
});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
process.exit(result.status ?? 1);
