.data
deadbeef:
.long 0xdeadbeef
cafecafe:
.long 0xcafecafe
.text
.globl main
main:
addi %r5 %r0 deadbeef
lw %r1 (0)%r5
send %r1
slli %r1 %r1 $-8
send %r1
slli %r1 %r1 $-8
send %r1
slli %r1 %r1 $-8
send %r1
halt
