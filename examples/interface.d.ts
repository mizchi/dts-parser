export interface IFoo {
  s: string;
  f: (t:number) => Object;
}

export interface IEFoo extends IFOO {
  n : number;
}
