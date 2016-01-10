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
#	.long	0xc1200000
	.long	0xc9742400
nyan:
	.long	0x3f060a92
.text
.globl	main
main:
	addi	%r29 %r0 $1023
	slli	%r29 %r29 $10
	addi	%r29 %r29 $1023
	addi	%r28 %r0 $1023
	addi	%r8 %r0 kakai
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
	jal	min_caml_floor
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
# ffloor
min_caml_floor:
	# float_of_int( int_of_float( x ) )をする
	# |x| >= 8388608のとき元々整数
	# |x| < 8388608のときfloat_of_int(int_of_float(x))を計算して、round evenによって生まれる調整
	# f2: x
	addi	%r9 %r0 min_caml_float_int_c1
	flw	%f5 0(%r9)
	fble	%f2 %f5	min_caml_floor_exit
	addi	%r9 %r0 min_caml_float_int_c2
	flw	%f4 0(%r9)
	fble	%f4 %f2 min_caml_floor_exit
min_caml_floor_small:
	# float_of_int(int_of_float(x))をする
	# r8: FLAG
	# f2: result, f3: x, f4: 8388608.0, f5: -8388608.0
	fmov	%f3 %f2
	fblt	%f2 %f0 min_caml_floor_small_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_floor_after_flag
min_caml_floor_small_negative:
	addi	%r8 %r0 $1
	fneg	%f2 %f2
min_caml_floor_after_flag:
	fadd	%f2 %f2 %f4
	fadd	%f2 %f2 %f5
	beq	%r8 %f2 min_caml_floor_adjust
	fneg	%f2 %f2
min_caml_floor_adjust:
	# r8: FLAG
	# f2: float_of_int(int_of_float(x)), f3: x, f4: -1.0f
	# %f2-1.0 < x < %f2となっているときは-1.0する
	addi	%r9 %r0 min_caml_float_minus_1
	flw	%f4 0(%r9)
	fble	%f2 %f3 min_caml_floor_exit
	fadd	%f5 %f2 %f4
	fble	%f3 %f5 min_caml_floor_exit
	fmov	%f2 %f5
min_caml_floor_exit:
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
