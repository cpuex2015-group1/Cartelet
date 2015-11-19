let rec type_error x = x in
let rec adder x y = x + y in
print_int (adder
	     (type_error
		1)
	     (type_error (* Here should make an error *)
		1.0))
