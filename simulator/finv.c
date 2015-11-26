#include<stdlib.h>
#include<stdint.h>

uint32_t finv(uint32_t x, uint32_t table1, uint32_t table2){

  uint32_t sign,expo1,expo2,frac1,frac2,A1,output;

  sign = x & 0x80000000;
  expo1 = (x & 0x7F800000)>>23;
  frac1 = x & 0x7FFFFF;

  if((expo1==255) && (frac1>0)) return x;
  else if(expo1==0) return (sign | (0xFF<<23));
  else if((expo1>253) || ((expo1==253)&&(frac1>0))) return sign;
  else if(expo1==253) return (sign | 0x800000);

  expo2 = 253 - expo1;
  A1 = frac1 & 0x1FFF;

  frac2 = table1 - (((table2*A1) & 0x3FFF000)>>12);

  output = sign | (expo2<<23) | frac2;

  return output;
}

