.data
deadbeef:
.long 0xdeadbeef
cafecafe:
.long 0xcafecafe
.text
.globl main
main:
addi %r5 %r0 deadbeef
ld (0)%r5 %r1
addi %r2 %r0 $8
send %r1
srl %r1 %r1 %r2
send %r1
srl %r1 %r1 %r2
send %r1
srl %r1 %r1 %r2
send %r1
halt
