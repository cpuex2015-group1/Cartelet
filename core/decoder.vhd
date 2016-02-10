library ieee;
use ieee.std_logic_1164.all;

use work.types.all;

package decoder is
    procedure decode(
        inst : in std_logic_vector(31 downto 0);
        op : out op_type);
end decoder;

package body decoder is

    procedure decode(
        inst : in std_logic_vector(31 downto 0);
        op : out op_type) is
    function stdv2str(vec:std_logic_vector) return string is
        variable str: string(vec'left+1 downto 1);
    begin
        for i in vec'reverse_range loop
            if(vec(i)='U') then
                str(i+1):='U';
            elsif(vec(i)='X') then
                str(i+1):='X';
            elsif(vec(i)='0') then
                str(i+1):='0';
            elsif(vec(i)='1') then
                str(i+1):='1';
            elsif(vec(i)='Z') then
                str(i+1):='Z';
            elsif(vec(i)='W') then
                str(i+1):='W';
            elsif(vec(i)='L') then
                str(i+1):='L';
            elsif(vec(i)='H') then
                str(i+1):='H';
            else
                str(i+1):='-';
            end if;
        end loop;
        return str;
    end;
    alias opcode : std_logic_vector(5 downto 0) is inst(31 downto 26);
    alias reg1 : std_logic_vector(4 downto 0) is inst(25 downto 21);
    alias reg2 : std_logic_vector(4 downto 0) is inst(20 downto 16);
    alias reg3 : std_logic_vector(4 downto 0) is inst(15 downto 11);
    alias imm : std_logic_vector(15 downto 0) is inst(15 downto 0);
    alias addr : std_logic_vector(25 downto 0) is inst(25 downto 0);
    begin
        op.opcode := opcode;
        op.reg1 := reg1;
        op.reg2 := reg2;
        op.reg3 := reg3;
        op.read1 := (others => '0');
        op.read2 := (others => '0');
        op.imm := imm;
        op.addr := addr;
        op.command := (others => '0');
        op.imm_zero_ext := false; -- 即値を符号拡張しない
        op.use_imm := false;

        if inst(31) = '1' then
            op.floating := true;
        else
            op.floating := false;
        end if;

        report stdv2str(inst(31 downto 26));
        case inst(31 downto 26) is
            when OP_ADD =>
                op.rs_tag := rs_alu;
                op.command := ALU_ADD;
                op.read1 := reg2;
                op.read2 := reg3;

            when OP_ADDI =>
                op.rs_tag := rs_alu;
                op.command := ALU_ADD;
                op.use_imm := true;
                op.read1 := reg2;

            when OP_ADDIU =>
                op.rs_tag := rs_alu;
                op.command := ALU_ADD;
                op.imm_zero_ext := true;
                op.use_imm := true;
                op.read1 := reg2;

            when OP_SUB =>
                op.rs_tag := rs_alu;
                op.command := ALU_SUB;
                op.read1 := reg2;
                op.read2 := reg3;

            when OP_SLLI =>
                op.rs_tag := rs_alu;
                op.command := ALU_SLL;
                op.use_imm := true;
                op.read1 := reg2;
                op.read2 := reg3;

            when OP_SRAI =>
                op.rs_tag := rs_alu;
                op.command := ALU_SRA;
                op.use_imm := true;
                op.read1 := reg2;
                op.read2 := reg3;

            when OP_SEND =>
                op.rs_tag := rs_send;
                op.read1 := reg1;

            when OP_RECV =>
                op.rs_tag := rs_recv;

            when OP_BEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_EQ;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_BNEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_NEQ;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_BLT =>
                op.rs_tag := rs_branch;
                op.command := BRU_LT;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_BLE =>
                op.rs_tag := rs_branch;
                op.command := BRU_LE;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_JR =>
                op.rs_tag := rs_jump;
                op.command := ALU_ADD;
                op.read1 := reg1;

            when OP_JAL =>
                op.rs_tag := rs_jal;

            when OP_LW =>
                op.rs_tag := rs_memory;
                op.command := MCU_LW;
                op.read1 := reg2;

            when OP_SW =>
                op.rs_tag := rs_memory;
                op.command := MCU_SW;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_FBEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_FEQ;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_FADD =>
                op.rs_tag := rs_fpu;
                op.command := FPU_ADD;
                op.read1 := reg2;
                op.read2 := reg3;

            when OP_FBNEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_FNEQ;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_FBLT =>
                op.rs_tag := rs_branch;
                op.command := BRU_FLT;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_FBLE =>
                op.rs_tag := rs_branch;
                op.command := BRU_FLE;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_FLW =>
                op.rs_tag := rs_memory;
                op.command := MCU_LW;
                op.read1 := reg2;

            when OP_FSW =>
                op.rs_tag := rs_memory;
                op.command := MCU_SW;
                op.read1 := reg1;
                op.read2 := reg2;

            when OP_HALT =>
                op.rs_tag := rs_halt;
            when others =>
                op.rs_tag := rs_others;
        end case;
    end decode;
end decoder;
