#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

int main(const int argc, const char* argv[]) {
  FILE *in_fp, *out_fp;
  uint8_t temp;
  union u {
    uint32_t ui;
    float f;
    int32_t i;
  } data;
  char buf[10000];

  in_fp = fopen("test-int-float.out.bin", "rb");
  out_fp = fopen("test-int-float.out", "w");

  while(1) {
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui = temp;
    data.ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui += temp;
    data.ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui += temp;
    data.ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui += temp;
    sprintf(buf, "\t%f\t", data.f);
    fwrite(buf, strlen(buf), 1, out_fp);

    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui = temp;
    data.ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui += temp;
    data.ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui += temp;
    data.ui <<= 8;
    if (fread(&temp, 1, 1, in_fp) != 1) break;
    data.ui += temp;
    sprintf(buf, "%d\n", data.i);
    fwrite(buf, strlen(buf), 1, out_fp);
  }

  fclose(out_fp);
  fclose(in_fp);
  return 0;
}
