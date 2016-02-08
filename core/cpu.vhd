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

    type rtype_type is (rtype_float, rtype_send, rtype_branch, rtype_jump, rtype_jal, rtype_store, rtype_load, rtype_halt, rtype_others);

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
    type rob_entries_type is array((2 ** TAG_LENGTH - 1) downto 0) of rob_entry_type;
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

    type fetch_count_type is array(3 downto 0) of integer;

    type fetch_decode_type is record
        first : fetch_count_type;
        pc : std_logic_vector(PMEM_ADDR_WIDTH downto 0);
    end record;
    constant fetch_decode_init : fetch_decode_type := (
        first => (others => 0),
        pc => (others => '0'));

    type insts_type is array(1 downto 0) of std_logic_vector(31 downto 0);

    constant PMEM_BUFF_LENGTH : integer := 3;
    type pmem_buff_type is array(2 ** PMEM_BUFF_LENGTH - 1 downto 0) of std_logic_vector(31 downto 0);
    signal pmem_buff : pmem_buff_type := (others => (others => '0'));

    type reg_type is record
        ZA : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
        ZD : std_logic_vector(31 downto 0);
        zd_enable : boolean;
        XWA : std_logic;
        pmem_we : pmem_we_type;
        pmem_addr : pmem_addr_type;
        pmem_din : pmem_din_type;
        cpu_state : cpu_state_type;
        prev_recv : receiver_out_type;
        buff32 : buff32_type;
        load_size : std_logic_vector(23 downto 0);
        load_counter : std_logic_vector(23 downto 0);
        regs : reg_file_type;
        fregs : reg_file_type;
        cdb : cdb_type;
        accepts : accepts_type;
        reset_rs : boolean;
        rob : rob_type;
        alu_in : alu_in_type;
        sdu_in : sdu_in_type;
        bru_in : bru_in_type;
        mcu_in : mcu_in_type;
        cpu_out : cpu_out_type;
        fetch_decode : fetch_decode_type;
        fetch_count : fetch_count_type;
        issue_count : integer;
        alu_ic : integer;
        bru_ic : integer;
        sdu_ic : integer;
        mcu_ic : integer;
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
        ZA => (others => '0'),
        ZD => (others => '0'),
        zd_enable => false,
        XWA => '1',
        pmem_we => (others => (others => '0')),
        pmem_addr => (others => (others => '0')),
        pmem_din => (others => (others => '0')),
        cpu_state => ready,
        prev_recv => receiver_out_init,
        buff32 => buff32_init,
        load_size => (others => '0'),
        load_counter => (others => '0'),
        regs => (others => reg_file_entry_init),
        fregs => (others => reg_file_entry_init),
        cdb => cdb_init,
        accepts => (others => accept_init),
        reset_rs => false,
        rob => rob_init,
        alu_in => alu_in_init,
        sdu_in => sdu_in_init,
        bru_in => bru_in_init,
        mcu_in => mcu_in_init,
        cpu_out => cpu_out_init,
        fetch_decode => fetch_decode_init,
        fetch_count => (others => 0),
        issue_count => 0,
        alu_ic => 0,
        bru_ic => 0,
        sdu_ic => 0,
        mcu_ic => 0,
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
    signal bru_in : bru_in_type := bru_in_init;
    signal bru_out : bru_out_type := bru_out_init;
    signal mcu_in : mcu_in_type := mcu_in_init;
    signal mcu_out : mcu_out_type := mcu_out_init;
    signal cdb : cdb_type := cdb_init;
    signal accepts : accepts_type := (others => accept_init);
    signal reset_rs : boolean;
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
    bru1 : bru port map (
        clk => clk,
        bru_in => bru_in,
        bru_out => bru_out);
    mcu1 : mcu port map (
        clk => clk,
        mcu_in => mcu_in,
        mcu_out => mcu_out);

    alu_in.cdb <= cdb;
    sdu_in.cdb <= cdb;
    bru_in.cdb <= cdb;
    mcu_in.cdb <= cdb;

    alu_in.accepts <= accepts;
    sdu_in.accepts <= accepts;
    bru_in.accepts <= accepts;
    mcu_in.accepts <= accepts;

    alu_in.reset_rs <= reset_rs;
    sdu_in.reset_rs <= reset_rs;
    bru_in.reset_rs <= reset_rs;
    mcu_in.reset_rs <= reset_rs;

    mcu_in.ZD <= cpu_in.ZD;


    comb : process (cpu_in, r, alu_out, sdu_out, bru_out, mcu_out, pmem_dout)
        variable v : reg_type := reg_init;
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
        variable tmp_pc : std_logic_vector(PMEM_ADDR_WIDTH + 1 downto 0) := (others => '0');
        variable fetch_pc_updated : boolean := false;
    begin
        tmp_pc := (others => '0');
        head_issued := true;
        sum := 0;
        index := 0;
        fetch_pc_updated := false;




        v := r;
        v.prev_recv := cpu_in.recv;
        v.pmem_we := (others => "0");
        v.reset_rs := false;
        v.ZA := (others => '0');
        v.ZD := (others => '0');
        v.zd_enable := false;
        v.XWA := '1';

        v.alu_in := alu_in_init;
        v.sdu_in := sdu_in_init;
        v.bru_in := bru_in_init;
        v.mcu_in := mcu_in_init;




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
                            v.fetch_pc := (others => '0');
                            v.pbhd := 0;
                            v.pbtl := 0;
                            v.stall_exec_schedule := (others => '0');
                            v.stall_fetch_schedule := (others => '0');
