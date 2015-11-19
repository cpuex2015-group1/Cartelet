open Asm

external getfl : float -> int32 = "getfl"

let server_mode = ref false

let stackset = ref S.empty (* すでにSaveされた変数の集合 (caml2html: emit_stackset) *)
let stackmap = ref [] (* Saveされた変数の、スタックにおける位置 (caml2html: emit_stackmap) *)
let save x =
  stackset := S.add x !stackset;
  if not (List.mem x !stackmap) then
    stackmap := !stackmap @ [x]
let savef x =
  stackset := S.add x !stackset;
  if not (List.mem x !stackmap) then
    (* let pad =
       if List.length !stackmap mod 2 = 0 then [] else [Id.gentmp Type.Int] in
     stackmap := !stackmap @ pad @ [x; x] *)
    stackmap := !stackmap @ [x]
let locate x =
  let rec loc = function
    | [] -> []
    | y :: zs when x = y -> 0 :: List.map succ (loc zs)
    | y :: zs -> List.map succ (loc zs) in
  loc !stackmap
(** あやしい *)
let offset x = (List.hd (locate x)) + 1
let stacksize () = List.length !stackmap * 1

let pp_id_or_imm = function
  | V(x) -> x
  | C(i) -> "$" ^ string_of_int i

(* 関数呼び出しのために引数を並べ替える(register shuffling) (caml2html: emit_shuffle) *)
let rec shuffle sw xys =
  (* remove identical moves *)
  let _, xys = List.partition (fun (x, y) -> x = y) xys in
  (* find acyclic moves *)
  match List.partition (fun (_, y) -> List.mem_assoc y xys) xys with
  | [], [] -> []
  | (x, y) :: xys, [] -> (* no acyclic moves; resolve a cyclic move *)
     (y, sw) :: (x, y) :: shuffle sw (List.map
					(function
					  | (y', z) when y = y' -> (sw, z)
					  | yz -> yz)
					xys)
  | xys, acyc -> acyc @ shuffle sw xys

(* 行末に.mlファイルの行番号情報を付記 *)
let line oc p = Printf.fprintf oc "\t# %d\n" p.Lexing.pos_lnum

type dest = Tail | NonTail of Id.t (* 末尾かどうかを表すデータ型 (caml2html: emit_dest) *)
let rec g oc = function (* 命令列のアセンブリ生成 (caml2html: emit_g) *)
  | dest, Ans(exp) -> g' oc (dest, exp)
  | dest, Let((x, t), exp, e) ->
     g' oc (NonTail(x), exp);
     g oc (dest, e)
and g' oc = function (* 各命令のアセンブリ生成 (caml2html: emit_gprime) *)
  (* 末尾でなかったら計算結果をdestにセット (caml2html: emit_nontail) *)
  | NonTail(_), Nop _ -> ()
  | NonTail(x), Set(i, p) ->
     Printf.fprintf oc "\taddi\t%s %s $%d" x reg_zero i;
     line oc p
  | NonTail(x), SetL(Id.L(y), p) ->
     Printf.fprintf oc "\taddi\t%s %s %s" x reg_zero y;
     line oc p
  | NonTail(x), Mov(y, p) ->
     if x <> y then (Printf.fprintf oc "\tadd\t%s %s %s" x reg_zero y;
		     line oc p)
  | NonTail(x), Neg(y, p) ->
     Printf.fprintf oc "\tsub\t%s %s %s" x reg_zero y;
     line oc p
  | NonTail(x), Add(y, V(z), p) ->
     Printf.fprintf oc "\tadd\t%s %s %s" x y z;
     line oc p
  | NonTail(x), Add(y, C(z), p) ->
     Printf.fprintf oc "\taddi\t%s %s $%d" x y z; (* addi 0消さなくて良い? *)
     line oc p
  | NonTail(x), Sub(y, V(z), p) ->
     Printf.fprintf oc "\tsub\t%s %s %s" x y z;
     line oc p
  | NonTail(x), Sub(y, C(z), p) ->
     Printf.fprintf oc "\taddi\t%s %s $%d" x y (-z); (* subi 0消さなくて良い? *)
     line oc p
  | NonTail(x), Mul(y, z', p) ->
     assert(z' = C(4));
     Printf.fprintf oc "\taddi\t%s %s $2" reg_tmp reg_zero;
     line oc p;
     Printf.fprintf oc "\tsll\t%s %s %s" x y reg_tmp;
     line oc p;
  | NonTail(x), Div(y, z', p) ->
     assert(z' = C(2));
     (* sraが無いので正負に分ける *)
     let pos_div = Id.genid "div_positive" in
     let div_exit = Id.genid "div_exit" in
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp y reg_zero;
     line oc p;
     Printf.fprintf oc "\tbeq\t%s %s %s" reg_tmp reg_zero pos_div;
     line oc p;
     (* negative *)
     (* intの最小値に対して微妙に正しくないが使わない(はず) *)
     Printf.fprintf oc "\tsub\t%s %s %s" x reg_zero y;
     line oc p;
     Printf.fprintf oc "\taddi\t%s %s $1" reg_tmp reg_zero;
     line oc p;
     Printf.fprintf oc "\tsrl\t%s %s %s" reg_tmp x reg_tmp;
     line oc p;
     Printf.fprintf oc "\tsub\t%s %s %s" x reg_zero reg_tmp;
     line oc p;
     Printf.fprintf oc "\tbeq\t%s %s %s" reg_zero reg_zero div_exit;
     line oc p;
     (* positive *)
     Printf.fprintf oc "%s:\n" pos_div;
     Printf.fprintf oc "\taddi\t%s %s $1" reg_tmp reg_zero;
     line oc p;
     Printf.fprintf oc "\tsrl\t%s %s %s" x y reg_tmp;
     line oc p;
     Printf.fprintf oc "%s:\n" div_exit;
  | NonTail(x), Ld(y, V(z), i, p) ->
     assert(i = 4);
     Printf.fprintf oc "\tadd\t%s %s %s" reg_tmp y z;
     line oc p;
     Printf.fprintf oc "\tld\t0(%s) %s" reg_tmp x;
     line oc p
  | NonTail(x), Ld(y, C(j), i, p) -> (* オーバーフロー大丈夫? *)
     assert(i = 4);
     Printf.fprintf oc "\tld\t%d(%s) %s" j y x;
     line oc p
  | NonTail(_), St(x, y, V(z), i, p) ->
     assert(i = 4);
     Printf.fprintf oc "\tadd\t%s %s %s" reg_tmp y z;
     line oc p;
     Printf.fprintf oc "\tst\t0(%s) %s" reg_tmp x;
     line oc p
  | NonTail(_), St(x, y, C(j), i, p) -> (* オーバーフロー大丈夫? *)
     assert(i = 4);
     Printf.fprintf oc "\tst\t%d(%s) %s" j y x;
     line oc p
  | NonTail(x), FMov(y, p) ->
     if x <> y then (Printf.fprintf oc "\tfmov\t%s %s" x y;
		     line oc p)
  | NonTail(x), FNeg(y, p) ->
     Printf.fprintf oc "\tfneg\t%s %s" x y;
     line oc p
  | NonTail(x), FAdd(y, z, p) ->
     Printf.fprintf oc "\tfadd\t%s %s %s" x y z;
     line oc p
  | NonTail(x), FSub(y, z, p) ->
     Printf.fprintf oc "\tfneg\t%s %s" reg_ftmp z;
     line oc p;
     Printf.fprintf oc "\tfadd\t%s %s %s" x y reg_ftmp;
     line oc p
  | NonTail(x), FMul(y, z, p) ->
     Printf.fprintf oc "\tfmul\t%s %s %s" x y z;
     line oc p
  | NonTail(x), FDiv(y, z, p) ->
     Printf.fprintf oc "\tnop\t# for debug\n";
     Printf.fprintf oc "\tfinv\t%s %s" reg_ftmp z;
     line oc p;
     Printf.fprintf oc "\tfmul\t%s %s %s" x y reg_ftmp;
     line oc p
  | NonTail(x), LdF(y, V(z), i, p) ->
     assert(i = 4);
     Printf.fprintf oc "\tadd\t%s %s %s" reg_tmp y z;
     line oc p;
     Printf.fprintf oc "\tfld\t0(%s) %s" reg_tmp x;
     line oc p
  | NonTail(x), LdF(y, C(j), i, p) -> (* オーバーフロー大丈夫? *)
     assert(i = 4);
     Printf.fprintf oc "\tfld\t%d(%s) %s" j y x;
     line oc p
  | NonTail(_), StF(x, y, V(z), i, p) ->
     assert(i = 4);
     Printf.fprintf oc "\tadd\t%s %s %s" reg_tmp y z;
     line oc p;
     Printf.fprintf oc "\tfst\t0(%s) %s" reg_tmp x;
     line oc p
  | NonTail(_), StF(x, y, C(j), i, p) -> (* オーバーフロー大丈夫? *)
     assert(i = 4);
     Printf.fprintf oc "\tfst\t%d(%s) %s" j y x;
     line oc p
  | NonTail(_), Comment(s, p) ->
     Printf.fprintf oc "\t# %s\t" s;
     line oc p
  (* 退避の仮想命令の実装 (caml2html: emit_save) *)
  | NonTail(_), Save(x, y, p) when List.mem x allregs && not (S.mem y !stackset) ->
      save y;
      Printf.fprintf oc "\tst\t%d(%s) %s" (-(offset y)) reg_sp x;
      line oc p
  | NonTail(_), Save(x, y, p) when List.mem x allfregs && not (S.mem y !stackset) ->
     savef y;
     Printf.fprintf oc "\tfst\t%d(%s) %s" (-(offset y)) reg_sp x;
     line oc p
  | NonTail(_), Save(x, y, p) -> assert (S.mem y !stackset); ()
  (* 復帰の仮想命令の実装 (caml2html: emit_restore) *)
  | NonTail(x), Restore(y, p) when List.mem x allregs ->
      Printf.fprintf oc "\tld\t%d(%s) %s" (-(offset y)) reg_sp x;
      line oc p
  | NonTail(x), Restore(y, p) ->
      assert (List.mem x allfregs);
      Printf.fprintf oc "\tfld\t%d(%s) %s" (-(offset y)) reg_sp x;
      line oc p
  (* 末尾だったら計算結果を第一レジスタにセットしてret (caml2html: emit_tailret) *)
  | Tail, (Nop _ | St _ | StF _ | Comment _ | Save _ as exp) ->
      let p = Asm.pos_of_exp exp in
      g' oc (NonTail(Id.gentmp Type.Unit), exp);
      Printf.fprintf oc "\tjr\t%s" reg_ra;
      line oc p
  | Tail, (Set _ | SetL _ | Mov _ | Neg _ | Add _ | Sub _ | Mul _ | Div _ | Ld _ as exp) ->
     let p = Asm.pos_of_exp exp in
     g' oc (NonTail(reg_rv), exp);
     Printf.fprintf oc "\tjr\t%s" reg_ra;
     line oc p
  | Tail, (FMov _ | FNeg _ | FAdd _ | FSub _ | FMul _ | FDiv _ | LdF _  as exp) ->
      let p = Asm.pos_of_exp exp in
      g' oc (NonTail(reg_frv), exp);
      Printf.fprintf oc "\tjr\t%s" reg_ra;
      line oc p
  | Tail, (Restore(x, p) as exp) ->
     (if x.[1] = 'r' then
	g' oc (NonTail(reg_rv), exp)
      else
	g' oc (NonTail(reg_frv), exp));
     (*match locate x with
      | [i] -> g' oc (NonTail(reg_rv), exp)
      | [i; j] when i + 1 = j -> g' oc (NonTail(reg_frv), exp)
      | _ -> assert false*)
     Printf.fprintf oc "\tjr\t%s" reg_ra;
     line oc p
(* 後で分岐予測のこと考える *)
  | Tail, IfEq(x, V(y), e1, e2, p) ->
     g'_tail_if oc e1 e2 "beq" x y p
  | Tail, IfEq(x, C(y), e1, e2, p) ->
     if y <> 0 then
       (Printf.fprintf oc "\taddi\t%s %s $%d" reg_tmp x (-y);
	line oc p;
	g'_tail_if oc e1 e2 "beq" reg_tmp reg_zero p)
     else
	g'_tail_if oc e1 e2 "beq" x reg_zero p
  | Tail, IfLE(x, V(y), e1, e2, p) ->
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp y x;
     line oc p;
     g'_tail_if oc e1 e2 "beq" reg_tmp reg_zero p
  | Tail, IfLE(x, C(y), e1, e2, p) ->
     Printf.fprintf oc "\tsub\t%s %s %s" reg_tmp reg_zero x;
     line oc p;
     Printf.fprintf oc "\taddi\t%s %s $%d" reg_tmp reg_tmp y;
     line oc p;
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp reg_tmp reg_zero;
     line oc p;
     g'_tail_if oc e1 e2 "beq" reg_tmp reg_zero p
  | Tail, IfGE(x, V(y), e1, e2, p) ->
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp x y;
     line oc p;
     g'_tail_if oc e1 e2 "beq" reg_tmp reg_zero p
  | Tail, IfGE(x, C(y), e1, e2, p) ->
     Printf.fprintf oc "\tsub\t%s %s %s" reg_tmp reg_zero x;
     line oc p;
     Printf.fprintf oc "\taddi\t%s %s $%d" reg_tmp reg_tmp y;
     line oc p;
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp reg_zero reg_tmp;
     line oc p;
     g'_tail_if oc e1 e2 "beq" reg_tmp reg_zero p
  | Tail, IfFEq(x, y, e1, e2, p) ->
     Printf.fprintf oc "\tfseq\t%s %s" x y;
     line oc p;
     g'_tail_if_float oc e1 e2 "bclt" p;
  | Tail, IfFLE(x, y, e1, e2, p) ->
     Printf.fprintf oc "\tfslt\t%s %s" y x;
     line oc p;
     g'_tail_if_float oc e2 e1 "bclt" p;
  | NonTail(z), IfEq(x, V(y), e1, e2, p) ->
     g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" x y p
  | NonTail(z), IfEq(x, C(y), e1, e2, p) ->
     if y <> 0 then
       (Printf.fprintf oc "\taddi\t%s %s $%d" reg_tmp x (-y);
	line oc p;
	g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" reg_tmp reg_zero p)
     else
	g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" x reg_zero p
  | NonTail(z), IfLE(x, V(y), e1, e2, p) ->
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp y x;
     line oc p;
     g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" reg_tmp reg_zero p
  | NonTail(z), IfLE(x, C(y), e1, e2, p) ->
     Printf.fprintf oc "\tsub\t%s %s %s" reg_tmp reg_zero x;
     line oc p;
     Printf.fprintf oc "\taddi\t%s %s $%d" reg_tmp reg_tmp y;
     line oc p;
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp reg_tmp reg_zero;
     line oc p;
     g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" reg_tmp reg_zero p
  | NonTail(z), IfGE(x, V(y), e1, e2, p) ->
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp x y;
     line oc p;
     g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" reg_tmp reg_zero p
  | NonTail(z), IfGE(x, C(y), e1, e2, p) ->
     Printf.fprintf oc "\tsub\t%s %s %s" reg_tmp reg_zero x;
     line oc p;
     Printf.fprintf oc "\taddi\t%s %s $%d" reg_tmp reg_tmp y;
     line oc p;
     Printf.fprintf oc "\tslt\t%s %s %s" reg_tmp reg_zero reg_tmp;
     line oc p;
     g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" reg_tmp reg_zero p
  | NonTail(z), IfFEq(x, y, e1, e2, p) ->
     Printf.fprintf oc "\tfseq\t%s %s" x y;
     line oc p;
     g'_non_tail_if_float oc (NonTail(z)) e1 e2 "bclt" p;
  | NonTail(z), IfFLE(x, y, e1, e2, p) ->
     Printf.fprintf oc "\tfslt\t%s %s" y x;
     line oc p;
     g'_non_tail_if_float oc (NonTail(z)) e2 e1 "bclt" p;
  (* 関数呼び出しの仮想命令の実装 (caml2html: emit_call) *)
  | Tail, CallCls(x, ys, zs, p) -> (* 末尾呼び出し (caml2html: emit_tailcall) *)
     g'_args oc [(x, reg_cl)] ys zs p;
     Printf.fprintf oc "\tld\t0(%s) %s" reg_cl reg_sw;
     line oc p;
     Printf.fprintf oc "\tjr\t%s" reg_sw;
     line oc p;
  | Tail, CallDir(Id.L(x), ys, zs, p) -> (* 末尾呼び出し *)
     (match x with
      | "min_caml_fabs" | "min_caml_abs_float" ->
	 (Printf.fprintf oc "\tfabs\t%s %s" reg_frv (List.hd zs);
	  line oc p;
	  Printf.fprintf oc "\tjr\t%s" reg_ra;
	  line oc p)
      | "min_caml_sqrt" ->
	 (Printf.fprintf oc "\tfsqrt\t%s %s" reg_frv (List.hd zs);
	  line oc p;
	  Printf.fprintf oc "\tjr\t%s" reg_ra;
	  line oc p)
      | "min_caml_read_int" when !server_mode ->
	 g' oc (Tail, CallDir(Id.L("min_caml_read_int_byte"), ys, zs, p))
      | "min_caml_read_float" when !server_mode ->
	 g' oc (Tail, CallDir(Id.L("min_caml_read_float_byte"), ys, zs, p))
      | _ ->
	 (g'_args oc [] ys zs p;
	  Printf.fprintf oc "\tbeq\t%s %s %s" reg_zero reg_zero x;
	  line oc p));
  | NonTail(a), CallCls(x, ys, zs, p) ->
     g'_args oc [(x, reg_cl)] ys zs p;
     let ss = stacksize () in
     Printf.fprintf oc "\taddi\t%s %s $%d" reg_sp reg_sp (-(ss+1));
     line oc p;
     Printf.fprintf oc "\tst\t0(%s) %s" reg_sp reg_ra;
     line oc p;
     Printf.fprintf oc "\tld\t0(%s) %s" reg_cl reg_sw;
     line oc p;
     Printf.fprintf oc "\tjalr\t%s" reg_sw;
     line oc p;
     Printf.fprintf oc "\tld\t0(%s) %s" reg_sp reg_ra;
     line oc p;
     Printf.fprintf oc "\taddi\t%s %s $%d" reg_sp reg_sp (ss+1);
     line oc p;
     if List.mem a allregs && a <> reg_rv then
       (Printf.fprintf oc "\tadd\t%s %s %s" a reg_zero reg_rv;
	line oc p)
     else if List.mem a allfregs && a <> reg_frv then
       (Printf.fprintf oc "\tfmov\t%s %s" reg_frv a;
	line oc p)
  | NonTail(a), CallDir(Id.L(x), ys, zs, p) ->
     (match x with
      | "min_caml_fabs" | "min_caml_abs_float" ->
	 (Printf.fprintf oc "\tfabs\t%s %s" a (List.hd zs);
	  line oc p;
	  if a <> reg_frv then (* 後でもう少し確認する *)
	    (Printf.fprintf oc "\tadd\t%s %s %s" a reg_zero reg_frv;
	     line oc p))
      | "min_caml_sqrt" ->
	 (Printf.fprintf oc "\tfsqrt\t%s %s" a (List.hd zs);
	  line oc p;
	  if a <> reg_frv then
	    (Printf.fprintf oc "\tadd\t%s %s %s" a reg_zero reg_frv;
	     line oc p))
      | "min_caml_read_int" when !server_mode ->
	 g' oc (NonTail(a), CallDir(Id.L("min_caml_read_int_byte"), ys, zs, p))
      | "min_caml_read_float" when !server_mode ->
	 g' oc (NonTail(a), CallDir(Id.L("min_caml_read_float_byte"), ys, zs, p))
      | _ ->
	 (g'_args oc [] ys zs p;
	  let ss = stacksize () in
	  Printf.fprintf oc "\taddi\t%s %s $%d" reg_sp reg_sp (-(ss+1));
	  line oc p;
	  Printf.fprintf oc "\tst\t0(%s) %s" reg_sp reg_ra;
	  line oc p;
	  Printf.fprintf oc "\tjal\t%s" x;
	  line oc p;
	  Printf.fprintf oc "\tld\t0(%s) %s" reg_sp reg_ra;
	  line oc p;
	  Printf.fprintf oc "\taddi\t%s %s $%d" reg_sp reg_sp (ss+1);
	  line oc p;
	  if List.mem a allregs && a <> reg_rv then
	    (Printf.fprintf oc "\tadd\t%s %s %s" a reg_zero reg_rv;
	     line oc p)
	  else if List.mem a allfregs && a <> reg_frv then
	    (Printf.fprintf oc "\tfmov\t%s %s" reg_frv a;
	     line oc p)))
and g'_tail_if oc e1 e2 b reg1 reg2 p =
  let b_true = Id.genid b in
  Printf.fprintf oc "\t%s\t%s %s %s" b reg1 reg2 b_true;
  line oc p;
  let stackset_back = !stackset in
  g oc (Tail, e2);
  Printf.fprintf oc "%s:\n" b_true;
  stackset := stackset_back;
  g oc (Tail, e1);
and g'_tail_if_float oc e1 e2 b p =
  let b_true = Id.genid b in
  Printf.fprintf oc "\t%s\t%s" b b_true;
  line oc p;
  let stackset_back = !stackset in
  g oc (Tail, e2);
  Printf.fprintf oc "%s:\n" b_true;
  stackset := stackset_back;
  g oc (Tail, e1);
and g'_non_tail_if oc dest e1 e2 b reg1 reg2 p =
  let b_true = Id.genid (b ^ "_true") in
  let b_cont = Id.genid (b ^ "_cont") in
  Printf.fprintf oc "\t%s\t%s %s %s" b reg1 reg2 b_true;
  line oc p;
  let stackset_back = !stackset in
  g oc (dest, e2);
  let stackset1 = !stackset in
  Printf.fprintf oc "\tbeq\t%s %s %s" reg_zero reg_zero b_cont;
  line oc p;
  Printf.fprintf oc "%s:\n" b_true;
  stackset := stackset_back;
  g oc (dest, e1);
  Printf.fprintf oc "%s:\n" b_cont;
  let stackset2 = !stackset in
  stackset := S.inter stackset1 stackset2
and g'_non_tail_if_float oc dest e1 e2 b p =
  let b_true = Id.genid (b ^ "_true") in
  let b_cont = Id.genid (b ^ "_cont") in
  Printf.fprintf oc "\t%s\t%s" b b_true;
  line oc p;
  let stackset_back = !stackset in
  g oc (dest, e2);
  let stackset1 = !stackset in
  Printf.fprintf oc "\tbeq\t%s %s %s" reg_zero reg_zero b_cont;
  line oc p;
  Printf.fprintf oc "%s:\n" b_true;
  stackset := stackset_back;
  g oc (dest, e1);
  Printf.fprintf oc "%s:\n" b_cont;
  let stackset2 = !stackset in
  stackset := S.inter stackset1 stackset2
and g'_args oc x_reg_cl ys zs p =
  assert (List.length ys <= Array.length regs - List.length x_reg_cl);
  assert (List.length zs <= Array.length fregs);
  (* let sw = Printf.sprintf "%d(%s)" (stacksize ()) reg_sp in *)
  let (i, yrs) =
    List.fold_left
      (fun (i, yrs) y -> (i + 1, (y, regs.(i)) :: yrs))
      (0, x_reg_cl)
      ys in
  List.iter
    (fun (y, r) -> (Printf.fprintf oc "\tadd\t%s %s %s" r reg_zero y; line oc p))
    (shuffle reg_sw yrs);
  let (d, zfrs) =
    List.fold_left
      (fun (d, zfrs) z -> (d + 1, (z, fregs.(d)) :: zfrs))
      (0, [])
      zs in
  List.iter
    (fun (z, fr) -> (Printf.fprintf oc "\tfmov\t%s %s" fr z; line oc p))
    (shuffle reg_fsw zfrs)

let h oc { name = Id.L(x); args = _; fargs = _; body = e; ret = _ } =
  Printf.fprintf oc "%s:\n" x;
  stackset := S.empty;
  stackmap := [];
  g oc (Tail, e)

(* mem : string list -> bool *)
let rec mem = function
  | [] -> false
  | str::lst ->
     (if M.mem str !(Typing.extenv) then true
      else mem lst)

let f oc (Prog(data, fundefs, e)) =
  Format.eprintf "generating assembly...@.";
  Printf.fprintf oc ".data\n";
  (* constant for library *)
  Printf.fprintf oc "min_caml_2pi:\n";
  Printf.fprintf oc "\t.long\t0x40c90fdb\n";
  Printf.fprintf oc "min_caml_pi:\n";
  Printf.fprintf oc "\t.long\t0x40490fdb\n";
  Printf.fprintf oc "min_caml_half_pi:\n";
  Printf.fprintf oc "\t.long\t0x3fc90fdb\n";
  Printf.fprintf oc "min_caml_quarter_pi:\n";
  Printf.fprintf oc "\t.long\t0x3f490fdb\n";
  Printf.fprintf oc "min_caml_float_0:\n";
  Printf.fprintf oc "\t.long\t0x00000000\n";
  Printf.fprintf oc "min_caml_float_1:\n";
  Printf.fprintf oc "\t.long\t0x3f800000\n";
  Printf.fprintf oc "min_caml_float_2:\n";
  Printf.fprintf oc "\t.long\t0x40000000\n";
  Printf.fprintf oc "min_caml_float_minus_1:\n";
  Printf.fprintf oc "\t.long\t0xbf800000\n";
  Printf.fprintf oc "min_caml_float_half:\n";
  Printf.fprintf oc "\t.long\t0x3f000000\n";
  (if mem ["read_int"; "read_float"; "read_int_byte"; "read_float_byte"] then
     (Printf.fprintf oc "min_caml_read_float_c1:\n";
      Printf.fprintf oc "\t.long\t0x3dcccccd\n"));
  (if mem ["int_of_float"; "truncate"; "float_of_int"; "read_int"; "read_float"] then
     (Printf.fprintf oc "min_caml_float_int_c1:\n";
      Printf.fprintf oc "\t.long\t0xcb000000\n"; (* (float)(-838860) *)
      Printf.fprintf oc "min_caml_float_int_c2:\n";
      Printf.fprintf oc "\t.long\t0x4b000000\n" (* (float)(838860) *)));
  (if mem ["cos"; "sin"] then
     (Printf.fprintf oc "min_caml_kernel_cos_c1:\n";
      Printf.fprintf oc "\t.long\t0xbf000000\n";
      Printf.fprintf oc "min_caml_kernel_cos_c2:\n";
      Printf.fprintf oc "\t.long\t0x3d2aa789\n";
      Printf.fprintf oc "min_caml_kernel_cos_c3:\n";
      Printf.fprintf oc "\t.long\t0xbab38106\n";
      Printf.fprintf oc "min_caml_kernel_sin_c1:\n";
      Printf.fprintf oc "\t.long\t0xbe2aaaac\n";
      Printf.fprintf oc "min_caml_kernel_sin_c2:\n";
      Printf.fprintf oc "\t.long\t0x3c088666\n";
      Printf.fprintf oc "min_caml_kernel_sin_c3:\n";
      Printf.fprintf oc "\t.long\t0xb94d64b6\n"));
  (if mem ["atan"] then
     (Printf.fprintf oc "min_caml_atan_c1:\n";
      Printf.fprintf oc "\t.long\t0x3ee00000\n";
      Printf.fprintf oc "min_caml_atan_c2:\n";
      Printf.fprintf oc "\t.long\t0x401c0000\n";
      Printf.fprintf oc "min_caml_kernel_atan_c1:\n";
      Printf.fprintf oc "\t.long\t0xbeaaaaaa\n";
      Printf.fprintf oc "min_caml_kernel_atan_c2:\n";
      Printf.fprintf oc "\t.long\t0x3e4ccccd\n";
      Printf.fprintf oc "min_caml_kernel_atan_c3:\n";
      Printf.fprintf oc "\t.long\t0xbe124925\n";
      Printf.fprintf oc "min_caml_kernel_atan_c4:\n";
      Printf.fprintf oc "\t.long\t0x3de38e38\n";
      Printf.fprintf oc "min_caml_kernel_atan_c5:\n";
      Printf.fprintf oc "\t.long\t0xbdb7d66e\n";
      Printf.fprintf oc "min_caml_kernel_atan_c6:\n";
      Printf.fprintf oc "\t.long\t0x3d75e7c5\n"));
  (* float table *)
  List.iter
    (fun (Id.L(x), f) ->
      Printf.fprintf oc "%s:\t# %f\n" x f;
      Printf.fprintf oc "\t.long\t0x%lx\n" (getfl f))
    data;
  Printf.fprintf oc ".text\n";
  List.iter (fun fundef -> h oc fundef) fundefs;
  Printf.fprintf oc ".globl\tmin_caml_start\n";
  Printf.fprintf oc "min_caml_start:\n";
  (* スタックポインタを一番底(2^20)にする *)
  Printf.fprintf oc "\taddi\t%s %s $1023\n" reg_sp reg_zero;
  Printf.fprintf oc "\taddi\t%s %s $10\n" reg_tmp reg_zero;
  Printf.fprintf oc "\tsll\t%s %s %s\n" reg_sp reg_sp reg_tmp;
  Printf.fprintf oc "\taddi\t%s %s $1023\n" reg_sp reg_sp;
  (* ヒープポインタ(グローバルポインタ)を中腹(2^10)にする *)
  Printf.fprintf oc "\taddi\t%s %s $1023\n" reg_hp reg_zero;
  stackset := S.empty;
  stackmap := [];
  Printf.fprintf oc "\t# Main Program Begin\n";
  g oc (NonTail(reg_rv), e);
  Printf.fprintf oc "\t# Main Program End\n";
  Printf.fprintf oc "\thalt\n";
