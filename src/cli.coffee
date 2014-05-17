fs = require 'fs'
pj = require 'prettyjson'
p = (obj) -> console.log pj.render obj, noColor: false

Parser = require './parser'
{Root} = require './nodes'

exports.show = (fpath)->
  source = fs.readFileSync(fpath).toString()
  parser = new Parser
  ast = parser.parse(source)
  root = new Root ast._sourceUnit
  p root.toJSON()
  # console.log JSON.stringify scope.toJSON()
