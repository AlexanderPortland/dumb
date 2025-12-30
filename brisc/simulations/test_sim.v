`timescale 1ns/1ps

module tb_riscv_cpu;
    reg clk;
    reg rst;

    // Instantiate the CPU
    moduleName dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation - 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Monitor CPU internal registers on every clock edge
    always @(posedge clk) begin
        $display("================================================================================================");
    $display("Time: %0t ns | Stage: %s", $time,
             dut.stage == 0 ? "IF " :
             dut.stage == 1 ? "ID " :
             dut.stage == 2 ? "EX " :
             dut.stage == 3 ? "MEM" :
             dut.stage == 4 ? "WB " : "???");
    $display("  PC: %h | IR: %h | next_pc: %h", dut.pc, dut.ir, dut.next_pc);
    $display("  IR Decode -> opcode: %b | funct3: %b | funct7: %b", dut.ir_op, dut.ir_f3, dut.ir_f7);
    $display("             -> rs1: %0d | rs2: %0d | rd: %0d | imm: %h (%0d)", 
             dut.ir_rs1, dut.ir_rs2, dut.ir_rd, dut.ir_imm, $signed(dut.ir_imm));
    $display("  Pipeline -> A: %h | B: %h | Imm: %h", dut.A, dut.B, dut.Imm);
    $display("           -> ALU: %h | LMD: %h", dut.ALUOutput, dut.LMD);
    $display("  Write Enables -> reg_w_en: %b | mem_w_en: %b", dut.reg_w_en, dut.mem_w_en);
    $display("  Registers -> x1:%h x2:%h x3:%h x4:%h x5:%h",
             dut.regs.regs[1], dut.regs.regs[2], dut.regs.regs[3], 
             dut.regs.regs[4], dut.regs.regs[5]);
    $display("");
    end

    // Test sequence
    initial begin
        $dumpfile("riscv_cpu.vcd");
        $dumpvars(0, tb_riscv_cpu);

        // Reset
        rst = 1;
        #10;
        rst = 0;
        #15;
        rst = 1;

        // Run for a bit
        #300;

        $display("\n=== Test Complete ===");
        $finish;
    end

endmodule