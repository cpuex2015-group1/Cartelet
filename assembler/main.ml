module TagDict = Map.Make(String)

let rec print_str_list l =
    match l with
    | [] -> ()
    | e :: l' -> Printf.printf "%s\n" e; print_str_list l'

let rec print_triple_list xs =
    match xs with
    | [] -> ()
    | (i1, i2, str) :: xs' -> Printf.printf "(%d, %d, %s)\n" i1 i2 str; print_triple_list xs'

let rec print_double_list xs =
    match xs with
    | [] -> ()
    | (i1, str) :: xs' -> Printf.printf "(%d, %s)\n" i1 str; print_double_list xs'

let half_byte_to_hex hb =
    match hb with
    | "0000" -> "0"
    | "0001" -> "1"
    | "0010" -> "2"
    | "0011" -> "3"
    | "0100" -> "4"
    | "0101" -> "5"
    | "0110" -> "6"
    | "0111" -> "7"
    | "1000" -> "8"
    | "1001" -> "9"
    | "1010" -> "a"
    | "1011" -> "b"
    | "1100" -> "c"
    | "1101" -> "d"
    | "1110" -> "e"
    | "1111" -> "f"
    | _ -> raise (Failure "matching failed in half_byte_to_hex")

let hex_to_half_byte hex =
    match hex with
    | "0" -> "0000"
    | "1" -> "0001"
    | "2" -> "0010"
    | "3" -> "0011"
    | "4" -> "0100"
    | "5" -> "0101"
    | "6" -> "0110"
    | "7" -> "0111"
    | "8" -> "1000"
    | "9" -> "1001"
    | "A" | "a" -> "1010"
    | "B" | "b" -> "1011"
    | "C" | "c" -> "1100"
    | "D" | "d" -> "1101"
    | "E" | "e" -> "1110"
    | "F" | "f" -> "1111"
    | _ -> raise (Failure "matching failed in hex_to_half_byte")

let rec to_bin dec =
    let half = dec / 2 in
    if dec mod 2 = 0 then
        if half > 0 then
            to_bin half ^ "0"
        else
            ""
    else
        to_bin half ^ "1"

let rec not' binstr =
    if String.length binstr > 0 then
        let car = String.sub binstr 0 1 in
        let cdr = String.sub binstr 1 (String.length binstr - 1) in
        match car with
        | "0" -> "1" ^ not' cdr
        | "1" -> "0" ^ not' cdr
        | _ -> raise (Failure "matching failed in not'")
    else
        ""

let rec to_dec binstr =
    if String.length binstr > 0 then
        let head = String.sub binstr 0 (String.length binstr - 1) in
        let tail = String.sub binstr (String.length binstr - 1) 1 in
        int_of_string tail + 2 * to_dec head
    else
        0

