library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
    generic (
        ADDR_LEN : integer := 5,
        DATA_LEN : integer := 32
    );
    port (
        clk : in std_logic;
        we : in std_logic;
        addr : in std_logic_vector(ADDR_LEN - 1 downto 0);
        din : in std_logic_vector(DATA_LEN - 1 downto 0);
        dout : out std_logic_vector(DATA_LEN - 1 downto 0)
    );
end ram;

architecture struct of ram is
    subtype ram_entry_type is std_logic_vector(DATA_LEN - 1 downto 0);
    type ram_type is array(0 to 2 ** ADDR_LEN - 1) of ram_entry_type;

    signal ram : ram_type := (others => (others => '0'));
    signal ram_addr : std_logic_vector(ADDR_LEN - 1 downto 0);
begin
    mem_clk: process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= din;
            end if;
            ram_addr <= addr;
        end if;
    end process;
    dout <= ram(to_integer(unsigned(ram_addr)));
end struct;
