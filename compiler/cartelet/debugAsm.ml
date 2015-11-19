(** for cartelet v1 *)
open Asm

let margin = 192
let max_indent = 48

(* id_emit : Id.t -> unit *)
let id_emit id = Format.print_string id

(* id_list_iter : Id.t list -> unit *)
let rec id_list_iter = function
    [] -> ()
  | [id]    -> Format.print_string id
  | id :: l -> (Format.print_string id;
		Format.print_space ();
		id_list_iter l)

(* label_emit : Id.l -> unit *)
let label_emit (Id.L l) = Format.print_string l

(* type_emit : Type.t -> unit *)
let rec type_emit = function
    Type.Unit    -> Format.print_string "u"
  | Type.Bool    -> Format.print_string "b"
  | Type.Int     -> Format.print_string "i"
  | Type.Float   -> Format.print_string "d"
  | Type.Fun _   -> Format.print_string "f"
  | Type.Tuple _ -> Format.print_string "t"
  | Type.Array _ -> Format.print_string "a"
  | Type.Var rt  -> (Format.print_string "v{";
		     (match !rt with
		      | None   -> Format.print_string "None"
		      | Some t -> type_emit t);
		     Format.print_string "}")

(* id_or_imm_emit : Asm.id_or_imm -> unit *)
let id_or_imm_emit = function
    Asm.V id -> id_emit id
  | Asm.C i  -> Format.print_int i

(* asm_emit : Asm.t -> unit *)
let rec asm_emit p =
  (Format.open_vbox 0;
   asm_iter p;
   Format.close_box ())
(* asm_iter : Asm.t -> unit *)
and asm_iter = function
    Asm.Ans e ->
     (Format.open_vbox 2;
      Format.print_string "Ans";
      Format.print_space ();
      exp_iter e;
      Format.close_box ())
  | Asm.Let ((id, ty), e, t) ->
     (Format.open_vbox 2;
      (* 識別子 *)
      Format.open_hbox ();
      Format.print_string "Let";
      Format.print_space ();
      id_emit id;
      Format.print_space ();
      Format.print_string ":";
      Format.print_space ();
      type_emit ty;
      Format.close_box ();
      Format.print_space ();
      (* 命令列 *)
      exp_iter e;
      Format.close_box ();
      Format.print_space ();
      asm_iter t)
