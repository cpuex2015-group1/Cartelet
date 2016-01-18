let eps = 0.000000001 in
let rec fib n =
  if n <= (1.0 +. 3.0 *. eps) then n else
  fib (n -. 1.0) +. fib (n -. 2.0) in
print_int (int_of_float (fib 30.0))
