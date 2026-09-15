// Copies only the existing SixComm OAuth fields through SSH stdin, never logs them.
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const keys = ['sixCommGmailClientId', 'sixCommGmailClientSecret', 'sixCommGmailRedirectUri'];
const source = readFileSync('/Users/geraldoprotta/IdeaProjects/News/config/content.local.cfm', 'utf8');
const values = {};
const originalClient = process.argv.includes('--original-login-client');
for (const key of keys) {
  const sourceKey = originalClient ? key.replace('sixCommGmail', 'googleOAuth') : key;
  const matches = [...source.matchAll(new RegExp('^\\s*' + sourceKey + '\\s*=\\s*"([^"\\r\\n]+)"\\s*,?\\s*$', 'gm'))];
  if (matches.length !== 1) throw Error('Missing or ambiguous existing configuration; values withheld.');
  values[key] = matches[0][1];
}
const result = spawnSync('ssh', ['-o', 'BatchMode=yes', 'rr-prod',
  'python3 /var/backups/restore_sixcomm_oauth_20260914.py' + (originalClient ? ' original-login-client' : '')], {
  input: JSON.stringify(values), encoding: 'utf8', maxBuffer: 1024 * 1024,
});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
process.exit(result.status ?? 1);
