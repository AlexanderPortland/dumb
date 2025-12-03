// selects from A or B based on X, sending that to out
module gate_multiplexer(A, B, X, out);
    input A, B, X;
    output out;

    wire not_x, a_out, b_out;

    not not1(not_x, X);
    and and1(a_out, A, not_x);
    and and2(b_out, B, X);
    or or1(out, a_out, b_out);

endmodule

// print the output from the multiplexer
module multiplexer_tb;
    reg test_A, test_B, test_X;
    wire test_out;

    gate_multiplexer uut(.A(test_A), .B(test_B), .X(test_X), .out(test_out));

    initial begin
        $display("A B X | out");
        $display("-----------");
        
        test_A = 0; test_B = 0; test_X = 0; #10;
        $display("%b %b %b | %b", test_A, test_B, test_X, test_out);

        test_A = 1; test_B = 0; test_X = 0; #10;
        $display("%b %b %b | %b", test_A, test_B, test_X, test_out);

        test_A = 0; test_B = 1; test_X = 0; #10;
        $display("%b %b %b | %b", test_A, test_B, test_X, test_out);

        test_A = 0; test_B = 0; test_X = 1; #10;
        $display("%b %b %b | %b", test_A, test_B, test_X, test_out);

        test_A = 1; test_B = 0; test_X = 1; #10;
        $display("%b %b %b | %b", test_A, test_B, test_X, test_out);

        test_A = 0; test_B = 1; test_X = 1; #10;
        $display("%b %b %b | %b", test_A, test_B, test_X, test_out);
        
        $finish;
    end
endmodule