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
    type store_buff_type is array(2 ** MCU_STORE_BUFF_ADDR_LENGTH - 1 downto 0) of store_buff_entry_type;

    subtype cache_entry_type is std_logic_vector(CACHE_TAG_LENGTH + 32 - 1 + 1 downto 0);
    type cache_type is array(2 ** (SRAM_ADDR_LENGTH - CACHE_TAG_LENGTH) - 1 downto 0) of cache_entry_type;

    type rs_entry_type is record
        busy : boolean;
        completed : boolean;
        sram_issued : boolean;
        counter : std_logic_vector(2 downto 0);
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        imm : std_logic_vector(IMM_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
        data : std_logic_vector(31 downto 0);
    end record;
    constant rs_entry_init : rs_entry_type := (
        busy => false,
        completed => false,
        sram_issued => false,
        counter => (others => '0'),
        command => (others => '0'),
        rtag => (others => '0'),
        imm => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init,
        data => (others => '0'));
    type rs_type is array(2 ** MCU_RS_ADDR_LENGTH - 1 downto 0) of rs_entry_type;
    type reg_type is record
        rs : rs_type;
        mcu_out : mcu_out_type;
        rshd : std_logic_vector(MCU_RS_ADDR_LENGTH - 1 downto 0);
        sbhd : std_logic_vector(MCU_STORE_BUFF_ADDR_LENGTH - 1 downto 0);
        sbtl : std_logic_vector(MCU_STORE_BUFF_ADDR_LENGTH - 1 downto 0);
        store_buff : store_buff_type;
        cache_wa : boolean;
        cache_index : std_logic_vector(SRAM_ADDR_LENGTH - CACHE_TAG_LENGTH - 1 downto 0);
        cache_entry : cache_entry_type;
    end record;
    constant reg_init : reg_type := (
        rs => (others => rs_entry_init),
        mcu_out => mcu_out_init,
        rshd => (others => '0'),
        sbhd => (others => '0'),
        sbtl => (others => '0'),
        store_buff => (others => store_buff_entry_init),
        cache_wa => false,
        cache_index => (others => '0'),
        cache_entry => (others => '0'));

    signal cache : cache_type := (others => (others => '0'));
    signal cache_entry : cache_entry_type := (others => '0');
    signal r, rin : reg_type := reg_init;
begin
    comb : process(r, mcu_in, cache_entry)
        variable v : reg_type := reg_init;
        variable num_free_entries : std_logic_vector(MCU_RS_ADDR_LENGTH downto 0);
        variable tmp : std_logic_vector(31 downto 0);
        variable rs_written : boolean := false;
        variable sram_addr : std_logic_vector(31 downto 0);
        variable index : integer := 0;
        variable index2 : integer := 0;
        variable input_done : booleans2 := (others => false);
        variable output_count : integer := 0;
        variable head_executed : boolean := true;
        variable head_outputted : boolean := true;
        variable sram_busy : boolean := false;
        variable cache_busy : boolean := false;
        variable insb : boolean := false;
        variable insb_data : std_logic_vector(31 downto 0);
    begin
        v := r;

--        v.mcu_out.ZA := (others => '0');
--        v.mcu_out.ZD := (others => '0');
        v.mcu_out.XWA := '1';
        v.mcu_out.zd_enable := false;
        v.mcu_out.outputs := (others => alu_out_body_entry_init);
        v.mcu_out.free_count := (others => '0');
        v.cache_wa := false;
        input_done := (others => false);
        output_count := 0;
        head_executed := true;
        head_outputted := true;
        sram_busy := false;
        cache_busy := false;

        index := 0;
        index2 := 0;
        insb := false;
        insb_data := (others => '0');

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
                v.rs(i).completed := false;
            end loop;
            v.sbhd := (others => '0');
            v.sbtl := (others => '0');
            for i in r.store_buff'reverse_range loop
                -- 実行して良いがまだ実行されていないものは実行し、実行中のものも放置する
                if v.store_buff(i).valid and v.store_buff(i).completed then
                    if unsigned(v.sbhd) = 0 then
                        v.sbhd := std_logic_vector(to_unsigned(i, MCU_STORE_BUFF_ADDR_LENGTH));
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
            v.mcu_out.free_count := (others => '0');
        else
            for i in r.rs'reverse_range loop
                index := to_integer(to_unsigned(to_integer(unsigned(r.rshd)) + i, MCU_RS_ADDR_LENGTH));

                -- NOTE: ビット数直接指定している
                sram_addr(31 downto 16) := (others => r.rs(index).imm(15));
                sram_addr(15 downto 0) := r.rs(index).imm;
                sram_addr := std_logic_vector(signed(r.rs(index).lhs.value) + signed(sram_addr));


                -- accepted by arbiter
                for j in mcu_in.accepts'reverse_range loop
                    if mcu_in.accepts(j).valid and v.rs(index).busy and v.rs(index).rtag = mcu_in.accepts(j).rtag then
                        v.rs(index).busy := false;
                        v.rs(index).completed := false;
                        v.rshd := std_logic_vector(unsigned(v.rshd) + 1);
                    end if;
                end loop;


                -- count down
                if r.rs(index).counter /= "000" then
                    v.rs(index).counter := std_logic_vector(unsigned(r.rs(index).counter) - 1);
                end if;


                -- SRAM からのデータを見張る
                if v.rs(index).busy and r.rs(index).command = MCU_LW and r.rs(index).sram_issued and not v.rs(index).completed and r.rs(index).counter = "000" then
                    v.rs(index).data := mcu_in.ZD;
                    v.rs(index).completed := true;
                end if;


                -- execute (store バッファに入れるか、ロード待ちにするか)
                case r.rs(index).command is
                    when MCU_SW =>
                        -- 使うものがそろっていて、かつストアバッファがあいていれば
                        if head_executed and v.rs(index).busy and not v.rs(index).completed and not r.rs(index).lhs.busy and not r.rs(index).rhs.busy and
                           std_logic_vector(unsigned(v.sbtl) + 1) /= v.sbhd then

                            v.rs(index).completed := true;

                            -- store buffer に入れる (complete 時に実際のメモリへの書き込みを行う)
                            v.store_buff(to_integer(unsigned(v.sbtl))).valid := true;
                            v.store_buff(to_integer(unsigned(v.sbtl))).executed := false;
                            v.store_buff(to_integer(unsigned(v.sbtl))).completed := false;
                            v.store_buff(to_integer(unsigned(v.sbtl))).addr := sram_addr(SRAM_ADDR_WIDTH downto 0);
                            v.store_buff(to_integer(unsigned(v.sbtl))).data := r.rs(index).rhs.value;

                            v.rs(index).data(31 downto MCU_STORE_BUFF_ADDR_LENGTH) := (others => '0');
                            v.rs(index).data(MCU_STORE_BUFF_ADDR_LENGTH - 1 downto 0) := v.sbtl; -- store 時にはstore buffer の id が来る

                            v.sbtl := std_logic_vector(unsigned(v.sbtl) + 1);
                        else
                            head_executed := false; -- インオーダー実行
                        end if;
                    when MCU_LW =>
                        -- load には rhs は必要ない
                        -- ここで head_executed を見ているのは、ストアバッファにはいっていないストアがある状態でロードしたくないから
                        if head_executed and v.rs(index).busy and not v.rs(index).completed and not r.rs(index).lhs.busy then
                            -- store buffer にあればそれをつかう
                            EXEC_LOOK_UP_SB: for j in r.store_buff'reverse_range loop
                                index2 := to_integer(to_unsigned(to_integer(unsigned(r.sbhd)) + j, MCU_STORE_BUFF_ADDR_LENGTH));
                                if v.store_buff(index2).valid and v.store_buff(index2).addr = sram_addr(SRAM_ADDR_WIDTH downto 0) then
                                    insb := true;
                                    insb_data := v.store_buff(index2).data;
                                end if;
                            end loop;

                            if insb then
                                v.rs(index).completed := true;
                                v.rs(index).data := insb_data;
                            elsif cache_entry(CACHE_TAG_LENGTH + 32 - 1 + 1) = '1' and
                                  r.cache_index = sram_addr(SRAM_ADDR_LENGTH - CACHE_TAG_LENGTH - 1 downto 0) and
                                  cache_entry(CACHE_TAG_LENGTH + 32 - 1 downto 32) = sram_addr(SRAM_ADDR_LENGTH - 1 downto CACHE_TAG_LENGTH) then

                                v.rs(index).completed := true;
                                v.rs(index).data := cache_entry(31 downto 0);
                            else
                                if not sram_busy and not r.rs(index).sram_issued then
                                    v.rs(index).counter := "001";
                                    v.rs(index).sram_issued := true;

                                    v.mcu_out.ZA := sram_addr(SRAM_ADDR_WIDTH downto 0);
                                    sram_busy := true;
                                end if;
                                if not cache_busy then
                                    v.cache_index := sram_addr(SRAM_ADDR_LENGTH - CACHE_TAG_LENGTH - 1 downto 0);
                                    cache_busy := true;
                                end if;
                            end if;
                            -- v.mcu_out.xwa = '0' の時は何もしない
                        else
                            head_executed := false;
                        end if;
                    when others =>
                end case;

                -- output
                if head_outputted and output_count < 2 and v.rs(index).busy and v.rs(index).completed then
                    v.mcu_out.outputs(output_count).valid := true;
                    if r.rs(index).command = MCU_LW then
                        v.mcu_out.outputs(output_count).to_rob.valid := true;
                    else
                        v.mcu_out.outputs(output_count).to_rob.valid := false;
                    end if;
                    v.mcu_out.outputs(output_count).to_rob.rtag := r.rs(index).rtag;
                    v.mcu_out.outputs(output_count).to_rob.value := v.rs(index).data;

                    output_count := output_count + 1;
                else
                    head_outputted := false;
                end if;


                -- insert into RS
                INSERT_L1: for j in mcu_in.inputs'reverse_range loop
                    if not input_done(j) and mcu_in.inputs(j).command /= MCU_NOP and not r.rs(index).busy then
                        v.rs(index).busy := true;
                        v.rs(index).sram_issued := false;
                        v.rs(index).command := mcu_in.inputs(j).command;
                        v.rs(index).rtag := mcu_in.inputs(j).rtag;
                        v.rs(index).imm := mcu_in.inputs(j).imm;
                        v.rs(index).lhs := mcu_in.inputs(j).lhs;
                        v.rs(index).rhs := mcu_in.inputs(j).rhs;

                        input_done(j) := true;
                        exit INSERT_L1;
                    end if;
                end loop;


                -- watch the CDB
                for j in mcu_in.cdb'reverse_range loop
                    if mcu_in.cdb(j).valid then
                        if v.rs(index).lhs.busy and v.rs(index).lhs.rtag = mcu_in.cdb(j).rtag then
                            v.rs(index).lhs.busy := false;
                            v.rs(index).lhs.value := mcu_in.cdb(j).value;
                        end if;
                        if v.rs(index).rhs.busy and v.rs(index).rhs.rtag = mcu_in.cdb(j).rtag then
                            v.rs(index).rhs.busy := false;
                            v.rs(index).rhs.value := mcu_in.cdb(j).value;
                        end if;
                    end if;
                end loop;


                -- update free_count
                if not v.rs(index).busy then
                    v.mcu_out.free_count := std_logic_vector(unsigned(v.mcu_out.free_count) + 1);
                end if;
            end loop;
        end if;

    -- store buffer 先頭が実行可能だったら実行
    -- reset_rs によらずバッファ処理する (NOTE: v.sbhd)
    -- NOTE: load 優先
        if r.store_buff(to_integer(unsigned(v.sbhd))).valid and r.store_buff(to_integer(unsigned(v.sbhd))).counter /= "00" then
            v.store_buff(to_integer(unsigned(v.sbhd))).counter := std_logic_vector(unsigned(r.store_buff(to_integer(unsigned(v.sbhd))).counter) - 1);
        end if;

        if v.store_buff(to_integer(unsigned(v.sbhd))).valid and v.store_buff(to_integer(unsigned(v.sbhd))).completed then
            if v.store_buff(to_integer(unsigned(v.sbhd))).executed and r.store_buff(to_integer(unsigned(v.sbhd))).counter = "00" then
                v.mcu_out.ZD := r.store_buff(to_integer(unsigned(v.sbhd))).data;
                v.mcu_out.zd_enable := true;
                v.store_buff(to_integer(unsigned(v.sbhd))).valid := false;
                v.store_buff(to_integer(unsigned(v.sbhd))).completed := false;
                v.store_buff(to_integer(unsigned(v.sbhd))).executed := false;
                v.sbhd := std_logic_vector(unsigned(v.sbhd) + 1);
            elsif not v.store_buff(to_integer(unsigned(v.sbhd))).executed then
                v.mcu_out.ZA := r.store_buff(to_integer(unsigned(v.sbhd))).addr;
                v.mcu_out.XWA := '0';
                sram_busy := true;
                v.store_buff(to_integer(unsigned(v.sbhd))).counter := "01"; -- 実験したらこれで動いただけで、ちゃんと考えていない
                v.store_buff(to_integer(unsigned(v.sbhd))).executed := true;

                -- cache に入れる
                -- NOTE: load でのキャッシュアクセスより強い
                v.cache_entry(CACHE_TAG_LENGTH + 32 - 1 + 1) := '1';
                v.cache_entry(CACHE_TAG_LENGTH + 32 - 1 downto 32) := r.store_buff(to_integer(unsigned(v.sbhd))).addr(SRAM_ADDR_LENGTH - 1 downto CACHE_TAG_LENGTH);
                v.cache_entry(31 downto 0) := r.store_buff(to_integer(unsigned(v.sbhd))).data;
                v.cache_index := r.store_buff(to_integer(unsigned(v.sbhd))).addr(SRAM_ADDR_LENGTH - CACHE_TAG_LENGTH - 1 downto 0);
                v.cache_wa := true;
            end if;
        end if;


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
            if rin.cache_wa then
                cache(to_integer(unsigned(rin.cache_index))) <= rin.cache_entry;
            else
                cache_entry <= cache(to_integer(unsigned(rin.cache_index)));
            end if;
            r <= rin;
        end if;
    end process;
end struct;
