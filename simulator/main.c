#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<unistd.h>
#include<stdint.h>
#include<signal.h>
#include"cpu.h"

#define MAXBUF 1024

FILE* fprecv8;
FILE* fpsend8;

int stepflag=0;
int recv8flag=0;
int send8flag=0;
int noprintflag=0;
int binflag=0;
int hexflag=0;
int x86flag=0;
int displayflag=0;
int breakpoint[BRAM_NUM]={};
int gdisp[GPR_NUM]={};
int fdisp[FPR_NUM]={};

int datasize,textsize;

long long int nop_count=0;
long long int add_count=0;
long long int addi_count=0;
long long int addiu_count=0;
long long int sub_count=0;
long long int slli_count=0;
long long int srai_count=0;
long long int beq_count=0;
long long int bneq_count=0;
long long int blt_count=0;
long long int ble_count=0;
long long int jr_count=0;
long long int jal_count=0;
long long int lw_count=0;
long long int sw_count=0;
long long int send_count=0;
long long int recv_count=0;
long long int halt_count=0;

long long int fmov_count=0;
long long int fadd_count=0;
long long int fsub_count=0;
long long int fmul_count=0;
long long int finv_count=0;
long long int fsqrt_count=0;
long long int fneg_count=0;
long long int fabs_count=0;
long long int ftoi_count=0;
long long int itof_count=0;
long long int floor_count=0;
long long int fbeq_count=0;
long long int fbneq_count=0;
long long int fblt_count=0;
long long int fble_count=0;
long long int flw_count=0;
long long int fsw_count=0;

long long int inst_count=0;


int nop_bp=0;
int send8_bp=0;

uint32_t finv_table1[1024];
uint32_t finv_table2[1024];
uint32_t fsqrt_table1[1024];
uint32_t fsqrt_table2[1024];

void printbin(uint32_t i)
{
  int k;

  for (k=31;k>=0;k--) {
    printf("%d",(i>>k)&1);
  }
  printf("\n");
}

void printfloat(uint32_t i)
{
  int k;

  for (k=31;k>=0;k--) {
    printf("%d",(i>>k)&1);
    if (k==31 || k==23) {
      printf(" ");
    }
  }
}

void print_reg()
{
  int i;

  puts("===Register===");

  for (i=0;i<GPR_NUM;i++) {
    if (binflag) {
      printf("GPR %2d : ",i);
      printbin(gpr[i]);
    } else if (hexflag) {
      printf("GPR %2d : %08x\n",i,gpr[i]);
    } else {
      printf("GPR %2d : %d\n",i,gpr[i]);
    }
  }

  for (i=0;i<FPR_NUM;i++) {
    printf("FPR %2d : ",i);
    printfloat(fpr[i].i);
    printf(" , %lf\n",fpr[i].f);
  }
}

void print_statistics()
{
  printf("===Statistics===\n");
  printf("nop   : %lld\n",nop_count);
  printf("add   : %lld\n",add_count);
  printf("addi  : %lld\n",addi_count);
  printf("addiu : %lld\n",addiu_count);
  printf("sub   : %lld\n",sub_count);
  printf("slli  : %lld\n",slli_count);
  printf("srai  : %lld\n",srai_count);
  printf("beq   : %lld\n",beq_count);
  printf("bneq  : %lld\n",bneq_count);
  printf("blt   : %lld\n",blt_count);
  printf("ble   : %lld\n",ble_count);
  printf("jr    : %lld\n",jr_count);
  printf("jal   : %lld\n",jal_count);
  printf("lw    : %lld\n",lw_count);
  printf("sw    : %lld\n",sw_count);
  printf("send  : %lld\n",send_count);
  printf("recv  : %lld\n",recv_count);
  printf("halt  : %lld\n",halt_count);
  printf("fmov  : %lld\n",fmov_count);
  printf("fadd  : %lld\n",fadd_count);
  printf("fsub  : %lld\n",fsub_count);
  printf("fmul  : %lld\n",fmul_count);
  printf("finv  : %lld\n",finv_count);
  printf("fsqrt : %lld\n",fsqrt_count);
  printf("fneg  : %lld\n",fneg_count);
  printf("fabs  : %lld\n",fabs_count);
  printf("ftoi  : %lld\n",ftoi_count);
  printf("itof  : %lld\n",itof_count);
  printf("floor : %lld\n",floor_count);
  printf("fbeq  : %lld\n",fbeq_count);
  printf("fbneq : %lld\n",fbneq_count);
  printf("fblt  : %lld\n",fblt_count);
  printf("fble  : %lld\n",fble_count);
  printf("flw   : %lld\n",flw_count);
  printf("fsw   : %lld\n",fsw_count);
  printf("---total : %lld---\n",inst_count);
}

