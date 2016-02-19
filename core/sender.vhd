library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity sender is
    generic (
        wtime : std_logic_vector(15 downto 0) := x"1ADB";
        SENDER_FIFO_ADDR_LENGTH : integer := 5
    );
    port (
        clk : in std_logic;
        sender_in : in sender_in_type;
        sender_out : out sender_out_type);
end sender;

architecture struct of sender is
    type sender_fifo_type is array(2 ** SENDER_FIFO_ADDR_LENGTH - 1 downto 0) of std_logic_vector(7 downto 0);
    type st_type is (ready, sending_a_bit);
    type reg_type is record
        sender_fifo : sender_fifo_type;
        sender_in_go : boolean;
        sender_in_data : std_logic_vector(7 downto 0);
        sending_buff : std_logic_vector(8 downto 0);
        st : st_type;
        counter : std_logic_vector(15 downto 0);
        rem_bits : std_logic_vector(3 downto 0);
        rem_bytes : std_logic_vector(2 downto 0);
        qhd : std_logic_vector(SENDER_FIFO_ADDR_LENGTH - 1 downto 0);
        qtl : std_logic_vector(SENDER_FIFO_ADDR_LENGTH - 1 downto 0);
    end record;
    signal r, rin : reg_type := (
        sender_fifo => (others => (others => '0')),
        sender_in_go => false,
        sender_in_data => (others => '0'),
        sending_buff => (others => '1'),
        st => ready,
        counter => (others => '0'),
        rem_bits => (others => '0'),
        rem_bytes => (others => '0'),
        qhd => (others => '0'),
        qtl => (others => '0')
    );
begin
    sender_out.rs_tx <= r.sending_buff(0);

    comb : process (sender_in, r)
        variable v : reg_type;
        variable send_enable : std_logic := '0';
        variable data_to_be_sent : std_logic_vector(7 downto 0) := (others => '0');
    begin
        v := r;
        send_enable := '0';
        v.sender_in_go := sender_in.go;
        v.sender_in_data := sender_in.data;
        data_to_be_sent := (others => '0');
        if unsigned(r.qtl) + 1 /= unsigned(r.qhd) and r.sender_in_go then
            v.sender_fifo(to_integer(unsigned(r.qtl))) := r.sender_in_data;
            v.qtl := std_logic_vector(unsigned(r.qtl) + 1);
        elsif r.qhd /= r.qtl then
            send_enable := '1';
            data_to_be_sent := r.sender_fifo(to_integer(unsigned(r.qhd)));
        end if;
        case r.st is
            when ready =>
                if send_enable = '1' then
                    v.sending_buff := data_to_be_sent & '0';
                    v.st := sending_a_bit;
                    v.counter := wtime;
                    v.rem_bits := x"a";
                    v.rem_bytes := "001";
                    v.qhd := std_logic_vector(unsigned(r.qhd) + 1);
                end if;
            when sending_a_bit =>
                if r.counter = x"0000" then
                    v.rem_bits := std_logic_vector(unsigned(r.rem_bits) - 1);
                    v.sending_buff := '1' & r.sending_buff(8 downto 1);
                    v.counter := wtime;
                    if r.rem_bits = x"0" then
                        v.rem_bytes := std_logic_vector(unsigned(r.rem_bytes) - 1);
                        v.st := ready;
                    else
                        v.st := sending_a_bit;
                    end if;
                else
                    v.counter := std_logic_vector(unsigned(r.counter) - 1);
                end if;
        end case;

        if to_unsigned(to_integer(unsigned(v.qtl)) + 2, SENDER_FIFO_ADDR_LENGTH) = unsigned(v.qhd) or
            to_unsigned(to_integer(unsigned(v.qtl)) + 1, SENDER_FIFO_ADDR_LENGTH) = unsigned(v.qhd) then
            sender_out.busy <= true;
        else
            sender_out.busy <= false;
        end if;
        rin <= v;
    end process;
    reg : process (clk)
    begin
        if rising_edge(clk) then
            r <= rin;
        end if;
    end process;
end struct;
