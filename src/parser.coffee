$ = require('jsonselect').match
TypeScript = require './typescript'

module.exports = class DTSParser
  preprocess: (ast) ->
    [
      '_fullText'
      'typeKind'
    ].forEach (name) ->
      $(":has(.#{name})", ast).forEach (item) ->
        item[name] = item[name]?.replace(/\s/g, '')

  parse: (source) ->
    ast = TypeScript.Parser.parse(
      'dummy.ts',
      TypeScript.SimpleText.fromString(source),
      true,
      new TypeScript.ParseOptions(TypeScript.LanguageVersion.EcmaScript5, true))
    @preprocess ast
    ast
