module execute
import rv32i_types::*;
(
    input   logic               clk, 
    input   logic               rst, 
    input   logic               stall,
    input   logic               flush,
    input   id_ex_stage_reg_t   data_in,
    input   logic[31:0]         ex_forwarding_a,
    input   logic[31:0]         ex_forwarding_b,
    input   logic               ex_hazard_a,
    input   logic               ex_hazard_b,
    output  ex_mm_stage_reg_t   data_out,
    output  logic[31:0]         ex_dmem_addr,
    output  logic[3:0]          ex_dmem_rmask,
    output  logic[3:0]          ex_dmem_wmask,
    output  logic[31:0]         ex_dmem_wdata,
    output  logic               ex_br_en,
    output  logic[31:0]         ex_br_target
);

    logic [3:0] aluop;
    logic   [31:0]  a;
    logic   [31:0]  b;
    // logic   [31:0]  as;
    // logic   [31:0]  bs;
    // logic   [31:0]  au;
    // logic   [31:0]  bu;
    logic   [31:0]  aluout;

    ex_mm_stage_reg_t   data_out_next;

    // assign as =   signed'(a);
    // assign bs =   signed'(b);
    // assign au = unsigned'(a);
    // assign bu = unsigned'(b);

    logic   [31:0]      w_byte_mask;

    logic   [3:0]       wmask;
    logic   [3:0]       rmask;
    logic   [31:0]      wdata;

    always_comb begin
        case (data_in.alu_m1_sel)
            pc_out: a = data_in.pc;
            rs1_out: begin
                case (ex_hazard_a)
                    1'b0: a = data_in.rs1_v;
                    1'b1: a = ex_forwarding_a;
                endcase
            end
            default: a = '0;
        endcase
    end

    always_comb begin
        case (data_in.alu_m2_sel)
            rs2_out: begin
                case (ex_hazard_b)
                    1'b0: b = data_in.rs2_v;
                    1'b1: b = ex_forwarding_b;
                endcase                
            end

            imm_out: b = data_in.imm;
            d4_out: b = 'd4;
            default: b = '0;
        endcase
    end

    always_comb begin
        if(ex_hazard_b && (data_in.opcode == op_b_store))
            wdata = ex_forwarding_b;
        else   
            wdata = data_in.rs2_v;
    end

    // drive the alu operatsions, brach enable, branch target
    always_comb begin
        ex_br_en = 1'b0;
        ex_br_target = 32'b0;
        
        ex_dmem_addr = 32'b0;
        rmask = 4'b0;
        wmask = 4'b0;
        ex_dmem_wdata = 32'b0;

        data_out_next.rd_v = aluout;

        case (data_in.opcode)
            op_b_reg: begin
                case (data_in.funct3)
                    arith_f3_add: begin
                        if(data_in.funct7[5]) begin
                            aluop = alu_op_sub;
                        end else begin
                            aluop = alu_op_add;
                        end
                    end
                    arith_f3_sr: begin
                        if(data_in.funct7[5]) begin
                            aluop = alu_op_sra;
                        end else begin
                            aluop = alu_op_srl;
                        end
                    end
                    arith_f3_sll:   aluop = alu_op_sll;                   
                    arith_f3_slt:   aluop = alu_op_slt;
                    arith_f3_sltu:  aluop = alu_op_sltu;
                    arith_f3_xor:   aluop = alu_op_xor;
                    arith_f3_or:    aluop = alu_op_or;
                    arith_f3_and:   aluop = alu_op_and;
                    default:        aluop = {1'b0, data_in.funct3};
                endcase
            end

            op_b_imm: begin
                case(data_in.funct3)
                    arith_f3_sr: begin
                        if(data_in.funct7[5]) begin
                            aluop = alu_op_sra;
                        end else begin
                            aluop = alu_op_srl;
                        end
                    end
                    arith_f3_add: aluop = alu_op_add;
                    arith_f3_sll: aluop = alu_op_sll;
                    arith_f3_slt: aluop = alu_op_slt;
                    arith_f3_sltu: aluop = alu_op_sltu;
                    arith_f3_xor: aluop = alu_op_xor;
                    arith_f3_or: aluop = alu_op_or;
                    arith_f3_and: aluop = alu_op_and;
                    default: aluop = {1'b0, data_in.funct3};
                endcase
            end

            op_b_lui, op_b_auipc: aluop = alu_op_add;

            op_b_load: begin
                aluop = alu_op_add;

                ex_dmem_addr = aluout & ~32'd3;
                wmask = 4'b0000;
                ex_dmem_wdata = 32'b0;
                case (data_in.funct3)
                    load_f3_lb, load_f3_lbu: begin
                        rmask = 4'b0001 << aluout[1:0];
                    end 
                    load_f3_lh, load_f3_lhu: begin
                        rmask = 4'b0011 << aluout[1:0];
                    end
                    load_f3_lw: begin
                        rmask = 4'b1111;
                    end
                    default: begin
                        rmask = 4'b0000;
                    end
                endcase
            end

            op_b_store: begin
                aluop = alu_op_add;
                ex_br_en = 1'b0;
                ex_br_target = 32'b0;
                ex_dmem_addr = aluout & ~32'd3;
                case (data_in.funct3)
                    store_f3_sb: begin
                        wmask = 4'b0001 << aluout[1:0];
                        case (wmask)
                            4'b0001: ex_dmem_wdata = {24'b0, {wdata[7:0]}};
                            4'b0010: ex_dmem_wdata = {16'b0, {wdata[7:0]}, 8'b0};
                            4'b0100: ex_dmem_wdata = {8'b0, {wdata[7:0]}, 16'b0};
                            4'b1000: ex_dmem_wdata = {{wdata[7:0]}, 24'b0};
                            default: ex_dmem_wdata = 32'b0;
                        endcase
                    end 
                    store_f3_sh: begin
                        wmask = 4'b0011 << aluout[1:0];
                        case (wmask)
                            4'b0011: ex_dmem_wdata = {16'b0, {wdata[15:0]}};
                            4'b1100: ex_dmem_wdata = {{wdata[15:0]}, 16'b0};
                            default: ex_dmem_wdata = 32'b0;
                        endcase
                    end 
                    store_f3_sw: begin
                        wmask = 4'b1111;
                        ex_dmem_wdata = wdata;
                    end
                    default: begin
                        wmask = 4'b0000;
                        ex_dmem_wdata = 32'b0;
                    end
                endcase
            end

            op_b_br: begin
                case (data_in.funct3)
                    branch_f3_beq: aluop = alu_op_eq;
                    branch_f3_bne: aluop = alu_op_ne;
                    branch_f3_blt: aluop = alu_op_slt;
                    branch_f3_bge: aluop = alu_op_ge;
                    branch_f3_bltu: aluop = alu_op_sltu;
                    branch_f3_bgeu: aluop = alu_op_geu;
                    default: aluop = '0;
                endcase
                ex_br_en = aluout[0] & data_in.valid;
                ex_br_target = data_in.pc + data_in.imm;
            end

            op_b_jal: begin
                aluop = alu_op_add;
                ex_br_en = 1'b1 & data_in.valid; // unconditional
                ex_br_target = aluout;
                data_out_next.rd_v = data_in.pc + 32'd4;
            end

            op_b_jalr: begin
                aluop = alu_op_add;
                ex_br_en = 1'b1 & data_in.valid; // unconditional 
                ex_br_target = aluout & 32'hfffffffe;
                data_out_next.rd_v = data_in.pc + 32'd4;
            end

            default: begin
                aluop = {1'b0, data_in.funct3};
                ex_br_en = 1'b0;
                ex_br_target = 32'b0;
            end
        endcase
        ex_dmem_rmask = rmask & {4{data_in.valid}};
        ex_dmem_wmask = wmask & {4{data_in.valid}};

        if(flush)
            data_out_next.valid = 1'b0;
        else 
            data_out_next.valid = data_in.valid;
        data_out_next.inst = data_in.inst;
        data_out_next.pc = data_in.pc;
        data_out_next.pc_wdata = (ex_br_en)? ex_br_target : data_in.pc + 32'd4;
        data_out_next.rs1_s = data_in.rs1_s;
        data_out_next.rs2_s = data_in.rs2_s;
        data_out_next.rs1_v = a;
        data_out_next.rs2_v = (data_in.opcode == op_b_store)? wdata : b;
        data_out_next.rd_s = data_in.rd_s;
        data_out_next.reg_wen = data_in.reg_wen;
        data_out_next.dmem_req = data_in.dmem_req;
        data_out_next.dmem_addr = ex_dmem_addr;
        data_out_next.dmem_rmask = ex_dmem_rmask;
        data_out_next.dmem_wmask = ex_dmem_wmask;
        data_out_next.dmem_wdata = ex_dmem_wdata;
    end

    always_comb begin
        unique case (aluop)
            alu_op_add: aluout = a +   b; /////
            alu_op_sll: aluout = a <<  b[4:0];
            alu_op_sra: aluout = unsigned'(signed'(a) >>> b[4:0]);   
            alu_op_sub: aluout = a -   b;
            alu_op_xor: aluout = a ^   b;
            alu_op_srl: aluout = a >>  b[4:0]; 
            alu_op_or : aluout = a |   b;
            alu_op_and: aluout = a &   b;
            alu_op_slt: aluout = (signed'(a) < signed'(b)) ? 32'b1 : 32'b0;
            alu_op_sltu: aluout = (unsigned'(a) < unsigned'(b)) ? 32'b1 : 32'b0;
            alu_op_eq: aluout = {31'b0, {(a == b)}};
            alu_op_ne: aluout = {31'b0, {(a != b)}};
            alu_op_ge: aluout = {31'b0, {(signed'(a) >= signed'(b))}};
            alu_op_geu: aluout = {31'b0, {(unsigned'(a) >= unsigned'(b))}};
            default   : aluout = 'x;
        endcase
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            data_out <= '0;
        end else if(!stall) begin
            data_out <= data_out_next;
        end
    end

endmodule: execute