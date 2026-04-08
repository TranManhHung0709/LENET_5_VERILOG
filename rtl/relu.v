// ReLU Activation Module
module relu (
    input  signed [15:0] in,
    output signed [15:0] out
);

    assign out = (in[15] == 1'b1) ? 16'd0 : in;

endmodule
