module writeback
import rv32i_types::*;
(
    input   logic               rst,
    input   logic               stall,
    input   mm_wb_stage_reg_t   data_in,   
    output  logic               wb_commit,
    output  logic                       wb_regf_wen,
    output  logic [31:0]                wb_rd_v,
    output  logic [4:0]                 wb_rd_s
);

    logic       [31:0]          byte_mask;
    assign byte_mask = {{8{data_in.dmem_rmask[3]}}, {8{data_in.dmem_rmask[2]}}, {8{data_in.dmem_rmask[1]}}, {8{data_in.dmem_rmask[0]}}};

    always_comb begin
        case (data_in.inst[6:0]) 
            op_b_load: begin
                case (data_in.inst[14:12])
                    load_f3_lb: begin
                        case (data_in.dmem_rmask)
                            4'b0001: wb_rd_v = {{25{data_in.dmem_rdata[7]}}, data_in.dmem_rdata[6:0]};
                            4'b0010: wb_rd_v = {{25{data_in.dmem_rdata[15]}}, data_in.dmem_rdata[14:8]};
                            4'b0100: wb_rd_v = {{25{data_in.dmem_rdata[23]}}, data_in.dmem_rdata[22:16]};
                            4'b1000: wb_rd_v = {{25{data_in.dmem_rdata[31]}}, data_in.dmem_rdata[30:24]};   
                            default: wb_rd_v = 32'b0; 
                        endcase                        
                    end 

                    load_f3_lbu: begin
                        case (data_in.dmem_rmask)
                            4'b0001: wb_rd_v = {24'b0, data_in.dmem_rdata[7:0]};
                            4'b0010: wb_rd_v = {24'b0, data_in.dmem_rdata[15:8]};
                            4'b0100: wb_rd_v = {24'b0, data_in.dmem_rdata[23:16]};
                            4'b1000: wb_rd_v = {24'b0, data_in.dmem_rdata[31:24]};   
                            default: wb_rd_v = 32'b0;     
                        endcase               
                    end

                    load_f3_lh: begin
                        case (data_in.dmem_rmask)
                            4'b0011: wb_rd_v = {{17{data_in.dmem_rdata[15]}}, data_in.dmem_rdata[14:0]};
                            4'b1100: wb_rd_v = {{17{data_in.dmem_rdata[31]}}, data_in.dmem_rdata[30:16]};
                            default: wb_rd_v = 32'b0;
                        endcase
                    end

                    load_f3_lhu: begin
                        case (data_in.dmem_rmask) 
                            4'b0011: wb_rd_v = {16'b0, data_in.dmem_rdata[15:0]};
                            4'b1100: wb_rd_v = {16'b0, data_in.dmem_rdata[31:16]};   
                            default: wb_rd_v = 32'b0;
                        endcase                    
                    end

                    load_f3_lw: begin
                        wb_rd_v = data_in.dmem_rdata;    
                    end   
                    default: wb_rd_v = 32'b0;
               
                endcase
                wb_rd_s = data_in.rd_s;
                wb_regf_wen = 1'b1 & data_in.valid;
            end

            op_b_store: begin //store instruction sends no request to register file at the WB stage
                wb_regf_wen = 1'b0;
                wb_rd_v = 32'b0;
                wb_rd_s = 5'b0;
            end

            op_b_lui, op_b_auipc, op_b_imm, op_b_reg, op_b_jal, op_b_jalr: begin
                wb_regf_wen = 1'b1 & data_in.valid;
                wb_rd_v = data_in.rd_v;
                wb_rd_s = data_in.rd_s;
            end

            default: begin
                wb_regf_wen = 1'b0;
                wb_rd_v = 32'b0;
                wb_rd_s = 5'b0;
            end             
        endcase
    end

    always_comb begin
        if(rst) begin
            wb_commit = 1'b0;
        end else if(data_in.valid & ~stall) begin
            wb_commit = 1'b1;
        end else
            wb_commit = 1'b0;
    end

endmodule: writeback