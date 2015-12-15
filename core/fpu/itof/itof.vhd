library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity itof is
  Port (
    clk     : in  STD_LOGIC;
    input   : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0));
end itof;

architecture struct of itof is

  function step1(input : std_logic_vector(31 downto 0))
    return std_logic_vector
  is
    variable minus_input : std_logic_vector (31 downto 0);
    variable count       : std_logic_vector (5 downto 0);
    variable tmp_frac1   : std_logic_vector (31 downto 0);
    variable step1_out   : std_logic_vector (37 downto 0);
  begin
    minus_input(31) := '0';
    minus_input(30) := not input(30);
    minus_input(29) := not input(29);
    minus_input(28) := not input(28);
    minus_input(27) := not input(27);
    minus_input(26) := not input(26);
    minus_input(25) := not input(25);
    minus_input(24) := not input(24);
    minus_input(23) := not input(23);
    minus_input(22) := not input(22);
    minus_input(21) := not input(21);
    minus_input(20) := not input(20);
    minus_input(19) := not input(19);
    minus_input(18) := not input(18);
    minus_input(17) := not input(17);
    minus_input(16) := not input(16);
    minus_input(15) := not input(15);
    minus_input(14) := not input(14);
    minus_input(13) := not input(13);
    minus_input(12) := not input(12);
    minus_input(11) := not input(11);
    minus_input(10) := not input(10);
    minus_input(9) := not input(9);
    minus_input(8) := not input(8);
    minus_input(7) := not input(7);
    minus_input(6) := not input(6);
    minus_input(5) := not input(5);
    minus_input(4) := not input(4);
    minus_input(3) := not input(3);
    minus_input(2) := not input(2);
    minus_input(1) := not input(1);
    minus_input(0) := not input(0);
    minus_input := minus_input + 1;

    if input(31) = '0' then
      tmp_frac1 := input;
    else
      tmp_frac1 := minus_input;
    end if;

    if tmp_frac1(31) = '1' then
      count := "000000";
    elsif tmp_frac1(30) = '1' then
      count := "000001";
    elsif tmp_frac1(29) = '1' then
      count := "000010";
    elsif tmp_frac1(28) = '1' then
      count := "000011";
    elsif tmp_frac1(27) = '1' then
      count := "000100";
    elsif tmp_frac1(26) = '1' then
      count := "000101";
    elsif tmp_frac1(25) = '1' then
      count := "000110";
    elsif tmp_frac1(24) = '1' then
      count := "000111";
    elsif tmp_frac1(23) = '1' then
      count := "001000";
    elsif tmp_frac1(22) = '1' then
      count := "001001";
    elsif tmp_frac1(21) = '1' then
      count := "001010";
    elsif tmp_frac1(20) = '1' then
      count := "001011";
    elsif tmp_frac1(19) = '1' then
      count := "001100";
    elsif tmp_frac1(18) = '1' then
      count := "001101";
    elsif tmp_frac1(17) = '1' then
      count := "001110";
    elsif tmp_frac1(16) = '1' then
      count := "001111";
    elsif tmp_frac1(15) = '1' then
      count := "010000";
    elsif tmp_frac1(14) = '1' then
      count := "010001";
    elsif tmp_frac1(13) = '1' then
      count := "010010";
    elsif tmp_frac1(12) = '1' then
      count := "010011";
    elsif tmp_frac1(11) = '1' then
      count := "010100";
    elsif tmp_frac1(10) = '1' then
      count := "010101";
    elsif tmp_frac1(9) = '1' then
      count := "010110";
    elsif tmp_frac1(8) = '1' then
      count := "010111";
    elsif tmp_frac1(7) = '1' then
      count := "011000";
    elsif tmp_frac1(6) = '1' then
      count := "011001";
    elsif tmp_frac1(5) = '1' then
      count := "011010";
    elsif tmp_frac1(4) = '1' then
      count := "011011";
    elsif tmp_frac1(3) = '1' then
      count := "011100";
    elsif tmp_frac1(2) = '1' then
      count := "011101";
    elsif tmp_frac1(1) = '1' then
      count := "011110";
    elsif tmp_frac1(0) = '1' then
      count := "011111";
    else
      count := "100000";
    end if;

    step1_out := input(31) & count & tmp_frac1(30 downto 0);

    return step1_out;

  end step1;


  function step2(step2_in : std_logic_vector(36 downto 0))
    return std_logic_vector
  is
    variable tmp_expo  : std_logic_vector (7 downto 0);  
    variable tmp_frac2 : std_logic_vector (23 downto 0);
    variable tmp_frac3 : std_logic_vector (23 downto 0);
    variable expo      : std_logic_vector (7 downto 0);
    variable frac      : std_logic_vector (22 downto 0);
    variable result    : std_logic_vector (30 downto 0);
  begin

    if step2_in(36) = '1' then
      tmp_expo := x"00";
    else
      tmp_expo := x"9E" - step2_in(35 downto 31);
    end if;

    case step2_in(35 downto 31) is
      when "00000" => tmp_frac2 := step2_in(30 downto 7);
      when "00001" => tmp_frac2 := step2_in(29 downto 6);
      when "00010" => tmp_frac2 := step2_in(28 downto 5);
      when "00011" => tmp_frac2 := step2_in(27 downto 4);
      when "00100" => tmp_frac2 := step2_in(26 downto 3);
      when "00101" => tmp_frac2 := step2_in(25 downto 2);
      when "00110" => tmp_frac2 := step2_in(24 downto 1);
      when "00111" => tmp_frac2 := step2_in(23 downto 0);
      when "01000" => tmp_frac2 := step2_in(22 downto 0) & "0";
      when "01001" => tmp_frac2 := step2_in(21 downto 0) & "00";
      when "01010" => tmp_frac2 := step2_in(20 downto 0) & "000";
      when "01011" => tmp_frac2 := step2_in(19 downto 0) & "0000";
      when "01100" => tmp_frac2 := step2_in(18 downto 0) & "00000";
      when "01101" => tmp_frac2 := step2_in(17 downto 0) & "000000";
      when "01110" => tmp_frac2 := step2_in(16 downto 0) & "0000000";
      when "01111" => tmp_frac2 := step2_in(15 downto 0) & "00000000";
      when "10000" => tmp_frac2 := step2_in(14 downto 0) & "000000000";
      when "10001" => tmp_frac2 := step2_in(13 downto 0) & "0000000000";
      when "10010" => tmp_frac2 := step2_in(12 downto 0) & "00000000000";
      when "10011" => tmp_frac2 := step2_in(11 downto 0) & "000000000000";
      when "10100" => tmp_frac2 := step2_in(10 downto 0) & "0000000000000";
      when "10101" => tmp_frac2 := step2_in(9 downto 0) & "00000000000000";
      when "10110" => tmp_frac2 := step2_in(8 downto 0) & "000000000000000";
      when "10111" => tmp_frac2 := step2_in(7 downto 0) & "0000000000000000";
      when "11000" => tmp_frac2 := step2_in(6 downto 0) & "00000000000000000";
      when "11001" => tmp_frac2 := step2_in(5 downto 0) & "000000000000000000";
      when "11010" => tmp_frac2 := step2_in(4 downto 0) & "0000000000000000000";
      when "11011" => tmp_frac2 := step2_in(3 downto 0) & "00000000000000000000";
      when "11100" => tmp_frac2 := step2_in(2 downto 0) & "000000000000000000000";
      when "11101" => tmp_frac2 := step2_in(1 downto 0) & "0000000000000000000000";
      when "11110" => tmp_frac2 := step2_in(0 downto 0) & "00000000000000000000000";
      when others  => tmp_frac2 := "000000000000000000000000";
    end case;


    if tmp_frac2(0) = '1' then
      tmp_frac3 := ("0" &tmp_frac2(23 downto 1)) + 1;
    else
      tmp_frac3 := '0' & tmp_frac2(23 downto 1);
    end if;

    if tmp_frac3(23) = '1' then
      expo := tmp_expo + 1;
    else
      expo := tmp_expo;
    end if;

    frac := tmp_frac3(22 downto 0);

    result := expo & frac;

    return result;
  end step2;


  signal sign      : std_logic;
  signal step1_out : std_logic_vector (37 downto 0);
  signal step2_in  : std_logic_vector (36 downto 0);

begin

  step1_out <= step1(input);
  output    <= sign & step2(step2_in);

  inttofloat : process(clk)
  begin
    if rising_edge(clk) then

      sign      <= step1_out(37);
      step2_in  <= step1_out(36 downto 0);

    end if;
  end process;
    
end struct;

