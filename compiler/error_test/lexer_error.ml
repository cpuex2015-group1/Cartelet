let rec lexer_error x =
  let rec f x = x + 1 in
  let rec g x = x + 2 in
  let rec Error x = if (f x) > (g x) then 1 in
  Error x
in print_int (lexer_error 3)
