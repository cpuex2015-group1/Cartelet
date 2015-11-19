let rec f i =
  print_int i;
  print_newline ();
  if i<=0 then 0.0
  else (read_float ()) +. (f (i-1)) in
print_int (int_of_float (f 287))

(*
let in1 = read_int () in
let in2 = read_int () in
let in3 = read_int () in
let in4 = read_float () in
let in5 = read_float () in
let in6 = read_float () in
let in7 = read_float () in
let in8 = read_int () in
let in9 = read_int () in
let in10 = read_int () in
print_int in1;
print_newline ();
print_int in2;
print_newline ();
print_int in3;
print_newline ();
print_int (int_of_float in4);
print_newline ();
print_int (int_of_float in5);
print_newline ();
print_int (int_of_float in6);
print_newline ();
print_int (int_of_float in7);
print_newline ();
print_int in8;
print_newline ();
print_int in9;
print_newline ();
print_int in10;
print_newline ();
 *)
