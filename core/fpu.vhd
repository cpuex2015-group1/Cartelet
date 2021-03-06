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

    component fmul is
      Port (
        clk: in std_logic;
        input1 : in  std_logic_vector (31 downto 0);
        input2 : in  std_logic_vector (31 downto 0);
        output : out std_logic_vector (31 downto 0));
--        a : in  std_logic_vector (31 downto 0);
--        b : in  std_logic_vector (31 downto 0);
--        c : out std_logic_vector (31 downto 0));
    end component;

    component finv is
      Port (
        clk     : in  STD_LOGIC;
        input   : in  STD_LOGIC_VECTOR (31 downto 0);
        output  : out STD_LOGIC_VECTOR (31 downto 0));
    end component;

    component fsqrt is
      Port (
        clk     : in  STD_LOGIC;
        input   : in  STD_LOGIC_VECTOR (31 downto 0);
        output  : out STD_LOGIC_VECTOR (31 downto 0));
    end component;

    component floor is
      Port (
        clk     : in  STD_LOGIC;
        input   : in  STD_LOGIC_VECTOR (31 downto 0);
        output  : out STD_LOGIC_VECTOR (31 downto 0));
    end component;

    component ftoi is
      Port (
        clk     : in  STD_LOGIC;
        input   : in  STD_LOGIC_VECTOR (31 downto 0);
        output  : out STD_LOGIC_VECTOR (31 downto 0));
    end component;

    component itof is
      Port (
        clk     : in  STD_LOGIC;
        input   : in  STD_LOGIC_VECTOR (31 downto 0);
        output  : out STD_LOGIC_VECTOR (31 downto 0));
    end component;

    type rs_entry_type is record
        busy : boolean;
        executing : boolean;
        completed : boolean; -- fpu の各ユニットからの読み出しが終了した
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
        completed => false,
        counter => (others => '0'),
        command => (others => '0'),
        rtag => (others => '0'),
        data => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init);
    type rs_type is array(2 ** FPU_RS_ADDR_LENGTH - 1 downto 0) of rs_entry_type;
    type reg_type is record
        rs : rs_type;
        fadd_lhs : std_logic_vector(31 downto 0);
        fadd_rhs : std_logic_vector(31 downto 0);
        fmul_lhs : std_logic_vector(31 downto 0);
        fmul_rhs : std_logic_vector(31 downto 0);
        finv_lhs : std_logic_vector(31 downto 0);
        fsqrt_lhs : std_logic_vector(31 downto 0);
        floor_lhs : std_logic_vector(31 downto 0);
        ftoi_lhs : std_logic_vector(31 downto 0);
        itof_lhs : std_logic_vector(31 downto 0);
        fpu_out : fpu_out_type;
    end record;
    constant reg_init : reg_type := (
        rs => (others => rs_entry_init),
        fadd_lhs => (others => '0'),
        fadd_rhs => (others => '0'),
        fmul_lhs => (others => '0'),
        fmul_rhs => (others => '0'),
        finv_lhs => (others => '0'),
        fsqrt_lhs => (others => '0'),
        floor_lhs => (others => '0'),
        ftoi_lhs => (others => '0'),
        itof_lhs => (others => '0'),
        fpu_out => fpu_out_init);
    signal r, rin : reg_type := reg_init;

    signal fadd_output : std_logic_vector(31 downto 0);
    signal fmul_output : std_logic_vector(31 downto 0);
    signal finv_output : std_logic_vector(31 downto 0);
    signal fsqrt_output : std_logic_vector(31 downto 0);
    signal floor_output : std_logic_vector(31 downto 0);
    signal ftoi_output : std_logic_vector(31 downto 0);
    signal itof_output : std_logic_vector(31 downto 0);

