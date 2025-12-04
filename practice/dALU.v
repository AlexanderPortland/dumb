`define OP_OR  4'd1
`define OP_AND 4'd2
`define OP_XOR 4'd3
`define OP_NOT 4'd4
`define OP_ADD 4'd5
`define OP_SHL 4'd6



// a stab at an 8-bit ALU
module dALU(
    input [7:0] A, B, 
    input [3:0] op,
    output reg [7:0] out, 
    output zero
    // output negative,
    // output overflow,
    // output carry // TODO: is carry not the same as overflow?
);
    // do all the calculations
    wire [7:0] or_res, and_res, not_res, xor_res;
    byte_bitwise_or or1(A, B, or_res);
    byte_bitwise_and and1(A, B, and_res);
    byte_bitwise_not not1(A, not_res);
    byte_bitwise_xor xor1(A, B, xor_res);
    
    wire [7:0] add_res;
    byte_ripple_adder add1(A, B, carry, add_res);

    // multiplex them all into the output together
    always @(*) begin
        case (op)
            `OP_OR: out = or_res;
            `OP_AND: out = and_res;
            `OP_XOR: out = xor_res;
            `OP_NOT: out = not_res;
            `OP_ADD: out = add_res;
            `OP_SHL: out = A << 1; // TODO: try from logic gates
            default: $error("IE: unknown op code %d", op);
        endcase
    end

    // check if the output is zero
    wire any_bit_set;
    byte_any_bit_set bs(out, any_bit_set);
    not n(zero, any_bit_set);
endmodule

// TODO: ops 
// - [ ] shift (from gates)
// - [ ] shr
// - [ ] more tests

module dALU_tb;
    reg [7:0] test_A, test_B;
    reg [3:0] test_op;
    wire [7:0] test_out;
    wire test_zero;

    dALU alu(.A(test_A), .B(test_B), .op(test_op), .out(test_out), .zero(test_zero));

    task assert_byte_eq;
        input [7:0] given, expected;
        input [8*50:1] label;
        begin
            if (given != expected) begin
                $error("FAIL: expected bit %b, found bit %b \t (%0s)", expected, given, label);
            end
        end
    endtask

    task assert_bit_eq;
        input given, expected;
        input [8*50:1] label;
        begin
            if (given != expected) begin
                $error("FAIL: expected bit %b, found bit %b \t (%0s)", expected, given, label);
            end
        end
    endtask

    initial begin
        assign test_op = `OP_OR; // or op code
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0011, "simple or"); 
        assert_bit_eq(test_zero, 0, "or non-zero");

        assign test_op = `OP_AND; // and op code
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0010, "simple and"); 
        assert_bit_eq(test_zero, 0, "and non-zero");

        assign test_op = `OP_ADD; // or op code
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0101, "simple add"); 
        assert_bit_eq(test_zero, 0, "or non-zero");

        assign test_op = `OP_AND; // and op code
        assign test_A = 8'b010; assign test_B = 8'b101; #10;
        assert_byte_eq(test_out, 8'b0000, "simple and to zero"); 
        assert_bit_eq(test_zero, 1, "and results in zero");

        assign test_op = `OP_SHL; // and op code
        assign test_A = 8'b010; assign test_B = 8'b101; #10;
        assert_byte_eq(test_out, 8'b0100, "simple shl"); 
        assert_bit_eq(test_zero, 0, "shl non-zero");

        $display("[dALU]\t\t\t All tests passed!!");
    end
endmodule