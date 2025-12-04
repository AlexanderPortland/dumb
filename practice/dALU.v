// a stab at an 8-bit ALU
module dALU(
    input [7:0] A, B, 
    input [1:0] op,
    output [7:0] out, 
    output zero
    // output negative,
    // output overflow, 
    // output carry // TODO: is carry not the same as overflow?
);
    // do all the calculations
    wire [7:0] or_res, and_res, add_res;
    byte_bitwise_or or1(A, B, or_res);
    byte_bitwise_and and1(A, B, and_res);
    byte_ripple_adder add1(A, B, carry, add_res);
    
    // multiplex them all into the output together
    wire [7:0] null_or, and_add;
    byte_multiplexer bm1(8'b0, or_res, op[0], null_or);
    byte_multiplexer bm2(and_res, add_res, op[0], and_add);
    byte_multiplexer bm3(null_or, and_add, op[1], out);

    // check if the output is zero
    wire any_bit_set;
    byte_any_bit_set bs(out, any_bit_set);
    not n(zero, any_bit_set);
endmodule

// OPS:
// 0. [RESERVED]
// 1. or
// 2. and
// 3. add

// TODO: ops 
// - [ ] shift
// - [ ] 

module dALU_tb;
    reg [7:0] test_A, test_B;
    reg [1:0] test_op;
    wire [7:0] test_out;
    wire test_zero;

    dALU alu(.A(test_A), .B(test_B), .op(test_op), .out(test_out), .zero(test_zero));

    task assert_byte_eq;
        input [7:0] given, expected;
        begin
            if (given != expected) begin
                $error("FAIL: expected byte %b, found byte %b", given, expected);
            end
        end
    endtask

    task assert_bit_eq;
        input given, expected;
        begin
            if (given != expected) begin
                $error("FAIL: expected bit %b, found bit %b", given, expected);
            end
        end
    endtask

    initial begin
        assign test_op = 1; // or op code
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0011); assert_bit_eq(test_zero, 0);

        assign test_op = 2; // and op code
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0010); assert_bit_eq(test_zero, 0);

        assign test_op = 3; // or op code
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0101); assert_bit_eq(test_zero, 0);

        assign test_op = 2; // and op code
        assign test_A = 8'b010; assign test_B = 8'b101; #10;
        assert_byte_eq(test_out, 8'b0000); assert_bit_eq(test_zero, 1);

        $display("[dALU]\t\t\t All tests passed!!");
    end
endmodule