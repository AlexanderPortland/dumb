`define STAGE_IF  0
`define STAGE_ID  1
`define STAGE_EX  2
`define STAGE_MEM 3
`define STAGE_WB  4

`define OP_REGS 8'b0110011
`define OP_REGI 8'b0010011
`define OP_LOAD 8'b0000011
`define OP_STR  8'b0100011
`define OP_BRCH 8'b1100011
`define OP_LUI  8'b0110111
`define OP_JAL  8'b1101111
`define OP_JALR 8'b1100111

module CPU (
    input clk,
    input rst
);
    reg [3:0] stage;

    // Control Registers
    reg [31:0] pc;
    reg [31:0] ir;
    reg [31:0] next_pc;

    // Temporary Registers (names stolen from the textbook)
    reg [31:0] A; reg[31:0] B; reg[31:0] Imm; reg[31:0] ALUOutput; reg[31:0] LMD;

    wire [31:0] next_instr;
    ROM_block #(.SZ(4096)) instr_mem(clk, pc, next_instr);

    wire [31:0] rs1_val; wire [31:0] rs2_val;
    wire [31:0] reg_write_data = (ir_op == `OP_LOAD) ? LMD : ALUOutput;
    reg_file regs(clk, rst, reg_w_en, ir_rd, reg_write_data, ir_rs1, rs1_val, ir_rs2, rs2_val);
    // only write to registers if we're an R-R, R-I or LD op
    wire reg_w_en = ((ir_op == `OP_REGS || ir_op == `OP_REGI || ir_op == `OP_LOAD || ir_op == `OP_LUI || ir_op == `OP_JAL || ir_op == `OP_JALR) &&
                       (stage == `STAGE_WB));

    // Decode the instruction into its component parts
    wire [6:0] ir_op  = ir[ 6: 0];
    wire [4:0] ir_rs1 = ir[19:15];
    wire [4:0] ir_rs2 = ir[24:20];
    wire [4:0] ir_rd  = ir[11: 7];
    wire [2:0] ir_f3  = ir[14:12];
    wire [6:0] ir_f7  = ir[31:25];

    wire [32:0] ir_imm_j;
    assign ir_imm_j[32:20] = {13{ir[31]}}; // Sign extend the last upper bits
    assign ir_imm_j[10:1] = ir[30:21];
    assign ir_imm_j[11] = ir[20];
    assign ir_imm_j[19:12] = ir[19:12];
    assign ir_imm_j[0] = 0;

    wire [32:0] ir_imm_b;
    assign ir_imm_b[32:12] = {21{ir[31]}}; // Sign extend the last upper bits
    assign ir_imm_b[10:5] = ir[30:25];
    assign ir_imm_b[4:1] = ir[11:8];
    assign ir_imm_b[11] = ir[7];
    assign ir_imm_b[0] = 0;

    // Decode the immediate portion which is often scattered across the instruction.
    logic [11:0] ir_imm;
    always_comb begin
        case (ir_op)
            `OP_JALR,
            `OP_REGI,
            `OP_LOAD: begin // Type I Instruction
                ir_imm = ir[31:20];
            end
            `OP_STR: begin // Type S Instruction
                ir_imm[11:5] = ir[31:25];
                ir_imm[4 :0] = ir[11: 7];
            end
            default: ir_imm = 12'dX;
        endcase
    end


    wire [31:0] alu_a; wire [31:0] alu_b; wire [31:0] alu_out; wire [6:0] alu_f7;
    ALU alu(alu_a, alu_b, ir_f3, alu_f7, alu_out);
    assign alu_a  = A;
    assign alu_b  = (ir_op == `OP_REGI) ? Imm : B;
    // TODO: not sure if endian-ness is really supposed to flip here or not...
    assign alu_f7 = (ir_op != `OP_REGI) ? ir_f7 : 
                    (ir_f3 == 8'h1 || ir_f3 == 8'h5) ? Imm[11:5] :
                    // ^^ only take funct7 from imm if one of the three ops that uses it
                    7'b0;

    wire [31:0] data_mem_out;
    RAM_block data_mem(clk, mem_w_en, ALUOutput, B, data_mem_out);
    // only enable write if we're in the MEMory access stage of a store op
    wire mem_w_en = (ir_op == `OP_STR && stage == `STAGE_MEM);

    logic brch_taken;
    always_comb begin
        if (ir_op == `OP_BRCH) begin
            case (ir_f3)
                3'h0: brch_taken = (rs1_val == rs2_val);
                3'h1: brch_taken = (rs1_val != rs2_val);
                3'h4: brch_taken = (rs1_val < rs2_val);
                3'h5: brch_taken = (rs1_val >= rs2_val);
                default: brch_taken = 1'hx;
            endcase
        end else begin
            brch_taken = 3'h0;
        end
    end

    initial begin
        pc <= 0;
        stage <= `STAGE_IF;
    end

    always @(posedge clk) begin
        case (stage)
            `STAGE_IF: begin
                next_pc <= pc + 4; // inc pc
                ir <= next_instr;  // fetch IR
            end
            // FIXME: WHY TF DO WE NEED A DECODE PHASE? cant this all be done synchronously?
            `STAGE_ID: begin
                A <= rs1_val;
                B <= rs2_val;
                // TODO: sign extend immediate for add;
                Imm <= {{20{ir_imm[11]}}, ir_imm[11:0]};
                if (ir == 32'h00100073) begin
                    $error("main successfully returned 0x%h", regs.regs[10]);
                    $finish(0);
                end
            end
            `STAGE_EX: begin
                // TODO: factor these out as macros
                if (ir_op == `OP_LOAD || ir_op == `OP_STR) begin
                    // Load/Store: calculate effective address
                    ALUOutput <= A + Imm;
                end else if (ir_op == `OP_REGS || ir_op == `OP_REGI) begin
                    // ALU op
                    ALUOutput <= alu_out;
                    if (alu_out == 32'hcccc) begin
                        $error("unknown alu op 0x%h", ir_f3);
                        $finish(1);
                    end
                end else if (ir_op == `OP_LUI) begin
                    ALUOutput <= ir[31:12] << 12;
                end else if (ir_op == `OP_JAL || ir_op == `OP_JALR) begin
                    // here, prep to store previous return addr
                    ALUOutput <= pc + 4;
                    if (ir_op == `OP_JAL) begin
                        next_pc <= pc + ir_imm_j;
                    end else begin
                        next_pc <= Imm + rs1_val;
                    end
                end else if (ir_op == `OP_BRCH) begin
                    if (brch_taken) begin
                        next_pc <= pc + ir_imm_b;
                    end
                end else begin
                    $error("unknown opcode 0b%b in ir 0x%h", ir_op, ir);
                    $finish(1);
                end
            end
            `STAGE_MEM: begin
                pc <= next_pc;
                if (ir_op == `OP_LOAD) begin
                    // load
                    LMD <= data_mem_out;
                end else if (ir_op == `OP_STR) begin
                    // store
                    // [don't do anything we already wrote by synchronously enabling w_en]
                end else if (ir_op == `OP_LUI) begin
                    // don't do anything here (we're waiting until WB)
                end else if (ir_op == `OP_BRCH) begin
                    // $error("have to handle MEM stage for branches");
                    // $finish(1);
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