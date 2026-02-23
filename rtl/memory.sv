//accepting the response comming from data memory. 

module memory
import rv32i_types::*;
(
    input   logic                       clk, 
    input   logic                       rst, 
    input   logic                       stall,
    input   logic                       flush,
    input   ex_mm_stage_reg_t           data_in,
    input   logic[31:0]                 mm_dmem_rdata,
    input   logic                       mm_imem_resp,
    input   logic                       mm_dmem_resp,
    output  mm_wb_stage_reg_t           data_out,
    output  logic                       mm_d_flight
);
    logic   [31:0]              dbuf;
    logic   [31:0]              dbuf_next;
    logic                       dbuf_resp;
    logic                       dbuf_resp_next;


    always_comb begin
        if(mm_imem_resp) begin
            dbuf_next = 32'b0;
            dbuf_resp_next = 1'b0;
        end else if (mm_dmem_resp) begin
            dbuf_next = mm_dmem_rdata;
            dbuf_resp_next = 1'b1;
        end else begin
            dbuf_next = dbuf;
            dbuf_resp_next = dbuf_resp;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            dbuf <= '0;
            dbuf_resp <= 1'b0;
        end else begin
            dbuf <= dbuf_next;
            dbuf_resp <= dbuf_resp_next;
        end
    end


    mm_wb_stage_reg_t           data_out_next;
    logic    [31:0]                   dmem_rdata;
    logic                             dmem_resp;

    always_comb begin
        if (mm_dmem_resp) begin
            dmem_rdata = mm_dmem_rdata;
            dmem_resp = mm_dmem_resp;
        end else begin
            dmem_rdata = dbuf;
            dmem_resp = dbuf_resp;
        end
    end
    always_comb begin
        if(flush)
            data_out_next.valid = 1'b0;
        else 
            data_out_next.valid = data_in.valid;

        data_out_next.inst = data_in.inst;
        data_out_next.pc = data_in.pc;
        data_out_next.pc_wdata = data_in.pc_wdata;
        data_out_next.rs1_s = data_in.rs1_s;
        data_out_next.rs1_v = data_in.rs1_v;
        data_out_next.rs2_s = data_in.rs2_s;
        data_out_next.rs2_v = data_in.rs2_v;
        data_out_next.rd_v = data_in.rd_v;
        data_out_next.rd_s = data_in.rd_s;
        data_out_next.reg_wen = data_in.reg_wen;
        data_out_next.dmem_addr = data_in.dmem_addr;
        data_out_next.dmem_rmask = data_in.dmem_rmask;
        data_out_next.dmem_wdata = data_in.dmem_wdata;
        data_out_next.dmem_wmask = data_in.dmem_wmask;
        data_out_next.dmem_rdata = dmem_rdata;
        case (data_in.inst[6:0])
            op_b_load: begin
                data_out_next.rd_v = dmem_rdata;
            end
        endcase

    end


    always_ff @(posedge clk) begin
        if(rst) begin
            data_out <= '0;
        end else if(~stall) begin
            data_out <= data_out_next;
        end
    end

    assign mm_d_flight = data_in.valid & data_in.dmem_req & !mm_dmem_resp & !dmem_resp;

endmodule: memory