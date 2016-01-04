#ifndef CPU_H
#define CPU_H

#define GPR_NUM 32
#define FPR_NUM 32
#define SRAM_NUM (1<<20)
#define BRAM_NUM (1<<20)

#define OP_NOP   0x00
#define OP_ADD   0x01
#define OP_ADDI  0x02
#define OP_ADDIU 0x03
#define OP_SUB   0x04
#define OP_SLLI  0x05
#define OP_SRAI  0x06
#define OP_BEQ   0x08
#define OP_BNEQ  0x09
#define OP_BLT   0x0a
#define OP_BLE   0x0b
#define OP_JR    0x0c
#define OP_JAL   0x0d
#define OP_LW    0x10
#define OP_SW    0x11
#define OP_SEND  0x1d
#define OP_RECV  0x1e
#define OP_HALT  0x1f

#define OP_FMOV  0x20
#define OP_FADD  0x21
#define OP_FSUB  0x22
#define OP_FMUL  0x23
#define OP_FINV  0x24
#define OP_FSQRT 0x25
#define OP_FNEG  0x26
#define OP_FABS  0x27
#define OP_FTOI  0x2c
#define OP_ITOF  0x2d
#define OP_FLOOR 0x2e
#define OP_FBEQ  0x28
#define OP_FBNEQ 0x29
#define OP_FBLT  0x2a
#define OP_FBLE  0x2b
#define OP_FLW   0x30
#define OP_FSW   0x31


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
extern long long int beq_count;
extern long long int bneq_count;
extern long long int blt_count;
extern long long int ble_count;
extern long long int jr_count;
extern long long int jal_count;
extern long long int lw_count;
extern long long int sw_count;
extern long long int send_count;
extern long long int recv_count;
extern long long int halt_count;

extern long long int fmov_count;
extern long long int fadd_count;
extern long long int fsub_count;
extern long long int fmul_count;
extern long long int finv_count;
extern long long int fsqrt_count;
extern long long int fneg_count;
extern long long int fabs_count;
extern long long int ftoi_count;
extern long long int itof_count;
extern long long int floor_count;
extern long long int fbeq_count;
extern long long int fbneq_count;
extern long long int fblt_count;
extern long long int fble_count;
extern long long int flw_count;
extern long long int fsw_count;

extern int nop_bp;
extern int send8_bp;

extern uint32_t finv_table1[1024];
extern uint32_t finv_table2[1024];
extern uint32_t fsqrt_table1[1024];
extern uint32_t fsqrt_table2[1024];

void exec_inst();

#endif
