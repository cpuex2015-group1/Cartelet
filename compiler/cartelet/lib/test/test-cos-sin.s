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
	slli	%r29 %r29 $10
	addi	%r29 %r29 $1023
	addi	%r28 %r0 $1023
	addi	%r8 %r0 minus2pi
	flw	%f2 0(%r8)
	addi	%r8 %r0 reitenichi
	flw	%f3 0(%r8)
	fneg	%f4 %f2
loop:
	fsw	-1(%r29) %f2
	fsw	-2(%r29) %f3
	fsw	-3(%r29) %f4
	addi	%r29 %r29 $-4
	sw	0(%r29) %r31
	jal	min_caml_print_float_byte
	flw	%f2 3(%r29)
	addi	%r8 %r0 $0
	jal	min_caml_sin
	jal	min_caml_print_float_byte
	lw	%r31 0(%r29)
	addi	%r29 %r29 $4
	flw	%f2 -1(%r29)
	flw	%f3 -2(%r29)
	flw	%f4 -3(%r29)
	fadd	%f2 %f2 %f3
	fblt	%f4 %f2 exit
	addi	%r8 %r0 loop
	jr	%r8
exit:
	halt
# cos
min_caml_cos:
	# 定義域を[0, 2pi)にする
	# r8: FLAG, r9: addr
	# f2: x, f3: pi, f5: pi/2, f6: temp
	fabs	%f2 %f2
	addi	%r29 %r29 $-1
	sw	0(%r29) %r31
	jal	min_caml_reduction_2pi
	lw	%r31 0(%r29)
	addi	%r29 %r29 $1
	addi	%r8 %r0 $0
	# x >= piならx := x - pi, FLAG reverse
	addi	%r9 %r0 min_caml_pi
	flw	%f3 0(%r9)
	fblt	%f2 %f3 min_caml_cos_2
	fneg	%f6 %f3
	fadd	%f2 %f2 %f6
	beq	%r8 %r0 min_caml_cos_1_0
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_cos_2
min_caml_cos_1_0:
	addi	%r8 %r0 $1
min_caml_cos_2:
	# x >= pi/2ならx := pi - x, FLAG reverse
	addi	%r9 %r0 min_caml_half_pi
	flw	%f5 0(%r9)
	fblt	%f2 %f5 min_caml_cos_3
	fneg	%f6 %f2
	fadd	%f2 %f3 %f6
	beq	%r8 %r0 min_caml_cos_2_0
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_cos_3
min_caml_cos_2_0:
	addi	%r8 %r0 $1
min_caml_cos_3:
	# x <= pi/4ならkernel_cos, そうでないならx := pi/2 - x, kernel_sinする
	addi	%r9 %r0 min_caml_quarter_pi
	flw	%f6 0(%r9)
	fble	%f2 %f6 min_caml_kernel_cos
	fneg	%f6 %f2
	fadd	%f2 %f5 %f6
	beq	%r0 %r0 min_caml_kernel_sin
min_caml_kernel_cos:
	# Tayler展開で計算する
	# r8: flag, r9: addr
	# f2: answer, f3: x^2, f5: const
	fmul	%f3 %f2 %f2
	addi	%r9 %r0 min_caml_kernel_cos_c3
	flw	%f5 0(%r9)
	fmul	%f2 %f5 %f3
	addi	%r9 %r0 min_caml_kernel_cos_c2
	flw	%f5 0(%r9)
	fadd	%f2 %f2 %f5
	fmul	%f2 %f2 %f3
	addi	%r9 %r0 min_caml_kernel_cos_c1
	flw	%f5 0(%r9)
	fadd	%f2 %f2 %f5
	fmul	%f2 %f2 %f3
	addi	%r9 %r0 min_caml_float_1
	flw	%f5 0(%r9)
	fadd	%f2 %f2 %f5
	beq	%r8 %r0 min_caml_kernel_cos_positive
	fabs	%f2 %f2
	fneg	%f2 %f2
	jr	%r31
