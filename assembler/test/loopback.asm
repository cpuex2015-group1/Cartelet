.data
.text
.globl main
main:
loop:
recv %r1
send %r1
bneq %r1 %r0 loop
halt
