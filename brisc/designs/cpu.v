`define STAGE_IF  0
`define STAGE_ID  1
`define STAGE_EX  2
`define STAGE_MEM 3
`define STAGE_WB  4

module moduleName (
    input clk,
    input rst
);
    reg [3:0] stage;

    reg [31:0] pc;
    reg [31:0] ir;
    reg [31:0] next_pc;

    reg [31:0] A; reg[31:0] B; reg[31:0] Imm; reg[31:0] ALUOutput; reg[31:0] LMD;

    wire [31:0] next_instr;
    ROM_block #(.SZ(4096)) instr_mem(clk, pc, next_instr);

    // just bc i dont want to use these ports yet...
    reg [31:0] write_data;

    wire [31:0] rs1_val; wire [31:0] rs2_val;
    wire reg_w_en;
    reg_file regs(clk, rst, reg_w_en, ir_rd, ALUOutput, ir_rs1, rs1_val, ir_rs2, rs2_val);
    // only write to registers if we're R-R, R-I or load
    assign reg_w_en = ((ir_op == 8'b0110011 || ir_op == 8'b0010011 || ir_op == 8'b0000011) &&
                       (stage == `STAGE_WB));

    wire [4:0] ir_rs1; wire [4:0] ir_rs2; wire [4:0] ir_rd; wire [11:0] ir_imm; wire [2:0] ir_f3;
    wire [6:0] ir_op; wire[6:0] ir_f7;
    assign ir_rs1 = ir[19:15];
    assign ir_rs2 = ir[24:20];
    assign ir_rd  = ir[11: 7];
    assign ir_imm = ir[31:20];
    assign ir_f3  = ir[14:12];
    assign ir_op  = ir[ 6: 0];
    assign ir_f7  = ir[31:25];

    wire [31:0] alu_a; wire [31:0] alu_b; wire [31:0] alu_out; wire [6:0] alu_f7;
    ALU alu(alu_a, alu_b, ir_f3, alu_f7, alu_out);
    assign alu_a  = A;
    assign alu_b  = (ir_op == 8'b0010011) ? Imm : B;
    // TODO: not sure if endian-ness is supposed to flip here or not...
    assign alu_f7 = (ir_op == 8'b0010011) ? Imm[11:5] : ir_f7;

    wire [31:0] data_mem_out; wire mem_w_en;
    RAM_block data_mem(clk, mem_w_en, ALUOutput, B, data_mem_out);
    // only enable write if we're in the MEMory access stage of a store op
    assign mem_w_en = (ir_op == 8'b0100011 && stage == `STAGE_MEM);

    initial begin
        pc <= 0;
        stage <= `STAGE_IF;
        write_data <= 0;
    end

    always @(posedge clk) begin
        case (stage)
            `STAGE_IF: begin
                next_pc <= pc + 4; // inc pc
                ir <= next_instr;  // fetch IR
            end
            `STAGE_ID: begin
                A <= rs1_val;
                B <= rs2_val;
                Imm <= {{20{ir_imm[11]}}, ir_imm[11:0]};
            end
            `STAGE_EX: begin
                // TODO: factor these out as macros
                if (ir_op == 8'b0000011 || ir_op == 8'b0100011) begin
                    // Load/Store: calculate effective address
                    ALUOutput <= A + Imm;
                end else if (ir_op == 8'b0110011 || ir_op == 8'b0010011) begin
                    // ALU op
                    ALUOutput <= alu_out;
                    if (alu_out == 32'hcccc) begin
                        $error("unknown alu op 0x%h", ir_f3);
                        $finish(1);
                    end
                end else begin
                    $error("unknown opcode 0b%b", ir_op);
                    $finish(1);
                end
            end
            `STAGE_MEM: begin
                pc <= next_pc;
                if (ir_op == 8'b0000011) begin
                    // load
                    LMD <= data_mem_out;
                end else if (ir_op == 8'b0100011) begin
                    // store
                    // [don't do anything we already wrote by synchronously enabling w_en]
                end else if (ir_op == 8'b1100011) begin
                    $error("have to handle MEM stage for branches");
                    $finish(1);
                end
            end
            `STAGE_WB: begin

            end
            default: begin
                $error("unknown stage");
                $finish(1);
            end
        endcase

        // update the current stage
        if (stage != `STAGE_WB) begin
            stage <= stage + 1;
        end else begin
            stage <= `STAGE_IF;
        end
    end
endmodule