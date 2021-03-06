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
