open Id
open Syntax
open KNormal
open Closure

let margin = 192
let max_indent = 48

type fundef_t   = FdSy of Syntax.t  | FdKn of KNormal.t
type lettuple_t = LtSy of Syntax.t  | LtId of Id.t
type all_t      = ASy of Syntax.t | AKn of KNormal.t | ACl of Closure.t
type let_t      = LKn of KNormal.t | LCl of Closure.t
type ifop_t     = IoKn of KNormal.t | IoCl of Closure.t

(* id_emit : Id.t -> unit *)
(* 識別子情報を表示する *)
let id_emit id = Format.print_string id

(* label_emit : Id.l -> unit *)
let label_emit (Id.L l) = Format.print_string l

(* type_emit : Type.t -> unit *)
(* 型情報を1文字で表示する *)
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

(* 
 * parser_emit用の関数
 *)
(* id_ty_list_iter : (Id.t * Type.t) list -> unit *)
let rec id_ty_list_iter = function
    [] -> ()
  | [(id, ty)] -> (Format.open_hbox ();
		   Format.print_string "(";
		   id_emit id;
		   Format.print_space ();
		   Format.print_string ":";
		   Format.print_space ();
		   type_emit ty;
		   Format.print_string ")";
		   Format.close_box ())
  | (id, ty) :: l -> (Format.open_hbox ();
		      Format.print_string "(";
		      id_emit id;
		      Format.print_space ();
		      Format.print_string ":";
		      Format.print_space ();
		      type_emit ty;
		      Format.print_string ");";
		      Format.close_box ();
		      Format.print_space ();
		      id_ty_list_iter l)

(* 
 * parser_emit関係
 *)
(* parser_emit : out_channel -> Syntax.t -> unit *)
(* pretty printer of Syntax.t *)
(* NB. Only this function changes out_channel to emitting Parser.t *)
let rec parser_emit oc s =
  (Format.set_formatter_out_channel oc;
   Format.set_margin margin;
   Format.set_max_indent max_indent;
   Format.open_vbox 0;
   parser_iter s;
   Format.print_space ();
   Format.close_box ();
   Format.print_flush ())
and parser_monop_emit name t =
  (Format.open_box 0;
   Format.print_string ("(" ^ name);
   Format.print_space ();
   parser_iter t;
   Format.print_string ")";
   Format.close_box ())
and parser_binop_emit name t0 t1 =
  (Format.open_box 1;
   Format.print_string ("(" ^ name);
   Format.print_space ();
   Format.open_box 0;
   parser_iter t0;
   Format.print_space ();
   parser_iter t1;
   Format.close_box ();
   Format.print_string ")";
   Format.close_box ())
