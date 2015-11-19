type t =
  | Unit of Lexing.position
  | Int of int * Lexing.position
  | Float of float * Lexing.position
  | Neg of Id.t * Lexing.position
  | Add of Id.t * Id.t * Lexing.position
  | Sub of Id.t * Id.t * Lexing.position
  | Mul of Id.t * Id.t * Lexing.position
  | Div of Id.t * Id.t * Lexing.position
  | FNeg of Id.t * Lexing.position
  | FAdd of Id.t * Id.t * Lexing.position
  | FSub of Id.t * Id.t * Lexing.position
  | FMul of Id.t * Id.t * Lexing.position
  | FDiv of Id.t * Id.t * Lexing.position
  | IfEq of Id.t * Id.t * t * t * Lexing.position
  | IfLE of Id.t * Id.t * t * t * Lexing.position
  | Let of (Id.t * Type.t) * t * t * Lexing.position
  | Var of Id.t * Lexing.position
  | LetRec of fundef * t * Lexing.position
  | App of Id.t * Id.t list * Lexing.position
  | Tuple of Id.t list * Lexing.position
  | LetTuple of (Id.t * Type.t) list * Id.t * t * Lexing.position
  | Get of Id.t * Id.t * Lexing.position
  | Put of Id.t * Id.t * Id.t * Lexing.position
  | ExtArray of Id.t * Lexing.position
  | ExtFunApp of Id.t * Id.t list * Lexing.position
and fundef = { name : Id.t * Type.t; args : (Id.t * Type.t) list; body : t }

val fv : t -> S.t
val f : Syntax.t -> t
