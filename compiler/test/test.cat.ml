let rec fless x y = x < y in
let rec fispos x = x > 0.0 in
let rec fisneg x = x < 0.0 in
let rec fiszero x = (x = 0.0) in
let rec fhalf x = x *. 0.5 in
let rec fsqr x = x *. x in
let rec fneg x = -.x in

let rec f x = 
  if x <= 0 then ()
  else (print_float (float_of_int x);
	f (x-1)) in
f 10;


(*
let pi = 3.14159265358979 in
let rec f x = 
  if x <= 0 then ()
  else (print_float (cos (2 *. pi /. x));
	f (x-1)) in
f 8;
 *)
