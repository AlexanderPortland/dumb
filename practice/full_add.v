// adds A to B with previous carry C, setting the sum and carry flags accordingly
module full_adder(A, B, C, carry, sum);
    input A, B, C;
    output sum, carry;

    wire a_and_b, a_xor_b;
    wire carry_w_c;
    wire only_one, all_three;

    // do my naive calculation for carrying
    and and1(a_and_b, A, B);
    xor xor1(a_xor_b, A, B);
    and and2(carry_w_c, C, a_xor_b);
    or or1(carry, a_and_b, carry_w_c);

    // do my naive calculation for sum
    xor xor2(only_one, a_xor_b, C);
    and and3(all_three, a_and_b, C);
    or or2(sum, only_one, all_three);
endmodule


module multiplexer_tb;
    reg test_A, test_B, test_C;
    wire test_carry, test_sum;

    full_adder uut(.A(test_A), .B(test_B), .C(test_C), .carry(test_carry), .sum(test_sum));

    task assert_eq;
        input given, expected;
        begin
            if (given != expected) begin
                $error("FAIL: expected %b, found %b", given, expected);
            end
        end
    endtask

    initial begin
        $display("A B C | C S");
        $display("-----------");
        
        test_A = 0; test_B = 0; test_C = 0; #10;
        // Want res to be  |  0  0
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 0); assert_eq(test_sum, 0);

        test_A = 0; test_B = 0; test_C = 1; #10;
        // Want res to be  |  0  1
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 0); assert_eq(test_sum, 1);

        test_A = 0; test_B = 1; test_C = 0; #10;
        // Want res to be  |  0  1
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 0); assert_eq(test_sum, 1);

        test_A = 0; test_B = 1; test_C = 1; #10;
        // Want res to be  |  1  0
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 1); assert_eq(test_sum, 0);

        test_A = 1; test_B = 0; test_C = 0; #10;
        // Want res to be  |  0  1
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 0); assert_eq(test_sum, 1);

        test_A = 1; test_B = 0; test_C = 1; #10;
        // Want res to be  |  1  0
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 1); assert_eq(test_sum, 0);

        test_A = 1; test_B = 1; test_C = 0; #10;
        // Want res to be  |  1  0
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 1); assert_eq(test_sum, 0);

        test_A = 1; test_B = 1; test_C = 1; #10;
        // Want res to be  |  1  1
        $display("%b %b %b | %b %b", test_A, test_B, test_C, test_carry, test_sum);
        assert_eq(test_carry, 1); assert_eq(test_sum, 1);

        $finish;
    end
endmodule