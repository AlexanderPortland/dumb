
`define BUS_MUX_PC 2'd1
`define BUS_MUX_ACC 2'd2
`define BUS_MUX_MEM 2'd3

`define ADDR_MUX_PC  2'd0
`define ADDR_MUX_BUS 2'd1
`define ADDR_MUX_SP  2'd2

`define SP_START_ADDR 8'd254

`define SP_SAME 2'd0
`define SP_INC  2'd1
`define SP_DEC  2'd2
// `define SP_LOAD 2'd3

// trying to make a very simple CPU
module dCPU(
    input clk,
    input rst,
    input [7:0] mem_in,
    output R, W,
    output reg [7:0] addr,
    output [7:0] data_out,
    output reg stop
);
    wire set_stop;

    wire ar_load;
    wire [7:0] data_bus;
    assign data_out = data_bus;

    // store the current program counter and intruction register.
    reg [7:0] pc, ir;
    wire pc_inc, pc_load, ir_load;

    // stack pointer (currently points 8b below the start of the stack for simplicity)
    reg [7:0] sp;
    wire [1:0] sp_chg;

    // register for operating on data
    reg [7:0] acc;
    wire ac_load;

    reg [3:0] flags;
    wire flags_load;

    // wires for interfacing w/ the ALU
    wire [3:0] alu_op;
    wire [7:0] alu_out; wire [3:0] alu_flags;
    dALU alu(acc, data_bus, alu_op, alu_out, alu_flags);

    wire [1:0] bus_mux;
    wire [1:0] addr_mux;
    control c(ir, flags, clk, rst, R, W, pc_inc, pc_load, sp_chg, ac_load, ar_load, ir_load, alu_op, flags_load, addr_mux, bus_mux, set_stop);

    // assign based on control's mux output
    assign data_bus = (bus_mux == `BUS_MUX_ACC) ? acc : 
                      (bus_mux == `BUS_MUX_PC)  ? pc : 
                      (bus_mux == `BUS_MUX_MEM) ? mem_in : 0;

    always @(posedge clk or posedge rst) begin
        // increment pc
        if (rst) begin
            pc <= 0;
            ir <= 0;
            acc <= 0;
            addr <= 0;
            flags <= 4'b0;
            sp <= `SP_START_ADDR;
            stop <= 0;
        end else begin
            // increment the pc or load a new value from the data bus
            if (pc_inc) begin 
                pc <= pc + 1;
            end else if (pc_load) begin
                pc <= data_bus;
            end

            case (sp_chg)
                // NOTE: the inc case here is intentionally non blocking, to ensure that
                // it takes effect before using its value to set the addr register
                // TODO: is this hella jank? idk if this will work in real life.
                `SP_INC: sp = sp + 1;
                `SP_DEC: sp <= sp - 1;
                // don't do anything on SP_SAME
            endcase

            // fetch instruction from the data bus
            if (ir_load) ir <= data_bus;
            if (flags_load) flags <= alu_flags;
            if (ac_load) acc <= alu_out;
            if (set_stop) stop <= 1;

            if (ar_load) begin
                case (addr_mux)
                    `ADDR_MUX_PC: addr = pc;
                    `ADDR_MUX_BUS: addr = data_bus;
                    `ADDR_MUX_SP: addr = sp;
                    default: addr = 0;
                endcase
            end
        end
    end
endmodule

// dCPU instruction codes
// full list at: https://docs.google.com/spreadsheets/d/1c0boO_7xaOKxYpqUAhQFa4LIaI-Rz7ZPAWl9ut44rdk/edit?usp=sharing
`define INSTR_LITA  8'hc0
`define INSTR_LOADA 8'hc1
`define INSTR_STORA 8'hc2
`define INSTR_ADD   8'hc3
`define INSTR_JMP   8'hc4
`define INSTR_JMPZ  8'hc5
`define INSTR_JMPC  8'hc6 // TODO: I think i messed up the order, so this is set if acc > M
`define INSTR_SUB   8'hc7
`define INSTR_CMP   8'hc8
`define INSTR_JMPNC 8'hc9 // and this is acc <= M
`define INSTR_PUSH  8'hca
`define INSTR_POP   8'hcb
`define INSTR_STOP  8'hcc
`define INSTR_NOP   8'h90

// TODO: i want to make a linting script to check for collisions

module control(
    input [7:0] instr,
    input [3:0] flags,
    input clk,
    input rst,
    output R, W,
    output pc_inc,
    output pc_load,
    output [1:0] sp_chg,
    output ac_load,
    output ar_load,
    output ir_load,
    output [3:0] alu_op,
    output flags_load,
    output [1:0] addr_mux, // where to take the address output from
    output [1:0] bus_mux,   // where to take the data bus output from
    output set_stop
);
    reg [2:0] state;
    wire clear;

    // TODO: would love some way to detect and stop on an unsupported opcode.
    wire jmp_taken;
    assign jmp_taken = (state == 3 && 
                        (instr == `INSTR_JMP || 
                        (instr == `INSTR_JMPZ && flags[`FLAGS_ZERO])  ||
                        (instr == `INSTR_JMPC && flags[`FLAGS_CARRY]) ||
                        (instr == `INSTR_JMPNC && !flags[`FLAGS_CARRY])));

    // register control
    assign pc_inc = (state == 1 || 
                    (state == 3 && !jmp_taken && instr != `INSTR_PUSH && instr != `INSTR_POP));
    assign pc_load = (state == 3 && jmp_taken);
    assign ir_load = (state == 1);
    assign ac_load = (state == 3 && 
                        (instr == `INSTR_LITA || instr == `INSTR_ADD || instr == `INSTR_SUB || instr == `INSTR_POP)) ||
                     (state == 4 && (instr == `INSTR_LOADA));
    assign ar_load = (state == 0 || 
                     (state == 2 && instr != `INSTR_NOP) || 
                     (state == 3 && (instr == `INSTR_STORA || instr == `INSTR_LOADA)));

    // ALU control
    assign alu_op = (state == 3 && instr == `INSTR_ADD) ? `OP_ADD : 
                    (state == 3 && (instr == `INSTR_SUB || instr == `INSTR_CMP)) ? `OP_SUB : `OP_PASS;
    assign flags_load = (alu_op != `OP_PASS);

    assign sp_chg = (state == 3 && instr == `INSTR_PUSH) ? `SP_DEC : 
                    (state == 2 && instr == `INSTR_POP)  ? `SP_INC : `SP_SAME;
    
    // remember, W/R will read WHEN LOW not when high...
    // and will allow you to read/write from mem in the current cycle
    assign R = (state == 1 || 
               (state == 2 && instr == `INSTR_LITA) ||
               (state == 3 && instr != `INSTR_PUSH) ||
               (state == 4 && instr == `INSTR_LOADA)) ? 0 : 1;
    assign W = ((state == 3 && instr == `INSTR_PUSH) || 
                (state == 4 && instr == `INSTR_STORA)) ? 0 : 1;

    assign addr_mux = (state == 2 && (instr == `INSTR_PUSH || instr == `INSTR_POP)) ? `ADDR_MUX_SP : 
                      (state == 3 && (instr == `INSTR_STORA || instr == `INSTR_LOADA)) ? `ADDR_MUX_BUS : `ADDR_MUX_PC;
                      
    assign bus_mux = ((state == 2 && instr == `INSTR_STOP) ||
                      (state == 3 && instr == `INSTR_PUSH) || 
                      (state == 4 && (instr == `INSTR_STORA))) ? `BUS_MUX_ACC : `BUS_MUX_MEM;

    assign clear = (state == 2 && instr == `INSTR_NOP) || 
                   (state == 3 && instr != `INSTR_STORA && instr != `INSTR_LOADA) || 
                   (state == 4 && (instr == `INSTR_STORA || instr == `INSTR_LOADA));

    assign set_stop = (state == 2 && instr == `INSTR_STOP);

    always @(negedge clk or posedge rst) begin
        if (clear || rst) begin
            state <= 0;
        end else begin
            state <= state + 1;
        end
    end
endmodule
