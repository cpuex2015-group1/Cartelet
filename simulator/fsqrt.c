#include<stdlib.h>
#include<stdint.h>

uint32_t fsqrt(uint32_t x, uint32_t table1, uint32_t table2){

  uint32_t expo1,expo2,frac1,frac2,A1,output;
  uint32_t nan = 0x7FC00000;

  expo1 = (x & 0x7F800000)>>23;
  frac1 = x & 0x7FFFFF;

  if((x>>31)==1) return nan;
  else if(expo1==255) return x;
  else if(expo1==0) return 0;

  if((expo1 & 1)==1) expo2 = (expo1>>1)+64;
  else expo2 = (expo1>>1)+63; 
  A1 = frac1 & 0x3FFF;

  if((expo1 & 1)==1) frac2 = table1 + (((table2+0x2000)*A1)>>15);
  else frac2 = table1 + (((table2+0x2000)*(A1<<1))>>15);

  output = (expo2<<23) | frac2;

  return output;
}

