.data
.text
.globl		main
main:
addi    %r1     %r0     $10
addi	%r30	%r0		$1
addi	%r31	%r0		end
fib:
addi	%r30	%r30	$1
sw		(0)%r30	%r31
addi	%r30	%r30	$1
sw		(0)%r30	%r2
addi	%r30	%r30	$1
sw		(0)%r30	%r3
addi	%r2		%r0		$1
beq		%r1		%r2		return_one
beq		%r1		%r0		return_one
addi	%r1		%r1		$-1
addi	%r2		%r1		$0
jal		fib
addi	%r3		%r1		$0
addi	%r1		%r2		$-1
jal		fib
add		%r1		%r1		%r3
lw      %r3     (0)%r30
addi	%r30	%r30	$-1
lw		%r2     (0)%r30
addi	%r30	%r30	$-1
lw		%r31    (0)%r30
addi	%r30	%r30	$-1
jr		%r31
return_one:
addi	%r1		%r0		$1
lw      %r3     (0)%r30
addi	%r30	%r30	$-1
lw		%r2     (0)%r30
addi	%r30	%r30	$-1
lw		%r31    (0)%r30
addi	%r30	%r30	$-1
jr		%r31
end:
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
send	%r1
halt
