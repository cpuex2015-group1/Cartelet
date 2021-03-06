open Asm

(* for register coalescing *)
(* [XXX] Callがあったら、そこから先は無意味というか逆効果なので追わない。
         そのために「Callがあったかどうか」を返り値の第1要素に含める。 *)
let rec target' src (dest, t) = function
  | Mov(x, _) when x = src && is_reg dest ->
      assert (t <> Type.Unit);
      assert (t <> Type.Float);
      false, [dest]
  | FMov(x, _) when x = src && is_reg dest ->
      assert (t = Type.Float);
      false, [dest]
  | IfEq(_, _, e1, e2, _) | IfLE(_, _, e1, e2, _) | IfGE(_, _, e1, e2, _)
  | IfFEq(_, _, e1, e2, _) | IfFLE(_, _, e1, e2, _) ->
      let c1, rs1 = target src (dest, t) e1 in
      let c2, rs2 = target src (dest, t) e2 in
      c1 && c2, rs1 @ rs2
  | CallCls(x, ys, zs, _) ->
      true, (target_args src regs 0 ys @
	     target_args src fregs 0 zs @
             if x = src then [reg_cl] else [])
  | CallDir(_, ys, zs, _) ->
      true, (target_args src regs 0 ys @
	     target_args src fregs 0 zs)
  | _ -> false, []
and target src dest = function (* register targeting (caml2html: regalloc_target) *)
  | Ans(exp) -> target' src dest exp
  | Let(xt, exp, e) ->
      let c1, rs1 = target' src xt exp in
      if c1 then true, rs1 else
      let c2, rs2 = target src dest e in
      c2, rs1 @ rs2
and target_args src all n = function (* auxiliary function for Call *)
  | [] -> []
  | y :: ys when src = y (* && n <= List.length all - 2 *) ->
      all.(n) :: target_args src all (n + 1) ys
  | _ :: ys -> target_args src all (n + 1) ys
(* "register sourcing" (?) as opposed to register targeting *)
(* （x86の2オペランド命令のためのregister coalescing） *)
let rec source t = function
  | Ans(exp) -> source' t exp
  | Let(_, _, e) -> source t e
and source' t = function
  | Mov(x, _) | Neg(x, _) |
    Add(x, C _, _) | Sub(x, _, _) | Mul(x, C _, _) | Div(x, _, _) |
    Slli(x, _, _) | Srai(x, _, _) |
    FMov(x, _) | FNeg(x, _) | FSub(x, _, _) | FDiv(x, _, _) |
    FInv(x, _) | FSqrt(x, _) | FAbs(x, _) |
    FToI(x, _) | IToF(x, _) | Floor(x, _) |
    Send(x, _) -> [x]
  | Add(x, V y, _) | FAdd(x, y, _) | FMul(x, y, _) -> [x; y]
  | Mul(x, V y, _) -> assert false
  | IfEq(_, _, e1, e2, _) | IfLE(_, _, e1, e2, _) | IfGE(_, _, e1, e2, _)
  | IfFEq(_, _, e1, e2, _) | IfFLE(_, _, e1, e2, _) ->
      source t e1 @ source t e2
  (* send無くて大丈夫? *)
  | CallCls _ | CallDir _ ->
      (match t with
	 Type.Unit -> []
       | Type.Float -> [freg_rv]
       | _ -> [reg_rv])
  | _ -> []

type alloc_result = (* allocにおいてspillingがあったかどうかを表すデータ型 *)
  | Alloc of Id.t (* allocated register *)
  | Spill of Id.t (* spilled variable *)
let rec alloc cont regenv x t prefer =
  (* allocate a register or spill a variable *)
  assert (not (M.mem x regenv));
  let all =
    match t with
    | Type.Unit -> [] (* dummy *)
    | Type.Float -> allfregs
    | _ -> allregs in
  if all = [] then Alloc("%unit") else (* [XX] ad hoc optimization *)
  if is_reg x then Alloc(x) else
  let free = fv cont in
  try
    let live = (* 生きているレジスタ *)
      S.add reg_cl
	    (List.fold_left
               (fun live y ->
		if is_reg y then S.add y live else
		  try S.add (M.find y regenv) live
		  with Not_found -> live)
               S.empty
               free) in
    let r = (* そうでないレジスタを探す *)
      List.find
        (fun r -> not (S.mem r live))
        (List.filter
	   (fun x -> match t with
		     | Type.Unit -> assert false
		     | Type.Float -> is_fpr x
		     | _ -> is_gpr x)
	   (prefer @ all)) in
    (* Format.eprintf "allocated %s to %s@." x r; *)
    Alloc(r)
  with Not_found ->
    Format.eprintf "register allocation failed for %s@." x;
    let y = (* 型の合うレジスタ変数を探す *)
      List.find
        (fun y ->
	  not (is_reg y) &&
          try (let x = M.find y regenv in
	       (x <> reg_cl) && (List.mem x all))
          with Not_found -> false)
        (List.rev free) in
    Format.eprintf "spilling %s from %s@." y (M.find y regenv);
    Spill(y)

