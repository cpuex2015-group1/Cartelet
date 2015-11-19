# div10 (unsigned)
min_caml_div10:
	# http://stackoverflow.com/a/19076173
	# http://homepage.cs.uiowa.edu/~jones/bcd/divide.html
	# r2: x/10, r8: x(unsigned), r9: 1, r10: 3
	add	%r8 %r0 %r2
	addi	%r9 %r0 $2
	srl	%r2 %r8 %r9
	add	%r2 %r2 %r8
	addi	%r9 %r0 $1
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r10 %r0 $3
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r10
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r10 %r0 $4
	srl	%r2 %r2 %r10
	jr	%r31
