
module byte_bitwise_and(input [7:0] A, B, output [7:0] out);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            and a(out[i], A[i], B[i]);
        end
    endgenerate
endmodule

module byte_bitwise_or(input [7:0] A, B, output [7:0] out);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            or o(out[i], A[i], B[i]);
        end
    endgenerate
endmodule

module byte_bitwise_not(input [7:0] A, output [7:0] out);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            not n(out[i], A[i]);
        end
    endgenerate
endmodule

module byte_bitwise_xor(input [7:0] A, B, output [7:0] out);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            xor x(out[i], A[i], B[i]);
        end
    endgenerate
endmodule

module byte_any_bit_set(input [7:0] A, output out);
    wire [8:0] temp;

    assign temp[0] = 0;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            or o(temp[i + 1], A[i], temp[i]);
        end
    endgenerate

    assign out = temp[8];
endmodule

module byte_logical_left_shift(input [7:0] A, output carry, output [7:0] out);
    wire zero;

    assign out[0] = 0;

    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin
            assign out[i] = A[i - 1];
        end
    endgenerate

    // assign the last bit to carry
    assign carry = A[7];
endmodule