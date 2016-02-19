library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity alu is
    port (
        clk : in std_logic;
        alu_in : in alu_in_type;
        alu_out : out alu_out_type);
end alu;

architecture struct of alu is
    type rs_entry_type is record
        busy : boolean;
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
    end record;
    constant rs_entry_init : rs_entry_type := (
        busy => false,
        command => (others => '0'),
        rtag => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init);
    type rs_type is array(2 ** ALU_RS_ADDR_LENGTH - 1 downto 0) of rs_entry_type;
    type reg_type is record
        rs : rs_type;
        alu_out : alu_out_type;
    end record;
    constant reg_init : reg_type := (
        rs => (others => rs_entry_init),
        alu_out => alu_out_init);
    signal r, rin : reg_type := reg_init;
begin
    comb : process(r, alu_in)
        variable v : reg_type := reg_init;
        type alu_in_dones_type is array(1 downto 0) of boolean; -- hardcode
        variable alu_in_dones : alu_in_dones_type := (others => false);
        variable output_count : integer := 0;
        variable tmp : std_logic_vector(31 downto 0) := (others => '0');
        function my_sra(a : std_logic_vector; count : std_logic_vector) return std_logic_vector is
        variable res : std_logic_vector(31 downto 0);
        begin
            res := a;
            if count(0) = '1' then
                if a(31) = '0' then
                    res := '0' & res(31 downto 1);
                else
                    res := '1' & res(31 downto 1);
                end if;
            end if;
            if count(1) = '1' then
                if a(31) = '0' then
                    res := "00" & res(31 downto 2);
                else
                    res := "11" & res(31 downto 2);
                end if;
            end if;
            if count(2) = '1' then
                if a(31) = '0' then
                    res := x"0" & res(31 downto 4);
                else
                    res := x"f" & res(31 downto 4);
                end if;
            end if;
            if count(3) = '1' then
                if a(31) = '0' then
                    res := x"00" & res(31 downto 8);
                else
                    res := x"ff" & res(31 downto 8);
                end if;
            end if;
            if count(4) = '1' then
                if a(31) = '0' then
                    res := x"0000" & res(31 downto 16);
                else
                    res := x"ffff" & res(31 downto 16);
                end if;
            end if;
            if unsigned(count(31 downto 5)) /= 0 then
                if a(31) = '0' then
                    res := (others => '0');
                else
                    res := (others => '1');
                end if;
            end if;
            return res;
        end function my_sra;
        function my_srl(a : std_logic_vector; count : std_logic_vector) return std_logic_vector is
            variable res : std_logic_vector(31 downto 0);
        begin
            res := a;
            if count(0) = '1' then
                res := '0' & res(31 downto 1);
            end if;
            if count(1) = '1' then
                res := "00" & res(31 downto 2);
            end if;
            if count(2) = '1' then
                res := x"0" & res(31 downto 4);
            end if;
            if count(3) = '1' then
                res := x"00" & res(31 downto 8);
            end if;
            if count(4) = '1' then
                res := x"0000" & res(31 downto 16);
            end if;
            if unsigned(count(31 downto 5)) /= 0 then
                res := (others => '0');
            end if;
            return res;
        end function my_srl;
        function my_sll(a : std_logic_vector; count : std_logic_vector) return std_logic_vector is
            variable res : std_logic_vector(31 downto 0);
        begin
            res := a;
            if count(0) = '1' then
                res := res(30 downto 0) & '0';
            end if;
            if count(1) = '1' then
                res := res(29 downto 0) & "00";
            end if;
            if count(2) = '1' then
                res := res(27 downto 0) & "0000";
            end if;
            if count(3) = '1' then
                res := res(23 downto 0) & x"00";
            end if;
            if count(4) = '1' then
                res := res(15 downto 0) & x"0000";
            end if;
            if unsigned(count(31 downto 5)) /= 0 then
                res := (others => '0');
            end if;
            return res;
        end function my_sll;
    begin
        v := r;

        alu_in_dones := (others => false);
        v.alu_out.free_count := (others => '0');
        v.alu_out.outputs := (others => alu_out_body_entry_init);
        output_count := 0;
        tmp := (others => '0');

        if alu_in.reset_rs then
            -- reset rs
            for i in r.rs'reverse_range loop
                v.rs(i).busy := false;
            end loop;
            v.alu_out.free_count := (others => '0');
        else
            for i in r.rs'reverse_range loop
                -- accepted by arbiter
                for j in alu_in.accepts'reverse_range loop
                    if alu_in.accepts(j).valid then
                        if r.rs(i).rtag = alu_in.accepts(j).rtag then
                            v.rs(i).busy := false;
                        end if;
                    end if;
                end loop;

                -- insert into RS
                INSERT_L1: for j in alu_in.inputs'reverse_range loop
                    if not alu_in_dones(j) and alu_in.inputs(j).command /= ALU_NOP and not v.rs(i).busy then
                        v.rs(i).busy := true;
                        v.rs(i).command := alu_in.inputs(j).command;
                        v.rs(i).rtag := alu_in.inputs(j).rtag;
                        v.rs(i).lhs := alu_in.inputs(j).lhs;
                        v.rs(i).rhs := alu_in.inputs(j).rhs;
                        alu_in_dones(j) := true;
                        exit INSERT_L1;
                    end if;
                end loop;

                -- watch the CDB
                for j in alu_in.cdb'reverse_range loop
                    if alu_in.cdb(j).valid then
                        if v.rs(i).lhs.busy and v.rs(i).lhs.rtag = alu_in.cdb(j).rtag then
                            v.rs(i).lhs.busy := false;
                            v.rs(i).lhs.value := alu_in.cdb(j).value;
                        end if;
                        if v.rs(i).rhs.busy and v.rs(i).rhs.rtag = alu_in.cdb(j).rtag then
                            v.rs(i).rhs.busy := false;
                            v.rs(i).rhs.value := alu_in.cdb(j).value;
                        end if;
                    end if;
                end loop;

                -- execute
                case v.rs(i).command is
                    when ALU_ADD =>
                        tmp := std_logic_vector(unsigned(v.rs(i).lhs.value) + unsigned(v.rs(i).rhs.value));
                    when ALU_SUB =>
                        tmp := std_logic_vector(unsigned(v.rs(i).lhs.value) - unsigned(v.rs(i).rhs.value));
                    when ALU_SLL =>
                        if r.rs(i).rhs.value(31) = '0' then -- positive
