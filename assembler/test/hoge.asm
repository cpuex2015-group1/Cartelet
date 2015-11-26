addi r30 r0 1
addi r1 r0 10
addi r31 r0 36
fib: addi r30 r30 1
st r30 r31
addi r30 r30 1
st r30 r2
addi r30 r30 1
st r30 r3
ld r30 r3
subi r30 r30 1
ld r30 r2
subi r30 r30 1
ld r30 r31
subi r30 r30 1
send r31
halt
