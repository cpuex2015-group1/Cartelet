let arr = create_array 3 1 in
let arrf = create_array 10 2.0 in
let monarr = create_array 1 3 in
    arr.(1) <- 5;
    print_int arr.(0);
    print_newline ();
    print_int arr.(1);
    print_newline ();
    print_int (int_of_float arrf.(3));
    print_newline ();
    print_int monarr.(0);
