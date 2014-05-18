interface Identity<T, U> {}

class Cls<T, U> {}

interface Id {
  id<T>(t: Array<Array<T>>): number;
  idx(t: number): Array;
}
