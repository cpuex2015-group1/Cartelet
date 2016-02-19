library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram_sim is
    generic (
        SIM_SRAM_ADDR_LENGTH : integer := 17
    );
    port (
        ZD     : inout std_logic_vector (31 downto 0);
        ZA     : in    std_logic_vector (19 downto 0);
        XWA    : in    std_logic;
        XE1    : in    std_logic;
        E2A    : in    std_logic;
        XE3    : in    std_logic;
        XGA    : in    std_logic;
        XZCKE  : in    std_logic;
        ADVA   : in    std_logic;
        XLBO   : in    std_logic;
        ZZA    : in    std_logic;
        XFT    : in    std_logic;
        XZBE   : in    std_logic_vector (3 downto 0);
        ZCLKMA : in    std_logic_vector (1 downto 0));

end sram_sim;

architecture behaviour of sram_sim is
    type mem_type is array (2 ** SIM_SRAM_ADDR_LENGTH - 1 downto 0) of std_logic_vector (31 downto 0);
    signal mem : mem_type;
    type data_type is array (1 downto 0) of std_logic_vector (31 downto 0);
    type addr_type is array (3 downto 0) of std_logic_vector (19 downto 0);
    signal xwab : std_logic_vector (3 downto 0) := (others => '1');
    signal zdbi : data_type := (others => (others => '0'));
    signal zab  : addr_type := (others => (others => '0'));
--    component SRAM_SIM_CLK is
--        port (
--            CLKIN_IN : in std_logic;
--            RST_IN : in std_logic;
--            CLK0_OUT : out std_logic;
--            LOCKED_OUT : out std_logic
--        );
--    end component;
    signal clk : std_logic;
    signal rst : std_logic := '0';
begin
--    sram_sim_clock : SRAM_SIM_CLK port map (
--        CLKIN_IN => ZCLKMA (0),
--        RST_IN => rst,
--        CLK0_OUT => clk
--    );

    process (ZCLKMA(0), ZD, ZA, xwab, zab)
        variable zdbo : std_logic_vector (31 downto 0);
    begin
        if rising_edge(ZCLKMA(0)) then
            xwab(1) <= XWA;
            xwab(2) <= xwab(1);
            xwab(3) <= xwab(2);

            zdbi(1) <= ZD;

            zab(1)  <= ZA;
            zab(2)  <= zab(1);
            zab(3)  <= zab(2);
            zdbo := (others => 'Z');
            if xwab (2 downto 1) = "01" then
                if zab(2)(0) = '1' or zab(2)(0) = '0' then
                    mem(to_integer(unsigned(zab(2)(SIM_SRAM_ADDR_LENGTH - 1 downto 0)))) <= ZD;
                    if zab(2) = zab(1) then
                        zdbo := ZD;
                    else
                        zdbo := mem(to_integer(unsigned(zab(1)(SIM_SRAM_ADDR_LENGTH - 1 downto 0))));
                    end if;
                end if;
            elsif xwab (2 downto 1) = "11" then
                if zab(1)(0) = '1' or zab(1)(0) = '0' then
                    zdbo := mem(to_integer(unsigned(zab(1)(SIM_SRAM_ADDR_LENGTH - 1 downto 0))));
                end if;
            else
                if zab(2)(0) = '1' or zab(2)(0) = '0' then
                    mem(to_integer(unsigned(zab(2)(SIM_SRAM_ADDR_LENGTH - 1 downto 0)))) <= ZD;
                    zdbo := (others => 'Z');
                end if;
            end if;

            ZD <= zdbo;
        end if;
    end process;
end behaviour;
