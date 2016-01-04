library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity top is
  Port ( MCLK1 : in  STD_LOGIC;
         RS_TX : out  STD_LOGIC);
end top;

architecture fpu4 of top is

   component clock
    port (
          CLKIN_IN        : in    std_logic; 
          RST_IN          : in    std_logic; 
          CLKFX_OUT       : out   std_logic; 
          CLKIN_IBUFG_OUT : out   std_logic; 
          CLK0_OUT        : out   std_logic; 
          LOCKED_OUT      : out   std_logic);
  end component;

  signal clk: std_logic;
  type input_rom  is array(0 to 99) of std_logic_vector(31 downto 0);
  type output_rom is array(0 to 99) of std_logic_vector(31 downto 0);

  constant input_data: input_rom :=(
    "01100111110001100110100101110011",
    "01010001111111110100101011101100",
    "00101001110011011011101010101011",
    "01110010111110111110001101000110",
    "01111100110000100101010011111000",
    "00011011111010001110011110001101",
    "01110110010110100010111001100011",
    "00110011100111111100100110011010",
    "01100110001100100000110110110111",
    "00110001010110001010001101011010",
    "00100101010111010000010100010111",
    "01011000111010010101111011010100",
    "00101011101100101100110111000110",
    "00011011101101000101010000010001",
    "00001110100000100111010001000001",
    "00100001001111011101110010000111",
    "01110000111010010011111010100001",
    "01000001111000011111110001100111",
    "00111110000000010111111010010111",
    "01101010110111000110101110010110",
    "00001111001110000101110000101010",
    "01101100101100000011101111111011",
    "00110010101011110011110001010100",
    "01101100000110001101101101011100",
    "00000010000110101111111001000011",
    "01111011111110101010101000111010",
    "01111011001010011101000111100110",
    "00000101001111000111110010010100",
    "01110101110110001011111001100001",
    "00001001111110010101110010111011",
    "00101000100110010000111110010101",
    "00110001111010111111000110110011",
    "00000101111011111111011100000000",
    "01101001101000010011101011100101",
    "01001010000010111100101111010000",
    "01001000010001110110010010111101",
    "00011111001000110001111010101000",
    "00011100011110110110010011000101",
    "00010100011100110101101011000101",
    "01011110010010110111100101100011",
    "00111011011100000110010000100100",
    "00010001100111100000100111011100",
    "00101010110101001010110011110010",
    "00011011000100001010111100111011",
    "00110011110011011110001101010000",
    "01001000010001110001010101011100",
    "00111011011011110010001000011001",
    "00111010100110110111110111110101",
    "00001011111000010001101000011100",
    "01111111001000111111100000101001",
    "01111000101001000001101100010011",
    "00110101110010100100111011101000",
    "00011000001100100011100011100000",
    "01111001010011010011110100110100",
    "00111100010111110100111001110111",
    "01111010110010110110110000000101",
    "00101100100001100010000100101011",
    "00101010000110100101010110100010",
    "00111110011100001011010101110011",
    "00111011000001000101110011010011",
    "00110110100101001011001110101111",
    "01100010111100001110010010011110",
    "01001111001100100001010101001001",
    "01111101100000100100111010101001",
    "00001000011100001101010010110010",
    "00001010001010010101010001001000",
    "00011010000010101011110011010101",
    "00001110000110001010100001000100",
    "00101100010110111111001110001110",
    "01001100110101110010110110011011",
    "00001001010000101110010100000110",
    "01000100001100111010111111001101",
    "00100011100001000111111100101101",
    "00101101110101000111011001000111",
    "01011110001100100001110011101100",
    "01001010110001000011000011110110",
    "00100000001000111000010101101100",
    "01111011101100100000011100000100",
    "01110100111011000000101110111001",
    "00100000101110101000011011000011",
    "00111110000001011111000111101100",
    "01011001011001110011001110110111",
    "00011001010100001010001111100011",
    "00010100110100111101100100110100",
    "01110111010111101010000011110010",
    "00010000101010001111011000000101",
    "00010100000000011011111010110100",
    "00111100010001000111100011111010",
    "01001001011010011110011000100011",
    "01010000000110101101101001101001",
    "01101010011111100100110001111110",
    "01010001001001011011001101001000",
    "00000100010100110011101010010100",
    "01111011001100011001100110010000",
    "00110010010101110100010011101110",
    "00011011101111001110100111100101",
    "00100101110011110000100011110101",
    "01101001111000100101111001010011",
    "01100000101010101101001010110010",
    "01010000100001011111101001010100");

  constant answer_data: output_rom :=(
    "01010011100111110101110100001101",
    "01001000101101001100010011100001",
    "00110100101000100100011010000101",
    "01011001001100111000111100111110",
    "01011110000111011011011101101001",
    "00101101101011001010100100101101",
    "01011010111011000101010111010111",
    "00111001100011110000001101100110",
    "01010010110101010111111110101101",
    "00111000011010110111111110000010",
    "00110010011011011101111000100111",
    "01001100001011001101010101011111",
    "00110101100101110100100010111100",
    "00101101100101111110110101111110",
    "00100111000000010011100010100010",
    "00110000010111000111011011011101",
    "01011000001011001100100101110001",
    "01000000101010100001001110111000",
    "00111110101101100001001010110011",
    "01010101001001111111100000111000",
    "00100111010110010011111100101100",
    "01010110000101100011000101110011",
    "00111001000101011100010001011011",
    "01010101110001011101000100000100",
    "00100000110001110011000110101011",
    "01011101101100110001111110000111",
    "01011101010100001000000100000010",
    "00100010010110111010101000101000",
    "01011010101001101001000000011000",
    "00100100101100101010100000110111",
    "00110100000010111111100001111101",
    "00111000101011011100100010101110",
    "00100010101011110100001000100100",
    "01010100100011111010100001001011",
    "01000100101111010010110100111010",
    "01000011111000011110111001001010",
    "00101111010011000101100101101110",
    "00101101111111011010111110110100",
    "00101001111110011001100011100001",
    "01001110111001000011101100100001",
    "00111101011110000001001010100101",
    "00101000100011100011101001111011",
    "00110101001001001111111000001001",
    "00101101010000000111010010101110",
    "00111001101000100101011010001100",
    "01000011111000011100000101001100",
    "00111101011101110110110001000011",
    "00111101000011010001001111110010",
    "00100101101010011011111001111011",
    "01011111010011001110000101111110",
    "01011100000100001110111011001111",
    "00111010101000001110101110101111",
    "00101011110101011001100110001011",
    "01011100011001010011011111111011",
    "00111101111011110001100001010111",
    "01011101001000010101110011101011",
    "00110110000000110000011101101000",
    "00110100110001101100010100110001",
    "00111110111110000011110010010110",
    "00111101001110000001010000001011",
    "00111011000010011111011010010011",
    "01010001001011111001100011010100",
    "01000111010101011000010000110110",
    "01011110100000010010011000000010",
    "00100011111110000100110010110010",
    "00100100110100000011001111010110",
    "00101100101111000111010110000111",
    "00100110110001011010111111110001",
    "00110101111011010100101011001000",
    "01000110001001011111010111010001",
    "00100100010111110101111000010001",
    "01000001110101100111100111000010",
    "00110001100000100011101010011110",
    "00110110101001001110100011010011",
    "01001110110101011000100011001010",
    "01000101000111100111100000011011",
    "00101111110011001001100111000100",
    "01011101100101101111010010001111",
    "01011010001011011101001001000011",
    "00110000000110101000010000111111",
    "00111110101110010010110011100101",
    "01001100011100110100100100000101",
    "00101100011001110001110000101111",
    "00101010001001001010101111010010",
    "01011011011011101011101101011111",
    "00101000000100110000111110101101",
    "00101001101101100011111110111111",
    "00111101111000000100010100010110",
    "01000100011101001011001100110111",
    "01000111110001110001101010100000",
    "01010100111111110010010111100010",
    "01001000010011011111010110011100",
    "00100001111010001000101000010101",
    "01011101010101010011100111111110",
    "00111000111010101100000010111110",
    "00101101100110111000000010010010",
    "00110010101000101100101000100111",
    "01010100101010100011100010001101",
    "01010000000100111101111010001110",
    "01001000000000101111010001101110");

  signal rom_addr: std_logic_vector(7 downto 0) := (others=>'0');
  signal input: std_logic_vector(31 downto 0) := (others=>'0');
  signal result1: std_logic_vector(31 downto 0);
  signal result2: std_logic_vector(31 downto 0);
  signal count: std_logic_vector(3 downto 0) := "0000";
  signal errorcount: std_logic_vector(7 downto 0) := "00000000";
  signal go : std_logic := '0';
  constant wtime : std_logic_vector(15 downto 0) := x"362C";
  signal writestate : std_logic_vector(3 downto 0) := "1001";
  signal writecountdown : std_logic_vector(15 downto 0) := (others=>'0');
  signal writebuf : std_logic_vector(7 downto 0);

  component fsqrt
  Port (
    clk    : in  STD_LOGIC;
    input  : in  STD_LOGIC_VECTOR (31 downto 0);
    output : out STD_LOGIC_VECTOR (31 downto 0));
  end component;