void handler(int signal)
{
  print_reg();
  printf("\n");
  print_statistics();
  exit(0);
}

void command_input()
{
  char buf[MAXBUF];
  char *tok;
  int regnum;
  uint32_t addr;
  int times;
  int i;

  while (1) {
    printf(">");

    fgets(buf,MAXBUF,stdin);

    tok=strtok(buf," \n");

    if (tok==NULL || strcmp(tok,"s")==0 || strcmp(tok,"step")==0) {
      stepflag=1;
      break;
    } else if (strcmp(tok,"r")==0 || strcmp(tok,"run")==0) {
      stepflag=0;
      break;
    } else if (strcmp(tok,"b")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter breakpoint address.");
      } else {
	addr=atoi(tok);
	if (addr>=0 && addr<BRAM_NUM) {
	  breakpoint[addr]=1;
	  printf("set breakpoint : %d\n",addr);
	} else {
	  puts("Invalid memory address.");
	}
      }
    } else if (strcmp(tok,"bi")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter breakpoint address and n.");
      } else {
	addr=atoi(tok);
	if (addr>=0 && addr<BRAM_NUM) {
	  tok=strtok(NULL," \n");
	  if (tok==NULL) {
	    puts("Please enter n.");
	  } else {
	    times=atoi(tok);
	    if (times>0) {
	      breakpoint[addr]=times+1;
	      printf("set breakpoint : %d\n",addr);
	      printf("n = %d\n",times);
	    } else {
	      puts("n must be positive number.");
	    }
	  }
	} else {
	  puts("Invalid memory address.");
	}
      }
    } else if (strcmp(tok,"binst")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter instruction name.");
      } else {
	if (strcmp(tok,"nop")==0) {
	  nop_bp=1;
	  puts("breakpoint : nop");
	} else if (strcmp(tok,"send8")==0) {
	  send8_bp=1;
	  puts("breakpoint : send8");
	} else {
	  puts("Unknown instruction.");
	}
      }
    } else if (strcmp(tok,"db")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter breakpoint address.");
      } else {
	addr=atoi(tok);
	if (addr>=0 && addr<BRAM_NUM) {
	  breakpoint[addr]=0;
	  printf("delete breakpoint : ");
	  printbin(addr);
	} else {
	  puts("Invalid memory address.");
	}
      }
    } else if (strcmp(tok,"pg")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter the register number.");
      } else {
	regnum=atoi(tok);
	if (regnum>=0 && regnum<GPR_NUM) {
	  printf("GPR %d : %d\n",regnum,gpr[regnum]);
	} else {
	  puts("Invalid register number.");
	}
      }
    } else if (strcmp(tok,"pf")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter the register number.");
      } else {
	regnum=atoi(tok);
	if (regnum>=0 && regnum<FPR_NUM) {
	  printf("FPR %2d : ",regnum);
	  printfloat(fpr[regnum].i);
	  printf(" , %lf\n",fpr[regnum].f);
	} else {
	  puts("Invalid register number.");
	}
      }
    } else if (strcmp(tok,"pm")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter the memory address.");
      } else {
	addr=atoi(tok);
	if (addr>=0 && addr<SRAM_NUM) {
	  printf("memory %d : ",addr);
	  printbin(sram[addr]);
	} else {
	  puts("Invalid memory address.");
	}
      }
    } else if (strcmp(tok,"ps")==0) {
      print_statistics();
    } else if (strcmp(tok,"pp")==0) {
      printf("pc : %d\n",pc);
    } else if (strcmp(tok,"pb")==0) {
      for (i=0;i<BRAM_NUM;i++) {
	if (breakpoint[i]==1) {
	  printf("breakpoint : %d\n",i);
	} else if (breakpoint[i]>1) {
	  printf("breakpoint ignore : %d (n = %d)\n",i,breakpoint[i]-1);
	}
      }
    } else if (strcmp(tok,"pc")==0) {
      printf("FPcond : %d\n",fpcond);
    } else if (strcmp(tok,"dg")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter the register number.");
      } else {
	regnum=atoi(tok);
	if (regnum>=0 && regnum<GPR_NUM) {
	  gdisp[regnum]=1;
	  displayflag=1;
	  printf("display : GPR %d\n",regnum);
	} else {
	  puts("Invalid register number.");
	}
      }
    } else if (strcmp(tok,"df")==0) {
      tok=strtok(NULL," \n");
      if (tok==NULL) {
	puts("Please enter the register number.");
      } else {
	regnum=atoi(tok);
	if (regnum>=0 && regnum<FPR_NUM) {
	  fdisp[regnum]=1;
	  displayflag=1;
	  printf("display : FPR %d\n",regnum);
	} else {
	  puts("Invalid register number.");
	}
      }
    } else if (strcmp(tok,"pa")==0) {
      print_reg();
    } else if (strcmp(tok,"pon")==0) {
      noprintflag=0;
      puts("print inst : on");
    } else if (strcmp(tok,"poff")==0) {
      noprintflag=1;
      puts("print inst : off");
    } else if (strcmp(tok,"h")==0 || strcmp(tok,"help")==0) {
      puts("commands");
      puts("h : help");
      puts("r : run");
      puts("s : step");
      puts("b [addr] : set breakpoint [addr]");
      puts("bi [addr] [n] : breakpoint ignore");
      puts("binst [instname] : breakpoint instruction(nop and send8 only)");
      puts("db [addr] : delete breakpoint [addr]");
      puts("pg [n] : print GPR [n]");
      puts("pf [n] : print FPR [n]");
      puts("pm [addr] : print memory [addr]");
      puts("pa : print all registers");
      puts("ps : print statistics");
      puts("pp : print PC");
      puts("pb : print breakpoints");
      puts("pc : print FPcond");
      puts("dg [n] : display GPR [n]");
      puts("df [n] : display FPR [n]");
      puts("pon/poff : print instructions on/off");
    } else {
      puts("Unknown command.");
    }
  }
}


