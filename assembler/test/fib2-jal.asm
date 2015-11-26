.data
.text
.globl		main
main:
addi    %r5     %r0     $1
addi    %r1     %r0     $1
addi    %r4     %r0     $34
loop:
addi	%r30	%r0		$1
addi	%r31	%r0		end
fib:
addi	%r30	%r30	$1
st		(0)%r30	%r31
addi	%r30	%r30	$1
st		(0)%r30	%r2
addi	%r30	%r30	$1
st		(0)%r30	%r3
addi	%r2		%r0		$1
beq		%r1		%r2		return_one
beq		%r1		%r0		return_one
subi	%r1		%r1		$1
addi	%r2		%r1		$0
jal		fib
addi	%r3		%r1		$0
subi	%r1		%r2		$1
jal		fib
add		%r1		%r1		%r3
ld		(0)%r30	%r3
subi	%r30	%r30	$1
ld		(0)%r30	%r2
subi	%r30	%r30	$1
ld		(0)%r30	%r31
subi	%r30	%r30	$1
jr		%r31
return_one:
addi	%r1		%r0		$1
ld		(0)%r30	%r3
subi	%r30	%r30	$1
ld		(0)%r30	%r2
subi	%r30	%r30	$1
ld		(0)%r30	%r31
subi	%r30	%r30	$1
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
addi    %r5 %r5 $1
addi    %r1 %r5 $0
bneq    %r5 %r4 loop
halt
