library ieee;
use ieee.std_logic_1164.all;

use work.types.all;

package forwarder is
    procedure forwarding(
        reg_num : in std_logic_vector(4 downto 0);
        floating : in boolean;
        reg_misc : in reg_misc_entry_type;
        value : in std_logic_vector(31 downto 0);
        regs : in reg_wb_type;
        forwarded_reg : out reg_file_entry_type);
end forwarder;

package body forwarder is
    procedure forwarding(
        reg_num : in std_logic_vector(4 downto 0);
        floating : in boolean;
        reg_misc : in reg_misc_entry_type;
        value : in std_logic_vector(31 downto 0);
        regs : in reg_wb_type;
        forwarded_reg : out reg_file_entry_type) is
    begin
        forwarded_reg.busy := reg_misc.busy;
        forwarded_reg.rtag := reg_misc.rtag;

        for i in regs'reverse_range loop
            if regs(i).valid and regs(i).reg_num = reg_num and regs(i).floating = floating then
                forwarded_reg.value := regs(i).value;
            else
                forwarded_reg.value := value;
            end if;
        end loop;
    end forwarding;
end forwarder;
