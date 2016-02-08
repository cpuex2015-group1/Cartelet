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
    begin
        op.opcode := inst(31 downto 26);
        op.reg1 := inst(25 downto 21);
        op.reg2 := inst(20 downto 16);
        op.reg3 := inst(15 downto 11);
        op.imm := inst(15 downto 0);
        op.addr := inst(25 downto 0);
        op.command := (others => '0');
        op.use_imm := false;
        report stdv2str(inst(31 downto 26));
        case inst(31 downto 26) is
            when OP_ADD =>
                op.rs_tag := rs_alu;
                op.command := ALU_ADD;
            when OP_ADDI =>
                op.rs_tag := rs_alu;
                op.command := ALU_ADD;
                op.use_imm := true;
            when OP_SEND =>
                op.rs_tag := rs_send;
            when OP_RECV =>
                op.rs_tag := rs_recv;
            when OP_BEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_EQ;
            when OP_BNEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_NEQ;
            when OP_BLT =>
                op.rs_tag := rs_branch;
                op.command := BRU_LT;
            when OP_BLE =>
                op.rs_tag := rs_branch;
                op.command := BRU_LE;
            when OP_JR =>
                op.rs_tag := rs_jump;
                op.command := ALU_ADD;
            when OP_JAL =>
                op.rs_tag := rs_jal;
            when OP_FBEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_FEQ;
            when OP_LW =>
                op.rs_tag := rs_memory;
                op.command := MCU_LW;
            when OP_SW =>
                op.rs_tag := rs_memory;
                op.command := MCU_SW;
            when OP_FBNEQ =>
                op.rs_tag := rs_branch;
                op.command := BRU_FNEQ;
            when OP_FBLT =>
                op.rs_tag := rs_branch;
                op.command := BRU_FLT;
            when OP_FBLE =>
                op.rs_tag := rs_branch;
                op.command := BRU_FLE;
            when OP_HALT =>
                op.rs_tag := rs_halt;
            when others =>
                op.rs_tag := rs_others;
        end case;
    end decode;
end decoder;
