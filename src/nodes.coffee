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
    when 'AnyKeyword' then 'Any'
    when 'VoidKeyword' then 'Void'
    when 'IdentifierName' then 'Identifier'

exports.Node = Node = class Node
  constructor: (@ast) ->

  $: (query) -> $ query, @ast

  $first: (query) -> @$(query)[0]

exports.FunctionNode = FunctionNode = class FunctionNode extends Node
  constructor: (@ast) ->

  propertyName: ->
    @$first(':root > .identifier > ._fullText')

  getType: ->
    args =  @arguments()
    identifiers = mapClass FunctionArgument, args
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
      annotationType: 'functionType'
      returnTypeName: returnTypeName
      arguments: args
    }

  arguments: (query) ->
    header = ":root > .callSignature > .parameterList > .parameters"
    item = @$(header + '> .item')
    if item.length > 0 then item
    else
      args = @$first(header+'> .elements')?.filter (i) -> i.identifier?
      args ?= []

  toJSON: ->
    propertyName: @propertyName()
    typeAnnotation: @getType()

exports.FunctionArgument = FunctionArgument = class FunctionArgument extends Node
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
    typeName = tokenKindToTypeName(tokenKind)
    typeName =
      if typeName is 'Identifier'
        @$first(':root > .typeAnnotation > .type > ._fullText')
      else
        typeName
    {
      annotationType: 'functionArgumentType'
      typeName: typeName
    }

exports.VariableNode = VariableNode = class VariableNode extends Node
  constructor: (@ast) ->

  propertyName: -> @$first(':root > .variableDeclarator > .propertyName > ._fullText')

  typeAnnotation: ->
    tokenKind = @$first(':root > .variableDeclarator > .typeAnnotation > .type > .tokenKind')
    typeName = tokenKindToTypeName(tokenKind)
    typeName =
      if typeName is 'Identifier'
        @$first('.variableDeclarator > .typeAnnotation > .type > ._fullText')
      else
        typeName
    return {
      annotationType: 'varialbleType'
      typeName: typeName
    }

  toJSON: ->
    propertyName: @propertyName()
    typeAnnotation: @typeAnnotation()


exports.Class = Class = class Class extends Node
  isFunctionNode = (node) -> node.callSignature?

  constructor: (@ast) ->

  getProperties: ->
    for el in @_classElements()
      if isFunctionNode(el)
        new FunctionNode(el)
      else
        new VariableNode(el)

  _classElements: ->
    item = @$(":root > .classElements > .item")
    if item.length > 0 then item
    else @$first(":root > .classElements > .nodeOrTokens") or []

  className: -> @$(':root > .identifier > ._fullText')?[0]

  toJSON: ->
    className: @className()
    properties: @getProperties().map (p) -> p.toJSON()

exports.VariableDeclarationNode = VariableDeclarationNode =
class VariableDeclarationNode extends Node
  toJSON: ->
    {
      propertyName: @$(':root > .propertyName > ._fullText')
      typeAnnotation: @typeAnnotation()
    }

  typeAnnotation: ->
    tokenKind = @$first(':root > .typeAnnotation > .type > .tokenKind')
    typeName = tokenKindToTypeName(tokenKind)
    typeName =
      if typeName is 'Identifier'
        @$first(':root > .typeAnnotation > .type > ._fullText')
      else
        typeName
    return {
      annotationType: 'variableDeclarationType'
      typeName: typeName
    }

exports.Module = Module = class Module extends Node

  constructor: (@ast) ->

  moduleName: -> @$first(':root > .item > .name > ._fullText') or @$first(':root .name > ._fullText')

  modules: ->
    item = @$(":root > .moduleElements > .item")
    if item.length > 0 then item
    else @$first(":root > .moduleElements > .nodeOrTokens")

  getModules: ->
    mods = @modules()
    mods = $(':root > *:has(.moduleKeyword)', mods)?.filter (m) -> m.moduleKeyword?
    mods ?= []
    mapClass Module, mods

  getClasses: ->
    mods = @modules()
    mods = $(':root > *:has(.classKeyword)', mods)?.filter (c) -> c.classKeyword?
    mods ?= []
    mapClass Class, mods

  getFunctions: ->
    mods = @modules()
    mods = $(':root > *:has(.functionKeyword)', mods)?.filter (f) -> f.functionKeyword?
    mods ?= []
    mapClass FunctionNode, mods

  getVariables: ->
    mods = @modules()
    mods = $(':root > *:has(:root .variableDeclaration)', mods)?.filter (v) -> v.variableDeclaration?

    items = []
    mods = mods.map (m) ->
      if elements = m.variableDeclaration.variableDeclarators.elements
        for el in elements when el.propertyName
          items.push el
      else if item = m.variableDeclaration.variableDeclarators.item
        items.push item
    mapClass VariableDeclarationNode, items

  getProperties: ->
    props = []
    [].concat(@getFunctions(), @getVariables())

  toJSON: ->
    moduleName: @moduleName()
    modules: @getModules().map (m) -> m.toJSON()
    classes: @getClasses().map (c) -> c.toJSON()
    properties: @getProperties().map (p) -> p.toJSON()

exports.TopModule = TopModule = class TopModule extends Module
  moduleName: -> 'Top'
  constructor: (@ast) ->
    # p @ast