--                            tmp := std_logic_vector(shift_left(unsigned(v.rs(i).lhs.value), to_integer(signed(v.rs(i).rhs.value))));
                            tmp := my_sll(v.rs(i).lhs.value, v.rs(i).rhs.value);
                        else -- negative
--                            tmp := std_logic_vector(shift_right(unsigned(v.rs(i).lhs.value), to_integer(-signed(v.rs(i).rhs.value))));
                            tmp := my_srl(v.rs(i).lhs.value, std_logic_vector(-signed(v.rs(i).rhs.value)));
                        end if;
                    when ALU_SRA =>
                        if r.rs(i).rhs.value(31) = '0' then -- positive
--                            tmp := std_logic_vector(shift_right(signed(v.rs(i).lhs.value), to_integer(signed(v.rs(i).rhs.value))));
                            tmp := my_sra(v.rs(i).lhs.value, v.rs(i).rhs.value);
                        else -- negative
--                            tmp := std_logic_vector(shift_left(unsigned(v.rs(i).lhs.value), to_integer(-signed(v.rs(i).rhs.value))));
                            tmp := my_sll(v.rs(i).lhs.value, std_logic_vector(-signed(v.rs(i).rhs.value)));
                        end if;
                    when others =>
                end case;

                -- update free_count
                if not v.rs(i).busy then
                    v.alu_out.free_count := std_logic_vector(unsigned(v.alu_out.free_count) + 1);
                end if;

                -- output
                if output_count < 2 and v.rs(i).busy and not v.rs(i).lhs.busy and not v.rs(i).rhs.busy then
                    v.alu_out.outputs(output_count).valid := true;
                    v.alu_out.outputs(output_count).to_rob.valid := true;
                    v.alu_out.outputs(output_count).to_rob.rtag := v.rs(i).rtag;
                    v.alu_out.outputs(output_count).to_rob.value := tmp(31 downto 0);
                    output_count := output_count + 1;
                end if;
            end loop;

        end if;


        alu_out.outputs <= r.alu_out.outputs; -- 出力は最短でも 1 クロック後
        alu_out.free_count <= v.alu_out.free_count; -- 空き rs 数はすぐに

        rin <= v;
    end process;

    reg : process(clk)
    begin
        if rising_edge(clk) then
            r <= rin;
        end if;
    end process;
end struct;
