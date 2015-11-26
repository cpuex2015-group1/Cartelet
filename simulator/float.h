#pragma once
#include <stdio.h>
#include <stdint.h>

#define b(binary) strtol(#binary, NULL, 2);
#define INF b(01111111100000000000000000000000)

typedef union f32_uint {
	struct {
		uint32_t frac: 23;
		uint32_t expo: 8;
		uint32_t sign: 1;
	};
	struct
	{
		uint32_t lo: 12;
		uint32_t hi: 11;
		uint32_t none2: 9;
	};
	struct
	{
		uint32_t mlo: 11;
		uint32_t mhi: 12;
		uint32_t none1: 9;
	};
	struct
	{
		uint32_t p31: 1;
		uint32_t p30: 1;
		uint32_t p29: 1;
		uint32_t p28: 1;
		uint32_t p27: 1;
		uint32_t p26: 1;
		uint32_t p25: 1;
		uint32_t p24: 1;
		uint32_t p23: 1;
		uint32_t p22: 1;
		uint32_t p21: 1;
		uint32_t p20: 1;
		uint32_t p19: 1;
		uint32_t p18: 1;
		uint32_t p17: 1;
		uint32_t p16: 1;
		uint32_t p15: 1;
		uint32_t p14: 1;
		uint32_t p13: 1;
		uint32_t p12: 1;
		uint32_t p11: 1;
		uint32_t p10: 1;
		uint32_t p09: 1;
		uint32_t p08: 1;
		uint32_t p07: 1;
		uint32_t p06: 1;
		uint32_t p05: 1;
		uint32_t p04: 1;
		uint32_t p03: 1;
		uint32_t p02: 1;
		uint32_t p01: 1;
		uint32_t p00: 1;
	};
	struct
	{
		uint32_t q00: 1;
		uint32_t q01: 1;
		uint32_t q02: 1;
		uint32_t q03: 1;
		uint32_t q04: 1;
		uint32_t q05: 1;
		uint32_t q06: 1;
		uint32_t q07: 1;
		uint32_t q08: 1;
		uint32_t q09: 1;
		uint32_t q10: 1;
		uint32_t q11: 1;
		uint32_t q12: 1;
		uint32_t q13: 1;
		uint32_t q14: 1;
		uint32_t q15: 1;
		uint32_t q16: 1;
		uint32_t q17: 1;
		uint32_t q18: 1;
		uint32_t q19: 1;
		uint32_t q20: 1;
		uint32_t q21: 1;
		uint32_t q22: 1;
		uint32_t q23: 1;
		uint32_t q24: 1;
		uint32_t q25: 1;
		uint32_t q26: 1;
		uint32_t q27: 1;
		uint32_t q28: 1;
		uint32_t q29: 1;
		uint32_t q30: 1;
		uint32_t q31: 1;
	};
	float fl;
	uint32_t ui;
} f32_uint;

char *dec2bin(uint64_t dec, int deg, char *binstr);
void print4(char *str);
void print_float(uint32_t a);
uint32_t slice(uint32_t target, int a, int b);
