open Asm

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
     let cx = M.find y env in
     if cx = 4 then Slli(y, 2, p) else failwith "multiply is supported only by 4"
  | Div(x, V(y), p) when M.mem y env ->
     let cy = M.find y env in
     if cy = 2 then Slli(x, -1, p) else failwith "division is supported only by 2"
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

let f (Prog(data, fundefs, e)) = (* プログラム全体の即値最適化 *)
  Prog(data, List.map h fundefs, g M.empty e)
