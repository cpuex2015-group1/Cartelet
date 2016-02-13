.data
.long 0x3F800000
.long 0x40000000
.text
.globl main
main:
addiu %r1 %r0 $0
addiu %r2 %r0 $1
addiu %r3 %r0 $0
addiu %r4 %r0 $5
addiu %r6 %r0 $10
flw %f1 (0)%r1
flw %f10 (0)%r2
finv %f11 %f10
fsqrt %f2 %f11
flw %f10 (0)%r2
fmul %f11 %f10 %f10
finv %f3 %f11
flw %f4 (0)%r1
loop:
fadd %f10 %f1 %f2
flw %f11 (0)%r2
finv %f12 %f11
fmul %f5 %f10 %f12
fmul %f10 %f1 %f2
fsqrt %f6 %f10
fneg %f10 %f5
fadd %f11 %f10 %f1
fmul %f10 %f11 %f11
fmul %f11 %f10 %f4
fneg %f10 %f11
fadd %f7 %f3 %f10
flw %f10 (0)%r2
fmul %f8 %f4 %f10
addiu %r3 %r3 $1
fmov %f1 %f5
fmov %f2 %f6
fmov %f3 %f7
fmov %f4 %f8
bneq %r3 %r4 loop
fadd %f10 %f5 %f6
fmul %f11 %f10 %f10
flw %f12 (0)%r2
fmul %f13 %f12 %f12
fmul %f14 %f13 %f7
finv %f15 %f14
fmul %f1 %f15 %f11
fsw (0)%r6 %f1
lw %r7 (0)%r6
send %r7
slli %r7 %r7 $-8
send %r7
slli %r7 %r7 $-8
send %r7
slli %r7 %r7 $-8
send %r7
halt