(* exp_iter : Asm.exp -> unit *)
and exp_iter e =
  begin
    (match e with
     | Asm.Nop p -> Format.print_string "Nop"
     | Asm.Set (i, p) ->
	(Format.open_hbox ();
	 Format.print_string "Set";
	 Format.print_space ();
	 Format.print_int i;
	 Format.close_box ())
     | Asm.SetL (l, p) ->
	(Format.open_hbox ();
	 Format.print_string "SetL";
	 Format.print_space ();
	 label_emit l;
	 Format.close_box ())
     | Asm.Mov (id, p) -> monop_emit "Mov" id
     | Asm.Neg (id, p) -> monop_emit "Neg" id
     | Asm.Add (id, idimm, p) -> binop_imm_emit "Add" id idimm
     | Asm.Sub (id, idimm, p) -> binop_imm_emit "Sub" id idimm
     | Asm.Mul (id, idimm, p) -> binop_imm_emit "Mul" id idimm
     | Asm.Div (id, idimm, p) -> binop_imm_emit "Div" id idimm
     | Asm.Ld (id, idimm, i, p) ->
	(Format.open_hbox ();
	 Format.print_string "Ld";
	 Format.print_space ();
	 id_emit id;
	 Format.print_space ();
	 id_or_imm_emit idimm;
	 Format.print_space ();
	 Format.print_int i;
	 Format.close_box ())
     | Asm.St (id0, id1, idimm, i, p) ->
	(Format.open_hbox ();
	 Format.print_string "St";
	 Format.print_space ();
	 id_emit id0;
	 Format.print_space ();
	 id_emit id1;
	 Format.print_space ();
	 id_or_imm_emit idimm;
	 Format.print_space ();
	 Format.print_int i;
	 Format.close_box ())
     | Asm.FMov (id, p) -> monop_emit "FMovD" id
     | Asm.FNeg (id, p) -> monop_emit "FNegD" id
     | Asm.FAdd (id0, id1, p) -> binop_id_emit "FAddD" id0 id1
     | Asm.FSub (id0, id1, p) -> binop_id_emit "FSubD" id0 id1
     | Asm.FMul (id0, id1, p) -> binop_id_emit "FMulD" id0 id1
     | Asm.FDiv (id0, id1, p) -> binop_id_emit "FDivD" id0 id1
     | Asm.LdF (id, idimm, i, p) ->
	(Format.open_hbox ();
	 Format.print_string "LdDF";
	 Format.print_space ();
	 id_emit id;
	 Format.print_space ();
	 id_or_imm_emit idimm;
	 Format.print_space ();
	 Format.print_int i;
	 Format.close_box ())
     | Asm.StF (id0, id1, idimm, i, p) ->
	(Format.open_hbox ();
	 Format.print_string "StDF";
	 Format.print_space ();
	 id_emit id0;
	 Format.print_space ();
	 id_emit id1;
	 Format.print_space ();
	 id_or_imm_emit idimm;
	 Format.print_space ();
	 Format.print_int i;
	 Format.close_box ())
     | Asm.Comment (str, p) ->
	(Format.open_box 1;
	 Format.print_string "; ";
	 Format.print_string str;
	 Format.close_box ())
     | Asm.IfEq (id, idimm, t0, t1, p) -> ifint_emit "IfEq" id idimm t0 t1
     | Asm.IfLE (id, idimm, t0, t1, p) -> ifint_emit "IfLE" id idimm t0 t1
     | Asm.IfGE (id, idimm, t0, t1, p) -> ifint_emit "IfGE" id idimm t0 t1
     | Asm.IfFEq (id0, id1, t0, t1, p) -> iffloat_emit "IfFEq" id0 id1 t0 t1
     | Asm.IfFLE (id0, id1, t0, t1, p) -> iffloat_emit "IfFLE" id0 id1 t0 t1
     | Asm.CallCls (id, iargs, fargs, p) -> 
	(Format.open_hbox ();
	 Format.print_string "CallCls";
	 Format.print_space ();
	 id_emit id;
	 Format.print_space ();
	 Format.print_string "[";
	 id_list_iter iargs;
	 Format.print_string "]";
	 Format.print_space ();
	 Format.print_string "[";
	 id_list_iter fargs;
	 Format.print_string "]";
	 Format.print_space ();
	 Format.close_box ())
     | Asm.CallDir (label, iargs, fargs, p) -> 
	(Format.open_hbox ();
	 Format.print_string "CallDir";
	 Format.print_space ();
	 label_emit label;
	 Format.print_space ();
	 Format.print_string "[";
	 id_list_iter iargs;
	 Format.print_string "]";
	 Format.print_space ();
	 Format.print_string "[";
	 id_list_iter fargs;
	 Format.print_string "]";
	 Format.print_space ();
	 Format.close_box ())
     | Asm.Save (id0, id1, p) ->
	(Format.open_hbox ();
	 Format.print_string "Save";
	 Format.print_space ();
	 id_emit id0;
	 Format.print_space ();
	 id_emit id1;
	 Format.close_box ())
     | Asm.Restore (id, p) ->
	(Format.open_hbox ();
	 Format.print_string "Restore";
	 Format.print_space ();
	 id_emit id;
	 Format.close_box ())
    )
  end
(* monop_emit : string -> Id.t -> unit *)
and monop_emit name id =
  (Format.open_hbox ();
   Format.print_string name;
   Format.print_space ();
   id_emit id;
   Format.close_box ())
(* binop_imm_emit : string -> Id.t -> Id.id_or_imm -> unit *)
and binop_imm_emit name id idimm =
  (Format.open_hbox ();
   Format.print_string name;
   Format.print_space ();
   id_emit id;
   Format.print_space ();
   id_or_imm_emit idimm;
   Format.close_box ())
(* binop_id_emit : string -> Id.t -> Id.t -> unit *)
and binop_id_emit name id0 id1 =
  (Format.open_hbox ();
   Format.print_string name;
   Format.print_space ();
   id_emit id0;
   Format.print_space ();
   id_emit id1;
   Format.close_box ())
