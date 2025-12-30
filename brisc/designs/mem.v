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
        write_instr(0,  32'h01000093);   // addi x1, x0, 16
        write_instr(4,  32'h07b00113);   // addi x2, x0, 123
        write_instr(8,  32'h0020a023);   // sw x2, 0(x1)
        write_instr(12, 32'h00800193);   // addi x3, x0, 8
        write_instr(16, 32'h403080b3);   // sub x1, x1, x3
        write_instr(20, 32'h0080b283);   // ld x5, 8(x1)
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
    output [31:0] data_out
);
    reg [7:0] data [0:(SZ-1)];

    assign data_out[7:0] = data[addr];
    assign data_out[15:8] = data[addr + 1];
    assign data_out[23:16] = data[addr + 2];
    assign data_out[31:24] = data[addr + 3];

    always @(posedge clk) begin
        if (w_en) begin
            $display("writing to addr 0x%h", addr);
            data[addr] <= data_in[7:0];
            data[addr + 1] <= data_in[15:8];
            data[addr + 2] <= data_in[23:16];
            data[addr + 3] <= data_in[31:24];
        end
    end
endmodule