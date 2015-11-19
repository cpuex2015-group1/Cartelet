type id_or_imm = V of Id.t | C of int
type t =
  | Ans of exp
  | Let of (Id.t * Type.t) * exp * t
and exp =
  | Nop of Lexing.position
  | Set of int * Lexing.position
  | SetL of Id.l * Lexing.position
  | Mov of Id.t * Lexing.position
  | Neg of Id.t * Lexing.position
  | Add of Id.t * id_or_imm * Lexing.position
  | Sub of Id.t * id_or_imm * Lexing.position
  | Mul of Id.t * id_or_imm * Lexing.position
  | Div of Id.t * id_or_imm * Lexing.position
  | Ld of Id.t * id_or_imm * int * Lexing.position
  | St of Id.t * Id.t * id_or_imm * int * Lexing.position
  | FMov of Id.t * Lexing.position
  | FNeg of Id.t * Lexing.position
  | FAdd of Id.t * Id.t * Lexing.position
  | FSub of Id.t * Id.t * Lexing.position
  | FMul of Id.t * Id.t * Lexing.position
  | FDiv of Id.t * Id.t * Lexing.position
  | LdF of Id.t * id_or_imm * int * Lexing.position
  | StF of Id.t * Id.t * id_or_imm * int * Lexing.position
  | Comment of string * Lexing.position
  (* virtual instructions *)
  | IfEq of Id.t * id_or_imm * t * t * Lexing.position
  | IfLE of Id.t * id_or_imm * t * t * Lexing.position
  | IfGE of Id.t * id_or_imm * t * t * Lexing.position
  | IfFEq of Id.t * Id.t * t * t * Lexing.position
  | IfFLE of Id.t * Id.t * t * t * Lexing.position
  (* closure address, integer arguments, and float arguments *)
  | CallCls of Id.t * Id.t list * Id.t list * Lexing.position
  | CallDir of Id.l * Id.t list * Id.t list * Lexing.position
  | Save of Id.t * Id.t * Lexing.position(* レジスタ変数の値をスタック変数へ保存 *)
  | Restore of Id.t * Lexing.position (* スタック変数から値を復元 *)
type fundef = { name : Id.l; args : Id.t list; fargs : Id.t list; body : t; ret : Type.t }
type prog = Prog of (Id.l * float) list * fundef list * t

val fletd : Id.t * exp * t -> t (* shorthand of Let for float *)
val seq : exp * t -> t (* shorthand of Let for unit *)

val regs : Id.t array
val fregs : Id.t array
val allregs : Id.t list
val allfregs : Id.t list
val reg_cl : Id.t

val reg_sw : Id.t
val reg_fsw : Id.t

val reg_zero : Id.t
val reg_tmp : Id.t
val reg_ftmp : Id.t
val reg_rv : Id.t
val reg_frv : Id.t
val reg_hp : Id.t
val reg_sp : Id.t
val reg_ra : Id.t
val is_reg : Id.t -> bool

val fv : t -> Id.t list
val concat : t -> Id.t * Type.t -> t -> t

val align : int -> int

val pos_of_exp : exp -> Lexing.position