min_caml_kernel_cos_positive:
	fabs	%f2 %f2
	jr	%r31
# sin
min_caml_sin:
	# 定義域を[0, 2pi)にする
	# r8: FLAG, r9: addr
	# f2: x, f3: pi, f5: pi/2, f6: temp
	fblt	%f2 %f0 min_caml_sin_flag_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_sin_after_flag
min_caml_sin_flag_negative:
	addi	%r8 %r0 $1
	fabs	%f2 %f2
min_caml_sin_after_flag:
	sw	-1(%r29) %r8
	addi	%r29 %r29 $-2
	sw	0(%r29) %r31
	jal	min_caml_reduction_2pi
	lw	%r31 0(%r29)
	addi	%r29 %r29 $2
	lw	%r8 -1(%r29)
	# x >= piならx := x - pi, FLAG reverse
	addi	%r9 %r0 min_caml_pi
	flw	%f3 0(%r9)
	fblt	%f2 %f3 min_caml_sin_2
	fneg	%f6 %f3
	fadd	%f2 %f2 %f6
	beq	%r8 %r0 min_caml_sin_1_0
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_sin_2
min_caml_sin_1_0:
	addi	%r8 %r0 $1
min_caml_sin_2:
	# x >= pi/2ならx := pi - x
	addi	%r9 %r0 min_caml_half_pi
	flw	%f5 0(%r9)
	fblt	%f2 %f5 min_caml_sin_3
	fneg	%f6 %f2
	fadd	%f2 %f3 %f6
min_caml_sin_3:
	# x <= pi/4ならkernel_sin, そうでないならx := pi/2 - x, kernel_cosする
	addi	%r9 %r0 min_caml_quarter_pi
	flw	%f6 0(%r9)
	fble	%f2 %f6 min_caml_kernel_sin
	fneg	%f6 %f2
	fadd	%f2 %f5 %f6
	beq	%r0 %r0 min_caml_kernel_cos
min_caml_kernel_sin:
	# Tayler展開で計算する
	# r8: flag, r9: addr
	# f2: x or answer, f3: temp, f4: x^2, f5: const
	fmul	%f4 %f2 %f2
	addi	%r9 %r0 min_caml_kernel_sin_c3
	flw	%f5 0(%r9)
	fmul	%f3 %f5 %f4
	addi	%r9 %r0 min_caml_kernel_sin_c2
	flw	%f5 0(%r9)
	fadd	%f3 %f3 %f5
	fmul	%f3 %f3 %f4
	addi	%r9 %r0 min_caml_kernel_sin_c1
	flw	%f5 0(%r9)
	fadd	%f3 %f3 %f5
	fmul	%f3 %f3 %f4
	fmul	%f3 %f3 %f2
	fadd	%f2 %f3 %f2
	beq	%r8 %r0 min_caml_kernel_sin_positive
	fabs	%f2 %f2
	fneg	%f2 %f2
	jr	%r31
min_caml_kernel_sin_positive:
	fabs	%f2 %f2
	jr	%r31
# cos & sin
min_caml_reduction_2pi:
	# f2を[0, 2pi)にする
	# f3: 2*pi, f4: 0.5, f5: p, f6: 2.0 or -p
	addi	%r9 %r0 min_caml_2pi
	flw	%f3 0(%r9)
	fmov	%f5 %f3
	addi	%r9 %r0 min_caml_float_half
	flw	%f4 0(%r9)
	addi	%r9 %r0 min_caml_float_2
	flw	%f6 0(%r9)
min_caml_reduction_2pi_while1:
	fblt	%f2 %f5 min_caml_reduction_2pi_while2
	fmul	%f5 %f5 %f6
	beq	%r0 %r0 min_caml_reduction_2pi_while1
min_caml_reduction_2pi_while2:
	fblt	%f2 %f3 min_caml_reduction_2pi_while2_exit
	fblt	%f2 %f5 min_caml_reduction_2pi_while2_after_if
	fneg	%f6 %f5
	fadd	%f2 %f2 %f6
