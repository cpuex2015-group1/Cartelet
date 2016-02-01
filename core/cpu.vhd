library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;
use work.decoder.all;

entity cpu is
    port (
        clk : in std_logic;
        cpu_in : in cpu_in_type;
        cpu_out : out cpu_out_type);
end entity;

architecture struct of cpu is
    component pmem is
        port (
            addra : IN STD_LOGIC_VECTOR(SINGLE_PMEM_ADDR_WIDTH DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            clka : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
    end component;

    type pmem_we_type is array(1 downto 0) of std_logic_vector(0 downto 0);
    type pmem_addr_type is array(1 downto 0) of std_logic_vector(SINGLE_PMEM_ADDR_WIDTH downto 0);
    type pmem_din_type is array(1 downto 0) of std_logic_vector(31 downto 0);
    type pmem_dout_type is array(1 downto 0) of std_logic_vector(31 downto 0);
    signal pmem_dout : pmem_dout_type;
    signal pmem_addr : pmem_addr_type;
    signal pmem_we : pmem_we_type;
    signal pmem_din : pmem_din_type;

    type rtype_type is (rtype_float, rtype_send, rtype_halt, rtype_others);

    type rob_entry_type is record
        valid : boolean;
        completed : boolean;
        rtype : rtype_type;
        reg_num : std_logic_vector(4 downto 0); -- not necessary
        value : std_logic_vector(31 downto 0);
    end record;
    constant rob_entry_init : rob_entry_type := (
        valid => false,
        completed => false,
        rtype => rtype_others,
        reg_num => (others => '0'),
        value => (others => '0'));
    type rob_entries_type is array((2 ** (TAG_WIDTH + 1) - 1) downto 0) of rob_entry_type;
    type rob_type is record
        entries : rob_entries_type;
        head : std_logic_vector(TAG_WIDTH downto 0);
        tail : std_logic_vector(TAG_WIDTH downto 0);
    end record;
    constant rob_init : rob_type := (
        entries => (others => rob_entry_init),
        head => (others => '0'),
        tail => (others => '0'));

    type buff32_type is record
        data : std_logic_vector(31 downto 0);
        bytes : std_logic_vector(1 downto 0);
        valid : boolean;
        fresh : boolean;
    end record;
    constant buff32_init : buff32_type := (
        data => (others => '0'),
        bytes => (others => '0'),
        valid => false,
        fresh => false);

    type fetch_decode_type is record
        first : integer;
        pc : std_logic_vector(PMEM_ADDR_WIDTH downto 0);
    end record;
    constant fetch_decode_init : fetch_decode_type := (
        first => 0,
        pc => (others => '0'));

    type insts_type is array(1 downto 0) of std_logic_vector(31 downto 0);

    constant PMEM_BUFF_WIDTH : integer := 3;
    type pmem_buff_type is array(2 ** PMEM_BUFF_WIDTH - 1 downto 0) of std_logic_vector(31 downto 0);
    signal pmem_buff : pmem_buff_type := (others => (others => '0'));

    type fetch_count_type is array(2 downto 0) of integer;

    type reg_type is record
        pmem_we : pmem_we_type;
        pmem_addr : pmem_addr_type;
        pmem_din : pmem_din_type;
        memory_out : memory_ctl_in_type;
        cpu_state : cpu_state_type;
        prev_recv : receiver_out_type;
        buff32 : buff32_type;
        load_size : std_logic_vector(23 downto 0);
        load_counter : std_logic_vector(23 downto 0);
        regs : reg_file_type;
        fregs : reg_file_type;
        cdb : cdb_type;
        rob : rob_type;
        alu_in : alu_in_type;
        sdu_in : sdu_in_type;
        cpu_out : cpu_out_type;
        fetch_decode : fetch_decode_type;
        fetch_count : fetch_count_type;
        issue_count : integer;
        insts : insts_type;
        pmem_dout : pmem_dout_type;
        stall_exec_schedule : std_logic_vector(3 downto 0);
        stall_fetch_schedule : std_logic_vector(3 downto 0);
        pbtl : integer;
        pbhd : integer;
        fetch_pc : std_logic_vector(PMEM_ADDR_WIDTH downto 0);
        pc : std_logic_vector(PMEM_ADDR_WIDTH downto 0);
    end record;
    constant reg_init : reg_type := (
        pmem_we => (others => (others => '0')),
        pmem_addr => (others => (others => '0')),
        pmem_din => (others => (others => '0')),
        memory_out => memory_ctl_in_init,
        cpu_state => ready,
        prev_recv => receiver_out_init,
        buff32 => buff32_init,
        load_size => (others => '0'),
        load_counter => (others => '0'),
        regs => (others => reg_file_entry_init),
        fregs => (others => reg_file_entry_init),
        cdb => cdb_init,
        rob => rob_init,
        alu_in => alu_in_init,
        sdu_in => sdu_in_init,
        cpu_out => cpu_out_init,
        fetch_decode => fetch_decode_init,
        fetch_count => (others => 0),
        issue_count => 0,
        insts => (others => (others => '0')),
        pmem_dout => (others => (others => '0')),
        stall_exec_schedule => (others => '0'),
        stall_fetch_schedule => (others => '0'),
        pbtl => 0,
        pbhd => 0,
        fetch_pc => (others => '0'),
        pc => (others => '0'));
    signal r, rin : reg_type := reg_init;
    signal alu_in : alu_in_type := alu_in_init;
    signal alu_out : alu_out_type := alu_out_init;
    signal sdu_in : sdu_in_type := sdu_in_init;
    signal sdu_out : sdu_out_type := sdu_out_init;
    signal cdb : cdb_type := cdb_init;
begin
    pmem0 : pmem port map (
        clka => clk,
        wea => pmem_we(0),
        addra => pmem_addr(0),
        dina => pmem_din(0),
        douta => pmem_dout(0));
    pmem1 : pmem port map (
        clka => clk,
        wea => pmem_we(1),
        addra => pmem_addr(1),
        dina => pmem_din(1),
        douta => pmem_dout(1));
    alu1 : alu port map (
        clk => clk,
        alu_in => alu_in,
        alu_out => alu_out);
    sdu1 : sdu port map (
        clk => clk,
        sdu_in => sdu_in,
        sdu_out => sdu_out);

    alu_in.cdb <= cdb;
    sdu_in.cdb <= cdb;

    comb : process (cpu_in, r, alu_out, sdu_out, pmem_dout)
        variable v : reg_type := reg_init;
        variable rob_head_ready : boolean := true;
        type rob_wb_entry_type is record
            valid : boolean;
            completed : boolean;
            rtype : rtype_type;
            rtag : std_logic_vector(TAG_WIDTH downto 0);
            value : std_logic_vector(31 downto 0);
        end record;
        constant rob_wb_entry_init : rob_wb_entry_type := (
            valid => false,
            completed => false,
            rtype => rtype_others,
            rtag => (others => '0'),
            value => (others => '0'));
        type rob_wb_type is array(1 downto 0) of rob_wb_entry_type;
        variable rob_wb : rob_wb_type := (others => rob_wb_entry_init);
        variable op : op_type := op_init;
        variable index : integer := 0;
        variable head_issued : boolean := true;
        variable sum : integer := 0;
    begin
        v := r;
        v.prev_recv := cpu_in.recv;

        v.pmem_we := (others => "0");

        v.buff32.fresh := false;
        v.cpu_out.receiver_pop := false;
        if not(r.prev_recv.valid) and cpu_in.recv.valid then
            v.cpu_out.receiver_pop := true;
            v.buff32.data := r.buff32.data(23 downto 0) & cpu_in.recv.data;
            v.buff32.bytes := std_logic_vector(unsigned(r.buff32.bytes) + 1);
            if v.buff32.bytes = "00" then
                v.buff32.valid := true;
                v.buff32.fresh := true;
            else
                v.buff32.valid := false;
            end if;
        end if;

        case r.cpu_state is
            when ready =>
                if r.buff32.fresh then
                    case r.buff32.data(31 downto 24) is
                        when CMD_PLOAD =>
                            v.cpu_state := ploading;
                            v.load_size(23 downto PMEM_ADDR_WIDTH + 1) := (others => '0');
                            v.load_size(PMEM_ADDR_WIDTH downto 0) := r.buff32.data(PMEM_ADDR_WIDTH downto 0);
                            v.load_counter := (others => '0');
                        when CMD_DLOAD =>
                            v.cpu_state := dloading;
                            v.load_size(23 downto SRAM_ADDR_WIDTH + 1) := (others => '0');
                            v.load_size(SRAM_ADDR_WIDTH downto 0) := r.buff32.data(SRAM_ADDR_WIDTH downto 0);
                            v.load_counter := (others => '0');
                        when CMD_EXEC =>
                            for i in v.pmem_addr'range loop
                                v.pmem_addr(i) := (others => '0');
                            end loop;
                            v.pc := (others => '0');
                            v.fetch_pc := (1 => '1', others => '0');
                            v.pbhd := 0;
                            v.pbtl := 0;
                            v.stall_exec_schedule := (others => '0');
                            v.stall_fetch_schedule := (1 => '1', others => '0');
                            v.cpu_state := running;
                        when others =>
                    end case;
                end if;
            when ploading =>
                if unsigned(r.load_counter) < unsigned(r.load_size) then
                    if r.buff32.fresh then
                        v.pmem_addr(to_integer(unsigned(r.load_counter(0 downto 0)))) := r.load_counter(SINGLE_PMEM_ADDR_WIDTH + 1 downto 1);
                        v.pmem_din(to_integer(unsigned(r.load_counter(0 downto 0)))) := r.buff32.data;
                        v.pmem_we(to_integer(unsigned(r.load_counter(0 downto 0)))) := "1";
                        v.load_counter := std_logic_vector(unsigned(r.load_counter) + 1);
                    end if;
                else
                    v.cpu_state := ready;
					for i in v.pmem_addr'range loop
						v.pmem_addr(i) := (others => '0');
					end loop;
                end if;
            when dloading =>
                if unsigned(r.load_counter) < unsigned(r.load_size) then
                    if r.buff32.fresh then
                        v.memory_out.data := r.buff32.data;
                        v.memory_out.addr := r.load_counter(SRAM_ADDR_WIDTH downto 0);
                        v.memory_out.we := true;
                    end if;
                else
                    v.cpu_state := ready;
                end if;
            when running =>

                -- ストールスケジュールをシフト
                v.stall_exec_schedule := '0' & r.stall_exec_schedule(3 downto 1);
                v.stall_fetch_schedule := '0' & r.stall_fetch_schedule(3 downto 1);

                -- shift fetch_count
                for i in 0 to r.fetch_count'length - 2 loop
                    v.fetch_count(i) := r.fetch_count(i + 1);
                end loop;
                v.fetch_count(r.fetch_count'length - 1) := 0;

                -- sender に送り続けるのを防ぐため
                v.cpu_out.send.go := false;


                ---- complete
                -- complete rob entry
                rob_head_ready := true;
                for i in 0 to 1 loop
                    index := to_integer(unsigned(v.rob.head));
                    if rob_head_ready and r.rob.entries(index).valid and r.rob.entries(index).completed then
                        if r.rob.entries(index).rtype = rtype_halt then
                            if i = 0 then -- halt は rob の先頭に来たときだけ有効
                                v := reg_init; -- まっさらにする
                            end if;
                        else
                            if r.rob.entries(index).rtype = rtype_send and not cpu_in.sender_busy then
                                -- send
                                v.cpu_out.send.data := v.rob.entries(index).value(7 downto 0);
                                v.cpu_out.send.go := true;
                            elsif index = to_integer(unsigned(r.regs(to_integer(unsigned(r.rob.entries(index).reg_num))).rtag)) then -- TODO: floating 区別
                                -- reg へ書き戻し
                                v.regs(to_integer(unsigned(r.rob.entries(index).reg_num))).busy := false;
                                v.regs(to_integer(unsigned(r.rob.entries(index).reg_num))).value := r.rob.entries(index).value;
                            end if;

                            v.rob.entries(index).valid := false;
                            v.rob.head := std_logic_vector(unsigned(v.rob.head) + 1);
                        end if;
                    else
                        rob_head_ready := false;
                    end if;
                end loop;

                ---- decode & issue
                -- ここでの issue_count は *前の* クロックで実行した命令数
                v.alu_in := alu_in_init;
                v.sdu_in := sdu_in_init;
                if r.stall_exec_schedule(0) = '0' then

                    -- 実行対象命令取得
                    -- TODO: validation (stall_exec_schedule でよい気もするが branch 実装時に考えよう)
                    v.insts(0) := pmem_buff(to_integer(to_unsigned(r.pbhd, PMEM_BUFF_WIDTH)));
                    v.insts(1) := pmem_buff(to_integer(to_unsigned(r.pbhd + 1, PMEM_BUFF_WIDTH)));


                    v.issue_count := 0;
                    head_issued := true;
                    for i in r.insts'reverse_range loop -- insts'range だと降順
                        decode(v.insts(i), op);
                        if unsigned(v.rob.tail) + 1 /= unsigned(v.rob.head) and head_issued then
                            case op.rs_tag is
                                when rs_alu =>
                                    if unsigned(alu_out.free_count) > v.issue_count then
                                        v.alu_in.inputs(v.issue_count).command := op.command;
                                        v.alu_in.inputs(v.issue_count).rtag := v.rob.tail;
                                        v.alu_in.inputs(v.issue_count).lhs.busy := v.regs(to_integer(unsigned(op.reg2))).busy; -- そのクロックで書き戻された値を使いたいからv
                                        v.alu_in.inputs(v.issue_count).lhs.rtag := v.regs(to_integer(unsigned(op.reg2))).rtag;
                                        v.alu_in.inputs(v.issue_count).lhs.value := v.regs(to_integer(unsigned(op.reg2))).value;
                                        if op.use_imm then
                                            v.alu_in.inputs(v.issue_count).rhs.busy := false;
    --                                        v.alu_in.inputs(v.issue_count).rhs.rtag := (others => '1'); -- 何でもいい
                                            v.alu_in.inputs(v.issue_count).rhs.value(31 downto 16) := (others => op.imm(15));
                                            v.alu_in.inputs(v.issue_count).rhs.value(15 downto 0) := op.imm;
                                        else
                                            v.alu_in.inputs(v.issue_count).rhs.busy := v.regs(to_integer(unsigned(op.reg3))).busy;
                                            v.alu_in.inputs(v.issue_count).rhs.rtag := v.regs(to_integer(unsigned(op.reg3))).rtag;
                                            v.alu_in.inputs(v.issue_count).rhs.value := v.regs(to_integer(unsigned(op.reg3))).value;
                                        end if;

                                        v.regs(to_integer(unsigned(op.reg1))).busy := true;
                                        v.regs(to_integer(unsigned(op.reg1))).rtag := v.alu_in.inputs(v.issue_count).rtag;

                                        v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := op.reg1;
                                        v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                        v.issue_count := v.issue_count + 1;
                                    else
                                        head_issued := false;
                                    end if;
                                when rs_send =>
                                    if unsigned(sdu_out.free_count) > v.issue_count then
                                        v.sdu_in.inputs(v.issue_count).valid := true;
                                        v.sdu_in.inputs(v.issue_count).rtag := v.rob.tail;
                                        v.sdu_in.inputs(v.issue_count).reg.busy := v.regs(to_integer(unsigned(op.reg1))).busy;
                                        v.sdu_in.inputs(v.issue_count).reg.rtag := v.regs(to_integer(unsigned(op.reg1))).rtag;
                                        v.sdu_in.inputs(v.issue_count).reg.value := v.regs(to_integer(unsigned(op.reg1))).value;

                                        v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_send;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := op.reg1;
                                        v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                        v.issue_count := v.issue_count + 1;
                                    else
                                        head_issued := false;
                                    end if;
                                when rs_halt =>
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).completed := true;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_halt;
                                    v.issue_count := v.issue_count + 1;
                                when others =>
                                    head_issued := false;
                            end case;
                        end if;
                    end loop;
                    v.pc := std_logic_vector(unsigned(v.pc) + v.issue_count);


                    v.pbhd := to_integer(to_unsigned(r.pbhd + v.issue_count, PMEM_BUFF_WIDTH));
                end if;

                ---- executed
                -- arbiter determines what data is to be sent to the cdb
                v.cdb := cdb_init;
                v.alu_in.accepts := alu_in_init.accepts;
                v.sdu_in.accepts := sdu_in_init.accepts;
                rob_wb := (others => rob_wb_entry_init);
                for i in 1 downto 0 loop
                    if alu_out.outputs(i).valid then
                        v.cdb(i).valid := alu_out.outputs(i).to_cdb.valid;
                        v.cdb(i).rtag := alu_out.outputs(i).to_cdb.rtag;
                        v.cdb(i).value := alu_out.outputs(i).to_cdb.value;

                        rob_wb(i).valid := true;
                        rob_wb(i).completed := true;
                        rob_wb(i).rtag := alu_out.outputs(i).to_rob.rtag;
                        rob_wb(i).value := alu_out.outputs(i).to_rob.value;

                        v.alu_in.accepts(i).valid := true;
                        v.alu_in.accepts(i).rtag := alu_out.outputs(i).to_rob.rtag;
                    elsif sdu_out.to_rob.valid then
                        rob_wb(i).valid := true;
                        rob_wb(i).completed := true;
                        rob_wb(i).rtag := sdu_out.to_rob.rtag;
                        rob_wb(i).value := sdu_out.to_rob.value;
                        rob_wb(i).rtype := rtype_send;

                        v.sdu_in.accepts(i).valid := true;
                        v.sdu_in.accepts(i).rtag := sdu_out.to_rob.rtag;
                    end if;
                end loop;

                -- update rob entry
                for i in rob_wb'range loop
                    if rob_wb(i).valid then
                        v.rob.entries(to_integer(unsigned(rob_wb(i).rtag))).completed := true;
                        v.rob.entries(to_integer(unsigned(rob_wb(i).rtag))).value := rob_wb(i).value;
                        v.rob.entries(to_integer(unsigned(rob_wb(i).rtag))).rtype := rob_wb(i).rtype;
                    end if;
                end loop;

                ---- fetch
                -- NOTE: 2 issue specific
                v.pbtl := to_integer(to_unsigned(r.pbtl + r.fetch_count(0), PMEM_BUFF_WIDTH));

                sum := 0;
                for i in r.fetch_count'reverse_range loop
                    sum := sum + r.fetch_count(i);
                end loop;

                -- いくつバッファに入れるか指定
                if v.pbtl < v.pbhd then
                    if v.pbhd - v.pbtl > 3 then
                        v.fetch_count(1) := 2;
                    elsif v.pbhd - v.pbtl > 2 then
                        v.fetch_count(1) := 1;
                    else
                        v.fetch_count(1) := 0;
                    end if;
                elsif v.pbtl > v.pbhd then
                    if 8 + v.pbhd - v.pbtl > 3 then -- 8 = 2 ** PMEM_BUFF_WIDTH
                        v.fetch_count(1) := 2;
                    elsif 8 + v.pbhd - v.pbtl > 2 then
                        v.fetch_count(1) := 1;
                    else
                        v.fetch_count(1) := 0;
                    end if;
                else -- その他は初期状態しかない（ように上で調整している）
                    v.fetch_count(1) := 2;
                end if;

                -- 常に二つずつ持ってくる
                if r.fetch_pc(0) = '0' then
                    v.pmem_addr(0) := r.fetch_pc(PMEM_ADDR_WIDTH downto 1);
                    v.pmem_addr(1) := r.fetch_pc(PMEM_ADDR_WIDTH downto 1);
                    v.fetch_decode.first := 0;
                else
                    v.pmem_addr(1) := r.fetch_pc(PMEM_ADDR_WIDTH downto 1);
                    v.pmem_addr(0) := std_logic_vector(unsigned(r.fetch_pc(PMEM_ADDR_WIDTH downto 1)) + 1);
                    v.fetch_decode.first := 1;
                end if;
                v.fetch_pc := std_logic_vector(to_unsigned(to_integer(unsigned(r.fetch_pc)) + v.fetch_count(1), PMEM_ADDR_WIDTH + 1)); -- 次に与えるアドレスの一つ目
        end case;

        pmem_din <= r.pmem_din;
        pmem_we <= r.pmem_we;
        pmem_addr <= r.pmem_addr;
        alu_in.inputs <= r.alu_in.inputs;
        alu_in.accepts <= r.alu_in.accepts;
        sdu_in.inputs <= r.sdu_in.inputs;
        sdu_in.accepts <= r.sdu_in.accepts;
        cpu_out <= r.cpu_out;
        cdb <= r.cdb;

        rin <= v;
    end process;

    reg : process (clk)
        variable tmp : std_logic_vector(0 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            -- fetch してきたものをバッファへ入れる
            if rin.stall_fetch_schedule(0) = '0' then
                for i in 0 to 1 loop
                    if i < rin.fetch_count(0) then
                        tmp := std_logic_vector(to_unsigned(i + rin.fetch_decode.first, 1));
                        pmem_buff(to_integer(to_unsigned(rin.pbtl + i, PMEM_BUFF_WIDTH))) <= pmem_dout(to_integer(unsigned(tmp)));
                    end if;
                end loop;
            end if;
            r <= rin;
        end if;
    end process;
end struct;
