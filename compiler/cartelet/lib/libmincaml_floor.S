# ffloor
min_caml_floor:
	# float_of_int( int_of_float( x ) )をする
	# |x| >= 8388608のとき元々整数
	# |x| < 8388608のときfloat_of_int(int_of_float(x))を計算して、round evenによって生まれる調整
	# f0: x
	addi	%r9 %r0 min_caml_float_int_c1
	fld	%f3 0(%r9)
	fslt	%f3 %f0
	bclf	min_caml_floor_exit
	addi	%r9 %r0 min_caml_float_int_c2
	fld	%f2 0(%r9)
	fslt	%f0 %f2
	bclf	min_caml_floor_exit
min_caml_floor_small:
	# float_of_int(int_of_float(x))をする
	# r8: FLAG
	# f0: result, f1: x, f2: 8388608.0, f3: -8388608.0, f4: 0.0
	fmov	%f1 %f0
	addi	%r9 %r0 min_caml_float_0
	fld	%f4 0(%r9)
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
	fld	%f2 0(%r9)
	fslt	%f1 %f0
	bclf	min_caml_floor_exit
	fadd	%f3 %f0 %f2
	fslt	%f3 %f1
	bclf	min_caml_floor_exit
	fmov	%f0 %f3
min_caml_floor_exit:
	jr	%r31
