fs = require 'fs'
path = require 'path'
pj = require 'prettyjson'
p = (obj) -> console.log pj.render obj, noColor: true

Parser = require './parser'
{TopModule} = require './nodes'

argv = require('optimist')
  .boolean('nc')
  .boolean('tsast')
  .alias('c', 'nc')
  .alias('o', 'out')
  .alias('w', 'write')
  .boolean('write')
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

  if argv.tsast
    output ast
    return

  top = new TopModule ast._sourceUnit

  if argv.write
    outpath = (path.join (argv.out ? ''), path.basename(argv._[0]))+'.json'
    fs.writeFileSync outpath, JSON.stringify(top.toJSON())
    console.log argv._[0], '->',outpath
  else
    reports = top.toJSON()
    output reports
