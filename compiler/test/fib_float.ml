let rec fib n =
  if n <= 1.0 then n else
  fib (n -. 1.0) +. fib (n -. 2.0) in
print_int (int_of_float (fib 30.0))
