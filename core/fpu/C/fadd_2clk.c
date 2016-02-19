#include <stdint.h>

uint32_t LZC_fadd(uint32_t x)
{
	if((x>>24)==1)return 0;
	else if((x>>23)==1)return 1;
	else if((x>>22)==1)return 2;
	else if((x>>21)==1)return 3;
	else if((x>>20)==1)return 4;
	else if((x>>19)==1)return 5;
	else if((x>>18)==1)return 6;
	else if((x>>17)==1)return 7;
	else if((x>>16)==1)return 8;
	else if((x>>15)==1)return 9;
	else if((x>>14)==1)return 10;
	else if((x>>13)==1)return 11;
	else if((x>>12)==1)return 12;
	else if((x>>11)==1)return 13;
	else if((x>>10)==1)return 14;
	else if((x>>9)==1)return 15;
	else if((x>>8)==1)return 16;
	else if((x>>7)==1)return 17;
	else if((x>>6)==1)return 18;
	else if((x>>5)==1)return 19;
	else if((x>>4)==1)return 20;
	else if((x>>3)==1)return 21;
	else if((x>>2)==1)return 22;
	else if((x>>1)==1)return 23;
	else if((x>>0)==1)return 24;
	else return 25;
}

uint32_t shift_r_fadd(uint32_t s, uint32_t k)
{
	if(k<24)return (s>>k);
	else return 0;
}

uint32_t fadd(uint32_t input1, uint32_t input2)
{
	uint32_t sign1,sign2,expo1,expo2,frac1,frac2,expodiff,tmp_expo,w_sign,w_frac_a,shifted_frac_a,w_frac_b,l_frac_b,shifted_frac_b,tmp_frac_b;
	uint32_t tmp_add_frac,tmp_sub_frac,add_frac,add_expo,sub_frac,sub_expo,result_a,count,expo,frac,result_b;
	int is_sub,way1,way2;

	sign1 = input1>>31;
	sign2 = input2>>31;
	expo1 = (input1<<1)>>24;
	expo2 = (input2<<1)>>24;
	frac1 = (input1<<9)>>9;
	frac2 = (input2<<9)>>9;

	if(expo1>expo2){
		expodiff = expo1 - expo2;
		tmp_expo = expo1;
		w_frac_a = frac1;
		shifted_frac_a = shift_r_fadd((0x800000 | frac2),expodiff);
	}
	else{
		expodiff = expo2 - expo1;
		tmp_expo = expo2;
		w_frac_a = frac2;
		shifted_frac_a = shift_r_fadd((0x800000 | frac1),expodiff);
	}

	if((input1<<1)>(input2<<1)){
		w_sign = sign1;
		w_frac_b = frac1;
		l_frac_b = frac2;
	}
	else{
		w_sign = sign2;
		w_frac_b = frac2;
		l_frac_b = frac1;
	}

	if((expo1 & 1) == (expo2 & 1)) shifted_frac_b = (0x800000 | l_frac_b) << 1;
	else shifted_frac_b = (0x800000 | l_frac_b);

	tmp_frac_b = ((0x800000 |w_frac_b) << 1) - shifted_frac_b;

	is_sub = sign1^sign2;

	if((expo1==0)||(expo2==0)) way1= 1;
	else way1 = 0;

	if(((expodiff>>1)==0)&&(is_sub==1))way2 = 1;
	else way2 = 0;



	tmp_add_frac = (0x800000 | w_frac_a) + shifted_frac_a;
	tmp_sub_frac = (0x800000 | w_frac_a) - shifted_frac_a;

	if((tmp_add_frac>>24)==0){
		add_frac = (tmp_add_frac<<9)>>9;
		add_expo = tmp_expo;
	}
	else{
		add_frac = (tmp_add_frac<<8)>>9;
		add_expo = (tmp_expo + 1) & 0xFF;
	}
	if((tmp_sub_frac>>23)==1){
		sub_frac = (tmp_sub_frac<<9)>>9;
		sub_expo = tmp_expo;
	}
	else{
		sub_frac = (tmp_sub_frac<<10)>>9;
		sub_expo = tmp_expo - 1;
	}

	if(is_sub==0)result_a = (w_sign<<31) | (add_expo<<23) | add_frac;
	else result_a = (w_sign<<31) | (sub_expo<<23) | sub_frac;


	count = LZC_fadd(tmp_frac_b);
	if((count==25)||(count>tmp_expo))expo = 0;
	else expo = tmp_expo - count;

	frac = ((tmp_frac_b<<count)&(0xFFFFFF))>>1;
	result_b = (w_sign<<31) | (expo<<23) | frac;


	if(way1==1) return ((w_sign<<31) | (tmp_expo<<23) | w_frac_a);
	else if(way2==0)return result_a;
	else return result_b;
}

