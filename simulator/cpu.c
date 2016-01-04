#include<stdio.h>
#include<stdint.h>
#include<math.h>
#include"cpu.h"
#include"fpu.h"

uint32_t pc=0;
uint32_t fpcond=0;

int32_t gpr[GPR_NUM]={};
IF fpr[FPR_NUM]={};

uint32_t sram[SRAM_NUM]={};
uint32_t bram[BRAM_NUM]={};

void printinst(uint32_t i) /* debug */
{
  int k;

  for (k=31;k>=0;k--) {
    printf("%d",(i>>k)&1);
    if (k==26 || k==21 || k==16 || k==11 || k==6) {
      printf(" ");
    }
  }
  printf("\n");
}

void print8(uint32_t i)
{
  int k;

  for (k=7;k>=0;k--) {
    printf("%d",(i>>k)&1);
  }
  printf("\n");
}

void decode(uint32_t inst,uint32_t *opcode,uint32_t *r1,uint32_t *r2,uint32_t *r3,uint32_t *shamt,uint32_t *funct,int16_t *imm,uint16_t *uimm,int16_t *addr)
{
  *opcode=inst>>26;
  *r1=(inst>>21)&0x1f;
  *r2=(inst>>16)&0x1f;
  *r3=(inst>>11)&0x1f;
  *shamt=(inst>>6)&0x1f;
  *funct=inst&0x3f;
  *imm=inst&0xffff;
  *uimm=inst&0xffff;
  *addr=inst&0x3ffffff;
}

