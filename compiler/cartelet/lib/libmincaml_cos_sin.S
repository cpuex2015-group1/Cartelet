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
	# f1: 2*pi, f2: 0.5, f3: p, f4: 2.0 or -p
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
