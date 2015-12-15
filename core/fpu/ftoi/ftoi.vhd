library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ftoi is
  Port (
    clk     : in  STD_LOGIC;
    input   : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0));
end ftoi;

architecture struct of ftoi is

  function step1(input : std_logic_vector(31 downto 0))
    return std_logic_vector
  is
    variable shift       : std_logic_vector (7 downto 0);
    variable tmp_frac    : std_logic_vector (31 downto 0);
    variable step1_out   : std_logic_vector (32 downto 0);
  begin
    shift := x"9D" - input(30 downto 23);

    case shift is
      when "00000000" => tmp_frac := "1" & input(22 downto 0) & "00000000";
      when "00000001" => tmp_frac := "01" & input(22 downto 0) & "0000000"; 
      when "00000010" => tmp_frac := "001" & input(22 downto 0) & "000000";
      when "00000011" => tmp_frac := "0001" & input(22 downto 0) & "00000";
      when "00000100" => tmp_frac := "00001" & input(22 downto 0) & "0000";
      when "00000101" => tmp_frac := "000001" & input(22 downto 0) & "000";
      when "00000110" => tmp_frac := "0000001" & input(22 downto 0) & "00";
      when "00000111" => tmp_frac := "00000001" & input(22 downto 0) & "0";
      when "00001000" => tmp_frac := "000000001" & input(22 downto 0);
      when "00001001" => tmp_frac := "0000000001" & input(22 downto 1);
      when "00001010" => tmp_frac := "00000000001" & input(22 downto 2);
      when "00001011" => tmp_frac := "000000000001" & input(22 downto 3);
      when "00001100" => tmp_frac := "0000000000001" & input(22 downto 4);
      when "00001101" => tmp_frac := "00000000000001" & input(22 downto 5);
      when "00001110" => tmp_frac := "000000000000001" & input(22 downto 6);
      when "00001111" => tmp_frac := "0000000000000001" & input(22 downto 7);
      when "00010000" => tmp_frac := "00000000000000001" & input(22 downto 8);
      when "00010001" => tmp_frac := "000000000000000001" & input(22 downto 9);
      when "00010010" => tmp_frac := "0000000000000000001" & input(22 downto 10);
      when "00010011" => tmp_frac := "00000000000000000001" & input(22 downto 11);
      when "00010100" => tmp_frac := "000000000000000000001" & input(22 downto 12);
      when "00010101" => tmp_frac := "0000000000000000000001" & input(22 downto 13);
      when "00010110" => tmp_frac := "00000000000000000000001" & input(22 downto 14);
      when "00010111" => tmp_frac := "000000000000000000000001" & input(22 downto 15);
      when "00011000" => tmp_frac := "0000000000000000000000001" & input(22 downto 16);
      when "00011001" => tmp_frac := "00000000000000000000000001" & input(22 downto 17);
      when "00011010" => tmp_frac := "000000000000000000000000001" & input(22 downto 18);
      when "00011011" => tmp_frac := "0000000000000000000000000001" & input(22 downto 19);
      when "00011100" => tmp_frac := "00000000000000000000000000001" & input(22 downto 20);
      when "00011101" => tmp_frac := "000000000000000000000000000001" & input(22 downto 21);
      when "00011110" => tmp_frac := "0000000000000000000000000000001" & input(22 downto 22);
      when "00011111" => tmp_frac := "00000000000000000000000000000001";
      when others     => tmp_frac := "00000000000000000000000000000000";
    end case;

    step1_out := input(31) & tmp_frac;

    return step1_out;

  end step1;


  function step2(step2_in : std_logic_vector(32 downto 0))
    return std_logic_vector
  is
    variable u_int     : std_logic_vector (30 downto 0);
    variable minus     : std_logic_vector (31 downto 0);
    variable result    : std_logic_vector (31 downto 0);
  begin

    if step2_in(0) = '1' then
      u_int := step2_in(31 downto 1) + 1;
    else
      u_int := step2_in(31 downto 1);
    end if;

    minus(31) := '1';
    minus(30) := not u_int(30);
    minus(29) := not u_int(29);
    minus(28) := not u_int(28);
    minus(27) := not u_int(27);
    minus(26) := not u_int(26);
    minus(25) := not u_int(25);
    minus(24) := not u_int(24);
    minus(23) := not u_int(23);
    minus(22) := not u_int(22);
    minus(21) := not u_int(21);
    minus(20) := not u_int(20);
    minus(19) := not u_int(19);
    minus(18) := not u_int(18);
    minus(17) := not u_int(17);
    minus(16) := not u_int(16);
    minus(15) := not u_int(15);
    minus(14) := not u_int(14);
    minus(13) := not u_int(13);
    minus(12) := not u_int(12);
    minus(11) := not u_int(11);
    minus(10) := not u_int(10);
    minus(9) := not u_int(9);
    minus(8) := not u_int(8);
    minus(7) := not u_int(7);
    minus(6) := not u_int(6);
    minus(5) := not u_int(5);
    minus(4) := not u_int(4);
    minus(3) := not u_int(3);
    minus(2) := not u_int(2);
    minus(1) := not u_int(1);
    minus(0) := not u_int(0);
    minus := minus + 1;

    if step2_in(32) = '0' then
      result := '0' & u_int;
    else
      result := minus;
    end if;

    return result;
  end step2;

  signal step1_out : std_logic_vector (32 downto 0);
  signal step2_in  : std_logic_vector (32 downto 0);

begin

  step1_out <= step1(input);
  output    <= step2(step2_in);

  floattoint : process(clk)
  begin
    if rising_edge(clk) then
      step2_in  <= step1_out;
    end if;
  end process;
    
end struct;


