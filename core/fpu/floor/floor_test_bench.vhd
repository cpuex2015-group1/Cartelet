LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library STD;
use std.textio.all;

ENTITY floor_testbench IS
END floor_testbench;

ARCHITECTURE testbench OF floor_testbench IS 

  COMPONENT floor
    Port (
    clk     : in  STD_LOGIC;
    input   : in  STD_LOGIC_VECTOR (31 downto 0);
    output  : out STD_LOGIC_VECTOR (31 downto 0));
  END COMPONENT;

  signal state  : std_logic_vector(3 downto 0) := "0000";
  signal input  : std_logic_vector(31 downto 0) := (others => '0');
  signal output : std_logic_vector(31 downto 0);
  signal simclk : std_logic := '0';

BEGIN 

  unit : floor PORT MAP (
    clk    => simclk,
    input  => input,
    output => output);

  test : process(simclk)
    file fd_i : text open read_mode is "testcase.txt";
    file fd_o : text open write_mode is "output.txt";
    variable li,lo : LINE;
    variable a : std_logic_vector(31 downto 0) := (others => '0');
    variable c : std_logic_vector(31 downto 0) := (others => '0');

    begin
      if rising_edge(simclk) then
        input <= a;
        c := output;
        if state < "0011" then
          readline(fd_i, li);
          read(li, a);
          state <= state + 1;
        elsif state = "0011" then
          if endfile(fd_i) then
            write(lo, c);
            writeline(fd_o, lo);
            state <= state + 1;
          else 
            write(lo, c);
            writeline(fd_o, lo);
            readline(fd_i, li);
            read(li, a);
          end if;
        elsif state < "0110" then
          write(lo, c);
          writeline(fd_o, lo);
          state <= state + 1;
        end if;
      end if;
    end process;  

  clockgen : process
  begin
    simclk <= '0';
    wait for 5 ns;
    simclk <= '1';
    wait for 5 ns;
  end process;
END;
