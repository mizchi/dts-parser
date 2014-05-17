fs = require('fs');
Parser = require('./src/parser');
TopModule = require('./src/nodes').TopModule;

exports.parse = function(fpath) {
  source = fs.readFileSync(fpath).toString();
  parser = new Parser;
  ast = parser.parse(source);
  top = new TopModule(ast._sourceUnit);
  return top.toJSON();
}