(* parsr_iter : Syntax.t -> unit *)
and parser_iter s =
  begin
    Format.open_box 2;
    begin
      match s with
      | Syntax.Unit _ ->
	 Format.print_string "Unit"
      | Syntax.Bool (b, _) ->
	 (Format.open_hbox ();
	  Format.print_string "(Bool";
	  Format.print_space ();
	  Format.print_bool b;
	  Format.print_string ")";
	  Format.close_box ())
      | Syntax.Int (i, _) ->
	 (Format.open_hbox ();
	  Format.print_string "(Int";
	  Format.print_space ();
	  Format.print_int i;
	  Format.print_string ")";
	  Format.close_box ())
      | Syntax.Float (f, _) ->
	 (Format.open_hbox ();
	  Format.print_string "(Float";
	  Format.print_space ();
	  Format.print_float f;
	  Format.print_string ")";
	  Format.close_box ())
      | Syntax.Not (t, _) -> parser_monop_emit "Not" t
      | Syntax.Neg (t, _) -> parser_monop_emit "Neg" t
      | Syntax.Add (t0, t1, _)  -> parser_binop_emit "Add" t0 t1
      | Syntax.Sub (t0, t1, _)  -> parser_binop_emit "Sub" t0 t1
      | Syntax.Mul (t0, t1, _)  -> parser_binop_emit "Mul" t0 t1
      | Syntax.Div (t0, t1, _)  -> parser_binop_emit "Div" t0 t1
      | Syntax.FNeg (t, _)      -> parser_monop_emit "FNeg" t
      | Syntax.FAdd (t0, t1, _) -> parser_binop_emit "Fadd" t0 t1
      | Syntax.FSub (t0, t1, _) -> parser_binop_emit "FSub" t0 t1
      | Syntax.FMul (t0, t1, _) -> parser_binop_emit "FMul" t0 t1
      | Syntax.FDiv (t0, t1, _) -> parser_binop_emit "FDib" t0 t1
      | Syntax.Eq (t0, t1, _)   -> parser_binop_emit "Eq" t0 t1
      | Syntax.LE (t0, t1, _)   -> parser_binop_emit "LE" t0 t1
      | Syntax.If (t0, t1, t2, _) ->
	 (Format.open_hbox ();
	  Format.print_string "(If";
	  Format.print_space ();
	  Format.open_vbox 0;
	  parser_iter t0;
	  Format.print_space ();
	  parser_iter t1;
	  Format.print_space ();
	  parser_iter t2;
	  Format.close_box ();
	  Format.print_string ")";
	  Format.close_box ())
      | Syntax.Let ((id, ty), t0, t1, p) ->
	 (Format.open_vbox 1;
	  Format.print_string "(";
	  (* definition *)
	  Format.open_box 2;
	  Format.print_string "Let";
	  Format.print_space ();
	  id_emit id;
	  Format.print_space ();
	  Format.print_string ":";
	  Format.print_space ();
	  type_emit ty;
	  Format.print_space ();
	  Format.print_string "=";
	  Format.print_space ();
	  parser_iter t0;
	  Format.close_box ();
	  Format.print_space ();
	  (* body *)
	  Format.open_hbox ();
	  Format.print_string "in";
	  Format.print_space ();
	  parser_iter t1;
	  Format.close_box ();
	  Format.print_string ")";
	  Format.close_box ())
      | Syntax.Var (id, _) ->
	 (Format.print_string "(Var";
	  Format.print_space ();
	  id_emit id;
	  Format.print_string ")")
      | Syntax.LetRec ({name = (id, ty); args = lst; body = tb}, t, _) ->
	 (Format.open_vbox 1;
	  Format.print_string "(LetRec";
	  Format.print_space ();
	  fundef_emit id ty lst (FdSy tb);
	  Format.print_space ();
	  parser_iter t;
	  Format.print_string ")";
	  Format.close_box ())
      | Syntax.App (t0, t1_list, _) ->
	 (Format.print_string "(App";
	  Format.print_space ();
	  parser_iter t0;
	  Format.print_space ();
	  parser_list_emit t1_list;
	  Format.print_string ")")
      | Syntax.Tuple (t_list, _) ->
	 (Format.print_string "(Tuple";
	  Format.print_space ();
	  parser_list_emit t_list;
	  Format.print_string ")")
      | Syntax.LetTuple (tuple, t0, t1, p) ->
	 lettuple_emit tuple (LtSy t0) (ASy t1) p
      | Syntax.Array (t0, t1, _) ->
	 (Format.print_string "[Array";
	  Format.print_space ();
	  parser_iter t0;
	  Format.print_string ",";
	  Format.print_space ();
	  parser_iter t1;
	  Format.print_string "]")
      | Syntax.Get (t0, t1, _) -> parser_binop_emit "Get" t0 t1
      | Syntax.Put (t0, t1, t2, _) ->
	 (Format.print_string "(Put";
	  Format.print_space ();
	  parser_iter t0;
	  Format.print_space ();
	  parser_iter t1;
	  Format.print_space ();
	  parser_iter t2;
	  Format.print_string ")")
    end;
    Format.close_box ()
  end
