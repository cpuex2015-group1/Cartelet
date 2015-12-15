library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity finv_step3 is
  Port (
    input  : in STD_LOGIC_VECTOR (31 downto 0);
    flag   : in STD_LOGIC;
    var    : in STD_LOGIC_VECTOR (13 downto 0);
    data1  : in STD_LOGIC_VECTOR (22 downto 0);
    output : out STD_LOGIC_VECTOR (31 downto 0));
end finv_step3;

architecture struct of finv_step3 is

  signal expo : std_logic_vector(7 downto 0);
  signal frac : std_logic_vector(22 downto 0);

begin

  frac <= data1 - ("000000000" & var);      --unsigned??
  expo <= x"FD" - input(30 downto 23);      --unsigned??
  output <= input when flag = '1' else
            input(31) & expo & frac;

end struct;