void display_reg()
{
  int i;

  for (i=0;i<GPR_NUM;i++) {
    if (gdisp[i]) {
      if (binflag) {
	printf("GPR %2d : ",i);
	printbin(gpr[i]);
      } else if (hexflag) {
	printf("GPR %2d : %08x\n",i,gpr[i]);
      } else {
	printf("GPR %2d : %d\n",i,gpr[i]);
      }
    }
  }

  for (i=0;i<FPR_NUM;i++) {
    if (fdisp[i]) {
      printf("FPR %2d : ",i);
      printfloat(fpr[i].i);
      printf(" , %lf\n",fpr[i].f);
    }
  }
}

void run()
{
  while(1) {
    if (bram[pc]==HALT) {
      halt_count++;
      inst_count++;
      break;
    }

    if (breakpoint[pc]==1) {
      stepflag=1;
    } else if (breakpoint[pc]>1) {
      breakpoint[pc]--;
    }

    if (stepflag==1) {
      command_input();
    }

    exec_inst(bram[pc]);
    inst_count++;

    if (displayflag) {
      display_reg();
    }
  }
}

void readinst(FILE* fp)
{
  uint32_t inst;
  uint32_t data=0;
  size_t rnum;
  int i;
  uint32_t addr;
  int dataflag;

  while (1) {
    inst=0;

    for (i=3;i>=0;i--) {
      rnum=fread(&data,1,1,fp);
      if (rnum==0) {
	break;
      }
      inst+=data<<(8*i);
    }

    if (rnum==0 || inst>>24==0x03) {
      break;
    } else if (inst>>24==0x01) {
      textsize=inst&0xffffff;
      addr=0;
      dataflag=0;
    } else if (inst>>24==0x02) {
      datasize=inst&0xffffff;
      addr=0;
      dataflag=1;
    } else {
      if (dataflag) {
	sram[addr]=inst;
	addr++;
      } else {
	bram[addr]=inst;
	addr++;
      }
    }
  }
}

uint32_t read_nbit(FILE *fp, int n){
	uint32_t data = 0;
	int i;
	int bit[32];
	char LF;
	for(i=0; i<n; i++) bit[i] = getc(fp);
    LF = getc(fp);
	for(i=0; i<n; i++){
		data = data * 2;
		if(bit[i]==49) data = data + 1;
	}
	return data;
}

