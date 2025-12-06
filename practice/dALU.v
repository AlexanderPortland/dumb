// OPCODES
`define OP_PASS 4'd7
`define OP_OR   4'd1
`define OP_AND  4'd2
`define OP_XOR  4'd3
`define OP_NOT  4'd4
`define OP_ADD  4'd5
`define OP_SUB  4'd6
`define OP_SHL  4'd7

// FLAG WIRES
`define FLAGS_ZERO     2'd0  // 1 if result is zero
`define FLAGS_CARRY    2'd1  // 1 if result carried
`define FLAGS_SIGN     2'd2  // 1 if result is positive
`define FLAGS_OVERFLOW 2'd3  // NOT YET USED

// a stab at an 8-bit ALU
module dALU(
    input [7:0] A, B,
    input [3:0] op,
    output reg [7:0] out,
    output [3:0] flags
    // output negative,
    // output carry // carry is when your value is correct, but too large to fit (i.e. truncation)
    // output overflow, // as i understand it, overflow is when your value is incorrect bc of overflow
);
    // do all the calculations
    wire [7:0] or_res, and_res, not_res, xor_res;
    byte_bitwise_or or1(A, B, or_res);
    byte_bitwise_and and1(A, B, and_res);
    byte_bitwise_not not1(A, not_res);
    byte_bitwise_xor xor1(A, B, xor_res);
    
    wire [7:0] add_sub_res, shl_res;
    wire sub, add_sub_carry, shl_carry;
    assign sub = (op == `OP_SUB);
    byte_ripple_add_sub add_sub1(A, B, sub, add_sub_carry, add_sub_res);
    byte_logical_left_shift shl1(A, shl_carry, shl_res);

    // multiplex them all into the output together
    // TODO: change this to an assign? or is that exactly the same?
    always @(*) begin
        case (op)
            `OP_OR: out = or_res; 
            `OP_AND: out = and_res;
            `OP_XOR: out = xor_res;
            `OP_NOT: out = not_res;
            `OP_ADD: out = add_sub_res;
            `OP_SUB: out = add_sub_res;
            `OP_SHL: out = shl_res; // TODO: try from logic gates
            `OP_PASS: out = B;
            // default: $error("IE: unknown op code %d", op);
            default: out = 0;
        endcase
    end

    // check if the output is zero
    wire any_bit_set;
    byte_any_bit_set bs(out, any_bit_set);
    not n(flags[`FLAGS_ZERO], any_bit_set);

    assign flags[`FLAGS_CARRY] = (op == `OP_SUB || op == `OP_ADD) ? add_sub_carry : 
                                 (op == `OP_SHL) ? shl_carry : 0;

    // check the sign of the output (using the most significant bit)
    // FIXME: not 100% sure this is right...
    assign flags[`FLAGS_SIGN] = out[7];
endmodule

// TODO: ops 
// - [ ] shift (from gates)
// - [ ] shr
// - [ ] more tests

module dALU_tb;
    reg [7:0] test_A, test_B;
    reg [3:0] test_op;
    wire [7:0] test_out;
    wire [3:0] test_flags;

    dALU alu(.A(test_A), .B(test_B), .op(test_op), .out(test_out), .flags(test_flags));

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
        assign test_op = `OP_OR;
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0011, "simple or"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "or non-zero");

        assign test_op = `OP_AND;
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0010, "simple and"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "and non-zero");

        assign test_op = `OP_ADD;
        assign test_A = 8'b010; assign test_B = 8'b011; #10;
        assert_byte_eq(test_out, 8'b0101, "simple add"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "or non-zero");

        assign test_op = `OP_AND;
        assign test_A = 8'b010; assign test_B = 8'b101; #10;
        assert_byte_eq(test_out, 8'b0000, "simple and to zero"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 1, "and results in zero");

        assign test_op = `OP_SHL;
        assign test_A = 8'b010; assign test_B = 8'b101; #10;
        assert_byte_eq(test_out, 8'b0100, "simple shl"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "simple shl");

        assign test_op = `OP_SHL;
        assign test_A = 8'd16; assign test_B = 8'd255; #10;
        assert_byte_eq(test_out, 8'd32, "shl to multiply by two"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "shl to multiply by two");

        assign test_op = `OP_OR;
        assign test_A = 8'd8; assign test_B = 8'd2; #10;
        assert_byte_eq(test_out, 8'D10, "sarah test"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "shl non-zero");

        assign test_op = `OP_ADD;
        assign test_A = 8'd250; assign test_B = 8'd7; #10;
        assert_byte_eq(test_out, 8'd1, "daniel test"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "or non-zero");

        assign test_op = `OP_ADD;
        assign test_A = 8'd200; assign test_B = 8'd1; #10;
        assert_byte_eq(test_out, 8'd201, "daniel test 2"); 
        assert_bit_eq(test_flags[`FLAGS_ZERO], 0, "or non-zero");


        $display("[dALU]\t\t\t All tests passed!!");
    end
endmodule