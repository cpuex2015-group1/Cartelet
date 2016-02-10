library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity fpu is
    port (
        clk : in std_logic;
        fpu_in : in fpu_in_type;
        fpu_out : out fpu_out_type);
end fpu;

architecture struct of fpu is
    component fadd is
      Port (
        clk     : in  STD_LOGIC;
        input1  : in  STD_LOGIC_VECTOR (31 downto 0);
        input2  : in  STD_LOGIC_VECTOR (31 downto 0);
        output  : out STD_LOGIC_VECTOR (31 downto 0));
    end component;

    type rs_entry_type is record
        busy : boolean;
        executing : boolean;
        outputting : boolean;
        counter : std_logic_vector(2 downto 0);
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        data : std_logic_vector(31 downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
    end record;
    constant rs_entry_init : rs_entry_type := (
        busy => false,
        executing => false,
        outputting => false,
        counter => (others => '0'),
        command => (others => '0'),
        rtag => (others => '0'),
        data => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init);
    type rs_type is array(FPU_RS_WIDTH downto 0) of rs_entry_type;
    type reg_type is record
        rs : rs_type;
        fadd_lhs : std_logic_vector(31 downto 0);
        fadd_rhs : std_logic_vector(31 downto 0);
        fpu_out : fpu_out_type;
    end record;
    constant reg_init : reg_type := (
        rs => (others => rs_entry_init),
        fadd_lhs => (others => '0'),
        fadd_rhs => (others => '0'),
        fpu_out => fpu_out_init);
    signal r, rin : reg_type := reg_init;

    signal fadd_output : std_logic_vector(31 downto 0);

begin
    fadd1: fadd port map (
        clk => clk,
        input1 => r.fadd_lhs,
        input2 => r.fadd_rhs,
        output => fadd_output
    );

    comb : process(r, fpu_in, fadd_output)
        variable v : reg_type := reg_init;
        variable num_free_entries : std_logic_vector(FPU_RS_WIDTH downto 0);
        variable tmp : std_logic_vector(31 downto 0);
        variable rs_written : boolean := false;
    begin
        v := r;

        -- reset rs and output
        if fpu_in.reset_rs then
            for i in r.rs'reverse_range loop
                v.rs(i).busy := false;
                v.rs(i).executing := false;
                v.rs(i).outputting := false;
            end loop;
            for i in r.fpu_out.outputs'reverse_range loop
                v.fpu_out.outputs(i).valid := false;
            end loop;
        end if;


        -- countdown
        for i in r.rs'reverse_range loop
            if v.rs(i).busy and r.rs(i).counter /= "000" then
                v.rs(i).counter := std_logic_vector(unsigned(r.rs(i).counter) - 1);
            end if;
        end loop;


        -- execute
        for i in r.rs'reverse_range loop
            if v.rs(i).busy and not v.rs(i).executing and not r.rs(i).lhs.busy and not r.rs(i).rhs.busy then
                v.rs(i).executing := true;
                case r.rs(i).command is
                    when FPU_ADD =>
                        v.fadd_lhs := r.rs(i).lhs.value;
                        v.fadd_rhs := r.rs(i).rhs.value;
                        v.rs(i).counter := "010";
                    when others =>
                end case;
            end if;
        end loop;


        -- 各コンポーネントからの出力を読む
        for i in r.rs'reverse_range loop
            if v.rs(i).busy and v.rs(i).executing and v.rs(i).counter = "000" then
                case v.rs(i).command is
                    when FPU_ADD =>
                        v.rs(i).data := fadd_output;
                    when others =>
                end case;
            end if;
        end loop;



        -- output
        for i in r.fpu_out.outputs'reverse_range loop
            if not v.fpu_out.outputs(i).valid then -- valid なものは占有されている
                EXEC_L2: for j in r.rs'reverse_range loop
                    -- v.rs(j).executing に注意
                    if v.rs(j).busy and v.rs(j).executing and v.rs(j).counter = "000" and not v.rs(j).outputting then
                        v.rs(j).outputting := true;

                        v.fpu_out.outputs(i).valid := true;
                        v.fpu_out.outputs(i).to_rob.valid := true;
                        v.fpu_out.outputs(i).to_rob.rtag := v.rs(j).rtag;
                        v.fpu_out.outputs(i).to_rob.value := v.rs(j).data;
                        exit EXEC_L2;
                    end if;
                end loop;
            end if;
        end loop;


        -- insert into RS
        for i in fpu_in.inputs'reverse_range loop
            INSERT_L2: for j in r.rs'reverse_range loop
                if fpu_in.inputs(i).command /= FPU_NOP and not rs_written and not v.rs(j).busy then
                    v.rs(j).busy := true;
                    v.rs(j).command := fpu_in.inputs(i).command;
                    v.rs(j).rtag := fpu_in.inputs(i).rtag;
                    v.rs(j).lhs := fpu_in.inputs(i).lhs;
                    v.rs(j).rhs := fpu_in.inputs(i).rhs;

                    exit INSERT_L2;
                end if;
            end loop;
        end loop;

        -- watch the CDB
        for i in fpu_in.cdb'reverse_range loop
            if fpu_in.cdb(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).lhs.busy and v.rs(j).lhs.rtag = fpu_in.cdb(i).rtag then
                        v.rs(j).lhs.busy := false;
                        v.rs(j).lhs.value := fpu_in.cdb(i).value;
                    end if;
                    if v.rs(j).rhs.busy and v.rs(j).rhs.rtag = fpu_in.cdb(i).rtag then
                        v.rs(j).rhs.busy := false;
                        v.rs(j).rhs.value := fpu_in.cdb(i).value;
                    end if;
                end loop;
            end if;
        end loop;

        -- busy or not
        v.fpu_out.free_count := (others => '0');
        for i in v.rs'reverse_range loop
            if not(v.rs(i).busy) then
                v.fpu_out.free_count := std_logic_vector(unsigned(v.fpu_out.free_count) + 1);
            end if;
        end loop;

        -- accepted by arbiter
        for i in fpu_in.accepts'reverse_range loop
            if fpu_in.accepts(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).rtag = fpu_in.accepts(i).rtag then
                        v.rs(j).busy := false;
                        v.rs(j).executing := false;
                        v.rs(j).outputting := false;
                    end if;
                end loop;
                for j in r.fpu_out.outputs'reverse_range loop
                    if v.fpu_out.outputs(j).to_rob.rtag = fpu_in.accepts(i).rtag then
                        v.fpu_out.outputs(j).valid := false;
                    end if;
                end loop;
            end if;
        end loop;

        fpu_out.outputs <= r.fpu_out.outputs; -- 出力は最短でも 1 クロック後
        fpu_out.free_count <= v.fpu_out.free_count; -- 空き rs 数はすぐに

        rin <= v;
    end process;

    reg : process(clk)
    begin
        if rising_edge(clk) then
            r <= rin;
        end if;
    end process;
end struct;
