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
deadbeef:
	.long	0x4b806010
reitenichi:
	.long	0x3dcccccd
kakai:
	.long	0xc1200000
nyan:
	.long	0x3f4ccccd
.text
.globl	main
main:
	addi	%r29 %r0 $1023
	addi	%r25 %r0 $10
	sll	%r29 %r29 %r25
	addi	%r29 %r29 $1023
	addi	%r28 %r0 $1023
	addi	%r8 %r0 kakai
	fld	0(%r8) %f0
	addi	%r8 %r0 reitenichi
	fld	0(%r8) %f1
	fneg	%f2 %f0
loop:
	fst	-1(%r29) %f0
	fst	-2(%r29) %f1
	fst	-3(%r29) %f2
	addi	%r29 %r29 $-4
	st	0(%r29) %r31
	nop
	jal	min_caml_print_float_byte
	fld	3(%r29) %f0
	jal	min_caml_int_of_float
	jal	min_caml_print_int_byte
	ld	0(%r29) %r31
	addi	%r29 %r29 $4
	fld	-1(%r29) %f0
	fld	-2(%r29) %f1
	fld	-3(%r29) %f2
	fadd	%f0 %f0 %f1
	fslt	%f2 %f0
	bclt	exit
	addi	%r8 %r0 loop
	jr	%r8
exit:
	halt	
# int_of_float (a.k.a. truncate)
min_caml_int_of_float:
min_caml_truncate:
	# FLAGを決めてabsをする
	addi	%r9 %r0 min_caml_float_0
	fld	0(%r9) %f1
	fslt	%f0 %f1
	bclt	min_caml_int_of_float_flag_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_int_of_float_after_flag
min_caml_int_of_float_flag_negative:
	addi	%r8 %r0 $1
	fneg	%f0 %f0
min_caml_int_of_float_after_flag:
	addi	%r9 %r0 min_caml_float_int_c2
	fld	0(%r9) %f1
	fslt	%f0 %f1
	bclf	min_caml_int_of_float_big
	# |x| < 8388608.0
	# r2: answer, r8: FLAG, r9: addr, r10: imm, r11: const for shift
	# f0: |x|, f1: 8388608.0
	fadd	%f0 %f0 %f1
	fst	-1(%r29) %f0
	ld	-1(%r29) %r2
	addiu32	%r10 %r0 $0x4b000000
	sub	%r2 %r2 %r10
	nop
	# FLAGの調整
	beq	%r8 %r0 min_caml_int_of_float_small_positive
	sub	%r2 %r0 %r2
min_caml_int_of_float_small_positive:
	jr	%r31
min_caml_int_of_float_big:
	# |x| >= 8388608.0
	# r2: answer, r8: FLAG, r9: addr, r10: imm, r11: const for shift
	# f0: |x|, f1: 8388608.0, f2: -8388608.0
	fneg	%f2 %f1
	addi	%r2 %r0 $0
	# m回8388608を足す
min_caml_int_of_float_big_loop:
	fadd	%f0 %f0 %f2
	addiu32 %r11 %r0 $8388608
	add	%r2 %r2 %r11
	fslt	%f0 %f1
	bclf	min_caml_int_of_float_big_loop
	# int_of_float(n)を足す
	st	-1(%r29) %r2
	addi	%r29 %r29 $-2
	st	0(%r29) %r31
	jal	min_caml_int_of_float
	ld	0(%r29) %r31
	addi	%r29 %r29 $2
	ld	-1(%r29) %r3
	add	%r2 %r2 %r3
	# FLAGの調整
	beq	%r8 %r0 min_caml_int_of_float_big_positive
	sub	%r2 %r0 %r2
min_caml_int_of_float_big_positive:
	jr	%r31
# float_of_int
min_caml_float_of_int:
	# FLAGを決めてabsをする
	slt	%r8 %r2 %r0
	beq	%r8 %r0 min_caml_float_of_int_flag_positive
	addi	%r9 %r0 $1
	sub	%r11 %r0 %r2
	beq	%r0 %r0 min_caml_float_of_int_after_flag
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
	sub	%r11 %r0 %r10
