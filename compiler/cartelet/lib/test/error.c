#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

union u {
  uint32_t ui;
  float f;
  int32_t i;
};

float reduction_2pi(float a) {
  float p = 2.0 * (float)M_PI;
  while (a >= p) p = p * 2.0;
  while (a >= 2.0 * (float)M_PI) {
    if (a >= p) a -= p;
    p /= 2.0;
  }
  return a;
}

float kernel_sin(float a, int flag) {
  float a2 = a*a;
  float answer;
  union nyan {
    float f;
    uint32_t ui;
  } c3, c2, c1;
  c3.ui = 0xb94d64b6;
  c2.ui = 0x3c088666;
  c1.ui = 0xbe2aaaac;
  answer = c3.f * a2;
  answer += c2.f;
  answer *= a2;
  answer += c1.f;
  answer *= a2;
  answer *= a;
  answer += a;
  if (flag == 0) {
    return fabsf(answer);
  } else {
    return -fabsf(answer);
  }
}

float kernel_cos(float a, int flag) {
  float a2 = a*a;
  float answer;
  union nyan {
    float f;
    uint32_t ui;
  } c3, c2, c1;
  c3.ui = 0xbab38106;
  c2.ui = 0x3d2aa789;
  c1.ui = 0xbf000000;
  answer = c3.f * a2;
  answer += c2.f;
  answer *= a2;
  answer += c1.f;
  answer *= a2;
  answer += 1.0f;
  if (flag == 0) {
    return fabsf(answer);
  } else {
    return -fabsf(answer);
  }
}

float mysin(float a) {
  int flag = (a<0.0)?1:0;
  a = fabsf(a);
  a = reduction_2pi(a);
  if (a>=(float)M_PI) {
    a -= (float)M_PI;
    flag ^= 1;
  }
  if (a>=(float)M_PI/2.0f) a = (float)M_PI - a;
  if (a<=(float)M_PI/4.0f) {
    return kernel_sin(a, flag);
  } else {
    a = (float)M_PI/2.0f - a;
    return kernel_cos(a, flag);
  }
}

int main(const int argc, const char* argv[]) {
  FILE *in_fp;
  const int num = 10000;//テスト回数はnum以下にする
  uint8_t temp;
  union u answer;
  union u input[num];
  union u output[num];
  int i;

  in_fp = fopen("test-cos-sin.out.bin", "rb");

  for(i=0;i<num;i++){
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    input[i].ui = temp;
    input[i].ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    input[i].ui += temp;
    input[i].ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    input[i].ui += temp;
    input[i].ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    input[i].ui += temp;

    if (fread(&temp, 1, 1, in_fp) != 1) break;
    output[i].ui = temp;
    output[i].ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    output[i].ui += temp;
    output[i].ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    output[i].ui += temp;
    output[i].ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    output[i].ui += temp;
  }

  int loopnum = i; //loopnum=テスト回数
  uint32_t tmpdiff;
  int diff[100];
  int error;
  for(i=0;i<100;i++) diff[i]=0;

  printf("input     output        answer        diff(ulp)\n");

  for(i=0;i<loopnum;i++){
    answer.f = sinf(input[i].f);

    if((output[i].ui & 0x80000000) == (answer.ui & 0x80000000)){ //outputとanswerの符号が同じ場合
      if(output[i].ui >= answer.ui) tmpdiff = output[i].ui - answer.ui;
      else tmpdiff = answer.ui - output[i].ui;
    }
    else{ //outputとanswerの符号が違う場合
      tmpdiff = (output[i].ui & 0x7fffffff) + (answer.ui & 0x7fffffff);
    }

    printf("%f ",input[i].f);
    printf("%.10f ",output[i].f);
    printf("%.10f ",answer.f);
    printf("%d\n",tmpdiff); 

    if(tmpdiff <= 100) diff[tmpdiff]++;
    else error++;
  }

  for(i=0;i<100;i++) printf("diff %d : %d\n",i,diff[i]);
  printf("error : %d\n",error); //100ulp以上のdiffの数
  printf("total : %d\n",loopnum);

  fclose(in_fp);
  return 0;
}
