module decode
import rv32i_types::*;
(
    input                        clk, 
    input                        rst,
    input   logic                stall,
    input   logic                flush,
    input   if_id_stage_reg_t    data_in,
    input   logic[31:0]          id_rs1_v,
    input   logic[31:0]          id_rs2_v,
    output id_ex_stage_reg_t     data_out,
    output  logic[4:0]           id_rs1_s,
    output  logic[4:0]           id_rs2_s
);

    id_ex_stage_reg_t data_out_next;


    always_comb begin
        if(flush)
            data_out_next.valid = 1'b0;
        else
            data_out_next.valid = data_in.valid;
      
        data_out_next.inst = data_in.inst;
        data_out_next.pc = data_in.pc;
        data_out_next.funct3 = data_in.inst[14:12];
        data_out_next.funct7 = data_in.inst[31:25];
        data_out_next.opcode = data_in.inst[6:0];
        data_out_next.rd_s = data_in.inst[11:7];
        data_out_next.reg_wen = 1'b0;
        data_out_next.dmem_req = 1'b0;
        data_out_next.imm = 32'd0; // for s_rr case, the immediate value will not be used. 
        data_out_next.alu_m1_sel = rs1_out;
        data_out_next.alu_m2_sel = rs2_out;
        data_out_next.rs1_s = '0;
        data_out_next.rs2_s = '0;
        data_out_next.rs1_v = '0;
        data_out_next.rs2_v ='0;
        data_out_next.rd_v = 32'b0;

        case (data_in.inst[6:0])
            op_b_imm: begin
                data_out_next.imm  = ({{21{data_in.inst[31]}}, data_in.inst[30:20]});
                data_out_next.alu_m1_sel = rs1_out;
                data_out_next.alu_m2_sel = imm_out;
                data_out_next.rs1_s = data_in.inst[19:15];
                data_out_next.rs2_s = '0; // don't care
                data_out_next.rs1_v = id_rs1_v;
                data_out_next.rs2_v = id_rs2_v;
                data_out_next.reg_wen = 1'b1;
                case (data_in.inst[11:7]) // nop 
                    5'b00000: begin
                        data_out_next.reg_wen = 1'b0;
                    end
                endcase

            end 
            op_b_reg: begin
                data_out_next.imm = 32'd0;
                data_out_next.alu_m1_sel = rs1_out;
                data_out_next.alu_m2_sel = rs2_out;
                data_out_next.rs1_s = data_in.inst[19:15];
                data_out_next.rs2_s = data_in.inst[24:20];
                data_out_next.rs1_v = id_rs1_v;
                data_out_next.rs2_v = id_rs2_v;
                data_out_next.reg_wen = 1'b1;
            end
            op_b_lui: begin
                data_out_next.imm = {{13{data_in.inst[31]}}, data_in.inst[30:12]} << 'd12;
                data_out_next.alu_m1_sel = rs1_out;
                data_out_next.rs1_s = 5'd0;
                data_out_next.alu_m2_sel = imm_out;
                data_out_next.rs2_s = 5'd0;
                data_out_next.reg_wen = 1'b1;
            end
            op_b_auipc: begin
                data_out_next.imm = {{13{data_in.inst[31]}}, data_in.inst[30:12]} << 'd12;
                data_out_next.alu_m1_sel = pc_out;
                data_out_next.rs1_s = '0;
                data_out_next.alu_m2_sel = imm_out;
                data_out_next.rs2_s = '0;  
                data_out_next.reg_wen = 1'b1;              
            end
            op_b_load: begin
                data_out_next.imm = {{21{data_in.inst[31]}}, data_in.inst[30:20]};
                data_out_next.rs1_s = data_in.inst[19:15];
                data_out_next.rs2_s = '0;
                data_out_next.rs1_v = id_rs1_v;
                data_out_next.rs2_v = 32'b0;
                data_out_next.alu_m1_sel = rs1_out;
                data_out_next.alu_m2_sel = imm_out;
                data_out_next.reg_wen = 1'b1;
                data_out_next.dmem_req = 1'b1;
            end
            op_b_store: begin
                data_out_next.imm = {{21{data_in.inst[31]}}, data_in.inst[30:25], data_in.inst[11:7]};
                data_out_next.rs1_s = data_in.inst[19:15];
                data_out_next.rs2_s = data_in.inst[24:20];
                data_out_next.rs1_v = id_rs1_v;
                data_out_next.rs2_v = id_rs2_v;
                data_out_next.rd_v = 32'b0;
                data_out_next.rd_s = 5'b0;
                data_out_next.alu_m1_sel = rs1_out;
                data_out_next.alu_m2_sel = imm_out;
                data_out_next.reg_wen = 1'b0;
                data_out_next.dmem_req = 1'b1;
            end
            op_b_br:begin
                data_out_next.imm = {{20{data_in.inst[31]}}, data_in.inst[7], data_in.inst[30:25], data_in.inst[11:8], 1'b0};
                data_out_next.rs1_s = data_in.inst[19:15];
                data_out_next.rs2_s = data_in.inst[24:20];
                data_out_next.rs1_v = id_rs1_v;
                data_out_next.rs2_v = id_rs2_v;
                data_out_next.rd_s = 5'b0;
                data_out_next.rd_v = 32'b0;
                data_out_next.alu_m1_sel = rs1_out;
                data_out_next.alu_m2_sel = rs2_out;
                data_out_next.reg_wen = 1'b0;
                data_out_next.dmem_req = 1'b0;
            end 

            op_b_jal: begin
                data_out_next.imm = {{12{data_in.inst[31]}}, data_in.inst[19:12], data_in.inst[20], data_in.inst[30:21], 1'b0};
                data_out_next.rs1_s = 5'b0;
                data_out_next.rs2_s = 5'b0;
                data_out_next.rs1_v = 32'b0;
                data_out_next.rs2_v = 32'b0;
                data_out_next.rd_s = data_in.inst[11:7];
                data_out_next.alu_m1_sel = pc_out;
                data_out_next.alu_m2_sel = imm_out;
                data_out_next.reg_wen = 1'b1;
                data_out_next.dmem_req = 1'b0;
            end
            op_b_jalr: begin
                data_out_next.imm = {{21{data_in.inst[31]}}, data_in.inst[30:20]};
                data_out_next.rs1_s = data_in.inst[19:15];
                data_out_next.rs2_s = 5'b0;
                data_out_next.rs1_v = id_rs1_v;
                data_out_next.rs2_v = 32'b0;
                data_out_next.rd_s = data_in.inst[11:7];
                data_out_next.alu_m1_sel = rs1_out;
                data_out_next.alu_m2_sel = imm_out;
                data_out_next.reg_wen = 1'b1;
                data_out_next.dmem_req = 1'b0;
            end
        endcase

    end 

    assign id_rs1_s = data_in.inst[19:15];
    assign id_rs2_s = data_in.inst[24:20];

    always_ff @(posedge clk) begin
        if(rst) begin
            data_out <= '0;
        end else if(!stall) begin
            data_out <= data_out_next;
        end
    end

endmodule: decode
