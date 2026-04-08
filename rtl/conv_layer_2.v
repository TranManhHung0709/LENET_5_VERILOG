// Convolution Layer 2 (5x5, 8 filters, Time-multiplexed FSM Architecture)
module conv_layer_2 (
    input clk,
    input rst_n,
    
    // Inputs from Maxpool 1
    input valid_in,
    input signed [15:0] pixel_in_0,
    input signed [15:0] pixel_in_1,
    input signed [15:0] pixel_in_2,
    input signed [15:0] pixel_in_3,
    
    // Outputs
    output valid_out,
    output signed [15:0] conv_out_0, output signed [15:0] conv_out_1,
    output signed [15:0] conv_out_2, output signed [15:0] conv_out_3,
    output signed [15:0] conv_out_4, output signed [15:0] conv_out_5,
    output signed [15:0] conv_out_6, output signed [15:0] conv_out_7
);

    // 1. Pack channels and connect to local FIFO
    wire [63:0] packed_pixel = {pixel_in_3, pixel_in_2, pixel_in_1, pixel_in_0};
    
    wire fifo_empty, fifo_full;
    wire [63:0] fifo_rd_data;
    wire shift_req;
    
    sync_fifo_32x64 u_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(valid_in),
        .wr_data(packed_pixel),
        .rd_en(shift_req && !fifo_empty),
        .rd_data(fifo_rd_data),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    // 2. Line Buffer for 12x12 Images (4-channel packed)
    wire [63:0] w [0:24]; // 25 Window data containers (64-bit each)
    wire line_buf_valid;
    
    line_buffer_5x5_12x12 u_linebuf (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(shift_req && !fifo_empty),
        .pixel_in(fifo_rd_data),
        .w00(w[0]), .w01(w[1]), .w02(w[2]), .w03(w[3]), .w04(w[4]),
        .w10(w[5]), .w11(w[6]), .w12(w[7]), .w13(w[8]), .w14(w[9]),
        .w20(w[10]), .w21(w[11]), .w22(w[12]), .w23(w[13]), .w24(w[14]),
        .w30(w[15]), .w31(w[16]), .w32(w[17]), .w33(w[18]), .w34(w[19]),
        .w40(w[20]), .w41(w[21]), .w42(w[22]), .w43(w[23]), .w44(w[24]),
        .valid_out(line_buf_valid)
    );

    // 3. Load weights and biases from ROM memory files
    reg signed [15:0] c3_w [0:799];
    reg signed [15:0] c3_bias[0:7];
    
    initial begin
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/weights/c3_weight.mem", c3_w);
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/weights/c3_bias.mem", c3_bias);
    end

    // 4. Finite State Machine (FSM) to process 4 input channels sequentially
    localparam S_IDLE  = 3'd0;
    localparam S_CH0   = 3'd1;
    localparam S_CH1   = 3'd2;
    localparam S_CH2   = 3'd3;
    localparam S_CH3   = 3'd4;
    localparam S_SHIFT = 3'd5;
    
    reg [2:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else state <= next_state;
    end
    
    assign shift_req = (state == S_IDLE && !line_buf_valid) || (state == S_SHIFT);

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (line_buf_valid) next_state = S_CH0;
            end
            S_CH0: next_state = S_CH1;
            S_CH1: next_state = S_CH2;
            S_CH2: next_state = S_CH3;
            S_CH3: next_state = S_SHIFT;
            S_SHIFT: next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    // 5. Multiplexer Array to select input channel and corresponding weight
    wire signed [15:0] sel_data [0:24];
    wire signed [15:0] sel_w_f0 [0:24]; wire signed [15:0] sel_w_f1 [0:24];
    wire signed [15:0] sel_w_f2 [0:24]; wire signed [15:0] sel_w_f3 [0:24];
    wire signed [15:0] sel_w_f4 [0:24]; wire signed [15:0] sel_w_f5 [0:24];
    wire signed [15:0] sel_w_f6 [0:24]; wire signed [15:0] sel_w_f7 [0:24];

    genvar i;
    generate
        for (i=0; i<25; i=i+1) begin : mux_array
            // Data MUX
            assign sel_data[i] = (state == S_CH0) ? w[i][15:0] :
                                 (state == S_CH1) ? w[i][31:16] :
                                 (state == S_CH2) ? w[i][47:32] :
                                                    w[i][63:48];
            
            // Weight MUX for 8 filters (800 weights total)
            assign sel_w_f0[i] = (state == S_CH0) ? c3_w[i]      : (state == S_CH1) ? c3_w[i+25]      : (state == S_CH2) ? c3_w[i+50]      : c3_w[i+75];
            assign sel_w_f1[i] = (state == S_CH0) ? c3_w[i+100]  : (state == S_CH1) ? c3_w[i+125]     : (state == S_CH2) ? c3_w[i+150]     : c3_w[i+175];
            assign sel_w_f2[i] = (state == S_CH0) ? c3_w[i+200]  : (state == S_CH1) ? c3_w[i+225]     : (state == S_CH2) ? c3_w[i+250]     : c3_w[i+275];
            assign sel_w_f3[i] = (state == S_CH0) ? c3_w[i+300]  : (state == S_CH1) ? c3_w[i+325]     : (state == S_CH2) ? c3_w[i+350]     : c3_w[i+375];
            assign sel_w_f4[i] = (state == S_CH0) ? c3_w[i+400]  : (state == S_CH1) ? c3_w[i+425]     : (state == S_CH2) ? c3_w[i+450]     : c3_w[i+475];
            assign sel_w_f5[i] = (state == S_CH0) ? c3_w[i+500]  : (state == S_CH1) ? c3_w[i+525]     : (state == S_CH2) ? c3_w[i+550]     : c3_w[i+575];
            assign sel_w_f6[i] = (state == S_CH0) ? c3_w[i+600]  : (state == S_CH1) ? c3_w[i+625]     : (state == S_CH2) ? c3_w[i+650]     : c3_w[i+675];
            assign sel_w_f7[i] = (state == S_CH0) ? c3_w[i+700]  : (state == S_CH1) ? c3_w[i+725]     : (state == S_CH2) ? c3_w[i+750]     : c3_w[i+775];
        end
    endgenerate

    // 6. 200 Parallel Multiplication Units
    wire signed [15:0] prod_f0 [0:24]; wire signed [15:0] prod_f1 [0:24];
    wire signed [15:0] prod_f2 [0:24]; wire signed [15:0] prod_f3 [0:24];
    wire signed [15:0] prod_f4 [0:24]; wire signed [15:0] prod_f5 [0:24];
    wire signed [15:0] prod_f6 [0:24]; wire signed [15:0] prod_f7 [0:24];
    
    generate
        for (i=0; i<25; i=i+1) begin : mac_units
            multiplier_q6_10 u_m0 (.a(sel_data[i]), .b(sel_w_f0[i]), .out(prod_f0[i]));
            multiplier_q6_10 u_m1 (.a(sel_data[i]), .b(sel_w_f1[i]), .out(prod_f1[i]));
            multiplier_q6_10 u_m2 (.a(sel_data[i]), .b(sel_w_f2[i]), .out(prod_f2[i]));
            multiplier_q6_10 u_m3 (.a(sel_data[i]), .b(sel_w_f3[i]), .out(prod_f3[i]));
            multiplier_q6_10 u_m4 (.a(sel_data[i]), .b(sel_w_f4[i]), .out(prod_f4[i]));
            multiplier_q6_10 u_m5 (.a(sel_data[i]), .b(sel_w_f5[i]), .out(prod_f5[i]));
            multiplier_q6_10 u_m6 (.a(sel_data[i]), .b(sel_w_f6[i]), .out(prod_f6[i]));
            multiplier_q6_10 u_m7 (.a(sel_data[i]), .b(sel_w_f7[i]), .out(prod_f7[i]));
        end
    endgenerate

    // Combinational Adder Tree per filter
    reg signed [15:0] sum_f0, sum_f1, sum_f2, sum_f3, sum_f4, sum_f5, sum_f6, sum_f7;
    integer step;
    always @(*) begin
        sum_f0=0; sum_f1=0; sum_f2=0; sum_f3=0; sum_f4=0; sum_f5=0; sum_f6=0; sum_f7=0;
        for (step=0; step<25; step=step+1) begin
            sum_f0 = sum_f0 + prod_f0[step]; sum_f1 = sum_f1 + prod_f1[step];
            sum_f2 = sum_f2 + prod_f2[step]; sum_f3 = sum_f3 + prod_f3[step];
            sum_f4 = sum_f4 + prod_f4[step]; sum_f5 = sum_f5 + prod_f5[step];
            sum_f6 = sum_f6 + prod_f6[step]; sum_f7 = sum_f7 + prod_f7[step];
        end
    end

    // 7. Channel Accumulator: Sums results from 4 input channels
    reg signed [15:0] acc_f0, acc_f1, acc_f2, acc_f3, acc_f4, acc_f5, acc_f6, acc_f7;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_f0<=0; acc_f1<=0; acc_f2<=0; acc_f3<=0;
            acc_f4<=0; acc_f5<=0; acc_f6<=0; acc_f7<=0;
        end else begin
            if (state == S_CH0) begin
                acc_f0 <= sum_f0; acc_f1 <= sum_f1; acc_f2 <= sum_f2; acc_f3 <= sum_f3;
                acc_f4 <= sum_f4; acc_f5 <= sum_f5; acc_f6 <= sum_f6; acc_f7 <= sum_f7;
            end else if (state == S_CH1 || state == S_CH2 || state == S_CH3) begin
                acc_f0 <= acc_f0 + sum_f0; acc_f1 <= acc_f1 + sum_f1;
                acc_f2 <= acc_f2 + sum_f2; acc_f3 <= acc_f3 + sum_f3;
                acc_f4 <= acc_f4 + sum_f4; acc_f5 <= acc_f5 + sum_f5;
                acc_f6 <= acc_f6 + sum_f6; acc_f7 <= acc_f7 + sum_f7;
            end
        end
    end

    // 8. Bias Addition and ReLU Activation
    wire signed [15:0] relu_0, relu_1, relu_2, relu_3, relu_4, relu_5, relu_6, relu_7;
    relu u_r0(.in(acc_f0 + c3_bias[0]), .out(relu_0)); relu u_r1(.in(acc_f1 + c3_bias[1]), .out(relu_1));
    relu u_r2(.in(acc_f2 + c3_bias[2]), .out(relu_2)); relu u_r3(.in(acc_f3 + c3_bias[3]), .out(relu_3));
    relu u_r4(.in(acc_f4 + c3_bias[4]), .out(relu_4)); relu u_r5(.in(acc_f5 + c3_bias[5]), .out(relu_5));
    relu u_r6(.in(acc_f6 + c3_bias[6]), .out(relu_6)); relu u_r7(.in(acc_f7 + c3_bias[7]), .out(relu_7));

    reg signed [15:0] reg_out_0, reg_out_1, reg_out_2, reg_out_3, reg_out_4, reg_out_5, reg_out_6, reg_out_7;
    reg reg_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out_0<=0; reg_out_1<=0; reg_out_2<=0; reg_out_3<=0;
            reg_out_4<=0; reg_out_5<=0; reg_out_6<=0; reg_out_7<=0;
            reg_valid <= 0;
        end else if (state == S_SHIFT) begin
            // Result is complete after 4 channels; pulse valid_out
            reg_out_0 <= relu_0; reg_out_1 <= relu_1; reg_out_2 <= relu_2; reg_out_3 <= relu_3;
            reg_out_4 <= relu_4; reg_out_5 <= relu_5; reg_out_6 <= relu_6; reg_out_7 <= relu_7;
            reg_valid <= 1;
        end else begin
            reg_valid <= 0;
        end
    end

    assign conv_out_0 = reg_out_0; assign conv_out_1 = reg_out_1;
    assign conv_out_2 = reg_out_2; assign conv_out_3 = reg_out_3;
    assign conv_out_4 = reg_out_4; assign conv_out_5 = reg_out_5;
    assign conv_out_6 = reg_out_6; assign conv_out_7 = reg_out_7;
    assign valid_out = reg_valid;

endmodule
