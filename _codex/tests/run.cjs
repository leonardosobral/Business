const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');

function testFiles(directory) {
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap(entry => {
    if (entry.name.startsWith('.') || entry.name === 'node_modules') return [];
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) return testFiles(file);
    return /\.test\.(?:js|cjs|mjs)$/.test(entry.name) ? [file] : [];
  });
}

const files = testFiles(__dirname).sort();
if (!files.length) throw new Error('No Node tests found');
const result = spawnSync(process.execPath, ['--test', ...process.argv.slice(2), ...files], {
  cwd: path.resolve(__dirname, '../..'),
  stdio: 'inherit'
});
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
