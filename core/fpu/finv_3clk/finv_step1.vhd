library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity finv_step1 is
  Port (
    input   : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0);
    addr    : out STD_LOGIC_VECTOR (9 downto 0);
    flag    : out STD_LOGIC);
end finv_step1;

architecture struct of finv_step1 is

  signal tmp_sign : std_logic;
  signal tmp_expo : std_logic_vector(7 downto 0);
  signal tmp_frac : std_logic_vector(22 downto 0);

begin

  addr <= input(22 downto 13);

  tmp_sign <= input(31);
  tmp_expo <= input(30 downto 23);
  tmp_frac <= input(22 downto 0);

  output  <= input when (tmp_expo = x"FF") and (tmp_frac > 0) else
             tmp_sign & x"FF" & "00000000000000000000000" when tmp_expo = x"00" else
             tmp_sign & "0000000000000000000000000000000" when (tmp_expo > x"FD") or ((tmp_expo = x"FD") and (tmp_frac > 0)) else
             tmp_sign & x"01" & "00000000000000000000000" when tmp_expo = x"FD" else
             input;

  flag  <= '1' when (tmp_expo >= x"FD") or (tmp_expo = x"00") else
           '0';

end struct;

