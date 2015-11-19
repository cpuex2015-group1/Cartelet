# atan
min_caml_atan:
	# r8: FLAG, r9: addr
	# f0: x, f1: pi, f2: 0.5, f3: temp(pi/4, pi/2), f4: temp, f5: temp
	addi	%r9 %r0 min_caml_float_0
	fld	0(%r9) %f1
	fslt	%f0 %f1
	bclt	min_caml_atan_flag_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_atan_after_flag
min_caml_atan_flag_negative:
	addi	%r8 %r0 $1
	fabs	%f0 %f0
min_caml_atan_after_flag:
	addi	%r9 %r0 min_caml_atan_c1
	fld	0(%r9) %f4
	fslt	%f0 %f4
	bclf	min_caml_atan_2
	# |x| < 0.4375
	# kernel_atan(|x|)を返す
	addi	%r29 %r29 $-1
	st	0(%r29) %r31
	jal	min_caml_kernel_atan
	ld	0(%r29) %r31
	addi	%r29 %r29 $1
	beq	%r8 %r0 min_caml_atan_positive
	fabs	%f0 %f0
	fneg	%f0 %f0
	jr	%r31
min_caml_atan_positive:
	fabs	%f0 %f0
	jr	%r31
min_caml_atan_2:
	addi	%r9 %r0 min_caml_atan_c2
	fld	0(%r9) %f4
	fslt	%f0 %f4
	bclf	min_caml_atan_3
	# 0.4375 <= |x| < 2.4375
	# pi/4 + kernel_atan((|x|-1)/(|x|+1)) = kernel_atan(|x|)を返す
	# r8: FLAG, r9: addr
	# f0: x, f1: pi, f2: 0.5, f3: temp(pi/4), f4: |x|+1, f5: |x|-1
	addi	%r9 %r0 min_caml_float_1
	fld	0(%r9) %f3
	fadd	%f4 %f0 %f3
	fneg	%f3 %f3
	fadd	%f5 %f0 %f3
	finv	%f4 %f4
	fmul	%f0 %f4 %f5
	addi	%r29 %r29 $-1
	st	0(%r29) %r31
	jal	min_caml_kernel_atan
	ld	0(%r29) %r31
	addi	%r29 %r29 $1
	addi	%r9 %r0 min_caml_quarter_pi
	fld	0(%r9) %f3
	fadd	%f0 %f0 %f3
	beq	%r8 %r0 min_caml_atan_positive
	fabs	%f0 %f0
	fneg	%f0 %f0
	jr	%r31
min_caml_atan_3:
	# |x| >= 2.4375
	# pi/2 - kernel_atan(1/|x|) = kernel_atan(|x|)を返す
	# r8: FLAG, r9: addr
	# f0: x, f1: pi, f2: 0.5, f3: temp(pi/2), f4: temp, f5: temp
	finv	%f0 %f0
	addi	%r29 %r29 $-1
	st	0(%r29) %r31
	jal	min_caml_kernel_atan
	ld	0(%r29) %r31
	addi	%r29 %r29 $1
	fneg	%f4 %f0
	addi	%r9 %r0 min_caml_half_pi
	fld	0(%r9) %f0
	fadd	%f0 %f0 %f4
	beq	%r8 %r0 min_caml_atan_positive
	fabs	%f0 %f0
	fneg	%f0 %f0
	jr	%r31
min_caml_kernel_atan:
	# Tayler展開で計算する
	# r8には触らないようにする, r9: addr
	# f0: x or answer, f1: temp, f2: x^2, f3: const
	fmul	%f2 %f0 %f0
	addi	%r9 %r0 min_caml_kernel_atan_c6
	fld	0(%r9) %f3
	fmul	%f1 %f3 %f2
	addi	%r9 %r0 min_caml_kernel_atan_c5
	fld	0(%r9) %f3
	fadd	%f1 %f1 %f3
	fmul	%f1 %f1 %f2
	addi	%r9 %r0 min_caml_kernel_atan_c4
	fld	0(%r9) %f3
	fadd	%f1 %f1 %f3
	fmul	%f1 %f1 %f2
	addi	%r9 %r0 min_caml_kernel_atan_c3
	fld	0(%r9) %f3
	fadd	%f1 %f1 %f3
	fmul	%f1 %f1 %f2
	addi	%r9 %r0 min_caml_kernel_atan_c2
	fld	0(%r9) %f3
	fadd	%f1 %f1 %f3
	fmul	%f1 %f1 %f2
	addi	%r9 %r0 min_caml_kernel_atan_c1
	fld	0(%r9) %f3
	fadd	%f1 %f1 %f3
	fmul	%f1 %f1 %f2
	fmul	%f1 %f1 %f0
	fadd	%f0 %f1 %f0
	jr	%r31
