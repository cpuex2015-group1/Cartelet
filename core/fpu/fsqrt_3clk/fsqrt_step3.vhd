library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fsqrt_step3 is
  Port (
    input  : in STD_LOGIC_VECTOR (31 downto 0);
    flag   : in STD_LOGIC;
    var    : in STD_LOGIC_VECTOR (13 downto 0);
    data1  : in STD_LOGIC_VECTOR (22 downto 0);
    output : out STD_LOGIC_VECTOR (31 downto 0));
end fsqrt_step3;

architecture struct of fsqrt_step3 is

  signal expo : std_logic_vector(7 downto 0);
  signal frac : std_logic_vector(22 downto 0);

begin

  expo <= ('0' & input(30 downto 24)) + x"40"  when input(23) = '1' else
          ('0' & input(30 downto 24)) + x"3F";

  frac <= data1 + ("000000000" & var) when input(23) = '0' else
          data1 + ("0000000000" & var(13 downto 1));

  output <= input when flag = '1' else
            '0' & expo & frac;

end struct;