(* auxiliary function for g and g'_and_restore *)
let add x r regenv =
  if is_reg x then (assert (x = r); regenv) else
  M.add x r regenv

(* auxiliary functions for g' *)
exception NoReg of Id.t * Type.t
let find x t regenv =
  if is_reg x then x else
  try M.find x regenv
  with Not_found -> raise (NoReg(x, t))
let find' x' regenv =
  match x' with
  | V(x) -> V(find x Type.Int regenv)
  | c -> c

let rec g dest cont regenv = function (* 命令列のレジスタ割り当て (caml2html: regalloc_g) *)
  | Ans(exp) -> g'_and_restore dest cont regenv exp
  | Let((x, t) as xt, exp, e) ->
      assert (not (M.mem x regenv));
      let cont' = concat e dest cont in
      let (e1', regenv1) = g'_and_restore xt cont' regenv exp in
      let (_call, targets) = target x dest cont' in
      let sources = source t e1' in
      (* レジスタ間のmovよりメモリを介するswapのほうが問題なので、sourcesよりtargetsを優先 *)
      (match alloc cont' regenv1 x t (targets @ sources) with
      | Spill(y) ->
	  let r = M.find y regenv1 in
	  let (e2', regenv2) = g dest cont (add x r (M.remove y regenv1)) e in
	  let save =
	    try Save(M.find y regenv, y, Asm.pos_of_exp exp)
	    with Not_found -> Nop(Asm.pos_of_exp exp) in
	  (seq(save, concat e1' (r, t) e2'), regenv2)
      | Alloc(r) ->
	  let (e2', regenv2) = g dest cont (add x r regenv1) e in
	  (concat e1' (r, t) e2', regenv2))
and g'_and_restore dest cont regenv exp = (* 使用される変数をスタックからレジスタへRestore (caml2html: regalloc_unspill) *)
  try g' dest cont regenv exp
  with NoReg(x, t) ->
    ((* Format.eprintf "restoring %s@." x; *)
     g dest cont regenv (Let((x, t), Restore(x, Asm.pos_of_exp exp), Ans(exp))))
and g' dest cont regenv = function (* 各命令のレジスタ割り当て (caml2html: regalloc_gprime) *)
  | Nop _ | Set _ | SetL _ | Recv _ | Comment _ | Restore _ as exp -> (Ans(exp), regenv)
  | Mov(x, p) -> (Ans(Mov(find x Type.Int regenv, p)), regenv)
  | Neg(x, p) -> (Ans(Neg(find x Type.Int regenv, p)), regenv)
  | Add(x, y', p) -> (Ans(Add(find x Type.Int regenv, find' y' regenv, p)), regenv)
  | Sub(x, y', p) -> (Ans(Sub(find x Type.Int regenv, find' y' regenv, p)), regenv)
  | Mul(x, y', p) -> (Ans(Mul(find x Type.Int regenv, find' y' regenv, p)), regenv)
  | Div(x, y', p) -> (Ans(Div(find x Type.Int regenv, find' y' regenv, p)), regenv)
  | Slli(x, i, p) -> (Ans(Slli(find x Type.Int regenv, i, p)), regenv)
  | Srai(x, i, p) -> (Ans(Srai(find x Type.Int regenv, i, p)), regenv)
  | Ld(x, y', p) -> (Ans(Ld(find x Type.Int regenv, find' y' regenv, p)), regenv)
  | St(x, y, z', p) -> (Ans(St(find x Type.Int regenv, find y Type.Int regenv, find' z' regenv, p)), regenv)
  | FMov(x, p) -> (Ans(FMov(find x Type.Float regenv, p)), regenv)
  | FNeg(x, p) -> (Ans(FNeg(find x Type.Float regenv, p)), regenv)
  | FAdd(x, y, p) -> (Ans(FAdd(find x Type.Float regenv, find y Type.Float regenv, p)), regenv)
  | FSub(x, y, p) -> (Ans(FSub(find x Type.Float regenv, find y Type.Float regenv, p)), regenv)
  | FMul(x, y, p) -> (Ans(FMul(find x Type.Float regenv, find y Type.Float regenv, p)), regenv)
  | FDiv(x, y, p) -> (Ans(FDiv(find x Type.Float regenv, find y Type.Float regenv, p)), regenv)
  | FInv(x, p) -> (Ans(FInv(find x Type.Float regenv, p)), regenv)
  | FSqrt(x, p) -> (Ans(FSqrt(find x Type.Float regenv, p)), regenv)
  | FAbs(x, p) -> (Ans(FAbs(find x Type.Float regenv, p)), regenv)
  | LdF(x, y', p) -> (Ans(LdF(find x Type.Int regenv, find' y' regenv, p)), regenv)
  | StF(x, y, z', p) -> (Ans(StF(find x Type.Float regenv, find y Type.Int regenv, find' z' regenv, p)), regenv)
  | FToI(x, p) -> (Ans(FToI(find x Type.Float regenv, p)), regenv)
  | IToF(x, p) -> (Ans(IToF(find x Type.Int regenv, p)), regenv)
  | Floor(x, p) -> (Ans(Floor(find x Type.Float regenv, p)), regenv)
  | Send(x, p) -> (Ans(Send(find x Type.Int regenv, p)), regenv)
  | IfEq(x, y', e1, e2, p) as exp -> g'_if dest cont regenv exp (fun e1' e2' -> IfEq(find x Type.Int regenv, find' y' regenv, e1', e2', p)) e1 e2 p
  | IfLE(x, y', e1, e2, p) as exp -> g'_if dest cont regenv exp (fun e1' e2' -> IfLE(find x Type.Int regenv, find' y' regenv, e1', e2', p)) e1 e2 p
  | IfGE(x, y', e1, e2, p) as exp -> g'_if dest cont regenv exp (fun e1' e2' -> IfGE(find x Type.Int regenv, find' y' regenv, e1', e2', p)) e1 e2 p
  | IfFEq(x, y, e1, e2, p) as exp -> g'_if dest cont regenv exp (fun e1' e2' -> IfFEq(find x Type.Float regenv, find y Type.Float regenv, e1', e2', p)) e1 e2 p
  | IfFLE(x, y, e1, e2, p) as exp -> g'_if dest cont regenv exp (fun e1' e2' -> IfFLE(find x Type.Float regenv, find y Type.Float regenv, e1', e2', p)) e1 e2 p
  | CallCls(x, ys, zs, p) as exp -> g'_call dest cont regenv exp (fun ys zs -> CallCls(find x Type.Int regenv, ys, zs, p)) ys zs p
  | CallDir(l, ys, zs, p) as exp -> g'_call dest cont regenv exp (fun ys zs -> CallDir(l, ys, zs, p)) ys zs p
  | Save(x, y, _) -> assert false
and g'_if dest cont regenv exp constr e1 e2 p = (* ifのレジスタ割り当て (caml2html: regalloc_if) *)
  let (e1', regenv1) = g dest cont regenv e1 in
  let (e2', regenv2) = g dest cont regenv e2 in
  let regenv' = (* 両方に共通のレジスタ変数だけ利用 *)
    List.fold_left
      (fun regenv' x ->
        try
	  if is_reg x then regenv' else
          let r1 = M.find x regenv1 in
          let r2 = M.find x regenv2 in
          if r1 <> r2 then regenv' else
	  M.add x r1 regenv'
        with Not_found -> regenv')
      M.empty
      (fv cont) in
  (List.fold_left
     (fun e x ->
       if x = fst dest || not (M.mem x regenv) || M.mem x regenv' then e else
       seq(Save(M.find x regenv, x, p), e)) (* そうでない変数は分岐直前にセーブ *)
     (Ans(constr e1' e2'))
     (fv cont),
   regenv')
and g'_call dest cont regenv exp constr ys zs p = (* 関数呼び出しのレジスタ割り当て (caml2html: regalloc_call) *)
  (List.fold_left
     (fun e x ->
       if x = fst dest || not (M.mem x regenv) then e else
       seq(Save(M.find x regenv, x, p), e))
     (Ans(constr
	    (List.map (fun y -> find y Type.Int regenv) ys)
	    (List.map (fun z -> find z Type.Float regenv) zs)))
     (fv cont),
   M.empty)

let h { name = Id.L(x); args = ys; fargs = zs; body = e; ret = t } = (* 関数のレジスタ割り当て (caml2html: regalloc_h) *)
  let regenv = M.add x reg_cl M.empty in
  let (i, arg_regs, regenv) =
    List.fold_left
      (fun (i, arg_regs, regenv) y ->
        let r = regs.(i) in
        (i + 1,
	 arg_regs @ [r],
	 (assert (not (is_reg y));
	  M.add y r regenv)))
      (0, [], regenv)
      ys in
  let (d, farg_regs, regenv) =
    List.fold_left
      (fun (d, farg_regs, regenv) z ->
        let fr = fregs.(d) in
        (d + 1,
	 farg_regs @ [fr],
	 (assert (not (is_reg z));
	  M.add z fr regenv)))
      (0, [], regenv)
      zs in
  let a =
    match t with
    | Type.Unit -> Id.gentmp Type.Unit
    | Type.Float -> freg_rv
    | _ -> reg_rv in
  let (e', regenv') = g (a, t) (Ans(Mov(a, Lexing.dummy_pos))) regenv e in
  { name = Id.L(x); args = arg_regs; fargs = farg_regs; body = e'; ret = t }

let f (Prog(data, fundefs, e)) = (* プログラム全体のレジスタ割り当て (caml2html: regalloc_f) *)
  Format.eprintf "register allocation: may take some time (up to a few minutes, depending on the size of functions)@.";
  let fundefs' = List.map h fundefs in
  let e', regenv' = g (Id.gentmp Type.Unit, Type.Unit) (Ans(Nop(Lexing.dummy_pos))) M.empty e in
  Prog(data, fundefs', e')
