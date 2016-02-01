library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity sdu is
    port (
        clk : in std_logic;
        sdu_in : in sdu_in_type;
        sdu_out : out sdu_out_type);
end sdu;

architecture struct of sdu is
    type rs_entry_type is record
        busy : boolean;
        executing : boolean;
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        reg : reg_file_entry_type;
    end record;
    constant rs_entry_init : rs_entry_type := (
        busy => false,
        executing => false,
        rtag => (others => '0'),
        reg => reg_file_entry_init);
    type rs_type is array(1 downto 0) of rs_entry_type;
    type reg_type is record
        rs : rs_type;
        sdu_out : sdu_out_type;
    end record;
    constant reg_init : reg_type := (
        rs => (others => rs_entry_init),
        sdu_out => sdu_out_init);
    signal r, rin : reg_type := reg_init;

    function stdv2str(vec:std_logic_vector) return string is
        variable str: string(vec'left+1 downto 1);
    begin
        for i in vec'reverse_range loop
            if(vec(i)='U') then
                str(i+1):='U';
            elsif(vec(i)='X') then
                str(i+1):='X';
            elsif(vec(i)='0') then
                str(i+1):='0';
            elsif(vec(i)='1') then
                str(i+1):='1';
            elsif(vec(i)='Z') then
                str(i+1):='Z';
            elsif(vec(i)='W') then
                str(i+1):='W';
            elsif(vec(i)='L') then
                str(i+1):='L';
            elsif(vec(i)='H') then
                str(i+1):='H';
            else
                str(i+1):='-';
            end if;
        end loop;
        return str;
    end;
begin
    comb : process(r, sdu_in)
        variable v : reg_type := reg_init;
        variable ex_done : boolean := false;
        variable rs_written : boolean := false;
    begin
        v := r;

        -- busy or not
        v.sdu_out.free_count := (others => '0');
        for i in r.rs'range loop
            if not(r.rs(i).busy) then
                v.sdu_out.free_count := std_logic_vector(unsigned(v.sdu_out.free_count) + 1);
            end if;
        end loop;

        -- check if write to the rob is accepted or not
        for i in sdu_in.accepts'reverse_range loop
            if sdu_in.accepts(i).valid then
                if sdu_in.accepts(i).rtag = r.sdu_out.to_rob.rtag then
                    v.sdu_out.to_rob.valid := false;
                end if;

                for j in r.rs'reverse_range loop
                    if r.rs(i).rtag = sdu_in.accepts(i).rtag and r.rs(i).executing then
                        v.rs(i).busy := false;
                        v.rs(i).executing := false;
                    end if;
                end loop;
            end if;
        end loop;

        -- select one entry and execute
        EXEC_L1: for i in r.rs'range loop
            if r.rs(i).busy and not r.rs(i).executing and not r.rs(i).reg.busy then
                v.rs(i).executing := true;

                v.sdu_out.to_rob.valid := true;
                v.sdu_out.to_rob.rtag := r.rs(i).rtag;
                v.sdu_out.to_rob.value := r.rs(i).reg.value;

                exit EXEC_L1;
            end if;
        end loop;

        -- insert into RS
        for i in sdu_in.inputs'range loop
            INSERT_L2: if sdu_in.inputs(i).valid then
                for j in r.rs'range loop
                    if not rs_written and not v.rs(j).busy then
                        v.rs(j).busy := true;
                        v.rs(j).rtag := sdu_in.inputs(i).rtag;
                        v.rs(j).reg.busy := sdu_in.inputs(i).reg.busy;
                        v.rs(j).reg.rtag := sdu_in.inputs(i).reg.rtag;
                        v.rs(j).reg.value := sdu_in.inputs(i).reg.value;

                        exit INSERT_L2;
                    end if;
                end loop;
            end if;
        end loop;

        -- watch the CDB
        for i in sdu_in.cdb'range loop
            if sdu_in.cdb(i).valid then
                for j in r.rs'range loop
                    if r.rs(j).reg.busy and r.rs(j).reg.rtag = sdu_in.cdb(i).rtag then
                        v.rs(j).reg.busy := false;
                        v.rs(j).reg.value := sdu_in.cdb(i).value;
                    end if;
                end loop;
            end if;
        end loop;

        sdu_out.to_rob <= r.sdu_out.to_rob; -- 出力は最短でも 1 クロック後
        sdu_out.free_count <= v.sdu_out.free_count;
        rin <= v;
    end process;

    reg : process(clk)
    begin
        if rising_edge(clk) then
            r <= rin;
        end if;
    end process;
end struct;
