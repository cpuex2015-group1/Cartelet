# atan
min_caml_atan:
	# r8: FLAG, r9: addr
	# f2: x, f4: 0.5, f5: temp(pi/4, pi/2), f6: temp, f7: temp
	fblt	%f2 %f0 min_caml_atan_flag_negative
	addi	%r8 %r0 $0
	beq	%r0 %r0 min_caml_atan_after_flag
min_caml_atan_flag_negative:
	addi	%r8 %r0 $1
	fabs	%f2 %f2
min_caml_atan_after_flag:
	addi	%r9 %r0 min_caml_atan_c1
	fld	0(%r9) %f6
	fblt	%f2 %f6 min_caml_atan_2
	# |x| < 0.4375
	# kernel_atan(|x|)を返す
	jal	min_caml_kernel_atan
	beq	%r8 %r0 min_caml_atan_positive
	fabs	%f2 %f2
	fneg	%f2 %f2
	jr	%r31
min_caml_atan_positive:
	fabs	%f2 %f2
	jr	%r31
min_caml_atan_2:
	addi	%r9 %r0 min_caml_atan_c2
	fld	0(%r9) %f6
	fblt	%f2 %f6 min_caml_atan_3
	# 0.4375 <= |x| < 2.4375
	# pi/4 + kernel_atan((|x|-1)/(|x|+1)) = kernel_atan(|x|)を返す
	# r8: FLAG, r9: addr
	# f2: x, f4: 0.5, f5: temp(pi/4), f6: |x|+1, f7: |x|-1
	addi	%r9 %r0 min_caml_float_1
	fld	0(%r9) %f5
	fadd	%f6 %f2 %f5
	fneg	%f5 %f5
	fadd	%f7 %f2 %f5
	finv	%f6 %f6
	fmul	%f2 %f6 %f7
	jal	min_caml_kernel_atan
	addi	%r9 %r0 min_caml_quarter_pi
	fld	0(%r9) %f5
	fadd	%f2 %f2 %f5
	beq	%r8 %r0 min_caml_atan_positive
	fabs	%f2 %f2
	fneg	%f2 %f2
	jr	%r31
min_caml_atan_3:
	# |x| >= 2.4375
	# pi/2 - kernel_atan(1/|x|) = kernel_atan(|x|)を返す
	# r8: FLAG, r9: addr
	# f2: x, f4: 0.5, f5: temp(pi/2), f6: temp, f7: temp
	finv	%f2 %f2
	jal	min_caml_kernel_atan
	fneg	%f6 %f2
	addi	%r9 %r0 min_caml_half_pi
	fld	0(%r9) %f2
	fadd	%f2 %f2 %f6
	beq	%r8 %r0 min_caml_atan_positive
	fabs	%f2 %f2
	fneg	%f2 %f2
	jr	%r31
min_caml_kernel_atan:
	# Tayler展開で計算する
	# r8には触らないようにする, r9: addr
	# f2: x or answer, f3: temp, f4: x^2, f5: const
	fmul	%f4 %f2 %f2
	addi	%r9 %r0 min_caml_kernel_atan_c6
	fld	0(%r9) %f5
	fmul	%f3 %f5 %f4
	addi	%r9 %r0 min_caml_kernel_atan_c5
	fld	0(%r9) %f5
	fadd	%f3 %f3 %f5
	fmul	%f3 %f3 %f4
	addi	%r9 %r0 min_caml_kernel_atan_c4
	fld	0(%r9) %f5
	fadd	%f3 %f3 %f5
	fmul	%f3 %f3 %f4
	addi	%r9 %r0 min_caml_kernel_atan_c3
	fld	0(%r9) %f5
	fadd	%f3 %f3 %f5
	fmul	%f3 %f3 %f4
	addi	%r9 %r0 min_caml_kernel_atan_c2
	fld	0(%r9) %f5
	fadd	%f3 %f3 %f5
	fmul	%f3 %f3 %f4
	addi	%r9 %r0 min_caml_kernel_atan_c1
	fld	0(%r9) %f5
	fadd	%f3 %f3 %f5
	fmul	%f3 %f3 %f4
	fmul	%f3 %f3 %f2
	fadd	%f2 %f3 %f2
	jr	%r31