(* ifint_emit : string -> Id.t -> Asm.id_or_imm -> Asm.t -> Asm.t -> unit *)
and ifint_emit name id idimm t0 t1 =
  (Format.open_vbox 2;
   Format.open_hbox ();
   Format.print_string name;
   Format.print_space ();
   (* 条件式 *)
   id_emit id;
   Format.print_space ();
   id_or_imm_emit idimm;
   Format.close_box ();
   Format.print_space ();
   (* TRUE節 *)
   asm_iter t0;
   Format.close_box ();
   Format.print_space ();
   (* FALSE節 *)
   Format.open_vbox 2;
   Format.print_string "ELSE";
   Format.print_space ();
   asm_iter t1;
   Format.close_box ())
(* iffloat_emit : string -> Id.t -> Id.t -> Asm.t -> Asm.t -> unit *)
and iffloat_emit name id0 id1 t0 t1 =
  (Format.open_vbox 2;
   Format.open_hbox ();
   Format.print_string name;
   Format.print_space ();
   (* 条件式 *)
   id_emit id0;
   Format.print_space ();
   id_emit id1;
   Format.close_box ();
   Format.print_space ();
   (* TRUE節 *)
   asm_iter t0;
   Format.close_box ();
   (* FALSE節 *)
   Format.open_vbox 2;
   Format.print_string "ELSE";
   Format.print_space ();
   asm_iter t1;
   Format.close_box ())

(* float_table_iter : (Id.l * float) list -> unit *)
let rec float_table_iter = function
    [] -> ()
  | [(l, f)] -> (Format.open_hbox ();
		 Format.print_string "(";
		 label_emit l;
		 Format.print_string ",";
		 Format.print_space ();
		 Format.print_float f;
		 Format.print_string ")";
		 Format.close_box ())
  | (l, f) :: lst -> (Format.open_hbox ();
		      Format.print_string "(";
		      label_emit l;
		      Format.print_string ",";
		      Format.print_space ();
		      Format.print_float f;
		      Format.print_string ")";
		      Format.close_box ();
		      Format.print_space ();
		      float_table_iter lst)

(* fundef_emit : Asm.fundef -> unit *)
let fundef_emit { name = l; args = args; fargs = fargs; body = t; ret = ty} =
  (Format.open_vbox 1;
   Format.print_string "{name = ";
   label_emit l;
   Format.print_space ();
   Format.open_hbox ();
   Format.print_string "args = [";
   id_list_iter args;
   Format.print_string "]";
   Format.close_box ();
   Format.print_space ();
   Format.open_hbox ();
   Format.print_string "fargs = [";
   id_list_iter fargs;
   Format.print_string "]";
   Format.close_box ();
   Format.print_space ();
   Format.open_vbox 2;
   Format.print_string "body = ";
   Format.print_space ();
   asm_emit t;
   Format.close_box ();
   Format.print_space ();
   Format.print_string "ret = ";
   type_emit ty;
   Format.print_string "}";
   Format.close_box ())

(* fundef_list_iter : Asm.fundef list -> unit *)
let rec fundef_list_iter = function
    [] -> ()
  | [fd] -> fundef_emit fd
  | fd :: l -> (fundef_emit fd;
		Format.print_space ();
		fundef_list_iter l)

(* asm_prog_emit : out_channel -> Asm.prog -> unit *)
let asm_prog_emit oc (Prog (float_table, toplevel_funcs, t)) =
  (Format.set_formatter_out_channel oc;
   Format.set_margin margin;
   Format.set_max_indent max_indent;
   Format.open_vbox 0;
   (* 浮動小数点数テーブル *)
   Format.print_string "; Table of floats";
   Format.print_space ();
   Format.open_hbox ();
   Format.print_string "[";
   float_table_iter float_table;
   Format.print_string "]";
   Format.close_box ();
   Format.print_space ();
   (* トップレベル関数 *)
   Format.print_string "; Toplevel_functions";
   Format.print_space ();
   fundef_list_iter toplevel_funcs;
   Format.print_space ();
   (* メインの式 *)
   Format.print_string "; Main";
   Format.print_space ();
   asm_emit t;
   Format.print_space ();
   Format.close_box ();
   Format.print_flush ())
