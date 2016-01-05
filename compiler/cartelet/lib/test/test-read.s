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
	slli	%r29 %r29 $10
	addi	%r29 %r29 $1023
	addi	%r28 %r0 $1023
	addi	%r2 %r0 $1
	jal	min_caml_read_float
	fmov	%f31 %f2
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
min_caml_read_int_start:
	recv8	%r3
	beq	%r3 %r11 min_caml_read_int_negative
	ble	%r9 %r3 min_caml_read_int_start_ble_30
	beq	%r0 %r0 min_caml_read_int_start
min_caml_read_int_start_ble_30:
	ble	%r3 %r10 min_caml_read_int_positive
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
	blt	%r3 %r9 min_caml_read_int_sign
	blt	%r10 %r3 min_caml_read_int_sign
	# multiply by 10
	slli	%r11 %r2 $1
	slli	%r12 %r2 $3
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
	sw	0(%r29) %r31
	jal	min_caml_read_int
	sw	1(%r29) %r3  # r3の区切り文字情報をストアしておく
	jal	min_caml_float_of_int
	lw	%r31 0(%r29)
	addi	%r29 %r29 $2
	lw	%r8 -1(%r29)
	addi	%r9 %r0 $0x2e  # '.'
	bneq	%r8 %r9 min_caml_read_float_exit
	# ここから小数点以下
	# 1.1と1.01を区別するため、read_intは使えない
	# r2: ans, r3: #(head zeros) r8: buffer, r9: '0', r10: '9'
	# f2: integer part
	addi	%r9 %r0 $0x30
	addi	%r10 %r0 $0x39
	addi	%r3 %r0 $0
	addi	%r8 %r0 $0
	# 先頭の0を数えつつ上桁を探す
min_caml_read_float_loop1:
	recv8	%r8
	blt	%r8 %r9 min_caml_read_float_exit
	blt	%r10 %r8 min_caml_read_float_exit
	bneq	%r8 %r9 min_caml_read_float_loop1_exit
	addi	%r3 %r3 $1
	beq	%r0 %r0 min_caml_read_float_loop1
min_caml_read_float_loop1_exit:
	addi	%r2 %r8 $-48
min_caml_read_float_loop2:
	# recieve
	recv8	%r8
	blt	%r8 %r9 min_caml_read_float_loop2_exit
	blt	%r10 %r8 min_caml_read_float_loop2_exit
	# multiply by 10
	slli	%r11 %r2 $1
	slli	%r12 %r2 $3
	add	%r2 %r11 %r12
	# add a digit
	addi	%r8 %r8 $-48
	add	%r2 %r2 %r8
	beq	%r0 %r0 min_caml_read_float_loop2
min_caml_read_float_loop2_exit:
	fsw	-1(%r29) %f2
	sw	-2(%r29) %r3
	addi	%r29 %r29 $-3
	sw	0(%r29) %r31
	jal	min_caml_float_of_int
	lw	%r31 0(%r29)
	addi	%r29 %r29 $3
	flw	%f3 -1(%r29)
	lw	%r3 -2(%r29)
	# 小数点以下の部分を0.fffまでずらし、更に頭の0の個数だけずらす
	addi	%r8 %r0 min_caml_float_1
	flw	%f4 0(%r8)
	addi	%r8 %r0 min_caml_read_float_c1
	flw	%f5 0(%r8)
min_caml_read_float_loop3:
	# r3: #(head zero)
	# f2: 小数点以下, f3: 整数部分, f4: 1.0f, f5: 0.1f
	fblt	%f2 %f4 min_caml_read_float_loop4
	fmul	%f2 %f2 %f5
	beq	%r0 %r0 min_caml_read_float_loop3
min_caml_read_float_loop4:
	ble	%r3 %r0 min_caml_read_float_loop4_exit
	addi	%r3 %r3 $-1
	fmul	%f2 %f2 %f5
	beq	%r0 %r0 min_caml_read_float_loop4
min_caml_read_float_loop4_exit:
	# 符号の兼ね合いを見つつ整数部分と小数点以下の部分を足す
	fble	%f0 %f3 min_caml_read_float_loop_exit_positive
	fneg	%f2 %f2
min_caml_read_float_loop_exit_positive:
	fadd	%f2 %f2 %f3
min_caml_read_float_exit:
	jr	%r31
# read_int_byte (32bit, byte -> byte)
min_caml_read_int_byte:
	recv8	%r2
	slli	%r2 %r2 $8
	recv8	%r3
	add	%r2 %r2 %r3
	slli	%r2 %r2 $8
	recv8	%r3
	add	%r2 %r2 %r3
	slli	%r2 %r2 $8
	recv8	%r3
	add	%r2 %r2 %r3
	jr	%r31
# read_float_byte (32bit, byte -> byte)
min_caml_read_float_byte:
	recv8	%r2
	slli	%r2 %r2 $8
	recv8	%r3
	add	%r2 %r2 %r3
	slli	%r2 %r2 $8
	recv8	%r3
	add	%r2 %r2 %r3
	slli	%r2 %r2 $8
	recv8	%r3
	add	%r2 %r2 %r3
	sw	-1(%r29) %r2
	flw	%f2 -1(%r29)
	jr	%r31
