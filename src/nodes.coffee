$ = require('jsonselect').match
pj = require 'prettyjson'
p = (obj) -> console.log pj.render obj, noColor: false
TypeScript = require './typescript'

mapClass = (Class, arr) -> arr.map (i) -> new Class(i)

listToJSON = (list) -> list.map (i) -> i.toJSON()

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

typeToTypeName = (type) ->
  type._fullText ? tokenKindToTypeName type.tokenKind

isFunctionNode = (node) -> node.callSignature?

exports.Node = Node = class Node
  constructor: (@ast) ->

  $: (query) -> $ query, @ast

  $first: (query) -> @$(query)[0]

  toJSON: -> throw 'Not implemented'

class TypeParameter extends Node
  '''
    typeParameters:
      item:
        identifier:
          _fullText: T
          tokenKind: 11
        constraint: null
  '''
  constructor: (@ast) ->

  toJSON: ->
    header = ":root > .typeParameters"
    items = @$(header + '> .item')
    items =
      if items.length > 0 then items
      else
        items = @$first(header+'> .elements')?.filter (i) -> i.identifier?
        items ?= []
    items.map (i) ->
      {
        typeParameterName: i.identifier._fullText
        constraint: i.constraint
      }

class FunctionNode extends Node
  constructor: (@ast) ->

  propertyName: ->
    p @ast
    @$first(':root > .propertyName > ._fullText')

  typeAnnotation: ->
    args =  @arguments()
    functionArgs = mapClass FunctionArgument, args
    returnTypeName = typeToTypeName @$first(':root > .callSignature > .typeAnnotation > .type')

    {
      annotationType: 'functionType'
      returnTypeName: returnTypeName
      arguments: listToJSON functionArgs
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
    typeAnnotation: @typeAnnotation()

class LambdaFunctionAnnotation extends Node
  '''
  typeParameterList:      null
  parameterList:
    _data:           0
    openParenToken:
      tokenKind: 72
    parameters:
      item:
        _data:             0
        dotDotDotToken:    null
        modifiers:

        identifier:
          _fullText: t
          tokenKind: 11
        questionToken:     null
        typeAnnotation:
          _data:      0
          colonToken:
            tokenKind: 106
          type:
            tokenKind: 67
        equalsValueClause: null
    closeParenToken:
      _fullText:           )
      tokenKind:           73
      _trailingTriviaInfo: 4
  equalsGreaterThanToken:
    _fullText:           =>
    tokenKind:           85
    _trailingTriviaInfo: 4
  type:
    tokenKind: 67
  '''
  constructor: (@ast) ->

  arguments: (query) ->
    header = ":root > .parameterList > .parameters"
    item = @$(header + '> .item')
    if item.length > 0 then item
    else
      args = @$first(header+'> .elements')?.filter (i) -> i.identifier?
      args ?= []

  typeAnnotation: ->
    args =  @arguments()
    identifiers = mapClass FunctionArgument, args
    args = identifiers.map (ident) =>
      identifierName: ident.identifierName()
      typeAnnotation: ident.typeAnnotation()

    # return type
    returnTypeTokenKind = @$first(':root > .type > .tokenKind')
    typeName = tokenKindToTypeName returnTypeTokenKind
    returnTypeName =
      if typeName is 'Identifier'
        @$first(':root > .type > ._fullText')
      else
        typeName
    {
      annotationType: 'lambdaFunctionType'
      returnTypeName: returnTypeName
      arguments: args
    }
  toJSON: -> @typeAnnotation()

class FunctionArgument extends Node
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

  toJSON: ->
    identifierName: @identifierName()
    typeAnnotation: @typeAnnotation()

class VariableNode extends Node
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

    # labmda
    type = @$first(':root > .variableDeclarator > .typeAnnotation > .type')
    if type.parameterList?
      lambdaFunctionAnnotation = new LambdaFunctionAnnotation(type)
      return lambdaFunctionAnnotation.toJSON()
    else
      return {
        annotationType: 'varialbleType'
        typeName: typeName
      }

  toJSON: ->
    propertyName: @propertyName()
    typeAnnotation: @typeAnnotation()

class VariableDeclarationNode extends Node
  toJSON: ->
    {
      propertyName: @$first(':root > .propertyName > ._fullText')
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

    # labmda
    type = @$first(':root > .typeAnnotation > .type')
    if type.parameterList?
      lambdaFunctionAnnotation = new LambdaFunctionAnnotation(type)
      return lambdaFunctionAnnotation.toJSON()
    else
      return {
        annotationType: 'variableDeclarationType'
        typeName: typeName
      }

class ClassNode extends Node

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
    properties: listToJSON @getProperties()

class InterfaceNode extends Node
  '''
  _data:             0
  modifiers:
    item:
      _fullText:           export
      tokenKind:           47
      _trailingTriviaInfo: 4
  interfaceKeyword:
    _fullText:           interface
    tokenKind:           52
    _trailingTriviaInfo: 4
  identifier:
    _fullText:           IFoo
    tokenKind:           11
    _trailingTriviaInfo: 4
  typeParameterList: null
  heritageClauses:

  body:
    _data:           0
    openBraceToken:
      _fullText:           {
      tokenKind:           70
      _trailingTriviaInfo: 5
    typeMembers:
      _data:     0
      elements:
        -
          _data:          0
          propertyName:
            _fullText:          a
            tokenKind:          11
            _leadingTriviaInfo: 8
          questionToken:  null
          typeAnnotation:
            _data:      0
            colonToken:
              tokenKind: 106
            type:
              tokenKind: 60
        -
          _fullText:           ;
          tokenKind:           78
          _trailingTriviaInfo: 5
        -
          _data:          0
          propertyName:
            _fullText:          b
            tokenKind:          11
            _leadingTriviaInfo: 8
          questionToken:  null
          typeAnnotation:
            _data:      0
            colonToken:
              tokenKind: 106
            type:
              tokenKind: 67
        -
          _fullText:           ;
          tokenKind:           78
          _trailingTriviaInfo: 5
    closeBraceToken:
      _fullText:           }
      tokenKind:           71
      _trailingTriviaInfo: 5
  '''

  constructor: (@ast) ->

  interfaceName: -> @$first(':root > .identifier > ._fullText')

  properties: ->
    typeMembers = @$first(':root > .body > .typeMembers')
    props = []
    if typeMembers.elements?
      for el in typeMembers.elements when el.propertyName
        props.push el
    else if typeMembers.item?
      props.push typeMembers.item
    # []
    mapClass VariableDeclarationNode, props

  toJSON: ->
    if @ast.typeParameterList
      typeParameter = new TypeParameter(@ast.typeParameterList)
    {
      interfaceName: @interfaceName()
      properties: listToJSON @properties()
      typeParameters: typeParameter?.toJSON()
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
    mapClass ClassNode, mods

  getInterfaces: ->
    mods = @modules()
    mods = $(':root > *:has(.interfaceKeyword)', mods)?.filter (c) -> c.interfaceKeyword?
    mods ?= []
    mapClass InterfaceNode, mods

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
    modules   : listToJSON @getModules()
    classes   : listToJSON @getClasses()
    properties: listToJSON @getProperties()
    interfaces: listToJSON @getInterfaces()

exports.TopModule = TopModule = class TopModule extends Module
  moduleName: -> 'Top'
  constructor: (@ast) ->
    p @ast
