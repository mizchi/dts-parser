interface IF1{}
interface IF2<T>{}
export class A {};
export class B extends A implements IF1, IF2<Object> {}
