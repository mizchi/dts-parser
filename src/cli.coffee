fs = require 'fs'
pj = require 'prettyjson'
p = (obj) -> console.log pj.render obj, noColor: false

Parser = require './parser'
{TopModule} = require './nodes'

exports.show = (fpath)->
  source = fs.readFileSync(fpath).toString()
  parser = new Parser
  ast = parser.parse(source)
  top = new TopModule ast._sourceUnit
  reports = top.toJSON()
  console.log '/------------------/'
  p reports
