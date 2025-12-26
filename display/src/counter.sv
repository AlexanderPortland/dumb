module counter (
    input clk,
    output [3:0] annodes,
    output [6:0] seg
);
    reg [27:0] counter;
    reg [15:0] data;

    reg display_clk;
    reg [15:0] display_clk_counter;

    hex_display display(data, display_clk, annodes, seg);

    initial begin
        counter <= 0;
        data <= 0;
        display_clk <= 0;
        display_clk_counter <= 0;
    end

    always @(posedge clk) begin
        if (counter >= 27'd5_000_000) begin
            counter <= 0;
            data <= data + 1;
        end else begin 
            counter <= counter + 1;
        end

        if (display_clk_counter >= 16'd50_000) begin
            display_clk <= ~display_clk;
            display_clk_counter <= 0;
        end else begin
            display_clk_counter <= display_clk_counter + 1;
        end
    end
endmodule