.data
.text
.globl min_caml_start
min_caml_start:
    addi %r2 %r0 $0
    addi %r3 %r0 $8
    addiu32 %r5 %r0 $0xdeadbeef
    addi %r4 %r0 $4
send-loop:
    send8 %r5
    srl  %r5 %r5 %r3
    addi %r4 %r4 $-1
    bneq %r4 %r0 send-loop
    halt
