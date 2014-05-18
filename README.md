# dts-parser

TypeScript d.ts parser(wip)

## Features

- [x] module
- [x] nested module
- [x] class
- [ ] extends
- [ ] implement
- [x] variable declaration
- [x] string/number/boolean/any/lambda
- [ ] nullable?
- [x] function
- [x] interface
- [x] generics declaration in class, interface, function
- [ ] generics application
- [ ] List like T[]

## Examples

examples/dummy.d.ts

```typescript
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
```

Exec

```
$ npm install
$ ./bin/dts-parser examples/dummy.d.ts
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
```

from code

```coffee
parser = require 'dts-parser'
console.log parser.parse('dummy.d.ts')
```

API will be changed soon
