.data
.text
.globl main
main:
addi %r1 %r0 $0xffff
send %r1
halt
