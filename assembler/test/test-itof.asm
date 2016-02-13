.data
min_caml_2pi:
    .long    0x40c90fdb
min_caml_pi:
    .long    0x40490fdb
.text
.globl main
main:
addiu %r1 %r0 min_caml_pi
addi %r2 %r0 $100
itof %f2 %r2
addi %r4 %r0 $10
fsw (0)%r4 %f2
lw %r8 (0)%r4
send %r8
slli %r8 %r8 $-8
send %r8
slli %r8 %r8 $-8
send %r8
slli %r8 %r8 $-8
send %r8
halt
