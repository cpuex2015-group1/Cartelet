open Asm

external getfl : float -> int32 = "getfl"

let server_mode = ref false

let stackset = ref S.empty (* すでにSaveされた変数の集合 (caml2html: emit_stackset) *)
let stackmap = ref [] (* Saveされた変数の、スタックにおける位置 (caml2html: emit_stackmap) *)
let save x =
  stackset := S.add x !stackset;
  if not (List.mem x !stackmap) then
    stackmap := !stackmap @ [x]
let savef x =
  stackset := S.add x !stackset;
  if not (List.mem x !stackmap) then
    stackmap := !stackmap @ [x]
let locate x =
  let rec loc = function
    | [] -> []
    | y :: zs when x = y -> 0 :: List.map succ (loc zs)
    | y :: zs -> List.map succ (loc zs) in
  loc !stackmap
(** あやしい *)
let offset x = (List.hd (locate x)) + 1
let stacksize () = List.length !stackmap * 1

let pp_id_or_imm = function
  | V(x) -> x
  | C(i) -> "$" ^ string_of_int i

(* 関数呼び出しのために引数を並べ替える(register shuffling) (caml2html: emit_shuffle) *)
let rec shuffle sw xys =
  (* remove identical moves *)
  let _, xys = List.partition (fun (x, y) -> x = y) xys in
  (* find acyclic moves *)
  match List.partition (fun (_, y) -> List.mem_assoc y xys) xys with
  | [], [] -> []
  | (x, y) :: xys, [] -> (* no acyclic moves; resolve a cyclic move *)
     (y, sw) :: (x, y) :: shuffle sw (List.map
					(function
					  | (y', z) when y = y' -> (sw, z)
					  | yz -> yz)
					xys)
  | xys, acyc -> acyc @ shuffle sw xys

(* 行末に.mlファイルの行番号情報を付記 *)
let line oc p = Printf.fprintf oc "\t# %d\n" p.Lexing.pos_lnum

(* nオペランドの命令を出力する *)
let emit_1 oc inst reg p =
  (Printf.fprintf oc "\t%s\t%s" inst reg;
   line oc p)
let emit_2 oc inst dst src p = 
  (Printf.fprintf oc "\t%s\t%s %s" inst dst src;
   line oc p)
let emit_3 oc inst dst src1 src2 p =
  (Printf.fprintf oc "\t%s\t%s %s %s" inst dst src1 src2;
   line oc p)
let emit_ld oc inst dst offset src p =
  (Printf.fprintf oc "\t%s\t%s %d(%s)" inst dst offset src;
   line oc p)
let emit_st oc inst offset dst src p =
  (Printf.fprintf oc "\t%s\t%d(%s) %s" inst offset dst src;
   line oc p)

(* 即値がn bitに収まるか *)
let is_signed_16bit n = n >= -32768 && n <= 32767
let is_unsigned_16bit n = n >= 0 && n <= 65535

type dest = Tail | NonTail of Id.t (* 末尾かどうかを表すデータ型 (caml2html: emit_dest) *)
let rec g oc = function (* 命令列のアセンブリ生成 (caml2html: emit_g) *)
  | dest, Ans(exp) -> g' oc (dest, exp)
  | dest, Let((x, t), exp, e) ->
     g' oc (NonTail(x), exp);
     g oc (dest, e)
and g' oc = function (* 各命令のアセンブリ生成 (caml2html: emit_gprime) *)
  (* 末尾でなかったら計算結果をdestにセット (caml2html: emit_nontail) *)
  | NonTail(_), Nop _ -> ()
  | NonTail(x), Set(i, p) ->
     (if is_signed_16bit i then
	emit_3 oc "addi" x reg_zero (string_of_int i) p
      else if is_unsigned_16bit i then
	emit_3 oc "addiu" x reg_zero (string_of_int i) p
      else
	assert false)
  | NonTail(x), SetL(Id.L(y), p) ->
     emit_3 oc "addi" x reg_zero y p
  | NonTail(x), Mov(y, p) ->
     if x <> y then emit_3 oc "addi" x y "0" p
  | NonTail(x), Neg(y, p) ->
     emit_3 oc "sub" x reg_zero y p
  | NonTail(x), Add(y, V(z), p) ->
     emit_3 oc "add" x y z p
  | NonTail(x), Add(y, C(i), p) ->
     (if i <> 0 || x <> y then
	(if is_signed_16bit i then
	   emit_3 oc "addi" x y (string_of_int i) p
	 else if is_unsigned_16bit i then
	   emit_3 oc "addiu" x y (string_of_int i) p
	 else
	   assert false))
  | NonTail(x), Sub(y, V(z), p) ->
     emit_3 oc "sub" x y z p
  | NonTail(x), Sub(y, C(i), p) ->
     (if i <> 0 || x <> y then
	(if is_signed_16bit (-i) then
	   emit_3 oc "addi" x y (string_of_int (-i)) p
	 else
	   assert false))
  | NonTail(x), Mul(y, z', p) ->
     assert(z' = C(4));
     emit_3 oc "slli" x y "2" p
  | NonTail(x), Div(y, z', p) ->
     assert(z' = C(2));
     emit_3 oc "srai" x y "1" p
  | NonTail(x), Slli(y, i, p) ->
     assert(is_signed_16bit i);
     emit_3 oc "slli" x y (string_of_int i) p
  | NonTail(x), Srai(y, i, p) ->
     assert(is_signed_16bit i);
     emit_3 oc "srai" x y (string_of_int i) p
  | NonTail(x), Ld(y, V(z), p) ->
     emit_3 oc "add" reg_tmp y z p;
     emit_ld oc "lw" x 0 reg_tmp p
  | NonTail(x), Ld(y, C(i), p) ->
     assert(is_signed_16bit i);
     emit_ld oc "lw" x i y p
  | NonTail(_), St(x, y, V(z), p) ->
     emit_3 oc "add" reg_tmp y z p;
     emit_st oc "sw" 0 reg_tmp x p
  | NonTail(_), St(x, y, C(i), p) ->
     assert(is_signed_16bit i);
     emit_st oc "sw" i y x p
  | NonTail(x), FMov(y, p) ->
     if x <> y then emit_2 oc "fmov" x y p
  | NonTail(x), FNeg(y, p) ->
     emit_2 oc "fneg" x y p
  | NonTail(x), FAdd(y, z, p) ->
     emit_3 oc "fadd" x y z p
  | NonTail(x), FSub(y, z, p) ->
     emit_3 oc "fsub" x y z p
  | NonTail(x), FMul(y, z, p) ->
     emit_3 oc "fmul" x y z p
  | NonTail(x), FDiv(y, z, p) ->
     (* CPU実験特有のルールによりこの最適化をしてもOK *)
     emit_2 oc "finv" freg_tmp z p;
     emit_3 oc "fmul" x y freg_tmp p
  | NonTail(x), FInv(y, p) ->
     emit_2 oc "finv" x y p
  | NonTail(x), FSqrt(y, p) ->
     emit_2 oc "fsqrt" x y p
  | NonTail(x), FAbs(y, p) ->
     emit_2 oc "fabs" x y p
  | NonTail(x), LdF(y, V(z), p) ->
     emit_3 oc "add" reg_tmp y z p;
     emit_ld oc "flw" x 0 reg_tmp p
  | NonTail(x), LdF(y, C(i), p) ->
     assert(is_signed_16bit i);
     emit_ld oc "flw" x i y p
  | NonTail(_), StF(x, y, V(z), p) ->
     emit_3 oc "add" reg_tmp y z p;
     emit_st oc "fsw" 0 reg_tmp x p
  | NonTail(_), StF(x, y, C(i), p) ->
     assert(is_signed_16bit i);
     emit_st oc "fsw" i y x p
  | NonTail(_), Send(x, p) ->
     (* 後で使う予定 *) ()
  | NonTail(x), Recv(p) ->
     (* 後で使う予定 *) ()
  | NonTail(_), Comment(s, p) ->
     Printf.fprintf oc "\t# %s\t" s;
     line oc p
  (* 退避の仮想命令の実装 (caml2html: emit_save) *)
  | NonTail(_), Save(x, y, p) when List.mem x allregs && not (S.mem y !stackset) ->
     save y;
     let offset_y = -(offset y) in
     assert(is_signed_16bit offset_y);
     emit_st oc "sw" offset_y reg_sp x p
  | NonTail(_), Save(x, y, p) when List.mem x allfregs && not (S.mem y !stackset) ->
     savef y;
     let offset_y = -(offset y) in
     assert(is_signed_16bit offset_y);
     emit_st oc "fsw" offset_y reg_sp x p
  | NonTail(_), Save(x, y, p) -> assert (S.mem y !stackset); ()
  (* 復帰の仮想命令の実装 (caml2html: emit_restore) *)
  | NonTail(x), Restore(y, p) when List.mem x allregs ->
     let offset_y = -(offset y) in
     assert(is_signed_16bit offset_y);
     emit_ld oc "lw" x offset_y reg_sp p
  | NonTail(x), Restore(y, p) ->
     assert (List.mem x allfregs);
     let offset_y = -(offset y) in
     assert(is_signed_16bit offset_y);
     emit_ld oc "flw" x offset_y reg_sp p
  (* 末尾だったら計算結果を第一レジスタにセットしてret (caml2html: emit_tailret) *)
  | Tail, (Nop _ | St _ | StF _ | Send _ | Recv _ | Comment _ | Save _ as exp) ->
     let p = Asm.pos_of_exp exp in
     g' oc (NonTail(Id.gentmp Type.Unit), exp);
     emit_1 oc "jr" reg_ra p
  | Tail, (Set _ | SetL _ | Mov _ |
	   Neg _ | Add _ | Sub _ | Mul _ | Div _ | Slli _ | Srai _ |
	   Ld _ as exp) ->
     let p = Asm.pos_of_exp exp in
     g' oc (NonTail(reg_rv), exp);
     emit_1 oc "jr" reg_ra p
  | Tail, (FMov _ | FNeg _ | FAdd _ | FSub _ | FMul _ | FDiv _ |
	   FInv _ | FSqrt _ | FAbs _ | LdF _  as exp) ->
     let p = Asm.pos_of_exp exp in
     g' oc (NonTail(freg_rv), exp);
     emit_1 oc "jr" reg_ra p
  | Tail, (Restore(x, p) as exp) ->
     (if x.[1] = 'r' then
	g' oc (NonTail(reg_rv), exp)
      else
	(assert(x.[1] = 'f');
	 g' oc (NonTail(freg_rv), exp)));
     emit_1 oc "jr" reg_ra p
(* 後で分岐予測のこと考える *)
  | Tail, IfEq(x, V(y), e1, e2, p) ->
     g'_tail_if oc e1 e2 "beq" x y p
  | Tail, IfEq(x, C(i), e1, e2, p) ->
     if i <> 0 then
       (assert(is_signed_16bit i);
	emit_3 oc "addi" reg_tmp reg_zero (string_of_int i) p;
	g'_tail_if oc e1 e2 "beq" x reg_tmp p)
     else
	g'_tail_if oc e1 e2 "beq" x reg_zero p
  | Tail, IfLE(x, V(y), e1, e2, p) ->
     g'_tail_if oc e1 e2 "ble" x y p
  | Tail, IfLE(x, C(i), e1, e2, p) ->
     assert(is_signed_16bit i);
     emit_3 oc "addi" reg_tmp reg_zero (string_of_int i) p;
     g'_tail_if oc e1 e2 "ble" x reg_tmp p
  | Tail, IfGE(x, V(y), e1, e2, p) ->
     g'_tail_if oc e1 e2 "ble" y x p
  | Tail, IfGE(x, C(i), e1, e2, p) ->
     assert(is_signed_16bit i);
     emit_3 oc "addi" reg_tmp reg_zero (string_of_int i) p;
     g'_tail_if oc e1 e2 "ble" reg_tmp x p
  | Tail, IfFEq(x, y, e1, e2, p) ->
     g'_tail_if oc e1 e2 "fbeq" x y p
  | Tail, IfFLE(x, y, e1, e2, p) ->
     g'_tail_if oc e1 e2 "fble" x y p
  | NonTail(z), IfEq(x, V(y), e1, e2, p) ->
     g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" x y p
  | NonTail(z), IfEq(x, C(i), e1, e2, p) ->
     if i <> 0 then
       (assert(is_signed_16bit(i));
	emit_3 oc "addi" reg_tmp reg_zero (string_of_int i) p;
	g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" x reg_tmp p)
     else
	g'_non_tail_if oc (NonTail(z)) e1 e2 "beq" x reg_zero p
  | NonTail(z), IfLE(x, V(y), e1, e2, p) ->
     g'_non_tail_if oc (NonTail(z)) e1 e2 "ble" x y p
  | NonTail(z), IfLE(x, C(i), e1, e2, p) ->
     assert(is_signed_16bit i);
     emit_3 oc "addi" reg_tmp reg_zero (string_of_int i) p;
     g'_non_tail_if oc (NonTail(z)) e1 e2 "ble" x reg_tmp p;
  | NonTail(z), IfGE(x, V(y), e1, e2, p) ->
     g'_non_tail_if oc (NonTail(z)) e1 e2 "ble" y x p
  | NonTail(z), IfGE(x, C(i), e1, e2, p) ->
     assert(is_signed_16bit i);
     emit_3 oc "addi" reg_tmp reg_zero (string_of_int i) p;
     g'_non_tail_if oc (NonTail(z)) e1 e2 "ble" reg_tmp x p;
  | NonTail(z), IfFEq(x, y, e1, e2, p) ->
     g'_non_tail_if oc (NonTail(z)) e1 e2 "fbeq" x y p
  | NonTail(z), IfFLE(x, y, e1, e2, p) ->
     g'_non_tail_if oc (NonTail(z)) e1 e2 "fble" x y p
  (* 関数呼び出しの仮想命令の実装 (caml2html: emit_call) *)
  | Tail, CallCls(x, ys, zs, p) -> (* 末尾呼び出し (caml2html: emit_tailcall) *)
     g'_args oc [(x, reg_cl)] ys zs p;
     emit_ld oc "lw" reg_tmp 0 reg_cl p;
     emit_1 oc "jr" reg_tmp p
  | Tail, CallDir(Id.L(x), ys, zs, p) -> (* 末尾呼び出し *)
     (match x with
      | "min_caml_fabs" | "min_caml_abs_float" ->
         g' oc (Tail, FAbs(List.hd zs, p))
      | "min_caml_sqrt" ->
	 g' oc (Tail, FSqrt(List.hd zs, p))
      | "min_caml_read_int" when !server_mode ->
	 g' oc (Tail, CallDir(Id.L("min_caml_read_int_byte"), ys, zs, p))
      | "min_caml_read_float" when !server_mode ->
	 g' oc (Tail, CallDir(Id.L("min_caml_read_float_byte"), ys, zs, p))
      | _ ->
	 (g'_args oc [] ys zs p;
	  emit_3 oc "beq" reg_zero reg_zero x p))
  | NonTail(a), CallCls(x, ys, zs, p) ->
     g'_args oc [(x, reg_cl)] ys zs p;
     let ss = stacksize () in
     assert(is_signed_16bit (ss+1) && is_signed_16bit (-(ss+1)));
     emit_3 oc "addi" reg_sp reg_sp (string_of_int (-(ss+1))) p;
     emit_st oc "sw" 0 reg_sp reg_ra p;
     emit_ld oc "lw" reg_tmp 0 reg_cl p;
     emit_1 oc "jalr" reg_tmp p;
     emit_ld oc "lw" reg_ra 0 reg_sp p;
     emit_3 oc "addi" reg_sp reg_sp (string_of_int (ss+1)) p;
     if List.mem a allregs && a <> reg_rv then
       emit_3 oc "addi" a reg_rv "0" p
     else if List.mem a allfregs && a <> freg_rv then
       emit_2 oc "fmov" a freg_rv p
     else
       assert (a = "%unit" || a = reg_rv || a = freg_rv)
  | NonTail(a), CallDir(Id.L(x), ys, zs, p) ->
     (match x with
      | "min_caml_fabs" | "min_caml_abs_float" ->
         g' oc (NonTail(a), FAbs(List.hd zs, p))
      | "min_caml_sqrt" ->
	 g' oc (NonTail(a), FSqrt(List.hd zs, p))
      | "min_caml_read_int" when !server_mode ->
	 g' oc (NonTail(a), CallDir(Id.L("min_caml_read_int_byte"), ys, zs, p))
      | "min_caml_read_float" when !server_mode ->
	 g' oc (NonTail(a), CallDir(Id.L("min_caml_read_float_byte"), ys, zs, p))
      | _ ->
	 begin
	   g'_args oc [] ys zs p;
	   let ss = stacksize () in
	   assert(is_signed_16bit (ss+1) && is_signed_16bit (-(ss+1)));
	   emit_3 oc "addi" reg_sp reg_sp (string_of_int (-(ss+1))) p;
	   emit_st oc "sw" 0 reg_sp reg_ra p;
	   emit_1 oc "jal" x p;
	   emit_ld oc "lw" reg_ra 0 reg_sp p;
	   emit_3 oc "addi" reg_sp reg_sp (string_of_int (ss+1)) p;
	   if List.mem a allregs && a <> reg_rv then
	     emit_3 oc "addi" a reg_rv "0" p
	   else if List.mem a allfregs && a <> freg_rv then
	     emit_2 oc "fmov" a freg_rv p
	   else
	     (* %unitはregAlloc.mlで生まれる *)
	      assert(a = "%unit" || a = reg_rv || a = freg_rv)
	 end)
and g'_tail_if oc e1 e2 b reg1 reg2 p =
  let b_true = Id.genid b in
  emit_3 oc b reg1 reg2 b_true p;
  let stackset_back = !stackset in
  g oc (Tail, e2);
  Printf.fprintf oc "%s:\n" b_true;
  stackset := stackset_back;
  g oc (Tail, e1);
and g'_non_tail_if oc dest e1 e2 b reg1 reg2 p =
  let b_true = Id.genid (b ^ "_true") in
  let b_cont = Id.genid (b ^ "_cont") in
  emit_3 oc b reg1 reg2 b_true p;
  let stackset_back = !stackset in
  g oc (dest, e2);
  let stackset1 = !stackset in
  emit_3 oc "beq" reg_zero reg_zero b_cont;
  Printf.fprintf oc "%s:\n" b_true;
  stackset := stackset_back;
  g oc (dest, e1);
  Printf.fprintf oc "%s:\n" b_cont;
  let stackset2 = !stackset in
  stackset := S.inter stackset1 stackset2
and g'_args oc x_reg_cl ys zs p =
  assert (List.length ys <= Array.length regs - List.length x_reg_cl);
  assert (List.length zs <= Array.length fregs);
  let (i, yrs) =
    List.fold_left
      (fun (i, yrs) y -> (i + 1, (y, regs.(i)) :: yrs))
      (0, x_reg_cl)
      ys in
  List.iter
    (fun (y, r) -> emit_3 oc "addi" r y "0" p)
    (shuffle reg_tmp yrs);
  let (d, zfrs) =
    List.fold_left
      (fun (d, zfrs) z -> (d + 1, (z, fregs.(d)) :: zfrs))
      (0, [])
      zs in
  List.iter
    (fun (z, fr) -> emit_2 oc "fmov" fr z p)
    (shuffle freg_tmp zfrs)
    
let h oc { name = Id.L(x); args = _; fargs = _; body = e; ret = _ } =
  Printf.fprintf oc "%s:\n" x;
  stackset := S.empty;
  stackmap := [];
  g oc (Tail, e)

(* mem : string list -> bool *)
let rec mem = function
  | [] -> false
  | str::lst ->
     (if M.mem str !(Typing.extenv) then true
      else mem lst)

(* emit_data : out_channel -> string list -> unit *)
let emit_data oc data =
  List.iter
    (fun (x, f) ->
      Printf.fprintf oc "%s:\n" x;
      Printf.fprintf oc "\t.long\t%s\n" f)
    data

let f oc (Prog(data, fundefs, e)) =
  Format.eprintf "generating assembly...@.";
  Printf.fprintf oc ".data\n";
  (* constant for library *)
  emit_data oc
	    [("min_caml_2pi",           "0x40c90fdb");
	     ("min_caml_pi",            "0x40490fdb");
	     ("min_caml_half_pi",       "0x3fc90fdb");
	     ("min_caml_quarter_pi",    "0x3f490fdb");
	     ("min_caml_float_0",       "0x00000000");
	     ("min_caml_float_1",       "0x3f800000");
	     ("min_caml_float_2",       "0x40000000");
	     ("min_caml_float_minus_1", "0xbf800000");
	     ("min_caml_float_half",    "0x3f000000")];
  (if mem ["read_int"; "read_float"; "read_int_byte"; "read_float_byte"] then
     emit_data oc [("min_caml_read_float_c1", "0x3dcccccd")]);
  (if mem ["int_of_float"; "truncate";
	   "float_of_int"; "read_int"; "read_float"] then
     emit_data oc
	       [("min_caml_float_int_c1", "0xcb000000");
		("min_caml_float_int_c2", "0x4b000000")]);
  (if mem ["cos"; "sin"] then
     emit_data oc
	       [("min_caml_kernel_cos_c1", "0xbf000000");
		("min_caml_kernel_cos_c2", "0x3d2aa789");
		("min_caml_kernel_cos_c3", "0xbab38106");
		("min_caml_kernel_sin_c1", "0xbe2aaaac");
		("min_caml_kernel_sin_c2", "0x3c088666");
		("min_caml_kernel_sin_c3", "0xb94d64b6")]);
  (if mem ["atan"] then
     emit_data oc
	       [("min_caml_atan_c1", "0x3ee00000");
		("min_caml_atan_c2", "0x401c0000");
		("min_caml_kernel_atan_c1", "0xbeaaaaaa");
		("min_caml_kernel_atan_c2", "0x3e4ccccd");
		("min_caml_kernel_atan_c3", "0xbe124925");
		("min_caml_kernel_atan_c4", "0x3de38e38");
		("min_caml_kernel_atan_c5", "0xbdb7d66e");
		("min_caml_kernel_atan_c6", "0x3d75e7c5")]);
  (* float table *)
  List.iter
    (fun (Id.L(x), f) ->
      Printf.fprintf oc "%s:\t# %f\n" x f;
      Printf.fprintf oc "\t.long\t0x%lx\n" (getfl f))
    data;
  Printf.fprintf oc ".text\n";
  List.iter (fun fundef -> h oc fundef) fundefs;
  Printf.fprintf oc ".globl\tmin_caml_start\n";
  Printf.fprintf oc "min_caml_start:\n";
  (* スタックポインタを一番底(2^20)にする *)
  Printf.fprintf oc "\taddi\t%s %s $1023\n" reg_sp reg_zero;
  Printf.fprintf oc "\taddi\t%s %s $10\n" reg_tmp reg_zero;
  Printf.fprintf oc "\tsll\t%s %s %s\n" reg_sp reg_sp reg_tmp;
  Printf.fprintf oc "\taddi\t%s %s $1023\n" reg_sp reg_sp;
  (* ヒープポインタ(グローバルポインタ)を中腹(2^10)にする *)
  Printf.fprintf oc "\taddi\t%s %s $1023\n" reg_hp reg_zero;
  stackset := S.empty;
  stackmap := [];
  Printf.fprintf oc "\t# Main Program Begin\n";
  g oc (NonTail(reg_rv), e);
  Printf.fprintf oc "\t# Main Program End\n";
  Printf.fprintf oc "\thalt\n";
