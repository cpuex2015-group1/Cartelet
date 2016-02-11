open KNormal

let rec g env = function
  | LetRec({ name = (f, t); args = yts; body = e1}, e2, p) ->
     let e1' = g env e1 in
     let fvs = S.diff (fv e1) (S.of_list (List.map fst yts)) in
     let fvs_mem = S.filter (fun x -> M.mem x env) fvs in
     LetRec({ name = (f, t); args = yts;
	      body =
		S.fold
		  (fun x e1 -> let e2 = M.find x env in
			       match e2 with
			       | Unit(p)     -> Let((x, Type.Unit),  e2, e1, p)
			       | Int(i, p)   -> Let((x, Type.Int),   e2, e1, p)
			       | Float(f, p) -> Let((x, Type.Float), e2, e1, p)
			       | _ -> e1)
		  fvs_mem
		  e1' },
	    g env e2, p)
  | Let((x, t), e1, e2, p) ->
     let e1' = g env e1 in
     Let((x, t), e1', g (M.add x e1' env) e2, p)
  | LetTuple(xts, y, e, p) -> LetTuple(xts, y, g env e, p) (* 後で考える *)
  | IfEq(x1, x2, e1, e2, p) -> IfEq(x1, x2, g env e1, g env e2, p)
  | IfLE(x1, x2, e1, e2, p) -> IfLE(x1, x2, g env e1, g env e2, p)
  | e -> e

let f = g M.empty
