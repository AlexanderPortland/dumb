
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
    output [7:0] data_out
);
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
    control c(ir, flags, clk, rst, R, W, pc_inc, pc_load, sp_chg, ac_load, ar_load, ir_load, alu_op, flags_load, addr_mux, bus_mux);

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
        end else begin
            // increment the pc or load a new value from the data bus
            if (pc_inc) begin 
                pc <= pc + 1;
            end else if (pc_load) begin
                pc <= data_bus;
            end

            case (sp_chg)
                // NOTE: the inc case here is intentionally non, blocking, to ensure that
                // it takes effect before taking its value for the addr register
                // TODO: is this hella jank? idk if this will work in real life.
                `SP_INC: sp = sp + 1;
                `SP_DEC: sp <= sp - 1;
                // don't do anything on SP_SAME
                // default: 
            endcase

            // fetch instruction from the data bus
            if (ir_load) ir <= data_bus;
            if (flags_load) flags <= alu_flags;
            if (ac_load) acc <= alu_out;

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
`define INSTR_LITA 8'hc0
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
    output [1:0] bus_mux   // where to take the data bus output from
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
                      
    assign bus_mux = ((state == 3 && instr == `INSTR_PUSH) || 
                      (state == 4 && (instr == `INSTR_STORA))) ? `BUS_MUX_ACC : `BUS_MUX_MEM;

    assign clear = (state == 2 && instr == `INSTR_NOP) || 
                   (state == 3 && instr != `INSTR_STORA && instr != `INSTR_LOADA) || 
                   (state == 4 && (instr == `INSTR_STORA || instr == `INSTR_LOADA));

    always @(negedge clk or posedge rst) begin
        if (clear || rst) begin
            state <= 0;
        end else begin
            state <= state + 1;
        end
    end
endmodule

// a little harness that emulates RAM for testing the CPU
// (initially vibecoded w/ claude, but now I'm expanding it to actually be useful)
module dCPU_tb;
    reg clk, rst;
    reg [7:0] mem_in;
    wire R, W;
    wire [7:0] addr, data_out;
    
    dCPU cpu(clk, rst, mem_in, R, W, addr, data_out);
    
    // clock emulation
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
            $display("Time=%0t-c%b state=%d pc=%h ir=%h, ar=%h acc=%d R=%b W=%b pc_inc=%b pc_l=%b ir_l=%b ar_l=%b ac_l=%b addr_m=%d, bus_m=%d sp=%d", 
                 $time, clk, cpu.c.state, cpu.pc, cpu.ir, addr, cpu.acc, R, W, cpu.pc_inc, cpu.pc_load, cpu.ir_load, cpu.ar_load, cpu.ac_load, cpu.addr_mux, cpu.bus_mux, cpu.sp);
        end
    end
    
    // simple memory model
    reg [7:0] memory [0:255];
    initial begin
        memory[0] = `INSTR_LITA;
        memory[1] = 8'd99;
        memory[2] = `INSTR_PUSH;
        memory[3] = `INSTR_ADD;
        memory[4] = 8'd5;
        memory[5] = `INSTR_LOADA;
        memory[6] = 8'd254;
        // memory[7] = `INSTR_ADD;
        // memory[8] = 8'd40;
        // memory[8] 
        // memory[9] 
        // memory[10]
        // memory[11]
        // memory[0] = `INSTR_LITA;  // Put some test instructions
        // memory[1] = 8'd208;
        // memory[2] = `INSTR_SUB;
        // memory[3] = 8'd16;
        // memory[4] = `INSTR_CMP;
        // memory[5] = 8'd65;
        // memory[6] = `INSTR_JMPNC;
        // memory[7] = 8'd10;
        // memory[8] = `INSTR_JMP;
        // memory[9] = 8'd2;
        // memory[10] = `INSTR_ADD;
        // memory[11] = 8'd100;
        // ... etc
    end
    
    // Read from memory when CPU requests
    always @(*) begin
        if (!R) begin  // R is active low
            mem_in = memory[addr];
            // $display("Time=%0t setting mem_in to %h", $time, mem_in);
        end else begin
            mem_in = 8'h00;
        end
    end

    // write to memory when the CPU requests
    always @(posedge clk) begin
        if (!W) begin
            memory[addr] <= data_out;
            $display("Time=%0t writing %h to memory[%h]", $time, data_out, addr);
        end
        if (!W && !R) begin
            $error("WARNING: trying to read and write from memory at the same time");
        end
    end
    
    // Test sequence
    initial begin
        $dumpfile("cpu_test.vcd");  // For waveform viewing
        $dumpvars(0, dCPU_tb);
        
        rst = 1;
        #1;
        rst = 0;
        
        #300;  // Run for a while
        
        $display("PC = %h, IR = %h, ACC = %h", cpu.pc, cpu.ir, cpu.acc);
        $finish;
    end
endmodule