/////////////////////////////////////////////////////////////
// Maybe merge what is in mp_verif/rtl/cpu/types.sv over here? //
/////////////////////////////////////////////////////////////

package rv32i_types;

    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [3:0] {
        alu_op_add     = 4'b0000,
        alu_op_sll     = 4'b0001,
        alu_op_slt     = 4'b0010,
        alu_op_sltu    = 4'b0011,
        alu_op_xor     = 4'b0100,
        alu_op_or      = 4'b0110,
        alu_op_and     = 4'b0111,
        alu_op_srl     = 4'b1000,
        alu_op_sra     = 4'b1001,
        alu_op_sub     = 4'b1010,
        // branch aluop
        alu_op_eq      = 4'b1011,
        alu_op_ne      = 4'b1100,
        alu_op_ge      = 4'b1101,
        alu_op_geu     = 4'b1111
    } alu_ops;

    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;


        // struct packed {
        //
        // } b_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

    } instr_t;

    typedef enum logic {
        rs1_out = 1'b0,
        pc_out  = 1'b1
    } alu_m1_sel_t;

    // more mux def here
    typedef enum logic [1:0] {
        rs2_out = 2'b00,
        d4_out = 2'b01,
        imm_out = 2'b10
    } alu_m2_sel_t;

    typedef struct packed {
        logic               valid;
        logic   [31:0]      inst;
        logic   [31:0]      pc;
    } if_id_stage_reg_t;

    typedef struct packed {
        logic               valid;
        logic   [31:0]      inst;
        logic   [31:0]      pc;

        alu_m1_sel_t        alu_m1_sel;
        alu_m2_sel_t        alu_m2_sel;
        logic       [4:0]   rs1_s;
        logic       [4:0]   rs2_s;
        logic       [31:0]  rs1_v;
        logic       [31:0]  rs2_v;
        logic       [2:0]   funct3;
        logic       [6:0]   funct7;
        logic       [6:0]   opcode;
        logic       [31:0]  imm;
        logic       [4:0]   rd_s;
        logic       [31:0]  rd_v;
        logic               reg_wen;
        //memory stage control signas
        logic               dmem_req;
    } id_ex_stage_reg_t;

    typedef struct packed {
        logic               valid;
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [31:0]      pc_wdata;
        // decode stage signals
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [31:0]      rs1_v;        
        logic   [31:0]      rs2_v;   
        // writeback stage signals
        logic   [4:0]       rd_s;     
        logic   [31:0]      rd_v;
        logic               reg_wen;
        // memory stage signals
        logic               dmem_req;
        logic   [31:0]      dmem_addr;
        logic   [3:0]       dmem_rmask;
        logic   [3:0]       dmem_wmask;
        logic   [31:0]      dmem_wdata;
    } ex_mm_stage_reg_t;

    typedef struct packed {
        logic               valid;
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [31:0]      pc_wdata;
        //decode stage signals
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [31:0]      rs1_v;
        logic   [31:0]      rs2_v;  
        // writeback stage signals 
        logic   [31:0]      rd_v;
        logic   [4:0]       rd_s;  
        logic               reg_wen;
        // memory stage signals
        logic   [31:0]      dmem_addr;
        logic   [3:0]       dmem_rmask;
        logic   [31:0]      dmem_wdata;
        logic   [3:0]       dmem_wmask;
        logic   [31:0]      dmem_rdata;
    } mm_wb_stage_reg_t;
    
endpackage