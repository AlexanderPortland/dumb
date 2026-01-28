`timescale 1ns/1ps

module tb_riscv_cpu;
    reg clk;
    reg rst;

    // Instantiate the CPU
    CPU dut (
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
        if (dut.stage == 0 || $test$plusargs("v")) begin
            $display("================================================================================================");
            $display("Time: %0t ns | Stage: %s", $time,
                    dut.stage == 0 ? "IF " :
                    dut.stage == 1 ? "ID " :
                    dut.stage == 2 ? "EX " :
                    dut.stage == 3 ? "MEM" :
                    dut.stage == 4 ? "WB " : "???");
            $display("  PC: %h | IR: %h | next_pc: %h", dut.pc, dut.ir, dut.next_pc);
            if ($test$plusargs("v")) begin
                $display("  IR Decode -> opcode: %b | funct3: %b | funct7: %b", dut.ir_op, dut.ir_f3, dut.ir_f7);
                $display("             -> rs1: %0d | rs2: %0d | rd: %0d | imm: %h (%0d) | irj: %b | irb: %b", 
                        dut.ir_rs1, dut.ir_rs2, dut.ir_rd, dut.ir_imm, $signed(dut.ir_imm), dut.ir_imm_j, dut.ir_imm_b);
                $display("  Pipeline -> A: %h | B: %h | Imm: %h", dut.A, dut.B, dut.Imm);
                $display("           -> ALU: %h | LMD: %h | mem_out: %h", dut.ALUOutput, dut.LMD, dut.data_mem_out);
                $display("  Write Enables -> reg_w_en: %b | mem_w_en: %b", dut.reg_w_en, dut.mem_w_en);
            end
            $display("  Registers:");
            $display("    x0(zero):%h  x1(ra):%h  x2(sp ):%h  x3(gp ):%h  x4(tp):%h  x5(t0):%h",
                    dut.regs.regs[0],  dut.regs.regs[1],  dut.regs.regs[2],  
                    dut.regs.regs[3],  dut.regs.regs[4],  dut.regs.regs[5]);
            $display("    x6( t1 ):%h  x7(t2):%h  x8(s0 ):%h  x9(s1 ):%h x10(a0):%h x11(a1):%h",
                    dut.regs.regs[6],  dut.regs.regs[7],  dut.regs.regs[8],  
                    dut.regs.regs[9],  dut.regs.regs[10], dut.regs.regs[11]);
            $display("   x12( a2 ):%h x13(a3):%h x14(a4 ):%h x15(a5 ):%h x16(a6):%h x17(a7):%h",
                    dut.regs.regs[12], dut.regs.regs[13], dut.regs.regs[14], 
                    dut.regs.regs[15], dut.regs.regs[16], dut.regs.regs[17]);
            $display("   x18( s2 ):%h x19(s3):%h x20(s4 ):%h x21(s5 ):%h x22(s6):%h x23(s7):%h",
                    dut.regs.regs[18], dut.regs.regs[19], dut.regs.regs[20], 
                    dut.regs.regs[21], dut.regs.regs[22], dut.regs.regs[23]);
            $display("   x24( s8 ):%h x25(s9):%h x26(s10):%h x27(s11):%h x28(t3):%h x29(t4):%h",
                    dut.regs.regs[24], dut.regs.regs[25], dut.regs.regs[26], 
                    dut.regs.regs[27], dut.regs.regs[28], dut.regs.regs[29]);
            $display("   x30( t5 ):%h x31(t6):%h",
                    dut.regs.regs[30], dut.regs.regs[31]);
            $display("");
        end
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
        #30000;

        $display("\n=== Test Complete ===");
        $finish;
    end

endmodule