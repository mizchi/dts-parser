declare module Foo {
    export function fun(str?: number[]):void;
    export var a:number;
    export class Bar {
        x: any;
    }
}

export class X {}
export var x: any;

export interface IFoo {
  s: string;
  f: (t:number) => Object[];
}

export interface IFoo2 extends IFOO {
  n : number;
}
