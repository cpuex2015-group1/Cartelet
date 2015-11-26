addi r1 r0 0xffff
addi r2 r0 16
sll r1 r1 r2
addi r1 r1 0xffff
addi r3 r0 1
st r3 r1
fld r3 f1
fneg f2 f1
addi r5 r0 12
fseq f2 f3
bclf pohe
addi r5 r0 1000
pohe:
send r5
halt
