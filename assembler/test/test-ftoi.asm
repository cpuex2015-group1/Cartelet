.data
min_caml_2pi:
    .long    0x40c90fdb
min_caml_pi:
    .long    0x40490fdb
.text
.globl main
main:
addiu %r1 %r0 min_caml_pi
flw %f2 (0)%r1
ftoi %r8 %f2
send %r8
slli %r8 %r8 $-8
send %r8
slli %r8 %r8 $-8
send %r8
slli %r8 %r8 $-8
send %r8
halt
