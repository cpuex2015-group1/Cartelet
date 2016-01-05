error: error.c test-cos-sin.s
	gcc -O0 -Wall -o error error.c -lm
	../../../../assembler/asm -format o test-cos-sin.s > test-cos-sin.o
	../../../../simulator/rin -o test-cos-sin.out.bin test-cos-sin.o -r
	./error

clean:
	rm -f error test-cos-sin.out.bin
