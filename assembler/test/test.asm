.data
.long 0x3f800000
.text
.globl main
main:
addi %r4 %r0 $128
loop:
addi %r2 %r0 $1
addi %r3 %r0 $33
fld (-1)%r2 %f0
fadd %f0 %f0 %f0
fst (-1)%r3 %f0
ld (-1)%r3 %r5
addi %r9 %r0 $8
send8 %r5
srl %r5 %r5 %r9
send8 %r5
srl %r5 %r5 %r9
send8 %r5
srl %r5 %r5 %r9
send8 %r5
addi %r4 %r4 $-1
bneq %r4 %r0 loop
halt
