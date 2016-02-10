library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.types.all;

entity mcu is
    port (
        clk : in std_logic;
        mcu_in : in mcu_in_type;
        mcu_out : out mcu_out_type);
end mcu;

architecture struct of mcu is
    type store_buff_entry_type is record
        valid : boolean;
        completed : boolean;
        executed : boolean;
        counter : std_logic_vector(1 downto 0);
        addr : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
        data : std_logic_vector(31 downto 0);
    end record;
    constant store_buff_entry_init : store_buff_entry_type := (
        valid => false,
        completed => false,
        executed => false,
        counter => (others => '0'),
        addr => (others => '0'),
        data => (others => '0'));
    type store_buff_type is array(2 ** (MCU_STORE_BUFF_WIDTH + 1) - 1 downto 0) of store_buff_entry_type;

--    type cache_entry_type is record
--        valid : boolean;
--        tag : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
--        data : std_logic_vector(31 downto 0);
--    end record;
--    constant cache_entry_init : cache_entry_type := (
--        valid => false,
--        tag => (others => '0'),
--        data => (others => '0'));
--    type cache_type is array(2 ** (CACHE_WIDTH + 1) - 1 downto 0) of cache_entry_type;

    subtype cache_entry_type is std_logic_vector(52 downto 0);
    type cache_type is array(2 ** (CACHE_WIDTH + 1) - 1 downto 0) of cache_entry_type;

    type rs_entry_type is record
        busy : boolean;
        executing : boolean;
        outputting : boolean;
        counter : std_logic_vector(2 downto 0); -- NOTE: counter = 0 でも executing = true な場合もある（cdbが詰まっている）
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        imm : std_logic_vector(IMM_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
        data : std_logic_vector(31 downto 0);
    end record;
    constant rs_entry_init : rs_entry_type := (
        busy => false,
        executing => false,
        outputting => false,
        counter => (others => '0'),
        command => (others => '0'),
        rtag => (others => '0'),
        imm => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init,
        data => (others => '0'));
    type rs_type is array(2 ** MCU_RS_WIDTH - 1 downto 0) of rs_entry_type;
    type reg_type is record
        rs : rs_type;
        mcu_out : mcu_out_type;
        sbhd : std_logic_vector(MCU_STORE_BUFF_WIDTH downto 0);
        sbtl : std_logic_vector(MCU_STORE_BUFF_WIDTH downto 0);
        store_buff : store_buff_type;
        cache_entry : cache_entry_type;
    end record;
    constant reg_init : reg_type := (
        rs => (others => rs_entry_init),
        mcu_out => mcu_out_init,
        sbhd => (others => '0'),
        sbtl => (others => '0'),
        store_buff => (others => store_buff_entry_init),
        cache_entry => (others => '0'));

    signal cache : cache_type := (others => (others => '0'));
    signal r, rin : reg_type := reg_init;
begin
    comb : process(r, mcu_in, cache)
        variable v : reg_type := reg_init;
        variable num_free_entries : std_logic_vector(MCU_RS_WIDTH downto 0);
        variable tmp : std_logic_vector(31 downto 0);
        variable rs_written : boolean := false;
        variable sram_addr : std_logic_vector(31 downto 0);
        variable index : integer := 0;
        variable cache_val : cache_entry_type;
    begin
        cache_val := (others => '0');

        v := r;

--        v.mcu_out.ZA := (others => '0');
--        v.mcu_out.ZD := (others => '0');
        v.mcu_out.XWA := '1';
        v.mcu_out.zd_enable := false;

    -- complete を見張る (reset_rs と同時に complete が来たときにちゃんと実行するために先に書いてある)
        for i in mcu_in.exec_store'reverse_range loop
            if mcu_in.exec_store(i).valid then
                v.store_buff(to_integer(unsigned(mcu_in.exec_store(i).buff_index))).completed := true;
            end if;
        end loop;

    -- reset rs and output
        if mcu_in.reset_rs then
            for i in r.rs'reverse_range loop
                v.rs(i).busy := false;
                v.rs(i).executing := false;
                v.rs(i).outputting := false;
            end loop;
            v.sbhd := (others => '0');
            v.sbtl := (others => '0');
            for i in r.store_buff'reverse_range loop
                -- 実行して良いがまだ実行されていないものは実行する
                if v.store_buff(i).valid and v.store_buff(i).completed and not v.store_buff(i).executed then
                    if v.sbhd = "00" then
                        v.sbhd := std_logic_vector(to_unsigned(i, MCU_STORE_BUFF_WIDTH + 1));
                        v.sbtl := std_logic_vector(unsigned(v.sbhd) + 1);
                    else
                        v.sbtl := std_logic_vector(unsigned(v.sbtl) + 1);
                    end if;
                else
                    v.store_buff(i).valid := false;
                    v.store_buff(i).completed := false;
                    v.store_buff(i).executed := false;
                end if;
            end loop;
            for i in r.mcu_out.outputs'reverse_range loop
                v.mcu_out.outputs(i).valid := false;
            end loop;
        end if;

    -- store buffer 先頭が実行可能だったら実行
        if r.store_buff(to_integer(unsigned(r.sbhd))).valid and r.store_buff(to_integer(unsigned(r.sbhd))).counter /= "00" then
            v.store_buff(to_integer(unsigned(r.sbhd))).counter := std_logic_vector(unsigned(r.store_buff(to_integer(unsigned(r.sbhd))).counter) - 1);
        end if;

        v.cache_entry := (others => '0');
        if v.store_buff(to_integer(unsigned(r.sbhd))).valid and v.store_buff(to_integer(unsigned(r.sbhd))).completed then
            if v.store_buff(to_integer(unsigned(r.sbhd))).executed and r.store_buff(to_integer(unsigned(r.sbhd))).counter = "00" then
                v.mcu_out.ZD := r.store_buff(to_integer(unsigned(r.sbhd))).data;
                v.mcu_out.zd_enable := true;
                v.store_buff(to_integer(unsigned(r.sbhd))).valid := false;
                v.store_buff(to_integer(unsigned(r.sbhd))).completed := false;
                v.sbhd := std_logic_vector(unsigned(r.sbhd) + 1);
            elsif not v.store_buff(to_integer(unsigned(r.sbhd))).executed then
                v.mcu_out.ZA := r.store_buff(to_integer(unsigned(r.sbhd))).addr;
                v.mcu_out.XWA := '0';
                v.store_buff(to_integer(unsigned(r.sbhd))).counter := "01"; -- 実験したらこれで動いただけで、ちゃんと考えていない
                v.store_buff(to_integer(unsigned(r.sbhd))).executed := true;

                -- cache に入れる
                v.cache_entry(52) := '1';
                v.cache_entry(51 downto 32) := r.store_buff(to_integer(unsigned(r.sbhd))).addr;
                v.cache_entry(31 downto 0) := r.store_buff(to_integer(unsigned(r.sbhd))).data;
            end if;
        end if;



    -- execute
        -- SRAM からのデータを見張る
        for i in r.rs'reverse_range loop
            if r.rs(i).counter /= "000" then
                v.rs(i).counter := std_logic_vector(unsigned(r.rs(i).counter) - 1);
            end if;
            -- TODO: もっと正確に
            if v.rs(i).busy and v.rs(i).executing and v.rs(i).command = MCU_LW then
                v.rs(i).data := mcu_in.ZD;
            end if;
        end loop;

        -- execute (store バッファに入れるか、ロード待ちにするか
        SRAM_ADDR_L1: for i in r.rs'reverse_range loop
            -- NOTE: ビット数直接指定している
            sram_addr(31 downto 16) := (others => r.rs(i).imm(15));
            sram_addr(15 downto 0) := r.rs(i).imm;
            sram_addr := std_logic_vector(signed(r.rs(i).lhs.value) + signed(sram_addr));
            case r.rs(i).command is
                when MCU_SW =>
                    -- 使うものがそろっていて、かつストアバッファがあいていれば
                    if v.rs(i).busy and not v.rs(i).executing and not r.rs(i).lhs.busy and not r.rs(i).rhs.busy and
                       std_logic_vector(unsigned(r.sbtl) + 1) /= r.sbhd then

                        v.rs(i).counter := "000";
                        v.rs(i).executing := true;

                        -- store buffer に入れる (complete 時に実際のメモリへの書き込みを行う)
                        v.store_buff(to_integer(unsigned(r.sbtl))).valid := true;
                        v.store_buff(to_integer(unsigned(r.sbtl))).addr := sram_addr(SRAM_ADDR_WIDTH downto 0);
                        v.store_buff(to_integer(unsigned(r.sbtl))).data := r.rs(i).rhs.value;

                        v.rs(i).data(31 downto MCU_STORE_BUFF_WIDTH + 1) := (others => '0');
                        v.rs(i).data(MCU_STORE_BUFF_WIDTH downto 0) := r.sbtl; -- store 時にはstore buffer の id が来る

                        v.sbtl := std_logic_vector(unsigned(r.sbtl) + 1);
                        exit SRAM_ADDR_L1;
                    end if;
                when MCU_LW =>
                    -- load には rhs は必要ない
                    if v.rs(i).busy and not v.rs(i).executing and not r.rs(i).lhs.busy then
                        cache_val := cache(to_integer(unsigned(sram_addr(CACHE_WIDTH downto 0))));
                        if cache_val(52) = '1' and
                           cache_val(51 downto 32) = sram_addr(SRAM_ADDR_WIDTH downto 0) then
                            -- cache hit
                            v.rs(i).counter := "000";
                            v.rs(i).data := cache_val(31 downto 0);

                            v.rs(i).executing := true;
                            exit SRAM_ADDR_L1;
                        elsif v.mcu_out.xwa = '1' then
                            -- cache miss だが store とはかぶらない
                            v.mcu_out.ZA := sram_addr(SRAM_ADDR_WIDTH downto 0);
                            v.rs(i).counter := "100"; -- TODO: もっと正確に
                            v.rs(i).executing := true;
                            exit SRAM_ADDR_L1;
                        end if;
                        -- v.mcu_out.xwa = '0' の時は何もしない
                    end if;
                when others =>
            end case;
        end loop;


        -- cdb へ流す
        for i in r.mcu_out.outputs'reverse_range loop
            if not v.mcu_out.outputs(i).valid then
                EXEC_L2: for j in r.rs'reverse_range loop
                    if v.rs(i).busy and v.rs(i).executing and v.rs(i).counter = "000" and not v.rs(i).outputting then
                        v.rs(i).outputting := true;
                        v.mcu_out.outputs(index).valid := true;

                        if r.rs(j).command = MCU_LW then
                            v.mcu_out.outputs(i).to_rob.valid := true;
                        else
                            v.mcu_out.outputs(i).to_rob.valid := false;
                        end if;
                        v.mcu_out.outputs(i).to_rob.rtag := r.rs(j).rtag;
                        v.mcu_out.outputs(i).to_rob.value := v.rs(j).data;
                        exit EXEC_L2;
                    end if;
                end loop;
            end if;
        end loop;



    -- insert into RS
        for i in mcu_in.inputs'reverse_range loop
            INSERT_L2: for j in r.rs'reverse_range loop
                if mcu_in.inputs(i).command /= MCU_NOP and not rs_written and not v.rs(j).busy then
                    v.rs(j).busy := true;
                    v.rs(j).command := mcu_in.inputs(i).command;
                    v.rs(j).rtag := mcu_in.inputs(i).rtag;
                    v.rs(j).imm := mcu_in.inputs(i).imm;
                    v.rs(j).lhs := mcu_in.inputs(i).lhs;
                    v.rs(j).rhs := mcu_in.inputs(i).rhs;

                    exit INSERT_L2;
                end if;
            end loop;
        end loop;

    -- watch the CDB
        for i in mcu_in.cdb'reverse_range loop
            if mcu_in.cdb(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).lhs.busy and v.rs(j).lhs.rtag = mcu_in.cdb(i).rtag then
                        v.rs(j).lhs.busy := false;
                        v.rs(j).lhs.value := mcu_in.cdb(i).value;
                    end if;
                    if v.rs(j).rhs.busy and v.rs(j).rhs.rtag = mcu_in.cdb(i).rtag then
                        v.rs(j).rhs.busy := false;
                        v.rs(j).rhs.value := mcu_in.cdb(i).value;
                    end if;
                end loop;
            end if;
        end loop;

    -- busy or not
    -- このクロックで accept されて free になったものは次のクロックで free とカウントされる
        v.mcu_out.free_count := "01"; -- NOTE
        for i in v.rs'reverse_range loop
--            if not(v.rs(i).busy) then
            if v.rs(i).busy then
                -- NOTE: 自明なハザード回避のために rs に busy なものは一つだけにする
                -- 後でまじめに考える
                v.mcu_out.free_count := (others => '0');
--                v.mcu_out.free_count := std_logic_vector(unsigned(v.mcu_out.free_count) + 1);
            end if;
        end loop;

    -- accepted by arbiter
        for i in mcu_in.accepts'reverse_range loop
            if mcu_in.accepts(i).valid then
                for j in r.rs'reverse_range loop
                    if v.rs(j).rtag = mcu_in.accepts(i).rtag then
                        v.rs(j).busy := false;
                        v.rs(j).executing := false;
                        v.rs(j).outputting := false;
                    end if;
                end loop;
                for j in r.mcu_out.outputs'reverse_range loop
                    if v.mcu_out.outputs(j).to_rob.rtag = mcu_in.accepts(i).rtag then
                        v.mcu_out.outputs(j).valid := false;
                    end if;
                end loop;
            end if;
        end loop;

        mcu_out.outputs <= r.mcu_out.outputs; -- 出力は最短でも 1 クロック後
        mcu_out.free_count <= v.mcu_out.free_count; -- 空き rs 数はすぐに

        mcu_out.ZA <= v.mcu_out.ZA;
        mcu_out.ZD <= v.mcu_out.ZD;
        mcu_out.zd_enable <= v.mcu_out.zd_enable;
        mcu_out.XWA <= v.mcu_out.XWA;

        rin <= v;
    end process;

    reg : process(clk)
    begin
        if rising_edge(clk) then
            -- cache には store buffer から出すタイミングで入れるようにしたのでリセットはいらなくなった
--            if mcu_in.reset_rs then
--                for i in cache'reverse_range loop
--                    cache(i).valid <= false;
--                end loop;
--            end if;
            if rin.cache_entry(52) = '1' then
                cache(to_integer(unsigned(rin.cache_entry(32 + CACHE_WIDTH downto 32)))) <= rin.cache_entry;
            end if;
            r <= rin;
        end if;
    end process;
end struct;

