addiu r1 r0 0x8f0d
addiu r16 r0 16
sll r1 r1 r16
addiu r1 r1 0xfbb9
addiu r2 r0 0x0b8c
sll r2 r2 r16
addiu r2 r2 0x10f1
addiu r3 r0 9
addiu r5 r0 10
st r3 r1 0
addiu r3 r3 1
st r3 r2 0
fld r3 f2 0
subi r3 r3 1
fld r3 f1 0
fadd f5 f1 f2 # should be 0x8f0ce397 8f0dfbb9 0b8c10f1 8f0ce397
fst r5 f5 0
ld r5 r9 0
send r9
halt
