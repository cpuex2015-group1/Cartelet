.data
.text
.globl main
main:
addi %r1 %r0 $1000
sw (2)%r3 %r1
lw %r2 (2)%r3
send %r2
halt
