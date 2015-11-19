(* 2オペランドではなく3オペランドのx86アセンブリもどき *)

type id_or_imm = V of Id.t | C of int
type t = (* 命令の列 (caml2html: sparcasm_t) *)
  | Ans of exp
  | Let of (Id.t * Type.t) * exp * t
and exp = (* 一つ一つの命令に対応する式 (caml2html: sparcasm_exp) *)
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
  | FMovD of Id.t * Lexing.position
  | FNegD of Id.t * Lexing.position
  | FAddD of Id.t * Id.t * Lexing.position
  | FSubD of Id.t * Id.t * Lexing.position
  | FMulD of Id.t * Id.t * Lexing.position
  | FDivD of Id.t * Id.t * Lexing.position
  | LdDF of Id.t * id_or_imm * int * Lexing.position
  | StDF of Id.t * Id.t * id_or_imm * int * Lexing.position
  | Comment of string * Lexing.position
  (* virtual instructions *)
  | IfEq of Id.t * id_or_imm * t * t * Lexing.position
  | IfLE of Id.t * id_or_imm * t * t * Lexing.position
  | IfGE of Id.t * id_or_imm * t * t  * Lexing.position(* 左右対称ではないので必要 *)
  | IfFEq of Id.t * Id.t * t * t * Lexing.position
  | IfFLE of Id.t * Id.t * t * t * Lexing.position
  (* closure address, integer arguments, and float arguments *)
  | CallCls of Id.t * Id.t list * Id.t list * Lexing.position
  | CallDir of Id.l * Id.t list * Id.t list * Lexing.position
  | Save of Id.t * Id.t  * Lexing.position(* レジスタ変数の値をスタック変数へ保存 (caml2html: sparcasm_save) *)
  | Restore of Id.t  * Lexing.position(* スタック変数から値を復元 (caml2html: sparcasm_restore) *)
type fundef = { name : Id.l; args : Id.t list; fargs : Id.t list; body : t; ret : Type.t }
(* プログラム全体 = 浮動小数点数テーブル + トップレベル関数 + メインの式 (caml2html: sparcasm_prog) *)
type prog = Prog of (Id.l * float) list * fundef list * t

let fletd(x, e1, e2) = Let((x, Type.Float), e1, e2)
let seq(e1, e2) = Let((Id.gentmp Type.Unit, Type.Unit), e1, e2)

let regs = (* Array.init 16 (fun i -> Printf.sprintf "%%r%d" i) *)
  [| "%eax"; "%ebx"; "%ecx"; "%edx"; "%esi"; "%edi" |]
let fregs = Array.init 8 (fun i -> Printf.sprintf "%%xmm%d" i)
let allregs = Array.to_list regs
let allfregs = Array.to_list fregs
let reg_cl = regs.(Array.length regs - 1) (* closure address (caml2html: sparcasm_regcl) *)
(*
let reg_sw = regs.(Array.length regs - 1) (* temporary for swap *)
let reg_fsw = fregs.(Array.length fregs - 1) (* temporary for swap *)
*)
let reg_sp = "%ebp" (* stack pointer *)
let reg_hp = "min_caml_hp" (* heap pointer (caml2html: sparcasm_reghp) *)
(* let reg_ra = "%eax" (* return address *) *)
let is_reg x = (x.[0] = '%' || x = reg_hp)

(* super-tenuki *)
let rec remove_and_uniq xs = function
  | [] -> []
  | x :: ys when S.mem x xs -> remove_and_uniq xs ys
  | x :: ys -> x :: remove_and_uniq (S.add x xs) ys

(* free variables in the order of use (for spilling) (caml2html: sparcasm_fv) *)
let fv_id_or_imm = function V(x) -> [x] | _ -> []
let rec fv_exp = function
  | Nop _ | Set _ | SetL _ | Comment _ | Restore _ -> []
  | Mov(x, _) | Neg(x, _) | FMovD(x, _) | FNegD(x, _) | Save(x, _, _) -> [x]
  | Add(x, y', _) | Sub(x, y', _) | Mul(x, y', _) | Div(x, y', _) | Ld(x, y', _, _) | LdDF(x, y', _, _) -> x :: fv_id_or_imm y'
  | St(x, y, z', _, _) | StDF(x, y, z', _, _) -> x :: y :: fv_id_or_imm z'
  | FAddD(x, y, _) | FSubD(x, y, _) | FMulD(x, y, _) | FDivD(x, y, _) -> [x; y]
  | IfEq(x, y', e1, e2, _) | IfLE(x, y', e1, e2, _) | IfGE(x, y', e1, e2, _) -> x :: fv_id_or_imm y' @ remove_and_uniq S.empty (fv e1 @ fv e2) (* uniq here just for efficiency *)
  | IfFEq(x, y, e1, e2, _) | IfFLE(x, y, e1, e2, _) -> x :: y :: remove_and_uniq S.empty (fv e1 @ fv e2) (* uniq here just for efficiency *)
  | CallCls(x, ys, zs, _) -> x :: ys @ zs
  | CallDir(_, ys, zs, _) -> ys @ zs
and fv = function
  | Ans(exp) -> fv_exp exp
  | Let((x, t), exp, e) ->
      fv_exp exp @ remove_and_uniq (S.singleton x) (fv e)
let fv e = remove_and_uniq S.empty (fv e)

let rec concat e1 xt e2 =
  match e1 with
  | Ans(exp) -> Let(xt, exp, e2)
  | Let(yt, exp, e1') -> Let(yt, exp, concat e1' xt e2)

let align i = (if i mod 8 = 0 then i else i + 4)

let pos_of_exp = function (* Asm.expからLexing.positionを抜き出す *)
    Nop(p)
  | Set(_, p) | SetL(_, p) | Mov(_, p)
  | Neg(_, p) | Add(_, _, p) | Sub(_, _, p) | Mul(_, _, p) | Div(_, _, p)
  | Ld(_, _, _, p) | St(_, _, _, _, p)
  | FMovD(_, p) | FNegD(_, p) | FAddD(_, _, p) | FSubD(_, _, p) | FMulD(_, _, p) | FDivD(_, _, p)
  | LdDF(_, _, _, p) | StDF(_, _, _, _, p)
  | Comment (_, p)
  | IfEq(_, _, _, _, p) | IfLE(_, _, _, _, p) | IfGE(_, _, _, _, p)
  | IfFEq(_, _, _, _, p) | IfFLE(_, _, _, _, p)
  | CallCls(_, _, _, p) | CallDir(_, _, _, p)
  | Save(_, _, p) | Restore(_, p) -> p