(* fundef_emit : Id.t -> Type.t -> (Id.t * Type.t) list -> fundef_t -> unit *)
and fundef_emit id ty lst t =
  (Format.open_vbox 1;
   Format.print_string "{";
   (* name *)
   Format.open_hbox ();
   Format.print_string "name = ";
   id_emit id;
   Format.print_space ();
   Format.print_string ":";
   Format.print_space ();
   type_emit ty;
   Format.print_string ";";
   Format.close_box ();
   Format.print_space ();
   (* args *)
   Format.open_hbox ();
   Format.print_string "args = ";
   Format.open_box 1;
   Format.print_string "[";
   id_ty_list_iter lst;
   Format.print_string "]";
   Format.close_box ();
   Format.print_string ";";
   Format.close_box ();
   Format.print_space ();
   (* body *)
   Format.open_box 1;
   Format.print_string "body =";
   Format.print_space ();
   Format.open_box 0;
   (match t with
    | FdSy tt -> parser_iter tt
    | FdKn tt -> kNormal_iter tt);
   Format.close_box ();
   Format.close_box ();
   Format.print_string "}";
   Format.close_box ())
(* parser_list_emit : Type.t list -> unit *)
and parser_list_emit = function
    [] -> ()
  | [x]   -> parser_iter x;
  | x::xs -> (parser_iter x;
	      Format.print_space ();
	      parser_list_emit xs)
(* lettuple_emit : (Id.t * Type.t) -> lettuple_t -> all_t -> unit *)
and lettuple_emit tuple t0 t1 p =
  (Format.open_vbox 2;
   Format.print_string "(";
   Format.open_box 2;
   Format.print_string "LetTuple";
   Format.print_space ();
   (* タプル *)
   Format.open_box 1;
   Format.print_string "(";
   id_ty_list_iter tuple;
   Format.print_string ")";
   Format.close_box ();
   Format.print_space ();
   Format.print_string "=";
   Format.print_space ();
   (match t0 with
    | LtSy tt -> parser_iter tt
    | LtId tt -> id_emit tt);
   Format.close_box ();
   Format.print_space ();
   (* body *)
   Format.open_hbox ();
   Format.print_string "in";
   Format.print_space ();
   (match t1 with
    | ASy tt -> parser_iter tt
    | AKn tt -> kNormal_iter tt
    | ACl tt -> closure_iter tt);
   Format.close_box ();
   Format.print_string ")";
   Format.close_box ())

(*
 *  kNormal_emit関係
 *)
(* kNormal_emit : out_channel -> KNormal.t -> unit *)
and kNormal_emit oc s =
  (Format.set_formatter_out_channel oc;
   Format.set_margin margin;
   Format.set_max_indent max_indent;
   Format.open_vbox 0;
   kNormal_iter s;
   Format.print_space ();
   Format.close_box ();
   Format.print_flush ())
