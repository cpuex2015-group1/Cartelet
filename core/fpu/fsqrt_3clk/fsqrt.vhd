library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fsqrt is
  Port (
    clk     : in  STD_LOGIC;
    input   : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0));
end fsqrt;

architecture struct of fsqrt is

  component fsqrt_step1 
    Port (
      input   : in  STD_LOGIC_VECTOR (31 downto 0);
      output  : out STD_LOGIC_VECTOR (31 downto 0);
      addr    : out STD_LOGIC_VECTOR (9 downto 0);
      flag    : out STD_LOGIC);
  end component;

  component fsqrt_step2 is
    Port (
      input     : in  STD_LOGIC_VECTOR (31 downto 0);
      flag_in   : in  STD_LOGIC;
      data1_in  : in  STD_LOGIC_VECTOR (22 downto 0);
      data2     : in  STD_LOGIC_VECTOR (12 downto 0);
      output    : out STD_LOGIC_VECTOR (31 downto 0);
      flag_out  : out STD_LOGIC;
      var       : out STD_LOGIC_VECTOR (13 downto 0);
      data1_out : out STD_LOGIC_VECTOR (22 downto 0));
  end component;

  component fsqrt_step3 is
    Port (
      input  : in STD_LOGIC_VECTOR (31 downto 0);
      flag   : in STD_LOGIC;
      var    : in STD_LOGIC_VECTOR (13 downto 0);
      data1  : in STD_LOGIC_VECTOR (22 downto 0);
      output : out STD_LOGIC_VECTOR (31 downto 0));
  end component;

  component fsqrt_table1 
    Port (
      clka  : IN STD_LOGIC;
      wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      dina  : IN STD_LOGIC_VECTOR(22 DOWNTO 0);
      douta : OUT STD_LOGIC_VECTOR(22 DOWNTO 0));
  end component;

  component fsqrt_table2
    Port (
      clka  : IN STD_LOGIC;
      wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      dina  : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
      douta : OUT STD_LOGIC_VECTOR(12 DOWNTO 0));
  end component;

  signal inout1_out  : STD_LOGIC_VECTOR (31 downto 0);
  signal inout2_in   : STD_LOGIC_VECTOR (31 downto 0);
  signal inout2_out  : STD_LOGIC_VECTOR (31 downto 0);
  signal inout3_in   : STD_LOGIC_VECTOR (31 downto 0);
  signal flag1_out   : STD_LOGIC;
  signal flag2_in    : STD_LOGIC;
  signal flag2_out   : STD_LOGIC;
  signal flag3_in    : STD_LOGIC;
  signal data1_2_out : STD_LOGIC_VECTOR (22 downto 0);
  signal data1_3_in  : STD_LOGIC_VECTOR (22 downto 0);
  signal var2_out    : STD_LOGIC_VECTOR (13 downto 0);
  signal var3_in     : STD_LOGIC_VECTOR (13 downto 0);

  signal addr        : STD_LOGIC_VECTOR (9  downto 0);
  signal data1       : STD_LOGIC_VECTOR (22 downto 0);
  signal data2       : STD_LOGIC_VECTOR (12 downto 0);

begin

  table1 : fsqrt_table1 PORT MAP (
      clka  => clk,
      wea   => "0",
      addra => addr,
      dina  => "00000000000000000000000",
      douta => data1);

  table2 : fsqrt_table2 PORT MAP (
      clka  => clk,
      wea   => "0",
      addra => addr,
      dina  => "0000000000000",
      douta => data2);

  step1 : fsqrt_step1 PORT MAP (
      input     => input,
      output    => inout1_out,
      addr      => addr,
      flag      => flag1_out);

  step2 : fsqrt_step2 PORT MAP (
      input     => inout2_in,
      flag_in   => flag2_in,
      data1_in  => data1,
      data2     => data2,
      output    => inout2_out, 
      flag_out  => flag2_out,
      var       => var2_out, 
      data1_out => data1_2_out);

  step3 : fsqrt_step3 PORT MAP (
      input     => inout3_in, 
      flag      => flag3_in,
      var       => var3_in,
      data1     => data1_3_in,
      output    => output);

  squareroot : process(clk)
  begin
    if rising_edge(clk) then

      inout2_in  <= inout1_out;
      inout3_in  <= inout2_out;
      flag2_in   <= flag1_out;
      flag3_in   <= flag2_out;
      data1_3_in <= data1_2_out;
      var3_in    <= var2_out;

    end if;
  end process;

end struct;


