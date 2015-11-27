type t = (* MinCamlの構文を表現するデータ型 (caml2html: syntax_t) *)
  | Unit of Lexing.position
  | Bool of bool * Lexing.position
  | Int of int * Lexing.position
  | Float of float * Lexing.position
  | Not of t * Lexing.position
  | Neg of t * Lexing.position
  | Add of t * t * Lexing.position
  | Sub of t * t * Lexing.position
  | Mul of t * t * Lexing.position
  | Div of t * t * Lexing.position
  | FNeg of t * Lexing.position
  | FAdd of t * t * Lexing.position
  | FSub of t * t * Lexing.position
  | FMul of t * t * Lexing.position
  | FDiv of t * t * Lexing.position
  | Eq of t * t * Lexing.position
  | LE of t * t * Lexing.position
  | If of t * t * t * Lexing.position
  | Let of (Id.t * Type.t) * t * t * Lexing.position
  | Var of Id.t * Lexing.position
  | LetRec of fundef * t * Lexing.position
  | App of t * t list * Lexing.position
  | Tuple of t list * Lexing.position
  | LetTuple of (Id.t * Type.t) list * t * t * Lexing.position
  | Array of t * t * Lexing.position
  | Get of t * t * Lexing.position
  | Put of t * t * t * Lexing.position
and fundef = { name : Id.t * Type.t; args : (Id.t * Type.t) list; body : t }

let pos_of_exp = function
    Unit p
  | Bool (_, p) | Int (_, p) | Float (_, p)
  | Not (_, p) | Neg (_, p) | Add (_, _, p) | Sub (_, _, p) | Mul (_, _, p) | Div (_, _, p)
  | FNeg (_, p) | FAdd (_, _, p) | FSub (_, _, p) | FMul (_, _, p) | FDiv (_, _, p)
  | Eq (_, _, p) | LE (_, _, p) | If (_, _, _, p)
  | Let (_, _, _, p) | Var (_, p) | LetRec (_, _, p)
  | App (_, _, p) | Tuple (_, p) | LetTuple (_, _, _, p)
  | Array (_, _, p) | Get (_, _, p) | Put (_, _, _, p) -> p