--                            v.fetch_count := (2 => 2, others => 0);
                            v.cpu_state := running;

			    v.buff32 := buff32_init;
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
                        v.ZD := r.buff32.data;
                        v.ZA := r.load_counter(SRAM_ADDR_WIDTH downto 0);
                        v.XWA := '0';
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

                -- shift first
                for i in 0 to r.fetch_decode.first'length - 2 loop
                    v.fetch_decode.first(i) := r.fetch_decode.first(i + 1);
                end loop;
                v.fetch_decode.first(r.fetch_decode.first'length - 1) := 0;

                -- sender に送り続けるのを防ぐため
                v.cpu_out.send.go := false;


                ---- complete
                -- complete rob entry
		index := to_integer(unsigned(r.rob.head));
                COMPLETE_L1: for i in 0 to 1 loop -- いくつ同時に complete させるかここで決める
                    if r.rob.entries(index).valid and r.rob.entries(index).completed then
                        if r.rob.entries(index).rtype = rtype_halt then
                            if i = 0 then -- halt は rob の先頭に来たときだけ有効
				v.cpu_state := ready;
                            end if;
			else
			    v.pc := std_logic_vector(unsigned(v.pc) + 1);
			    v.rob.entries(index).valid := false;
			    v.rob.entries(index).completed := false;

			    if r.rob.entries(index).rtype = rtype_branch then
				if r.rob.entries(index).value(31) = '0' then -- 正しく分岐している
				    v.rob.entries(index).valid := false;
				    v.rob.entries(index).completed := false;
				else -- 間違えた
				    -- プログラムバッファを空にする
				    v.pbhd := 0;
				    v.pbtl := 0;
				    -- NOTE: v.pc がすでに +1 されていることに注意
				    -- NOTE: ここは、pmem の幅が 15bit だから正しい
				    -- 16bit より大きくなったらちゃんと符号拡張しなければならない
				    tmp_pc := std_logic_vector(signed('0' & v.pc) + signed(r.rob.entries(index).value(PMEM_ADDR_WIDTH + 1 downto 0)));
				    v.fetch_pc := tmp_pc(PMEM_ADDR_WIDTH downto 0);
				    v.pc := tmp_pc(PMEM_ADDR_WIDTH downto 0);

				    v.stall_exec_schedule := "1111";
				    fetch_pc_updated := true;

				    -- rob も空にする
				    v.rob.tail := (others => '0');
				    v.rob.entries := (others => rob_entry_init);

				    -- rs も空にする
				    v.reset_rs := true;

				    -- busy な reg も解放する
				    for j in r.regs'reverse_range loop
					v.regs(j).busy := false;
				    end loop;

				    exit COMPLETE_L1;
				end if;
			    elsif r.rob.entries(index).rtype = rtype_jump or r.rob.entries(index).rtype = rtype_jal then -- TODO: あまりにも効率が悪い
				-- jr, jal
				-- プログラムバッファを空にする
				v.pbhd := 0;
				v.pbtl := 0;

				-- NOTE: ここが branch と違う
				-- jal なら regs(31) に pc 待避
                                if r.rob.entries(index).rtype = rtype_jal then
                                    if index = to_integer(unsigned(r.regs(31).rtag)) then
                                        v.regs(31).busy := false;
                                    end if;
				    v.regs(31).value(31 downto PMEM_ADDR_WIDTH + 1) := (others => '0');
				    v.regs(31).value(PMEM_ADDR_WIDTH downto 0) := v.pc; -- 上ですでに +1 しているので pc + 1
				end if;

				v.fetch_pc := r.rob.entries(index).value(PMEM_ADDR_WIDTH downto 0);
				v.pc := r.rob.entries(index).value(PMEM_ADDR_WIDTH downto 0);


				v.stall_exec_schedule := "1111";
				fetch_pc_updated := true;

				-- rob も空にする
				v.rob.tail := (others => '0');
				v.rob.entries := (others => rob_entry_init);

				-- rs も空にする
				v.reset_rs := true;

				-- busy な reg も解放する
				for j in r.regs'reverse_range loop
				    v.regs(j).busy := false;
				end loop;

				exit COMPLETE_L1;
			    else
				if r.rob.entries(index).rtype = rtype_send and not cpu_in.sender_busy then
				    -- send
				    v.cpu_out.send.data := v.rob.entries(index).value(7 downto 0);
				    v.cpu_out.send.go := true;
				elsif r.rob.entries(index).rtype = rtype_store then
				    -- ここで本当にメモリへ書き込む
				    v.mcu_in.exec_store(i).valid := true;
				    v.mcu_in.exec_store(i).buff_index := r.rob.entries(index).value(MCU_STORE_BUFF_WIDTH downto 0);
                                else
				    -- reg へ書き戻し
				    -- alu 命令と load
				    -- TODO: floating 区別
                                    if index = to_integer(unsigned(r.regs(to_integer(unsigned(r.rob.entries(index).reg_num))).rtag)) then
                                        v.regs(to_integer(unsigned(r.rob.entries(index).reg_num))).busy := false;
                                    end if;
				    v.regs(to_integer(unsigned(r.rob.entries(index).reg_num))).value := r.rob.entries(index).value;
				end if;
			    end if;
			    index := to_integer(to_unsigned(index + 1, TAG_LENGTH));
			end if;
                    else
                        exit COMPLETE_L1;
                    end if;
                end loop;

		if fetch_pc_updated then
                    v.rob.head := (others => '0');
                else
		    v.rob.head := std_logic_vector(to_unsigned(index, TAG_LENGTH));
		end if;

                ---- decode & issue
                -- ここでの issue_count は *前の* クロックで実行した命令数
                if v.stall_exec_schedule(0) = '0' then

                    -- 実行対象命令取得
                    -- TODO: validation (stall_exec_schedule でよい気もするが branch 実装時に考えよう)
                    v.insts(0) := pmem_buff(to_integer(to_unsigned(r.pbhd, PMEM_BUFF_LENGTH)));
                    v.insts(1) := pmem_buff(to_integer(to_unsigned(r.pbhd + 1, PMEM_BUFF_LENGTH)));


                    v.issue_count := 0;
                    v.alu_ic := 0;
                    v.bru_ic := 0;
                    v.sdu_ic := 0;
                    v.mcu_ic := 0;
                    for i in r.insts'reverse_range loop -- insts'range だと降順
                        decode(v.insts(i), op);
                        if unsigned(r.rob.tail) + i + 1 /= unsigned(r.rob.head) and head_issued then -- ここのチェックは r で、今のクロックのrobの状態は反映していないので分岐ミスなどでrobが消えていた時は上のstall_exec_scheduleでバリデーションする
                            case op.rs_tag is
                                when rs_alu =>
                                    if unsigned(alu_out.free_count) > v.alu_ic then
                                        v.alu_in.inputs(v.alu_ic).command := op.command;
                                        v.alu_in.inputs(v.alu_ic).rtag := v.rob.tail;
                                        v.alu_in.inputs(v.alu_ic).lhs := v.regs(to_integer(unsigned(op.reg2))); -- そのクロックで書き戻された値を使いたいからv
                                        if op.use_imm then
                                            v.alu_in.inputs(v.alu_ic).rhs.busy := false;
                                            v.alu_in.inputs(v.alu_ic).rhs.rtag := (others => '-');
                                            v.alu_in.inputs(v.alu_ic).rhs.value(31 downto 16) := (others => op.imm(15));
                                            v.alu_in.inputs(v.alu_ic).rhs.value(15 downto 0) := op.imm;
                                        else
                                            v.alu_in.inputs(v.alu_ic).rhs := v.regs(to_integer(unsigned(op.reg3)));
                                        end if;

                                        v.regs(to_integer(unsigned(op.reg1))).busy := true;
                                        v.regs(to_integer(unsigned(op.reg1))).rtag := v.alu_in.inputs(v.alu_ic).rtag;

                                        v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := op.reg1;
                                        v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                        v.alu_ic := v.alu_ic + 1;
                                    else
                                        head_issued := false;
                                    end if;
                                when rs_send =>
                                    if unsigned(sdu_out.free_count) > v.sdu_ic then
                                        v.sdu_in.inputs(v.sdu_ic).valid := true;
                                        v.sdu_in.inputs(v.sdu_ic).rtag := v.rob.tail;
                                        v.sdu_in.inputs(v.sdu_ic).reg := v.regs(to_integer(unsigned(op.reg1)));

                                        v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_send;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := op.reg1;
                                        v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                        v.sdu_ic := v.sdu_ic + 1;
                                    else
                                        head_issued := false;
                                    end if;
                                when rs_branch =>
                                    if unsigned(bru_out.free_count) > v.bru_ic then
                                        v.bru_in.input.rtag := v.rob.tail;
                                        v.bru_in.input.command := op.command;
                                        v.bru_in.input.lhs := v.regs(to_integer(unsigned(op.reg1)));
                                        v.bru_in.input.rhs := v.regs(to_integer(unsigned(op.reg2)));
                                        v.bru_in.input.taken := false; -- TODO: 分岐予測
                                        v.bru_in.input.offset := op.imm;

                                        v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_branch;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := (others => '-');
                                        v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                        v.bru_ic := v.bru_ic + 1;
                                    else
                                        head_issued := false;
                                    end if;
                                when rs_memory =>
                                    if unsigned(mcu_out.free_count) > v.mcu_ic then
                                        v.mcu_in.inputs(v.mcu_ic).command := op.command;
                                        v.mcu_in.inputs(v.mcu_ic).rtag := v.rob.tail;
                                        -- lhs : address
                                        -- imm : displacement
                                        -- rhs : data
                                        v.mcu_in.inputs(v.mcu_ic).imm := op.imm;
                                        if op.opcode = OP_SW then
                                            v.mcu_in.inputs(v.mcu_ic).lhs := v.regs(to_integer(unsigned(op.reg1)));
                                            v.mcu_in.inputs(v.mcu_ic).rhs := v.regs(to_integer(unsigned(op.reg2)));
                                        else
                                            v.mcu_in.inputs(v.mcu_ic).lhs := v.regs(to_integer(unsigned(op.reg2)));
                                            v.mcu_in.inputs(v.mcu_ic).rhs.busy := false;
                                            v.mcu_in.inputs(v.mcu_ic).rhs.rtag := (others => '-');
                                            v.mcu_in.inputs(v.mcu_ic).rhs.value := (others => '-');
                                        end if;

                                        if op.opcode = OP_LW then
                                            v.regs(to_integer(unsigned(op.reg1))).busy := true;
                                            v.regs(to_integer(unsigned(op.reg1))).rtag := v.rob.tail;
                                        end if;

                                        v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                        if op.opcode = OP_SW then
                                            v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_store;
                                            v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := (others => '-');
                                        else
                                            v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_load;
                                            v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := op.reg1;
                                        end if;
                                        v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                        v.mcu_ic := v.mcu_ic + 1;
                                    else
                                        head_issued := false;
                                    end if;
				when rs_jump =>
				    -- ALU に入れる
				    -- ジャンプ先のアドレスを知りたいだけなので、レジスタの値解決ができればそれでいい
				    -- reg1 + 0 を計算することで代用している
                                    if unsigned(alu_out.free_count) > v.alu_ic then
                                        v.alu_in.inputs(v.alu_ic).command := ALU_ADD;
                                        v.alu_in.inputs(v.alu_ic).rtag := v.rob.tail;
                                        v.alu_in.inputs(v.alu_ic).lhs := v.regs(to_integer(unsigned(op.reg1))); -- そのクロックで書き戻された値を使いたいからv
					v.alu_in.inputs(v.alu_ic).rhs.busy := false;
					v.alu_in.inputs(v.alu_ic).rhs.rtag := (others => '-');
					v.alu_in.inputs(v.alu_ic).rhs.value(31 downto 0) := (others => '0');

                                        v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).reg_num := (others => '-');
                                        v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_jump;
                                        v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                        v.alu_ic := v.alu_ic + 1;
                                    else
                                        head_issued := false;
                                    end if;
				when rs_jal =>
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).completed := true;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_jal;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).value(25 downto 0) := op.addr;

				    v.regs(31).busy := true;
				    v.regs(31).rtag := v.rob.tail;

				    v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                    v.issue_count := v.issue_count + 1;
                                when rs_halt =>
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))) := rob_entry_init;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).valid := true;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).completed := true;
                                    v.rob.entries(to_integer(unsigned(v.rob.tail))).rtype := rtype_halt;

				    v.rob.tail := std_logic_vector(unsigned(v.rob.tail) + 1);

                                    v.issue_count := v.issue_count + 1;
                                when others =>
                                    head_issued := false;
                            end case;
                        end if;
                    end loop;
                    v.issue_count := v.issue_count + v.alu_ic + v.sdu_ic + v.bru_ic + v.mcu_ic;

                    -- プログラムバッファの先頭を進める
                    v.pbhd := to_integer(to_unsigned(r.pbhd + v.issue_count, PMEM_BUFF_LENGTH));
                end if;

                ---- executed
                -- arbiter determines what data is to be sent to the cdb
                v.cdb := cdb_init;
                v.accepts := (others => accept_init);
                rob_wb := (others => rob_wb_entry_init);
                for i in r.cdb'reverse_range loop
                    if alu_out.outputs(i).valid then
                        v.cdb(i).valid := alu_out.outputs(i).to_rob.valid;
                        v.cdb(i).rtag := alu_out.outputs(i).to_rob.rtag;
                        v.cdb(i).value := alu_out.outputs(i).to_rob.value;

                        rob_wb(i).valid := true;
                        rob_wb(i).completed := true;
                        rob_wb(i).rtag := alu_out.outputs(i).to_rob.rtag;
                        rob_wb(i).value := alu_out.outputs(i).to_rob.value;

                        v.accepts(i).valid := true;
                        v.accepts(i).rtag := alu_out.outputs(i).to_rob.rtag;
                    elsif i = 0 and sdu_out.to_rob.valid then -- TODO: 今は cdb(0) にしか流さないが、もっとまともな選別をする
                        rob_wb(i).valid := true;
                        rob_wb(i).completed := true;
                        rob_wb(i).rtag := sdu_out.to_rob.rtag;
                        rob_wb(i).value := sdu_out.to_rob.value;

                        v.accepts(i).valid := true;
                        v.accepts(i).rtag := sdu_out.to_rob.rtag;
                    elsif i = 1 and bru_out.output.to_rob.valid then -- TODO: 今は cdb(1) にしか流さないが、もっとまともな選別をする
                        rob_wb(i).valid := true;
                        rob_wb(i).completed := true;
                        rob_wb(i).rtag := bru_out.output.to_rob.rtag;
                        rob_wb(i).value := bru_out.output.to_rob.value;

                        v.accepts(i).valid := true;
                        v.accepts(i).rtag := bru_out.output.to_rob.rtag;
                    elsif mcu_out.outputs(i).valid then
                        if mcu_out.outputs(i).to_rob.valid then -- mcu では to_rob.valid を cdb への書き込みフラグにしている
                            v.cdb(i).valid := true;
                            v.cdb(i).rtag := mcu_out.outputs(i).to_rob.rtag;
                            v.cdb(i).value := mcu_out.outputs(i).to_rob.value;
                        end if;

                        rob_wb(i).valid := true;
                        rob_wb(i).completed := true;
                        rob_wb(i).rtag := mcu_out.outputs(i).to_rob.rtag;
                        rob_wb(i).value := mcu_out.outputs(i).to_rob.value;

                        v.accepts(i).valid := true;
                        v.accepts(i).rtag := mcu_out.outputs(i).to_rob.rtag;
                    end if;
                end loop;

                -- update rob entry
                for i in rob_wb'range loop
                    if rob_wb(i).valid then
                        v.rob.entries(to_integer(unsigned(rob_wb(i).rtag))).completed := true;
                        v.rob.entries(to_integer(unsigned(rob_wb(i).rtag))).value := rob_wb(i).value;
                    end if;
                end loop;

                ---- fetch
                -- NOTE: 2 issue specific
                -- いくつバッファに入れられるか指定
                if not fetch_pc_updated then
                    -- 分岐ミスでfetch_pc が更新されていないときにここで更新する
                    v.pbtl := to_integer(to_unsigned(r.pbtl + r.fetch_count(0), PMEM_BUFF_LENGTH));
                    sum := to_integer(to_unsigned(r.pbtl + r.fetch_count(0) + r.fetch_count(1) + r.fetch_count(2) + r.fetch_count(3), PMEM_BUFF_LENGTH));
                    if sum < v.pbhd then
                        if v.pbhd - sum > 3 then
                            v.fetch_count(2) := 2;
                        elsif v.pbhd - sum > 2 then
                            v.fetch_count(2) := 1;
                        else
                            v.fetch_count(2) := 0;
                        end if;
                    elsif sum > v.pbhd then
                        if 8 + v.pbhd - sum > 3 then -- 8 = 2 ** PMEM_BUFF_LENGTH
                            v.fetch_count(2) := 2;
                        elsif 8 + v.pbhd - sum > 2 then
                            v.fetch_count(2) := 1;
                        else
                            v.fetch_count(2) := 0;
                        end if;
                    else -- その他は初期状態しかない（ように上で調整している）
                        v.fetch_count(2) := 2;
                    end if;
                    v.fetch_pc := std_logic_vector(to_unsigned(to_integer(unsigned(r.fetch_pc)) + r.fetch_count(2), PMEM_ADDR_WIDTH + 1)); -- 次に与えるアドレスの一つ目
                else
                    v.fetch_count := (2 => 2, others => 0);
                end if;

                -- 常に二つずつ持ってくる
                if v.fetch_pc(0) = '0' then
                    v.pmem_addr(0) := v.fetch_pc(PMEM_ADDR_WIDTH downto 1);
                    v.pmem_addr(1) := v.fetch_pc(PMEM_ADDR_WIDTH downto 1);
                    v.fetch_decode.first(2) := 0;
                else
                    v.pmem_addr(1) := v.fetch_pc(PMEM_ADDR_WIDTH downto 1);
                    v.pmem_addr(0) := std_logic_vector(unsigned(v.fetch_pc(PMEM_ADDR_WIDTH downto 1)) + 1);
                    v.fetch_decode.first(2) := 1;
                end if;

        end case;

        alu_in.inputs <= r.alu_in.inputs;
        sdu_in.inputs <= r.sdu_in.inputs;
        bru_in.input <= r.bru_in.input;
        mcu_in.inputs <= r.mcu_in.inputs;
        mcu_in.exec_store <= r.mcu_in.exec_store;
        accepts <= r.accepts;
        cpu_out.send <= r.cpu_out.send;
        cpu_out.receiver_pop <= r.cpu_out.receiver_pop;
        cdb <= r.cdb;

        -- データ領域読み込みようにCPUから直にメモリへかけるようにする
        if r.cpu_state /= running then
            cpu_out.XWA <= v.XWA;
            cpu_out.ZD <= v.ZD;
            cpu_out.zd_enable <= v.zd_enable;
            cpu_out.ZA <= v.ZA;
        else
            cpu_out.XWA <= mcu_out.XWA;
            cpu_out.ZD <= mcu_out.ZD;
            cpu_out.zd_enable <= mcu_out.zd_enable;
            cpu_out.ZA <= mcu_out.ZA;
        end if;

        reset_rs <= v.reset_rs; -- reset はすぐに

        rin <= v;
    end process;

    reg : process (clk)
        variable tmp : std_logic_vector(0 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            pmem_din <= rin.pmem_din;
            pmem_we <= rin.pmem_we;
            pmem_addr <= rin.pmem_addr;
            -- fetch してきたものをバッファへ入れる
            if rin.stall_fetch_schedule(0) = '0' then
                for i in 0 to 1 loop
                    if i < rin.fetch_count(0) then
                        tmp := std_logic_vector(to_unsigned(i + rin.fetch_decode.first(0), 1));
                        pmem_buff(to_integer(to_unsigned(rin.pbtl + i, PMEM_BUFF_LENGTH))) <= pmem_dout(to_integer(unsigned(tmp)));
                    end if;
                end loop;
            end if;
            r <= rin;
        end if;
    end process;
end struct;
