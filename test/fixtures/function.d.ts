declare module Foo {
    export class Hoge {
        s: any;
        f1(str:string, n: number, obj: Object): number;
        f2: (str:string, n: number, obj: Object) => number;
    }
}
