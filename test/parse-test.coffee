fs = require 'fs'
path = require 'path'
dts = require '../index'
assert = require 'assert'

targets = [
  'arrayable.d.ts'
  'comments.d.ts'
  'dot.d.ts'
  'dummy.d.ts'
  'exported_function.d.ts'
  'extends.d.ts'
  'function.d.ts'
  'generics.d.ts'
  'interface.d.ts'
  'multi_module.d.ts'
  'nullable.d.ts'
]

describe '#parse', ->
  targets.map (target) =>
    it target, ->
      preparsed = JSON.parse fs.readFileSync(path.join __dirname,'parsed/'+target+'.json').toString()
      source = fs.readFileSync(path.join __dirname ,'fixtures/'+target).toString()
      parsed = dts.parse(source)
      assert.equal JSON.stringify(parsed), JSON.stringify(preparsed)

      # FIXME: I want to use deepEqual but doesn't works comparing json
      # assert.deepEqual parsed, preparsed
