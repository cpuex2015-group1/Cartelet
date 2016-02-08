library ieee;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity top is
    generic (
--        wtime : std_logic_vector(15 downto 0) := x"24ED" -- 90MHz 9600
--        wtime : std_logic_vector(15 downto 0) := x"2847" -- 99MHz 9600
        wtime : std_logic_vector(15 downto 0) := x"1ADB" -- 66MHz 9600
--        wtime : std_logic_vector(15 downto 0) := x"0242" -- 66MHz 115200
--        wtime : std_logic_vector(15 downto 0) := x"0302" -- 88MHz 115200
--        wtime : std_logic_vector(15 downto 0) := x"2CC2" -- 110MHz (5/3) 9600
--        wtime : std_logic_vector(15 downto 0) := x"313C" -- 121MHz 9600
--        wtime : std_logic_vector(15 downto 0) := x"0D6D" -- 133MHz 38400
    );
    port (
        MCLK1  : in    std_logic;
        RS_RX  : in    std_logic;
        RS_TX  : out   std_logic;
        ZD     : inout std_logic_vector(31 downto 0);
        ZA     : out   std_logic_vector(SRAM_ADDR_WIDTH downto 0);
        XWA    : out   std_logic;
        XE1    : out   std_logic;
        E2A    : out   std_logic;
        XE3    : out   std_logic;
        XGA    : out   std_logic;
        XZCKE  : out   std_logic;
        ADVA   : out   std_logic;
        XLBO   : out   std_logic;
        ZZA    : out   std_logic;
        XFT    : out   std_logic;
        XZBE   : out   std_logic_vector(3 downto 0);
        ZCLKMA : out   std_logic_vector(1 downto 0));
end top;

architecture struct of top is
    component CPU_CLK is
        port (
            CLKIN_IN : in std_logic;
            RST_IN : in std_logic;
            CLKFX_OUT : out std_logic;
            CLKIN_IBUFG_OUT : out std_logic;
            CLK0_OUT : out std_logic;
            LOCKED_OUT : out std_logic
        );
    end component;
    signal clk : std_logic;
    signal iclk : std_logic;
    signal receiver_in : receiver_in_type := receiver_in_init;
    signal sender_out : sender_out_type := sender_out_init;
    signal cpu_in : cpu_in_type := cpu_in_init;
    signal cpu_out : cpu_out_type := cpu_out_init;
begin
    cpu_clock : CPU_CLK port map (
        CLKIN_IN => MCLK1,
        RST_IN => '0',
        CLKFX_OUT => clk
    );
    sender0 : sender generic map (wtime) port map (clk, cpu_out.send, sender_out);
    receiver0 : receiver generic map (wtime) port map (clk, receiver_in, cpu_in.recv);
    cpu0 : cpu port map (clk, cpu_in, cpu_out);

    cpu_in.sender_busy <= sender_out.busy;
    receiver_in.rs_rx <= RS_RX;
    receiver_in.pop <= cpu_out.receiver_pop;

    RS_TX <= sender_out.rs_tx;

    cpu_in.ZD <= ZD;
    ZD <= cpu_out.ZD when cpu_out.zd_enable = true else (others => 'Z');

    ZA <= cpu_out.ZA;
    XWA <= cpu_out.XWA;

    XE1 <= '0';
    E2A <= '1';
    XE3 <= '0';
    XGA <= '0';
    XZCKE <= '0';
    ADVA <= '0';
    XLBO <= '1';
    ZZA <= '0';
    XFT <= '1';
    XZBE <= "0000";
    ZCLKMA(0) <= clk;
    ZCLKMA(1) <= clk;
end struct;
