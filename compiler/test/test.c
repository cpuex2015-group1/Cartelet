#include <stdio.h>
#include <stdlib.h>

int main() {
  FILE *fp = fopen("tron.sld", "r");
  double f, sum = 0.0;
  while(~fscanf(fp, "%lf", &f)) {
    sum += f;
  }
  printf("%lf\n", sum);
  return 0;
}
