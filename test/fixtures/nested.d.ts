module A.B {
    export interface Point<T> {
        x : number;
        y : number;
    }
}
module A {
    export var array: A.B.Point<Object>[];
}
