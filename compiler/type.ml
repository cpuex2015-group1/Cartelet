type t = (* MinCamlの型を表現するデータ型 (caml2html: type_t) *)
  | Unit
  | Bool
  | Int
  | Float
  | Fun of t list * t (* arguments are uncurried *)
  | Tuple of t list
  | Array of t
  | Var of t option ref

let gentyp () = Var(ref None) (* 新しい型変数を作る *)

let rec string_of_type = function
    Unit -> "unit"
  | Bool -> "bool"
  | Int  -> "int"
  | Float -> "float"
  | Fun (lst, t) -> "(" ^ (string_of_fun lst) ^ " -> " ^ (string_of_type t) ^ ")"
  | Tuple lst    -> "(" ^ (string_of_tuple lst) ^ ")"
  | Array t      -> (string_of_type t) ^ " array"
  | Var r ->
     (match !r with
      | None   -> "var{None}"
      | Some t -> "var{" ^ (string_of_type t) ^ "}")
and string_of_fun = function
    [] -> ""
  | [t]    -> string_of_type t
  | t :: l -> (string_of_type t) ^ " -> " ^ (string_of_fun l)
and string_of_tuple = function
    [] -> ""
  | [t]    -> string_of_type t
  | t :: l -> (string_of_type t) ^ "; " ^ (string_of_tuple l)
