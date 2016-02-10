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
        executing : boolean;
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
    end record;
    constant rs_entry_init : rs_entry_type := (
        busy => false,
        executing => false,
        command => (others => '0'),
        rtag => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init);
    type rs_type is array(ALU_RS_WIDTH downto 0) of rs_entry_type;
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
        variable tmp : std_logic_vector(31 downto 0);
    begin
        v := r;

        tmp := (others => '0');

        -- reset rs and output
        if alu_in.reset_rs then
            for i in r.rs'reverse_range loop
                v.rs(i).busy := false;
            end loop;
            for i in r.alu_out.outputs'reverse_range loop
                v.alu_out.outputs(i).valid := false;
            end loop;
        end if;



        -- execute
        for i in r.alu_out.outputs'reverse_range loop
            if not v.alu_out.outputs(i).valid then -- valid なものは占有されている
                EXEC_L2: for j in r.rs'reverse_range loop
                    -- v.rs(j).executing に注意
                    if v.rs(j).busy and not v.rs(j).executing and not r.rs(j).lhs.busy and not r.rs(j).rhs.busy then
                        v.rs(j).executing := true;
                        case r.rs(j).command is
                            when ALU_ADD =>
                                tmp := std_logic_vector(unsigned(r.rs(j).lhs.value) + unsigned(r.rs(j).rhs.value));
                            when ALU_SUB =>
                                tmp := std_logic_vector(unsigned(r.rs(j).lhs.value) - unsigned(r.rs(j).rhs.value));
                            when ALU_SLL =>
                                if r.rs(j).rhs.value(31) = '0' then -- positive
                                    tmp := std_logic_vector(shift_left(unsigned(r.rs(j).lhs.value), to_integer(signed(r.rs(j).rhs.value))));
                                else -- negative
                                    tmp := std_logic_vector(shift_right(unsigned(r.rs(j).lhs.value), to_integer(-signed(r.rs(j).rhs.value))));
                                end if;
                            when ALU_SRA =>
                                if r.rs(j).rhs.value(31) = '0' then -- positive
                                    tmp := std_logic_vector(shift_right(signed(r.rs(j).lhs.value), to_integer(signed(r.rs(j).rhs.value))));
                                else -- negative
                                    tmp := std_logic_vector(shift_left(unsigned(r.rs(j).lhs.value), to_integer(-signed(r.rs(j).rhs.value))));
                                end if;
                            when others =>
                        end case;

                        v.alu_out.outputs(i).valid := true;
                        v.alu_out.outputs(i).to_rob.valid := true;
                        v.alu_out.outputs(i).to_rob.rtag := r.rs(j).rtag;
                        v.alu_out.outputs(i).to_rob.value := tmp;
                        exit EXEC_L2;
                    end if;
                end loop;
            end if;
        end loop;


        -- insert into RS
        for i in alu_in.inputs'reverse_range loop
            INSERT_L2: for j in r.rs'reverse_range loop
                if alu_in.inputs(i).command /= ALU_NOP and not v.rs(j).busy then
                    v.rs(j).busy := true;
                    v.rs(j).command := alu_in.inputs(i).command;
                    v.rs(j).rtag := alu_in.inputs(i).rtag;
                    v.rs(j).lhs := alu_in.inputs(i).lhs;
                    v.rs(j).rhs := alu_in.inputs(i).rhs;

                    exit INSERT_L2;
                end if;
            end loop;
        end loop;

        -- watch the CDB
        for i in alu_in.cdb'reverse_range loop
            if alu_in.cdb(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).lhs.busy and v.rs(j).lhs.rtag = alu_in.cdb(i).rtag then
                        v.rs(j).lhs.busy := false;
                        v.rs(j).lhs.value := alu_in.cdb(i).value;
                    end if;
                    if v.rs(j).rhs.busy and v.rs(j).rhs.rtag = alu_in.cdb(i).rtag then
                        v.rs(j).rhs.busy := false;
                        v.rs(j).rhs.value := alu_in.cdb(i).value;
                    end if;
                end loop;
            end if;
        end loop;

        -- busy or not
        v.alu_out.free_count := (others => '0');
        for i in v.rs'reverse_range loop
            if not(v.rs(i).busy) then
                v.alu_out.free_count := std_logic_vector(unsigned(v.alu_out.free_count) + 1);
            end if;
        end loop;

        -- accepted by arbiter
        for i in alu_in.accepts'reverse_range loop
            if alu_in.accepts(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).rtag = alu_in.accepts(i).rtag then
                        v.rs(j).busy := false;
                        v.rs(j).executing := false;
                    end if;
                end loop;
                for j in r.alu_out.outputs'reverse_range loop
                    if v.alu_out.outputs(j).to_rob.rtag = alu_in.accepts(i).rtag then
                        v.alu_out.outputs(j).valid := false;
                    end if;
                end loop;
            end if;
        end loop;

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
