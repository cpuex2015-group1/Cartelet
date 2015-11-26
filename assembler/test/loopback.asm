.text
.globl main
main:
loop:
recv8 %r1
send8 %r1
bneq %r1 %r0 loop
halt