int readtable(char* rootpath)
{
  char* filepath = malloc(strlen(rootpath) + 20);
  FILE *finv_fp1,*finv_fp2,*fsqrt_fp1,*fsqrt_fp2;
  int i;

  /* 実行ファイル名がrinであることを仮定している。あとでちゃんと直す */
  rootpath[strlen(rootpath) - 3] = '\0';

  strcpy(filepath, rootpath);
  strcat(filepath, "finv_table1.txt");
  finv_fp1=fopen(filepath,"r");
  if (finv_fp1==NULL) {
    puts("can't open file : finv_table1.txt");
    return 1;
  }
  strcpy(filepath, rootpath);
  strcat(filepath, "finv_table2.txt");
  finv_fp2=fopen(filepath,"r");
  if (finv_fp2==NULL) {
    puts("can't open file : finv_table2.txt");
    return 1;
  }
  strcpy(filepath, rootpath);
  strcat(filepath, "fsqrt_table1.txt");
  fsqrt_fp1=fopen(filepath,"r");
  if (fsqrt_fp1==NULL) {
    puts("can't open file : fsqrt_table1.txt");
    return 1;
  }
  strcpy(filepath, rootpath);
  strcat(filepath, "fsqrt_table2.txt");
  fsqrt_fp2=fopen(filepath,"r");
  if (fsqrt_fp2==NULL) {
    puts("can't open file : fsqrt_table2.txt");
    return 1;
  }

  for (i=0;i<1024;i++) {
    finv_table1[i]=read_nbit(finv_fp1,23);
    finv_table2[i]=read_nbit(finv_fp2,13);
    fsqrt_table1[i]=read_nbit(fsqrt_fp1,23);
    fsqrt_table2[i]=read_nbit(fsqrt_fp2,13);
  }

  fclose(finv_fp1);
  fclose(finv_fp2);
  fclose(fsqrt_fp1);
  fclose(fsqrt_fp2);

  free(filepath);

  return 0;
}

int main(int argc,char* argv[])
{
  FILE *fp;
  int option;
  struct sigaction si;

  si.sa_handler=handler;
  si.sa_flags=0;
  sigemptyset(&si.sa_mask);
  sigaction(SIGINT,&si,NULL);

  if (argc<2) {
    printf("usage: %s [options] filename\n",argv[0]);
    return 1;
  }

  while ((option=getopt(argc,argv,"hsi:o:rbxf"))!=-1) {
    switch (option) {
    case 'h':
      printf("usage: %s [options] filename\n",argv[0]);
      printf("options\n");
      printf("-h : help\n");
      printf("-s : step exec\n");
      printf("-i [filename] : input recv8 from binary file\n");
      printf("-o [filename] : output send8 in binary file\n");
      printf("-r : output result only\n");
      printf("-b : print GPR in binary\n");
      printf("-x : print GPR in hex\n");
      printf("-f : use x86 FPU\n");
      return 0;
    case 's':
      stepflag=1;
      break;
    case 'i':
      recv8flag=1;
      fprecv8=fopen(optarg,"rb");
      if (fprecv8==NULL) {
	printf("can't open file : %s\n",optarg);
	return 1;
      }
      break;
    case 'o':
      send8flag=1;
      fpsend8=fopen(optarg,"wb");
      if (fpsend8==NULL) {
	printf("can't open file : %s\n",optarg);
	return 1;
      }
      break;
    case 'r':
      noprintflag=1;
      break;
    case 'b':
      binflag=1;
      break;
    case 'x':
      hexflag=1;
      break;
    case 'f':
      x86flag=1;
      break;
    default:
      printf("Unknown option\n");
    }
  }

  if (argv[optind]==NULL) {
    printf("No input file\n");
    return 1;
  }

  fp=fopen(argv[optind],"rb");
  if (fp==NULL) {
    printf("can't open file : %s\n",argv[optind]);
    return 1;
  }

  readinst(fp);
  fclose(fp);

  if (readtable(argv[0])==1) {
    return 1;
  }

  run();

  print_reg();
  printf("\n");
  print_statistics();

  if (recv8flag) {
    fclose(fprecv8);
  }
  if (send8flag) {
    fclose(fpsend8);
  }

  return 0;
}
