/// Reads in blocks of 4B
module ROM_block #(
    parameter SZ = 4096
) (
    input clk,
    input [31:0] addr,
    output [31:0] data_out
);
    reg [7:0] data [0:(SZ-1)];

    assign data_out = {data[addr + 3], data[addr + 2], data[addr + 1], data[addr]};

    initial begin
        write_instr(0, 32'h00500093);   // addi x1, x0, 5
        write_instr(4, 32'h01008113);   // addi x2, x1, 16
        write_instr(8, 32'h401101b3);   // sub x3, x2, x1
    end

    task write_instr;
        input [31:0] addr;
        input [31:0] instr;
        begin
            data[addr]   = instr[7:0];
            data[addr+1] = instr[15:8];
            data[addr+2] = instr[23:16];
            data[addr+3] = instr[31:24];
        end
    endtask
endmodule

/// Reads and writes in blocks of 4B
module RAM_block #(
    parameter SZ = 4096
) (
    input clk,
    input w_en,
    input [31:0] addr,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [7:0] data [0:(SZ-1)];

    always @(posedge clk) begin
        if (w_en) begin
            data[addr] <= data_in[7:0];
            data[addr + 1] <= data_in[15:8];
            data[addr + 2] <= data_in[23:16];
            data[addr + 3] <= data_in[31:24];
        end
        
        // TODO: could make this synchronous too
        data_out <= {data[addr + 3], data[addr + 2], data[addr + 1], data[addr]};
    end
endmodule