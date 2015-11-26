addi r30 r0 1
addi r1 r0 10
addi r31 r0 36
fib: addi r30 r30 1
st r30 r31 0
addi r30 r30 1
st r30 r2 0
addi r30 r30 1
st r30 r3 0
addi r2 r0 1
beq r1 r2 return_one
beq r1 r0 return_one
subi r1 r1 1
addi r2 r1 0
addi r31 r0 16
beq r0 r0 fib
addi r3 r1 0
subi r1 r2 1
addi r31 r0 20
beq r0 r0 fib
add r1 r1 r3
ld r30 r3 0
subi r30 r30 1
ld r30 r2 0
subi r30 r30 1
ld r30 r31 0
subi r30 r30 1
jr r31
return_one: addi r1 r0 1
ld r30 r3 0
subi r30 r30 1
ld r30 r2 0
subi r30 r30 1
ld r30 r31 0
subi r30 r30 1
jr r31
send r1
halt
