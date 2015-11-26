addi r1 r0 0xcafe
addi r2 r0 4
recv8 r1
sll r1 r1 r2
recv8 r1
send r1
halt
