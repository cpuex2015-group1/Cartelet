.data
min_caml_2pi:
	.long	0x40c90fdb
min_caml_pi:
	.long	0x40490fdb
min_caml_pi_rest:
	.long	0xb3bbbd2e
min_caml_pi_rest_neg:
	.long	0x33bbbd2e
min_caml_half_pi:
	.long	0x3fc90fdb
min_caml_quarter_pi:
	.long	0x3f490fdb
min_caml_float_0:
	.long	0x00000000
min_caml_float_1:
	.long	0x3f800000
min_caml_float_2:
	.long	0x40000000
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
reitenichi:
	.long	0x3dcccccd
minus2pi:
	.long	0xc1fb53d1
nyan:
	.long	0x3f060a92
.text
.globl	main
main:
#	addi	%r29 %r0 $1023
#	addi	%r25 %r0 $10
#	sll	%r29 %r29 %r25
#	addi	%r29 %r29 $1023
#	addi	%r28 %r0 $1023
#	addi	%r8 %r0 nyan
#	fld	0(%r8) %f0
#	addi	%r8 %r0 $0
#	jal	min_caml_kernel_sin
#	halt


	addi	%r29 %r0 $1023
	addi	%r25 %r0 $10
	sll	%r29 %r29 %r25
	addi	%r29 %r29 $1023
	addi	%r28 %r0 $1023
	addi	%r8 %r0 minus2pi
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
	jal	min_caml_print_float_byte
	fld	3(%r29) %f0
	addi	%r8 %r0 $0
	jal	min_caml_sin
	jal	min_caml_print_float_byte
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
# cos
min_caml_cos:
	# 定義域を[0, 2pi)にする
	# r8: FLAG, r9: addr
	# f0: x, f1: pi, f3: pi/2, f4: temp
	fabs	%f0 %f0
	addi	%r29 %r29 $-1
	st	0(%r29) %r31
	jal	min_caml_reduction_2pi
	ld	0(%r29) %r31
	addi	%r29 %r29 $1
	addi	%r8 %r0 $0
	# x >= piならx := x - pi, FLAG reverse
	addi	%r9 %r0 min_caml_pi
	fld	0(%r9) %f1
	fslt	%f0 %f1
	bclt	min_caml_cos_2
	fneg	%f4 %f1
	fadd	%f0 %f0 %f4
	beq	%r8 %r0 min_caml_cos_1_0
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_cos_2
min_caml_cos_1_0:
	addi	%r8 %r0 $1
min_caml_cos_2:
	# x >= pi/2ならx := pi - x, FLAG reverse
	addi	%r9 %r0 min_caml_half_pi
	fld	0(%r9) %f3
	fslt	%f0 %f3
	bclt	min_caml_cos_3
	fneg	%f4 %f0
	fadd	%f0 %f1 %f4
	beq	%r8 %r0 min_caml_cos_2_0
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_cos_3
min_caml_cos_2_0:
	addi	%r8 %r0 $1
min_caml_cos_3:
	# x <= pi/4ならkernel_cos, そうでないならx := pi/2 - x, kernel_sinする
	addi	%r9 %r0 min_caml_quarter_pi
	fld	0(%r9) %f4
	fslt	%f4 %f0
	bclf	min_caml_kernel_cos
	fneg	%f4 %f0
	fadd	%f0 %f3 %f4
	beq	%r0 %r0 min_caml_kernel_sin
min_caml_kernel_cos:
	# Tayler展開で計算する
	# r8: flag, r9: addr
	# f0: answer, f1: x^2, f3: const
	fmul	%f1 %f0 %f0
	addi	%r9 %r0 min_caml_kernel_cos_c3
	fld	0(%r9) %f3
	fmul	%f0 %f3 %f1
	addi	%r9 %r0 min_caml_kernel_cos_c2
	fld	0(%r9) %f3
	fadd	%f0 %f0 %f3
	fmul	%f0 %f0 %f1
	addi	%r9 %r0 min_caml_kernel_cos_c1
	fld	0(%r9) %f3
	fadd	%f0 %f0 %f3
	fmul	%f0 %f0 %f1
	addi	%r9 %r0 min_caml_float_1
	fld	0(%r9) %f3
	fadd	%f0 %f0 %f3
	beq	%r8 %r0 min_caml_kernel_cos_positive
	fabs	%f0 %f0
	fneg	%f0 %f0
	jr	%r31
min_caml_kernel_cos_positive:
	fabs	%f0 %f0
	jr	%r31
# sin
min_caml_sin:
	# 定義域を[0, 2pi)にする
	# r8: FLAG, r9: addr
	# f0: x, f1: pi, f3: pi/2, f4: temp
	addi	%r9 %r0 min_caml_float_0
	fld	0(%r9) %f1
	fslt	%f0 %f1
	bclt	min_caml_sin_flag_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_sin_after_flag
