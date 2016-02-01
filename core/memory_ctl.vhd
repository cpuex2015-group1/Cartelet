library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity memory_ctl is
    port (
        clk : in std_logic;
        memory_ctl_in : in memory_ctl_in_type;
        memory_ctl_out : out memory_ctl_out_type);
end entity;

architecture struct of memory_ctl is
    type reg_type is record
        hoge : std_logic_vector(3 downto 0);
    end record;
    constant reg_init : reg_type := (
        hoge => (others => '0'));
    signal r, rin : reg_type := reg_init;
begin
    comb : process (memory_ctl_in, r)
    begin
    end process;

    reg : process (clk)
    begin
        if rising_edge(clk) then
            r <= rin;
        end if;
    end process;
end struct;
