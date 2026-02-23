module cpu
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp
);

    // pipeline control signals 
    logic   g_stall;
    logic   dmem_flight;
    logic   ifid_flush, idex_flush, exmm_flush, mmwb_flush;
    logic   ifid_stall, idex_stall, exmm_stall, mmwb_stall;    

    // branch signals          
    logic                   br_en;
    logic   [31:0]          br_target;

    // load use hazard
    logic   load_use_hazard_flag;

    // pipeline registers
    if_id_stage_reg_t       ifid_reg;
    id_ex_stage_reg_t       idex_reg;
    ex_mm_stage_reg_t       exmm_reg;
    mm_wb_stage_reg_t       mmwb_reg;

    // register file signals
    logic   [31:0]          reg_rs1_v;
    logic   [31:0]          reg_rs2_v;
    logic                   regfile_wen;
    logic   [31:0]          reg_rd_v;
    logic   [4:0]           reg_rd_s;
    logic   [4:0]           reg_rs1_s;
    logic   [4:0]           reg_rs2_s;

    // data hazard detection signals
    logic [31:0] forwarding_a, forwarding_b; 
    logic data_hazard_a, data_hazard_b;

    // write back signals
    logic                   commit;
    logic   [63:0]          order;

    always_comb begin
        forwarding_a = 32'b0;
        forwarding_b = 32'b0;
        data_hazard_a = 1'b0;
        data_hazard_b = 1'b0;

        if(exmm_reg.reg_wen && (exmm_reg.rd_s != 0) && (exmm_reg.rd_s == idex_reg.rs1_s) && exmm_reg.valid && idex_reg.valid) begin
            forwarding_a = exmm_reg.rd_v;
            data_hazard_a = 1'b1;
        end else if(mmwb_reg.reg_wen && (mmwb_reg.rd_s != 0) && (mmwb_reg.rd_s == idex_reg.rs1_s) && mmwb_reg.valid && idex_reg.valid) begin
            forwarding_a = reg_rd_v;
            data_hazard_a = 1'b1;
        end 
        
        if(exmm_reg.reg_wen && (exmm_reg.rd_s != 0) && (exmm_reg.rd_s == idex_reg.rs2_s) && exmm_reg.valid && idex_reg.valid) begin
            forwarding_b = exmm_reg.rd_v;
            data_hazard_b = 1'b1;
        end else if(mmwb_reg.reg_wen && (mmwb_reg.rd_s != 0) && (mmwb_reg.rd_s == idex_reg.rs2_s) && mmwb_reg.valid && idex_reg.valid) begin
            forwarding_b = reg_rd_v;
            data_hazard_b = 1'b1;
        end 
    end

    assign load_use_hazard_flag = (((idex_reg.rd_s == ifid_reg.inst[19:15]) || (idex_reg.rd_s == ifid_reg.inst[24:20]))
                                && (idex_reg.opcode == op_b_load) && idex_reg.valid && ifid_reg.valid && idex_reg.reg_wen && (idex_reg.rd_s != 0));

    // pipeline control logic 
    assign g_stall = !imem_resp | dmem_flight;
    always_comb begin
        ifid_flush = 1'b0;
        idex_flush = 1'b0;
        exmm_flush = 1'b0;
        mmwb_flush = 1'b0;
        ifid_stall = g_stall;
        idex_stall = g_stall;
        exmm_stall = g_stall;
        mmwb_stall = g_stall;
        if(br_en) begin
            ifid_flush = 1'b1;
            idex_flush = 1'b1;
        end else if (load_use_hazard_flag) begin
            idex_flush = 1'b1;
            ifid_stall = 1'b1;
        end
    end  
    

    fetch fetch_stage (
        .clk                (clk),
        .rst                (rst),
        .stall              (ifid_stall),
        .flush              (ifid_flush),
        .if_br_en           (br_en),
        .if_br_target       (br_target),
        .if_imem_rdata      (imem_rdata),
        .data_out           (ifid_reg), // pc
        .if_imem_addr       (imem_addr),
        .if_imem_rmask      (imem_rmask)
    );

    decode decode_stage (
        .clk                (clk),
        .rst                (rst),
        .stall              (idex_stall),
        .flush              (idex_flush),
        .data_in            (ifid_reg),
        .id_rs1_v           (reg_rs1_v),
        .id_rs2_v           (reg_rs2_v),
        .data_out           (idex_reg), // pc, inst, opcode, rs1_s, rs2_s, alu_m1_sel, alu_m2_sel, funct3, funct7, imm, dmem_req, rd_s, rd_v, reg_wen
        .id_rs1_s           (reg_rs1_s),
        .id_rs2_s           (reg_rs2_s)
    );

    logic   [3:0]       ex_rmask;
    logic   [3:0]       ex_wmask;
    assign dmem_rmask = ex_rmask & {4{!g_stall}};
    assign dmem_wmask = ex_wmask & {4{!g_stall}};

    execute execute_stage (
        .clk                (clk),
        .rst                (rst),
        .stall              (exmm_stall),
        .flush              (exmm_flush),
        .data_in            (idex_reg),
        .ex_forwarding_a    (forwarding_a),
        .ex_forwarding_b    (forwarding_b),
        .ex_hazard_a        (data_hazard_a),
        .ex_hazard_b        (data_hazard_b),
        .data_out           (exmm_reg),  
        .ex_dmem_addr       (dmem_addr),
        .ex_dmem_rmask      (ex_rmask),
        .ex_dmem_wmask      (ex_wmask),
        .ex_dmem_wdata      (dmem_wdata),
        .ex_br_en           (br_en),
        .ex_br_target       (br_target)
    );

    memory memory_stage (
        .clk                (clk),
        .rst                (rst),
        .stall              (mmwb_stall),
        .flush              (mmwb_flush),
        .data_in            (exmm_reg),
        .mm_dmem_rdata      (dmem_rdata),
        .mm_imem_resp       (imem_resp),
        .mm_dmem_resp       (dmem_resp),
        .data_out           (mmwb_reg), 
        .mm_d_flight        (dmem_flight)
    );

    writeback writeback_stage (
        .rst                (rst),
        .data_in            (mmwb_reg),
        .stall              (g_stall),
        .wb_commit          (commit),
        .wb_regf_wen        (regfile_wen),
        .wb_rd_v            (reg_rd_v),
        .wb_rd_s            (reg_rd_s)
    );

    regfile register_file (
        .clk                (clk),
        .rst                (rst),
        .regf_we            (regfile_wen & !g_stall),
        .rd_v               (reg_rd_v),
        .rs1_s              (reg_rs1_s),
        .rs2_s              (reg_rs2_s),
        .rd_s               (reg_rd_s),
        .rs1_v              (reg_rs1_v),
        .rs2_v              (reg_rs2_v)
    );


    always_ff   @(posedge clk) begin
        if(rst) begin
            order <= 64'd0;
        end else if (commit) begin
            order <= order + 1'd1;
        end 
    end


            logic           monitor_valid;
            logic   [63:0]  monitor_order;
            logic   [31:0]  monitor_inst;
            logic   [4:0]   monitor_rs1_addr;
            logic   [4:0]   monitor_rs2_addr;
            logic   [31:0]  monitor_rs1_rdata;
            logic   [31:0]  monitor_rs2_rdata;
            logic           monitor_regf_we;
            logic   [4:0]   monitor_rd_addr;
            logic   [31:0]  monitor_rd_wdata;
            logic   [31:0]  monitor_pc_rdata;
            logic   [31:0]  monitor_pc_wdata;
            logic   [31:0]  monitor_mem_addr;
            logic   [3:0]   monitor_mem_rmask;
            logic   [3:0]   monitor_mem_wmask;
            logic   [31:0]  monitor_mem_rdata;
            logic   [31:0]  monitor_mem_wdata;

    assign monitor_valid     = commit;
    assign monitor_order     = order;
    assign monitor_inst      = mmwb_reg.inst;
    assign monitor_rs1_addr  = mmwb_reg.rs1_s;
    assign monitor_rs2_addr  = mmwb_reg.rs2_s;
    assign monitor_rs1_rdata = mmwb_reg.rs1_v;
    assign monitor_rs2_rdata = mmwb_reg.rs2_v;
    assign monitor_rd_addr   = mmwb_reg.rd_s;
    assign monitor_rd_wdata  = reg_rd_v;
    assign monitor_regf_we   = regfile_wen & !g_stall;
    assign monitor_pc_rdata  = mmwb_reg.pc;
    assign monitor_pc_wdata  = mmwb_reg.pc_wdata;
    assign monitor_mem_addr  = mmwb_reg.dmem_addr;
    assign monitor_mem_rmask = mmwb_reg.dmem_rmask;
    assign monitor_mem_wmask = mmwb_reg.dmem_wmask;
    assign monitor_mem_rdata = mmwb_reg.dmem_rdata;
    assign monitor_mem_wdata = mmwb_reg.dmem_wdata;



endmodule : cpu
/// global stall for imem, backpressure for dmem, why???



