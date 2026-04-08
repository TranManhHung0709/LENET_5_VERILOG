// Signed Q6.10 Multiplier
module multiplier_q6_10 (
    input  signed [15:0] a,
    input  signed [15:0] b,
    output signed [15:0] out
);

    wire signed [31:0] temp_mult; // 32-bit to prevent overflow
    
    assign temp_mult = a * b; // Result in Q12.20 format
    
    // Scale back to Q6.10
    assign out = temp_mult[25:10];

endmodule
