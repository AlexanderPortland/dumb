/// TODO: right now, global variables won't work properly, because we're reading the whole
/// elf into ROM. instead, we should have a unified piece of memory with two underlying stores
/// and a selection between them. I should also modify `_start` to zero .bss and copy .data.

/// Reads in blocks of 4B
module ROM_block #(
    parameter SZ = 4096 // The number of 32-bit words to store
) (
    input clk,
    input [31:0] addr,
    output [31:0] data_out
);
    reg [31:0] data [0:(SZ-1)];

    assign data_out = data[addr >> 2];

    initial begin
        $readmemh("../programs/test.hex", data);
    end
endmodule

/// Reads and writes in blocks of 4B
module RAM_block #(
    parameter SZ = 8192
) (
    input clk,
    input w_en,
    input [31:0] addr,
    input [31:0] data_in,
    output [31:0] data_out
);
    reg [7:0] data [0:(SZ-1)];

    assign data_out[7:0] = data[addr];
    assign data_out[15:8] = data[addr + 1];
    assign data_out[23:16] = data[addr + 2];
    assign data_out[31:24] = data[addr + 3];

    integer i;
    initial begin
        for (i = 0; i < SZ; i = i + 1) begin
            data[i] = 8'hac;
        end
    end

    always @(posedge clk) begin
        if (w_en) begin
            $display("writing 0x%h to addr 0x%h", data_in, addr);
            if (addr > SZ) begin
                    $error("write OOB at addr 0x%h", addr);
                    $finish(1);
                end
            data[addr] <= data_in[7:0];
            data[addr + 1] <= data_in[15:8];
            data[addr + 2] <= data_in[23:16];
            data[addr + 3] <= data_in[31:24];
        end
    end
endmodule