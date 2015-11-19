let arr = create_array 3 1.0 in
    print_int arr.(0)


(*
let rec f x = 
  if x <= 0 then ()
  else (print_float (float_of_int x);
	f (x-1)) in
f 10;
 *)

(*
let pi = 3.14159265358979 in
let rec f x = 
  if x <= 0 then ()
  else (print_float (cos (2 *. pi /. x));
	f (x-1)) in
f 8;
 *)
