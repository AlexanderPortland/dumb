
// A register file w/ 32 32-bit registers, two read ports and a write port.
module reg_file (
    input clk,
    input rst,
    // Write port
    input [4:0] write_rg,
    input [31:0] write_data,

    // Read port 1
    input [4:0] read1_rg,
    output [31:0] read1,

    // Read port 2
    input [4:0] read2_rg,
    output [31:0] read2
);
    // TODO: i think can use the built-in reg file on the FPGA eventually
    reg [31:0] regs [1:31];

    assign read1 = (read1_rg == 0) ? 32'b0 : regs[read1_rg];
    assign read2 = (read2_rg == 0) ? 32'b0 : regs[read2_rg];

    integer i;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset all registers to zero
            for (i = 1; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else begin
            // Otherwise, write into the specified register
            if (write_rg != 0) begin
                regs[write_rg] <= write_data;
            end
        end
    end
endmodule

// module regfile_tb;
//     reg clk, rst;
//     reg [4:0] read1_rg, read2_rg;
//     wire [31:0] read1, read2;
    
//     reg [4:0] write_rg;
//     reg [31:0] write_data;

//     reg_file regs(clk, rst, write_rg, write_data, read1_rg, read1, read2_rg, read2);

//     initial begin
//         write_rg = 0;
//         clk <= 0;
//         rst <= 1;
//         #1;
//         rst <= 0;
//         #1;
//         rst <= 1;
//         forever begin
//             #1
//             clk = ~clk;
//         end
//     end

//     always @(posedge clk or negedge clk) begin
//         $strobe("t=%0t clk=%b rst=%b wr%d:%h r1=%d:%h r2=%d:%h | x1=%h x2=%h x3=%h", 
//             $time, clk, rst, write_rg, write_data, read1_rg, read1, read2_rg, read2,
//             regs.regs[1], regs.regs[2], regs.regs[3]);
//     end

//     initial begin
//         #10;
//         read1_rg = 1;
//         read2_rg = 2;
//         #1;
//         write_rg = 1;
//         write_data = 32'hdeadbeef;
//         #4;
//         write_rg = 3;
//         write_data = 32'hfeedfeed;
//         read2_rg = 3;
//         #4;
//         $finish();
//     end
// endmodule