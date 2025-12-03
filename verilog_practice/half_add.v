// adds A to B, setting the sum and carry flags
module half_adder(A, B, carry, sum);
    input A, B;
    output sum, carry;

    and and1(carry, A, B);
    xor xor1(sum, A, B);

endmodule

module multiplexer_tb;
    reg test_A, test_B;
    wire test_carry, test_sum;

    half_adder uut(.A(test_A), .B(test_B), .carry(test_carry), .sum(test_sum));

    initial begin
        $display("A B | C S");
        $display("-----------");
        
        test_A = 0; test_B = 0; #10;
        // Want res to be  0  0
        $display("%b %b | %b %b", test_A, test_B, test_carry, test_sum);

        test_A = 0; test_B = 1; #10;
        // Want res to be  0  1
        $display("%b %b | %b %b", test_A, test_B, test_carry, test_sum);

        test_A = 1; test_B = 0; #10;
        // Want res to be  0  1
        $display("%b %b | %b %b", test_A, test_B, test_carry, test_sum);

        test_A = 1; test_B = 1; #10;
        // Want res to be  1  0
        $display("%b %b | %b %b", test_A, test_B, test_carry, test_sum);
        
        $finish;
    end
endmodule