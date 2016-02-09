.data
.text
.globl main
main:
addi %r1 %r0 $0x0001
send %r1
addi %r1 %r1 $0x0002
addi %r1 %r1 $0x0002
addi %r1 %r1 $0x0002
addi %r1 %r1 $0x0002
addi %r1 %r1 $0x0002
send %r1
halt