min_caml_reduction_2pi_while2_after_if:
	fmul	%f5 %f5 %f4
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
	ble	%r0 %r2 min_caml_print_int_positive
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
	sw	-1(%r29) %r2
	sw	-2(%r29) %r8
	sw	-3(%r29) %r9
	sw	-4(%r29) %r12
	addi	%r29 %r29 $-5
	sw	0(%r29) %r31
	jal	min_caml_div10
	lw	%r31 0(%r29)
	addi	%r29 %r29 $5
	lw	%r8 -1(%r29)
	lw	%r12 -4(%r29)
	# multiply by 10
	slli	%r10 %r2 $1
	slli	%r11 %r2 $3
	add	%r10 %r10 %r11
	# x mod 10
	sub	%r10 %r8 %r10
	# [0-9] in binary -> ASCII
	addi	%r10 %r10 $0x30	
	lw	%r8 -2(%r29)
	lw	%r9 -3(%r29)
	slli	%r9 %r9 $8
	slli	%r11 %r8 $-24
	add	%r9 %r9 %r11
	slli	%r8 %r8 $8
	add	%r8 %r8 %r10
	# loop check
	beq	%r2 %r0 min_caml_print_int_send
	addi	%r12 %r12 $-1
	beq	%r12 %r0 min_caml_print_int_loop_exit
	beq	%r0 %r0 min_caml_print_int_loop
min_caml_print_int_loop_exit:
	# rest 2 digits
	# r2: x/(10^7), r8: upper 4 bytes ASCII, r9: lower 4 bytes ASCII
	# remark: byte sequence is reversed
	# divide by 10
	sw	-1(%r29) %r2
	sw	-2(%r29) %r8
	sw	-3(%r29) %r9
	addi	%r29 %r29 $-4
	sw	0(%r29) %r31
	jal	min_caml_div10
	lw	%r31 0(%r29)
	addi	%r29 %r29 $4
	lw	%r8 -1(%r29)
	# multiply by 10
	slli	%r10 %r2 $1
	slli	%r11 %r2 $3
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
	lw	%r8 -2(%r29)
	lw	%r9 -3(%r29)
min_caml_print_int_send:
	send8	%r8
	slli	%r8 %r8 $-8
	beq	%r8 %r0 min_caml_print_int_exit
	send8	%r8
	slli	%r8 %r8 $-8
	beq	%r8 %r0 min_caml_print_int_exit
	send8	%r8
	slli	%r8 %r8 $-8
	beq	%r8 %r0 min_caml_print_int_exit
	send8	%r8
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
	slli	%r9 %r9 $-8
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
	slli	%r9 %r9 $-8
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
	slli	%r9 %r9 $-8
	beq	%r9 %r0 min_caml_print_int_exit
	send8	%r9
min_caml_print_int_exit:
	jr	%r31
# print_int (32bit, byte -> byte)
min_caml_print_int_byte:
	slli	%r10 %r2 $-24
	send8	%r10
	slli	%r10 %r2 $-16
	send8	%r10
	slli	%r10 %r2 $-8
	send8	%r10
	send8	%r2
	jr	%r31	
# print_float (32bit, byte -> byte)
min_caml_print_float_byte:
	fsw	-1(%r29) %f2
	lw	%r8 -1(%r29)
	slli	%r10 %r8 $-24
	send8	%r10
	slli	%r10 %r8 $-16
	send8	%r10
	slli	%r10 %r8 $-8
	send8	%r10
	send8	%r8
	jr	%r31	
# div10 (unsigned)
min_caml_div10:
	# http://stackoverflow.com/a/19076173
	# http://homepage.cs.uiowa.edu/~jones/bcd/divide.html
	# 後で書き直す
	# r2: x/10, r8: x(unsigned)
	add	%r8 %r0 %r2
	slli	%r2 %r8 $-2
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-3
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-3
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-3
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-3
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-3
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-3
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-3
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-1
	add	%r2 %r2 %r8
	slli	%r2 %r2 $-4
	jr	%r31
