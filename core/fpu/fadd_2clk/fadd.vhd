library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fadd is
  Port (
    clk     : in  STD_LOGIC;
    input1  : in  STD_LOGIC_VECTOR (31 downto 0);
    input2  : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0));
end fadd;

architecture struct of fadd is

  function shift_r(s : std_logic_vector(23 downto 0); k : std_logic_vector(7 downto 0))
    return std_logic_vector
  is
    variable t : std_logic_vector(23 downto 0);
  begin
    case k is
      when "00000000" => t := s;
      when "00000001" => t := "0" & s(23 downto 1);
      when "00000010" => t := "00" & s(23 downto 2);
      when "00000011" => t := "000" & s(23 downto 3);
      when "00000100" => t := "0000" & s(23 downto 4);
      when "00000101" => t := "00000" & s(23 downto 5);
      when "00000110" => t := "000000" & s(23 downto 6);
      when "00000111" => t := "0000000" & s(23 downto 7);
      when "00001000" => t := "00000000" & s(23 downto 8);
      when "00001001" => t := "000000000" & s(23 downto 9);
      when "00001010" => t := "0000000000" & s(23 downto 10);
      when "00001011" => t := "00000000000" & s(23 downto 11);
      when "00001100" => t := "000000000000" & s(23 downto 12);
      when "00001101" => t := "0000000000000" & s(23 downto 13);
      when "00001110" => t := "00000000000000" & s(23 downto 14);
      when "00001111" => t := "000000000000000" & s(23 downto 15);
      when "00010000" => t := "0000000000000000" & s(23 downto 16);
      when "00010001" => t := "00000000000000000" & s(23 downto 17);
      when "00010010" => t := "000000000000000000" & s(23 downto 18);
      when "00010011" => t := "0000000000000000000" & s(23 downto 19);
      when "00010100" => t := "00000000000000000000" & s(23 downto 20);
      when "00010101" => t := "000000000000000000000" & s(23 downto 21);
      when "00010110" => t := "0000000000000000000000" & s(23 downto 22);
      when "00010111" => t := "00000000000000000000000" & s(23);
      when others     => t := "000000000000000000000000";
    end case;
    return t;
  end shift_r;

  function step1(input1 : std_logic_vector(31 downto 0); input2 : std_logic_vector(31 downto 0))
    return std_logic_vector
  is
    variable way            : std_logic;
    variable w_sign         : std_logic;
    variable is_sub         : std_logic;
    variable tmp_expo       : std_logic_vector (7 downto 0);
    variable expodiff       : std_logic_vector (7 downto 0);
    variable shifted_frac_a : std_logic_vector (23 downto 0);
    variable w_frac_a       : std_logic_vector (22 downto 0);
    variable w_frac_b       : std_logic_vector (22 downto 0);
    variable l_frac_b       : std_logic_vector (22 downto 0);
    variable shifted_frac_b : std_logic_vector (24 downto 0);
    variable tmp_frac_b     : std_logic_vector (24 downto 0);
    variable step1_out      : std_logic_vector (82 downto 0);

  begin

    if input1(30 downto 23) > input2(30 downto 23) then
      expodiff := input1(30 downto 23) - input2(30 downto 23);
      tmp_expo := input1(30 downto 23);
      w_frac_a := input1(22 downto 0);
      shifted_frac_a := shift_r('1' & input2(22 downto 0),expodiff);
    else
      expodiff := input2(30 downto 23) - input1(30 downto 23);
      tmp_expo := input2(30 downto 23);
      w_frac_a := input2(22 downto 0);
      shifted_frac_a := shift_r('1' & input1(22 downto 0),expodiff);
    end if;

    if input1(30 downto 0) > input2(30 downto 0) then
      w_sign := input1(31);
      w_frac_b := input1(22 downto 0);
      l_frac_b := input2(22 downto 0);
    else
      w_sign := input2(31);
      w_frac_b := input2(22 downto 0);
      l_frac_b := input1(22 downto 0);
    end if;

    if input1(23) = input2(23) then
      shifted_frac_b := '1' & l_frac_b(22 downto 0) & '0';
    else 
      shifted_frac_b := "01" & l_frac_b(22 downto 0);
    end if;

    tmp_frac_b := ('1' & w_frac_b & '0') - shifted_frac_b;

    is_sub := input1(31) xor input2(31);

    if (expodiff(7 downto 1) = "0000000") and (is_sub = '1') then
      way := '1';
    else
      way := '0';
    end if;

    step1_out := way & w_sign & is_sub & w_frac_a & shifted_frac_a & tmp_expo & tmp_frac_b;
    return step1_out;

  end step1;


  function step2a(step2_in : std_logic_vector(55 downto 0))
    return std_logic_vector
  is
    variable a_tmp_frac : std_logic_vector (24 downto 0);
    variable a_expo     : std_logic_vector (7 downto 0);
    variable a_frac     : std_logic_vector (22 downto 0);
    variable s_tmp_frac : std_logic_vector (23 downto 0);
    variable s_expo     : std_logic_vector (7 downto 0);
    variable s_frac     : std_logic_vector (22 downto 0);
    variable result     : std_logic_vector (30 downto 0);
  begin
    a_tmp_frac := ("01" & step2_in(54 downto 32)) + ("0" & step2_in(31 downto 8));
    s_tmp_frac := ("1" & step2_in(54 downto 32)) - step2_in(31 downto 8);
    
    if a_tmp_frac(24) = '0' then
      a_frac := a_tmp_frac(22 downto 0);
      a_expo := step2_in(7 downto 0);
    else
      a_frac := a_tmp_frac(23 downto 1);
      a_expo := step2_in(7 downto 0) + 1;
    end if;

    if s_tmp_frac(23) = '1' then
      s_frac := s_tmp_frac(22 downto 0);
      s_expo := step2_in(7 downto 0);
    else
      s_frac := s_tmp_frac(21 downto 0) & '0';
      s_expo := step2_in(7 downto 0) - 1;
    end if;

    if step2_in(55) = '0' then
      result := a_expo & a_frac;
    else
      result := s_expo & s_frac;
    end if;

    return result;
  end step2a;

  function step2b(step2b_in : std_logic_vector(32 downto 0))
    return std_logic_vector
  is
    variable count  : std_logic_vector (4 downto 0);
    variable expo   : std_logic_vector (7 downto 0);
    variable frac   : std_logic_vector (22 downto 0);
    variable result : std_logic_vector (30 downto 0);
  begin
    if step2b_in(24) = '1' then
      frac  := step2b_in(23 downto 1);
      count := "00000";
    elsif step2b_in(23) = '1' then
      frac  := step2b_in(22 downto 0);
      count := "00001";
    elsif step2b_in(22) = '1' then
      frac  := step2b_in(21 downto 0) & "0";
      count := "00010";
    elsif step2b_in(21) = '1' then
      frac  := step2b_in(20 downto 0) & "00";
      count := "00011";
    elsif step2b_in(20) = '1' then
      frac  := step2b_in(19 downto 0) & "000";
      count := "00100";
    elsif step2b_in(19) = '1' then
      frac  := step2b_in(18 downto 0) & "0000";
      count := "00101";
    elsif step2b_in(18) = '1' then
      frac  := step2b_in(17 downto 0) & "00000";
      count := "00110";
    elsif step2b_in(17) = '1' then
      frac  := step2b_in(16 downto 0) & "000000";
      count := "00111";
    elsif step2b_in(16) = '1' then
      frac  := step2b_in(15 downto 0) & "0000000";
      count := "01000";
    elsif step2b_in(15) = '1' then
      frac  := step2b_in(14 downto 0) & "00000000";
      count := "01001";
    elsif step2b_in(14) = '1' then
      frac  := step2b_in(13 downto 0) & "000000000";
      count := "01010";
    elsif step2b_in(13) = '1' then
      frac  := step2b_in(12 downto 0) & "0000000000";
      count := "01011";
    elsif step2b_in(12) = '1' then
      frac  := step2b_in(11 downto 0) & "00000000000";
      count := "01100";
    elsif step2b_in(11) = '1' then
      frac  := step2b_in(10 downto 0)  & "000000000000";
      count := "01101";
    elsif step2b_in(10) = '1' then
      frac  := step2b_in(9 downto 0)  & "0000000000000";
      count := "01110";
    elsif step2b_in(9) = '1' then
      frac  := step2b_in(8 downto 0)  & "00000000000000";
      count := "01111";
    elsif step2b_in(8) = '1' then
      frac  := step2b_in(7 downto 0)  & "000000000000000";
      count := "10000";
    elsif step2b_in(7) = '1' then
      frac  := step2b_in(6 downto 0)  & "0000000000000000";
      count := "10001";
    elsif step2b_in(6) = '1' then
      frac  := step2b_in(5 downto 0)  & "00000000000000000";
      count := "10010";
    elsif step2b_in(5) = '1' then
      frac  := step2b_in(4 downto 0)  & "000000000000000000";
      count := "10011";
    elsif step2b_in(4) = '1' then
      frac  := step2b_in(3 downto 0)  & "0000000000000000000";
      count := "10100";
    elsif step2b_in(3) = '1' then
      frac  := step2b_in(2 downto 0)  & "00000000000000000000";
      count := "10101";
    elsif step2b_in(2) = '1' then
      frac  := step2b_in(1 downto 0)  & "000000000000000000000";
      count := "10110";
    elsif step2b_in(1) = '1' then
      frac  := step2b_in(0 downto 0)  & "0000000000000000000000";
      count := "10111";
    elsif step2b_in(0) = '1' then
      frac  := "00000000000000000000000";
      count := "11000";
    else
      frac  := "00000000000000000000000";
      count := "11100";
    end if;

    if (count(4 downto 2) = "111") or (count>step2b_in(32 downto 25)) then
      expo := x"00";
    else
      expo := step2b_in(32 downto 25) - count;
    end if;

    result := expo & frac;

    return result;
  end step2b;


  signal way       : std_logic;
  signal w_sign    : std_logic;
  signal step1_out : std_logic_vector (82 downto 0);
  signal step2_in  : std_logic_vector (80 downto 0);
  signal expofrac  : std_logic_vector (30 downto 0);

begin

  step1_out <= step1(input1,input2);

  expofrac  <= step2a(step2_in(80 downto 25)) when way = '0' else
               step2b(step2_in(32 downto 0));

  output    <= w_sign & expofrac;

  floatadd : process(clk)
  begin
    if rising_edge(clk) then

      way       <= step1_out(82);
      w_sign    <= step1_out(81);
      step2_in  <= step1_out(80 downto 0);

    end if;
  end process;
    
end struct;