##
## libmincaml_int_float.S
## むっちゃ大きい数に対してはまだむちゃくちゃ遅い！
## 加算を倍々に足すやつにすべき(あとでする)
##

# int_of_float (a.k.a. truncate)
min_caml_int_of_float:
min_caml_truncate:
	# FLAGを決めてabsをする
	fblt	%f2 %f0 min_caml_int_of_float_flag_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_int_of_float_after_flag
min_caml_int_of_float_flag_negative:
	addi	%r8 %r0 $1
	fneg	%f2 %f2
min_caml_int_of_float_after_flag:
	addi	%r9 %r0 min_caml_float_int_c2
	flw	%f3 0(%r9)
	fble	%f3 %f2 min_caml_int_of_float_big
	# |x| < 8388608.0
	# r2: answer, r8: FLAG, r9: addr, r10: imm, r11: const for shift
	# f2: |x|, f3: 8388608.0
	fadd	%f2 %f2 %f3
	fsw	-1(%r29) %f2
	lw	%r2 -1(%r29)
	addiu32	%r10 %r0 $0x4b000000
	sub	%r2 %r2 %r10
	# FLAGの調整
	beq	%r8 %r0 min_caml_int_of_float_small_positive
	sub	%r2 %r0 %r2
min_caml_int_of_float_small_positive:
	jr	%r31
min_caml_int_of_float_big:
	# |x| >= 8388608.0
	# r2: answer, r8: FLAG, r9: addr, r11: 8388608
	# f2: |x|, f3: 8388608.0, f4: -8388608.0
	fneg	%f4 %f3
	addi	%r2 %r0 $0
	addiu32 %r11 %r0 $8388608
	# m回8388608を足す
min_caml_int_of_float_big_loop:
	fadd	%f2 %f2 %f4
	add	%r2 %r2 %r11
	fble	%f3 %f2 min_caml_int_of_float_big_loop
	# int_of_float(n)を足す
	sw	-1(%r29) %r2
	addi	%r29 %r29 $-2
	sw	0(%r29) %r31
	jal	min_caml_int_of_float
	lw	%r31 0(%r29)
	addi	%r29 %r29 $2
	lw	%r3 -1(%r29)
	add	%r2 %r2 %r3
	# FLAGの調整
	beq	%r8 %r0 min_caml_int_of_float_big_positive
	sub	%r2 %r0 %r2
min_caml_int_of_float_big_positive:
	jr	%r31
# float_of_int
min_caml_float_of_int:
	# FLAGを決めてabsをする
	ble	%r0 %r2 min_caml_float_of_int_flag_positive
	addi	%r9 %r0 $1
	sub	%r11 %r0 %r2
	beq	%r0 %r0 min_caml_float_of_int_after_flag
min_caml_float_of_int_flag_positive:
	addi	%r9 %r0 $0
	add	%r11 %r0 %r2
min_caml_float_of_int_after_flag:
	addiu32	%r8 %r0 $8388608
	ble	%r8 %r11 min_caml_float_of_int_big
	# |x| < 838860
	# 8388608.0f + xにして、8388608.0fを引く
	# r2: x, r8: const or addr, r9: FLAG, r10: temp, r11: |x|
	# f2: answer
	addiu32	%r8 %r0 $0x4b000000
	add	%r10 %r11 %r8
	sw	-1(%r29) %r10
	flw	%f2 -1(%r29)
	addi	%r8 %r0 min_caml_float_int_c1
	flw	%f3 0(%r8)
	fadd	%f2 %f2 %f3
	# FLAG
	beq	%r9 %r0 min_caml_float_of_int_small_positive
	fneg	%f2 %f2
min_caml_float_of_int_small_positive:
	jr	%r31
min_caml_float_of_int_big:
	# |x| >= 8388608
	# x = m*8388608 + nとしてfloat_of_int(8388608)*m+float_of_int(n)を求める
	# r2: x, r8: |x| or n, r9: FLAG, r10: 8388608, r11: -8388608, r12: temp
	# f2: answer, f3: 8388608.0
	fmov	%f2 %f0
	addi	%r8 %r0 min_caml_float_int_c2
	flw	%f3 0(%r8)
	add	%r8 %r0 %r11
	add	%r9 %r0 %r0
	addiu32	%r10 %r0 $8388608
	sub	%r11 %r0 %r10
min_caml_float_of_int_big_loop:
	# float_of_int(8388608)*mを求める
	fadd	%f2 %f2 %f3
	add	%r8 %r8 %r11
	ble	%r10 %r8 min_caml_float_of_int_big_loop
	# float_of_int(n)を求める
	sw	-1(%r29) %r2
	fsw	-2(%r29) %f2
	addi	%r29 %r29 $-3
	sw	0(%r29) %r31
	add	%r2 %r0 %r8
	jal	min_caml_float_of_int
	lw	%r31 0(%r29)
	addi	%r29 %r29 $3
	flw	%f3 -2(%r29)
	lw	%r2 -1(%r29)
	# 足し算する
	fadd	%f2 %f2 %f3
	# FLAG
	beq	%r9 %r0 min_caml_float_of_int_big_positive
	fneg	%f2 %f2
min_caml_float_of_int_big_positive:
	jr	%r31
