// adds 4 bit integers A and B, setting the carry flag and sum output.
module four_bit_ripple_adder(input [3:0] A, input [3:0] B, output carry_out, output [3:0] sum);
    wire [3:0] carry;

    assign carry[0] = 0;
    full_adder fa1(A[0], B[0], carry[0], carry[1], sum[0]);
    full_adder fa2(A[1], B[1], carry[1], carry[2], sum[1]);
    full_adder fa3(A[2], B[2], carry[2], carry[3], sum[2]);
    full_adder fa4(A[3], B[3], carry[3], carry_out, sum[3]);
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