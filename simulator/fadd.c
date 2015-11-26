#include <stdint.h>

/*
入力の非正規化数は0として扱う。
演算の結果、非正規化数となった場合+0を返す。
1つ以上のNaNが入力としてきた場合、NaNを返す。
丸め処理はnearest even。
*/

uint32_t shift_r(uint32_t s, int k)
{
//tの27ビット目はflag
	uint32_t t;
	switch (k) {
		case 0: t = s;
				break;
		case 1: t = 0x4000000 + (s>>1);
				if((s & 0x1)==0) t = t - 0x4000000;
				break;
		case 2: t = 0x4000000 + (s>>2);
				if((s & 0x3)==0) t = t - 0x4000000;
				break;
		case 3: t = 0x4000000 + (s>>3);
				if((s & 0x7)==0) t = t - 0x4000000;
				break;
		case 4: t = 0x4000000 + (s>>4);
				if((s & 0xF)==0) t = t - 0x4000000;
				break;
		case 5: t = 0x4000000 + (s>>5);
				if((s & 0x1F)==0) t = t - 0x4000000;
				break;
		case 6: t = 0x4000000 + (s>>6);
				if((s & 0x3F)==0) t = t - 0x4000000;
				break;
		case 7: t = 0x4000000 + (s>>7);
				if((s & 0x7F)==0) t = t - 0x4000000;
				break;
		case 8: t = 0x4000000 + (s>>8);
				if((s & 0xFF)==0) t = t - 0x4000000;
				break;
		case 9: t = 0x4000000 + (s>>9);
				if((s & 0x1FF)==0) t = t - 0x4000000;
				break;
		case 10: t = 0x4000000 + (s>>10);
				if((s & 0x3FF)==0) t = t - 0x4000000;
				break;
		case 11: t = 0x4000000 + (s>>11);
				if((s & 0x7FF)==0) t = t - 0x4000000;
				break;
		case 12: t = 0x4000000 + (s>>12);
				if((s & 0xFFF)==0) t = t - 0x4000000;
				break;
		case 13: t = 0x4000000 + (s>>13);
				if((s & 0x1FFF)==0) t = t - 0x4000000;
				break;
		case 14: t = 0x4000000 + (s>>14);
				if((s & 0x3FFF)==0) t = t - 0x4000000;
				break;
		case 15: t = 0x4000000 + (s>>15);
				if((s & 0x7FFF)==0) t = t - 0x4000000;
				break;
		case 16: t = 0x4000000 + (s>>16);
				if((s & 0xFFFF)==0) t = t - 0x4000000;
				break;
		case 17: t = 0x4000000 + (s>>17);
				if((s & 0x1FFFF)==0) t = t - 0x4000000;
				break;
		case 18: t = 0x4000000 + (s>>18);
				if((s & 0x3FFFF)==0) t = t - 0x4000000;
				break;
		case 19: t = 0x4000000 + (s>>19);
				if((s & 0x7FFFF)==0) t = t - 0x4000000;
				break;
		case 20: t = 0x4000000 + (s>>20);
				if((s & 0xFFFFF)==0) t = t - 0x4000000;
				break;
		case 21: t = 0x4000000 + (s>>21);
				if((s & 0x1FFFFF)==0) t = t - 0x4000000;
				break;
		case 22: t = 0x4000000 + (s>>22);
				if((s & 0x3FFFFF)==0) t = t - 0x4000000;
				break;
		case 23: t = 0x4000000 + (s>>23);
				if((s & 0x7FFFFF)==0) t = t - 0x4000000;
				break;
		case 24: t = 0x4000000 + (s>>24);
				if((s & 0xFFFFFF)==0) t = t - 0x4000000;
				break;
		case 25: t = 0x4000000 + (s>>25);
				if((s & 0x1FFFFFF)==0) t = t - 0x4000000;
				break;
	}
	return t;
}

uint32_t shift_l(uint32_t s, int k)
{
	return s<<k;
}

uint32_t lzc(uint32_t x)
{
    uint32_t y;
    uint32_t n = 25;
    y = x >> 16; if (y != 0){ n = n - 16 ; x = y; }
    y = x >>  8; if (y != 0){ n = n -  8 ; x = y; }
    y = x >>  4; if (y != 0){ n = n -  4 ; x = y; }
    y = x >>  2; if (y != 0){ n = n -  2 ; x = y; }
    y = x >>  1; if (y != 0){ n = n -  1 ; x = y; }
    return n - (x & 1);
}

