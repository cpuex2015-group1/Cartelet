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
	lw	-1(%r29) %r8
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