void exec_inst(uint32_t inst)
{
  uint32_t opcode,r1,r2,r3,shamt,funct;
  int16_t imm;
  uint16_t uimm;
  int16_t addr;

  uint32_t recvdata=0;
  uint8_t senddata=0;

  int finv_addr,fsqrt_addr;

  decode(inst,&opcode,&r1,&r2,&r3,&shamt,&funct,&imm,&uimm,&addr);

  if (!noprintflag) {
    printinst(inst);
  }

  switch (opcode) {
  case OP_NOP:
    if (!noprintflag) {
      printf("nop\n");
    }
    if (nop_bp) {
      stepflag=1;
    }
    pc++;
    nop_count++;
    break;
  case OP_ADD:
    gpr[r1]=gpr[r2]+gpr[r3];
    if (!noprintflag) {
      printf("add : r%d <- r%d + r%d\n",r1,r2,r3);
    }
    pc++;
    add_count++;
    break;
  case OP_ADDI:
    gpr[r1]=gpr[r2]+imm;
    if (!noprintflag) {
      printf("addi : r%d <- r%d + %d\n",r1,r2,imm);
    }
    pc++;
    addi_count++;
    break;
  case OP_ADDIU:
    gpr[r1]=gpr[r2]+uimm;
    if (!noprintflag) {
      printf("addiu : r%d <- r%d + %d\n",r1,r2,uimm);
    }
    pc++;
    addiu_count++;
    break;
  case OP_SUB:
    gpr[r1]=gpr[r2]-gpr[r3];
    if (!noprintflag) {
      printf("sub : r%d <- r%d - r%d\n",r1,r2,r3);
    }
    pc++;
    sub_count++;
    break;
  case OP_SLLI:
    if (imm>=0) {
      gpr[r1]=(unsigned) gpr[r2]<<imm;
    } else {
      gpr[r1]=(unsigned) gpr[r2]>>(-imm);
    }
    if (!noprintflag) {
      printf("slli : r%d <- r%d << %d\n",r1,r2,imm);
    }
    pc++;
    slli_count++;
    break;
  case OP_SRAI:
    if (imm>=0) {
      gpr[r1]=gpr[r2]>>imm;
    } else {
      gpr[r1]=gpr[r2]<<(-imm);
    }
    if (!noprintflag) {
      printf("srai : r%d <- r%d >>> r%d\n",r1,r2,imm);
    }
    pc++;
    srai_count++;
    break;
  case OP_BEQ:
    if (gpr[r1]==gpr[r2]) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("beq : pc <- (r%d == r%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    beq_count++;
    break;
  case OP_BNEQ:
    if (gpr[r1]!=gpr[r2]) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("bneq : pc <- (r%d != r%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    bneq_count++;
    break;
  case OP_BLT:
    if (gpr[r1]<gpr[r2]) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("blt : pc <- (r%d < r%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    blt_count++;
    break;
  case OP_BLE:
    if (gpr[r1]<=gpr[r2]) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("ble : pc <- (r%d <= r%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    ble_count++;
    break;
  case OP_JR:
    pc=gpr[r1];
    if (!noprintflag) {
      printf("jr : pc <- r%d\n",r1);
    }
    jr_count++;
    break;
  case OP_JAL:
    gpr[31]=pc+1;
    pc=addr;
    if (!noprintflag) {
      printf("jal : r31 <- pc + 1; pc <- %d\n",addr);
    }
    jal_count++;
    break;
  case OP_LW:
    gpr[r1]=sram[gpr[r2]+imm];
    if (!noprintflag) {
      printf("lw : r%d <- mem[r%d + %d]\n",r1,r2,imm);
    }
    pc++;
    lw_count++;
    break;
  case OP_SW:
    sram[gpr[r1]+imm]=gpr[r2];
    if (!noprintflag) {
      printf("sw : mem[r%d + %d] <- r%d\n",r1,imm,r2);
    }
    pc++;
    sw_count++;
    break;
  case OP_SEND:
    if (send8flag) {
      senddata=gpr[r1]&0xff;
      fwrite(&senddata,1,1,fpsend8);
    }
    if (!noprintflag) {
      printf("send : r%d = ",r1);
      print8(gpr[r1]);
    }
    if (send8_bp) {
      stepflag=1;
    }
    pc++;
    send_count++;
    break;
  case OP_RECV:
    if (recv8flag && fread(&recvdata,1,1,fprecv8)==0) {
      printf("recv(hexで入力)>");
      scanf("%x",&recvdata);
    }
    gpr[r1]=(gpr[r1]&0xffffff00)|recvdata;
    if (!noprintflag) {
      printf("recv : r%d <- ",r1);
      print8(recvdata);
    }
    pc++;
    recv_count++;
    break;
  case OP_HALT:
    if (!noprintflag) {
      printf("halt\n");
    }
    halt_count++;
    break;
  case OP_FMOV:
    fpr[r1].i=fpr[r2].i;
    if (!noprintflag) {
      printf("fmov : f%d <- f%d\n",r1,r2);
    }
    pc++;
    fmov_count++;
    break; 
  case OP_FADD:
    if (x86flag) {
      fpr[r1].f=fpr[r2].f+fpr[r3].f;
    } else {
      fpr[r1].i=fadd(fpr[r2].i,fpr[r3].i);
    }
    if (!noprintflag) {
      printf("fadd : f%d <- f%d + f%d\n",r1,r2,r3);
    }
    pc++;
    fadd_count++;
    break;
  case OP_FSUB:
    pc++;
    fsub_count++;
    break;
  case OP_FMUL:
    if (x86flag) {
      fpr[r1].f=fpr[r2].f*fpr[r3].f;
    } else {
      fpr[r1].i=fmul(fpr[r2].i,fpr[r3].i);
    }
    if (!noprintflag) {
      printf("fmul : f%d <- f%d * f%d\n",r1,r2,r3);
    }
    pc++;
    fmul_count++;
    break;
  case OP_FINV:
    if (x86flag) {
      fpr[r1].f=1.0/fpr[r2].f;
    } else {
      finv_addr=(fpr[r2].i & 0x7FE000)>>13;
      fpr[r1].i=finv(fpr[r2].i,finv_table1[finv_addr],finv_table2[finv_addr]);
    }
    if (!noprintflag) {
      printf("finv : f%d <- 1 / f%d\n",r1,r2);
    }
    pc++;
    finv_count++;
    break;  
  case OP_FSQRT:
    if (x86flag) {
      fpr[r1].f=sqrt(fpr[r2].f);
    } else {
      fsqrt_addr=(fpr[r2].i & 0xFFC000)>>14;
      fpr[r1].i=fsqrt(fpr[r2].i,fsqrt_table1[fsqrt_addr],fsqrt_table2[fsqrt_addr]);
    }
    if (!noprintflag) {
      printf("fsqrt : f%d <- sqrt(f%d)\n",r1,r2);
    }
    pc++;
    fsqrt_count++;
    break;
  case OP_FNEG:
    fpr[r1].f=-fpr[r2].f;
    if (!noprintflag) {
      printf("fneg : f%d <- -f%d\n",r1,r2);
    }
    pc++;
    fneg_count++;
    break;
  case OP_FABS:
    if (fpr[r2].f<0) {
      fpr[r1].f=-fpr[r2].f;
    } else {
      fpr[r1].f=fpr[r2].f;
    }
    if (!noprintflag) {
      printf("fabs : f%d <- abs(f%d)\n",r1,r2);
    }
    pc++;
    fabs_count++;
    break;
  case OP_FTOI:
    if (x86flag) {
      gpr[r1]=(int32_t)roundf(fpr[r2].f);
    } else {
      gpr[r1]=fpu_ftoi(fpr[r2].i);
    }
    if (!noprintflag) {
      printf("ftoi : r%d <- (int32_t) roundf(f%d)\n",r1,r2);
    }
    pc++;
    ftoi_count++;
    break;
  case OP_ITOF:
    if (x86flag) {
      fpr[r1].f=(float)gpr[r2];
    } else {
      fpr[r1].i=fpu_itof(gpr[r2]);
    }
    if (!noprintflag) {
      printf("itof : f%d <- (floor) r%d\n",r1,r2);
    }
    pc++;
    itof_count++;
    break;
  case OP_FLOOR:
    if (x86flag) {
      fpr[r1].f=floor(fpr[r2].f);
    } else {
      fpr[r1].i=fpu_floor(fpr[r2].i);
    }
    if (!noprintflag) {
      printf("floor : f%d <- floor(f%d)\n",r1,r2);
    }
    pc++;
    floor_count++;
    break;
  case OP_FBEQ:
    if (fpr[r1].f==fpr[r2].f) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("fbeq : pc <- (f%d == f%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    fbeq_count++;
    break;
  case OP_FBNEQ:
    if (fpr[r1].f!=fpr[r2].f) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("fbneq : pc <- (f%d != f%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    fbneq_count++;
    break;
  case OP_FBLT:
    if (fpr[r1].f<fpr[r2].f) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("fblt : pc <- (f%d < f%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    fblt_count++;
    break;
  case OP_FBLE:
    if (fpr[r1].f<=fpr[r2].f) {
      pc=pc+1+imm;
    } else {
      pc++;
    }
    if (!noprintflag) {
      printf("fble : pc <- (f%d <= f%d) ? pc + %d + 1 : pc + 1\n",r1,r2,imm);
    }
    fble_count++;
    break;
  case OP_FLW:
    fpr[r1].i=sram[gpr[r2]+imm];
    if (!noprintflag) {
      printf("fld : f%d <- mem[r%d + %d]\n",r1,r2,imm);
    }
    pc++;
    flw_count++;
    break;
  case OP_FSW:
    sram[gpr[r1]+imm]=fpr[r2].i;
    if (!noprintflag) {
      printf("fst : mem[r%d + %d] <- f%d\n",r1,imm,r2);
    }
    pc++;
    fsw_count++;
    break;
  default:
    printf("Unknown instruction\n");
    pc++;
    break;
  }
}
