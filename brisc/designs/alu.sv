module ALU (
    input [31:0] A,
    input [31:0] B,
    input [2:0] funct3,
    input [6:0] funct7,
    output logic [31:0] out
);
    always_comb begin
        case (funct3)
            3'h0: begin
                if (funct7 == 7'h00) begin
                    out = A + B;
                end else begin
                    out = A - B;
                end
            end
            default: out = 32'hcccc;
        endcase
    end
endmodule