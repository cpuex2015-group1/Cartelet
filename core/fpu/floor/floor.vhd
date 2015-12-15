library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity floor is
  Port (
    clk     : in  STD_LOGIC;
    input   : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0));
end floor;

architecture struct of floor is

  function step1(input : std_logic_vector(31 downto 0))
    return std_logic_vector
  is
    variable tmp        : std_logic_vector (7 downto 0);
    variable count      : std_logic_vector (4 downto 0);
    variable flag       : std_logic_vector (1 downto 0);
    variable tmp_result : std_logic_vector (31 downto 0);
    variable step1_out  : std_logic_vector (38 downto 0);
  begin
    tmp := 149 - input(30 downto 23);

    if input(0) = '1' then
      count := "00000";
    elsif input(1) = '1' then
      count := "00001";
    elsif input(2) = '1' then
      count := "00010";
    elsif input(3) = '1' then
      count := "00011";
    elsif input(4) = '1' then
      count := "00100";
    elsif input(5) = '1' then
      count := "00101";
    elsif input(6) = '1' then
      count := "00110";
    elsif input(7) = '1' then
      count := "00111";
    elsif input(8) = '1' then
      count := "01000";
    elsif input(9) = '1' then
      count := "01001";
    elsif input(10) = '1' then
      count := "01010";
    elsif input(11) = '1' then
      count := "01011";
    elsif input(12) = '1' then
      count := "01100";
    elsif input(13) = '1' then
      count := "01101";
    elsif input(14) = '1' then
      count := "01110";
    elsif input(15) = '1' then
      count := "01111";
    elsif input(16) = '1' then
      count := "10000";
    elsif input(17) = '1' then
      count := "10001";
    elsif input(18) = '1' then
      count := "10010";
    elsif input(19) = '1' then
      count := "10011";
    elsif input(20) = '1' then
      count := "10100";
    elsif input(21) = '1' then
      count := "10101";
    elsif input(22) = '1' then
      count := "10110";
    else
      count := "10111";
    end if;

    if input(30 downto 23) = x"00" then
      flag := "00";
    elsif input(30 downto 23) < 127 then
      if input(31) = '0' then
        flag := "10";
      else
        flag := "11";
      end if;
    elsif input(30 downto 23) > 149 then
      flag := "00";
    elsif count > tmp(4 downto 0) then
      flag := "00";
    else
      flag := "01";
    end if;

    if flag = "10" then
      tmp_result := x"00000000";
    elsif flag = "11" then
      tmp_result := x"BF800000";
    else
      tmp_result := input;
    end if;
   
    step1_out := flag & tmp(4 downto 0) & tmp_result;

    return step1_out;

  end step1;


  function step2(step2_in : std_logic_vector(38 downto 0))
    return std_logic_vector
  is
    variable tmp_frac     : std_logic_vector (22 downto 0);
    variable tmp_expofrac : std_logic_vector (30 downto 0);
    variable result       : std_logic_vector (31 downto 0);
  begin

    case step2_in(36 downto 32) is
      when "00000" => tmp_frac := step2_in(22 downto 1) & "0";
      when "00001" => tmp_frac := step2_in(22 downto 2) & "00";
      when "00010" => tmp_frac := step2_in(22 downto 3) & "000";
      when "00011" => tmp_frac := step2_in(22 downto 4) & "0000";
      when "00100" => tmp_frac := step2_in(22 downto 5) & "00000";
      when "00101" => tmp_frac := step2_in(22 downto 6) & "000000";
      when "00110" => tmp_frac := step2_in(22 downto 7) & "0000000";
      when "00111" => tmp_frac := step2_in(22 downto 8) & "00000000";
      when "01000" => tmp_frac := step2_in(22 downto 9) & "000000000";
      when "01001" => tmp_frac := step2_in(22 downto 10) & "0000000000";
      when "01010" => tmp_frac := step2_in(22 downto 11) & "00000000000";
      when "01011" => tmp_frac := step2_in(22 downto 12) & "000000000000";
      when "01100" => tmp_frac := step2_in(22 downto 13) & "0000000000000";
      when "01101" => tmp_frac := step2_in(22 downto 14) & "00000000000000";
      when "01110" => tmp_frac := step2_in(22 downto 15) & "000000000000000";
      when "01111" => tmp_frac := step2_in(22 downto 16) & "0000000000000000";
      when "10000" => tmp_frac := step2_in(22 downto 17) & "00000000000000000";
      when "10001" => tmp_frac := step2_in(22 downto 18) & "000000000000000000";
      when "10010" => tmp_frac := step2_in(22 downto 19) & "0000000000000000000";
      when "10011" => tmp_frac := step2_in(22 downto 20) & "00000000000000000000";
      when "10100" => tmp_frac := step2_in(22 downto 21) & "000000000000000000000";
      when "10101" => tmp_frac := step2_in(22 downto 22) & "0000000000000000000000";
      when others  => tmp_frac := "00000000000000000000000";
    end case;

    case step2_in(36 downto 32) is
      when "00000" => tmp_expofrac := (step2_in(30 downto 1) + 1) & "0";
      when "00001" => tmp_expofrac := (step2_in(30 downto 2) + 1) & "00";
      when "00010" => tmp_expofrac := (step2_in(30 downto 3) + 1) & "000";
      when "00011" => tmp_expofrac := (step2_in(30 downto 4) + 1) & "0000";
      when "00100" => tmp_expofrac := (step2_in(30 downto 5) + 1) & "00000";
      when "00101" => tmp_expofrac := (step2_in(30 downto 6) + 1) & "000000";
      when "00110" => tmp_expofrac := (step2_in(30 downto 7) + 1) & "0000000";
      when "00111" => tmp_expofrac := (step2_in(30 downto 8) + 1) & "00000000";
      when "01000" => tmp_expofrac := (step2_in(30 downto 9) + 1) & "000000000";
      when "01001" => tmp_expofrac := (step2_in(30 downto 10) + 1) & "0000000000";
      when "01010" => tmp_expofrac := (step2_in(30 downto 11) + 1) & "00000000000";
      when "01011" => tmp_expofrac := (step2_in(30 downto 12) + 1) & "000000000000";
      when "01100" => tmp_expofrac := (step2_in(30 downto 13) + 1) & "0000000000000";
      when "01101" => tmp_expofrac := (step2_in(30 downto 14) + 1) & "00000000000000";
      when "01110" => tmp_expofrac := (step2_in(30 downto 15) + 1) & "000000000000000";
      when "01111" => tmp_expofrac := (step2_in(30 downto 16) + 1) & "0000000000000000";
      when "10000" => tmp_expofrac := (step2_in(30 downto 17) + 1) & "00000000000000000";
      when "10001" => tmp_expofrac := (step2_in(30 downto 18) + 1) & "000000000000000000";
      when "10010" => tmp_expofrac := (step2_in(30 downto 19) + 1) & "0000000000000000000";
      when "10011" => tmp_expofrac := (step2_in(30 downto 20) + 1) & "00000000000000000000";
      when "10100" => tmp_expofrac := (step2_in(30 downto 21) + 1) & "000000000000000000000";
      when "10101" => tmp_expofrac := (step2_in(30 downto 22) + 1) & "0000000000000000000000";
      when others  => tmp_expofrac := (step2_in(30 downto 23) + 1) & "00000000000000000000000";
    end case;

    if step2_in(38 downto 37) = "01" then
      if step2_in(31) = '0' then
        result := '0' & step2_in(30 downto 23) & tmp_frac;
      else
        result := '1' & tmp_expofrac;
      end if;
    else
      result := step2_in(31 downto 0);
    end if;

    return result;
  end step2;


  signal step1_out : std_logic_vector (38 downto 0);
  signal step2_in  : std_logic_vector (38 downto 0);

begin

  step1_out <= step1(input);
  output    <= step2(step2_in);

  fpu_floor : process(clk)
  begin
    if rising_edge(clk) then

      step2_in  <= step1_out(38 downto 0);

    end if;
  end process;
    
end struct;

