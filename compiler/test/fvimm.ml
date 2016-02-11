let a = 1 in
let b = 2 in
let rec f x = x + a + b in
print_int (f (int_of_float 10.0))
