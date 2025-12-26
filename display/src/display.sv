/// Converts a 16b input for display in hex on a four-digit seven segment display.
module hex_display (
    input [15:0] in,
    // This clock should be signficantly slower than the one used in general 
    // to ensure we're not updating the display to fast.
    // The manual recommends a refresh frequency of 1KHz-60Hz which implies this clock 
    // would need to be driven 4kHz-240Hz.
    input clk,
    output [3:0] annodes,
    output [6:0] seg
);
    reg [1:0] state;
    wire [3:0] curr_data;

    // Select the digit for the current data based on the state.
    // (Since only one kind of digit can be displayed at any given time).
    assign curr_data = (state == 0) ? in[3:0] :
                       (state == 1) ? in[7:4] :
                       (state == 2) ? in[11:8] :
                       (state == 3) ? in[15:12] : 0;

    assign annodes[0] = (state != 0);
    assign annodes[1] = (state != 1);
    assign annodes[2] = (state != 2);
    assign annodes[3] = (state != 3);
    
    seven_segment_data curr_seg(curr_data, seg);

    always @(posedge clk) begin
        state <= state + 1;
    end
endmodule

// For both anodes, and segments, LOW is active
`define SEG_ACTIVE 0
`define SEG_INACTIVE 1

/// Determines which segments should be active to display the hex character for byte-sized `data`.
module seven_segment_data (
    input [3:0] data,
    output [6:0] seg
);
    assign seg[0] = (data == 1 || data == 4 || data == 11 || data == 13) ? `SEG_INACTIVE : `SEG_ACTIVE;
    assign seg[1] = (data == 5 || data == 6 || (data >= 11 && data != 13)) ? `SEG_INACTIVE : `SEG_ACTIVE;
    assign seg[2] = (data == 2 || data == 12 || data == 14 || data == 15) ? `SEG_INACTIVE : `SEG_ACTIVE;
    assign seg[3] = (data == 1 || data == 4 || data == 7 || data == 9 || data == 10 || data == 15) ? `SEG_INACTIVE : `SEG_ACTIVE;
    assign seg[4] = (data == 1 || data == 3 || data == 4 || data == 5 || data == 7 || data == 9) ? `SEG_INACTIVE : `SEG_ACTIVE;
    assign seg[5] = (data == 1 || data == 2 || data == 3 || data == 7 || data == 'hd) ? `SEG_INACTIVE : `SEG_ACTIVE;
    assign seg[6] = (data == 0 || data == 1 || data == 7 || data == 'hc) ? `SEG_INACTIVE : `SEG_ACTIVE;
endmodule