module fetch
import rv32i_types::*;
(   
    input   logic               clk,
    input   logic               rst,
    input   logic               stall,
    input   logic               flush,
    input   logic               if_br_en,
    input   logic   [31:0]      if_br_target,
    input   logic   [31:0]      if_imem_rdata,
    output  if_id_stage_reg_t   data_out,
    output  logic[31:0]         if_imem_addr,
    output  logic[3:0]          if_imem_rmask
);
    logic   [31:0]          pc;
    logic   [31:0]          pc_next;

    if_id_stage_reg_t       data_out_next;

    assign if_imem_rmask = 4'b1111;
    assign if_imem_addr = (rst)? 32'haaaaa000: pc_next;

// if id reg
    always_comb begin
        if(!stall) begin
            data_out_next.inst = if_imem_rdata;
            data_out_next.pc = pc;
        end else begin
            data_out_next.inst = data_out.inst;
            data_out_next.pc = data_out.pc;
        end
    
        if(flush) begin
            data_out_next.valid = 1'b0;
        end else if (!stall) begin
            data_out_next.valid = 1'b1;
        end else begin
            data_out_next.valid = data_out.valid;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            data_out <= '0;
        end else begin
            data_out <= data_out_next;
        end
    end

// pc_reg
    always_comb begin
        if(stall)begin
            pc_next = pc;
        end else if (if_br_en) begin
            pc_next = if_br_target;
        end else begin
            pc_next = pc + 32'd4;
        end
    end
    
    always_ff @(posedge clk) begin
        if(rst) begin
            pc <= 32'haaaaa000;
        end else begin
            pc <= pc_next;
        end
    end



endmodule : fetch


/// TO DO: remember to propagate the order

