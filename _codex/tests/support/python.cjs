const fs = require('node:fs');
const path = require('node:path');

const virtualenv = path.resolve(__dirname, '..', '.venv',
  process.platform === 'win32' ? 'Scripts/python.exe' : 'bin/python3');
module.exports = process.env.PYTHON || (fs.existsSync(virtualenv) ? virtualenv : 'python3');
