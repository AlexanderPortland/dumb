// selects from A or B based on X, sending that to out
module bit_multiplexer(input A, input B, input X, output out);

    wire not_x, a_out, b_out;

    not not1(not_x, X);
    and and1(a_out, A, not_x);
    and and2(b_out, B, X);
    or or1(out, a_out, b_out);

endmodule

// selects from A or B based on X, sending that to out
module byte_multiplexer(input [7:0] A, B, input X, output [7:0] out);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            bit_multiplexer b(A[i], B[i], X, out[i]);
        end
    endgenerate
endmodule

// print the output from the multiplexer
module multiplexer_tb;
    reg test_A, test_B, test_X;
    wire test_out;

    bit_multiplexer uut(.A(test_A), .B(test_B), .X(test_X), .out(test_out));

    task assert_eq;
        input given, expected;
        begin
            if (given != expected) begin
                $error("FAIL: expected %b, found %b", given, expected);
            end
        end
    endtask

    initial begin
        test_A = 0; test_B = 0; test_X = 0; #10;
        // $display("%b %b %b | %b", test_A, test_B, test_X, test_out);
        assert_eq(test_out, 0);

        test_A = 1; test_B = 0; test_X = 0; #10;
        // $display("%b %b %b | %b", test_A, test_B, test_X, test_out);
        assert_eq(test_out, 1);

        test_A = 0; test_B = 1; test_X = 0; #10;
        // $display("%b %b %b | %b", test_A, test_B, test_X, test_out);
        assert_eq(test_out, 0);

        test_A = 0; test_B = 0; test_X = 1; #10;
        // $display("%b %b %b | %b", test_A, test_B, test_X, test_out);
        assert_eq(test_out, 0);

        test_A = 1; test_B = 0; test_X = 1; #10;
        // $display("%b %b %b | %b", test_A, test_B, test_X, test_out);
        assert_eq(test_out, 0);

        test_A = 0; test_B = 1; test_X = 1; #10;
        // $display("%b %b %b | %b", test_A, test_B, test_X, test_out);
        assert_eq(test_out, 1);
        
        $display("[bit_multiplexer]\t All tests passed!!");
    end
endmodule