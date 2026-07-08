const fs = require('fs');
const path = require('path');

const backendRoot = __dirname;

function requireLocal(moduleName) {
  const candidates = [
    path.join(backendRoot, 'src', moduleName),
    path.join(backendRoot, moduleName)
  ];

  for (const candidate of candidates) {
    const filePath = `${candidate}.js`;
    if (fs.existsSync(filePath)) {
      return require(filePath);
    }
  }

  throw new Error(`Cannot find module '${moduleName}' in src/ or backend root.`);
}

module.exports = {
  requireLocal
};
