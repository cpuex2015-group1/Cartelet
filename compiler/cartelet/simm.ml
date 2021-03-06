open Asm

let data' = ref []

(* CPU実験で要求されているものはOCamlのものと違うので再定義 *)
let int_of_float x =
  if x>=0.0 then int_of_float (x+.0.5) else int_of_float (x-.0.5)
let truncate x = int_of_float x

let rec g env = function (* 命令列の即値最適化 (caml2html: simm13_g) *)
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), Set(i, p), e) ->
      (* Format.eprintf "found simm %s = %d@." x i; *)
      let e' = g (M.add x i env) e in
      if List.mem x (fv e') then Let((x, t), Set(i, p), e') else
      ((* Format.eprintf "erased redundant Set to %s@." x; *)
       e')
  | Let(xt, exp, e) -> Let(xt, g' env exp, g env e)
and g' env = function (* 各命令の即値最適化 (caml2html: simm13_gprime) *)
  | Add(x, V(y), p) when M.mem y env -> Add(x, C(M.find y env), p)
  | Add(x, V(y), p) when M.mem x env -> Add(y, C(M.find x env), p)
  | Sub(x, V(y), p) when M.mem y env -> Sub(x, C(M.find y env), p)
  | Mul(x, V(y), p) when M.mem y env -> 
     let cy = M.find y env in
     if cy = 4 then Slli(x, 2, p) else failwith "multiply is supported only by 4"
  | Mul(x, V(y), p) when M.mem x env ->
     let cx = M.find x env in
     if cx = 4 then Slli(y, 2, p) else failwith "multiply is supported only by 4"
  | Div(x, V(y), p) when M.mem y env ->
     let cy = M.find y env in
     if cy = 2 then Srai(x, 1, p) else failwith "division is supported only by 2"
  | IfEq(x, V(y), e1, e2, p) when M.mem y env -> IfEq(x, C(M.find y env), g env e1, g env e2, p)
  | IfLE(x, V(y), e1, e2, p) when M.mem y env -> IfLE(x, C(M.find y env), g env e1, g env e2, p)
  | IfGE(x, V(y), e1, e2, p) when M.mem y env -> IfGE(x, C(M.find y env), g env e1, g env e2, p)
  | IfEq(x, V(y), e1, e2, p) when M.mem x env -> IfEq(y, C(M.find x env), g env e1, g env e2, p)
  | IfLE(x, V(y), e1, e2, p) when M.mem x env -> IfGE(y, C(M.find x env), g env e1, g env e2, p)
  | IfGE(x, V(y), e1, e2, p) when M.mem x env -> IfLE(y, C(M.find x env), g env e1, g env e2, p)
  | IfEq(x, y', e1, e2, p) -> IfEq(x, y', g env e1, g env e2, p)
  | IfLE(x, y', e1, e2, p) -> IfLE(x, y', g env e1, g env e2, p)
  | IfGE(x, y', e1, e2, p) -> IfGE(x, y', g env e1, g env e2, p)
  | IfFEq(x, y, e1, e2, p) -> IfFEq(x, y, g env e1, g env e2, p)
  | IfFLE(x, y, e1, e2, p) -> IfFLE(x, y, g env e1, g env e2, p)
  | e -> e

let h { name = l; args = xs; fargs = ys; body = e; ret = t } = (* トップレベル関数の即値最適化 *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

type num = Int of int | Float of float
let getInt = function Int(i) -> i | _ -> assert false
let getFloat = function Float(f) -> f | _ -> assert false

let rec g_pre env = function (* 浮動小数点数データが増えうる最適化を先にしておく *)
  | Ans(FToI(x, p)) when M.mem x env ->
     let d = int_of_float (getFloat (M.find x env)) in
     Ans(Set(d, p))
  | Ans(exp) -> Ans(exp)
  | Let((x, t), Set(i, p), e) ->
     let e' = g_pre (M.add x (Int(i)) env) e in
     if List.mem x (fv e') then Let((x, t), Set(i, p), e')
     else e'
  | Let((x, t), SetL(l, p), e) when List.exists (fun (l', _) -> l = l') !data' ->
     let (_, f) = List.find (fun (l', _) -> l = l') !data' in
     let e' = g_pre (M.add x (Float(f)) env) e in
     if List.mem x (fv e') then Let((x, t), SetL(l, p), e')
     else e'
  | Let((x1, t), IToF(x2, p), e) when M.mem x2 env ->
     let d = float_of_int (getInt (M.find x2 env)) in
     let l =
       try
	 let (l, _) = List.find (fun (_, d') -> d = d') !data' in
	 l
       with Not_found ->
	 let l = Id.L(Id.genid "l") in
	 data' := (l, d) :: !data';
	 l in
     let x3 = Id.genid "l" in
     let e' = g_pre (M.add x1 (Float(d)) env) e in
     if List.mem x1 (fv e') then
       Let((x3, Type.Int), SetL(l, p),
	   Let((x1, t), LdF(x3, C(0), p), e'))
     else e'
  | Let((x1, t), FToI(x2, p), e) when M.mem x2 env ->
     let d = int_of_float (getFloat (M.find x2 env)) in
     let e' = g_pre (M.add x1 (Int(d)) env) e in
     if List.mem x1 (fv e') then Let((x1, t), Set(d, p), e')
     else e'
  | Let((x1, t), Floor(x2, p), e) when M.mem x2 env ->
     let d = floor (getFloat (M.find x2 env)) in
     let l =
       try
	 let (l, _) = List.find (fun (_, d') -> d = d') !data' in
	 l
       with Not_found ->
	 let l = Id.L(Id.genid "l") in
	 data' := (l, d) :: !data';
	 l in
     let x3 = Id.genid "l" in
     let e' = g_pre (M.add x1 (Float(d)) env) e in
     if List.mem x1 (fv e') then
       Let((x3, Type.Int), SetL(l, p),
	   Let((x1, t), LdF(x3, C(0), p), e'))
     else e'
  | Let((x, t), exp, e) -> Let((x, t), exp, g_pre env e)

let h_pre { name = l; args = xs; fargs = ys; body = e; ret = t } = (* トップレベル関数の即値最適化 *)
  { name = l; args = xs; fargs = ys; body = g_pre M.empty e; ret = t }

let f (Prog(data, fundefs, e)) = (* プログラム全体の即値最適化 *)
  data' := data;
  let fundefs' = List.map h_pre fundefs in
  let e' = g_pre M.empty e in
  Prog(!data', List.map h fundefs', g M.empty e')
