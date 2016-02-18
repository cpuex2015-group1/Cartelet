#include <stdint.h>

uint32_t fmul(uint32_t input1, uint32_t input2)
{
	uint32_t sign1,sign2,sign,expo1,expo2,flag,tmp_expo1,tmp_expo2,expo,frac1,frac2,frac,result;
	uint64_t tmp_frac;

	sign1 = input1>>31;
	sign2 = input2>>31;
	expo1 = (input1<<1)>>24;
	expo2 = (input2<<1)>>24;
	frac1 = (input1<<9)>>9;
	frac2 = (input2<<9)>>9;

	sign = sign1^sign2;
	tmp_expo1 = expo1 + expo2;
	tmp_frac = (uint64_t)(0x800000 | frac1) * (uint64_t)(0x800000 | frac2);

	if((expo1==0)||(expo2==0)) flag = 1;
	else flag = 0;

	if((tmp_frac>>47)==1){
		tmp_expo2 = tmp_expo1 + 1;
		frac = (0x7FFFFF) & ((uint32_t)(tmp_frac>>24));
	}
	else{
		tmp_expo2 = tmp_expo1;
		frac = (0x7FFFFF) & ((uint32_t)(tmp_frac>>23));
	}

	if((flag==1)||(((tmp_expo2>>8)|(tmp_expo2>>7))==0)) result = (sign<<31);	
	else{
		expo = tmp_expo2 - 127;
		expo = 0xFF & expo;
		result = (sign<<31) | (expo<<23) | frac;
	}

	return result;
}

