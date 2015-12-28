#include<stdint.h>

uint32_t LZC(uint32_t x)
{
	if((x>>31)==1)return 0;
	else if((x>>30)==1)return 1;
	else if((x>>29)==1)return 2;
	else if((x>>28)==1)return 3;
	else if((x>>27)==1)return 4;
	else if((x>>26)==1)return 5;
	else if((x>>25)==1)return 6;
	else if((x>>24)==1)return 7;
	else if((x>>23)==1)return 8;
	else if((x>>22)==1)return 9;
	else if((x>>21)==1)return 10;
	else if((x>>20)==1)return 11;
	else if((x>>19)==1)return 12;
	else if((x>>18)==1)return 13;
	else if((x>>17)==1)return 14;
	else if((x>>16)==1)return 15;
	else if((x>>15)==1)return 16;
	else if((x>>14)==1)return 17;
	else if((x>>13)==1)return 18;
	else if((x>>12)==1)return 19;
	else if((x>>11)==1)return 20;
	else if((x>>10)==1)return 21;
	else if((x>>9)==1)return 22;
	else if((x>>8)==1)return 23;
	else if((x>>7)==1)return 24;
	else if((x>>6)==1)return 25;
	else if((x>>5)==1)return 26;
	else if((x>>4)==1)return 27;
	else if((x>>3)==1)return 28;
	else if((x>>2)==1)return 29;
	else if((x>>1)==1)return 30;
	else if((x>>0)==1)return 31;
	else return 32;
}

uint32_t fpu_itof(int32_t x){
	uint32_t sign,count,tmp_expo,tmp_frac1,tmp_frac2,tmp_frac3,expo,frac;
	sign = ((uint32_t)x)>>31;
	if(sign==1) tmp_frac1 = ~((uint32_t)x) + 1;
	else tmp_frac1 = (uint32_t)x;
	count = LZC(tmp_frac1);
	if(count==32) tmp_expo = 0;
	else tmp_expo = 0x9E - count;
	tmp_frac2 = tmp_frac1<<(count+1);
	if(((tmp_frac2<<23)>>31)==0) tmp_frac3 = tmp_frac2>>9;
	else tmp_frac3 = (tmp_frac2>>9) + 1;
	if((tmp_frac3>>23)==0){
		expo = tmp_expo;
		frac = (tmp_frac3<<9)>>9;
	}
	else{
		expo = tmp_expo + 1;
		frac = 0;
	}
	return ((sign<<31) | (expo<<23) | frac);
}

