module regfile
(
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we,
    input   logic   [31:0]  rd_v,
    input   logic   [4:0]   rs1_s, rs2_s, rd_s,
    output  logic   [31:0]  rs1_v, rs2_v
);

            logic   [31:0]  data [32];
            logic   [31:0]  no_hazard_rs1_v;
            logic   [31:0]  no_hazard_rs2_v;
            logic           reg1_hazard;
            logic           reg2_hazard;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < 32; i++) begin
                data[i] <= '0;
            end
        end else if (regf_we && (rd_s != 5'd0)) begin
            data[rd_s] <= rd_v;
        end
    end

    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         rs1_v <= 'x;
    //         rs2_v <= 'x;
    //     end else begin
    //         rs1_v <= (rs1_s != 5'd0) ? data[rs1_s] : '0;
    //         rs2_v <= (rs2_s != 5'd0) ? data[rs2_s] : '0;
    //     end
    // end

    always_comb begin
        no_hazard_rs1_v = (rs1_s != 5'd0) ? data[rs1_s] : '0;
        no_hazard_rs2_v = (rs2_s != 5'd0) ? data[rs2_s] : '0;           
    end

    // load use hazard logic

    assign reg1_hazard = regf_we && (rd_s == rs1_s) && (rd_s != 0);
    assign reg2_hazard = regf_we && (rd_s == rs2_s) && (rd_s != 0);
    assign rs1_v = (reg1_hazard)? rd_v : no_hazard_rs1_v;
    assign rs2_v = (reg2_hazard)? rd_v: no_hazard_rs2_v;

endmodule : regfile