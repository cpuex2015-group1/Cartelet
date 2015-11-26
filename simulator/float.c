#include <stdio.h>
#include "float.h"

extern char *dec2bin(uint64_t dec, int deg, char *binstr)
{
	binstr[deg] = '\0';
	for (deg--; deg>=0; deg--) {
		binstr[deg] = (dec % 2) ? '1' : '0';
		dec = dec / 2;
	};
	return binstr;
}

extern void print4(char *str)
{
	int i=4;
	while(1)
	{
		if (*str == '\0') return;
		if (!i) putchar(',');
		i = (i+1)%4;
		putchar(*str);
		str++;
	}
}

extern void print_float(uint32_t a)
{
	f32_uint b;
	int i;
	b.ui = a;
	for (i=0; i<32; i++)
	{
		printf("%u", (a >> (32-i-1)) & 1);
		if (i==0) printf (", ");
		if (i==4) printf (" ");
		if (i==8) printf (", ");
		if (i>8 && i%4==3) printf (" ");
	}
}

extern uint32_t slice(uint32_t target, int a, int b)
{
	return (target & ((1<<(a+1))-1))>>b;
}
