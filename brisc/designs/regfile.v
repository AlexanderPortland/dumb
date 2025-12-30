
// A register file w/ 32 32-bit registers, two read ports and a write port.
module reg_file (
    input clk,
    input rst,
    
    // Write port
    input w_en,
    input [4:0] write_rg,
    input [31:0] write_data,

    // Read port 1
    input [4:0] read1_rg,
    output [31:0] read1,

    // Read port 2
    input [4:0] read2_rg,
    output [31:0] read2
);
    // TODO: i think can use the built-in reg file on the FPGA eventually?
    // skip x0 because it's not writable and always returns zero.
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
            // $display("writing into reg %d", write_rg);
            if (write_rg != 0 && w_en) begin
                regs[write_rg] <= write_data;
            end
        end
    end
endmodule