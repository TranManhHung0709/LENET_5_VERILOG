// LeNet-5 Top Module: Integrates the entire CNN pipeline
// Pipeline: Conv1 -> Pool1 -> Conv2 -> Pool2 -> Flatten -> f1 -> f2 -> out -> Argmax
// Input: 28x28 Images (Serial stream, 1 pixel per clock cycle)
// Output: Prediction index (0-9)
module lenet5_top (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire signed [15:0] pixel_in,
    
    output wire [3:0] prediction,  // Final predicted digit (0-9)
    output wire result_valid       // Pulse asserted when prediction is ready
);

    // 1. CONV1 (28x28 -> 24x24, 4 filters)
    wire c1_valid;
    wire signed [15:0] c1_out0, c1_out1, c1_out2, c1_out3;
    
    conv_layer_1 u_conv1 (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .pixel_in(pixel_in),
        .valid_out(c1_valid),
        .conv_out_0(c1_out0), .conv_out_1(c1_out1),
        .conv_out_2(c1_out2), .conv_out_3(c1_out3)
    );

    // 2. MAXPOOL1 (24x24 -> 12x12, 4 channels)
    wire p1_valid;
    wire signed [15:0] p1_out0, p1_out1, p1_out2, p1_out3;
    
    maxpool_layer_1 u_pool1 (
        .clk(clk), .rst_n(rst_n), .valid_in(c1_valid),
        .in_ch0(c1_out0), .in_ch1(c1_out1),
        .in_ch2(c1_out2), .in_ch3(c1_out3),
        .valid_out(p1_valid),
        .out_ch0(p1_out0), .out_ch1(p1_out1),
        .out_ch2(p1_out2), .out_ch3(p1_out3)
    );

    // 3. CONV2 (12x12 -> 8x8, 8 filters, Time-multiplexed architecture)
    wire c2_valid;
    wire signed [15:0] c2_out0, c2_out1, c2_out2, c2_out3;
    wire signed [15:0] c2_out4, c2_out5, c2_out6, c2_out7;
    
    conv_layer_2 u_conv2 (
        .clk(clk), .rst_n(rst_n), .valid_in(p1_valid),
        .pixel_in_0(p1_out0), .pixel_in_1(p1_out1),
        .pixel_in_2(p1_out2), .pixel_in_3(p1_out3),
        .valid_out(c2_valid),
        .conv_out_0(c2_out0), .conv_out_1(c2_out1),
        .conv_out_2(c2_out2), .conv_out_3(c2_out3),
        .conv_out_4(c2_out4), .conv_out_5(c2_out5),
        .conv_out_6(c2_out6), .conv_out_7(c2_out7)
    );

    // 4. MAXPOOL2 (8x8 -> 4x4, 8 channels)
    wire p2_valid;
    wire signed [15:0] p2_out0, p2_out1, p2_out2, p2_out3;
    wire signed [15:0] p2_out4, p2_out5, p2_out6, p2_out7;
    
    maxpool_layer_2 u_pool2 (
        .clk(clk), .rst_n(rst_n), .valid_in(c2_valid),
        .in_ch0(c2_out0), .in_ch1(c2_out1),
        .in_ch2(c2_out2), .in_ch3(c2_out3),
        .in_ch4(c2_out4), .in_ch5(c2_out5),
        .in_ch6(c2_out6), .in_ch7(c2_out7),
        .valid_out(p2_valid),
        .out_ch0(p2_out0), .out_ch1(p2_out1),
        .out_ch2(p2_out2), .out_ch3(p2_out3),
        .out_ch4(p2_out4), .out_ch5(p2_out5),
        .out_ch6(p2_out6), .out_ch7(p2_out7)
    );

    // 5. FLATTEN (8 parallel channels -> 1 sequential data stream)
    wire flat_valid;
    wire signed [15:0] flat_data;
    
    flatten_8ch u_flatten (
        .clk(clk), .rst_n(rst_n), .valid_in(p2_valid),
        .ch0(p2_out0), .ch1(p2_out1), .ch2(p2_out2), .ch3(p2_out3),
        .ch4(p2_out4), .ch5(p2_out5), .ch6(p2_out6), .ch7(p2_out7),
        .valid_out(flat_valid),
        .data_out(flat_data)
    );


    // 6. DENSE Layer F1 (128 inputs -> 32 neurons, with ReLU)
    wire f1_valid;
    wire signed [15:0] f1_data;
    wire f1_done;
    
    dense_layer #(
        .INPUT_SIZE(128),
        .OUTPUT_SIZE(32),
        .WEIGHT_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/f1_weight.mem"),
        .BIAS_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/f1_bias.mem"),
        .HAS_RELU(1)
    ) u_dense_f1 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(flat_valid), .data_in(flat_data),
        .valid_out(f1_valid), .data_out(f1_data), .done(f1_done)
    );

    // 7. DENSE Layer F2 (32 inputs -> 16 neurons, with ReLU)
    wire f2_valid;
    wire signed [15:0] f2_data;
    wire f2_done;
    
    dense_layer #(
        .INPUT_SIZE(32),
        .OUTPUT_SIZE(16),
        .WEIGHT_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/f2_weight.mem"),
        .BIAS_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/f2_bias.mem"),
        .HAS_RELU(1)
    ) u_dense_f2 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(f1_valid), .data_in(f1_data),
        .valid_out(f2_valid), .data_out(f2_data), .done(f2_done)
    );

    // 8. DENSE OUTPUT Layer (16 inputs -> 10 neurons, NO ReLU)
    wire out_valid;
    wire signed [15:0] out_data;
    wire out_done;
    
    dense_layer #(
        .INPUT_SIZE(16),
        .OUTPUT_SIZE(10),
        .WEIGHT_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/out_weight.mem"),
        .BIAS_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/out_bias.mem"),
        .HAS_RELU(0)
    ) u_dense_out (
        .clk(clk), .rst_n(rst_n),
        .valid_in(f2_valid), .data_in(f2_data),
        .valid_out(out_valid), .data_out(out_data), .done(out_done)
    );

    // 9. ARGMAX (Identify the maximum value among the 10 outputs)
    argmax u_argmax (
        .clk(clk), .rst_n(rst_n),
        .valid_in(out_valid), .data_in(out_data),
        .done_in(out_done),
        .prediction(prediction),
        .valid_out(result_valid)
    );

endmodule
