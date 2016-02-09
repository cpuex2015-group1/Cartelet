.data
.text
.globl main
main:
addi %r4 %r0 $10
addi %r1 %r0 $0
addi %r2 %r0 $1
loop:
add %r3 %r2 %r0
add %r2 %r1 %r2
add %r1 %r3 %r0
addi %r4 %r4 $-1
bneq %r4 %r0 loop
send %r2
halt
