.data
.long 0x3f800000
.text
.globl main
main:
addi %r1 %r0 $0
addi %r10 %r0 $100
addi %r8 %r0 $8
fld (0)%r1 %f1
finv %f2 %f1
fst (0)%r10 %f2
ld (0)%r10 %r2
send8 %r2
srl %r2 %r2 %r8
send8 %r2
srl %r2 %r2 %r8
send8 %r2
srl %r2 %r2 %r8
send8 %r2
halt
