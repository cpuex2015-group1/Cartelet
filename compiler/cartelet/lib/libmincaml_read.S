# read_int (32bit, ASCII -> byte)
min_caml_read_int:
	# [0-9-]が送られてくるまでrecv8し続ける。
	# その後[0-9]が送られ続けてくる間受け取り、それ以外が来たらbreak
	# オーバーフローしたときの挙動はundefinedとしておく
	# こっそりr3に、区切り文字(数字の直後の1文字)のASCIIを入れて返す(read_float用)
	# r2: ans, r3: buffer, r8: FLAG, r9: '0', r10: '9', r11, r12, r13, r14: temp
	addi	%r9 %r0 $0x30
	addi	%r10 %r0 $0x39
	addi	%r3 %r0 $0
	# 最初の1bitはマイナスかもしれない
	addi	%r11 %r0 $0x2d  # '-'
min_caml_read_int_start:
	recv8	%r3
	beq	%r3 %r11 min_caml_read_int_negative
	slt	%r13 %r3 %r9
	slt	%r14 %r10 %r3
	add	%r13 %r13 %r14
	beq	%r13 %r0 min_caml_read_int_positive
	beq	%r0 %r0 min_caml_read_int_start
min_caml_read_int_negative:
	addi	%r8 %r0 $1
	addi	%r2 %r0 $0
	beq	%r0 %r0 min_caml_read_int_loop
min_caml_read_int_positive:
	addi	%r8 %r0 $0
	addi	%r2 %r3 $-48  # ASCII to binary
min_caml_read_int_loop:
	# recieve
	recv8	%r3
	slt	%r11 %r3 %r9
	bneq	%r11 %r0 min_caml_read_int_sign
	slt	%r11 %r10 %r3
	bneq	%r11 %r0 min_caml_read_int_sign
	# multiply by 10
	addi	%r13 %r0 $1
	sll	%r11 %r2 %r13
	addi	%r13 %r0 $3
	sll	%r12 %r2 %r13
	add	%r2 %r11 %r12
	# add a digit
	addi	%r3 %r3 $-48
	add	%r2 %r2 %r3
	beq	%r0 %r0 min_caml_read_int_loop
min_caml_read_int_sign:
	# 符号判定
	beq	%r8 %r0 min_caml_read_int_exit
	sub	%r2 %r0 %r2
min_caml_read_int_exit:
	jr	%r31
# read_float (32bit, ASCII -> byte)
min_caml_read_float:
	# 整数部分を受け取り、区切り文字が'.'なら小数点以下も読み取る
	# float_of_intの分の誤差も入ることに注意。
	# 整数も受け取る。".1"(= 0.1)みたいなのには対応していない。
	addi	%r29 %r29 $-2
	st	0(%r29) %r31
	jal	min_caml_read_int
	st	1(%r29) %r3  # r3の区切り文字情報をストアしておく
	jal	min_caml_float_of_int
	ld	0(%r29) %r31
	addi	%r29 %r29 $2
	ld	-1(%r29) %r8
	addi	%r9 %r0 $0x2e  # '.'
	bneq	%r8 %r9 min_caml_read_float_exit
	# ここから小数点以下
	# 1.1と1.01を区別するため、read_intは使えない
	# r2: ans, r3: #(head zeros) r8: buffer, r9: '0', r10: '9'
	# f0: integer part
	addi	%r9 %r0 $0x30
	addi	%r10 %r0 $0x39
	addi	%r3 %r0 $0
	addi	%r8 %r0 $0
	# 先頭の0を数えつつ上桁を探す
min_caml_read_float_loop1:
	recv8	%r8
	slt	%r12 %r8 %r9
	bneq	%r12 %r0 min_caml_read_float_exit
	slt	%r12 %r10 %r8
	bneq	%r12 %r0 min_caml_read_float_exit
	bneq	%r8 %r9 min_caml_read_float_loop1_exit
	addi	%r3 %r3 $1
	beq	%r0 %r0 min_caml_read_float_loop1
min_caml_read_float_loop1_exit:
	addi	%r2 %r8 $-48
min_caml_read_float_loop2:
	# recieve
	recv8	%r8
	slt	%r11 %r8 %r9
	bneq	%r11 %r0 min_caml_read_float_loop2_exit
	slt	%r11 %r10 %r8
	bneq	%r11 %r0 min_caml_read_float_loop2_exit
	# multiply by 10
	addi	%r13 %r0 $1
	sll	%r11 %r2 %r13
	addi	%r13 %r0 $3
	sll	%r12 %r2 %r13
	add	%r2 %r11 %r12
	# add a digit
	addi	%r8 %r8 $-48
	add	%r2 %r2 %r8
	beq	%r0 %r0 min_caml_read_float_loop2
min_caml_read_float_loop2_exit:
	fst	-1(%r29) %f0
	st	-2(%r29) %r3
	addi	%r29 %r29 $-3
	st	0(%r29) %r31
	jal	min_caml_float_of_int
	ld	0(%r29) %r31
	addi	%r29 %r29 $3
	fld	-1(%r29) %f1
	ld	-2(%r29) %r3
	# 小数点以下の部分を0.fffまでずらし、更に頭の0の個数だけずらす
	addi	%r8 %r0 min_caml_float_1
	fld	0(%r8) %f2
	addi	%r8 %r0 min_caml_read_float_c1
	fld	0(%r8) %f3
min_caml_read_float_loop3:
	# r3: #(head zero)
	# f0: 小数点以下, f1: 整数部分, f2: 1.0f, f3: 0.1f
	fslt	%f0 %f2
	bclt	min_caml_read_float_loop4
	fmul	%f0 %f0 %f3
	beq	%r0 %r0 min_caml_read_float_loop3
min_caml_read_float_loop4:
	slt	%r9 %r0 %r3
	beq	%r9 %r0 min_caml_read_float_loop4_exit
	addi	%r3 %r3 $-1
	fmul	%f0 %f0 %f3
	beq	%r0 %r0 min_caml_read_float_loop4
min_caml_read_float_loop4_exit:
	# 符号の兼ね合いを見つつ整数部分と小数点以下の部分を足す
	addi	%r8 %r0 min_caml_float_0
	fld	0(%r8) %f2
	fslt	%f1 %f2
	bclf	min_caml_read_float_loop_exit_positive
	fneg	%f0 %f0
min_caml_read_float_loop_exit_positive:
	fadd	%f0 %f0 %f1
min_caml_read_float_exit:
	jr	%r31
# read_int_byte (32bit, byte -> byte)
min_caml_read_int_byte:
	addi	%r8 %r0 $8
	recv8	%r2
	sll	%r2 %r2 %r8
	recv8	%r2
	sll	%r2 %r2 %r8
	recv8	%r2
	sll	%r2 %r2 %r8
	recv8	%r2
	jr	%r31
# read_float_byte (32bit, byte -> byte)
min_caml_read_float_byte:
	addi	%r8 %r0 $8
	recv8	%r2
	sll	%r2 %r2 %r8
	recv8	%r2
	sll	%r2 %r2 %r8
	recv8	%r2
	sll	%r2 %r2 %r8
	recv8	%r2
	st	-1(%r29) %r2
	fld	-1(%r29) %f0
	jr	%r31
