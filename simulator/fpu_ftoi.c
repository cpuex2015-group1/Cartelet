#include<stdint.h>

uint32_t shift_r(uint32_t x,uint32_t shift){
	if(shift>31) return 0;
	else return x>>shift;
}

int32_t fpu_ftoi(uint32_t x){
	uint32_t sign,shift,tmp_frac1,tmp_frac2,u_int;
	int32_t result;

	sign = x>>31;
	shift = 0x9D - ((x<<1)>>24);
	tmp_frac1 = (0x80000000 | (x<<8));
	tmp_frac2 = shift_r(tmp_frac1,shift);
	if((tmp_frac2 & 1)==1)u_int = (tmp_frac2>>1) + 1;
	else u_int = tmp_frac2>>1;

	if(sign==1) result = (int32_t)((~u_int) + 1);
	else result = (int32_t)u_int;

	return result;
}

