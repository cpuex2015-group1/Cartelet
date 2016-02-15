library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fmul is
  Port (
    clk     : in  STD_LOGIC;
    input1  : in  STD_LOGIC_VECTOR (31 downto 0);
    input2  : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0));
end fmul;

architecture struct of fmul is

  function step1(input1 : std_logic_vector(31 downto 0); input2 : std_logic_vector(31 downto 0))
    return std_logic_vector
  is
    variable sign           : std_logic;
    variable tmp_expo       : std_logic_vector (8 downto 0);
    variable tmp_frac       : std_logic_vector (47 downto 0);
    variable step1_out      : std_logic_vector (34 downto 0);

  begin

    sign := input1(31) xor input2(31);
    tmp_expo := ('0' & input1(30 downto 23)) + ('0' & input2(30 downto 23));
    tmp_frac := ('1' & input1(22 downto 0)) * ('1' & input2(22 downto 0));

    step1_out := sign & tmp_expo & tmp_frac(47 downto 23);

    return step1_out;
  end step1;

  function step2(step2_in : std_logic_vector(33 downto 0))
    return std_logic_vector
  is
    variable tmp_expo : std_logic_vector (8 downto 0);
    variable expo     : std_logic_vector (8 downto 0);
    variable frac     : std_logic_vector (22 downto 0);
    variable result   : std_logic_vector (30 downto 0);
  begin

    if step2_in(24) = '1' then
      tmp_expo := step2_in(33 downto 25) + 1;
      frac     := step2_in(23 downto 1);
    else
      tmp_expo := step2_in(33 downto 25);
      frac     := step2_in(22 downto 0);
    end if;

    if (tmp_expo(8) or tmp_expo(7)) = '1' then
      expo := tmp_expo - 127;
      result := frac & expo(7 downto 0);
    else
      result := "0000000000000000000000000000000";
    end if;

    return result;
  end step2;

  signal sign      : std_logic;
  signal step1_out : std_logic_vector (34 downto 0);
  signal step2_in  : std_logic_vector (33 downto 0);
  signal expofrac  : std_logic_vector (30 downto 0);

begin

  step1_out <= step1(input1,input2);
  expofrac  <= step2(step2_in);
  output    <= sign & expofrac;

  floatmul : process(clk)
  begin
    if rising_edge(clk) then

      sign     <= step1_out(34);
      step2_in <= step1_out(33 downto 0);

    end if;
  end process;
    
end struct;

