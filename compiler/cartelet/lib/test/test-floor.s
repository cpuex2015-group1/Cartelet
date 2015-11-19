.data
min_caml_pi:
	.long	0x40490fdb
min_caml_half_pi:
	.long	0x3fc90fdb
min_caml_quarter_pi:
	.long	0x3f490fdb
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
reitenichi:
	.long	0x3dcccccd
kakai:
	.long	0xc1200000
nyan:
	.long	0x3f060a92
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
	jal	min_caml_print_float_byte
	fld	3(%r29) %f0
	jal	min_caml_floor
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
# ffloor
min_caml_floor:
	# float_of_int( int_of_float( x ) )をする
	# |x| >= 8388608のとき元々整数
	# |x| < 8388608のときfloat_of_int(int_of_float(x))を計算して、round evenによって生まれる調整
	# f0: x
	addi	%r9 %r0 min_caml_float_int_c1
	fld	0(%r9) %f3
	fslt	%f3 %f0
	bclf	min_caml_floor_exit
	addi	%r9 %r0 min_caml_float_int_c2
	fld	0(%r9) %f2
	fslt	%f0 %f2
	bclf	min_caml_floor_exit
min_caml_floor_small:
	# float_of_int(int_of_float(x))をする
	# r8: FLAG
	# f0: result, f1: x, f2: 8388608.0, f3: -8388608.0, f4: 0.0
	fmov	%f1 %f0
	addi	%r9 %r0 min_caml_float_0
	fld	0(%r9) %f4
	fslt	%f0 %f4
	bclt	min_caml_floor_small_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_floor_after_flag
min_caml_floor_small_negative:
	addi	%r8 %r0 $1
	fneg	%f0 %f0
min_caml_floor_after_flag:
	fadd	%f0 %f0 %f2
	fadd	%f0 %f0 %f3
	beq	%r8 %f0 min_caml_floor_adjust
	fneg	%f0 %f0
min_caml_floor_adjust:
	# r8: FLAG
	# f0: float_of_int(int_of_float(x)), f1: x, f2: -1.0f
	# %f0-1.0 < x < %f0となっているときは-1.0する
	addi	%r9 %r0 min_caml_float_minus_1
	fld	0(%r9) %f2
	fslt	%f1 %f0
	bclf	min_caml_floor_exit
	fadd	%f3 %f0 %f2
	fslt	%f3 %f1
	bclf	min_caml_floor_exit
	fmov	%f0 %f3
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
