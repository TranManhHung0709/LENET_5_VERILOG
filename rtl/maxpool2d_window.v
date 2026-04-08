// 2x2 Window Max-Pooling Logic
module maxpool2d_window (
    input  signed [15:0] d0,
    input  signed [15:0] d1,
    input  signed [15:0] d2,
    input  signed [15:0] d3,
    output signed [15:0] max_out
);

    // First stage: Find maximum of 2 pairs
    wire signed [15:0] max01;
    wire signed [15:0] max23;
    
    assign max01 = (d0 > d1) ? d0 : d1;
    assign max23 = (d2 > d3) ? d2 : d3;
    
    // Final stage: Find overall maximum
    assign max_out = (max01 > max23) ? max01 : max23;

endmodule
