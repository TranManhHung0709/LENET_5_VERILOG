// Convolution Layer 1 (5x5, 4 filters, Parallel Architecture)
module conv_layer_1 (
    input clk,
    input rst_n,
    input valid_in,
    input signed [15:0] pixel_in,
    
    output valid_out,
    output signed [15:0] conv_out_0,  // Filter 0 output
    output signed [15:0] conv_out_1,  // Filter 1 output
    output signed [15:0] conv_out_2,  // Filter 2 output
    output signed [15:0] conv_out_3   // Filter 3 output
);

    // Line Buffer instantiation
    wire signed [15:0] w[0:24];
    wire window_valid;
    
    line_buffer_5x5 line_buf (
        .clock(clk),
        .reset(~rst_n),
        .valid_in(valid_in),
        .pixel_in(pixel_in),
        
        .w00(w[0]), .w01(w[1]), .w02(w[2]), .w03(w[3]), .w04(w[4]),
        .w10(w[5]), .w11(w[6]), .w12(w[7]), .w13(w[8]), .w14(w[9]),
        .w20(w[10]), .w21(w[11]), .w22(w[12]), .w23(w[13]), .w24(w[14]),
        .w30(w[15]), .w31(w[16]), .w32(w[17]), .w33(w[18]), .w34(w[19]),
        .w40(w[20]), .w41(w[21]), .w42(w[22]), .w43(w[23]), .w44(w[24]),
        
        .valid_out(window_valid)
    );

    // Load weights and biases from ROM memory files
    reg signed [15:0] c1_weight [0:99];
    reg signed [15:0] c1_bias [0:3];
    
    initial begin
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/weights/c1_weight.mem", c1_weight);
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/weights/c1_bias.mem", c1_bias);
    end

    // Mapped weights for parallel filter processing
    wire signed [15:0] weight_f0 [0:24];
    wire signed [15:0] weight_f1 [0:24];
    wire signed [15:0] weight_f2 [0:24];
    wire signed [15:0] weight_f3 [0:24];
    
    genvar i;
    generate
        for (i=0; i<25; i=i+1) begin : weight_assign
            assign weight_f0[i] = c1_weight[i];
            assign weight_f1[i] = c1_weight[i + 25];
            assign weight_f2[i] = c1_weight[i + 50];
            assign weight_f3[i] = c1_weight[i + 75];
        end
    endgenerate

    // Multiplier Array for 4 filters
    wire signed [15:0] prod_f0 [0:24];
    wire signed [15:0] prod_f1 [0:24];
    wire signed [15:0] prod_f2 [0:24];
    wire signed [15:0] prod_f3 [0:24];
    
    generate
        for (i=0; i<25; i=i+1) begin : mac_units
            // Instantiate 4 multiplication units in parallel per kernel element
            multiplier_q6_10 u_mult_0 (.a(w[i]), .b(weight_f0[i]), .out(prod_f0[i]));
            multiplier_q6_10 u_mult_1 (.a(w[i]), .b(weight_f1[i]), .out(prod_f1[i]));
            multiplier_q6_10 u_mult_2 (.a(w[i]), .b(weight_f2[i]), .out(prod_f2[i]));
            multiplier_q6_10 u_mult_3 (.a(w[i]), .b(weight_f3[i]), .out(prod_f3[i]));
        end
    endgenerate

    // Combinational Adder Tree to compute convolution sums
    reg signed [15:0] sum_0, sum_1, sum_2, sum_3;
    integer step;
    
    always @(*) begin
        sum_0 = c1_bias[0];
        sum_1 = c1_bias[1];
        sum_2 = c1_bias[2];
        sum_3 = c1_bias[3];
        
        for (step=0; step<25; step=step+1) begin
            sum_0 = sum_0 + prod_f0[step];
            sum_1 = sum_1 + prod_f1[step];
            sum_2 = sum_2 + prod_f2[step];
            sum_3 = sum_3 + prod_f3[step];
        end
    end

    // ReLU Activation units
    wire signed [15:0] relu_0_out, relu_1_out, relu_2_out, relu_3_out;
    relu u_relu_0 (.in(sum_0), .out(relu_0_out));
    relu u_relu_1 (.in(sum_1), .out(relu_1_out));
    relu u_relu_2 (.in(sum_2), .out(relu_2_out));
    relu u_relu_3 (.in(sum_3), .out(relu_3_out));

    // Output Registers to reduce combinational delay path
    reg signed [15:0] reg_out_0, reg_out_1, reg_out_2, reg_out_3;
    reg reg_valid_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out_0 <= 0; reg_out_1 <= 0; reg_out_2 <= 0; reg_out_3 <= 0;
            reg_valid_out <= 0;
        end else begin
            reg_out_0 <= relu_0_out;
            reg_out_1 <= relu_1_out;
            reg_out_2 <= relu_2_out;
            reg_out_3 <= relu_3_out;
            reg_valid_out <= window_valid;
        end
    end

    assign conv_out_0 = reg_out_0;
    assign conv_out_1 = reg_out_1;
    assign conv_out_2 = reg_out_2;
    assign conv_out_3 = reg_out_3;
    assign valid_out  = reg_valid_out;

endmodule
