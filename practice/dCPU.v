
`define BUS_MUX_PC 2'd1
`define BUS_MUX_ACC 2'd2
`define BUS_MUX_MEM 2'd3

`define ADDR_MUX_PC  1'd0
`define ADDR_MUX_BUS 1'd1

// trying to make a very simple CPU
module dCPU(
    input clk,
    input rst,
    input [7:0] mem_in,
    output R, W,
    output reg [7:0] addr,
    output [7:0] data_out
);
    wire [7:0] data_bus;
    assign data_out = data_bus;

    // store the current program counter and intruction register.
    reg [7:0] pc, ir;
    wire pc_inc, pc_load, ir_load;

    reg [3:0] flags;
    wire flags_load;

    // registers for operating on data
    reg [7:0] acc;
    wire ac_load, ar_load;

    // wires for interfacing w/ the ALU
    wire [3:0] alu_op;
    wire [7:0] alu_out; wire [3:0] alu_flags;
    dALU alu(acc, data_bus, alu_op, alu_out, alu_flags);

    wire [1:0] bus_mux;
    wire addr_mux;
    control c(ir, flags, clk, rst, R, W, pc_inc, pc_load, ac_load, ar_load, ir_load, alu_op, flags_load, addr_mux, bus_mux);

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
        end else begin
            // increment the pc or load a new value from the data bus
            if (pc_inc) begin 
                pc <= pc + 1;
            end else if (pc_load) begin
                pc <= data_bus;
            end

            // fetch instruction from the data bus
            if (ir_load) ir <= data_bus;
            if (flags_load) flags <= alu_flags;
            if (ac_load) acc <= alu_out;

            if (ar_load) begin
                case (addr_mux)
                    `ADDR_MUX_PC: addr = pc;
                    `ADDR_MUX_BUS: addr = data_bus;
                    default: addr = 0;
                endcase
            end
        end
    end
endmodule

`define INSTR_LOADA 8'hc1
`define INSTR_STORA 8'hc2
`define INSTR_ADD   8'hc3
`define INSTR_JMP   8'hc4
`define INSTR_JMPZ  8'hc5
`define INSTR_JMPC  8'hc6 // TODO: I think i messed up the order, so this is set if acc > M
`define INSTR_SUB   8'hc7
`define INSTR_CMP   8'hc8
`define INSTR_JMPNC 8'hc9 // and this is acc <= M

module control(
    input [7:0] instr,
    input [3:0] flags,
    input clk,
    input rst,
    output R, W,
    output pc_inc,
    output pc_load,
    output ac_load,
    output ar_load,
    output ir_load,
    output [3:0] alu_op,
    output flags_load,
    output addr_mux,      // where to take the address output from
    output [1:0] bus_mux // where to take the data bus output from
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

    // inc if state is 1 or 3
    assign pc_inc = (state == 1 || (state == 3 && !jmp_taken));
    assign pc_load = (state == 3 && jmp_taken);
    assign ir_load = (state == 1);
    assign ac_load = (state == 3 && 
                        (instr == `INSTR_LOADA || instr == `INSTR_ADD || instr == `INSTR_SUB));
    assign ar_load = (state == 0 || state == 2 || (state == 3 && instr == `INSTR_STORA));

    assign alu_op = (state == 3 && instr == `INSTR_ADD) ? `OP_ADD : 
                    (state == 3 && (instr == `INSTR_SUB || instr == `INSTR_CMP)) ? `OP_SUB : `OP_PASS;
    assign flags_load = (alu_op != `OP_PASS);
    
    // remember, W/R will read WHEN LOW not when high...
    // and will allow you to read/write from mem in the current cycle
    assign R = (state == 1 || state == 3) ? 0 : 1;
    assign W = (state == 4 && instr == `INSTR_STORA) ? 0 : 1;

    assign addr_mux = (state == 3 && instr == `INSTR_STORA) ? `ADDR_MUX_BUS : `ADDR_MUX_PC;
    assign bus_mux = (state == 4 && instr == `INSTR_STORA) ? `BUS_MUX_ACC : `BUS_MUX_MEM;

    assign clear = (state == 3 && instr != `INSTR_STORA) || (state == 4 && instr == `INSTR_STORA);

    always @(negedge clk or posedge rst) begin
        if (clear || rst) begin
            state <= 0;
        end else begin
            state <= state + 1;
        end
    end
endmodule

module dCPU_tb;
    reg clk, rst;
    reg [7:0] mem_in;
    wire R, W;
    wire [7:0] addr, data_out;
    
    // Instantiate your CPU
    dCPU cpu(clk, rst, mem_in, R, W, addr, data_out);
    
    // Clock generation
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
            $display("Time=%0t clk=%b state=%d pc=%h ir=%h, ar=%h acc=%d R=%b W=%b pc_inc=%b pc_load=%b ir_load=%b ar_load=%b ac_load=%b alu_op=%d flags=%b", 
                 $time, clk, cpu.c.state, cpu.pc, cpu.ir, addr, cpu.acc, R, W, cpu.pc_inc, cpu.pc_load, cpu.ir_load, cpu.ar_load, cpu.ac_load, cpu.alu_op, cpu.flags);
        end
    end
    
    // Simple memory model
    reg [7:0] memory [0:255];
    initial begin
        memory[0] = `INSTR_LOADA;
        memory[1] = 8'd10;
        memory[2] = `INSTR_STORA;
        memory[3] = 8'd7;
        memory[4] = `INSTR_LOADA;
        memory[5] = 8'd30;
        memory[6] = `INSTR_LOADA;
        memory[7] = 8'd40;
        // memory[8] 
        // memory[9] 
        // memory[10]
        // memory[11]
        // memory[0] = `INSTR_LOADA;  // Put some test instructions
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
        if (!W) begin
            memory[addr] = data_out;
        end
    end

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
        
        #320;  // Run for a while
        
        $display("PC = %h, IR = %h, ACC = %h", cpu.pc, cpu.ir, cpu.acc);
        $finish;
    end
endmodule