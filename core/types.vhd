library IEEE;
use IEEE.STD_LOGIC_1164.all;

package types is
    constant SENDER_DATA_WIDTH : integer := 7;
    constant RECEIVER_DATA_WIDTH : integer := 7;
    constant SINGLE_PMEM_ADDR_WIDTH : integer := 13;
    constant PMEM_ADDR_WIDTH : integer := 14;
    constant SRAM_ADDR_WIDTH : integer := 19;
    constant ROB_ADDR_WIDTH : integer := 4;
    constant ALU_RS_WIDTH : integer := 1;
    constant MCU_RS_WIDTH : integer := 1;
	constant CONCURRENCY : integer := 2;
    constant TAG_LENGTH : integer := 4;
    constant TAG_WIDTH : integer := TAG_LENGTH - 1;
    constant IMM_LENGTH : integer := 16;
    constant IMM_WIDTH : integer := 15;
    constant MCU_STORE_BUFF_WIDTH : integer := 1;
    constant CACHE_WIDTH : integer := 2;



    type rs_state_type is (rs_alu, rs_send, rs_recv, rs_branch, rs_jump, rs_jal, rs_memory, rs_halt, rs_others);

    type reg_file_entry_type is record
        busy : boolean;
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        value : std_logic_vector(31 downto 0);
    end record;
    constant reg_file_entry_init : reg_file_entry_type := (
        busy => false,
        rtag => (others => '0'),
        value => (others => '0'));
    type reg_file_type is array(31 downto 0) of reg_file_entry_type;


    type receiver_in_type is record
        rs_rx : std_logic;
        pop : boolean;
    end record;
    constant receiver_in_init : receiver_in_type := (
        rs_rx => '0',
        pop => false);
    type receiver_out_type is record
        data : std_logic_vector(RECEIVER_DATA_WIDTH downto 0);
        valid : boolean;
    end record;
    constant receiver_out_init : receiver_out_type := (
        data => (others => '0'),
        valid => false);
    component receiver is
        generic (wtime : std_logic_vector(15 downto 0) := x"1ADB");
        port (
            clk : in std_logic;
            receiver_in : in receiver_in_type;
            receiver_out : out receiver_out_type);
    end component;


    type sender_in_type is record
        data : std_logic_vector(SENDER_DATA_WIDTH downto 0);
        go : boolean;
    end record;
    constant sender_in_init : sender_in_type := (
        data => (others => '0'),
        go => false);
    type sender_out_type is record
        rs_tx : std_logic;
        busy : boolean;
    end record;
    constant sender_out_init : sender_out_type := (
        rs_tx => '0',
        busy => false);
    component sender is
        generic (wtime : std_logic_vector(15 downto 0) := x"1ADB");
        port (
            clk : in std_logic;
            sender_in : in sender_in_type;
            sender_out : out sender_out_type);
    end component;


