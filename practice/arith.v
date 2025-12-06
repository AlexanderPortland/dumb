// adds 4 bit integers A and B, setting the carry flag and sum output.
module four_bit_ripple_adder(input [3:0] A, input [3:0] B, output carry_out, output [3:0] sum);
    wire [4:0] carry;

    assign carry[0] = 0;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            full_adder fa1(A[i], B[i], carry[i], carry[i + 1], sum[i]);
        end
    endgenerate

    assign carry_out = carry[4];
endmodule

module byte_ripple_add_sub(
    input [7:0] A, input [7:0] B, input sub, 
    output carry_out, output [7:0] sum
);
    wire [8:0] carry;
    wire [8:0] B_in;

    assign carry[0] = sub;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            xor(B_in[i], B[i], sub);
            full_adder fa1(A[i], B_in[i], carry[i], carry[i + 1], sum[i]);
        end
    endgenerate

    assign carry_out = carry[8];
endmodule

module four_bit_ripple_adder_tb;
    reg [3:0] test_A, test_B;
    wire [3:0] test_sum;
    wire test_carry;

    four_bit_ripple_adder uut(.A(test_A), .B(test_B), .carry_out(test_carry), .sum(test_sum));

    task assert_eq;
        input [3:0] given, expected;
        begin
            if (given != expected) begin
                $error("FAIL: expected %b, found %b", given, expected);
            end
        end
    endtask

    initial begin
        assign test_A = 4'b0000; assign test_B = 4'b0000; #10;
        assert_eq(test_sum, 4'b0000); assert_eq(test_carry, 0);

        assign test_A = 4'b0001; assign test_B = 4'b0000; #10;
        assert_eq(test_sum, 4'b0001); assert_eq(test_carry, 0);

        assign test_A = 4'b0001; assign test_B = 4'b0001; #10;
        assert_eq(test_sum, 4'b0010); assert_eq(test_carry, 0);

        assign test_A = 4'b0101; assign test_B = 4'b1010; #10;
        assert_eq(test_sum, 4'b1111); assert_eq(test_carry, 0);

        assign test_A = 4'b0101; assign test_B = 4'b0101; #10;
        assert_eq(test_sum, 4'b1010); assert_eq(test_carry, 0);

        assign test_A = 4'b1101; assign test_B = 4'b1010; #10;
        assert_eq(test_sum, 4'b0111); assert_eq(test_carry, 1);

        assign test_A = 4'b1111; assign test_B = 4'b0001; #10;
        assert_eq(test_sum, 4'b0000); assert_eq(test_carry, 1);

        assign test_A = 4'b1111; assign test_B = 4'b1111; #10;
        assert_eq(test_sum, 4'b1110); assert_eq(test_carry, 1);

        assign test_A = 3; assign test_B = 4; #10;
        assert_eq(test_sum, 7); assert_eq(test_carry, 0);

        $display("[four_bit_ripple_adder]\t All tests passed!!");
    end
endmodule

module byte_ripple_adder_tb;
    reg [7:0] test_A, test_B;
    wire [7:0] test_sum;
    wire test_carry;
    reg test_sub;

    byte_ripple_add_sub uut(.A(test_A), .B(test_B), .sub(test_sub), .carry_out(test_carry), .sum(test_sum));

    task assert_eq;
        input [7:0] given, expected;
        begin
            if (given != expected) begin
                $error("FAIL: expected %b, found %b", given, expected);
            end
        end
    endtask

    initial begin
        assign test_sub = 0;
        assign test_A = 245; assign test_B = 3; #10;
        assert_eq(test_sum, 248); assert_eq(test_carry, 0);

        assign test_A = 255; assign test_B = 1; #10;
        assert_eq(test_sum, 0); assert_eq(test_carry, 1);

        assign test_A = 15; assign test_B = 33; #10;
        assert_eq(test_sum, 48); assert_eq(test_carry, 0);

        assign test_A = 15; assign test_B = 33; #10;
        assert_eq(test_sum, 48); assert_eq(test_carry, 0);

        $display("[byte_ripple_add_sub]\t All tests passed!!");
    end
endmodule