library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity bru is
    port (
        clk : in std_logic;
        bru_in : in bru_in_type;
        bru_out : out bru_out_type);
end bru;

architecture struct of bru is
    type rs_entry_type is record
        busy : boolean;
        executing : boolean;
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
        taken : boolean;
        offset : std_logic_vector(IMM_LENGTH - 1 downto 0);
    end record;
    constant rs_entry_init : rs_entry_type := (
        busy => false,
        executing => false,
        command => (others => '0'),
        rtag => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init,
        taken => false,
        offset => (others => '0'));
    type rs_type is array(0 downto 0) of rs_entry_type; -- TODO: RS は一つで良い？
    type reg_type is record
        rs : rs_type;
        bru_out : bru_out_type;
    end record;
    constant reg_init : reg_type := (
        rs => (others => rs_entry_init),
        bru_out => bru_out_init);
    signal r, rin : reg_type := reg_init;
begin
    comb : process(r, bru_in)
        variable v : reg_type := reg_init;
        variable tmp : std_logic_vector(31 downto 0);
        variable rs_written : boolean := false;
    begin
        v := r;

        v.bru_out := bru_out_init;

        -- reset rs
        -- NOTE: r.bru_out.output.valid は使わない
        if bru_in.reset_rs then
            for i in r.rs'reverse_range loop
                v.rs(i).busy := false;
            end loop;
            v.bru_out.output.to_rob.valid := false;
        end if;

        -- execute
        if not v.bru_out.output.to_rob.valid then -- valid だったら占有されている
            for j in r.rs'reverse_range loop
                if v.rs(j).busy and r.rs(j).command /= BRU_NOP and not r.rs(j).lhs.busy and not r.rs(j).rhs.busy then
                    v.rs(j).executing := true;
                    case r.rs(j).command is
                        when BRU_EQ =>
                            -- 31 : 誤った分岐なら 1 otherwise 0
                            -- 15 downto 0 : offset
                            if (r.rs(j).lhs.value = r.rs(j).rhs.value) = r.rs(j).taken then
                                tmp(31) := '0';
                            else
                                tmp(31) := '1';
                            end if;
                        when BRU_NEQ =>
                            if (r.rs(j).lhs.value /= r.rs(j).rhs.value) = r.rs(j).taken then
                                tmp(31) := '0';
                            else
                                tmp(31) := '1';
                            end if;
                        when others =>
                    end case;
                    tmp(30 downto 16) := (others => '-');
                    tmp(15 downto 0) := r.rs(j).offset;
                    v.bru_out.output.to_rob.valid := true;
                    v.bru_out.output.to_rob.rtag := r.rs(j).rtag;
                    v.bru_out.output.to_rob.value := tmp;
                end if;
            end loop;
        end if;


        -- insert into RS
        INSERT_L2: for j in r.rs'reverse_range loop
            if bru_in.input.command /= BRU_NOP and not rs_written and not v.rs(j).busy then
                v.rs(j).busy := true;
                v.rs(j).command := bru_in.input.command;
                v.rs(j).rtag := bru_in.input.rtag;
                v.rs(j).lhs := bru_in.input.lhs;
                v.rs(j).rhs := bru_in.input.rhs;
                v.rs(j).offset := bru_in.input.offset;

--                exit INSERT_L2;
            end if;
        end loop;

        -- watch the CDB
        for i in bru_in.cdb'reverse_range loop
            if bru_in.cdb(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).lhs.busy and v.rs(j).lhs.rtag = bru_in.cdb(i).rtag then
                        v.rs(j).lhs.busy := false;
                        v.rs(j).lhs.value := bru_in.cdb(i).value;
                    end if;
                    if v.rs(j).rhs.busy and v.rs(j).rhs.rtag = bru_in.cdb(i).rtag then
                        v.rs(j).rhs.busy := false;
                        v.rs(j).rhs.value := bru_in.cdb(i).value;
                    end if;
                end loop;
            end if;
        end loop;

        -- busy or not
        v.bru_out.free_count := (others => '0');
        for i in r.rs'reverse_range loop
            if not v.rs(i).busy then
                v.bru_out.free_count := std_logic_vector(unsigned(v.bru_out.free_count) + 1);
            end if;
        end loop;

        -- accepted by arbiter
        for i in bru_in.accepts'reverse_range loop
            if bru_in.accepts(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).rtag = bru_in.accepts(i).rtag then
                        v.rs(j).busy := false;
                        v.rs(j).executing := false;
                    end if;
                end loop;
                if v.bru_out.output.to_rob.rtag = bru_in.accepts(i).rtag then
                    v.bru_out.output.to_rob.valid := false;
                end if;
            end if;
        end loop;

        bru_out.output <= r.bru_out.output; -- 出力は最短でも 1 クロック後
        bru_out.free_count <= v.bru_out.free_count; -- 空き rs 数はすぐに

        rin <= v;
    end process;

    reg : process(clk)
    begin
        if rising_edge(clk) then
            r <= rin;
        end if;
    end process;
end struct;
