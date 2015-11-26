addi r1 r0 0
addi r2 r0 32767
write-loop: st r1 r1
addi r1 r1 1
bneq r1 r2 write-loop
addi r1 r0 0
read-loop: ld r1 r3
add r4 r4 r3
addi r1 r1 1
bneq r1 r2 read-loop
send r4
halt
