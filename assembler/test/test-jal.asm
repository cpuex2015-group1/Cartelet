.data
.text
.globl main
main:
addi %r1 %r0 $10
jal hoge
addi %r1 %r1 $10
hoge:
send %r1
halt
