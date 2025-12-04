// adds 4 bit integers A and B, setting the carry flag and sum output.
module four_bit_ripple_adder(input [3:0] A, input [3:0] B, output carry_out, output [3:0] sum);
    wire [3:0] carry;

    assign carry[0] = 0;
    full_adder fa1(A[0], B[0], carry[0], carry[1], sum[0]);
    full_adder fa2(A[1], B[1], carry[1], carry[2], sum[1]);
    full_adder fa3(A[2], B[2], carry[2], carry[3], sum[2]);
    full_adder fa4(A[3], B[3], carry[3], carry_out, sum[3]);
endmodule

module byte_ripple_adder(input [7:0] A, input [7:0] B, output carry_out, output [7:0] sum);
    wire [7:0] carry;

    // TODO: there must be a better way to write this...
    assign carry[0] = 0;
    full_adder fa1(A[0], B[0], carry[0], carry[1], sum[0]);
    full_adder fa2(A[1], B[1], carry[1], carry[2], sum[1]);
    full_adder fa3(A[2], B[2], carry[2], carry[3], sum[2]);
    full_adder fa4(A[3], B[3], carry[3], carry[4], sum[3]);
    full_adder fa5(A[4], B[4], carry[4], carry[5], sum[4]);
    full_adder fa6(A[5], B[5], carry[5], carry[6], sum[5]);
    full_adder fa7(A[6], B[6], carry[6], carry[7], sum[6]);
    full_adder fa8(A[7], B[7], carry[7], carry_out, sum[7]);
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

        // print out math for debugging
        // $display("a   is %b", test_A); $display("b   is %b", test_B); 
        // $display("       ----");
        // $display("out is %b (carry %b)", test_sum, test_carry);

        $display("[four_bit_ripple_adder]\t All tests passed!!");
    end
endmodule

module byte_ripple_adder_tb;
    reg [7:0] test_A, test_B;
    wire [7:0] test_sum;
    wire test_carry;

    byte_ripple_adder uut(.A(test_A), .B(test_B), .carry_out(test_carry), .sum(test_sum));

    task assert_eq;
        input [7:0] given, expected;
        begin
            if (given != expected) begin
                $error("FAIL: expected %b, found %b", given, expected);
            end
        end
    endtask

    initial begin
        assign test_A = 245; assign test_B = 3; #10;
        assert_eq(test_sum, 248); assert_eq(test_carry, 0);

        assign test_A = 255; assign test_B = 1; #10;
        assert_eq(test_sum, 0); assert_eq(test_carry, 1);

        assign test_A = 15; assign test_B = 33; #10;
        assert_eq(test_sum, 48); assert_eq(test_carry, 0);

        assign test_A = 15; assign test_B = 33; #10;
        assert_eq(test_sum, 48); assert_eq(test_carry, 0);

        $display("[byte_ripple_adder]\t All tests passed!!");
    end
endmodule