(* kNormal_iter : KNormal.t -> unit *)
and kNormal_iter s =
  begin
    Format.open_box 2;
    begin
      match s with
      | KNormal.Unit p       -> parser_iter (Syntax.Unit p)
      | KNormal.Int (i, p)   -> parser_iter (Syntax.Int (i, p))
      | KNormal.Float (f, p) -> parser_iter (Syntax.Float (f, p))
      | KNormal.Neg (id, p)  -> parser_iter (Syntax.Var (id, p))
      | KNormal.Add (id0, id1, p) ->
	 parser_iter (Syntax.Add (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.Sub (id0, id1, p) ->
	 parser_iter (Syntax.Sub (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.Mul (id0, id1, p) ->
	 parser_iter (Syntax.Mul (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.Div (id0, id1, p) ->
	 parser_iter (Syntax.Div (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.FNeg (id, p) -> parser_iter (Syntax.Var (id, p))
      | KNormal.FAdd (id0, id1, p) ->
	 parser_iter (Syntax.FAdd (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.FSub (id0, id1, p) ->
	 parser_iter (Syntax.FSub (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.FMul (id0, id1, p) ->
	 parser_iter (Syntax.FMul (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.FDiv (id0, id1, p) ->
	 parser_iter (Syntax.FDiv (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.IfEq (id0, id1, t0, t1, p) ->
	 ifop_emit "IfEq" id0 id1 (IoKn t0) (IoKn t1) p
      | KNormal.IfLE (id0, id1, t0, t1, p) ->
	 ifop_emit "IfLe" id0 id1 (IoKn t0) (IoKn t1) p
      | KNormal.Let ((id, ty), t0, t1, p) ->
	 let_emit id ty (LKn t0) (LKn t1) p
      | KNormal.Var (id, p) -> parser_iter (Syntax.Var (id, p))
      | KNormal.LetRec ({name = (id, ty); args = lst; body = tb}, t, _) ->
	 (Format.open_vbox 1;
	  Format.print_string "(LetRec";
	  Format.print_space ();
	  fundef_emit id ty lst (FdKn tb);
	  Format.print_space ();
	  kNormal_iter t;
	  Format.print_string ")";
	  Format.close_box ())
      | KNormal.App (id0, id1_lst, p) ->
	 parser_iter (Syntax.App
			(Syntax.Var (id0, p),
			 List.rev_map (fun id -> Syntax.Var (id, p)) id1_lst,
			 p))
      | KNormal.Tuple (id_lst, p) ->
	 parser_iter (Syntax.Tuple
			(List.rev_map (fun id -> Syntax.Var (id, p)) id_lst, p))
      | KNormal.LetTuple (tuple, id, t, p) ->
	 lettuple_emit tuple (LtId id) (AKn t) p
      | KNormal.Get (id0, id1, p) ->
	 parser_iter (Syntax.Get (Syntax.Var (id0, p), Syntax.Var (id1, p), p))
      | KNormal.Put (id0, id1, id2, p) ->
	 parser_iter (Syntax.Put (Syntax.Var (id0, p), Syntax.Var (id1, p), Syntax.Var (id2, p), p))
      | KNormal.ExtArray (id, p) ->
	 (Format.open_box 1;
	  Format.print_string "(ExtArray";
	  Format.print_space ();
	  id_emit id;
	  Format.print_string ")")
      | KNormal.ExtFunApp (id0, id1_lst, p) ->
	 (Format.open_box 1;
	  Format.print_string "(ExtFunApp";
	  Format.print_space ();
	  id_emit id0;
	  Format.print_space ();
	  Format.open_box 1;
	  Format.print_string "(";
	  parser_list_emit (List.rev_map
			      (fun id -> (Syntax.Var (id, p))) id1_lst);
	  Format.print_string ")";
	  Format.close_box ();
	  Format.close_box ())
    end;
    Format.close_box ()
  end
(* let_emit : Id.t -> Type.t -> let_t -> let_t -> unit *)
and let_emit id ty t0 t1 p =
  (Format.open_vbox 1;
   Format.print_string "(";
   (* definition *)
   Format.open_box 2;
   Format.print_string "Let";
   Format.print_space ();
   id_emit id;
   Format.print_space ();
   Format.print_string ":";
   Format.print_space ();
   type_emit ty;
   Format.print_space ();
   Format.print_string "=";
   Format.print_space ();
   (match t0 with
    | LKn tt -> kNormal_iter tt
    | LCl tt -> closure_iter tt);
   Format.print_space ();
   Format.print_string "in";
   Format.close_box ();
   Format.print_space ();
   (* body *)
   Format.open_box 0;
   (match t1 with
    | LKn tt -> kNormal_iter tt
    | LCl tt -> closure_iter tt);
   Format.close_box ();
   Format.print_string ")";
   Format.close_box ())
(* ifop_emit : string -> Id.t -> Id.t -> ifop_t -> ifop_t -> unit *)
and ifop_emit name id0 id1 t0 t1 p =
  (Format.open_vbox 1;
   (* 評価式 *)
   Format.open_hbox ();
   Format.print_string ("(" ^ name);
   Format.print_space ();
   parser_iter (Syntax.Var (id0, p));
   Format.print_space ();
   parser_iter (Syntax.Var (id1, p));
   Format.close_box ();
   Format.print_space ();
   (* true節、false節 *)
   (match t0 with
    | IoKn tt -> kNormal_iter tt
    | IoCl tt -> closure_iter tt);
   Format.print_space ();
   (match t1 with
    | IoKn tt -> kNormal_iter tt
    | IoCl tt -> closure_iter tt);
   Format.print_string ")")

(*
 * closure_prog_emit関係
 *)
(* closure_prog_emit : out_channel -> Closure.prog -> unit *)
and closure_prog_emit oc (Prog (fundef_lst, s)) =
  (Format.set_formatter_out_channel oc;
   Format.set_margin margin;
   Format.set_max_indent max_indent;
   Format.open_vbox 0;
   fundef_list_emit fundef_lst;
   Format.print_space ();
   closure_iter s;
   Format.print_space ();
   Format.close_box ();
   Format.print_flush ())
(* fundef_list_emit : fundef list -> unit *)
and fundef_list_emit = function
    [] -> ()
  | [fd]    -> cl_fundef_emit fd
  | fd :: l -> (Format.open_vbox 0;
		cl_fundef_emit fd;
		Format.print_space ();
		fundef_list_emit l;
		Format.close_box ())
(* cl_fundef_emit : Closure.fundef -> unit *)
and cl_fundef_emit {name = (label, ty); args = args; formal_fv = formal_fv; body = t} =
  (Format.open_vbox 0;
   Format.print_string "{";
   (* name *)
   Format.open_hbox ();
   Format.print_string "name = ";
   label_emit label;
   Format.print_space ();
   Format.print_string ":";
   Format.print_space ();
   type_emit ty;
   Format.print_string ";";
   Format.close_box ();
   Format.print_space ();
   (* args *)
   Format.open_hbox ();
   Format.print_string "args = ";
   Format.open_box 1;
   Format.print_string "[";
   id_ty_list_iter args;
   Format.print_string "]";
   Format.close_box ();
   Format.print_string ";";
   Format.close_box ();
   Format.print_space ();
   (* formal_fv *)
   Format.open_hbox ();
   Format.print_string "formal_fv = ";
   Format.open_box 1;
   Format.print_string "[";
   id_ty_list_iter formal_fv;
   Format.print_string "]";
   Format.close_box ();
   Format.print_string ";";
   Format.close_box ();
   Format.print_space ();
   (* body *)
   Format.open_box 2;
   Format.print_string "body = ";
   Format.open_box 0;
   closure_iter t;
   Format.close_box ();
   Format.close_box ();
   Format.print_string "}";
   Format.close_box ())
(* closure_iter : Closure.t -> unit *)
and closure_iter s =
  begin
    Format.open_box 2;
    begin
      match s with
      | Closure.Unit p       -> kNormal_iter (KNormal.Unit p)
      | Closure.Int (i, p)   -> kNormal_iter (KNormal.Int (i, p))
      | Closure.Float (f, p) -> kNormal_iter (KNormal.Float (f, p))
      | Closure.Neg (id, p)  -> kNormal_iter (KNormal.Neg (id, p))
      | Closure.Add (id0, id1, p)  -> kNormal_iter (KNormal.Add (id0, id1, p))
      | Closure.Sub (id0, id1, p)  -> kNormal_iter (KNormal.Sub (id0, id1, p))
      | Closure.Mul (id0, id1, p)  -> kNormal_iter (KNormal.Mul (id0, id1, p))
      | Closure.Div (id0, id1, p)  -> kNormal_iter (KNormal.Div (id0, id1, p))
      | Closure.FNeg (id, p)       -> kNormal_iter (KNormal.FNeg (id, p))
      | Closure.FAdd (id0, id1, p) -> kNormal_iter (KNormal.FAdd (id0, id1, p))
      | Closure.FSub (id0, id1, p) -> kNormal_iter (KNormal.FSub (id0, id1, p))
      | Closure.FMul (id0, id1, p) -> kNormal_iter (KNormal.FMul (id0, id1, p))
      | Closure.FDiv (id0, id1, p) -> kNormal_iter (KNormal.FDiv (id0, id1, p))
      | Closure.IfEq (id0, id1, t0, t1, p) ->
	 ifop_emit "IfEq" id0 id1 (IoCl t0) (IoCl t1) p
      | Closure.IfLE (id0, id1, t0, t1, p) ->
	 ifop_emit "IfLE" id0 id1 (IoCl t0) (IoCl t1) p
      | Closure.Let ((id, ty), t0, t1, p) ->
	 let_emit id ty (LCl t0) (LCl t1) p
      | Closure.Var (id, p) -> kNormal_iter (KNormal.Var (id, p))
      | Closure.MakeCls ((id, ty), cl, t, p) ->
	  (Format.open_vbox 1;
	   Format.print_string "(MakeCls";
	   Format.print_space ();
	   Format.open_hbox ();
	   id_emit id;
	   Format.print_space ();
	   type_emit ty;
	   Format.close_box ();
	   Format.print_space ();
	   cl_emit cl;
	   Format.print_space ();
	   closure_iter t;
	   Format.print_string ")";
	   Format.close_box ())
      | Closure.AppCls (id0, id1_lst, p) ->
	  (Format.print_string "(AppCls";
	   Format.print_space ();
	   (* 識別子 *)
	   Format.open_box 2;
	   Format.print_string "(Var";
	   Format.print_space ();
	   id_emit id0;
	   Format.print_string ")";
	   Format.close_box ();
	   Format.print_space ();
	   (* 引数 *)
	   parser_list_emit (List.rev_map (fun id -> Syntax.Var (id, p)) id1_lst);
	   Format.print_string ")")
      | Closure.AppDir (label, id_lst, p) ->
	  (Format.print_string "(AppCls";
	   Format.print_space ();
	   (* 識別子 *)
	   Format.open_box 2;
	   Format.print_string "(Var";
	   Format.print_space ();
	   label_emit label;
	   Format.print_string ")";
	   Format.close_box ();
	   Format.print_space ();
	   (* 引数 *)
	   parser_list_emit (List.rev_map (fun id -> Syntax.Var (id, p)) id_lst);
	   Format.print_string ")")
      | Closure.Tuple (tuple, p) -> kNormal_iter (KNormal.Tuple (tuple, p))
      | Closure.LetTuple (tuple, id, t, p) ->
	 lettuple_emit tuple (LtId id) (ACl t) p
      | Closure.Get (id0, id1, p)      -> kNormal_iter (KNormal.Get (id0, id1, p))
      | Closure.Put (id0, id1, id2, p) -> kNormal_iter (KNormal.Put (id0, id1, id2, p))
      | Closure.ExtArray (label, p) ->
	 (Format.print_string "(ExtArray";
	  Format.print_space ();
	  label_emit label;
	  Format.print_string ")")
    end;
    Format.close_box ()
  end
(* cl_emit : Closure.closure -> unit *)
(* NB. not closure_emit *)
and cl_emit {entry = label; actual_fv = id_lst} =
  (Format.open_box 1;
   Format.print_string "(MakeCls";
   Format.print_space ();
   Format.print_string "{entry = ";
   label_emit label;
   Format.print_string ";";
   Format.print_space ();
   Format.print_string "actual_fv = ";
   Format.open_box 1;
   Format.print_string "[";
   id_list_iter id_lst;
   Format.print_string "]";
   Format.close_box ();
   Format.print_string "}";
   Format.close_box ())
(* id_list_iter : Id.t list -> unit *)
and id_list_iter = function
    [] -> ()
  | [id]    -> Format.print_string id
  | id :: l -> (Format.print_string id;
		Format.print_space ();
		id_list_iter l)

(* 
 * main.ml用の情報
 *)
type level = (* どの段階でデバッグ出力するかを管理する型 *)
  | Parser
  | Typing
  | KNormal
  | Alpha
  | Iter
  | Closure
  | Virtual
  | Simm
  | RegAlloc
  | Emit

(* level_of_string : string -> Debug.level *)
(* 規定外なら(例外を出すのではなく)Emit扱いにする *)
let level_of_string = function
    "Parser"   -> Parser
  | "Typing"   -> Typing
  | "KNormal"  -> KNormal
  | "Alpha"    -> Alpha
  | "Iter"     -> Iter
  | "Closure"  -> Closure
  | "Virtual"  -> Virtual
  | "Simm"     -> Simm
  | "RegAlloc" -> RegAlloc
  | _          -> Emit
