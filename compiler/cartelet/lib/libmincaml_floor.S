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
