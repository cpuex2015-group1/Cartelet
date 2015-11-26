##
## libmincaml_int_float.S
## むっちゃ大きい数に対してはまだむちゃくちゃ遅い！
## 加算を倍々に足すやつにすべき(あとでする)
##

# int_of_float (a.k.a. truncate)
min_caml_int_of_float:
min_caml_truncate:
	# FLAGを決めてabsをする
	addi	%r9 %r0 min_caml_float_0
	flw	%f1 0(%r9)
	fslt	%f0 %f1
	bclt	min_caml_int_of_float_flag_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_int_of_float_after_flag
min_caml_int_of_float_flag_negative:
	addi	%r8 %r0 $1
	fneg	%f0 %f0
min_caml_int_of_float_after_flag:
	addi	%r9 %r0 min_caml_float_int_c2
	flw	%f1 0(%r9)
	fslt	%f0 %f1
	bclf	min_caml_int_of_float_big
	# |x| < 8388608.0
	# r2: answer, r8: FLAG, r9: addr, r10: imm, r11: const for shift
	# f0: |x|, f1: 8388608.0
	fadd	%f0 %f0 %f1
	fsw	-1(%r29) %f0
	lw	-1(%r29) %r2
	addiu32	%r10 %r0 $0x4b000000
	sub	%r2 %r2 %r10
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
	sw	-1(%r29) %r2
	addi	%r29 %r29 $-2
	sw	0(%r29) %r31
	jal	min_caml_int_of_float
	lw	%r31 0(%r29)
	addi	%r29 %r29 $2
	lw	-1(%r29) %r3
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
	sw	-1(%r29) %r10
	flw	-1(%r29) %f0
	addi	%r8 %r0 min_caml_float_int_c1
	flw	%f1 0(%r8)
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
	flw	%f0 0(%r8)
	addi	%r8 %r0 min_caml_float_int_c2
	flw	%f1 0(%r8)
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
	sw	-1(%r29) %r2
	fsw	-2(%r29) %f0
	addi	%r29 %r29 $-3
	sw	0(%r29) %r31
	add	%r2 %r0 %r8
	jal	min_caml_float_of_int
	lw	%r31 0(%r29)
	addi	%r29 %r29 $3
	flw	-2(%r29) %f1
	lw	-1(%r29) %r2
	# 足し算する
	fadd	%f0 %f0 %f1
	# FLAG
	beq	%r9 %r0 min_caml_float_of_int_big_positive
	fneg	%f0 %f0
min_caml_float_of_int_big_positive:
	jr	%r31
