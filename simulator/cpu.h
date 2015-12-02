#ifndef CPU_H
#define CPU_H

#define GPR_NUM 32
#define FPR_NUM 32
#define SRAM_NUM (1<<20)
#define BRAM_NUM (1<<20)

#define OP_NOP   
#define OP_ADD   
#define OP_ADDI  
#define OP_ADDIU 
#define OP_SUB
#define OP_SLLI
#define OP_SRAI
#define OP_BCND
#define OP_JR
#define OP_JAL
#define OP_LW
#define OP_SW
#define OP_SEND
#define OP_RECV

#define OP_FMOV
#define OP_FADD
#define OP_FSUB
#define OP_FMUL
#define OP_FINV
#define OP_FSQRT
#define OP_FNEG
#define OP_FABS
#define OP_FBCND
#define OP_FLW
#define OP_FSW


#define HALT (OP_HALT<<26)

typedef union {
  uint32_t i;
  float f;
} IF;

extern uint32_t pc;
extern uint32_t fpcond;

extern int32_t gpr[GPR_NUM];
extern IF fpr[FPR_NUM];

extern uint32_t sram[SRAM_NUM];
extern uint32_t bram[BRAM_NUM];

extern FILE* fprecv8;
extern FILE* fpsend8;

extern int stepflag;
extern int recv8flag;
extern int send8flag;
extern int noprintflag;
extern int x86flag;

extern long long int nop_count;
extern long long int add_count;
extern long long int addi_count;
extern long long int addiu_count;
extern long long int sub_count;
extern long long int slli_count;
extern long long int srai_count;
extern long long int bcnd_count;
extern long long int jr_count;
extern long long int jal_count;
extern long long int lw_count;
extern long long int sw_count;
extern long long int send_count;
extern long long int recv_count;

extern long long int fmov_count;
extern long long int fadd_count;
extern long long int fsub_count;
extern long long int fmul_count;
extern long long int finv_count;
extern long long int fsqrt_count;
extern long long int fneg_count;
extern long long int fabs_count;
extern long long int fbcnd_count;

extern int nop_bp;
extern int send8_bp;

extern uint32_t finv_table1[1024];
extern uint32_t finv_table2[1024];
extern uint32_t fsqrt_table1[1024];
extern uint32_t fsqrt_table2[1024];

void exec_inst();

#endif
