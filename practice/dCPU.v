
`define DATA_MUX_PC 2'd1
`define DATA_MUX_ACC 2'd2
`define DATA_MUX_MEM 2'd3

`define ADDR_MUX_PC 1'd0

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

    // registers for operating on data
    reg [7:0] acc;
    wire ac_load, ar_load;

    // wires for interfacing w/ the ALU
    wire [3:0] alu_op;
    wire [7:0] alu_out;
    dALU alu(acc, data_bus, alu_op, alu_out, /* TODO: add flags here... */);

    wire [1:0] data_mux;
    wire addr_mux;
    control c(ir, clk, rst, R, W, pc_inc, pc_load, ac_load, ar_load, ir_load, alu_op, addr_mux, data_mux);

    // assign based on control's mux output
    assign data_bus = (data_mux == `DATA_MUX_ACC) ? acc : 
                      (data_mux == `DATA_MUX_PC)  ? pc : 
                      (data_mux == `DATA_MUX_MEM) ? mem_in : 0;

    always @(posedge clk or posedge rst) begin
        // increment pc
        if (rst) begin
            pc <= 0;
            ir <= 0;
            acc <= 0;
            addr <= 0;
        end else begin
            if (pc_inc) begin 
                pc <= pc + 1;
            end else if (pc_load) begin
                pc <= data_bus;
            end

            // fetch instruction from the data bus
            if (ir_load) begin 
                ir <= data_bus;
                // $display("loaded %h off the data_bus %h for the instruction register data_mux is %d", ir, data_bus, data_mux);
            end

            // load the ALU result
            if (ac_load) acc <= alu_out;

            if (ar_load) begin
                case (addr_mux)
                    `ADDR_MUX_PC: addr = pc;
                    default: addr = 0;
                endcase
            end
        end
    end
endmodule

`define INSTR_LOADA 8'd1
`define INSTR_ADD 8'd2
`define INSTR_JMP 8'd3

module control(
    input [7:0] instr,
    input clk,
    input rst,
    output R, W,
    output pc_inc,
    output pc_load,
    output ac_load,
    output ar_load,
    output ir_load,
    output [3:0] alu_op,
    output addr_mux,      // where to take the address output from
    output [1:0] data_mux // where to take the data bus output from
);
    reg [2:0] state;
    wire clear;

    // TODO: would love some way to detect and stop on an unsupported opcode.

    // inc if state is 1 or 3
    assign pc_inc = (state == 1 || (state == 3 && instr != `INSTR_JMP)) ? 1 : 0;
    assign pc_load = (state == 3 && instr == `INSTR_JMP);
    assign ir_load = (state == 1);
    assign ac_load = (state == 3 && instr != `INSTR_JMP);
    assign ar_load = (state == 0 || state == 2) ? 1 : 0;

    assign alu_op = (instr == `INSTR_ADD && state == 3) ? `OP_ADD : `OP_PASS;
    
    // remember, W/R will read WHEN LOW not when high...
    // and will allow you to read/write from mem in the current cycle
    assign R = (state == 1 || state == 3) ? 0 : 1;
    assign W = 1;

    assign addr_mux = `ADDR_MUX_PC;
    assign data_mux = `DATA_MUX_MEM;

    assign clear = (state == 3);

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
            $display("Time=%0t clk=%b state=%d pc=%h ir=%h, ar=%h acc=%d R=%b W=%b pc_inc=%b pc_load=%b ir_load=%b ar_load=%b ac_load=%b data_mux=%d alu_op=%d", 
                 $time, clk, cpu.c.state, cpu.pc, cpu.ir, addr, cpu.acc, R, W, cpu.pc_inc, cpu.pc_load, cpu.ir_load, cpu.ar_load, cpu.ac_load, cpu.data_mux, cpu.alu_op);
        end
    end
    
    // Simple memory model
    reg [7:0] memory [0:255];
    initial begin
        memory[0] = `INSTR_LOADA;  // Put some test instructions
        memory[1] = 8'd1;
        memory[2] = `INSTR_ADD;
        memory[3] = 8'd200;
        memory[4] = `INSTR_JMP;
        memory[5] = 8'd8;
        memory[6] = 8'd200;
        memory[7] = 8'd7;
        memory[8] = `INSTR_ADD;
        memory[9] = 8'd10;
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
    
    // Test sequence
    initial begin
        $dumpfile("cpu_test.vcd");  // For waveform viewing
        $dumpvars(0, dCPU_tb);
        
        rst = 1;
        #1;
        rst = 0;
        
        #200;  // Run for a while
        
        $display("PC = %h, IR = %h, ACC = %h", cpu.pc, cpu.ir, cpu.acc);
        $finish;
    end
endmodule