min_caml_sin_flag_negative:
	addi	%r8 %r0 $1
	fabs	%f0 %f0
min_caml_sin_after_flag:
	st	-1(%r29) %r8
	addi	%r29 %r29 $-2
	st	0(%r29) %r31
	jal	min_caml_reduction_2pi
	ld	0(%r29) %r31
	addi	%r29 %r29 $2
	ld	-1(%r29) %r8
	# x >= piならx := x - pi, FLAG reverse
	addi	%r9 %r0 min_caml_pi
	fld	0(%r9) %f1
	fslt	%f0 %f1
	bclt	min_caml_sin_2
	fneg	%f4 %f1
	fadd	%f0 %f0 %f4
#	addi	%r9 %r0 min_caml_pi_rest_neg
#	fld	0(%r9) %f4
#	fadd	%f0 %f0 %f4
	beq	%r8 %r0 min_caml_sin_1_0
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_sin_2
min_caml_sin_1_0:
	addi	%r8 %r0 $1
min_caml_sin_2:
	# x >= pi/2ならx := pi - x
	addi	%r9 %r0 min_caml_half_pi
	fld	0(%r9) %f3
	fslt	%f0 %f3
	bclt	min_caml_sin_3
	fneg	%f4 %f0
	fadd	%f0 %f1 %f4
#	addi	%r9 %r0 min_caml_pi_rest
#	fld	0(%r9) %f4
#	fadd	%f0 %f0 %f4
min_caml_sin_3:
	# x <= pi/4ならkernel_sin, そうでないならx := pi/2 - x, kernel_cosする
	addi	%r9 %r0 min_caml_quarter_pi
	fld	0(%r9) %f4
	fslt	%f4 %f0
	bclf	min_caml_kernel_sin
	fneg	%f4 %f0
	fadd	%f0 %f3 %f4
	beq	%r0 %r0 min_caml_kernel_cos
min_caml_kernel_sin:
	# Tayler展開で計算する
	# r8: flag, r9: addr
	# f0: x or answer, f1: temp, f2: x^2, f3: const
	fmul	%f2 %f0 %f0
	addi	%r9 %r0 min_caml_kernel_sin_c3
	fld	0(%r9) %f3
	fmul	%f1 %f3 %f2
	addi	%r9 %r0 min_caml_kernel_sin_c2
	fld	0(%r9) %f3
	fadd	%f1 %f1 %f3
	fmul	%f1 %f1 %f2
	addi	%r9 %r0 min_caml_kernel_sin_c1
	fld	0(%r9) %f3
	fadd	%f1 %f1 %f3
	fmul	%f1 %f1 %f2
	fmul	%f1 %f1 %f0
	fadd	%f0 %f1 %f0
	beq	%r8 %r0 min_caml_kernel_sin_positive
	fabs	%f0 %f0
	fneg	%f0 %f0
	jr	%r31
min_caml_kernel_sin_positive:
	fabs	%f0 %f0
	jr	%r31
# cos & sin
min_caml_reduction_2pi:
	# f0を[0, 2pi)にする
	# f1: 2*pi, f2: 0.5, f3: p, f4: 2.0 or -p, f5: rest2pi, f6: -rest2pi
	addi	%r9 %r0 min_caml_2pi
	fld	0(%r9) %f1
	fmov	%f3 %f1
	addi	%r9 %r0 min_caml_float_half
	fld	0(%r9) %f2
	addi	%r9 %r0 min_caml_float_2
	fld	0(%r9) %f4
min_caml_reduction_2pi_while1:
	fslt	%f0 %f3
	bclt	min_caml_reduction_2pi_while2
	fmul	%f3 %f3 %f4
	beq	%r0 %r0 min_caml_reduction_2pi_while1
min_caml_reduction_2pi_while2:
	fslt	%f0 %f1
	bclt	min_caml_reduction_2pi_while2_exit
	fslt	%f0 %f3
	bclt	min_caml_reduction_2pi_while2_after_if
	fneg	%f4 %f3
	fadd	%f0 %f0 %f4
min_caml_reduction_2pi_while2_after_if:
	fmul	%f3 %f3 %f2
	beq	%r0 %r0 min_caml_reduction_2pi_while2
min_caml_reduction_2pi_while2_exit:
	jr	%r31
# print_newline
min_caml_print_newline:
	addi	%r8 %r0 $0x0a  # LF
	send8	%r8
	jr	%r31
# print_char (print_byte)
min_caml_print_byte:
min_caml_print_char:
	send8	%r2
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