min_caml_float_of_int_big_loop:
	# float_of_int(8388608)*mを求める
	fadd	%f0 %f0 %f1
	add	%r8 %r8 %r11
	slt	%r12 %r8 %r10
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
	# 8388608.0 * m + float_of_int(n)
	fadd	%f0 %f0 %f1
	# FLAG
	beq	%r9 %r0 min_caml_float_of_int_big_positive
	fneg	%f0 %f0
min_caml_float_of_int_big_positive:
	jr	%r31
# ffloor
min_caml_floor:
	# float_of_int( int_of_float( x ) )をする
	# |x| >= 8388608のとき元々整数
	# |x| < 8388608のときもっと速くできるがとりあえず実装
	# f0: x
	addi	%r8 %r0 min_caml_float_int_c2
	fld	0(%r8) %f1
	fslt	%f0 %f1
	bclf	min_caml_floor_exit
	addi	%r8 %r0 min_caml_float_int_c1
	fld	0(%r8) %f1
	fslt	%f1 %f0
	bclf	min_caml_floor_exit
min_caml_floor_small:
	fst	-1(%r29) %f0
	addi	%r29 %r29 $-2
	st	0(%r29) %r31
	jal	min_caml_int_of_float
	jal	min_caml_float_of_int
	ld	0(%r29) %r31
	addi	%r29 %r29 $2
	fld	-1(%r29) %f1
	# f0: float_of_int(int_of_float(x)), f1: x, f2: -1.0f, f3: 0.0f, f4: 1.0f
	# x<0ならfloor(x)+1を求めているので-1する
	addi	%r8 %r0 min_caml_float_minus_1
	fld	0(%r8) %f2
	addi	%r8 %r0 min_caml_float_0
	fld	0(%r8) %f3
	fslt	%f1 %f3
	bclf	min_caml_floor_positive
	fadd	%f0 %f0 %f2
min_caml_floor_negative:
	# x < %f0 < x+1となっているときは+1する
	fslt	%f1 %f0
	bclf	min_caml_floor_exit
	addi	%r8 %r0 min_caml_float_1
	fld	0(%r8) %f4
	fadd	%f1 %f1 %f4
	fslt	%f0 %f1
	bclf	min_caml_floor_exit
	fadd	%f0 %f0 %f4
min_caml_floor_positive:
	# x-1 < %f0 < xとなっているときは-1する
	fslt	%f0 %f1
	bclf	min_caml_floor_exit
	fadd	%f1 %f1 %f2
	fslt	%f1 %f0
	bclf	min_caml_floor_exit
	fadd	%f0 %f0 %f2
min_caml_floor_exit:
	jr	%r31
# div10 (unsigned)
min_caml_div10:
	# http://stackoverflow.com/a/19076173
	# http://homepage.cs.uiowa.edu/~jones/bcd/divide.html
	# r2: x/10, r8: x(unsigned), r9: 1, r10: 3
	add	%r8 %r0 %r2
	addi	%r9 %r0 $2
	srl	%r2 %r8 %r9
	add	%r2 %r2 %r8
	addi	%r9 %r0 $1
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r10 %r0 $3
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r10 %r0 $4
	srl	%r2 %r2 %r10
	jr	%r31
# print_int (32bit, byte -> ASCII)
min_caml_print_int:
	# x : signed 32 bit int
	# マイナスだけ出力
	slt	%r8 %r2 %r0
	beq	%r8 %r0 min_caml_print_int_positive
	addi	%r8 %r0 $0x2d # '-'
	send8	%r8
	sub	%r2 %r0 %r2
min_caml_print_int_positive:
	# 下から1桁ずつASCIIに直して上から出力
	# r2: x -> x/10, r8: x -> x mod 10, r12: counter
	addi	%r12 %r0 $8
	add	%r8 %r0 %r0
	add	%r9 %r0 %r0
