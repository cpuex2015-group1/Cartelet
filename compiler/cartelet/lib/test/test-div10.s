.data
.text
.globl	min_caml_start
min_caml_start:
	addi	%r2 %r2 $5
	jal	min_caml_div10
	halt
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
min_caml_div10_2:
	# http://stackoverflow.com/a/19076173
	# http://homepage.cs.uiowa.edu/~jones/bcd/divide.html
	# r2: x/10, r8: temp, r9: shift, r10: r, r11: temp
	add	%r10 %r0 %r2
	addi	%r9 %r0 $1
	srl	%r8 %r2 %r9
	add	%r2 %r2 %r8
	srl	%r2 %r2 %r9
	addi	%r9 %r0 $4
	srl	%r8 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r9 %r0 $8
	srl	%r8 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r9 %r0 $16
	srl	%r8 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r9 %r0 $3
	srl	%r2 %r2 %r9
	# ここから+1するかどうかの計算
	addi	%r9 %r0 $2
	sll	%r11 %r2 %r9
	add	%r11 %r11 %r9
	addi	%r9 %r0 $1
	sll	%r11 %r11 %r9
	sub	%r10 %r10 %r11
	addi	%r10 %r10 $-9
	slt	%r10 %r0 %r10
	beq	%r10 %r0 min_caml_div10_r_gt_9
	addi	%r2 %r2 $1
min_caml_div10_r_gt_9:
	jr	%r31
	
temp:
	# r2&r8: x/10 & x(unsigned), r9: shift, r10: r, r11: temp
	add	%r10 %r0 %r2
	addi	%r9 %r0 $1
	srl	%r8 %r2 %r9
	add	%r8 %r8 %r2
	srl	%r8 %r8 %r9
	addi	%r9 %r0 $4
	srl	%r2 %r8 %r9
	add	%r2 %r2 %r8
	addi	%r9 %r0 $8
	srl	%r8 %r2 %r9
	add	%r8 %r8 %r2
	addi	%r9 %r0 $16
	srl	%r2 %r2 %r9
	add	%r2 %r2 %r8
	addi	%r9 %r0 $3
	srl	%r2 %r2 %r9
