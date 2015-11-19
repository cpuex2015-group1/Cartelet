let rec parser_error x =
  let rec f x = x + 1 in
  let rec g x = x + 2 in
  let rec here_makes_an_error x f (g x) in
  here_makes_an_error x
in print_int (parser_error x)