min_caml_print_int_loop:
	# max 10 digits
	# divide by 10
	st	-1(%r29) %r2
	st	-2(%r29) %r8
	st	-3(%r29) %r9
	st	-4(%r29) %r12
	addi	%r29 %r29 $-5
	st	0(%r29) %r31
	jal	min_caml_div10
	ld	0(%r29) %r31
	addi	%r29 %r29 $5
	ld	-1(%r29) %r8
	ld	-4(%r29) %r12	
	# multiply by 10
	addi	%r9 %r0 $1
	sll	%r10 %r2 %r9
	addi	%r9 %r0 $3
	sll	%r11 %r2 %r9
	add	%r10 %r10 %r11
	# x mod 10
	sub	%r10 %r8 %r10
	# [0-9] in binary -> ASCII
	addi	%r10 %r10 $0x30	
	ld	-2(%r29) %r8
	ld	-3(%r29) %r9
	addi	%r13 %r0 $8
	sll	%r9 %r9 %r13
	addi	%r14 %r0 $24
	srl	%r11 %r8 %r14
	add	%r9 %r9 %r11
	sll	%r8 %r8 %r13
	add	%r8 %r8 %r10
	# loop check
	beq	%r2 %r0 min_caml_print_int_send
	addi	%r12 %r12 $-1
	beq	%r12 %r0 min_caml_print_int_loop_exit
	addi	%r13 %r0 min_caml_print_int_loop
	jr	%r13
min_caml_print_int_loop_exit:
	# rest 2 digits
	# r2: x/(10^7), r8: upper 4 bytes ASCII, r9: lower 4 bytes ASCII
	# remark: byte sequence is reversed
	# divide by 10
	st	-1(%r29) %r2
	st	-2(%r29) %r8
	st	-3(%r29) %r9
	addi	%r29 %r29 $-4
	st	0(%r29) %r31
	jal	min_caml_div10
	ld	0(%r29) %r31
	addi	%r29 %r29 $4
	ld	-1(%r29) %r8
	# multiply by 10
	addi	%r9 %r0 $1
	sll	%r10 %r2 %r9
	addi	%r9 %r0 $1
	sll	%r11 %r2 %r9
	add	%r10 %r10 %r11
	# x mod 10
	sub	%r10 %r8 %r10
	# [0-9] in binary -> ASCII
	addi	%r10 %r10 $0x30
	beq	%r2 %r0 min_caml_print_int_send_9
	# rest 1 digit
	addi	%r2 %r2 $0x30
	send8	%r2
min_caml_print_int_send_9:
	send8	%r10
	ld	-2(%r29) %r8
	ld	-3(%r29) %r9
min_caml_print_int_send:
	addi	%r10 %r0 $8
	send8	%r8
	srl	%r8 %r8 %r10
	beq	%r8 %r0 min_caml_print_int_exit
	send8	%r8
	srl	%r8 %r8 %r10
	beq	%r8 %r0 min_caml_print_int_exit
	send8	%r8
	srl	%r8 %r8 %r10
	beq	%r8 %r0 min_caml_print_int_exit
	send8	%r8
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
	srl	%r9 %r9 %r10
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
	srl	%r9 %r9 %r10
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
	srl	%r9 %r9 %r10
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
min_caml_print_int_exit:
	jr	%r31
# print_int (32bit, byte -> byte)
min_caml_print_int_byte:
	addi	%r9 %r0 $24
	srl	%r10 %r2 %r9
	send8	%r10
	addi	%r9 %r0 $16
	srl	%r10 %r2 %r9
	send8	%r10
	addi	%r9 %r0 $8
	srl	%r10 %r2 %r9
	send8	%r10
	send8	%r2
	jr	%r31	
# print_float (32bit, byte -> byte)
min_caml_print_float_byte:
	fst	-1(%r29) %f0
	ld	-1(%r29) %r8
	addi	%r9 %r0 $24
	srl	%r10 %r8 %r9
	send8	%r10
	addi	%r9 %r0 $16
	srl	%r10 %r8 %r9
	send8	%r10
	addi	%r9 %r0 $8
	srl	%r10 %r8 %r9
	send8	%r10
	send8	%r8
	jr	%r31	
