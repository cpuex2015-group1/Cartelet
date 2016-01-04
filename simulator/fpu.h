#ifndef FPU_H
#define FPU_H

uint32_t fadd(uint32_t,uint32_t);
uint32_t finv(uint32_t,uint32_t,uint32_t);
uint32_t fsqrt(uint32_t,uint32_t,uint32_t);
uint32_t fmul(uint32_t,uint32_t);
int32_t fpu_ftoi(uint32_t);
uint32_t fpu_itof(int32_t);
uint32_t fpu_floor(uint32_t);

#endif
