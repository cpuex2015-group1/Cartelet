.data
.text
.globl	main
main:
	jal	sub
	halt
sub:	
	jr	%r31