begin
  clk0: clock port map(    
      CLKIN_IN        => MCLK1, 
      RST_IN          => '0', 
      CLKFX_OUT       => clk);

  squareroot: fsqrt port map(
    clk    => clk,
    input  => input,
    output => result1);

  test : process(clk)
  begin
    if rising_edge(clk) then

      result2 <= result1;

      if count < "0100" then
        input <= input_data(conv_integer(rom_addr));
        rom_addr <= rom_addr + 1;
        count <= count + 1;

      elsif count = "0100" then
        if rom_addr = 99 then
          count <= "0101";
        end if;
        if answer_data(conv_integer(rom_addr) - 4) /= result2 then
          errorcount <= errorcount + 1;
        end if;
        input <= input_data(conv_integer(rom_addr));
        rom_addr <= rom_addr + 1;
        
      elsif count < "1001"  then
        if answer_data(conv_integer(rom_addr) - 4) /= result2 then
          errorcount <= errorcount + 1;
        end if;
        rom_addr <= rom_addr + 1;
        count <= count + 1;
      elsif count = "1001" then
        go <= '1';
        count <= "1111";
      end if;


      if writestate = "1001" then
        if go = '1' then
          RS_TX <= '0';
          writebuf <= errorcount;
          writestate <= "0000";
          writecountdown <= wtime;
        else
          RS_TX <= '1';
        end if;
      elsif writestate = "1000" then
        if writecountdown = 0 then
          RS_TX <= '1';
          writestate <= "1001";
          go <= '0';
        else
          writecountdown <= writecountdown - 1;
        end if;
      else
        if writecountdown = 0 then
          RS_TX <= writebuf(0);
          writebuf <= '1' & writebuf(7 downto 1);
          writecountdown <= wtime;
          writestate <= writestate + 1;
        else
          writecountdown <= writecountdown - 1;
        end if;
      end if;

    end if;
  end process;

end fpu4;
