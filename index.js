fs = require('fs');
Parser = require('./src/parser');
Root = require('./src/nodes').Root;

exports.parse = function(fpath) {
  source = fs.readFileSync(fpath).toString();
  parser = new Parser;
  ast = parser.parse(source);
  root = new Root(ast._sourceUnit);
  return root.toJSON();
}
