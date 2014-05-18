fs = require 'fs'
pj = require 'prettyjson'
p = (obj) -> console.log pj.render obj, noColor: true

Parser = require './parser'
{TopModule} = require './nodes'

argv = require('optimist')
  .boolean('nc')
  .alias('c', 'nc')
  .boolean('json')
  .alias('j', 'json')
  .argv

output = (source) ->
  if argv.json
    console.log JSON.stringify source
  else
    console.log pj.render source, noColor: argv.nc

exports.show = ->
  source = fs.readFileSync(argv._[0]).toString()
  parser = new Parser
  ast = parser.parse(source)
  top = new TopModule ast._sourceUnit
  reports = top.toJSON()
  output reports
