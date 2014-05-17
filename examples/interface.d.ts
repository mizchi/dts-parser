export interface IFoo {
  s: string;
  f: (t:number) => Object;
}

declare module A {
  export interface IA {
    as: string;
    af: (t:number) => Object;
  }
}
