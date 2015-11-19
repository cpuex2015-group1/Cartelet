let rec unterminated_comment n = 
  if n <= 1 then n else
  fib (n - 1) + fib (n - 2) in
print_int (fib 30) 
(* this comment is not terminated