uint32_t fadd(uint32_t a, uint32_t b)
{
	uint32_t w;
	uint32_t l;
	uint32_t w_sign;
	uint32_t l_sign;
	uint32_t w_expo;
	uint32_t l_expo;
	uint32_t w_frac;
	uint32_t l_frac;
	int shift;
	uint32_t shifted_frac;
	uint32_t tmp_frac1;
	uint32_t tmp_frac2;
	uint32_t expo;
	uint32_t frac;
	uint32_t pluszero = 0;
	uint32_t minuszero = 0x80000000;
	uint32_t plusinf = 0x7F800000;
	uint32_t minusinf = 0xFF800000;
	uint32_t nan = 0x7FC00000;
	int count = 0;
	int flag = 0;

	if((a<<1) >= (b<<1)){
		w = a;
		l = b;
	}
	else{
		w = b;
		l = a;
	}
	//指数が大きいほうがwで小さい方がl(指数が同じ場合仮数で比較するが、それも同じならaがw)

    w_sign = w>>31;
    l_sign = l>>31;
	w_expo = (w & 0x7F800000)>>23;
	l_expo = (l & 0x7F800000)>>23;
	w_frac = w & 0x7FFFFF;
	l_frac = l & 0x7FFFFF;

	if(w_expo==255){
		if(l_expo==255 && w_sign!=l_sign) return nan;
		else return w;
	}

	if(l_expo==0){
		if(w_expo==0){
			if(w_sign==1 && l_sign==1) return minuszero;
			//プラスゼロとマイナスゼロの入力に対してはプラスゼロを返す
			else return pluszero;
		}
		else return w;
	}

	shift = w_expo - l_expo;

	if(shift>25) return w;

	if(w_sign==l_sign){
		tmp_frac1 = (l_frac + 0x800000) << 1;

		shifted_frac = shift_r(tmp_frac1, shift);
		if(shifted_frac > 0x3FFFFFF) flag = 1;
		tmp_frac1 = shifted_frac & 0x3FFFFFF;

		tmp_frac2 = ((w_frac + 0x800000) << 1) + tmp_frac1;
		if((tmp_frac2 & 0x2000000) == 0x2000000){
			if(w_expo==254){
	  			if(w_sign==0) return plusinf;
	  			else return minusinf;
			}
			else{
				frac = (tmp_frac2 >> 2) - 0x800000; 
				if(((tmp_frac2 & 2) == 2) && (((tmp_frac2 & 1) == 1) || ((tmp_frac2 & 4) == 4) || (flag == 1))) frac = frac + 1; 
				expo = w_expo + 1;
			}
		}
		else{
			if(((tmp_frac2 & 1) == 1) && (((tmp_frac2 & 2) == 2) || (flag == 1))) tmp_frac2 = tmp_frac2 + 1;
			if((tmp_frac2 & 0x2000000) == 0x2000000){
				frac = (tmp_frac2 >> 2) - 0x800000; 
				expo = w_expo + 1;
			}
			else{
				frac = (tmp_frac2 >> 1) - 0x800000;
				expo = w_expo;
			}
		}
	}

	else{
		if(shift>1){
			tmp_frac1 = (l_frac + 0x800000) << 2; 

			shifted_frac = shift_r(tmp_frac1, shift);
			if(shifted_frac > 0x3FFFFFF) flag = 1;
			tmp_frac1 = shifted_frac & 0x3FFFFFF;

			tmp_frac2 = ((w_frac + 0x800000) << 2) - tmp_frac1;
			if((tmp_frac2 & 0x2000000) == 0x2000000){
				expo = w_expo;
				frac = (tmp_frac2>>2) - 0x800000;
				if(((tmp_frac2 & 3) == 3) || (((tmp_frac2 & 7) == 6) && (flag == 0))) frac = frac + 1;				
			}
			else{
				frac = tmp_frac2>>1;
				if(((tmp_frac2 & 3) == 3) && (flag == 0)) frac = frac + 1;
				if((frac & 0x1000000) == 0x1000000){
					frac = (frac>>1) - 0x800000;
					expo = w_expo;
				}
				else{
					frac = frac - 0x800000;
					expo = w_expo - 1;
				}
			}
		}
		else{
			
			if(shift==0) tmp_frac1 = (w_frac - l_frac) << 1;
			else tmp_frac1 = (w_frac << 1) - l_frac + 0x800000;
			if(tmp_frac1==0) return 0;

			count = lzc(tmp_frac1);
			tmp_frac1 = shift_l(tmp_frac1, count);  
 
			if(w_expo <= count) return 0;
			expo = w_expo - count;
			if(count == 0 && ((tmp_frac1 & 3) == 3)) frac = (tmp_frac1 >> 1) - 0x7FFFFF;
			else frac = (tmp_frac1>>1) - 0x800000;
		}
	}

	return ((w_sign<<31) | (expo<<23) | frac);

}