let neg binstr =
    to_bin (to_dec (not' binstr) + 1)

let rec zfill str num =
    if String.length str < num then
        zfill ("0" ^ str) num
    else
        str

let reg_to_bin str =
    let num = int_of_string (String.sub str 2 (String.length str - 2)) in (* %r とかを読み飛ばす*)
    zfill (to_bin num) 5

let rec repeat str num =
    if num > 0 then
        str ^ repeat str (num - 1)
    else ""

let dec_imm_to_bin_for_data str =
    let car = String.sub str 0 1 in
    let cdr = String.sub str 1 (String.length str - 1) in
    match car with
    | "-" -> neg (zfill (to_bin (int_of_string cdr)) 32)
    | _   -> zfill (to_bin (int_of_string str)) 32

let dec_imm_to_bin str =
    let car = String.sub str 0 1 in
    let cdr = String.sub str 1 (String.length str - 1) in
    match car with
    | "-" -> neg (zfill (to_bin (int_of_string cdr)) 16)
    | _   -> zfill (to_bin (int_of_string str)) 16

(* hex をそのまま bin にするだけ (符号は非対応) *)
let rec hex_imm_to_bin str =
    if String.length str > 0 then
        let car = String.sub str 0 1 in
        let cdr = String.sub str 1 (String.length str - 1) in
        hex_to_half_byte car ^ hex_imm_to_bin cdr
    else
        ""

let imm_to_bin_for_data str =
    if String.length str > 2 && String.sub str 0 2 = "0x" then
        zfill (hex_imm_to_bin (String.sub str 2 (String.length str - 2))) 32
    else if String.length str > 2 && String.sub str 0 2 = "0b" then
        zfill (String.sub str 2 (String.length str - 2)) 32
    else
        dec_imm_to_bin_for_data str


let imm_to_bin' str =
    if String.length str > 2 && String.sub str 0 2 = "0x" then
        zfill (hex_imm_to_bin (String.sub str 2 (String.length str - 2))) 16
    else if String.length str > 2 && String.sub str 0 2 = "0b" then
        zfill (String.sub str 2 (String.length str - 2)) 16
    else
        dec_imm_to_bin str

let imm_to_bin str =
    let res = imm_to_bin' (String.sub str 1 (String.length str - 1)) in
    if String.length res <= 16 then
        res
    else
        raise (Failure "immediate overflow")

let imm_to_bin_unlimited str =
    imm_to_bin' (String.sub str 1 (String.length str - 1))

let dsp_to_bin str =
    let res = imm_to_bin' str in
    if String.length res <= 16 then
        res
    else
        raise (Failure "immediate overflow")

let tag_to_bin str line tag_dict =
    let target_line = TagDict.find str tag_dict in
    dsp_to_bin (string_of_int (target_line - line - 1))

let abs_tag_to_bin str line tag_dict =
    let target_line = TagDict.find str tag_dict in
    dsp_to_bin (string_of_int (target_line))

let imm_or_abs_tag_to_bin str line tag_dict =
    if TagDict.exists (fun key _ -> key = str) tag_dict then
        abs_tag_to_bin str line tag_dict
    else
        imm_to_bin str

let tag_counter = ref 0

let get_fresh_tag () =
    tag_counter := !tag_counter + 1;
    "_asm_tag" ^ string_of_int !tag_counter

let first_half_of_imm imm =
    let binstr = imm_to_bin_unlimited imm in
    String.sub (zfill binstr 32) 0 16

let last_half_of_imm imm =
    let binstr = imm_to_bin_unlimited imm in
    String.sub (zfill binstr 32) 16 16

let convert_pseudo_ops' line asm =
    let tokens = Str.split (Str.regexp "[ \t()]+") asm in
    let head = List.hd tokens in
    let (label, tokens) = if String.sub head (String.length head - 1) 1 = ":" then ([(line, head)], List.tl tokens) else ([], tokens) in
    if List.length tokens > 0 then
        match List.hd tokens with
        | "jalr" ->
            let tag = get_fresh_tag () in
            label @
            [(line, "addiu %r31 %r0 " ^ tag);
             (line, "jr " ^ List.nth tokens 1);
             (line, tag ^ ":")]
        | "addiu32" ->
            label @
            [(line, "addiu " ^ List.nth tokens 1 ^ " %r0 $0b" ^ first_half_of_imm (List.nth tokens 3));
            (line, "slli " ^ List.nth tokens 1 ^ " " ^ List.nth tokens 1 ^ " $16");
            (line, "addiu " ^ List.nth tokens 1 ^ " " ^ List.nth tokens 1 ^ " $0b" ^ last_half_of_imm (List.nth tokens 3))]
        | _ -> [(line, asm)]
    else
        [(line, asm)]


let rec convert_pseudo_ops text =
    let converted = List.flatten (List.map (fun (line, asm) -> convert_pseudo_ops' line asm) text) in
    if converted = text then
        converted
    else
        convert_pseudo_ops converted

let is_integer_string str = 
  try ignore (int_of_string str); true
  with _ -> false

let is_gpr str =
  (String.sub str 0 2) = "%r" &&
    is_integer_string (String.sub str 2 ((String.length str) - 2))

let is_fpr str = 
  (String.sub str 0 2) = "%f" &&
    is_integer_string (String.sub str 2 ((String.length str) - 2))

exception Invalid_Reg_Name of int

(* 第2引数にオペランド数を指定する *)
let rec assert_reg_name_gpr tokens = function
  | 0 -> ()
  | n when is_gpr (List.nth tokens n) -> assert_reg_name_gpr tokens (n-1)
  | n -> raise (Invalid_Reg_Name n)

let rec assert_reg_name_fpr tokens = function
  | 0 -> ()
  | n when is_fpr (List.nth tokens n) -> assert_reg_name_fpr tokens (n-1)
  | n -> raise (Invalid_Reg_Name n)

let asm_to_bin line str tag_dict =
    Printf.eprintf "%s\n" str;
    let tokens = Str.split (Str.regexp "[ \t()]+") str in
    try match List.hd tokens with
    (* 整数命令 *)
    | "nop"   -> repeat "0" 32
    | "add"   -> (assert_reg_name_gpr tokens 3;
		  "000001" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             reg_to_bin (List.nth tokens 3) ^ repeat "0" 11)
    | "addi"  -> (assert_reg_name_gpr tokens 2;
		  "000010" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             imm_or_abs_tag_to_bin (List.nth tokens 3) line tag_dict)
    | "addiu" -> (assert_reg_name_gpr tokens 2;
		  "000011" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             imm_or_abs_tag_to_bin (List.nth tokens 3) line tag_dict)
    | "sub"   -> (assert_reg_name_gpr tokens 3;
		  "000100" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             reg_to_bin (List.nth tokens 3) ^ repeat "0" 11)
    | "slli"  -> (assert_reg_name_gpr tokens 2;
		  "000101" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             imm_to_bin (List.nth tokens 3))
    | "srai"  -> (assert_reg_name_gpr tokens 2;
		  "000110" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             imm_to_bin (List.nth tokens 3))
    | "beq"   -> (assert_reg_name_gpr tokens 2;
		  "001000" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "bneq"  -> (assert_reg_name_gpr tokens 2;
		  "001001" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "blt"   -> (assert_reg_name_gpr tokens 2;
		  "001010" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "ble"   -> (assert_reg_name_gpr tokens  2;
		  "001011" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "jr"    -> (assert_reg_name_gpr tokens 1;
		  "001100" ^ reg_to_bin (List.nth tokens 1) ^ repeat "0" 21)
    | "jal"   -> "001101" ^ repeat "0" 10 ^
                            abs_tag_to_bin (List.nth tokens 1) line tag_dict
    | "lw"    -> (if not (is_gpr (List.nth tokens 1)) then raise (Invalid_Reg_Name 1);
		  if not (is_gpr (List.nth tokens 3)) then raise (Invalid_Reg_Name 3);
		  "010000" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 3) ^
                             dsp_to_bin (List.nth tokens 2))
    | "sw"    -> (if not (is_gpr (List.nth tokens 2)) then raise (Invalid_Reg_Name 2);
		  if not (is_gpr (List.nth tokens 3)) then raise (Invalid_Reg_Name 3);
		  "010001" ^ reg_to_bin (List.nth tokens 2) ^
                             reg_to_bin (List.nth tokens 3) ^
                             dsp_to_bin (List.nth tokens 1))
    | "send"
    | "send8" -> (assert_reg_name_gpr tokens 1;
		  "011101" ^ reg_to_bin (List.nth tokens 1) ^ repeat "0" 21)
    | "recv"
    | "recv8" -> (assert_reg_name_gpr tokens 1;
		  "011110" ^ reg_to_bin (List.nth tokens 1) ^ repeat "0" 21)
    | "halt"  -> "011111" ^ repeat "0" 26
    (* 浮動小数点数命令 *)
    | "fmov"  -> (assert_reg_name_fpr tokens 2;
		  "100000" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "fadd"  -> (assert_reg_name_fpr tokens 3;
		  "100001" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             reg_to_bin (List.nth tokens 3) ^ repeat "0" 11)
    | "fsub"  -> (assert_reg_name_fpr tokens  3;
		  "100010" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             reg_to_bin (List.nth tokens 3) ^ repeat "0" 11)
    | "fmul"  -> (assert_reg_name_fpr tokens  3;
		  "100011" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             reg_to_bin (List.nth tokens 3) ^ repeat "0" 11)
    | "finv"  -> (assert_reg_name_fpr tokens  2;
		  "100100" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "fsqrt" -> (assert_reg_name_fpr tokens 2;
		  "100101" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "fneg"  -> (assert_reg_name_fpr tokens 2;
		  "100110" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "fabs"  -> (assert_reg_name_fpr tokens 2;
		  "100111" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "ftoi"  -> (if not (is_gpr (List.nth tokens 1)) then raise (Invalid_Reg_Name 1);
		  if not (is_fpr (List.nth tokens 2)) then raise (Invalid_Reg_Name 2);
		  "101100" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "itof"  -> (if not (is_fpr (List.nth tokens 1)) then raise (Invalid_Reg_Name 1);
		  if not (is_gpr (List.nth tokens 2)) then raise (Invalid_Reg_Name 2);
		  "101101" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "floor" -> (assert_reg_name_fpr tokens 2;
		  "101110" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^ repeat "0" 16)
    | "fbeq"  -> (assert_reg_name_fpr tokens 2;
		  "101000" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "fbneq" -> (assert_reg_name_fpr tokens 2;
		  "101001" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "fblt"  -> (assert_reg_name_fpr tokens 2;
		  "101010" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "fble"  -> (assert_reg_name_fpr tokens 2;
		  "101011" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 2) ^
                             tag_to_bin (List.nth tokens 3) line tag_dict)
    | "flw"   -> (if not (is_fpr (List.nth tokens 1)) then raise (Invalid_Reg_Name 1);
		  if not (is_gpr (List.nth tokens 3)) then raise (Invalid_Reg_Name 3);
		  "110000" ^ reg_to_bin (List.nth tokens 1) ^
                             reg_to_bin (List.nth tokens 3) ^
                             dsp_to_bin (List.nth tokens 2))
    | "fsw"   -> (if not (is_gpr (List.nth tokens 2)) then raise (Invalid_Reg_Name 2);
		  if not (is_fpr (List.nth tokens 3)) then raise (Invalid_Reg_Name 3);
		  "110001" ^ reg_to_bin (List.nth tokens 2) ^
                             reg_to_bin (List.nth tokens 3) ^
                             dsp_to_bin (List.nth tokens 1))
    | _ -> raise (Failure "matching failed in asm_to_bin")
    with
      | Invalid_Reg_Name(n) -> raise (Failure (Printf.sprintf "Invalid format of registor naming: %s" str))

let rec split_by_num str num =
    let l = String.length str in
    if l > num then
        String.sub str 0 num :: split_by_num (String.sub str num (l - num)) num
    else
        [str]

let bin_to_hex str =
    let str = (
        let r = String.length str mod 4 in
        if r != 0 then
            repeat "0" (4 - r) ^ str
        else
            str) in
    let half_bytes = split_by_num str 4 in
    List.fold_left (fun acc hb -> acc ^ half_byte_to_hex hb) "" half_bytes


let asm_to_hex line str tag_dict =
    bin_to_hex (asm_to_bin line str tag_dict)

let remove_comment str =
    try
        String.sub str 0 (String.index str '#')
    with Not_found -> str

let assemble asms tag_dict mode =
    let asms = List.filter (fun (_, x) -> not (Str.string_match (Str.regexp "[\t ]*$") x 0)) (List.rev_map (fun (line, str) -> (line, remove_comment str)) asms) in
    if mode = "hexstr" then
        List.fold_left (fun acc (line, asm) -> acc ^ asm_to_hex line asm tag_dict) "" asms
    else
        List.fold_left (fun acc (line, asm) -> acc ^ "x\"" ^ asm_to_hex line asm tag_dict ^ "\",\n") "" asms

let rec extract_data' data asms =
    match asms with
    | [] -> data
    | (_, asm) :: asms' when asm = ".text" -> data
    | (_, asm) :: asms' when asm = ".data" -> extract_data' data asms'
    | lineasm :: asms' -> extract_data' (data @ [lineasm]) asms'

let extract_data asms =
    extract_data' [] asms

let rec extract_text asms =
    match asms with
    | [] -> []
    | (_, asm) :: asms' when asm = ".text" -> asms'
    | _ :: asms' -> extract_text asms'

let rec trim_spaces_forward str =
    if String.length str > 0 then
        let car = String.sub str 0 1 in
        let cdr = String.sub str 1 (String.length str - 1) in
        match car with
        | "\t" | " " -> trim_spaces_forward cdr
        | _ -> str
    else
        str

let rec trim_spaces_backward str =
    if String.length str > 0 then
        let tl = String.sub str (String.length str - 1) 1 in
        let hd = String.sub str 0 (String.length str - 1) in
        match tl with
        | "\t" | " " -> trim_spaces_backward hd
        | _ -> str
    else
        str

let rec trim_comment asms =
    if asms = [] then
        []
    else
        let (line, asm) = List.hd asms in
        if Str.string_match (Str.regexp "^[\t ]*$") asm 0 then
            trim_comment (List.tl asms)
        else if Str.string_match (Str.regexp "^[\t ]*#.*$") asm 0 then
            trim_comment (List.tl asms)
        else
            let asm = (try
                String.sub asm 0 (String.index asm '#')
            with Not_found -> asm) in
            let asm = trim_spaces_forward (trim_spaces_backward asm) in
            (line, asm) :: trim_comment (List.tl asms)

let optimize text = (* TODO *)
    text

let is_tag_def str =
    Str.string_match (Str.regexp "^.*:$") str 0

let has_tag_def str =
    Str.string_match (Str.regexp "^.*:") str 0

let get_tag_def str = (* raises Not_found exception *)
    String.sub str 0 (String.index str ':')

let remove_tag_def str =
    try
        let index = String.index str ':' in
        trim_spaces_forward (String.sub str (index + 1) (String.length str - index - 1))
    with Not_found -> str

let rec attach_logical_line_num' num text =
    match text with
    | [] -> []
    | (line, asm) :: asms' when is_tag_def asm -> (num, line, asm) :: attach_logical_line_num' num asms'
    | (line, asm) :: asms' -> (num, line, asm) :: attach_logical_line_num' (num + 1) asms'

let attach_logical_line_num text =
    attach_logical_line_num' 0 text

let rec create_tag_dict' tag_dict text =
    match text with
    | [] -> tag_dict
    | (lline, pline, asm) :: asms' when has_tag_def asm -> create_tag_dict' (TagDict.add (get_tag_def asm) lline tag_dict) asms'
    | asm :: asms' -> create_tag_dict' tag_dict asms'

let create_tag_dict text =
    create_tag_dict' TagDict.empty text

let rec strip_tag_def asms =
    match asms with
    | [] -> []
    | (lline, pline, asm) :: asms' when is_tag_def asm -> strip_tag_def asms'
    | (lline, pline, asm) :: asms' when has_tag_def asm -> (lline, pline, remove_tag_def asm) :: strip_tag_def asms'
    | asm :: asms' -> asm :: strip_tag_def asms'

let has_globl str =
    Str.string_match (Str.regexp "[.]globl") str 0

let get_globl_tag str =
    let tokens = Str.split (Str.regexp "[ \t]+") str in
    List.nth tokens 1

let rec get_entry_point text =
    match text with
    | [] -> raise (Failure "entry point not found")
    | (_, asm) :: asms' when has_globl asm -> get_globl_tag asm
    | asm :: asms' -> get_entry_point asms'

let rec remove_entry_point_mark text =
    match text with
    | [] -> []
    | (_, asm) :: asms' when has_globl asm -> asms'
    | asm :: asms' -> asm :: remove_entry_point_mark asms'

let output_format = ref "h" (* Hexstr Simulator Object Binary *)

let rec print_by_byte bin_str =
    if String.length bin_str > 8 then
        (Printf.printf "x\"%s\", " (bin_to_hex (String.sub bin_str 0 8));
        print_by_byte (String.sub bin_str 8 (String.length bin_str - 8)))
    else if String.length bin_str > 0 then
        Printf.printf "x\"%s\", " (bin_to_hex bin_str)
    else
        ()

let rec output_format_sim prog =
    match prog with
    | [] -> ()
    | l :: prog' -> print_by_byte l; Printf.printf "\n"; output_format_sim prog'

let rec output_format_hex prog =
    match prog with
    | [] -> ()
    | l :: prog' -> Printf.printf "%s" (bin_to_hex l); output_format_hex prog'

let rec int32_of_bin' i32 bin =
    if String.length bin > 0 then
        let car = String.sub bin 0 1 in
        let cdr = String.sub bin 1 (String.length bin - 1) in
        let two = Int32.add Int32.one Int32.one in
        match car with
        | "0" -> int32_of_bin' (Int32.mul i32 two) cdr
        | "1" -> int32_of_bin' (Int32.add (Int32.mul i32 two) Int32.one) cdr
        | _ -> raise (Failure "matching failed in int32_of_bin'")
    else
        i32

let int32_of_bin bin =
    int32_of_bin' Int32.zero bin

let output_int32 i =
    output_byte stdout (Int32.to_int (Int32.shift_right i 24));
    output_byte stdout (Int32.to_int (Int32.shift_right i 16));
    output_byte stdout (Int32.to_int (Int32.shift_right i 8));
    output_byte stdout (Int32.to_int i)

let rec output_format_obj prog =
    match prog with
    | [] -> ()
    | l :: prog' -> output_int32 (int32_of_bin l); output_format_obj prog'

let rec output_format_coe prog' =
  match prog' with
  | [] -> ()
  | l :: prog' -> Printf.printf "%s,\n" l; output_format_coe prog'

(* for debug *)
let rec output_text' = function
  | [] -> ()
  | (num, line, asm) :: lst -> (Printf.eprintf "(%d, %s)\n" num asm;
				output_text' lst)

let main' asms =
    let asms = trim_comment asms in
    let data = attach_logical_line_num (extract_data asms) in
    let data_tag_dict = create_tag_dict data in
    let data = strip_tag_def data in
    let data' = List.map (fun (_, _, d) -> let tokens = Str.split (Str.regexp "[ \t()]+") d in (Printf.eprintf "%s\n" (List.nth tokens 1)); imm_to_bin_for_data (List.nth tokens 1)) data in
    let text = extract_text asms in
    let entry_point = get_entry_point text in
    let text = remove_entry_point_mark text in
    let text = convert_pseudo_ops text in
    let text = optimize text in
    (* ひとまず0xaaを送る箇所をコメントアウトした。後で直す *)
    let text = (*[(-1, "addi %r1 %r0 $0x00aa"); (-1, "send8 %r1")] @ *)[(-1, "beq %r0 %r0 " ^ entry_point)] @ text in
    let text' = attach_logical_line_num text in
    output_text' text'; (* for debug *)
    let tag_dict = TagDict.merge (fun key a b -> if a = None then b else a) data_tag_dict (create_tag_dict text') in
    let text' = strip_tag_def text' in
    let prog' = List.map (fun (lline, _, asm) -> asm_to_bin lline asm tag_dict) text' in
    let prog =
        [("00000010" ^ zfill (to_bin (List.length data')) 24)] @
        data' @
        [("00000001" ^ zfill (to_bin (List.length prog')) 24)] @
        prog' @
        ["00000011000000000000000000000000"] in
    match !output_format with
    | "h" -> output_format_hex prog; Printf.printf "\n"
    | "s" -> Printf.eprintf "%d, %s\n" ((List.length prog) * 4) (bin_to_hex (to_bin ((List.length prog) * 4))); output_format_sim prog
    | "o" -> output_format_obj prog
	| "c" -> Printf.printf "memory_initialization_radix=2;\nmemory_initialization_vector=\n"; output_format_coe prog'
    | _ -> raise (Failure (Printf.sprintf "Unknown output format: %s" !output_format))

let () =
    Arg.parse
        [("-format", Arg.String(fun s -> output_format := s), "output format (h, s, o, b, c)")]
        (fun file ->
            let ic = open_in file in
            let asms = ref [] in
            let line = ref 1 in
            try
                while true do
                    let asm = input_line ic in
                    asms := !asms @ [(!line, asm)];
                    line := !line + 1
                done
            with End_of_file ->
                main' !asms;
                close_in ic)
        (Printf.sprintf "Cartelet V1 assembler\nusage: %s [-format h,s,o,b,c] filename" Sys.argv.(0))
