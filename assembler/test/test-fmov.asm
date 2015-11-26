addiu r1 r0 0xffff
addiu r16 r0 16
sll r1 r1 r16
addiu r1 r1 0xffff
addiu r2 r0 0xffff
sll r2 r2 r16
addiu r2 r2 0xffff
addiu r3 r0 9
addiu r4 r0 100
st r3 r1 0
addi r3 r3 1
st r3 r2 0
fld r3 f2 0
subi r3 r3 1
fld r3 f1 0
fmov f4 f1
fst r4 f4 0
ld r4 r9 0
send r9
halt
