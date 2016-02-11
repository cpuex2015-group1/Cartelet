open KNormal

let threshold = ref 0

let rec size = function
  | IfEq(_, _, e1, e2, _) | IfLE(_, _, e1, e2, _)
  | Let(_, e1, e2, _) | LetRec({ body = e1 }, e2, _) -> 1 + size e1 + size e2
  | LetTuple(_, _, e, _) -> 1 + size e
  | _ -> 1

let rec f = function
  | Let(xt, IfEq(x2, x3, e3, e4, p2), e2, p1) when size e2 < !threshold ->
     let e2' = f e2 in
     IfEq(x2, x3, Let(xt, f e3, e2', p1),
	  Let(xt, f e4, e2', p1), p2)
  | Let(xt, IfLE(x2, x3, e3, e4, p2), e2, p1) when size e2 < !threshold ->
     let e2' = f e2 in
     IfLE(x2, x3, Let(xt, f e3, e2', p1),
	  Let(xt, f e4, e2', p1), p2)
  | Let(xt, e1, e2, p1) -> Let(xt, f e1, f e2, p1)
  | IfEq(x1, x2, e1, e2, p) -> IfEq(x1, x2, f e1, f e2, p)
  | IfLE(x1, x2, e1, e2, p) -> IfLE(x1, x2, f e1, f e2, p)
  | LetRec({ name = xt; args = yts; body = e1 }, e2, p) ->
     LetRec({ name = xt; args = yts; body = f e1 }, f e2, p)
  | LetTuple(xts, y, e, p) -> LetTuple(xts, y, f e, p)
  | e -> e
