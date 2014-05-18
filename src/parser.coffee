$ = require('JSONSelect').match
TypeScript = require './typescript'

module.exports = class DTSParser
  preprocess: (ast) ->
    [
      '_fullText'
      'typeKind'
    ].forEach (name) ->
      $(":has(.#{name})", ast).forEach (item) ->
        text = item[name]?.replace? /\s/g, ''
        item[name] = text

  parse: (source) ->
    source = source.replace /\/\*([\s\S]*?)\*\//g, ''
    source = source.replace /\/\/.*\n/g, ''

    ast = TypeScript.Parser.parse(
      'dummy.ts',
      TypeScript.SimpleText.fromString(source),
      true,
      new TypeScript.ParseOptions(TypeScript.LanguageVersion.EcmaScript5, true))
    @preprocess ast
    ast
