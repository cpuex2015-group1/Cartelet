.data
.text
.globl main
main:
addi %r2 %r0 $0
addi %r1 %r0 hoge
jr %r1
addi %r2 %r0 $100
hoge:
addi %r2 %r2 $10
send %r2
halt
