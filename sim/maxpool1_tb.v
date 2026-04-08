`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: maxpool1_tb
// Description: Testbench for the integrated Conv1 -> Maxpool1 pipeline.
//////////////////////////////////////////////////////////////////////////////////

module maxpool1_tb;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [15:0] pixel_in;
    
    // Interconnect signals between Conv1 and Maxpool1
    wire conv1_valid_out;
    wire signed [15:0] conv1_out_0;
    wire signed [15:0] conv1_out_1;
    wire signed [15:0] conv1_out_2;
    wire signed [15:0] conv1_out_3;

    // Convolution Layer 1 instance
    conv_layer_1 uut_conv1 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .pixel_in(pixel_in),
        
        .valid_out(conv1_valid_out),
        .conv_out_0(conv1_out_0),
        .conv_out_1(conv1_out_1),
        .conv_out_2(conv1_out_2),
        .conv_out_3(conv1_out_3)
    );

    // Maxpool1 output signals
    wire pool1_valid_out;
    wire signed [15:0] pool1_out_0;
    wire signed [15:0] pool1_out_1;
    wire signed [15:0] pool1_out_2;
    wire signed [15:0] pool1_out_3;

    // Maxpool Layer 1 instance
    maxpool_layer_1 uut_pool1 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(conv1_valid_out),
        .in_ch0(conv1_out_0),
        .in_ch1(conv1_out_1),
        .in_ch2(conv1_out_2),
        .in_ch3(conv1_out_3),
        
        .valid_out(pool1_valid_out),
        .out_ch0(pool1_out_0),
        .out_ch1(pool1_out_1),
        .out_ch2(pool1_out_2),
        .out_ch3(pool1_out_3)
    );

    // Load input image from memory
    reg signed [15:0] img_mem [0:783];
    integer i;

    // Clock Initialization
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Procedure
    initial begin
        $dumpfile("maxpool_sim.vcd");
        $dumpvars(0, maxpool1_tb);
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/weights/input_img.mem", img_mem);
        
        rst_n = 0;
        valid_in = 0;
        pixel_in = 0;
        
        #100;
        rst_n = 1;
        #20;
        
        $display("=========== STARTING INTEGRATION TEST (CONV1 + MAXPOOL1) ===========");
        
        // Scan input image
        for (i = 0; i < 784; i = i + 1) begin
            valid_in = 1;
            pixel_in = img_mem[i];
            @(posedge clk);
        end
        
        // Final dummy cycle to flush the pipeline (Final Valid pulse)
        valid_in = 1;
        pixel_in = 0;
        @(posedge clk);
        
        valid_in = 0;
        pixel_in = 0;
        
        // Wait for remaining data to flow through the pipeline
        #2000;
        
        $display("--- SUMMARY ---");
        $display("Conv1 Valid Count: %0d (Expected: 576)", conv_valid_cnt);
        $display("Pool1 Valid Count: %0d (Expected: 144)", pool_valid_cnt);
        $display("=========== SIMULATION COMPLETED ===========");
        $finish;
    end

    // Monitor output valid counts for comparison
    integer conv_valid_cnt = 0;
    integer pool_valid_cnt = 0;

    always @(posedge clk) begin
        if (conv1_valid_out) begin
            conv_valid_cnt = conv_valid_cnt + 1;
        end
        
        if (pool1_valid_out) begin
            pool_valid_cnt = pool_valid_cnt + 1;
            
            // Log first few Maxpool output values
            if (pool_valid_cnt <= 10) begin
                $display("Time %0d ns | Pool Output %0d | Ch0: %h | Ch1: %h | Ch2: %h | Ch3: %h", 
                          $time, pool_valid_cnt, pool1_out_0, pool1_out_1, pool1_out_2, pool1_out_3);
            end
        end
    end

endmodule
