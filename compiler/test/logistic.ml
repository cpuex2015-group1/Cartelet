(* Thanks to @levelfour *)
let rec logistic a n x0 =
  if n = 0 then x0
  else
    let x = logistic a (n - 1) x0 in
    a *. x *. (1.0 -. x)
(* 下の方の桁のx87との一致をごまかしている *)
in print_int (int_of_float ((logistic 3.8 15 0.5) *. 10000.0))
