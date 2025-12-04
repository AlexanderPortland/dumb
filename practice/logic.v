// selects from A or B based on X, sending that to out
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