# dts-parser

TypeScript d.ts parser(wip)

## Features

- [x] module
- [x] classe
- [x] string/number
- [ ] interface
- [ ] function
- [ ] Generics

## Examples

examples/dummy.d.ts

```typescript
declare module Foo {
    export class Hoge {
        name: string;
        n: number;
        bool: boolean;
        obj: Object;
        arr: Array;
    }
}
```

Exec

```
$ npm install
$ ./bin/dts-parser examples/dummy.d.ts
modules:
  -
    name:    Foo
    type:    module
    modules:
      (empty array)
    classes:
      -
        className:  Hoge
        properties:
          -
            propertyName: name
            typeName:     String
          -
            propertyName: n
            typeName:     Number
          -
            propertyName: bool
            typeName:     Boolean
          -
            propertyName: obj
            typeName:     Object
          -
            propertyName: arr
            typeName:     Array
```

from code

```coffee
fs = require 'fs'
Parser = require './parser'
{Root} = require './nodes'

source = fs.readFileSync('dummy.d.ts').toString()
parser = new Parser
ast = parser.parse(source)
root = new Root ast._sourceUnit
console.log root.toJSON()
```
