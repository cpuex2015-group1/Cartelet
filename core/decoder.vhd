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
            when OP_HALT =>
                op.rs_tag := rs_halt;
            when others =>
                op.rs_tag := rs_others;
        end case;
    end decode;
end decoder;
