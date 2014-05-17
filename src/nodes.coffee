$ = require('jsonselect').match
pj = require 'prettyjson'
p = (obj) -> console.log pj.render obj, noColor: false
TypeScript = require './typescript'

mapClass = (Class, arr) -> arr.map (i) -> new Class(i)

tokenKindToTypeKeyword = (tokenKind) ->
  for key, val of TypeScript.SyntaxKind
    if val is tokenKind then return key
  ''

tokenKindToTypeName = (tokenKind)->
  keyword = tokenKindToTypeKeyword(tokenKind)
  switch keyword
    when 'StringKeyword' then 'String'
    when 'NumberKeyword' then 'Number'
    when 'BooleanKeyword' then 'Boolean'
    when 'IdentifierName' then 'Identifier'

exports.Node = Node = class Node
  constructor: (@ast) ->

  $: (query) -> $ query, @ast

  $first: (query) -> @$(query)[0]

  _modules: ->
    item = @$(":root > .moduleElements > .item")
    if item.length > 0 then item
    else @$first(":root > .moduleElements > .nodeOrTokens")


exports.Function = Function = class Function extends Node
  constructor: (@ast) ->

  propertyName: -> @$first(':root > .propertyName > ._fullText')

  getType: ->
    args =  @arguments()
    identifiers = mapClass Identifier, args
    args = identifiers.map (ident) =>
      identifierName: ident.identifierName()
      typeAnnotation: ident.typeAnnotation()

    # return type
    returnTypeTokenKind = @$first(':root > .callSignature > .typeAnnotation > .type > .tokenKind')
    typeName = tokenKindToTypeName returnTypeTokenKind
    returnTypeName =
      if typeName is 'Identifier'
        @$first(':root > .typeAnnotation > .type > ._fullText')
      else
        typeName
    {
      nodeType: 'functionType'
      returnTypeName: returnTypeName
      arguments: args
    }

  arguments: (query) ->
    header = ":root > .callSignature > .parameterList > .parameters"
    item = @$(header + '> .item')
    if item.length > 0 then item
    else @$first(header+'> .elements').filter (i) -> i.identifier?

exports.Identifier = Identifier = class Identifier extends Node
  '''
  Example: str:string
    _data:             0
    dotDotDotToken:    null
    modifiers:

    identifier:
      _fullText: str
      tokenKind: 11
    questionToken:     null
    typeAnnotation:
      _data:      0
      colonToken:
        tokenKind: 106
      type:
        tokenKind: 69
    equalsValueClause: null
  '''
  constructor: (@ast) ->

  identifierName: -> @$first(':root > .identifier > ._fullText')

  typeAnnotation: ->
    tokenKind = @$first(':root > .typeAnnotation > .type > .tokenKind')
    console.log tokenKind
    # typeName = Type.tokenKindToTypeName(tokenKind)
    typeName = tokenKindToTypeName(tokenKind)
    if typeName is 'Identifier'
      @$first(':root > .typeAnnotation > .type > ._fullText')
    else
      typeName

exports.Property = Property = class Property extends Node
  constructor: (@ast) ->

  propertyName: -> @$first(':root > .variableDeclarator > .propertyName > ._fullText') ? @$first(':root > .propertyName > ._fullText')

  isFunction: -> !!@$first(':root .callSignature')

  arguments: (query) ->
    header = ":root > .callSignature > .parameterList > .parameters"
    item = @$(header + '> .item')
    if item.length > 0 then item
    else @$first(header+'> .elements').filter (i) -> i.identifier?

  getType: ->
    if @isFunction()
      args =  @arguments()
      identifiers = mapClass Identifier, args
      args = identifiers.map (ident) =>
        identifierName: ident.identifierName()
        typeAnnotation: ident.typeAnnotation()

      # return type
      returnTypeTokenKind = @$first(':root > .callSignature > .typeAnnotation > .type > .tokenKind')
      typeName = tokenKindToTypeName returnTypeTokenKind
      returnTypeName =
        if typeName is 'Identifier'
          @$first(':root > .typeAnnotation > .type > ._fullText')
        else
          typeName
      return {
        nodeType: 'functionType'
        returnTypeName: returnTypeName
        arguments: args
      }

    else
      tokenKind = @$first(':root > .variableDeclarator > .typeAnnotation > .type > .tokenKind')
      typeName = tokenKindToTypeName(tokenKind)
      typeName =
        if typeName is 'Identifier'
          @$first('.variableDeclarator > .typeAnnotation > .type > ._fullText')
        else
          typeName
      return {
        nodeType: 'identifierType'
        typeName: typeName
      }

  toJSON: ->
    propertyName: @propertyName()
    typeAnnotation: @getType()

exports.Class = Class = class Class extends Node
  constructor: (@ast) ->

  getProperties: ->
    mapClass Property, @_classElements()

  _classElements: ->
    item = @$(":root > .classElements > .item")
    if item.length > 0 then item
    else @$first(":root > .classElements > .nodeOrTokens") or []

  className: -> @$(':root > .identifier > ._fullText')?[0]

  toJSON: ->
    className: @className()
    properties: @getProperties().map (p) -> p.toJSON()

exports.Module = Module = class Module extends Node

  constructor: (@ast) ->

  moduleName: -> @$first(':root > .item > .name > ._fullText') or @$first(':root .name > ._fullText')

  getModules: ->
    mods = @_modules()
    mods = $(':root > *:has(.moduleKeyword)', mods)
    mapClass Module, mods

  getClasses: ->
    mods = @_modules()
    mods = $(':root > *:has(.classKeyword)', mods)
    mapClass Class, mods

  getFunctions: ->
    mods = @_modules()
    mods = $(':root > *:has(.functionKeyword)', mods)
    mapClass Class, mods

  toJSON: ->
    moduleName: @moduleName()
    modules: @getModules().map (m) -> m.toJSON()
    classes: @getClasses().map (c) -> c.toJSON()
    functions: @getFunctions()

exports.Root = Root = class Root extends Module
  constructor: (@ast) ->
