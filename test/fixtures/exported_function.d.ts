declare module Foo {
    export function fun(str: string):void;
    export function funfun(str: string):void;
    export var a:number, b: Object;
    export var c: Object;
    export class Bar {
        f():string;
        x: any;
    }
}

export class X {}
export var x: any;

/*
moduleName: Top
modules:
  -
    moduleName: Foo
    modules:
      (empty array)
    classes:
      -
        className:  Bar
        properties:
          -
            typeAnnotation:
              annotationType: functionType
              returnTypeName: String
              arguments:
                (empty array)
          -
            propertyName:   x
            typeAnnotation:
              nodeType: identifierType
              typeName: Any
    properties:
      -
        propertyName:   fun
        typeAnnotation:
          annotationType: functionType
          returnTypeName: Void
          arguments:
            -
              identifierName: str
              typeAnnotation: String
      -
        propertyName:   funfun
        typeAnnotation:
          annotationType: functionType
          returnTypeName: Void
          arguments:
            -
              identifierName: str
              typeAnnotation: String
      -
        propertyName:
          - a
        typeAnnotation:
          nodeType: identifierType
          typeName: Number
      -
        propertyName:
          - b
        typeAnnotation:
          nodeType: identifierType
          typeName: Object
      -
        propertyName:
          - c
        typeAnnotation:
          nodeType: identifierType
          typeName: Object
classes:
  -
    className:  X
    properties:
      (empty array)
properties:
  -
    propertyName:
      - x
    typeAnnotation:
      nodeType: identifierType
      typeName: Any
*/
