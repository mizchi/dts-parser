$ = require('jsonselect').match
pj = require 'prettyjson'
p = (obj) -> console.log pj.render obj, noColor: false
TypeScript = require './typescript'

mapClass = (Class, arr) -> arr.map (i) -> new Class(i)

exports.Node = Node = class Node
  constructor: (@ast) ->

  $: (query) -> $ query, @ast

  $first: (query) -> @$(query)[0]

  _modules: ->
    item = @$(":root > .moduleElements > .item")
    if item.length > 0 then item
    else @$first(":root > .moduleElements > .nodeOrTokens")

  getModules: ->
    mods = @_modules()
    mods = $(':root > *:has(.moduleKeyword)', mods)
    mapClass Module, mods

  getClasses: ->
    mods = @_modules()
    mods = $(':root > *:has(.classKeyword)', mods)
    mapClass Class, mods

exports.Property = Property = class Property extends Node
  constructor: (@ast) ->

  propertyName: -> @$first(':root > .variableDeclarator > .propertyName > ._fullText')

  typeName: ->
    console.log @_typeKeywordName()
    switch @_typeKeywordName()
      when 'StringKeyword' then 'String'
      when 'NumberKeyword' then 'Number'
      when 'BooleanKeyword' then 'Boolean'
      when 'IdentifierName' # then 'Boolean'
        @$first('.variableDeclarator > .typeAnnotation > .type > ._fullText')

  _typeKeywordName: ->
    for key, val of TypeScript.SyntaxKind
      if val is @_typeTokenKind() then return key
    ''

  _typeTokenKind: -> @$first(':root > .variableDeclarator > .typeAnnotation > .type > .tokenKind')

  toJSON: ->
    propertyName: @propertyName()
    typeName: @typeName()

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

  toJSON: ->
    name: @moduleName()
    type: 'module'
    modules: @getModules().map (m) -> m.toJSON()
    classes: @getClasses().map (c) -> c.toJSON()

exports.Root = Root = class Root extends Node
  constructor: (@ast) ->
  toJSON: ->
    modules: do =>
      modules = @getModules()
      for m in @getModules()
        m.toJSON()
