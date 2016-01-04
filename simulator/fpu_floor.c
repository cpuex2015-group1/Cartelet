#include<stdint.h>

uint32_t TZC(uint32_t x)
{
	if     ((x&0x1)==0x1)return 0;
	else if((x&0x2)==0x2)return 1;
	else if((x&0x4)==0x4)return 2;
	else if((x&0x8)==0x8)return 3;
	else if((x&0x10)==0x10)return 4;
	else if((x&0x20)==0x20)return 5;
	else if((x&0x40)==0x40)return 6;
	else if((x&0x80)==0x80)return 7;
	else if((x&0x100)==0x100)return 8;
	else if((x&0x200)==0x200)return 9;
	else if((x&0x400)==0x400)return 10;
	else if((x&0x800)==0x800)return 11;
	else if((x&0x1000)==0x1000)return 12;
	else if((x&0x2000)==0x2000)return 13;
	else if((x&0x4000)==0x4000)return 14;
	else if((x&0x8000)==0x8000)return 15;
	else if((x&0x10000)==0x10000)return 16;
	else if((x&0x20000)==0x20000)return 17;
	else if((x&0x40000)==0x40000)return 18;
	else if((x&0x80000)==0x80000)return 19;
	else if((x&0x100000)==0x100000)return 20;
	else if((x&0x200000)==0x200000)return 21;
	else if((x&0x400000)==0x400000)return 22;
	else return 23;
}

uint32_t fpu_floor(uint32_t x){
	uint32_t sign,input_expo,input_frac,input_expofrac,tmp,count,flag,tmp_result,plus_result,minus_result,result;
	sign = x>>31;
	input_expo = (x<<1)>>24;
	input_frac = (x<<9)>>9;
	input_expofrac = (x<<1)>>1;

	tmp = 149 - input_expo;
	count = TZC(input_frac);

	if(input_expo==0) flag = 0;
	else if(input_expo < 127){
		if(sign==0) flag = 2;
		else flag = 3;
	}
	else if(input_expo > 149) flag = 0;
	else if(count > tmp) flag = 0;
	else flag = 1;

	if(flag==2) tmp_result = 0;
	else if(flag==3) tmp_result = 0xBF800000;
	else tmp_result = x;


	plus_result = (input_expo<<23) | ((input_frac>>(tmp+1))<<(tmp+1));
	minus_result = (1<<31) | (((input_expofrac>>(tmp+1))+1)<<(tmp+1));

	if(flag==1){
		if(sign==0)result = plus_result;
		else result = minus_result;
	}
	else result = tmp_result;

	return result;
}

