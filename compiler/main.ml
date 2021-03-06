let limit = ref 1000
let debug_level = ref Debug.Emit

let rec iter n e = (* 最適化処理をくりかえす (caml2html: main_iter) *)
  Format.eprintf "iteration %d@." n;
  if n = 0 then e else
  let e' = Elim.f (FvImm.f (ConstFold.f (NonTailIf.f (Inline.f (Assoc.f (Beta.f e)))))) in
  if e = e' then e else
  iter (n - 1) e'

let lexbuf outchan l = (* バッファをコンパイルor途中まで変換してチャンネルへ出力する *)
  Id.counter := 0;
  Typing.extenv := M.empty;
  try
    let d = Parser.exp Lexer.token l in
    if !debug_level = Debug.Parser then Debug.parser_emit outchan d
    else
      let d = Typing.f d in
      if !debug_level = Debug.Typing then Debug.parser_emit outchan d
      else
	let d = KNormal.f d in
	if !debug_level = Debug.KNormal then Debug.kNormal_emit outchan d
	else
	  let d = Alpha.f d in
	  if !debug_level = Debug.Alpha then Debug.kNormal_emit outchan d
	  else
	    let d = iter !limit d in
	    if !debug_level = Debug.Iter then Debug.kNormal_emit outchan d
	    else
	      let d = Closure.f d in
	      if !debug_level = Debug.Closure then Debug.closure_prog_emit outchan d
	      else
		let d = Virtual.f d in
		if !debug_level = Debug.Virtual then DebugAsm.asm_prog_emit outchan d
		else
		  let d = Simm.f d in
		  if !debug_level = Debug.Simm then DebugAsm.asm_prog_emit outchan d
		  else
		    let d = RegAlloc.f d in
		    if !debug_level = Debug.RegAlloc then DebugAsm.asm_prog_emit outchan d
		    else
		      (assert(!debug_level = Debug.Emit);
		       Emit.f outchan d)
  with
    Typing.Error(e, ty1, ty2, p) ->
      (Format.eprintf "Error: This expression at %d has type %s but an expression was expected type %s\n\t@."
		      p.Lexing.pos_lnum
		      (Type.string_of_type ty2)
		      (Type.string_of_type ty1);
       Debug.parser_emit stderr e;
       failwith "Type mismatch")

let string s = lexbuf stdout (Lexing.from_string s) (* 文字列をコンパイルして標準出力に表示する (caml2html: main_string) *)

(* cat : in_channel -> out_channel -> unit *)
let cat ic oc =
  let rec cat_iter () =
    output_string oc ((input_line ic) ^ "\n");
    cat_iter ()
  in
    try cat_iter () with End_of_file -> ()

(* mem : id.l list -> bool *)
let rec mem = function
  | [] -> false
  | f :: lst -> if M.mem f !(Typing.extenv) then true
		else mem lst

(* catlib : string -> out_channel -> unit *)
let catlib lib oc =
  let libchan = open_in lib in
  try
    cat libchan oc;
    close_in libchan
  with e -> (close_in libchan; raise e)

let file f = (* ファイルをコンパイルしてファイルに出力する (caml2html: main_file) *)
  let inchan = open_in (f ^ ".ml") in
  let outchan = (match !debug_level with
		 | Debug.Emit -> open_out (f ^ ".s")
		 | _          -> open_out (f ^ ".out")) in
  let libchan = open_in "libmincaml.S" in (* ad hoc library load for cartelet [should be deleted] *)
  try
    lexbuf outchan (Lexing.from_channel inchan);
    (if !debug_level = Debug.Emit then
       (* 本当はリンカがすべき仕事 *)
       (output_string outchan "\n# Library Begin\n";
	cat libchan outchan;
	catlib "lib/libmincaml_create_array.S" outchan;
	if mem ["print_newline"; "print_byte"; "print_byte"; "print_char"; "print_int"; "print_float"; "print_int_byte"; "print_float_byte"] then
	  (catlib "lib/libmincaml_div10.S" outchan;
	   catlib "lib/libmincaml_print.S" outchan);
	if mem ["read_int"; "read_float"] then
	  catlib "lib/libmincaml_read.S" outchan;
	if mem ["truncate"; "int_of_float"; "float_of_int"; "floor"; "read_int"; "read_float"] then
	  catlib "lib/libmincaml_int_float.S" outchan;
	if mem ["floor"] then
	  catlib "lib/libmincaml_floor.S" outchan;
	if mem ["cos"; "sin"] then
	  catlib "lib/libmincaml_cos_sin.S" outchan;
	if mem ["atan"] then
	  catlib "lib/libmincaml_atan.S" outchan;
        output_string outchan "# Library End\n"));
    close_in inchan;
    close_out outchan;
    close_in libchan;
  with e -> (close_in inchan; close_out outchan; close_in libchan; raise e)

let () = (* ここからコンパイラの実行が開始される (caml2html: main_entry) *)
  let files = ref [] in
  Arg.parse
    [("-inline", Arg.Set_int(Inline.threshold), "maximum size of functions inlined");
     ("-nonTailIf", Arg.Set_int(NonTailIf.threshold), "maximum size of functions expanded");
     ("-iter", Arg.Set_int(limit), "maximum number of optimizations iterated");
     ("-debug", Arg.String(fun s -> debug_level := Debug.level_of_string s), "output level for debugging");
     ("-server", Arg.Unit(fun () -> Virtual.server_mode := true), "toggle to server mode (use print_***_byte instead of print_***)")]
    (fun s -> files := !files @ [s])
    ("Mitou Min-Caml Compiler (C) Eijiro Sumii\n" ^
     Printf.sprintf "usage: %s [-inline m] [-iter n] ...filenames without \".ml\"..." Sys.argv.(0));
  List.iter
    (fun f -> ignore (file f))
    !files
