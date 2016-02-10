.data
.text
.globl main
main:
addiu %r1 %r0 $0x8f0d
slli %r1 %r1 $16
addiu %r1 %r1 $0xfbb9
addiu %r2 %r0 $0x0b8c
slli %r2 %r2 $16
addiu %r2 %r2 $0x10f1
addiu %r3 %r0 $9
addiu %r5 %r0 $10
sw (0)%r3 %r1
addiu %r3 %r3 $1
sw (0)%r3 %r2
flw %f2 (0)%r3
addi %r3 %r3 $-1
flw %f1 (0)%r3
fadd %f5 %f1 %f2 # should be 0x8f0ce397 8f0dfbb9 0b8c10f1 8f0ce397
fsw (0)%r5 %f5
lw %r9 (0)%r5
send %r9
slli %r9 %r9 $-8
send %r9
slli %r9 %r9 $-8
send %r9
slli %r9 %r9 $-8
send %r9
halt