--    type memory_ctl_in_type is record
--        inputs : alu_in_body_type;
--        data : std_logic_vector(31 downto 0);
--        addr : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
--        we : boolean;
--    end record;
--    constant memory_ctl_in_init : memory_ctl_in_type := (
--        data => (others => '0'),
--        addr => (others => '0'),
--        we => false);
--    type memory_ctl_out_type is record
--        data_for_cpu  : std_logic_vector(31 downto 0);
--        data_for_sram : std_logic_vector(31 downto 0);
--        addr_for_cpu  : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
--        addr_for_sram : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
--        xwa : std_logic;
--    end record;
--    constant memory_ctl_out_init : memory_ctl_out_type := (
--        data_for_cpu => (others => '0'),
--        data_for_sram => (others => '0'),
--        addr_for_cpu => (others => '0'),
--        addr_for_sram => (others => '0'),
--        xwa => '0');
--    component memory_ctl is
--        port (
--            clk : in std_logic;
--            memory_ctl_in : in memory_ctl_in_type;
--            memory_ctl_out : out memory_ctl_out_type);
--    end component;


    type cpu_state_type is (ready, running, ploading, dloading);
    type cpu_in_type is record
        recv : receiver_out_type;
        sender_busy : boolean;
        ZD : std_logic_vector(31 downto 0);
    end record;
    constant cpu_in_init : cpu_in_type := (
        recv => receiver_out_init,
        sender_busy => false,
        ZD => (others => '0'));
    type cpu_out_type is record
        receiver_pop : boolean;
        send : sender_in_type;
        ZD : std_logic_vector(31 downto 0);
        zd_enable : boolean;
        ZA : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
        XWA : std_logic;
    end record;
    constant cpu_out_init : cpu_out_type := (
        receiver_pop => false,
        send => sender_in_init,
        ZD => (others => '0'),
        zd_enable => false,
        ZA => (others => '0'),
        XWA => '1');
    component cpu is
        port (
            clk : in std_logic;
            cpu_in : in cpu_in_type;
            cpu_out : out cpu_out_type);
    end component;

    type cdb_entry_type is record
        valid : boolean;
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        value : std_logic_vector(31 downto 0);
    end record;
    constant cdb_entry_init : cdb_entry_type := (
        valid => false,
        rtag => (others => '0'),
        value => (others => '0'));
    type cdb_type is array(1 downto 0) of cdb_entry_type;
    constant cdb_init : cdb_type := (others => cdb_entry_init);

    type alu_out_to_rob_type is record
        valid : boolean;
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        value : std_logic_vector(31 downto 0);
    end record;
    constant alu_out_to_rob_init : alu_out_to_rob_type := (
        valid => false,
        rtag => (others => '0'),
        value => (others => '0'));

    constant CMD_WIDTH : integer := 3;
    type alu_in_body_entry_type is record
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
    end record;
    constant alu_in_body_entry_init : alu_in_body_entry_type := (
        command => (others => '0'),
        rtag => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init);
    type alu_in_body_type is array(1 downto 0) of alu_in_body_entry_type;
    type alu_in_accept_type is record
        valid : boolean;
        rtag : std_logic_vector(TAG_WIDTH downto 0);
    end record;
    subtype accept_type is alu_in_accept_type;
    constant alu_in_accept_init : alu_in_accept_type := (
        valid => false,
        rtag => (others => '0'));
    alias accept_init is alu_in_accept_init;
    type alu_in_accepts_type is array(1 downto 0) of alu_in_accept_type;
    subtype accepts_type is alu_in_accepts_type;
    type alu_in_type is record
        reset_rs : boolean;
        cdb : cdb_type;
        accepts : alu_in_accepts_type;
        inputs : alu_in_body_type;
    end record;
    constant alu_in_init : alu_in_type := (
        reset_rs => false,
        cdb => cdb_init,
        accepts => (others => alu_in_accept_init),
        inputs => (others => alu_in_body_entry_init));
    type alu_out_body_entry_type is record
        valid : boolean;
        to_rob : alu_out_to_rob_type;
    end record;
    constant alu_out_body_entry_init : alu_out_body_entry_type := (
        valid => false,
        to_rob => alu_out_to_rob_init);
    type alu_out_body_type is array(1 downto 0) of alu_out_body_entry_type;
    type alu_out_type is record
        free_count : std_logic_vector(ALU_RS_WIDTH downto 0);
        outputs : alu_out_body_type;
    end record;
    constant alu_out_init : alu_out_type := (
        free_count => (others => '0'),
        outputs => (others => alu_out_body_entry_init));
    component alu is
        port (
            clk : in std_logic;
            alu_in : in alu_in_type;
            alu_out : out alu_out_type);
    end component;




    -- branch unit
    type bru_in_body_entry_type is record
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
        taken : boolean;
        offset : std_logic_vector(IMM_LENGTH - 1 downto 0);
    end record;
    constant bru_in_body_entry_init : bru_in_body_entry_type := (
        command => (others => '0'),
        rtag => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init,
        taken => false,
        offset => (others => '0'));

    type bru_in_type is record
        reset_rs : boolean;
        cdb : cdb_type;
        accepts : accepts_type;
        input : bru_in_body_entry_type;
    end record;
    constant bru_in_init : bru_in_type := (
        reset_rs => false,
        cdb => cdb_init,
        accepts => (others => accept_init),
        input => bru_in_body_entry_init);

    type bru_out_type is record
        free_count : std_logic_vector(0 downto 0);
        output : alu_out_body_entry_type;
    end record;
    constant bru_out_init : bru_out_type := (
        free_count => "0",
        output => alu_out_body_entry_init);

    component bru is
        port (
            clk : in std_logic;
            bru_in : in bru_in_type;
            bru_out : out bru_out_type);
    end component;



    type sdu_in_body_entry_type is record
        valid : boolean;
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        reg : reg_file_entry_type;
    end record;
    constant sdu_in_body_entry_init : sdu_in_body_entry_type := (
        valid => false,
        rtag => (others => '0'),
        reg => reg_file_entry_init);
    type sdu_in_body_type is array(1 downto 0) of sdu_in_body_entry_type;
    type sdu_in_type is record
        reset_rs : boolean;
        inputs : sdu_in_body_type;
        cdb : cdb_type;
        accepts : accepts_type;
    end record;
    subtype sdu_out_to_rob_type is alu_out_to_rob_type;
    alias sdu_out_to_rob_init is alu_out_to_rob_init;
    constant sdu_in_init : sdu_in_type := (
        reset_rs => false,
        inputs => (others => sdu_in_body_entry_init),
        cdb => cdb_init,
        accepts => (others => accept_init));
    type sdu_out_type is record
        free_count : std_logic_vector(ALU_RS_WIDTH downto 0);
        to_rob : sdu_out_to_rob_type;
    end record;
    constant sdu_out_init : sdu_out_type := (
        free_count => (others => '0'),
        to_rob => sdu_out_to_rob_init);
    component sdu is
        port (
            clk : in std_logic;
            sdu_in : in sdu_in_type;
            sdu_out : out sdu_out_type);
    end component;


    type fpu_in_type is record
        command : std_logic_vector(3 downto 0);
        lhs : std_logic_vector(31 downto 0);
        rhs : std_logic_vector(31 downto 0);
    end record;
    constant fpu_in_init : fpu_in_type := (
        command => (others => '0'),
        lhs => (others => '0'),
        rhs => (others => '0'));
    type fpu_out_type is record
        data : std_logic_vector(31 downto 0);
    end record;
    constant fpu_out_init : fpu_out_type := (
        data => (others => '0'));
    component fpu is
        port (
            clk : in std_logic;
            fpu_in : in fpu_in_type;
            fpu_out : out fpu_out_type);
    end component;

    type exec_store_entry_type is record
        valid : boolean;
        buff_index : std_logic_vector(MCU_STORE_BUFF_WIDTH downto 0);
    end record;
    constant exec_store_entry_init : exec_store_entry_type := (
        valid => false,
        buff_index => (others => '0'));

    type exec_store_type is array(1 downto 0) of exec_store_entry_type; -- NOTE: 1clk でcomplete する命令数に応じて変える


    type mcu_in_body_entry_type is record
        command : std_logic_vector(CMD_WIDTH downto 0);
        rtag : std_logic_vector(TAG_WIDTH downto 0);
        imm : std_logic_vector(IMM_WIDTH downto 0);
        lhs : reg_file_entry_type;
        rhs : reg_file_entry_type;
    end record;
    constant mcu_in_body_entry_init : mcu_in_body_entry_type := (
        command => (others => '0'),
        rtag => (others => '0'),
        imm => (others => '0'),
        lhs => reg_file_entry_init,
        rhs => reg_file_entry_init);
    type mcu_in_body_type is array(1 downto 0) of mcu_in_body_entry_type;

    type mcu_in_type is record
        ZD : std_logic_vector(31 downto 0);
        reset_rs : boolean;
        cdb : cdb_type;
        accepts : accepts_type;
        inputs : mcu_in_body_type;
        exec_store : exec_store_type;
    end record;
    constant mcu_in_init : mcu_in_type := (
        ZD => (others => '0'),
        reset_rs => false,
        cdb => cdb_init,
        accepts => (others => accept_init),
        inputs => (others => mcu_in_body_entry_init),
        exec_store => (others => exec_store_entry_init));

    type mcu_out_type is record
        free_count : std_logic_vector(MCU_RS_WIDTH downto 0);
        outputs : alu_out_body_type;
        ZA : std_logic_vector(SRAM_ADDR_WIDTH downto 0);
        ZD : std_logic_vector(31 downto 0);
        zd_enable : boolean;
        XWA : std_logic;
    end record;
    constant mcu_out_init : mcu_out_type := (
        free_count => (others => '0'),
        outputs => (others => alu_out_body_entry_init),
        ZA => (others => '0'),
        ZD => (others => '0'),
        zd_enable => false,
        XWA => '1');

    component mcu is
        port (
            clk : in std_logic;
            mcu_in : in mcu_in_type;
            mcu_out : out mcu_out_type);
    end component;


    type op_type is record
        opcode : std_logic_vector(5 downto 0);
        rs_tag : rs_state_type;
        reg1 : std_logic_vector(4 downto 0);
        reg2 : std_logic_vector(4 downto 0);
        reg3 : std_logic_vector(4 downto 0);
        imm : std_logic_vector(15 downto 0);
        addr : std_logic_vector(25 downto 0);
        command : std_logic_vector(3 downto 0);
        use_imm : boolean;
    end record;
    constant op_init : op_type := (
        opcode => (others => '0'),
        rs_tag => rs_others,
        reg1 => (others => '0'),
        reg2 => (others => '0'),
        reg3 => (others => '0'),
        imm => (others => '0'),
        addr => (others => '0'),
        command => (others => '0'),
        use_imm => false);


    constant CMD_PLOAD : std_logic_vector(7 downto 0) := x"01";
    constant CMD_DLOAD : std_logic_vector(7 downto 0) := x"02";
    constant CMD_EXEC  : std_logic_vector(7 downto 0) := x"03";


    constant OP_NOP   : std_logic_vector(5 downto 0) := "000000";
    constant OP_ADD   : std_logic_vector(5 downto 0) := "000001";
    constant OP_ADDI  : std_logic_vector(5 downto 0) := "000010";
    constant OP_SEND  : std_logic_vector(5 downto 0) := "011101";
    constant OP_RECV  : std_logic_vector(5 downto 0) := "011110";
    constant OP_HALT  : std_logic_vector(5 downto 0) := "011111";
    constant OP_BEQ   : std_logic_vector(5 downto 0) := "001000";
    constant OP_BNEQ  : std_logic_vector(5 downto 0) := "001001";
    constant OP_BLT   : std_logic_vector(5 downto 0) := "001010";
    constant OP_BLE   : std_logic_vector(5 downto 0) := "001011";
    constant OP_JR    : std_logic_vector(5 downto 0) := "001100";
    constant OP_JAL   : std_logic_vector(5 downto 0) := "001101";
    constant OP_LW    : std_logic_vector(5 downto 0) := "010000";
    constant OP_SW    : std_logic_vector(5 downto 0) := "010001";

    constant OP_FBEQ  : std_logic_vector(5 downto 0) := "101000";
    constant OP_FBNEQ : std_logic_vector(5 downto 0) := "101001";
    constant OP_FBLT  : std_logic_vector(5 downto 0) := "101010";
    constant OP_FBLE  : std_logic_vector(5 downto 0) := "101011";


    constant ALU_NOP  : std_logic_vector(3 downto 0) := "0000";
    constant ALU_ADD  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_SUB  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SLL  : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SRL  : std_logic_vector(3 downto 0) := "0100";
    constant ALU_ADDU : std_logic_vector(3 downto 0) := "0101";


    constant FPU_NOP  : std_logic_vector(3 downto 0) := "0000";
    constant FPU_ADD  : std_logic_vector(3 downto 0) := "0001";
    constant FPU_MUL  : std_logic_vector(3 downto 0) := "0010";
    constant FPU_INV  : std_logic_vector(3 downto 0) := "0011";
    constant FPU_NEG  : std_logic_vector(3 downto 0) := "0100";
    constant FPU_ABS  : std_logic_vector(3 downto 0) := "0101";
    constant FPU_SQRT : std_logic_vector(3 downto 0) := "0110";



    constant BRU_NOP  : std_logic_vector(3 downto 0) := "0000";
    constant BRU_EQ   : std_logic_vector(3 downto 0) := "0001";
    constant BRU_NEQ  : std_logic_vector(3 downto 0) := "0010";
    constant BRU_LT   : std_logic_vector(3 downto 0) := "0011";
    constant BRU_LE   : std_logic_vector(3 downto 0) := "0100";
    constant BRU_FEQ  : std_logic_vector(3 downto 0) := "1001";
    constant BRU_FNEQ : std_logic_vector(3 downto 0) := "1010";
    constant BRU_FLT  : std_logic_vector(3 downto 0) := "1011";
    constant BRU_FLE  : std_logic_vector(3 downto 0) := "1100";


    constant MCU_NOP : std_logic_vector(3 downto 0) := "0000";
    constant MCU_LW  : std_logic_vector(3 downto 0) := "0001";
    constant MCU_SW  : std_logic_vector(3 downto 0) := "0010";


end package;
