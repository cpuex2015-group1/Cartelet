error: error.c test-atan.s
	gcc -O0 -Wall -o error error.c -lm
	../../../../assembler/asm -format o test-atan.s > test-atan.o
	../../../../simulator/rin -o test-atan.out.bin test-atan.o -r
	./error

clean:
	rm -f error test-cos-sin.out.bin test-atan.out.bin
