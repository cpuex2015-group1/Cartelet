.data
min_caml_pi:
	.long	0x40490fdb
min_caml_float_0:
	.long	0x00000000
min_caml_float_1:
	.long	0x3f800000
min_caml_float_minus_1:
	.long	0xbf800000
min_caml_float_half:
	.long	0x3f000000
min_caml_float_int_c1:
	.long	0xcb000000
min_caml_float_int_c2:
	.long	0x4b000000
min_caml_kernel_cos_c1:
	.long	0xbf000000
min_caml_kernel_cos_c2:
	.long	0x3d2aa789
min_caml_kernel_cos_c3:
	.long	0xbab38106
min_caml_kernel_sin_c1:
	.long	0xbe2aaaac
min_caml_kernel_sin_c2:
	.long	0x3c088666
min_caml_kernel_sin_c3:
	.long	0xb94d64b6
min_caml_read_float_c1:
	.long	0x3dcccccd
.text
.globl	main
main:
	addi	%r29 %r0 $1023
	addi	%r25 %r0 $10
	sll	%r29 %r29 %r25
	addi	%r29 %r29 $1023
	addi	%r28 %r0 $1023
	addi	%r2 %r0 $1
	jal	min_caml_read_float
	fmov	%f31 %f0
	jal	min_caml_read_float
	halt
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
	addi	%r12 %r0 min_caml_read_int_start
min_caml_read_int_start:
	recv8	%r3
	beq	%r3 %r11 min_caml_read_int_negative
	slt	%r13 %r3 %r9
	slt	%r14 %r10 %r3
	add	%r13 %r13 %r14
	beq	%r13 %r0 min_caml_read_int_positive
	jr	%r12
min_caml_read_int_negative:
	addi	%r8 %r0 $1
	addi	%r2 %r0 $0
	addi	%r11 %r0 min_caml_read_int_loop
	jr	%r11
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
	addi	%r11 %r0 min_caml_read_int_loop
	jr	%r11
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
	# r2: ans, r3: #(head zeros) r8: buffer, r9: '0', r10: '9', r11: temp
	# f0: integer part
	addi	%r9 %r0 $0x30
	addi	%r10 %r0 $0x39
	addi	%r11 %r0 min_caml_read_float_loop1
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
	jr	%r11
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
	addi	%r11 %r0 min_caml_read_float_loop2
	jr	%r11
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
	addi	%r8 %r0 min_caml_read_float_loop3
min_caml_read_float_loop3:
	# r3: #(head zero)
	# f0: 小数点以下, f1: 整数部分, f2: 1.0f, f3: 0.1f
	fslt	%f0 %f2
	bclt	min_caml_read_float_loop3_exit
	fmul	%f0 %f0 %f3
	jr	%r8
min_caml_read_float_loop3_exit:
	addi	%r8 %r0 min_caml_read_float_loop4
min_caml_read_float_loop4:
	slt	%r9 %r0 %r3
	beq	%r9 %r0 min_caml_read_float_loop4_exit
	addi	%r3 %r3 $-1
	fmul	%f0 %f0 %f3
	jr	%r8
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
# float_of_int
min_caml_float_of_int:
	# FLAGを決めてabsをする
	slt	%r8 %r2 %r0
	beq	%r8 %r0 min_caml_float_of_int_flag_positive
	addi	%r9 %r0 $1
	sub	%r11 %r0 %r2
	addi	%r10 %r0 min_caml_float_of_int_after_flag
	jr	%r10
min_caml_float_of_int_flag_positive:
	addi	%r9 %r0 $0
	add	%r11 %r0 %r2
min_caml_float_of_int_after_flag:
	addiu32	%r8 %r0 $8388608
	slt	%r10 %r11 %r8
	beq	%r10 %r0 min_caml_float_of_int_big
	# |x| < 838860
	# 8388608.0f + xにして、8388608.0fを引く
	# r2: x, r8: const or addr, r9: FLAG, r10: temp, r11: |x|
	# f0: answer
	addiu32	%r8 %r0 $0x4b000000
	add	%r10 %r11 %r8
	st	-1(%r29) %r10
	fld	-1(%r29) %f0
	addi	%r8 %r0 min_caml_float_int_c1
	fld	0(%r8) %f1
	fadd	%f0 %f0 %f1
	# FLAG
	beq	%r9 %r0 min_caml_float_of_int_small_positive
	fneg	%f0 %f0
min_caml_float_of_int_small_positive:
	jr	%r31
min_caml_float_of_int_big:
	# |x| >= 8388608
	# x = m*8388608 + nとしてfloat_of_int(8388608)*m+float_of_int(n)を求める
	# r2: x, r8: |x| or n, r9: FLAG, r10: 8388608, r11: -8388608, r12: temp
	# f0: answer, f1: 8388608.0
	addi	%r8 %r0 min_caml_float_0
	fld	0(%r8) %f0
	addi	%r8 %r0 min_caml_float_int_c2
	fld	0(%r8) %f1
	add	%r8 %r0 %r11
	add	%r9 %r0 %r0
	addiu32	%r10 %r0 $8388608
	addiu32	%r11 %r0 $4286578688 # -8388608
min_caml_float_of_int_big_loop:
	# float_of_int(8388608)*mを求める
	fadd	%f0 %f0 %f1
	add	%r8 %r8 %r11
	slt	%r12 %r10 %r8
	beq	%r12 %r0 min_caml_float_of_int_big_loop
	# float_of_int(n)を求める
	st	-1(%r29) %r2
	fst	-2(%r29) %f0
	addi	%r29 %r29 $-3
	st	0(%r29) %r31
	add	%r2 %r0 %r8
	jal	min_caml_float_of_int
	ld	0(%r29) %r31
	addi	%r29 %r29 $3
	fld	-2(%r29) %f1
	ld	-1(%r29) %r2
	# 足し算する
	fadd	%f0 %f0 %f1
	# FLAG
	beq	%r9 %r0 min_caml_float_of_int_big_positive
	fneg	%f0 %f0
min_caml_float_of_int_big_positive:
	jr	%r31