begin
    fadd1: fadd port map (
        clk => clk,
        input1 => r.fadd_lhs,
        input2 => r.fadd_rhs,
        output => fadd_output
    );

    fmul1: fmul port map (
        clk => clk,
        input1 => r.fmul_lhs,
        input2 => r.fmul_rhs,
        output => fmul_output
--        a => r.fmul_lhs,
--        b => r.fmul_rhs,
--        c => fmul_output
    );

    finv1: finv port map (
        clk => clk,
        input => r.finv_lhs,
        output => finv_output
    );

    fsqrt1: fsqrt port map (
        clk => clk,
        input => r.fsqrt_lhs,
        output => fsqrt_output
    );

    floor1: floor port map (
        clk => clk,
        input => r.floor_lhs,
        output => floor_output
    );

    ftoi1: ftoi port map (
        clk => clk,
        input => r.ftoi_lhs,
        output => ftoi_output
    );

    itof1: itof port map (
        clk => clk,
        input => r.itof_lhs,
        output => itof_output
    );

    comb : process(r, fpu_in, fadd_output, fmul_output, finv_output, fsqrt_output, floor_output, ftoi_output, itof_output)
        variable v : reg_type := reg_init;
        variable num_free_entries : std_logic_vector(FPU_RS_ADDR_LENGTH downto 0);
        variable tmp : std_logic_vector(31 downto 0);
        variable fadd_busy : boolean := false;
        variable fmul_busy : boolean := false;
        variable finv_busy : boolean := false;
        variable fsqrt_busy : boolean := false;
        variable floor_busy : boolean := false;
        variable ftoi_busy : boolean := false;
        variable itof_busy : boolean := false;
        type fpu_in_dones_type is array(1 downto 0) of boolean;
        variable fpu_in_dones : fpu_in_dones_type := (others => false);
        variable output_count : integer := 0;
    begin
        v := r;

        fadd_busy := false;
        fmul_busy := false;
        finv_busy := false;
        fsqrt_busy := false;
        floor_busy := false;
        ftoi_busy := false;
        itof_busy := false;

        fpu_in_dones := (others => false);
        output_count := 0;

        v.fpu_out.outputs := (others => alu_out_body_entry_init);
        v.fpu_out.free_count := (others => '0');

        -- reset rs and output
        if fpu_in.reset_rs then
            for i in r.rs'reverse_range loop
                v.rs(i).busy := false;
                v.rs(i).executing := false;
                v.rs(i).completed := false;
            end loop;
            v.fpu_out.free_count := (others => '0');
        else
            for i in r.rs'reverse_range loop
                -- countdown
                if r.rs(i).counter /= "000" then
                    v.rs(i).counter := std_logic_vector(unsigned(r.rs(i).counter) - 1);
                end if;

                -- accepted by arbiter
                for j in fpu_in.accepts'reverse_range loop
                    if fpu_in.accepts(j).valid then
                        if r.rs(i).rtag = fpu_in.accepts(j).rtag then
                            v.rs(i).busy := false;
                            v.rs(i).executing := false;
                            v.rs(i).completed := false;
                        end if;
                    end if;
                end loop;

                -- execute
                if v.rs(i).busy and not v.rs(i).executing and not r.rs(i).lhs.busy and not r.rs(i).rhs.busy then
                    case r.rs(i).command is
                        when FPU_MOV =>
                            v.rs(i).counter := "000";
                            v.rs(i).executing := true;
                        when FPU_ADD =>
                            if not fadd_busy then
                                v.fadd_lhs := r.rs(i).lhs.value;
                                v.fadd_rhs := r.rs(i).rhs.value;
                                v.rs(i).counter := "010";
                                v.rs(i).executing := true;
                                fadd_busy := true;
                            end if;
                        when FPU_MUL =>
                            if not fmul_busy then
                                v.fmul_lhs := r.rs(i).lhs.value;
                                v.fmul_rhs := r.rs(i).rhs.value;
                                v.rs(i).counter := "010";
                                v.rs(i).executing := true;
                                fmul_busy := true;
                            end if;
                        when FPU_SUB =>
                            if not fadd_busy then
                                v.fadd_lhs := r.rs(i).lhs.value;
                                if r.rs(i).rhs.value(31) = '1' then
                                    v.fadd_rhs(31) := '0';
                                else
                                    v.fadd_rhs(31) := '1';
                                end if;
                                v.fadd_rhs(30 downto 0) := r.rs(i).rhs.value(30 downto 0);
                                v.rs(i).counter := "010";
                                v.rs(i).executing := true;
                                fadd_busy := true;
                            end if;
                        when FPU_INV =>
                            if not finv_busy then
                                v.finv_lhs := r.rs(i).lhs.value;
                                v.rs(i).counter := "011";
                                v.rs(i).executing := true;
                                finv_busy := true;
                            end if;
                        when FPU_SQRT =>
                            if not fsqrt_busy then
                                v.fsqrt_lhs := r.rs(i).lhs.value;
                                v.rs(i).counter := "011";
                                v.rs(i).executing := true;
                                fsqrt_busy := true;
                            end if;
                        when FPU_NEG =>
                            v.rs(i).counter := "000";
                            v.rs(i).executing := true;
                        when FPU_ABS =>
                            v.rs(i).counter := "000";
                            v.rs(i).executing := true;
                        when FPU_FLOOR =>
                            if not floor_busy then
                                v.floor_lhs := r.rs(i).lhs.value;
                                v.rs(i).counter := "010";
                                v.rs(i).executing := true;
                                floor_busy := true;
                            end if;
                        when FPU_FTOI =>
                            if not ftoi_busy then
                                v.ftoi_lhs := r.rs(i).lhs.value;
                                v.rs(i).counter := "010";
                                v.rs(i).executing := true;
                                ftoi_busy := true;
                            end if;
                        when FPU_ITOF =>
                            if not itof_busy then
                                v.itof_lhs := r.rs(i).lhs.value;
                                v.rs(i).counter := "010";
                                v.rs(i).executing := true;
                                itof_busy := true;
                            end if;
                        when others =>
                    end case;
                end if;

                -- read outputs from components
                if v.rs(i).busy and v.rs(i).executing and v.rs(i).counter = "000" and not v.rs(i).completed then
                    v.rs(i).completed := true; -- 1 clk しか実行されない
                    case v.rs(i).command is
                        when FPU_MOV =>
                            v.rs(i).data := r.rs(i).lhs.value;
                        when FPU_ADD =>
                            v.rs(i).data := fadd_output;
                        when FPU_MUL =>
                            v.rs(i).data := fmul_output;
                        when FPU_SUB =>
                            v.rs(i).data := fadd_output;
                        when FPU_INV =>
                            v.rs(i).data := finv_output;
                        when FPU_SQRT =>
                            v.rs(i).data := fsqrt_output;
                        when FPU_NEG =>
                            if r.rs(i).lhs.value(31) = '1' then
                                v.rs(i).data(31) := '0';
                            else
                                v.rs(i).data(31) := '1';
                            end if;
                            v.rs(i).data(30 downto 0) := r.rs(i).lhs.value(30 downto 0);
                        when FPU_ABS =>
                            v.rs(i).data(31) := '0';
                            v.rs(i).data(30 downto 0) := r.rs(i).lhs.value(30 downto 0);
                        when FPU_FLOOR =>
                            v.rs(i).data := floor_output;
                        when FPU_FTOI =>
                            v.rs(i).data := ftoi_output;
                        when FPU_ITOF =>
                            v.rs(i).data := itof_output;
                        when others =>
                    end case;
                end if;

                -- output
                if output_count < 2 and v.rs(i).busy and v.rs(i).completed then
                    v.fpu_out.outputs(output_count).valid := true;
                    v.fpu_out.outputs(output_count).to_rob.valid := true;
                    v.fpu_out.outputs(output_count).to_rob.rtag := v.rs(i).rtag;
                    v.fpu_out.outputs(output_count).to_rob.value := v.rs(i).data;
                    output_count := output_count + 1;
                end if;

                -- insert into RS
                INSERT_L1: for j in fpu_in.inputs'reverse_range loop
                    if not fpu_in_dones(j) and fpu_in.inputs(j).command /= FPU_NOP and not v.rs(i).busy then
                        v.rs(i).busy := true;
                        v.rs(i).executing := false;
                        v.rs(i).completed := false;
                        v.rs(i).command := fpu_in.inputs(j).command;
                        v.rs(i).rtag := fpu_in.inputs(j).rtag;
                        v.rs(i).lhs := fpu_in.inputs(j).lhs;
                        v.rs(i).rhs := fpu_in.inputs(j).rhs;
                        fpu_in_dones(j) := true;
                        exit INSERT_L1;
                    end if;
                end loop;

                -- watch the CDB
                for j in fpu_in.cdb'reverse_range loop
                    if fpu_in.cdb(j).valid then
                        if v.rs(i).lhs.busy and v.rs(i).lhs.rtag = fpu_in.cdb(j).rtag then
                            v.rs(i).lhs.busy := false;
                            v.rs(i).lhs.value := fpu_in.cdb(j).value;
                        end if;
                        if v.rs(i).rhs.busy and v.rs(i).rhs.rtag = fpu_in.cdb(j).rtag then
                            v.rs(i).rhs.busy := false;
                            v.rs(i).rhs.value := fpu_in.cdb(j).value;
                        end if;
                    end if;
                end loop;

                -- update free_count
                if not v.rs(i).busy then
                    v.fpu_out.free_count := std_logic_vector(unsigned(v.fpu_out.free_count) + 1);
                end if;
            end loop;
        end if;

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
