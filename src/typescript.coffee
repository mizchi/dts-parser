fs = require 'fs'
eval fs.readFileSync(__dirname+'/../node_modules/typescript/bin/typescript.js').toString()
module.exports = TypeScript
