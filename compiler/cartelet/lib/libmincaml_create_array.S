# create_array
min_caml_create_array:
	# r2: array size -> array addr
	# r3: initial value
	add	%r8 %r0 %r2
	add	%r2 %r0 %r28
min_caml_create_array_loop:
	beq	%r8 %r0 min_caml_create_array_exit
	sw	0(%r28) %r3
	addi	%r8 %r8 $-1
	addi	%r28 %r28 $1
	beq	%r0 %r0 min_caml_create_array_loop
min_caml_create_array_exit:
	jr	%r31
# create_float_array
min_caml_create_float_array:
	# r2: array size -> array addr
	# r9: addr
	# f0: initial value
	add	%r8 %r0 %r2
	add	%r2 %r0 %r28
min_caml_create_float_array_loop:
	beq	%r8 %r0 min_caml_create_float_array_exit
	fsw	0(%r28) %f0
	addi	%r8 %r8 $-1
	addi	%r28 %r28 $1
	beq	%r0 %r0 min_caml_create_float_array_loop
min_caml_create_float_array_exit:
	jr	%r31
